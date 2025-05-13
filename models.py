from app import db
from datetime import datetime
from flask_login import UserMixin
from werkzeug.security import generate_password_hash, check_password_hash

# Define user roles
class UserRole:
    USER = 'user'  # Regular user/player
    OWNER = 'owner'  # Turf owner
    ADMIN = 'admin'  # Admin
    
# Define notification types
class NotificationType:
    BOOKING_REMINDER = 'booking_reminder'
    BOOKING_CONFIRMED = 'booking_confirmed'
    BOOKING_CANCELLED = 'booking_cancelled'
    BOOKING_AUTO_APPROVED = 'booking_auto_approved'
    PAYMENT_SUCCESS = 'payment_success'
    PAYMENT_FAILED = 'payment_failed'
    PRICE_NEGOTIATION = 'price_negotiation'
    NEW_REVIEW = 'new_review'
    TURF_FEATURED = 'turf_featured'
    DISPUTE_UPDATE = 'dispute_update'

# Define booking status constants
class BookingStatus:
    PENDING = 'pending'  # Initial request
    NEGOTIATING = 'negotiating'  # Price negotiation in progress
    PAYMENT_PENDING = 'payment_pending'  # Payment needs to be completed
    CONFIRMED = 'confirmed'  # Booking confirmed
    CANCELLED = 'cancelled'  # Booking cancelled
    COMPLETED = 'completed'  # Booking completed

class User(UserMixin, db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(64), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(256), nullable=False)
    phone_number = db.Column(db.String(20), nullable=True)
    role = db.Column(db.String(20), nullable=False, default=UserRole.USER)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Relationships
    bookings = db.relationship('Booking', backref='user', lazy='dynamic')
    turfs = db.relationship('Turf', backref='owner', lazy='dynamic')
    
    def set_password(self, password):
        self.password_hash = generate_password_hash(password)
    
    def check_password(self, password):
        return check_password_hash(self.password_hash, password)
    
    def is_owner(self):
        return self.role == UserRole.OWNER
    
    def is_admin(self):
        return self.role == UserRole.ADMIN


class Turf(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text, nullable=True)
    address = db.Column(db.String(200), nullable=False)
    city = db.Column(db.String(100), nullable=False)
    state = db.Column(db.String(100), nullable=False)
    country = db.Column(db.String(100), nullable=False)
    postal_code = db.Column(db.String(20), nullable=False)
    latitude = db.Column(db.Float, nullable=True)
    longitude = db.Column(db.Float, nullable=True)
    base_price_per_hour = db.Column(db.Float, nullable=False)
    features = db.Column(db.Text, nullable=True)  # Comma-separated list of features
    size = db.Column(db.String(50), nullable=True)  # 5-a-side, 7-a-side, etc.
    indoor = db.Column(db.Boolean, default=False)
    active = db.Column(db.Boolean, default=True)
    auto_approve_bookings = db.Column(db.Boolean, default=False)  # Automatically approve bookings if set to True
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Foreign keys
    owner_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    
    # Relationships
    images = db.relationship('TurfImage', backref='turf', lazy='dynamic')
    time_slots = db.relationship('TimeSlot', backref='turf', lazy='dynamic')
    bookings = db.relationship('Booking', backref='turf', lazy='dynamic')
    
    @property
    def has_parking(self):
        return self.has_feature('parking')
        
    @property
    def has_changing_room(self):
        return self.has_feature('changing_room')
        
    @property
    def has_shower(self):
        return self.has_feature('shower')
        
    @property
    def has_floodlights(self):
        return self.has_feature('floodlights')
        
    @property
    def has_equipment(self):
        return self.has_feature('equipment')
        
    @property
    def has_refreshments(self):
        return self.has_feature('refreshments')
        
    @property
    def surface_type(self):
        if self.features:
            features_list = self.features.lower().split(',')
            for surface in ['grass', 'artificial', 'indoor', 'clay', 'concrete']:
                if surface in features_list:
                    return surface
        return None
        
    def has_feature(self, feature_name):
        if not self.features:
            return False
        return feature_name.lower() in [f.strip().lower() for f in self.features.split(',')]


