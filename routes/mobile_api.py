from flask import Blueprint, request, jsonify, make_response
import jwt
import datetime
import os
from werkzeug.security import check_password_hash
from functools import wraps

from models import User, UserRole, Turf, Review, TimeSlot, Booking, BookingStatus, TurfImage, Negotiation
from app import db

# Create a blueprint for all mobile API routes
mobile_api = Blueprint('mobile_api', __name__)

# Time slots endpoint is defined later in this file

# JWT Configuration - Always use the same secret in development for testing
JWT_SECRET = 'turf-booking-jwt-secret-for-mobile-app'
JWT_EXPIRATION = datetime.timedelta(days=7)

# In production, use this:
# JWT_SECRET = os.environ.get('JWT_SECRET')
# if not JWT_SECRET:
#     raise RuntimeError("JWT_SECRET environment variable not set")

# Authentication helper functions
def generate_token(user_id):
    """Generate a JWT token for the user"""
    payload = {
        'exp': datetime.datetime.utcnow() + JWT_EXPIRATION,
        'iat': datetime.datetime.utcnow(),
        'sub': str(user_id)  # Convert to string to avoid JWT validation issues
    }
    return jwt.encode(
        payload,
        JWT_SECRET,
        algorithm='HS256'
    )

def token_required(f):
    """Decorator to protect routes with JWT"""
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        
        # Get token from headers
        if 'Authorization' in request.headers:
            auth_header = request.headers['Authorization']
            if auth_header.startswith('Bearer '):
                token = auth_header.split(' ')[1]
        
        if not token:
            return jsonify({
                'success': False,
                'message': 'Token is missing'
            }), 401
        
        try:
            payload = jwt.decode(token, JWT_SECRET, algorithms=['HS256'])
            # Convert string user_id back to integer
            user_id = int(payload['sub'])
            user = User.query.get(user_id)
            
            if not user:
                return jsonify({
                    'success': False,
                    'message': 'User not found'
                }), 401
                
        except jwt.ExpiredSignatureError:
            return jsonify({
                'success': False,
                'message': 'Token has expired'
            }), 401
        except jwt.InvalidTokenError as e:
            return jsonify({
                'success': False,
                'message': f'Invalid token: {str(e)}'
            }), 401
        except Exception as e:
            return jsonify({
                'success': False,
                'message': f'Token error: {str(e)}'
            }), 401
        
        return f(user, *args, **kwargs)
    
    return decorated

# API Routes for Authentication
@mobile_api.route('/login', methods=['POST'])
def api_login():
    """API endpoint for mobile app login"""
    data = request.get_json()
    if not data:
        return jsonify({
            'success': False,
            'message': 'No data provided'
        }), 400
    
    email = data.get('email')
    password = data.get('password')
    
    if not email or not password:
        return jsonify({
            'success': False,
            'message': 'Email and password are required'
        }), 400
    
    user = User.query.filter_by(email=email).first()
    if not user or not user.check_password(password):
        return jsonify({
            'success': False,
            'message': 'Invalid email or password'
        }), 401
    
    token = generate_token(user.id)
    
    return jsonify({
        'success': True,
        'message': 'Login successful',
        'token': token,
        'user': {
            'id': user.id,
            'username': user.username,
            'email': user.email,
            'phone_number': user.phone_number,
            'role': user.role
        }
    })

@mobile_api.route('/register', methods=['POST'])
def api_register():
    """API endpoint for mobile app registration"""
    data = request.get_json()
    if not data:
        return jsonify({
            'success': False,
            'message': 'No data provided'
        }), 400
    
    username = data.get('username')
    email = data.get('email')
    phone_number = data.get('phone_number')
    password = data.get('password')
    role = data.get('role', UserRole.USER)
    
    # Validate required fields
    if not username or not email or not phone_number or not password:
        return jsonify({
            'success': False,
            'message': 'All fields are required'
        }), 400
    
    # Check for existing email
    if User.query.filter_by(email=email).first():
        return jsonify({
            'success': False,
            'message': 'Email address is already registered'
        }), 400
    
    # Check for existing username
    if User.query.filter_by(username=username).first():
        return jsonify({
            'success': False,
            'message': 'Username is already taken'
        }), 400
    
    # Create new user
    try:
        user = User(
            username=username,
            email=email,
            phone_number=phone_number,
            role=role
        )
        user.set_password(password)
        
        db.session.add(user)
        db.session.commit()
        
        token = generate_token(user.id)
        
        return jsonify({
            'success': True,
            'message': 'Registration successful',
            'token': token,
            'user': {
                'id': user.id,
                'username': user.username,
                'email': user.email,
                'phone_number': user.phone_number,
                'role': user.role
            }
        }), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'message': f'Registration failed: {str(e)}'
        }), 500

@mobile_api.route('/verify_token', methods=['GET'])
@token_required
def api_verify_token(current_user):
    """API endpoint to verify token validity and get user info"""
    return jsonify({
        'success': True,
        'user': {
            'id': current_user.id,
            'username': current_user.username,
            'email': current_user.email,
            'phone_number': current_user.phone_number,
            'role': current_user.role
        }
    })

# Turf API Endpoints
@mobile_api.route('/turfs', methods=['GET'])
def get_turfs():
    """Get all turfs with pagination and filtering"""
    try:
        # Get query parameters
        page = request.args.get('page', 1, type=int)
        limit = request.args.get('limit', 10, type=int)
        city = request.args.get('city', None, type=str)
        indoor = request.args.get('indoor', None)
        
        # Convert indoor string to boolean if provided
        if indoor is not None:
            indoor = indoor.lower() == 'true'
        
        # Build query
        query = Turf.query
        
        # Apply filters if provided
        if city:
            query = query.filter(Turf.city.ilike(f'%{city}%'))
        if indoor is not None:
            query = query.filter_by(indoor=indoor)
        
        # Count total results
        total_turfs = query.count()
        total_pages = (total_turfs + limit - 1) // limit if limit > 0 else 1
        
        # Apply pagination
        query = query.order_by(Turf.created_at.desc())
        turfs = query.offset((page - 1) * limit).limit(limit).all()
        
        # Prepare response data
        turfs_data = []
        for turf in turfs:
            # Get primary image if available
            primary_image = None
            images = turf.images.all()
            if images:
                for img in images:
                    if img.is_primary:
                        primary_image = img
                        break
                if not primary_image:
                    primary_image = images[0]
            
            # Build turf data dictionary
            turf_data = {
                'id': turf.id,
                'name': turf.name,
                'address': turf.address,
                'city': turf.city,
                'state': turf.state,
                'country': turf.country,
                'base_price_per_hour': turf.base_price_per_hour,
                'features': turf.features.split(',') if turf.features else [],
                'size': turf.size,
                'indoor': turf.indoor,
                'avg_rating': turf.get_average_rating(),
                'rating_count': turf.get_rating_count(),
                'surface_type': turf.surface_type,
                'has_parking': turf.has_parking,
                'has_changing_room': turf.has_changing_room,
                'has_shower': turf.has_shower,
                'has_floodlights': turf.has_floodlights,
                'has_equipment': turf.has_equipment,
                'image': primary_image.url if primary_image else None
            }
            turfs_data.append(turf_data)
        
        return jsonify({
            'success': True,
            'turfs': turfs_data,
            'current_page': page,
            'total_pages': total_pages,
            'total_turfs': total_turfs
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error fetching turfs: {str(e)}'
        }), 500

