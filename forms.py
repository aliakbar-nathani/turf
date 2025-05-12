from flask_wtf import FlaskForm
from wtforms import StringField, PasswordField, SubmitField, BooleanField, TextAreaField, SelectField, FloatField, IntegerField, HiddenField, TimeField, RadioField
from wtforms.validators import DataRequired, Length, Email, EqualTo, ValidationError, Optional, NumberRange
from datetime import date

from models import User, UserRole

class LoginForm(FlaskForm):
    email = StringField('Email', validators=[DataRequired(), Email()])
    password = PasswordField('Password', validators=[DataRequired()])
    remember = BooleanField('Remember Me')
    submit = SubmitField('Login')

class RegisterForm(FlaskForm):
    username = StringField('Username', validators=[DataRequired(), Length(min=3, max=20)])
    email = StringField('Email', validators=[DataRequired(), Email()])
    phone_number = StringField('Phone Number', validators=[DataRequired(), Length(min=10, max=15)])
    password = PasswordField('Password', validators=[DataRequired(), Length(min=6)])
    confirm_password = PasswordField('Confirm Password', validators=[DataRequired(), EqualTo('password')])
    submit = SubmitField('Sign Up')
    
    def validate_username(self, username):
        user = User.query.filter_by(username=username.data).first()
        if user:
            raise ValidationError('Username is already taken.')
    
    def validate_email(self, email):
        user = User.query.filter_by(email=email.data).first()
        if user:
            raise ValidationError('Email is already registered.')

class RegisterOwnerForm(RegisterForm):
    submit = SubmitField('Sign Up as Turf Owner')

class UserProfileForm(FlaskForm):
    username = StringField('Username', validators=[DataRequired(), Length(min=3, max=20)])
    email = StringField('Email', validators=[DataRequired(), Email()], render_kw={'readonly': True})
    phone_number = StringField('Phone Number', validators=[DataRequired(), Length(min=10, max=15)])
    current_password = PasswordField('Current Password')
    new_password = PasswordField('New Password', validators=[Optional(), Length(min=6)])
    confirm_password = PasswordField('Confirm New Password', validators=[Optional(), EqualTo('new_password')])
    submit = SubmitField('Update Profile')

class AdminProfileForm(FlaskForm):
    username = StringField('Username', validators=[DataRequired(), Length(min=3, max=20)])
    email = StringField('Email', validators=[DataRequired(), Email()])
    phone_number = StringField('Phone Number', validators=[Optional(), Length(min=10, max=15)])
    role = SelectField('Role', choices=[
        (UserRole.USER, 'Regular User'),
        (UserRole.OWNER, 'Turf Owner'),
        (UserRole.ADMIN, 'Admin')
    ], validators=[DataRequired()])
    new_password = PasswordField('New Password', validators=[Optional(), Length(min=6)])
    confirm_password = PasswordField('Confirm New Password', validators=[Optional(), EqualTo('new_password')])
    submit = SubmitField('Update User')

class TurfForm(FlaskForm):
    name = StringField('Turf Name', validators=[DataRequired(), Length(max=100)])
    description = TextAreaField('Description', validators=[Optional()])
    address = StringField('Address', validators=[DataRequired(), Length(max=200)])
    city = StringField('City', validators=[DataRequired(), Length(max=100)])
    state = StringField('State', validators=[DataRequired(), Length(max=100)])
    country = StringField('Country', validators=[DataRequired(), Length(max=100)])
    postal_code = StringField('Postal Code', validators=[DataRequired(), Length(max=20)])
    base_price_per_hour = FloatField('Base Price per Hour', validators=[DataRequired(), NumberRange(min=1)])
    features = StringField('Features (comma-separated)', validators=[Optional()])
    size = StringField('Size (e.g., 5-a-side)', validators=[Optional(), Length(max=50)])
    indoor = BooleanField('Indoor Turf')
    
    # Advanced amenities
    has_parking = BooleanField('Parking Available')
    has_changing_room = BooleanField('Changing Rooms')
    has_shower = BooleanField('Showers')
    has_floodlights = BooleanField('Floodlights')
    has_equipment = BooleanField('Equipment Available')
    has_refreshments = BooleanField('Refreshments Available')
    
    # Booking settings
    auto_approve_bookings = BooleanField('Auto-approve bookings (instantly confirms bookings with paid or pay-on-arrival)')
    surface_type = SelectField('Surface Type', choices=[
        ('grass', 'Grass'), 
        ('artificial', 'Artificial Turf'),
        ('indoor', 'Indoor'),
        ('clay', 'Clay'),
        ('concrete', 'Concrete'),
        ('other', 'Other')
    ])
    
    # Images
    image_url = StringField('Primary Image URL', validators=[Optional()])
    additional_images = StringField('Additional Image URLs (comma-separated)', validators=[Optional()])
    
    submit = SubmitField('Save Turf')

