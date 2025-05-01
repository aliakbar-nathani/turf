from flask import Blueprint, render_template, redirect, url_for, flash, request, abort, jsonify
from flask_login import login_required, current_user
from datetime import datetime, time, timedelta

from app import db
from models import Turf, TimeSlot, Booking, BookingStatus, Negotiation, Dispute
from forms import BookingForm, NegotiationForm, DisputeForm

booking = Blueprint('booking', __name__)

@booking.route('/turfs/<int:turf_id>')
def view_turf(turf_id):
    turf = Turf.query.get_or_404(turf_id)
    
    # Get all turf images
    all_images = turf.images.all()
    primary_image = next((img for img in all_images if img.is_primary), all_images[0] if all_images else None)
    
    # Get available time slots for today
    today = datetime.utcnow().date()
    available_slots = turf.get_available_slots(today)
    
    # Get features as list
    features = turf.features.split(',') if turf.features else []
    
    return render_template(
        'turf/details.html',
        turf=turf,
        primary_image=primary_image,
        all_images=all_images,
        available_slots=available_slots,
        features=features,
        today=today,
        title=turf.name
    )

@booking.route('/turfs/<int:turf_id>/availability')
def check_availability(turf_id):
    turf = Turf.query.get_or_404(turf_id)
    date_str = request.args.get('date')
    
    if not date_str:
        return jsonify({'error': 'Date is required'}), 400
    
    try:
        date = datetime.strptime(date_str, '%Y-%m-%d').date()
    except ValueError:
        return jsonify({'error': 'Invalid date format'}), 400
    
    available_slots = turf.get_available_slots(date)
    
    # Format slots for response
    slots_data = []
    for slot in available_slots:
        # Calculate adjusted price
        adjusted_price = turf.base_price_per_hour
        if slot.price_adjustment:
            adjusted_price = adjusted_price * (1 + slot.price_adjustment / 100)
        
        slots_data.append({
            'id': slot.id,
            'start_time': slot.start_time.strftime('%H:%M'),
            'end_time': slot.end_time.strftime('%H:%M'),
            'price': round(adjusted_price, 2)
        })
    
    return jsonify({'slots': slots_data})

@booking.route('/turfs/<int:turf_id>/book', methods=['GET', 'POST'])
@login_required
def book_turf(turf_id):
    turf = Turf.query.get_or_404(turf_id)
    form = BookingForm()
    
    # Get available dates for the next 14 days (for JavaScript initialization)
    today = datetime.utcnow().date()
    available_dates = [(today + timedelta(days=i)).strftime('%Y-%m-%d') for i in range(14)]
    
    # Set default empty choices for the time slot field
    form.time_slot.choices = [('', 'Select a time slot')]
    
    # Set initial date if provided in query params
    if request.args.get('date'):
        try:
            form.booking_date.data = request.args.get('date')
        except ValueError:
            pass
    
    if form.validate_on_submit():
        # Get the selected date and time slot
        try:
            booking_date = datetime.strptime(form.booking_date.data, '%Y-%m-%d').date() if form.booking_date.data else None
            if not booking_date:
                flash('Please select a valid booking date.', 'danger')
                return redirect(url_for('booking.book_turf', turf_id=turf.id))
            time_slot_id = form.time_slot.data
        except ValueError:
            flash('Invalid date format. Please select a date from the calendar.', 'danger')
            return redirect(url_for('booking.book_turf', turf_id=turf.id))
        
        # Validate time slot
        time_slot = TimeSlot.query.get_or_404(time_slot_id)
        if time_slot.turf_id != turf.id:
            flash('Invalid time slot selected.', 'danger')
            return redirect(url_for('booking.book_turf', turf_id=turf.id))
        
        # Check if slot is available
        is_available = True
        booked_slots = Booking.query.filter_by(
            turf_id=turf.id,
            booking_date=booking_date,
            status=BookingStatus.CONFIRMED
        ).all()
        
        for booked in booked_slots:
            if (time_slot.start_time < booked.end_time and time_slot.end_time > booked.start_time):
                is_available = False
                break
        
        if not is_available:
            flash('Selected time slot is no longer available.', 'danger')
            return redirect(url_for('booking.book_turf', turf_id=turf.id))
        
        # Calculate price
        base_price = turf.base_price_per_hour
        adjusted_price = base_price
        if time_slot.price_adjustment:
            adjusted_price = base_price * (1 + time_slot.price_adjustment / 100)
        
        # Calculate duration in hours
        start_dt = datetime.combine(booking_date, time_slot.start_time)
        end_dt = datetime.combine(booking_date, time_slot.end_time)
        duration_hours = (end_dt - start_dt).total_seconds() / 3600
        
        total_price = adjusted_price * duration_hours
        
        # Apply user's price negotiation if provided and negotiation is enabled
        user_price = form.proposed_price.data
        negotiation_enabled = form.negotiation_enabled.data == '1'
        
        # If negotiation is not enabled, ignore any proposed price
        if not negotiation_enabled:
            user_price = None
        
        # Create the booking
        booking = Booking(
            user_id=current_user.id,
            turf_id=turf.id,
            booking_date=booking_date,
            start_time=time_slot.start_time,
            end_time=time_slot.end_time,
            original_price=total_price,
            total_price=total_price if not user_price else user_price,
            user_proposed_price=user_price if negotiation_enabled else None,
            status=BookingStatus.PENDING if negotiation_enabled and user_price and user_price < total_price else BookingStatus.CONFIRMED
        )
        
        db.session.add(booking)
        
        # If user proposed a different price and negotiation is enabled, create a negotiation record
        if negotiation_enabled and user_price and user_price < total_price:
            negotiation = Negotiation(
                booking_id=booking.id,
                proposed_price=user_price,
                proposed_by='user',
                message=form.message.data
            )
            db.session.add(negotiation)
        
        db.session.commit()
        
        if booking.status == BookingStatus.PENDING:
            flash('Your booking request with price negotiation has been sent to the turf owner!', 'success')
            return redirect(url_for('user.bookings'))
        else:
            # Redirect to payment if price is accepted
            return redirect(url_for('payment.checkout', booking_id=booking.id))
    
    return render_template(
        'turf/booking.html',
        turf=turf,
        form=form,
        available_dates=available_dates,
        title=f'Book {turf.name}'
    )