@mobile_api.route('/turf/<int:turf_id>', methods=['GET'])
def get_turf_details(turf_id):
    """Get detailed information for a single turf"""
    try:
        turf = Turf.query.get_or_404(turf_id)
        
        # Get all images
        images = turf.images.all()
        image_urls = [img.url for img in images]
        
        # Get primary image if available
        primary_image = None
        for img in images:
            if img.is_primary:
                primary_image = img.url
                break
        if not primary_image and images:
            primary_image = images[0].url
        
        # Get available time slots for today
        today = datetime.datetime.utcnow().date()
        available_slots = turf.get_available_slots(today)
        
        # Convert time slots to a serializable format
        slots_data = []
        for slot in available_slots:
            slots_data.append({
                'id': slot.id,
                'day_of_week': slot.day_of_week,
                'start_time': slot.start_time.strftime('%H:%M'),
                'end_time': slot.end_time.strftime('%H:%M'),
                'price_adjustment': slot.price_adjustment
            })
        
        # Build turf details response
        turf_data = {
            'id': turf.id,
            'name': turf.name,
            'description': turf.description,
            'address': turf.address,
            'city': turf.city,
            'state': turf.state,
            'country': turf.country,
            'postal_code': turf.postal_code,
            'latitude': turf.latitude,
            'longitude': turf.longitude,
            'base_price_per_hour': turf.base_price_per_hour,
            'features': turf.features.split(',') if turf.features else [],
            'size': turf.size,
            'indoor': turf.indoor,
            'avg_rating': turf.get_average_rating(),
            'rating_count': turf.get_rating_count(),
            'surface_type': turf.surface_type,
            'has_parking': turf.has_parking,
            'has_changing_room': turf.has_changing_room,
            'has_shower': turf.has_shower,
            'has_floodlights': turf.has_floodlights,
            'has_equipment': turf.has_equipment,
            'has_refreshments': turf.has_refreshments,
            'primary_image': primary_image,
            'images': image_urls,
            'available_slots': slots_data,
            'owner': {
                'id': turf.owner.id,
                'username': turf.owner.username
            }
        }
        
        return jsonify({
            'success': True,
            'turf': turf_data
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error fetching turf details: {str(e)}'
        }), 500

@mobile_api.route('/search', methods=['GET'])
def search_turfs():
    """API endpoint for basic turf search"""
    try:
        # Get query parameters
        city = request.args.get('city', None, type=str)
        date_str = request.args.get('date', None, type=str)
        min_price = request.args.get('min_price', None, type=float)
        max_price = request.args.get('max_price', None, type=float)
        indoor = request.args.get('indoor', None)
        
        # Convert string parameters
        date = None
        if date_str:
            try:
                date = datetime.datetime.strptime(date_str, '%Y-%m-%d').date()
            except ValueError:
                pass
        
        if indoor is not None:
            indoor = indoor.lower() == 'true'
        
        # Build query
        query = Turf.query.filter(Turf.active == True)
        
        # Apply filters
        if city:
            query = query.filter(Turf.city.ilike(f'%{city}%'))
        if min_price is not None:
            query = query.filter(Turf.base_price_per_hour >= min_price)
        if max_price is not None:
            query = query.filter(Turf.base_price_per_hour <= max_price)
        if indoor is not None:
            query = query.filter_by(indoor=indoor)
        
        # Execute query
        turfs = query.all()
        
        # Filter by availability if date is provided
        if date:
            available_turfs = []
            for turf in turfs:
                available_slots = turf.get_available_slots(date)
                if available_slots:
                    turf.available_slots = available_slots
                    available_turfs.append(turf)
            turfs = available_turfs
        
        # Prepare response data
        turfs_data = []
        for turf in turfs:
            # Get primary image if available
            primary_image = None
            images = turf.images.all()
            if images:
                for img in images:
                    if img.is_primary:
                        primary_image = img
                        break
                if not primary_image:
                    primary_image = images[0]
            
            # Build turf data
            turf_data = {
                'id': turf.id,
                'name': turf.name,
                'address': turf.address,
                'city': turf.city,
                'state': turf.state,
                'country': turf.country,
                'base_price_per_hour': turf.base_price_per_hour,
                'features': turf.features.split(',') if turf.features else [],
                'size': turf.size,
                'indoor': turf.indoor,
                'avg_rating': turf.get_average_rating(),
                'rating_count': turf.get_rating_count(),
                'surface_type': turf.surface_type,
                'has_parking': turf.has_parking,
                'has_changing_room': turf.has_changing_room,
                'has_shower': turf.has_shower,
                'has_floodlights': turf.has_floodlights,
                'has_equipment': turf.has_equipment,
                'image': primary_image.url if primary_image else None
            }
            turfs_data.append(turf_data)
        
        return jsonify({
            'success': True,
            'turfs': turfs_data,
            'count': len(turfs_data)
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error searching turfs: {str(e)}'
        }), 500

@mobile_api.route('/turf/<int:turf_id>/time_slots', methods=['GET', 'OPTIONS'])
def get_turf_time_slots(turf_id):
    """Get available time slots for a specific turf on a given date"""
    # Handle preflight OPTIONS request
    if request.method == 'OPTIONS':
        response = make_response()
        response.headers.add('Access-Control-Allow-Origin', '*')
        response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
        response.headers.add('Access-Control-Allow-Methods', 'GET')
        return response
        
    try:
        # Get the date from query parameters
        date_str = request.args.get('date', None, type=str)
        if not date_str:
            return jsonify({
                'success': False,
                'message': 'Date parameter is required'
            }), 400
        
        # Parse the date
        try:
            date = datetime.datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            return jsonify({
                'success': False,
                'message': 'Invalid date format. Use YYYY-MM-DD'
            }), 400
        
        # Get the turf
        turf = Turf.query.get_or_404(turf_id)
        
        # Get available time slots for the date
        time_slots = turf.get_available_slots(date)
        
        # If no time slots are available for the date, return empty array
        if not time_slots:
            return jsonify({
                'success': True,
                'time_slots': []
            })
        
        # Format the time slots
        formatted_slots = []
        for slot in time_slots:
            # Calculate adjusted price
            adjusted_price = turf.base_price_per_hour
            if slot.price_adjustment:
                adjusted_price = adjusted_price * (1 + slot.price_adjustment / 100)
                
            # Format times
            start_time = slot.start_time.strftime('%H:%M')
            end_time = slot.end_time.strftime('%H:%M')
            start_time_12hr = slot.start_time.strftime('%I:%M %p')
            end_time_12hr = slot.end_time.strftime('%I:%M %p')
            
            formatted_slots.append({
                'id': slot.id,
                'day_of_week': slot.day_of_week,
                'start_time': start_time,
                'end_time': end_time,
                'value': f"{start_time} - {end_time}",
                'text': f"{start_time_12hr} - {end_time_12hr}",
                'price': round(adjusted_price, 2),
                'price_adjustment': slot.price_adjustment
            })
        
        return jsonify({
            'success': True,
            'time_slots': formatted_slots
        })
        
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error fetching time slots: {str(e)}'
        }), 500