class TimeSlotForm(FlaskForm):
    day_of_week = SelectField('Day of Week', choices=[
        (0, 'Monday'),
        (1, 'Tuesday'),
        (2, 'Wednesday'),
        (3, 'Thursday'),
        (4, 'Friday'),
        (5, 'Saturday'),
        (6, 'Sunday')
    ], coerce=int, validators=[DataRequired()])
    start_time = TimeField('Start Time', validators=[DataRequired()])
    end_time = TimeField('End Time', validators=[DataRequired()])
    price_adjustment = FloatField('Price Adjustment (%)', validators=[Optional()])
    submit = SubmitField('Add Time Slot')
    
    def validate_end_time(self, end_time):
        if self.start_time.data and end_time.data <= self.start_time.data:
            raise ValidationError('End time must be after start time.')

class BookingSearchForm(FlaskForm):
    city = StringField('City', validators=[Optional()])
    date = StringField('Date', validators=[Optional()])
    min_price = FloatField('Min Price', validators=[Optional(), NumberRange(min=0)])
    max_price = FloatField('Max Price', validators=[Optional(), NumberRange(min=0)])
    indoor = SelectField('Type', choices=[
        ('', 'Any'), 
        ('True', 'Indoor'), 
        ('False', 'Outdoor')
    ], validators=[Optional()])
    submit = SubmitField('Search')

class BookingForm(FlaskForm):
    booking_date = StringField('Date', validators=[DataRequired()])
    time_slot = SelectField('Time Slot', validators=[DataRequired()], coerce=str)
    payment_option = SelectField('Payment Option', choices=[
        ('pay_online', 'Pay Online Now'),
        ('pay_on_arrival', 'Pay On Arrival')
    ], default='pay_online', validators=[DataRequired()])
    # Note: negotiation_enabled is handled via a standard HTML input in the template
    proposed_price = FloatField('Your Proposed Price (optional)', validators=[Optional(), NumberRange(min=0)])
    message = TextAreaField('Message to Owner (optional)', validators=[Optional()])
    submit = SubmitField('Book Now')

class NegotiationForm(FlaskForm):
    action = HiddenField('Action', validators=[DataRequired()])
    proposed_price = FloatField('Your Counter Offer', validators=[Optional(), NumberRange(min=0)])
    message = TextAreaField('Message', validators=[Optional()])
    submit = SubmitField('Submit')

class DisputeForm(FlaskForm):
    title = StringField('Title', validators=[DataRequired(), Length(max=100)])
    description = TextAreaField('Description', validators=[DataRequired()])
    submit = SubmitField('Submit Dispute')


class ReviewForm(FlaskForm):
    rating = SelectField('Rating', choices=[
        (5, '★★★★★ Excellent'),
        (4, '★★★★ Very Good'),
        (3, '★★★ Good'),
        (2, '★★ Fair'),
        (1, '★ Poor')
    ], coerce=int, validators=[DataRequired()])
    comment = TextAreaField('Your Review', validators=[Optional(), Length(max=1000)])
    submit = SubmitField('Submit Review')


class OwnerReviewResponseForm(FlaskForm):
    response = TextAreaField('Your Response', validators=[DataRequired()])
    submit = SubmitField('Submit Response')


