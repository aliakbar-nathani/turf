from flask import Blueprint, render_template, redirect, url_for, flash, request, abort, jsonify
from flask_login import login_required, current_user
from datetime import datetime, timedelta
import json

from app import db
from models import User, Turf, TurfImage, TimeSlot, Booking, BookingStatus, Negotiation
from forms import TurfForm, TimeSlotForm

owner = Blueprint('owner', __name__)

@owner.before_request
def check_owner():
    if not current_user.is_authenticated or not current_user.is_owner():
        abort(403)  # Forbidden

@owner.route('/dashboard')
@login_required
def dashboard():
    # Get summary data for dashboard
    turfs_count = Turf.query.filter_by(owner_id=current_user.id).count()
    
    # Get bookings for all turfs owned by current user
    current_date = datetime.utcnow().date()
    
    # Today's bookings
    today_bookings = db.session.query(Booking).join(Turf).filter(
        Turf.owner_id == current_user.id,
        Booking.booking_date == current_date,
        Booking.status == BookingStatus.CONFIRMED
    ).count()
    
    # Pending bookings (including negotiations)
    pending_bookings = db.session.query(Booking).join(Turf).filter(
        Turf.owner_id == current_user.id,
        Booking.status.in_([BookingStatus.PENDING, BookingStatus.NEGOTIATING])
    ).count()
    
    # Recent revenue (last 30 days)
    thirty_days_ago = current_date - timedelta(days=30)
    recent_revenue = db.session.query(db.func.sum(Booking.total_price)).join(Turf).filter(
        Turf.owner_id == current_user.id,
        Booking.booking_date >= thirty_days_ago,
        Booking.booking_date <= current_date,
        Booking.status == BookingStatus.COMPLETED,
        Booking.payment_status == 'paid'
    ).scalar() or 0
    
    # Get recent bookings across all turfs
    recent_bookings = db.session.query(Booking).join(Turf).filter(
        Turf.owner_id == current_user.id
    ).order_by(
        Booking.created_at.desc()
    ).limit(5).all()
    
    # Get turfs with most bookings
    popular_turfs = db.session.query(
        Turf, db.func.count(Booking.id).label('booking_count')
    ).join(Booking).filter(
        Turf.owner_id == current_user.id,
        Booking.status.in_([BookingStatus.CONFIRMED, BookingStatus.COMPLETED])
    ).group_by(Turf.id).order_by(
        db.desc('booking_count')
    ).limit(3).all()
    
    return render_template(
        'owner/dashboard.html',
        turfs_count=turfs_count,
        today_bookings=today_bookings,
        pending_bookings=pending_bookings,
        recent_revenue=recent_revenue,
        recent_bookings=recent_bookings,
        popular_turfs=popular_turfs,
        title='Owner Dashboard'
    )

@owner.route('/turfs')
@login_required
def turfs():
    turfs = Turf.query.filter_by(owner_id=current_user.id).all()
    return render_template('owner/turfs.html', turfs=turfs, title='My Turfs')

@owner.route('/turfs/new', methods=['GET', 'POST'])
@login_required
def new_turf():
    form = TurfForm()
    if form.validate_on_submit():
        turf = Turf(
            name=form.name.data,
            description=form.description.data,
            address=form.address.data,
            city=form.city.data,
            state=form.state.data,
            country=form.country.data,
            postal_code=form.postal_code.data,
            base_price_per_hour=form.base_price_per_hour.data,
            features=form.features.data,
            size=form.size.data,
            indoor=form.indoor.data,
            owner_id=current_user.id
        )
        
        db.session.add(turf)
        db.session.commit()
        
        # Add primary image if provided
        if form.image_url.data:
            image = TurfImage(
                url=form.image_url.data,
                is_primary=True,
                turf_id=turf.id
            )
            db.session.add(image)
            
        # Add additional images if provided
        if form.additional_images.data:
            additional_urls = [url.strip() for url in form.additional_images.data.split(',') if url.strip()]
            for url in additional_urls:
                image = TurfImage(
                    url=url,
                    is_primary=False,
                    turf_id=turf.id
                )
                db.session.add(image)
                
        db.session.commit()
        
        flash('Your turf has been created!', 'success')
        return redirect(url_for('owner.turfs'))
    
    return render_template('owner/manage_turf.html', form=form, title='Add New Turf')