@mobile_api.route('/advanced_search', methods=['GET'])
def advanced_search_turfs():
    """API endpoint for advanced turf search"""
    try:
        # Get query parameters
        city = request.args.get('city', None, type=str)
        date_str = request.args.get('date', None, type=str)
        min_price = request.args.get('min_price', None, type=float)
        max_price = request.args.get('max_price', None, type=float)
        indoor = request.args.get('indoor', None)
        has_parking = request.args.get('has_parking', None)
        has_changing_room = request.args.get('has_changing_room', None)
        has_shower = request.args.get('has_shower', None)
        has_floodlights = request.args.get('has_floodlights', None)
        has_equipment = request.args.get('has_equipment', None)
        min_rating = request.args.get('min_rating', None, type=int)
        surface_type = request.args.get('surface_type', None, type=str)
        
        # Convert string parameters to appropriate types
        date = None
        if date_str:
            try:
                date = datetime.datetime.strptime(date_str, '%Y-%m-%d').date()
            except ValueError:
                pass
        
        if indoor is not None:
            indoor = indoor.lower() == 'true'
        if has_parking is not None:
            has_parking = has_parking.lower() == 'true'
        if has_changing_room is not None:
            has_changing_room = has_changing_room.lower() == 'true'
        if has_shower is not None:
            has_shower = has_shower.lower() == 'true'
        if has_floodlights is not None:
            has_floodlights = has_floodlights.lower() == 'true'
        if has_equipment is not None:
            has_equipment = has_equipment.lower() == 'true'
        
        # Start with active turfs
        query = Turf.query.filter(Turf.active == True)
        
        # Apply filters
        if city:
            query = query.filter(Turf.city.ilike(f'%{city}%'))
        if min_price is not None:
            query = query.filter(Turf.base_price_per_hour >= min_price)
        if max_price is not None:
            query = query.filter(Turf.base_price_per_hour <= max_price)
        if indoor is not None:
            query = query.filter_by(indoor=indoor)
        
        # Get initial results that match database columns
        turfs = query.all()
        
        # Apply post-query filters (for virtual properties)
        filtered_turfs = []
        for turf in turfs:
            include = True
            
            # Apply feature filters
            if has_parking and not turf.has_parking:
                include = False
            if has_changing_room and not turf.has_changing_room:
                include = False
            if has_shower and not turf.has_shower:
                include = False
            if has_floodlights and not turf.has_floodlights:
                include = False
            if has_equipment and not turf.has_equipment:
                include = False
            
            # Apply surface type filter
            if surface_type and turf.surface_type != surface_type:
                include = False
            
            # Apply rating filter
            if min_rating and turf.get_average_rating() < min_rating:
                include = False
            
            if include:
                filtered_turfs.append(turf)
        
        # Apply date filter
        if date:
            available_turfs = []
            for turf in filtered_turfs:
                available_slots = turf.get_available_slots(date)
                if available_slots:
                    turf.available_slots = available_slots
                    available_turfs.append(turf)
            filtered_turfs = available_turfs
        
        # Prepare response data
        turfs_data = []
        for turf in filtered_turfs:
            # Get primary image if available
            primary_image = None
            images = turf.images.all()
            if images:
                for img in images:
                    if img.is_primary:
                        primary_image = img
                        break
                if not primary_image:
                    primary_image = images[0]
            
            # Build turf data
            turf_data = {
                'id': turf.id,
                'name': turf.name,
                'address': turf.address,
                'city': turf.city,
                'state': turf.state,
                'country': turf.country,
                'base_price_per_hour': turf.base_price_per_hour,
                'features': turf.features.split(',') if turf.features else [],
                'size': turf.size,
                'indoor': turf.indoor,
                'avg_rating': turf.get_average_rating(),
                'rating_count': turf.get_rating_count(),
                'surface_type': turf.surface_type,
                'has_parking': turf.has_parking,
                'has_changing_room': turf.has_changing_room,
                'has_shower': turf.has_shower,
                'has_floodlights': turf.has_floodlights,
                'has_equipment': turf.has_equipment,
                'image': primary_image.url if primary_image else None
            }
            turfs_data.append(turf_data)
        
        return jsonify({
            'success': True,
            'turfs': turfs_data,
            'count': len(turfs_data)
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error in advanced search: {str(e)}'
        }), 500

