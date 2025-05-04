import os
import logging

from flask import Flask, request, Blueprint, jsonify, render_template
from flask_sqlalchemy import SQLAlchemy
from sqlalchemy.orm import DeclarativeBase
from werkzeug.middleware.proxy_fix import ProxyFix
from flask_login import LoginManager
from flask_cors import CORS
import stripe


class Base(DeclarativeBase):
    pass


# Set up logging
logging.basicConfig(level=logging.DEBUG)

# Initialize SQLAlchemy with custom model class
db = SQLAlchemy(model_class=Base)

# Create Flask app
app = Flask(__name__)
app.secret_key = os.environ.get("SESSION_SECRET", os.urandom(24))
app.wsgi_app = ProxyFix(app.wsgi_app, x_proto=1, x_host=1)  # needed for url_for to generate with https

# Enable CORS for all routes and origins
CORS(app, resources={r"/*": {"origins": "*"}}, supports_credentials=True)

# Add hasattr to Jinja environment
app.jinja_env.globals.update(hasattr=hasattr)

# Configure the database using environment variables
app.config["SQLALCHEMY_DATABASE_URI"] = os.environ.get("DATABASE_URL")
app.config["SQLALCHEMY_ENGINE_OPTIONS"] = {
    "pool_recycle": 300,
    "pool_pre_ping": True,
}
app.config["SQLALCHEMY_TRACK_MODIFICATIONS"] = False

# Configure CSRF protection
from flask_wtf.csrf import CSRFProtect, CSRFError

csrf = CSRFProtect()
csrf.init_app(app)

# Handle CSRF errors
@app.errorhandler(CSRFError)
def handle_csrf_error(e):
    if request.path.startswith('/api/mobile/') or request.path.startswith('/auth/api/'):
        # For API requests, return JSON error
        return jsonify({'success': False, 'message': 'CSRF token is missing or invalid'}), 400
    # For regular web requests, render error template
    return render_template('error.html', message='CSRF token is missing or invalid'), 400

# Exempt all API routes from CSRF protection
@app.before_request
def csrf_exempt_api_routes():
    if request.path.startswith('/api/mobile/') or request.path.startswith('/auth/api/'):
        csrf.exempt(request.endpoint)

# Initialize database with app
db.init_app(app)

# Set up login manager
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'auth.login'
login_manager.login_message_category = 'info'

# Set up Stripe
stripe.api_key = os.environ.get('STRIPE_SECRET_KEY', 'sk_test_placeholder')

with app.app_context():
    # Import models and create tables
    import models  # noqa: F401
    db.create_all()
    
    # Import routes
    from routes.auth import auth
    from routes.user import user
    from routes.owner import owner
    from routes.admin import admin
    from routes.booking import booking
    from routes.payment import payment
    from routes.home import home
    from routes.reviews import reviews_bp
    from routes.favorites import favorites
    from routes.notifications import notifications
    from routes.mobile_api import mobile_api
    
    # Register blueprints
    app.register_blueprint(auth, url_prefix='/auth')
    app.register_blueprint(user, url_prefix='/user')
    app.register_blueprint(owner, url_prefix='/owner')
    app.register_blueprint(admin, url_prefix='/admin')
    app.register_blueprint(booking, url_prefix='/bookings')
    app.register_blueprint(payment, url_prefix='/payment')
    app.register_blueprint(reviews_bp, url_prefix='/reviews')
    app.register_blueprint(favorites)  
    app.register_blueprint(notifications)
    app.register_blueprint(home)
    
    # Register mobile API blueprint with CSRF exemption
    csrf.exempt(mobile_api)
    app.register_blueprint(mobile_api, url_prefix='/api/mobile')
    
    # API endpoint for time slots directly from app - needed for mobile app
    @app.route('/api/turf/<int:turf_id>/time_slots', methods=['GET'])
    @csrf.exempt
    def api_time_slots(turf_id):
        """API endpoint to get available time slots for a turf on a specific date"""
        from models import Turf
        date_str = request.args.get('date')
        
        if not date_str:
            return jsonify({
                'success': False,
                'error': 'Date is a required parameter'
            }), 400
        
        try:
            from datetime import datetime
            date_obj = datetime.strptime(date_str, '%Y-%m-%d').date()
        except ValueError:
            return jsonify({
                'success': False,
                'error': 'Invalid date format. Use YYYY-MM-DD'
            }), 400
        
        turf = Turf.query.get_or_404(turf_id)
        
        # Get available time slots
        available_slots = turf.get_available_slots(date_obj)
        
        # Format the slots for JSON response
        formatted_slots = []
        for slot in available_slots:
            formatted_slots.append({
                'id': slot.id,
                'day_of_week': slot.day_of_week,
                'start_time': slot.start_time.strftime('%H:%M'),
                'end_time': slot.end_time.strftime('%H:%M'),
                'value': f"{slot.start_time.strftime('%H:%M')} - {slot.end_time.strftime('%H:%M')}",
                'text': f"{slot.start_time.strftime('%I:%M %p')} - {slot.end_time.strftime('%I:%M %p')}",
                'price_adjustment': slot.price_adjustment
            })
        
        return jsonify({
            'success': True,
            'turf_id': turf_id,
            'date': date_str,
            'time_slots': formatted_slots
        })
    
    # User loader for Flask-Login
    @login_manager.user_loader
    def load_user(user_id):
        from models import User
        return User.query.get(int(user_id))