@owner.route('/turfs/<int:turf_id>/edit', methods=['GET', 'POST'])
@login_required
def edit_turf(turf_id):
    turf = Turf.query.get_or_404(turf_id)
    
    # Check if current user owns this turf
    if turf.owner_id != current_user.id:
        abort(403)
    
    form = TurfForm()
    
    if form.validate_on_submit():
        turf.name = form.name.data
        turf.description = form.description.data
        turf.address = form.address.data
        turf.city = form.city.data
        turf.state = form.state.data
        turf.country = form.country.data
        turf.postal_code = form.postal_code.data
        turf.base_price_per_hour = form.base_price_per_hour.data
        turf.features = form.features.data
        turf.size = form.size.data
        turf.indoor = form.indoor.data
        
        db.session.commit()
        
        # Update primary image if provided
        if form.image_url.data:
            # Check if primary image exists
            primary_image = TurfImage.query.filter_by(turf_id=turf.id, is_primary=True).first()
            
            if primary_image:
                primary_image.url = form.image_url.data
            else:
                image = TurfImage(
                    url=form.image_url.data,
                    is_primary=True,
                    turf_id=turf.id
                )
                db.session.add(image)
        
        # Update additional images if provided
        if form.additional_images.data:
            # Delete existing non-primary images
            existing_images = TurfImage.query.filter_by(turf_id=turf.id, is_primary=False).all()
            for img in existing_images:
                db.session.delete(img)
                
            # Add new images
            additional_urls = [url.strip() for url in form.additional_images.data.split(',') if url.strip()]
            for url in additional_urls:
                image = TurfImage(
                    url=url,
                    is_primary=False,
                    turf_id=turf.id
                )
                db.session.add(image)
            
        db.session.commit()
        
        flash('Your turf has been updated!', 'success')
        return redirect(url_for('owner.turfs'))
    
    elif request.method == 'GET':
        form.name.data = turf.name
        form.description.data = turf.description
        form.address.data = turf.address
        form.city.data = turf.city
        form.state.data = turf.state
        form.country.data = turf.country
        form.postal_code.data = turf.postal_code
        form.base_price_per_hour.data = turf.base_price_per_hour
        form.features.data = turf.features
        form.size.data = turf.size
        form.indoor.data = turf.indoor
        
        # Get primary image if exists
        primary_image = TurfImage.query.filter_by(turf_id=turf.id, is_primary=True).first()
        if primary_image:
            form.image_url.data = primary_image.url
            
        # Get additional images if they exist
        additional_images = TurfImage.query.filter_by(turf_id=turf.id, is_primary=False).all()
        if additional_images:
            form.additional_images.data = ', '.join([img.url for img in additional_images])
    
    return render_template('owner/manage_turf.html', form=form, turf=turf, title='Edit Turf')

@owner.route('/turfs/<int:turf_id>/slots', methods=['GET', 'POST'])
@login_required
def manage_slots(turf_id):
    turf = Turf.query.get_or_404(turf_id)
    
    # Check if current user owns this turf
    if turf.owner_id != current_user.id:
        abort(403)
    
    form = TimeSlotForm()
    
    if form.validate_on_submit():
        time_slot = TimeSlot(
            day_of_week=form.day_of_week.data,
            start_time=form.start_time.data,
            end_time=form.end_time.data,
            price_adjustment=form.price_adjustment.data,
            turf_id=turf.id
        )
        
        db.session.add(time_slot)
        db.session.commit()
        
        flash('Time slot added successfully!', 'success')
        return redirect(url_for('owner.manage_slots', turf_id=turf.id))
    
    # Get existing time slots grouped by day
    slots_by_day = {i: [] for i in range(7)}  # 0=Monday, 6=Sunday
    
    for slot in turf.time_slots:
        slots_by_day[slot.day_of_week].append(slot)
    
    # Sort slots by start time for each day
    for day in slots_by_day:
        slots_by_day[day] = sorted(slots_by_day[day], key=lambda x: x.start_time)
    
    days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
    
    return render_template(
        'owner/time_slots.html',
        turf=turf,
        form=form,
        slots_by_day=slots_by_day,
        days=days,
        title='Manage Time Slots'
    )

