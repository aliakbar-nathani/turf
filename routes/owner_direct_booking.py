from flask import Blueprint, render_template, redirect, url_for, flash, request, jsonify, abort
from flask_login import login_required, current_user
from datetime import datetime
import secrets
from werkzeug.security import generate_password_hash

from app import db
from models import User, Turf, TimeSlot, Booking, BookingStatus
from forms import DirectBookingForm

owner_direct_booking = Blueprint('owner_direct_booking', __name__)

@owner_direct_booking.before_request
def check_owner():
    if not current_user.is_authenticated or not current_user.is_owner():
        abort(403)  # Forbidden

@owner_direct_booking.route('/create-booking', methods=['GET', 'POST'])
@login_required
def create_booking():
    form = DirectBookingForm()
    
    # Populate the turf select field with turfs owned by the current user
    turf_choices = [(t.id, t.name) for t in Turf.query.filter_by(owner_id=current_user.id).all()]
    form.turf_id.choices = turf_choices if turf_choices else [(0, "No turfs available")]
    
    # Always initialize time_slot choices
    form.time_slot.choices = [("", "Select a turf first")]
    
    if request.method == 'GET' and turf_choices:
        # If we have turfs, preselect the first one
        form.turf_id.data = turf_choices[0][0]
        
        # Populate time slots for the selected turf
        turf_id = form.turf_id.data
        time_slots = TimeSlot.query.filter_by(turf_id=turf_id).all()
        if time_slots:
            time_slot_choices = [(f"{slot.start_time}-{slot.end_time}", f"{slot.start_time} - {slot.end_time}") for slot in time_slots]
            form.time_slot.choices = time_slot_choices
        else:
            form.time_slot.choices = [("", "No time slots available")]
    
    if form.validate_on_submit():
        try:
            # Check if turf_id is the default "no turfs" value
            if form.turf_id.data == 0:
                flash('Please add a turf before creating a booking', 'danger')
                return redirect(url_for('owner_direct_booking.create_booking'))
                
            # Parse time slot
            if not form.time_slot.data or form.time_slot.data == "":
                flash('Please select a valid time slot', 'danger')
                return redirect(url_for('owner_direct_booking.create_booking'))
                
            start_time, end_time = form.time_slot.data.split('-')
            
            # Get the turf
            turf = Turf.query.get(form.turf_id.data)
            if not turf:
                flash('Turf not found', 'danger')
                return redirect(url_for('owner_direct_booking.create_booking'))
                
            # Check if the turf belongs to the current user
            if turf.owner_id != current_user.id:
                flash('You do not own this turf', 'danger')
                return redirect(url_for('owner_direct_booking.create_booking'))
        except Exception as e:
            flash(f'Error processing form: {str(e)}', 'danger')
            return redirect(url_for('owner_direct_booking.create_booking'))
        
        # Create a user account for the customer if they don't already have one
        existing_user = User.query.filter_by(phone_number=form.customer_phone.data).first()
        
        if existing_user:
            customer_id = existing_user.id
        else:
            # Create a temporary username based on phone number and name
            if form.customer_name.data:
                clean_name = form.customer_name.data.lower().replace(' ', '_')
                username = f"{clean_name}_{form.customer_phone.data[-4:]}"
            else:
                username = f"customer_{form.customer_phone.data[-4:]}"
            
            # Create a temporary password
            temp_password = secrets.token_urlsafe(8)
            
            # Create the user with a valid email
            phone_digits = ''.join(c for c in form.customer_phone.data if c.isdigit())
            email = f"customer_{phone_digits}@example.com"  # Placeholder email
            
            new_user = User(
                username=username,
                email=email,
                phone_number=form.customer_phone.data,
                password_hash=generate_password_hash(temp_password),
                role='user'
            )
            db.session.add(new_user)
            db.session.flush()  # Get the ID without committing
            customer_id = new_user.id
            
        # Create the booking
        try:
            if form.booking_date.data:
                booking_date = datetime.strptime(form.booking_date.data, '%Y-%m-%d').date()
            else:
                flash('Please select a valid booking date', 'danger')
                return redirect(url_for('owner_direct_booking.create_booking'))
        except ValueError:
            flash('Invalid date format. Please use YYYY-MM-DD', 'danger')
            return redirect(url_for('owner_direct_booking.create_booking'))
        
        new_booking = Booking(
            user_id=customer_id,
            turf_id=turf.id,
            booking_date=booking_date,
            start_time=start_time,
            end_time=end_time,
            total_price=form.total_price.data,
            original_price=form.total_price.data,  # Same price since it's direct
            status=BookingStatus.CONFIRMED,  # Direct bookings are automatically confirmed
            payment_method=form.payment_method.data,
            payment_status='paid' if form.payment_method.data == 'paid_offline' else 'pending',
            notes=form.notes.data or None
        )
        
        db.session.add(new_booking)
        db.session.commit()
        
        flash('Booking created successfully', 'success')
        return redirect(url_for('owner.bookings'))
    
    # Handle form errors
    elif request.method == 'POST':
        flash('Please correct the errors in the form', 'danger')
    
    return render_template('owner/create_booking.html', title='Create Booking', form=form)
    
@owner_direct_booking.route('/get-time-slots/<int:turf_id>')
@login_required
def get_time_slots(turf_id):
    # Check if turf belongs to current user
    turf = Turf.query.get(turf_id)
    if not turf or turf.owner_id != current_user.id:
        return jsonify({'error': 'Unauthorized'}), 403
        
    # Get all time slots for the turf
    time_slots = TimeSlot.query.filter_by(turf_id=turf_id).all()
    
    # Format time slots for select field
    slots = [{'value': f"{slot.start_time}-{slot.end_time}", 
               'text': f"{slot.start_time} - {slot.end_time}"} 
             for slot in time_slots]
             
    return jsonify({'slots': slots})