@booking.route('/bookings/<int:booking_id>/negotiate', methods=['GET', 'POST'])
@login_required
def negotiate(booking_id):
    booking = Booking.query.get_or_404(booking_id)
    
    # Check if the booking belongs to the current user
    if booking.user_id != current_user.id:
        abort(403)
    
    # Check if booking is in a negotiable state
    if booking.status not in [BookingStatus.PENDING, BookingStatus.NEGOTIATING]:
        flash('This booking is no longer negotiable.', 'warning')
        return redirect(url_for('user.bookings'))
    
    form = NegotiationForm()
    
    if form.validate_on_submit():
        action = form.action.data
        
        if action == 'accept':
            # Accept owner's counter offer
            booking.status = BookingStatus.CONFIRMED
            
            # Update the latest negotiation
            latest_negotiation = Negotiation.query.filter_by(
                booking_id=booking.id
            ).order_by(Negotiation.created_at.desc()).first()
            
            if latest_negotiation and latest_negotiation.proposed_by == 'owner':
                latest_negotiation.is_accepted = True
            
            db.session.commit()
            
            flash('You have accepted the owner\'s price!', 'success')
            return redirect(url_for('payment.checkout', booking_id=booking.id))
        
        elif action == 'counter':
            # Make a counter offer
            counter_price = form.proposed_price.data
            
            # Ensure we have a valid counter price (not None and greater than zero)
            if counter_price is None or not isinstance(counter_price, (int, float)) or counter_price <= 0:
                flash('Please enter a valid counter price.', 'danger')
                return redirect(url_for('booking.negotiate', booking_id=booking.id))
            
            # Create negotiation record
            negotiation = Negotiation(
                booking_id=booking.id,
                proposed_price=counter_price,
                proposed_by='user',
                message=form.message.data
            )
            
            db.session.add(negotiation)
            
            # Update booking
            booking.status = BookingStatus.NEGOTIATING
            booking.total_price = counter_price
            
            db.session.commit()
            
            flash('Your counter offer has been sent to the owner!', 'success')
            return redirect(url_for('user.bookings'))
        
        elif action == 'cancel':
            # Cancel negotiation
            booking.status = BookingStatus.CANCELLED
            db.session.commit()
            
            flash('You have cancelled this booking request.', 'info')
            return redirect(url_for('user.bookings'))
    
    turf = Turf.query.get(booking.turf_id)
    negotiations = Negotiation.query.filter_by(booking_id=booking.id).order_by(Negotiation.created_at.asc()).all()
    
    return render_template(
        'turf/negotiation.html',
        booking=booking,
        turf=turf,
        negotiations=negotiations,
        form=form,
        title='Price Negotiation'
    )

@booking.route('/bookings/<int:booking_id>/cancel', methods=['POST'])
@login_required
def cancel_booking(booking_id):
    booking = Booking.query.get_or_404(booking_id)
    
    # Check if the booking belongs to the current user
    if booking.user_id != current_user.id:
        abort(403)
    
    # Check if booking is cancellable
    if booking.status not in [BookingStatus.CONFIRMED]:
        flash('This booking cannot be cancelled.', 'warning')
        return redirect(url_for('user.bookings'))
    
    booking.status = BookingStatus.CANCELLED
    db.session.commit()
    
    flash('Your booking has been cancelled.', 'success')
    return redirect(url_for('user.bookings'))

@booking.route('/bookings/<int:booking_id>/dispute', methods=['GET', 'POST'])
@login_required
def create_dispute(booking_id):
    booking = Booking.query.get_or_404(booking_id)
    
    # Check if the booking belongs to the current user
    if booking.user_id != current_user.id:
        abort(403)
    
    form = DisputeForm()
    
    if form.validate_on_submit():
        dispute = Dispute(
            title=form.title.data,
            description=form.description.data,
            booking_id=booking.id,
            user_id=current_user.id
        )
        
        db.session.add(dispute)
        db.session.commit()
        
        flash('Your dispute has been submitted. An admin will review it shortly.', 'success')
        return redirect(url_for('user.bookings'))
    
    turf = Turf.query.get(booking.turf_id)
    
    return render_template(
        'user/dispute.html',
        booking=booking,
        turf=turf,
        form=form,
        title='Submit Dispute'
    )