@owner.route('/turfs/<int:turf_id>/slots/<int:slot_id>/delete', methods=['POST'])
@login_required
def delete_slot(turf_id, slot_id):
    turf = Turf.query.get_or_404(turf_id)
    
    # Check if current user owns this turf
    if turf.owner_id != current_user.id:
        abort(403)
    
    slot = TimeSlot.query.get_or_404(slot_id)
    
    # Check if slot belongs to the turf
    if slot.turf_id != turf.id:
        abort(403)
    
    db.session.delete(slot)
    db.session.commit()
    
    flash('Time slot deleted successfully!', 'success')
    return redirect(url_for('owner.manage_slots', turf_id=turf.id))

@owner.route('/bookings')
@login_required
def bookings():
    status_filter = request.args.get('status', 'all')
    turf_id = request.args.get('turf_id', 'all')
    page = request.args.get('page', 1, type=int)
    
    # Build query for bookings on turfs owned by current user
    query = db.session.query(Booking).join(Turf).filter(Turf.owner_id == current_user.id)
    
    # Apply filters
    if status_filter != 'all':
        query = query.filter(Booking.status == status_filter)
    
    if turf_id != 'all':
        query = query.filter(Booking.turf_id == turf_id)
    
    # Order by most recent first
    bookings = query.order_by(Booking.booking_date.desc(), Booking.start_time.desc()).paginate(
        page=page, per_page=10, error_out=False
    )
    
    # Get all turfs for the filter dropdown
    turfs = Turf.query.filter_by(owner_id=current_user.id).all()
    
    return render_template(
        'owner/bookings.html',
        bookings=bookings,
        status_filter=status_filter,
        turf_id=turf_id,
        turfs=turfs,
        title='Bookings'
    )

@owner.route('/bookings/<int:booking_id>/respond', methods=['POST'])
@login_required
def respond_booking(booking_id):
    booking = Booking.query.get_or_404(booking_id)
    
    # Check if booking is for a turf owned by current user
    turf = Turf.query.get_or_404(booking.turf_id)
    if turf.owner_id != current_user.id:
        abort(403)
    
    action = request.form.get('action')
    
    if action == 'accept':
        # Accept booking at the proposed/original price
        booking.status = BookingStatus.CONFIRMED
        flash('Booking has been confirmed!', 'success')
    
    elif action == 'reject':
        # Reject booking
        booking.status = BookingStatus.CANCELLED
        flash('Booking has been rejected.', 'info')
    
    elif action == 'counter':
        # Make a counter offer
        counter_price = float(request.form.get('counter_price', 0))
        
        if counter_price <= 0:
            flash('Please enter a valid counter price.', 'danger')
            return redirect(url_for('owner.bookings'))
        
        # Create negotiation record
        negotiation = Negotiation(
            booking_id=booking.id,
            proposed_price=booking.total_price,
            counter_price=counter_price,
            proposed_by='owner',
            message=request.form.get('message', '')
        )
        
        db.session.add(negotiation)
        
        # Update booking status
        booking.status = BookingStatus.NEGOTIATING
        booking.total_price = counter_price  # Update with counter offer
        
        flash('Counter offer has been sent to the user.', 'success')
    
    db.session.commit()
    return redirect(url_for('owner.bookings'))

