from flask import Blueprint, request, jsonify
import jwt
import datetime
import os
from werkzeug.security import check_password_hash
from functools import wraps

from models import User, UserRole, Turf, Review, TimeSlot, Booking, BookingStatus, TurfImage
from app import db

# Create a blueprint for all mobile API routes
mobile_api = Blueprint('mobile_api', __name__)

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

@mobile_api.route('/turf/<int:turf_id>/time_slots', methods=['GET'])
def get_available_time_slots(turf_id):
    """Get available time slots for a specific turf on a given date"""
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
        
        # If no time slots are available for the date, provide dummy slots
        if not time_slots:
            # Create some sample time slots
            dummy_slots = [
                "09:00 - 10:00",
                "10:00 - 11:00",
                "11:00 - 12:00",
                "14:00 - 15:00",
                "15:00 - 16:00",
                "16:00 - 17:00",
                "17:00 - 18:00",
                "18:00 - 19:00"
            ]
            return jsonify({
                'success': True,
                'time_slots': dummy_slots
            })
        
        # Format the time slots
        formatted_slots = []
        for slot in time_slots:
            start = slot.start_time.strftime('%H:%M')
            end = slot.end_time.strftime('%H:%M')
            formatted_slots.append(f"{start} - {end}")
        
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