# Booking API Endpoints
@mobile_api.route('/booking/create', methods=['POST'])
@token_required
def create_booking(current_user):
    """Create a new booking with optional negotiation"""
    data = request.get_json()
    if not data:
        return jsonify({
            'success': False,
            'message': 'No data provided'
        }), 400
    
    # Extract booking details
    turf_id = data.get('turf_id')
    booking_date = data.get('booking_date')
    time_slot = data.get('time_slot')
    payment_option = data.get('payment_option')
    proposed_price = data.get('proposed_price')
    message = data.get('message')
    
    # Validate required fields
    if not turf_id or not booking_date or not time_slot:
        return jsonify({
            'success': False,
            'message': 'Turf ID, booking date, and time slot are required'
        }), 400
    
    # Check if turf exists
    turf = Turf.query.get(turf_id)
    if not turf:
        return jsonify({
            'success': False,
            'message': 'Turf not found'
        }), 404
    
    # Parse the date
    try:
        date_obj = datetime.datetime.strptime(booking_date, '%Y-%m-%d').date()
    except ValueError:
        return jsonify({
            'success': False,
            'message': 'Invalid date format. Use YYYY-MM-DD'
        }), 400
    
    # Parse time slot to get start and end times
    try:
        time_parts = time_slot.split(' - ')
        start_time_str = time_parts[0]
        end_time_str = time_parts[1]
        start_time = datetime.datetime.strptime(start_time_str, '%H:%M').time()
        end_time = datetime.datetime.strptime(end_time_str, '%H:%M').time()
    except (ValueError, IndexError):
        return jsonify({
            'success': False,
            'message': 'Invalid time slot format. Use HH:MM - HH:MM'
        }), 400
    
    # Calculate price based on turf's base price per hour
    start_datetime = datetime.datetime.combine(date_obj, start_time)
    end_datetime = datetime.datetime.combine(date_obj, end_time)
    duration = (end_datetime - start_datetime).total_seconds() / 3600  # hours
    total_price = turf.base_price_per_hour * duration
    
    # Determine if this is a negotiation or direct booking
    is_negotiation = payment_option == 'negotiation'
    
    # For negotiation, check that proposed price is valid
    if is_negotiation:
        if proposed_price is None or float(proposed_price) <= 0:
            return jsonify({
                'success': False,
                'message': 'Proposed price is required for negotiation and must be greater than 0'
            }), 400
        
        # Set pending negotiation status
        status = BookingStatus.NEGOTIATING
        payment_method = 'pending_negotiation'
    else:
        # Direct booking - use selected payment method
        status = BookingStatus.PAYMENT_PENDING if payment_option == 'pay_online' else BookingStatus.CONFIRMED
        payment_method = payment_option
    
    # Create the booking
    try:
        # Create the booking record
        booking = Booking(
            user_id=current_user.id,
            turf_id=turf_id,
            booking_date=date_obj,
            start_time=start_time,
            end_time=end_time,
            total_price=total_price if not is_negotiation else float(proposed_price),
            original_price=total_price,
            status=status,
            payment_method=payment_method,
            user_proposed_price=float(proposed_price) if is_negotiation else None
        )
        
        db.session.add(booking)
        db.session.flush()  # Get the booking ID without committing
        
        # Create negotiation record if needed
        if is_negotiation:
            negotiation = Negotiation(
                booking_id=booking.id,
                proposed_by='user',
                proposed_price=float(proposed_price),
                message=message or '',
                is_accepted=False
            )
            db.session.add(negotiation)
        
        db.session.commit()
        
        # Prepare the response
        response_data = {
            'success': True,
            'booking': {
                'id': booking.id,
                'turf_id': booking.turf_id,
                'turf_name': turf.name,
                'booking_date': booking_date,
                'time_slot': time_slot,
                'total_price': booking.total_price,
                'status': booking.status,
                'is_negotiation': is_negotiation
            }
        }
        
        # Add payment link if online payment is selected
        if payment_option == 'pay_online' and not is_negotiation:
            # Generate payment URL for Stripe checkout
            # This will use the same payment URL format as our web frontend
            domain = os.environ.get('REPLIT_DEV_DOMAIN', '') 
            if not domain and os.environ.get('REPLIT_DOMAINS'):
                domain = os.environ.get('REPLIT_DOMAINS', '').split(',')[0]
                
            # Absolute URL for the payment page
            response_data['redirect_url'] = f'https://{domain}/payment/checkout/{booking.id}'
        
        if is_negotiation:
            response_data['message'] = 'Your booking with price negotiation has been submitted'
        else:
            response_data['message'] = 'Booking created successfully'
        
        return jsonify(response_data), 201
    
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'message': f'Error creating booking: {str(e)}'
        }), 500

# Owner-specific API endpoints
@mobile_api.route('/owner/turfs', methods=['GET'])
@token_required
def get_owner_turfs(current_user):
    """Get all turfs owned by the current user"""
    # Check if user is an owner
    if current_user.role != UserRole.OWNER and current_user.role != UserRole.ADMIN:
        return jsonify({
            'success': False,
            'message': 'You do not have permission to access owner turfs'
        }), 403
    
    try:
        # Get all turfs owned by the current user
        turfs = Turf.query.filter_by(owner_id=current_user.id).all()
        
        turfs_data = []
        for turf in turfs:
            # Get primary image if available
            primary_image = None
            images = turf.images.all()
            if images:
                for img in images:
                    if img.is_primary:
                        primary_image = img
                        break
                if not primary_image and images:
                    primary_image = images[0]
            
            # Get total bookings count
            total_bookings = Booking.query.filter_by(turf_id=turf.id).count()
            
            # Get bookings waiting payment count
            pending_bookings = Booking.query.filter_by(
                turf_id=turf.id, 
                status=BookingStatus.PAYMENT_PENDING
            ).count()
            
            # Get active negotiations count
            negotiations = Booking.query.filter_by(
                turf_id=turf.id, 
                status=BookingStatus.NEGOTIATING
            ).count()
            
            # Get average rating
            avg_rating = db.session.query(db.func.avg(Review.rating)).filter(
                Review.turf_id == turf.id
            ).scalar() or 0
            
            # Get review count
            review_count = Review.query.filter_by(turf_id=turf.id).count()
            
            # Build turf data
            turf_data = {
                'id': turf.id,
                'name': turf.name,
                'address': turf.address,
                'city': turf.city,
                'base_price_per_hour': float(turf.base_price_per_hour),
                'indoor': turf.indoor,
                'rating': float(avg_rating),
                'review_count': review_count,
                'total_bookings': total_bookings,
                'pending_bookings': pending_bookings,
                'active_negotiations': negotiations,
                'image': primary_image.image_url if primary_image and hasattr(primary_image, 'image_url') else None,
                'created_at': turf.created_at.strftime('%Y-%m-%d') if hasattr(turf, 'created_at') and turf.created_at else None
            }
            turfs_data.append(turf_data)
        
        return jsonify({
            'success': True,
            'turfs': turfs_data
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error fetching owner turfs: {str(e)}'
        }), 500