class TurfImage(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    url = db.Column(db.String(255), nullable=False)
    is_primary = db.Column(db.Boolean, default=False)
    turf_id = db.Column(db.Integer, db.ForeignKey('turf.id'), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)


class TimeSlot(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    day_of_week = db.Column(db.Integer, nullable=False)  # 0=Monday, 6=Sunday
    start_time = db.Column(db.Time, nullable=False)
    end_time = db.Column(db.Time, nullable=False)
    price_adjustment = db.Column(db.Float, default=0.0)  # +/- percentage adjustment to base price
    turf_id = db.Column(db.Integer, db.ForeignKey('turf.id'), nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)


class Booking(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    booking_date = db.Column(db.Date, nullable=False)
    start_time = db.Column(db.Time, nullable=False)
    end_time = db.Column(db.Time, nullable=False)
    total_price = db.Column(db.Float, nullable=False)
    original_price = db.Column(db.Float, nullable=False)  # Before negotiation
    user_proposed_price = db.Column(db.Float, nullable=True)  # User's proposed price
    status = db.Column(db.String(20), nullable=False, default=BookingStatus.PENDING)
    payment_status = db.Column(db.String(20), nullable=False, default='unpaid')
    payment_method = db.Column(db.String(20), nullable=False, default='pay_online')  # 'pay_online' or 'pay_on_arrival'
    payment_id = db.Column(db.String(100), nullable=True)  # External payment reference
    notes = db.Column(db.Text, nullable=True)  # Additional notes for the booking
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Foreign keys
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    turf_id = db.Column(db.Integer, db.ForeignKey('turf.id'), nullable=False)
    
    # Relationships
    negotiations = db.relationship('Negotiation', backref='booking', lazy='dynamic')


class Negotiation(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    proposed_price = db.Column(db.Float, nullable=False)
    counter_price = db.Column(db.Float, nullable=True)
    is_accepted = db.Column(db.Boolean, nullable=True)  # None=pending, True=accepted, False=rejected
    proposed_by = db.Column(db.String(20), nullable=False)  # 'user' or 'owner'
    message = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Foreign keys
    booking_id = db.Column(db.Integer, db.ForeignKey('booking.id'), nullable=False)


class Dispute(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    title = db.Column(db.String(100), nullable=False)
    description = db.Column(db.Text, nullable=False)
    status = db.Column(db.String(20), nullable=False, default='open')  # open, in_progress, resolved, closed
    resolution = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    resolved_at = db.Column(db.DateTime, nullable=True)
    
    # Foreign keys
    booking_id = db.Column(db.Integer, db.ForeignKey('booking.id'), nullable=False)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    
    # Relationships
    booking = db.relationship('Booking', backref='disputes')
    user = db.relationship('User', backref='disputes')


class Review(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    rating = db.Column(db.Integer, nullable=False)  # 1-5 star rating
    comment = db.Column(db.Text, nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Foreign keys
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    turf_id = db.Column(db.Integer, db.ForeignKey('turf.id'), nullable=False)
    booking_id = db.Column(db.Integer, db.ForeignKey('booking.id'), nullable=True)  # Optional, link to specific booking
    
    # Relationships
    user = db.relationship('User', backref=db.backref('reviews', lazy='dynamic'))
    turf = db.relationship('Turf', backref=db.backref('reviews', lazy='dynamic'))
    
    # Optional owner response
    owner_response = db.Column(db.Text, nullable=True)
    owner_response_date = db.Column(db.DateTime, nullable=True)


class Favorite(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Foreign keys
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    turf_id = db.Column(db.Integer, db.ForeignKey('turf.id'), nullable=False)
    
    # Relationships
    user = db.relationship('User', backref=db.backref('favorites', lazy='dynamic'))
    turf = db.relationship('Turf', backref=db.backref('favorited_by', lazy='dynamic'))
    
    # Enforce uniqueness - a user can favorite a turf only once
    __table_args__ = (db.UniqueConstraint('user_id', 'turf_id', name='unique_user_turf_favorite'),)


class Notification(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    type = db.Column(db.String(50), nullable=False)  # Use values from NotificationType
    title = db.Column(db.String(100), nullable=False)
    message = db.Column(db.Text, nullable=False)
    read = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Foreign keys
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    
    # Optional related entity keys (nullable)
    booking_id = db.Column(db.Integer, db.ForeignKey('booking.id'), nullable=True)
    turf_id = db.Column(db.Integer, db.ForeignKey('turf.id'), nullable=True)
    review_id = db.Column(db.Integer, db.ForeignKey('review.id'), nullable=True)
    
    # Relationships
    user = db.relationship('User', backref=db.backref('notifications', lazy='dynamic'))
    booking = db.relationship('Booking', backref=db.backref('notifications', lazy='dynamic'))
    turf = db.relationship('Turf', backref=db.backref('notifications', lazy='dynamic'))
    review = db.relationship('Review', backref=db.backref('notifications', lazy='dynamic'))
    
    
class NotificationSetting(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    email_booking_confirmation = db.Column(db.Boolean, default=True)
    email_booking_reminder = db.Column(db.Boolean, default=True)
    sms_booking_reminder = db.Column(db.Boolean, default=False)
    email_price_negotiation = db.Column(db.Boolean, default=True)
    email_turf_promotions = db.Column(db.Boolean, default=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)
    
    # Foreign keys
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False, unique=True)
    
    # Relationships
    user = db.relationship('User', backref=db.backref('notification_settings', uselist=False))