class AdvancedSearchForm(FlaskForm):
    city = StringField('City', validators=[Optional()])
    date = StringField('Date', validators=[Optional()])
    min_price = FloatField('Min Price', validators=[Optional(), NumberRange(min=0)])
    max_price = FloatField('Max Price', validators=[Optional(), NumberRange(min=0)])
    indoor = SelectField('Type', choices=[
        ('', 'Any'), 
        ('True', 'Indoor'), 
        ('False', 'Outdoor')
    ], validators=[Optional()])
    
    # Advanced filters
    has_parking = BooleanField('Parking Available', default=False)
    has_changing_room = BooleanField('Changing Rooms', default=False)
    has_shower = BooleanField('Showers', default=False)
    has_floodlights = BooleanField('Floodlights', default=False)
    has_equipment = BooleanField('Equipment', default=False)
    auto_approve_bookings = BooleanField('Instant Booking', default=False)
    min_rating = SelectField('Minimum Rating', choices=[
        ('0', 'Any Rating'),
        ('3', '3+ Stars'),
        ('4', '4+ Stars'),
        ('5', '5 Stars')
    ], coerce=int, default='0', validators=[Optional()])
    surface_type = SelectField('Surface Type', choices=[
        ('', 'Any Surface'),
        ('grass', 'Grass'),
        ('artificial', 'Artificial Turf'),
        ('indoor', 'Indoor'),
        ('clay', 'Clay'),
        ('concrete', 'Concrete')
    ], validators=[Optional()])
    
    submit = SubmitField('Search')


class NotificationSettingsForm(FlaskForm):
    email_booking_confirmation = BooleanField('Email Booking Confirmations', default=True)
    email_booking_reminder = BooleanField('Email Booking Reminders', default=True)
    sms_booking_reminder = BooleanField('SMS Booking Reminders', default=False)
    email_price_negotiation = BooleanField('Email Price Negotiation Updates', default=True)
    email_turf_promotions = BooleanField('Email Promotions for Favorite Turfs', default=False)
    submit = SubmitField('Save Notification Settings')


class ShareTurfForm(FlaskForm):
    platform = SelectField('Share on', choices=[
        ('copy', 'Copy Link'),
        ('whatsapp', 'WhatsApp'),
        ('facebook', 'Facebook'),
        ('twitter', 'Twitter'),
        ('email', 'Email')
    ])
    submit = SubmitField('Share')
    
class DirectBookingForm(FlaskForm):
    turf_id = SelectField('Select Turf', coerce=int, validators=[DataRequired()])
    customer_name = StringField('Customer Name', validators=[DataRequired(), Length(min=3, max=50)])
    customer_phone = StringField('Customer Phone', validators=[DataRequired(), Length(min=10, max=15)])
    booking_date = StringField('Booking Date', validators=[DataRequired()])
    time_slot = SelectField('Time Slot', validators=[DataRequired()], coerce=str)
    total_price = FloatField('Price', validators=[DataRequired(), NumberRange(min=0)])
    payment_method = SelectField('Payment Method', choices=[
        ('pay_on_arrival', 'Pay On Arrival'),
        ('paid_offline', 'Already Paid (Offline)')
    ], validators=[DataRequired()])
    notes = TextAreaField('Notes (Optional)', validators=[Optional(), Length(max=500)])
    submit = SubmitField('Create Booking')

# Form for booking actions (accept, reject, etc.)
class BookingActionForm(FlaskForm):
    action = RadioField('Action', choices=[
        ('accept', 'Accept Booking'),
        ('payment_received_offline', 'Payment Received Offline'),
        ('reject', 'Reject Booking'),
        ('counter', 'Make Counter Offer')
    ], validators=[DataRequired()])
    
    counter_price = FloatField('Counter Price', validators=[Optional()])
    message = TextAreaField('Message', validators=[Optional()])
    
    submit = SubmitField('Submit')

# Form for simple booking actions (mark complete, payment confirmed)
class SimpleBookingActionForm(FlaskForm):
    action = HiddenField('Action', validators=[DataRequired()])
    submit = SubmitField('Submit')