@mobile_api.route('/owner/analytics', methods=['GET'])
@token_required
def get_owner_analytics(current_user):
    """Get analytics data for owner's turfs"""
    # Check if user is an owner
    if current_user.role != UserRole.OWNER and current_user.role != UserRole.ADMIN:
        return jsonify({
            'success': False,
            'message': 'You do not have permission to access owner analytics'
        }), 403
    
    try:
        # Get turf ID from query params
        turf_id = request.args.get('turf_id', None, type=int)
        
        # Get all turfs owned by the current user
        turfs = Turf.query.filter_by(owner_id=current_user.id).all()
        
        if not turfs:
            return jsonify({
                'success': False,
                'message': 'You need to add a turf before viewing analytics'
            }), 400
        
        # If no turf_id is specified, use the first turf
        if turf_id is None:
            turf_id = turfs[0].id
        
        # Verify that the turf belongs to the current user
        selected_turf = next((t for t in turfs if t.id == turf_id), None)
        if not selected_turf:
            return jsonify({
                'success': False,
                'message': 'Selected turf not found or not owned by you'
            }), 404
        
        # Time periods for analytics
        current_date = datetime.datetime.utcnow().date()
        thirty_days_ago = current_date - datetime.timedelta(days=30)
        ninety_days_ago = current_date - datetime.timedelta(days=90)
        
        # Calculate revenue metrics
        monthly_revenue = db.session.query(db.func.sum(Booking.total_price)).filter(
            Booking.turf_id == selected_turf.id,
            Booking.booking_date >= thirty_days_ago,
            Booking.booking_date <= current_date,
            Booking.status == BookingStatus.COMPLETED,
            Booking.payment_status == 'paid'
        ).scalar() or 0
        
        # Get booking counts
        total_bookings = Booking.query.filter(
            Booking.turf_id == selected_turf.id,
            Booking.status.in_([BookingStatus.CONFIRMED, BookingStatus.COMPLETED])
        ).count()
        
        # Get recent bookings
        recent_bookings = Booking.query.filter(
            Booking.turf_id == selected_turf.id,
            Booking.status.in_([BookingStatus.CONFIRMED, BookingStatus.COMPLETED])
        ).order_by(Booking.created_at.desc()).limit(5).all()
        
        recent_bookings_data = []
        for booking in recent_bookings:
            user = User.query.get(booking.user_id)
            recent_bookings_data.append({
                'id': booking.id,
                'username': user.username,
                'booking_date': booking.booking_date.strftime('%Y-%m-%d'),
                'time_slot': f"{booking.start_time.strftime('%H:%M')} - {booking.end_time.strftime('%H:%M')}",
                'total_price': booking.total_price,
                'status': booking.status,
                'payment_status': booking.payment_status
            })
        
        # Get negotiation data
        negotiation_count = Negotiation.query.join(Booking).filter(
            Booking.turf_id == selected_turf.id
        ).count()
        
        # Calculate average negotiation percentage
        negotiations = Negotiation.query.join(Booking).filter(
            Booking.turf_id == selected_turf.id,
            Negotiation.is_accepted == True
        ).all()
        
        total_negotiation_percentage = 0
        successful_negotiations = 0
        
        for negotiation in negotiations:
            booking = Booking.query.get(negotiation.booking_id)
            if booking and booking.original_price > 0:
                percentage = ((booking.total_price - booking.original_price) / booking.original_price) * 100
                total_negotiation_percentage += percentage
                successful_negotiations += 1
        
        avg_negotiation_percentage = round(total_negotiation_percentage / successful_negotiations, 2) if successful_negotiations > 0 else 0
        
        # Get booking distribution by day of week
        bookings_by_day = {}
        
        days_of_week = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
        
        # Initialize all days with 0 bookings
        for i, day in enumerate(days_of_week):
            bookings_by_day[i] = 0
        
        # Populate with actual booking counts
        bookings_last_90_days = Booking.query.filter(
            Booking.turf_id == selected_turf.id,
            Booking.booking_date >= ninety_days_ago,
            Booking.booking_date <= current_date,
            Booking.status.in_([BookingStatus.CONFIRMED, BookingStatus.COMPLETED])
        ).all()
        
        for booking in bookings_last_90_days:
            # Get day of week as integer (0 = Monday, 6 = Sunday)
            day_of_week = booking.booking_date.weekday()
            bookings_by_day[day_of_week] = bookings_by_day.get(day_of_week, 0) + 1
        
        # Find the most and least popular days
        most_popular_day_index = max(bookings_by_day, key=bookings_by_day.get) if bookings_by_day else 0
        
        # Find the least popular day (excluding days with 0 bookings if possible)
        min_bookings = float('inf')
        least_popular_day_index = 0
        
        for day_index, count in bookings_by_day.items():
            if 0 < count < min_bookings:
                min_bookings = count
                least_popular_day_index = day_index
        
        # If all days have 0 bookings, pick the first day
        if min_bookings == float('inf'):
            least_popular_day_index = 0
            min_bookings = 0
        
        most_popular_day = days_of_week[most_popular_day_index] if bookings_by_day else 'No data'
        least_popular_day = days_of_week[least_popular_day_index] if min_bookings < float('inf') else 'No data'
        
        # Prepare chart data
        chart_data = {
            'bookingsByDay': [bookings_by_day.get(i, 0) for i in range(7)],
            'daysOfWeek': days_of_week
        }
        
        # Different format for JSON serialization
        chart_data_json = {
            'labels': days_of_week,
            'datasets': [{
                'label': 'Bookings',
                'data': [bookings_by_day.get(i, 0) for i in range(7)]
            }]
        }
        
        # Build response
        return jsonify({
            'success': True,
            'turf': {
                'id': selected_turf.id,
                'name': selected_turf.name
            },
            'turfs': [{'id': t.id, 'name': t.name} for t in turfs],
            'analytics': {
                'monthly_revenue': monthly_revenue,
                'total_bookings': total_bookings,
                'negotiation_count': negotiation_count,
                'avg_negotiation_percentage': avg_negotiation_percentage,
                'most_popular_day': most_popular_day,
                'least_popular_day': least_popular_day,
                'chart_data': chart_data_json,
                'recent_bookings': recent_bookings_data
            }
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error fetching analytics: {str(e)}'
        }), 500

@mobile_api.route('/owner/negotiations/respond/<int:booking_id>', methods=['POST'])
@token_required
def owner_respond_to_negotiation(current_user, booking_id):
    """Owner endpoint to respond to a negotiation"""
    # Check if user is an owner
    if current_user.role != UserRole.OWNER and current_user.role != UserRole.ADMIN:
        return jsonify({
            'success': False,
            'message': 'You do not have permission to respond to negotiations'
        }), 403
    
    # Forward to the general respond_to_negotiation function
    return respond_to_negotiation(current_user, booking_id)

