from datetime import datetime
from app import db
from flask_login import UserMixin
from werkzeug.security import generate_password_hash, check_password_hash
from sqlalchemy.ext.associationproxy import association_proxy

# Define user roles
class UserRole:
    USER = 'user'  # Regular user/player
    OWNER = 'owner'  # Turf owner
    ADMIN = 'admin'  # Admin


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
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    
    # Advanced filtering amenities
    has_parking = db.Column(db.Boolean, default=False)
    has_changing_room = db.Column(db.Boolean, default=False)
    has_shower = db.Column(db.Boolean, default=False)
    has_floodlights = db.Column(db.Boolean, default=False)
    has_equipment = db.Column(db.Boolean, default=False)
    has_refreshments = db.Column(db.Boolean, default=False)
    surface_type = db.Column(db.String(50), nullable=True)  # grass, artificial, indoor, etc.
    
    # Foreign keys
    owner_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False)
    
    # Relationships
    images = db.relationship('TurfImage', backref='turf', lazy='dynamic')
    time_slots = db.relationship('TimeSlot', backref='turf', lazy='dynamic')
    bookings = db.relationship('Booking', backref='turf', lazy='dynamic')
    
    def get_available_slots(self, date):
        """Get available time slots for a specific date"""
        slots = TimeSlot.query.filter_by(turf_id=self.id, day_of_week=date.weekday()).all()
        booked_slots = Booking.query.filter_by(
            turf_id=self.id,
            booking_date=date,
            status=BookingStatus.CONFIRMED
        ).all()
        
        # Create a list of booked time ranges
        booked_times = []
        for booking in booked_slots:
            booked_times.append((booking.start_time, booking.end_time))
        
        available_slots = []
        for slot in slots:
            # Check if the slot overlaps with any booking
            is_available = True
            for booked_start, booked_end in booked_times:
                if (slot.start_time < booked_end and slot.end_time > booked_start):
                    is_available = False
                    break
            
            if is_available:
                available_slots.append(slot)
        
        return available_slots
        
    def get_average_rating(self):
        """Calculate the average rating for this turf"""
        from sqlalchemy import func
        
        result = db.session.query(func.avg(Review.rating)).filter_by(turf_id=self.id).scalar()
        if result is None:
            return 0
        return round(float(result), 1)
        
    def get_rating_count(self):
        """Get the total number of ratings for this turf"""
        return Review.query.filter_by(turf_id=self.id).count()
        
    def get_rating_distribution(self):
        """Get the distribution of ratings (how many 5-star, 4-star, etc.)"""
        from sqlalchemy import func
        
        distribution = {}
        for i in range(1, 6):
            count = Review.query.filter_by(turf_id=self.id, rating=i).count()
            distribution[i] = count
        return distribution
        
    def is_favorited_by(self, user_id):
        """Check if this turf is favorited by a specific user"""
        return Favorite.query.filter_by(turf_id=self.id, user_id=user_id).first() is not None
        
    def get_share_url(self, domain):
        """Generate a shareable URL for this turf"""
        return f"https://{domain}/turfs/{self.id}"
        
    def to_dict(self):
        """Convert turf to dictionary for JSON/API responses"""
        return {
            'id': self.id,
            'name': self.name,
            'description': self.description,
            'address': self.address,
            'city': self.city,
            'state': self.state,
            'country': self.country,
            'base_price_per_hour': self.base_price_per_hour,
            'indoor': self.indoor,
            'size': self.size,
            'features': self.features.split(',') if self.features else [],
            'avg_rating': self.get_average_rating(),
            'rating_count': self.get_rating_count(),
            'has_parking': self.has_parking,
            'has_changing_room': self.has_changing_room,
            'has_shower': self.has_shower,
            'has_floodlights': self.has_floodlights,
            'surface_type': self.surface_type
        }


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


class BookingStatus:
    PENDING = 'pending'  # Initial request
    NEGOTIATING = 'negotiating'  # Price negotiation in progress
    CONFIRMED = 'confirmed'  # Booking confirmed
    CANCELLED = 'cancelled'  # Booking cancelled
    COMPLETED = 'completed'  # Booking completed


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
    payment_id = db.Column(db.String(100), nullable=True)  # External payment reference
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


class NotificationType:
    BOOKING_REMINDER = 'booking_reminder'
    BOOKING_CONFIRMED = 'booking_confirmed'
    BOOKING_CANCELLED = 'booking_cancelled'
    PAYMENT_SUCCESS = 'payment_success'
    PAYMENT_FAILED = 'payment_failed'
    PRICE_NEGOTIATION = 'price_negotiation'
    NEW_REVIEW = 'new_review'
    TURF_FEATURED = 'turf_featured'
    DISPUTE_UPDATE = 'dispute_update'


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