@owner.route('/analytics')
@login_required
def analytics():
    # Get all turfs owned by the current user
    turfs = Turf.query.filter_by(owner_id=current_user.id).all()
    
    # Default to the first turf if none specified
    selected_turf_id = request.args.get('turf_id', None, type=int)
    
    if not turfs:
        flash('You need to add a turf before viewing analytics.', 'info')
        return redirect(url_for('owner.turfs'))
    
    if selected_turf_id is None and turfs:
        selected_turf_id = turfs[0].id
    
    # Get selected turf
    selected_turf = next((t for t in turfs if t.id == selected_turf_id), None)
    
    if not selected_turf:
        flash('Selected turf not found.', 'danger')
        return redirect(url_for('owner.analytics'))
    
    # Time periods for analytics
    current_date = datetime.utcnow().date()
    thirty_days_ago = current_date - timedelta(days=30)
    ninety_days_ago = current_date - timedelta(days=90)
    
    # Calculate revenue metrics
    monthly_revenue = db.session.query(db.func.sum(Booking.total_price)).filter(
        Booking.turf_id == selected_turf.id,
        Booking.booking_date >= thirty_days_ago,
        Booking.booking_date <= current_date,
        Booking.status == BookingStatus.COMPLETED,
        Booking.payment_status == 'paid'
    ).scalar() or 0
    
    # Get booking counts
    total_bookings = Booking.query.filter(
        Booking.turf_id == selected_turf.id,
        Booking.status.in_([BookingStatus.CONFIRMED, BookingStatus.COMPLETED])
    ).count()
    
    recent_bookings = Booking.query.filter(
        Booking.turf_id == selected_turf.id,
        Booking.booking_date >= thirty_days_ago,
        Booking.status.in_([BookingStatus.CONFIRMED, BookingStatus.COMPLETED])
    ).count()
    
    # Get data for booking trend chart (last 90 days)
    booking_trend = db.session.query(
        Booking.booking_date, 
        db.func.count(Booking.id)
    ).filter(
        Booking.turf_id == selected_turf.id,
        Booking.booking_date >= ninety_days_ago,
        Booking.booking_date <= current_date,
        Booking.status.in_([BookingStatus.CONFIRMED, BookingStatus.COMPLETED])
    ).group_by(
        Booking.booking_date
    ).all()
    
    # Format for chart.js
    dates = [b[0].strftime('%Y-%m-%d') for b in booking_trend]
    counts = [b[1] for b in booking_trend]
    
    # Get data for weekly distribution chart
    weekly_distribution = db.session.query(
        db.func.extract('dow', Booking.booking_date).label('day_of_week'),
        db.func.count(Booking.id)
    ).filter(
        Booking.turf_id == selected_turf.id,
        Booking.status.in_([BookingStatus.CONFIRMED, BookingStatus.COMPLETED])
    ).group_by(
        'day_of_week'
    ).all()
    
    # Format for chart.js (0=Sunday, 6=Saturday)
    days_of_week = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
    weekly_data = [0] * 7
    
    for day, count in weekly_distribution:
        weekly_data[int(day)] = count
    
    # Get negotiation stats
    negotiations = db.session.query(
        db.func.count(Negotiation.id).label('count'),
        db.func.avg(
            db.case(
                (Negotiation.is_accepted == True, 100 * Negotiation.counter_price / Negotiation.proposed_price),
                else_=None
            )
        ).label('avg_percentage')
    ).join(Booking).filter(
        Booking.turf_id == selected_turf.id,
        Negotiation.proposed_by == 'user'  # User-initiated negotiations
    ).one()
    
    negotiation_count = negotiations.count or 0
    avg_negotiation_percentage = round(negotiations.avg_percentage or 100, 2)
    
    # Data for charts and JavaScript
    chart_data_json = {
        'dates': dates,
        'counts': counts,
        'weekly_labels': days_of_week,
        'weekly_data': weekly_data
    }
    
    # For Python / template logic
    chart_data = {
        'weekly_data': weekly_data,
        'weekly_labels': days_of_week
    }
    
    # Calculate most popular/least popular days
    most_popular_day_index = 0
    least_popular_day_index = 0
    max_bookings = 0
    min_bookings = float('inf')
    
    for i, bookings in enumerate(weekly_data):
        if bookings > max_bookings:
            max_bookings = bookings
            most_popular_day_index = i
        if bookings < min_bookings and bookings > 0:
            min_bookings = bookings
            least_popular_day_index = i
    
    most_popular_day = days_of_week[most_popular_day_index] if weekly_data else 'No data'
    least_popular_day = days_of_week[least_popular_day_index] if weekly_data and min_bookings < float('inf') else 'No data'
    
    return render_template(
        'owner/analytics.html',
        turfs=turfs,
        selected_turf=selected_turf,
        monthly_revenue=monthly_revenue,
        total_bookings=total_bookings,
        recent_bookings=recent_bookings,
        negotiation_count=negotiation_count,
        avg_negotiation_percentage=avg_negotiation_percentage,
        chart_data=chart_data,
        chart_data_json=json.dumps(chart_data_json),
        most_popular_day=most_popular_day,
        least_popular_day=least_popular_day,
        title='Turf Analytics'
    )