# Create direct booking by owner for customers not using the app
@mobile_api.route('/owner/bookings/create', methods=['POST'])
@token_required
def create_owner_booking(current_user):
    """Create a direct booking by owner for customers who are not on the app"""
    # Check if user is an owner
    if current_user.role != UserRole.OWNER and current_user.role != UserRole.ADMIN:
        return jsonify({
            'success': False,
            'message': 'You do not have permission to create owner bookings'
        }), 403
    
    try:
        data = request.get_json()
        if not data:
            return jsonify({
                'success': False,
                'message': 'No data provided'
            }), 400
        
        # Extract booking data
        turf_id = data.get('turf_id')
        customer_name = data.get('customer_name')
        customer_phone = data.get('customer_phone')
        booking_date_str = data.get('booking_date')
        start_time_str = data.get('start_time')
        end_time_str = data.get('end_time')
        total_price = data.get('total_price')
        payment_method = data.get('payment_method', 'pay_on_arrival')
        notes = data.get('notes', '')
        
        # Validate required fields
        if not all([turf_id, customer_name, customer_phone, booking_date_str, start_time_str, end_time_str, total_price]):
            return jsonify({
                'success': False,
                'message': 'Missing required fields'
            }), 400
        
        # Verify turf ownership
        turf = Turf.query.get(turf_id)
        if not turf or turf.owner_id != current_user.id:
            return jsonify({
                'success': False,
                'message': 'Turf not found or not owned by you'
            }), 404
        
        # Parse date and time
        try:
            booking_date = datetime.datetime.strptime(booking_date_str, '%Y-%m-%d').date()
            start_time = datetime.datetime.strptime(start_time_str, '%H:%M').time()
            end_time = datetime.datetime.strptime(end_time_str, '%H:%M').time()
        except ValueError:
            return jsonify({
                'success': False,
                'message': 'Invalid date or time format. Use YYYY-MM-DD for dates and HH:MM for times.'
            }), 400
        
        # Verify that the booking date is not in the past
        if booking_date < datetime.datetime.utcnow().date():
            return jsonify({
                'success': False,
                'message': 'Cannot book for a date in the past'
            }), 400
        
        # Verify that start time is before end time
        if start_time >= end_time:
            return jsonify({
                'success': False,
                'message': 'Start time must be before end time'
            }), 400
        
        # Check availability - verify no overlapping bookings
        existing_bookings = Booking.query.filter(
            Booking.turf_id == turf_id,
            Booking.booking_date == booking_date,
            Booking.status.in_([BookingStatus.CONFIRMED, BookingStatus.PAYMENT_PENDING, BookingStatus.NEGOTIATING]),
            ~((Booking.end_time <= start_time) | (Booking.start_time >= end_time))
        ).all()
        
        if existing_bookings:
            return jsonify({
                'success': False,
                'message': 'Time slot is already booked'
            }), 400
        
        # Create a booking record directly with CONFIRMED status
        # Since this is an owner-created booking, we'll use a placeholder user account or the owner's account
        # In a real-world scenario, you might want to have a "walk-in customer" account
        try:
            # Create a new booking
            booking = Booking(
                turf_id=turf_id,
                user_id=current_user.id,  # Using owner's account as placeholder
                booking_date=booking_date,
                start_time=start_time,
                end_time=end_time,
                total_price=float(total_price),
                original_price=float(total_price),
                status=BookingStatus.CONFIRMED,  # Direct bookings are automatically confirmed
                payment_method=payment_method
            )
            
            # Set payment status based on method
            if payment_method == 'pay_on_arrival':
                booking.payment_status = 'unpaid'
            else:
                booking.payment_status = 'paid'
            
            db.session.add(booking)
            
            # Add a note about this being an owner-created booking for a customer
            note = f"Owner-created booking for {customer_name} (Phone: {customer_phone})"
            if notes:
                note += f". Notes: {notes}"
            
            # Update the database
            db.session.commit()
            
            return jsonify({
                'success': True,
                'message': 'Booking created successfully',
                'booking': {
                    'id': booking.id,
                    'turf_name': turf.name,
                    'booking_date': booking_date_str,
                    'time_slot': f"{start_time_str} - {end_time_str}",
                    'total_price': total_price,
                    'customer_name': customer_name,
                    'customer_phone': customer_phone,
                    'payment_method': payment_method,
                    'status': booking.status
                }
            })
        except Exception as e:
            db.session.rollback()
            return jsonify({
                'success': False,
                'message': f'Error creating booking: {str(e)}'
            }), 500
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error creating owner booking: {str(e)}'
        }), 500

@mobile_api.route('/bookings/user', methods=['GET'])
@mobile_api.route('/user/bookings', methods=['GET'])  # Add the endpoint the mobile app is using
@token_required
def get_user_bookings(current_user):
    """Get all bookings for the current user"""
    try:
        bookings = Booking.query.filter_by(user_id=current_user.id).order_by(Booking.created_at.desc()).all()
        
        bookings_data = []
        for booking in bookings:
            turf = Turf.query.get(booking.turf_id)
            
            # Get latest negotiation if applicable
            latest_negotiation = None
            if booking.status == BookingStatus.NEGOTIATING:
                negotiation = Negotiation.query.filter_by(booking_id=booking.id).order_by(Negotiation.created_at.desc()).first()
                if negotiation:
                    latest_negotiation = {
                        'id': negotiation.id,
                        'proposed_by': negotiation.proposed_by,
                        'proposed_price': negotiation.proposed_price,
                        'message': negotiation.message,
                        'is_accepted': negotiation.is_accepted,
                        'created_at': negotiation.created_at.strftime('%Y-%m-%d %H:%M:%S')
                    }
            
            booking_data = {
                'id': booking.id,
                'turf': {
                    'id': turf.id,
                    'name': turf.name,
                    'address': turf.address,
                    'city': turf.city
                },
                'booking_date': booking.booking_date.strftime('%Y-%m-%d'),
                'time_slot': f"{booking.start_time.strftime('%H:%M')} - {booking.end_time.strftime('%H:%M')}",
                'total_price': booking.total_price,
                'status': booking.status,
                'payment_method': booking.payment_method,
                'created_at': booking.created_at.strftime('%Y-%m-%d %H:%M:%S'),
                'negotiation': latest_negotiation
            }
            
            bookings_data.append(booking_data)
        
        return jsonify({
            'success': True,
            'bookings': bookings_data
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error fetching bookings: {str(e)}'
        }), 500

@mobile_api.route('/booking/<int:booking_id>/cancel', methods=['POST'])
@token_required
def cancel_booking(current_user, booking_id):
    """Cancel a booking"""
    try:
        # Get the booking
        booking = Booking.query.get_or_404(booking_id)
        
        # Check if user owns this booking or is the turf owner
        turf = Turf.query.get(booking.turf_id)
        is_turf_owner = (current_user.id == turf.owner_id)
        is_booking_user = (current_user.id == booking.user_id)
        
        if not (is_turf_owner or is_booking_user):
            return jsonify({
                'success': False,
                'message': 'You do not have permission to cancel this booking'
            }), 403
        
        # Check if booking can be canceled (not completed or already canceled)
        if booking.status in [BookingStatus.COMPLETED, BookingStatus.CANCELLED]:
            return jsonify({
                'success': False,
                'message': f'Booking cannot be canceled (current status: {booking.status})'
            }), 400
        
        # Update booking status to cancelled
        booking.status = BookingStatus.CANCELLED
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Booking cancelled successfully',
            'booking_id': booking_id
        })
    
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'message': f'Error cancelling booking: {str(e)}'
        }), 500

