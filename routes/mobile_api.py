from flask import Blueprint, request, jsonify
import jwt
import datetime
import os
from werkzeug.security import check_password_hash
from functools import wraps

from models import User, UserRole, Turf, Review, TimeSlot, Booking, BookingStatus
from app import db

# Create a blueprint for all mobile API routes
mobile_api = Blueprint('mobile_api', __name__)

# JWT Configuration
JWT_SECRET = os.environ.get('JWT_SECRET', 'turf-booking-jwt-secret')
JWT_EXPIRATION = datetime.timedelta(days=7)

# Authentication helper functions
def generate_token(user_id):
    """Generate a JWT token for the user"""
    payload = {
        'exp': datetime.datetime.utcnow() + JWT_EXPIRATION,
        'iat': datetime.datetime.utcnow(),
        'sub': user_id
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
            user = User.query.get(payload['sub'])
            
            if not user:
                return jsonify({
                    'success': False,
                    'message': 'Invalid token'
                }), 401
                
        except jwt.ExpiredSignatureError:
            return jsonify({
                'success': False,
                'message': 'Token has expired'
            }), 401
        except jwt.InvalidTokenError:
            return jsonify({
                'success': False,
                'message': 'Invalid token'
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
        'avg_rating': turf.avg_rating
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
        
        # Update turf's average rating
        turf = Turf.query.get(turf_id)
        all_reviews = Review.query.filter_by(turf_id=turf_id).all()
        total_rating = sum([r.rating for r in all_reviews]) + rating
        turf.avg_rating = total_rating / (len(all_reviews) + 1)
        
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
        reviews_data.append({
            'id': review.id,
            'rating': review.rating,
            'comment': review.comment,
            'created_at': review.created_at.strftime('%Y-%m-%d %H:%M:%S'),
            'turf': {
                'id': turf.id,
                'name': turf.name,
                'image_url': turf.image_url
            },
            'owner_response': review.owner_response
        })
    
    return jsonify({
        'success': True,
        'reviews': reviews_data
    })