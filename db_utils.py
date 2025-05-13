from app import mongo
from flask_login import UserMixin
from werkzeug.security import generate_password_hash, check_password_hash
from bson.objectid import ObjectId
from datetime import datetime

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

# User class for Flask-Login
class User(UserMixin):
    def __init__(self, user_data):
        self.user_data = user_data
        
    def get_id(self):
        return str(self.user_data.get('_id'))
    
    @property
    def id(self):
        return self.user_data.get('_id')
    
    @property
    def username(self):
        return self.user_data.get('username')
    
    @property
    def email(self):
        return self.user_data.get('email')
    
    @property
    def role(self):
        return self.user_data.get('role')
    
    @property
    def phone_number(self):
        return self.user_data.get('phone_number')
    
    def set_password(self, password):
        return generate_password_hash(password)
    
    def check_password(self, password):
        return check_password_hash(self.user_data.get('password_hash'), password)
    
    def is_owner(self):
        return self.role == UserRole.OWNER
    
    def is_admin(self):
        return self.role == UserRole.ADMIN

# User-related database functions
def find_user_by_id(user_id):
    if not user_id:
        return None
    
    # Handle both string and ObjectId types
    if isinstance(user_id, str):
        try:
            user_id = ObjectId(user_id)
        except:
            return None
    
    user_data = mongo.db.users.find_one({'_id': user_id})
    if user_data:
        return User(user_data)
    return None

def find_user_by_email(email):
    user_data = mongo.db.users.find_one({'email': email})
    if user_data:
        return User(user_data)
    return None

def find_user_by_username(username):
    user_data = mongo.db.users.find_one({'username': username})
    if user_data:
        return User(user_data)
    return None

def create_user(username, email, password, phone_number=None, role=UserRole.USER):
    password_hash = generate_password_hash(password)
    
    user_data = {
        'username': username,
        'email': email,
        'password_hash': password_hash,
        'phone_number': phone_number,
        'role': role,
        'created_at': datetime.utcnow()
    }
    
    result = mongo.db.users.insert_one(user_data)
    user_data['_id'] = result.inserted_id
    return User(user_data)

def update_user(user_id, update_data):
    if isinstance(user_id, str):
        user_id = ObjectId(user_id)
    
    mongo.db.users.update_one({'_id': user_id}, {'$set': update_data})
    return find_user_by_id(user_id)

# Turf-related database functions
def create_turf(owner_id, name, description, address, city, state, country, postal_code, 
                base_price_per_hour, features=None, size=None, indoor=False, **kwargs):
    
    if isinstance(owner_id, str):
        owner_id = ObjectId(owner_id)
    
    turf_data = {
        'owner_id': owner_id,
        'name': name,
        'description': description,
        'address': address,
        'city': city,
        'state': state,
        'country': country,
        'postal_code': postal_code,
        'base_price_per_hour': base_price_per_hour,
        'features': features,
        'size': size,
        'indoor': indoor,
        'active': True,
        'created_at': datetime.utcnow(),
        'updated_at': datetime.utcnow()
    }
    
    # Add optional fields
    for key, value in kwargs.items():
        turf_data[key] = value
    
    result = mongo.db.turfs.insert_one(turf_data)
    turf_data['_id'] = result.inserted_id
    return turf_data

def find_turf_by_id(turf_id):
    if isinstance(turf_id, str):
        try:
            turf_id = ObjectId(turf_id)
        except:
            return None
    
    return mongo.db.turfs.find_one({'_id': turf_id})

def find_turfs_by_owner(owner_id):
    if isinstance(owner_id, str):
        owner_id = ObjectId(owner_id)
    
    return list(mongo.db.turfs.find({'owner_id': owner_id}))

def update_turf(turf_id, update_data):
    if isinstance(turf_id, str):
        turf_id = ObjectId(turf_id)
    
    update_data['updated_at'] = datetime.utcnow()
    mongo.db.turfs.update_one({'_id': turf_id}, {'$set': update_data})
    return find_turf_by_id(turf_id)

def find_turfs(query=None, limit=None, skip=None, sort=None):
    if query is None:
        query = {'active': True}
    
    cursor = mongo.db.turfs.find(query)
    
    if sort:
        cursor = cursor.sort(sort)
    
    if skip:
        cursor = cursor.skip(skip)
    
    if limit:
        cursor = cursor.limit(limit)
    
    return list(cursor)

# Booking-related database functions
def create_booking(user_id, turf_id, booking_date, start_time, end_time, total_price, 
                   status='PENDING', payment_method='pay_online', **kwargs):
    
    if isinstance(user_id, str):
        user_id = ObjectId(user_id)
    
    if isinstance(turf_id, str):
        turf_id = ObjectId(turf_id)
    
    booking_data = {
        'user_id': user_id,
        'turf_id': turf_id,
        'booking_date': booking_date,
        'start_time': start_time,
        'end_time': end_time,
        'total_price': total_price,
        'status': status,
        'payment_method': payment_method,
        'created_at': datetime.utcnow(),
        'updated_at': datetime.utcnow()
    }
    
    # Add optional fields
    for key, value in kwargs.items():
        booking_data[key] = value
    
    result = mongo.db.bookings.insert_one(booking_data)
    booking_data['_id'] = result.inserted_id
    return booking_data

def find_booking_by_id(booking_id):
    if isinstance(booking_id, str):
        try:
            booking_id = ObjectId(booking_id)
        except:
            return None
    
    return mongo.db.bookings.find_one({'_id': booking_id})

def find_bookings_by_user(user_id):
    if isinstance(user_id, str):
        user_id = ObjectId(user_id)
    
    return list(mongo.db.bookings.find({'user_id': user_id}))

def find_bookings_by_turf(turf_id):
    if isinstance(turf_id, str):
        turf_id = ObjectId(turf_id)
    
    return list(mongo.db.bookings.find({'turf_id': turf_id}))

def update_booking(booking_id, update_data):
    if isinstance(booking_id, str):
        booking_id = ObjectId(booking_id)
    
    update_data['updated_at'] = datetime.utcnow()
    mongo.db.bookings.update_one({'_id': booking_id}, {'$set': update_data})
    return find_booking_by_id(booking_id)

def find_bookings(query=None, limit=None, skip=None, sort=None):
    if query is None:
        query = {}
    
    cursor = mongo.db.bookings.find(query)
    
    if sort:
        cursor = cursor.sort(sort)
    
    if skip:
        cursor = cursor.skip(skip)
    
    if limit:
        cursor = cursor.limit(limit)
    
    return list(cursor)