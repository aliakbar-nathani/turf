from datetime import datetime
from app import db
from flask_login import UserMixin
from werkzeug.security import generate_password_hash, check_password_hash

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