@mobile_api.route('/booking/<int:booking_id>/negotiation', methods=['POST'])
@token_required
def respond_to_negotiation(current_user, booking_id):
    """Submit a counter offer or accept/reject a negotiation"""
    data = request.get_json()
    if not data:
        return jsonify({
            'success': False,
            'message': 'No data provided'
        }), 400
    
    # Extract negotiation data
    action = data.get('action')
    proposed_price = data.get('proposed_price')
    message = data.get('message', '')
    
    if not action:
        return jsonify({
            'success': False,
            'message': 'Action is required (accept, reject, counter)'
        }), 400
    
    # Validate action
    if action not in ['accept', 'reject', 'counter']:
        return jsonify({
            'success': False,
            'message': 'Invalid action. Must be accept, reject, or counter'
        }), 400
    
    # Get the booking
    booking = Booking.query.get(booking_id)
    if not booking:
        return jsonify({
            'success': False,
            'message': 'Booking not found'
        }), 404
    
    # Check if user owns this booking or is the turf owner
    turf = Turf.query.get(booking.turf_id)
    is_turf_owner = (current_user.id == turf.owner_id)
    is_booking_user = (current_user.id == booking.user_id)
    
    if not (is_turf_owner or is_booking_user):
        return jsonify({
            'success': False,
            'message': 'You do not have permission to modify this booking'
        }), 403
    
    # Check if booking is in negotiation status
    if booking.status != BookingStatus.NEGOTIATING:
        return jsonify({
            'success': False,
            'message': 'This booking is not in negotiation status'
        }), 400
    
    # Get the latest negotiation
    latest_negotiation = Negotiation.query.filter_by(booking_id=booking_id).order_by(Negotiation.created_at.desc()).first()
    if not latest_negotiation:
        return jsonify({
            'success': False,
            'message': 'No negotiation found for this booking'
        }), 404
    
    # Check if current user is the correct party to respond
    current_party = 'owner' if is_turf_owner else 'user'
    expected_party = 'owner' if latest_negotiation.proposed_by == 'user' else 'user'
    
    if current_party != expected_party:
        return jsonify({
            'success': False,
            'message': 'It is not your turn to respond to this negotiation'
        }), 403
    
    try:
        if action == 'accept':
            # Accept the negotiation
            latest_negotiation.is_accepted = True
            
            # Update booking status based on payment option
            booking.status = BookingStatus.PAYMENT_PENDING
            booking.total_price = latest_negotiation.proposed_price
            
            # If we need to collect payment, update payment method
            if booking.payment_method == 'pending_negotiation':
                booking.payment_method = 'pay_on_arrival'  # Default to pay on arrival until payment is selected
                
        elif action == 'reject':
            # Reject the negotiation - cancel the booking
            booking.status = BookingStatus.CANCELLED
            
        elif action == 'counter':
            # Submit counter offer
            if proposed_price is None or float(proposed_price) <= 0:
                return jsonify({
                    'success': False,
                    'message': 'Proposed price is required for counter offer and must be greater than 0'
                }), 400
            
            # Create new negotiation record
            negotiation = Negotiation(
                booking_id=booking_id,
                proposed_by=current_party,
                proposed_price=float(proposed_price),
                message=message,
                is_accepted=False
            )
            db.session.add(negotiation)
        
        db.session.commit()
        
        # Prepare response message
        if action == 'accept':
            message = 'Negotiation accepted'
        elif action == 'reject':
            message = 'Negotiation rejected and booking cancelled'
        else:
            message = 'Counter offer submitted'
        
        # Get updated booking details to return
        # Prepare booking for API response
        turf = Turf.query.get(booking.turf_id)
        
        # Get latest negotiation if applicable
        latest_negotiation = None
        proposed_price = None
        negotiation_message = None
        
        if booking.status == BookingStatus.NEGOTIATING:
            negotiation = Negotiation.query.filter_by(booking_id=booking.id).order_by(Negotiation.created_at.desc()).first()
            if negotiation:
                latest_negotiation = {
                    'id': negotiation.id,
                    'proposed_by': negotiation.proposed_by,
                    'proposed_price': negotiation.proposed_price,
                    'message': negotiation.message,
                    'is_accepted': negotiation.is_accepted,
                    'created_at': negotiation.created_at.strftime('%Y-%m-%d %H:%M:%S')
                }
                proposed_price = negotiation.proposed_price
                negotiation_message = negotiation.message
        
        # Get first image URL if available
        image_url = ""
        turf_image = TurfImage.query.filter_by(turf_id=turf.id).first()
        if turf_image:
            image_url = turf_image.image_url
            
        updated_booking = {
            'id': booking.id,
            'user_id': booking.user_id,
            'turf_id': booking.turf_id,
            'turf_name': turf.name,
            'turf_image_url': image_url,
            'booking_date': booking.booking_date.strftime('%Y-%m-%d'),
            'start_time': booking.start_time.strftime('%H:%M'),
            'end_time': booking.end_time.strftime('%H:%M'),
            'price': float(booking.total_price),
            'status': booking.status,
            'payment_method': booking.payment_method,
            'is_paid': booking.is_paid,
            'is_negotiable': booking.is_negotiable,
            'proposed_price': proposed_price,
            'message': negotiation_message,
            'created_at': booking.created_at.strftime('%Y-%m-%d %H:%M:%S'),
            'negotiation': latest_negotiation
        }
        
        return jsonify({
            'success': True,
            'message': message,
            'action': action,
            'booking_id': booking_id,
            'booking': updated_booking
        })
    
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'message': f'Error processing negotiation: {str(e)}'
        }), 500

@mobile_api.route('/bookings/owner', methods=['GET'])
@mobile_api.route('/owner/bookings', methods=['GET'])  # Add the endpoint the mobile app is using
@token_required
def get_owner_bookings(current_user):
    """Get all bookings for turfs owned by the current user"""
    # Check if user is an owner
    if current_user.role != UserRole.OWNER and current_user.role != UserRole.ADMIN:
        return jsonify({
            'success': False,
            'message': 'You do not have permission to view owner bookings'
        }), 403
    
    try:
        # Get all turfs owned by the user
        turfs = Turf.query.filter_by(owner_id=current_user.id).all()
        turf_ids = [turf.id for turf in turfs]
        
        if not turf_ids:
            return jsonify({
                'success': True,
                'bookings': []
            })
        
        # Get all bookings for these turfs
        bookings = Booking.query.filter(Booking.turf_id.in_(turf_ids)).order_by(Booking.created_at.desc()).all()
        
        bookings_data = []
        for booking in bookings:
            turf = Turf.query.get(booking.turf_id)
            user = User.query.get(booking.user_id)
            
            # Get latest negotiation if applicable
            latest_negotiation = None
            if booking.status == BookingStatus.NEGOTIATING:
                negotiation = Negotiation.query.filter_by(booking_id=booking.id).order_by(Negotiation.created_at.desc()).first()
                if negotiation:
                    latest_negotiation = {
                        'id': negotiation.id,
                        'proposed_by': negotiation.proposed_by,
                        'proposed_price': negotiation.proposed_price,
                        'message': negotiation.message,
                        'is_accepted': negotiation.is_accepted,
                        'created_at': negotiation.created_at.strftime('%Y-%m-%d %H:%M:%S')
                    }
            
            booking_data = {
                'id': booking.id,
                'turf': {
                    'id': turf.id,
                    'name': turf.name,
                },
                'user': {
                    'id': user.id,
                    'username': user.username,
                    'phone_number': user.phone_number
                },
                'booking_date': booking.booking_date.strftime('%Y-%m-%d'),
                'time_slot': f"{booking.start_time.strftime('%H:%M')} - {booking.end_time.strftime('%H:%M')}",
                'total_price': booking.total_price,
                'status': booking.status,
                'payment_method': booking.payment_method,
                'created_at': booking.created_at.strftime('%Y-%m-%d %H:%M:%S'),
                'negotiation': latest_negotiation
            }
            
            bookings_data.append(booking_data)
        
        return jsonify({
            'success': True,
            'bookings': bookings_data
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error fetching owner bookings: {str(e)}'
        }), 500

