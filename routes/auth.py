from flask import Blueprint, render_template, redirect, url_for, flash, request, jsonify
from flask_login import login_user, current_user, logout_user, login_required
from werkzeug.security import generate_password_hash
import jwt
from datetime import datetime, timedelta
from functools import wraps
import os

from app import db
from models import User, UserRole
from forms import LoginForm, RegisterForm, RegisterOwnerForm

auth = Blueprint('auth', __name__)

@auth.route('/login', methods=['GET', 'POST'])
def login():
    if current_user.is_authenticated:
        return redirect(url_for('user.dashboard'))
    
    form = LoginForm()
    if form.validate_on_submit():
        user = User.query.filter_by(email=form.email.data).first()
        if user and user.check_password(form.password.data):
            login_user(user, remember=form.remember.data)
            next_page = request.args.get('next')
            
            # Redirect based on user role
            if not next_page or next_page == '/':
                if user.role == UserRole.ADMIN:
                    next_page = url_for('admin.dashboard')
                elif user.role == UserRole.OWNER:
                    next_page = url_for('owner.dashboard')
                else:
                    next_page = url_for('user.dashboard')
            
            return redirect(next_page)
        else:
            flash('Login unsuccessful. Please check email and password.', 'danger')
    
    return render_template('auth/login.html', form=form, title='Login')

@auth.route('/register', methods=['GET', 'POST'])
def register():
    if current_user.is_authenticated:
        return redirect(url_for('user.dashboard'))
    
    form = RegisterForm()
    if form.validate_on_submit():
        user = User(
            username=form.username.data,
            email=form.email.data,
            phone_number=form.phone_number.data,
            role=UserRole.USER
        )
        user.set_password(form.password.data)
        
        db.session.add(user)
        db.session.commit()
        
        flash('Your account has been created! You can now log in.', 'success')
        return redirect(url_for('auth.login'))
    
    return render_template('auth/register.html', form=form, title='Register')

@auth.route('/register/owner', methods=['GET', 'POST'])
def register_owner():
    if current_user.is_authenticated:
        return redirect(url_for('user.dashboard'))
    
    form = RegisterOwnerForm()
    if form.validate_on_submit():
        user = User(
            username=form.username.data,
            email=form.email.data,
            phone_number=form.phone_number.data,
            role=UserRole.OWNER
        )
        user.set_password(form.password.data)
        
        db.session.add(user)
        db.session.commit()
        
        flash('Your turf owner account has been created! You can now log in.', 'success')
        return redirect(url_for('auth.login'))
    
    return render_template('auth/register.html', form=form, title='Register as Turf Owner', is_owner=True)

@auth.route('/logout')
def logout():
    logout_user()
    return redirect(url_for('auth.login'))

# JWT Secret Key
JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY', 'dev-secret-key')
JWT_EXPIRATION = 7  # days

def generate_token(user_id):
    """Generate a JWT token for the user"""
    payload = {
        'sub': user_id,
        'iat': datetime.utcnow(),
        'exp': datetime.utcnow() + timedelta(days=JWT_EXPIRATION)
    }
    return jwt.encode(payload, JWT_SECRET_KEY, algorithm='HS256')

def token_required(f):
    """Decorator to protect API routes with JWT token authentication"""
    @wraps(f)
    def decorated(*args, **kwargs):
        token = None
        
        # Get token from authorization header
        auth_header = request.headers.get('Authorization')
        if auth_header and auth_header.startswith('Bearer '):
            token = auth_header.split(' ')[1]
        
        if not token:
            return jsonify({
                'success': False,
                'message': 'Authentication token is missing'
            }), 401
        
        try:
            # Decode token
            payload = jwt.decode(token, JWT_SECRET_KEY, algorithms=['HS256'])
            user_id = payload['sub']
            
            # Get user from database
            user = User.query.get(user_id)
            if not user:
                return jsonify({
                    'success': False,
                    'message': 'Invalid user'
                }), 401
                
        except jwt.ExpiredSignatureError:
            return jsonify({
                'success': False,
                'message': 'Authentication token has expired'
            }), 401
        except jwt.InvalidTokenError:
            return jsonify({
                'success': False,
                'message': 'Invalid authentication token'
            }), 401
        
        # Pass user to decorated function
        return f(user, *args, **kwargs)
    
    return decorated

# API Routes for Mobile App Authentication
@auth.route('/api/login', methods=['POST'])
def api_login():
    """API endpoint for mobile app login - CSRF exempt"""
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

@auth.route('/api/register', methods=['POST'])
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

@auth.route('/api/verify_token', methods=['GET'])
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