# Reviews API Endpoints
@mobile_api.route('/turf/<int:turf_id>/reviews', methods=['GET'])
def get_turf_reviews(turf_id):
    """Get all reviews for a turf"""
    turf = Turf.query.get_or_404(turf_id)
    reviews = Review.query.filter_by(turf_id=turf_id).order_by(Review.created_at.desc()).all()
    
    reviews_data = []
    for review in reviews:
        user = User.query.get(review.user_id)
        reviews_data.append({
            'id': review.id,
            'rating': review.rating,
            'comment': review.comment,
            'created_at': review.created_at.strftime('%Y-%m-%d %H:%M:%S'),
            'user': {
                'id': user.id,
                'username': user.username
            },
            'owner_response': review.owner_response
        })
    
    return jsonify({
        'success': True,
        'turf_name': turf.name,
        'reviews': reviews_data,
        'avg_rating': turf.get_average_rating(),
        'review_count': turf.get_rating_count()
    })

@mobile_api.route('/turf/<int:turf_id>/can_review', methods=['GET'])
@token_required
def can_review_turf(current_user, turf_id):
    """Check if user can review a turf (must have completed booking)"""
    # Check if user has a completed booking for this turf
    completed_bookings = Booking.query.filter_by(
        user_id=current_user.id, 
        turf_id=turf_id,
        status=BookingStatus.COMPLETED
    ).count()
    
    # Check if user already reviewed this turf
    existing_review = Review.query.filter_by(
        user_id=current_user.id,
        turf_id=turf_id
    ).first()
    
    return jsonify({
        'success': True,
        'can_review': completed_bookings > 0 and not existing_review,
        'has_booking': completed_bookings > 0,
        'already_reviewed': existing_review is not None
    })

@mobile_api.route('/turf/<int:turf_id>/review', methods=['POST'])
@token_required
def submit_review(current_user, turf_id):
    """Submit a review for a turf"""
    data = request.get_json()
    if not data:
        return jsonify({
            'success': False,
            'message': 'No data provided'
        }), 400
        
    rating = data.get('rating')
    comment = data.get('comment', '')
    
    if not rating or not isinstance(rating, int) or rating < 1 or rating > 5:
        return jsonify({
            'success': False,
            'message': 'Valid rating (1-5) is required'
        }), 400
    
    # Check if user can review this turf
    completed_bookings = Booking.query.filter_by(
        user_id=current_user.id, 
        turf_id=turf_id,
        status=BookingStatus.COMPLETED
    ).count()
    
    if completed_bookings == 0:
        return jsonify({
            'success': False,
            'message': 'You can only review turfs where you have completed a booking'
        }), 403
    
    # Check if user already reviewed this turf
    existing_review = Review.query.filter_by(
        user_id=current_user.id,
        turf_id=turf_id
    ).first()
    
    if existing_review:
        return jsonify({
            'success': False,
            'message': 'You have already reviewed this turf'
        }), 400
    
    # Create and save the review
    try:
        review = Review(
            user_id=current_user.id,
            turf_id=turf_id,
            rating=rating,
            comment=comment
        )
        
        db.session.add(review)
        
        # No need to manually update average rating
        # It's calculated on-the-fly by the get_average_rating() method
        turf = Turf.query.get(turf_id)
        
        db.session.commit()
        
        return jsonify({
            'success': True,
            'message': 'Review submitted successfully',
            'review': {
                'id': review.id,
                'rating': review.rating,
                'comment': review.comment,
                'created_at': review.created_at.strftime('%Y-%m-%d %H:%M:%S')
            }
        }), 201
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'message': f'Failed to submit review: {str(e)}'
        }), 500

@mobile_api.route('/user/profile', methods=['GET'])
@token_required
def get_user_profile(current_user):
    """Get the current user's profile information"""
    try:
        user_data = {
            'id': current_user.id,
            'username': current_user.username,
            'email': current_user.email,
            'phone_number': current_user.phone_number,
            'role': current_user.role,
            'created_at': current_user.created_at.strftime('%Y-%m-%d %H:%M:%S')
        }
        
        return jsonify({
            'success': True,
            'data': user_data
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'message': f'Error getting user profile: {str(e)}'
        }), 500

@mobile_api.route('/user/profile', methods=['PUT'])
@token_required
def update_user_profile(current_user):
    """Update the current user's profile information"""
    data = request.get_json()
    if not data:
        return jsonify({
            'success': False,
            'message': 'No data provided'
        }), 400
    
    username = data.get('username')
    phone_number = data.get('phone_number')
    current_password = data.get('current_password')
    new_password = data.get('new_password')
    
    if not username:
        return jsonify({
            'success': False,
            'message': 'Username is required'
        }), 400
    
    if not phone_number:
        return jsonify({
            'success': False,
            'message': 'Phone number is required'
        }), 400
    
    try:
        # Check if username is taken by another user
        existing_user = User.query.filter(User.username == username, User.id != current_user.id).first()
        if existing_user:
            return jsonify({
                'success': False,
                'message': 'Username is already taken'
            }), 400
        
        # Update basic info
        current_user.username = username
        current_user.phone_number = phone_number
        
        # Update password if provided
        if current_password and new_password:
            if not current_user.check_password(current_password):
                return jsonify({
                    'success': False,
                    'message': 'Current password is incorrect'
                }), 400
            
            current_user.set_password(new_password)
        
        db.session.commit()
        
        # Return updated user data
        user_data = {
            'id': current_user.id,
            'username': current_user.username,
            'email': current_user.email,
            'phone_number': current_user.phone_number,
            'role': current_user.role,
            'created_at': current_user.created_at.strftime('%Y-%m-%d %H:%M:%S')
        }
        
        return jsonify({
            'success': True,
            'message': 'Profile updated successfully',
            'data': user_data
        })
    except Exception as e:
        db.session.rollback()
        return jsonify({
            'success': False,
            'message': f'Error updating profile: {str(e)}'
        }), 500

@mobile_api.route('/user/reviews', methods=['GET'])
@token_required
def get_user_reviews(current_user):
    """Get all reviews submitted by the authenticated user"""
    reviews = Review.query.filter_by(user_id=current_user.id).order_by(Review.created_at.desc()).all()
    
    reviews_data = []
    for review in reviews:
        turf = Turf.query.get(review.turf_id)
        # Get first image URL if available
        image_url = None
        turf_image = TurfImage.query.filter_by(turf_id=turf.id).first()
        if turf_image:
            image_url = turf_image.image_url
            
        reviews_data.append({
            'id': review.id,
            'rating': review.rating,
            'comment': review.comment,
            'created_at': review.created_at.strftime('%Y-%m-%d %H:%M:%S'),
            'turf': {
                'id': turf.id,
                'name': turf.name,
                'image_url': image_url
            },
            'owner_response': review.owner_response
        })
    
    return jsonify({
        'success': True,
        'reviews': reviews_data
    })