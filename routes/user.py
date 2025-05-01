from flask import Blueprint, render_template, redirect, url_for, flash, request, abort
from flask_login import login_required, current_user
from datetime import datetime
from sqlalchemy import func

from app import db
from models import User, Turf, Booking, BookingStatus, Review, Favorite
from forms import UserProfileForm, BookingSearchForm, AdvancedSearchForm

user = Blueprint('user', __name__)

@user.route('/dashboard')
@login_required
def dashboard():
    if current_user.is_owner():
        return redirect(url_for('owner.dashboard'))
    if current_user.is_admin():
        return redirect(url_for('admin.dashboard'))
    
    # Get recent and upcoming bookings
    recent_bookings = Booking.query.filter_by(
        user_id=current_user.id
    ).filter(
        Booking.status.in_([BookingStatus.CONFIRMED, BookingStatus.COMPLETED])
    ).order_by(
        Booking.booking_date.desc()
    ).limit(5).all()
    
    upcoming_bookings = Booking.query.filter_by(
        user_id=current_user.id,
        status=BookingStatus.CONFIRMED
    ).filter(
        Booking.booking_date >= datetime.utcnow().date()
    ).order_by(
        Booking.booking_date.asc()
    ).limit(5).all()
    
    # Get recent turfs you've played at
    played_turfs = db.session.query(Turf).join(Booking).filter(
        Booking.user_id == current_user.id,
        Booking.status.in_([BookingStatus.CONFIRMED, BookingStatus.COMPLETED])
    ).distinct().limit(3).all()
    
    # Get featured or recommended turfs
    recommended_turfs = Turf.query.filter_by(active=True).order_by(db.func.random()).limit(3).all()
    
    return render_template(
        'user/dashboard.html',
        recent_bookings=recent_bookings,
        upcoming_bookings=upcoming_bookings,
        played_turfs=played_turfs,
        recommended_turfs=recommended_turfs,
        title='Dashboard'
    )

@user.route('/profile', methods=['GET', 'POST'])
@login_required
def profile():
    form = UserProfileForm()
    
    if form.validate_on_submit():
        current_user.username = form.username.data
        current_user.phone_number = form.phone_number.data
        
        # Check if password should be updated
        if form.new_password.data:
            current_user.set_password(form.new_password.data)
        
        db.session.commit()
        flash('Your profile has been updated!', 'success')
        return redirect(url_for('user.profile'))
    elif request.method == 'GET':
        form.username.data = current_user.username
        form.email.data = current_user.email
        form.phone_number.data = current_user.phone_number
    
    return render_template('user/profile.html', form=form, title='My Profile')

@user.route('/bookings')
@login_required
def bookings():
    status_filter = request.args.get('status', 'all')
    page = request.args.get('page', 1, type=int)
    
    # Build query based on filter
    query = Booking.query.filter_by(user_id=current_user.id)
    
    if status_filter != 'all':
        query = query.filter_by(status=status_filter)
    
    # Order by most recent first
    bookings = query.order_by(Booking.booking_date.desc(), Booking.start_time.desc()).paginate(
        page=page, per_page=10, error_out=False
    )
    
    return render_template(
        'user/bookings.html',
        bookings=bookings,
        status_filter=status_filter,
        title='My Bookings'
    )

@user.route('/search', methods=['GET', 'POST'])
def search():
    form = BookingSearchForm()
    
    # If form is submitted or if there are GET parameters
    if form.validate_on_submit() or request.args.get('city'):
        # Get search parameters from form or URL
        city = form.city.data or request.args.get('city', '')
        date = form.date.data or request.args.get('date', None)
        if isinstance(date, str) and date:
            try:
                date = datetime.strptime(date, '%Y-%m-%d').date()
            except ValueError:
                date = None
        min_price = form.min_price.data or request.args.get('min_price', None, type=float)
        max_price = form.max_price.data or request.args.get('max_price', None, type=float)
        indoor = form.indoor.data if form.indoor.data is not None else request.args.get('indoor', None) 
        if indoor == 'True':
            indoor = True
        elif indoor == 'False':
            indoor = False
        
        # Build query
        query = Turf.query.filter_by(active=True)
        
        if city:
            query = query.filter(Turf.city.ilike(f'%{city}%'))
        
        if min_price is not None:
            query = query.filter(Turf.base_price_per_hour >= min_price)
        
        if max_price is not None:
            query = query.filter(Turf.base_price_per_hour <= max_price)
        
        if indoor is not None:
            query = query.filter_by(indoor=indoor)
        
        # Execute query
        turfs = query.all()
        
        # Filter by availability if date is provided
        if date:
            # This is a naive approach - in a real app we'd do more sophisticated filtering
            available_turfs = []
            for turf in turfs:
                available_slots = turf.get_available_slots(date)
                if available_slots:
                    turf.available_slots = available_slots
                    available_turfs.append(turf)
            turfs = available_turfs
        
        return render_template(
            'turf/search_results.html',
            turfs=turfs,
            city=city,
            date=date,
            min_price=min_price,
            max_price=max_price,
            indoor=indoor,
            title='Search Results'
        )
    
    # Render the search form
    featured_cities = ['Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Kolkata', 'Hyderabad']
    return render_template('turf/search.html', form=form, cities=featured_cities, title='Find a Turf')

@user.route('/advanced-search', methods=['GET', 'POST'])
def advanced_search():
    """Advanced search with more filtering options"""
    form = AdvancedSearchForm()
    
    # If form is submitted or if there are GET parameters
    if form.validate_on_submit() or request.args.get('city'):
        # Get basic search parameters
        city = form.city.data or request.args.get('city', '')
        date = form.date.data or request.args.get('date', None)
        if isinstance(date, str) and date:
            try:
                date = datetime.strptime(date, '%Y-%m-%d').date()
            except ValueError:
                date = None
        min_price = form.min_price.data or request.args.get('min_price', None, type=float)
        max_price = form.max_price.data or request.args.get('max_price', None, type=float)
        indoor = form.indoor.data if form.indoor.data is not None else request.args.get('indoor', None) 
        if indoor == 'True':
            indoor = True
        elif indoor == 'False':
            indoor = False
        
        # Get advanced filters
        has_parking = form.has_parking.data
        has_changing_room = form.has_changing_room.data
        has_shower = form.has_shower.data
        has_floodlights = form.has_floodlights.data
        has_equipment = form.has_equipment.data
        min_rating = form.min_rating.data
        surface_type = form.surface_type.data
        
        # Build query
        query = Turf.query.filter_by(active=True)
        
        # Apply basic filters
        if city:
            query = query.filter(Turf.city.ilike(f'%{city}%'))
        
        if min_price is not None:
            query = query.filter(Turf.base_price_per_hour >= min_price)
        
        if max_price is not None:
            query = query.filter(Turf.base_price_per_hour <= max_price)
        
        if indoor is not None:
            query = query.filter_by(indoor=indoor)
        
        # Apply advanced filters
        if has_parking:
            query = query.filter_by(has_parking=True)
        
        if has_changing_room:
            query = query.filter_by(has_changing_room=True)
        
        if has_shower:
            query = query.filter_by(has_shower=True)
        
        if has_floodlights:
            query = query.filter_by(has_floodlights=True)
        
        if has_equipment:
            query = query.filter_by(has_equipment=True)
        
        if surface_type:
            query = query.filter_by(surface_type=surface_type)
        
        # Apply rating filter
        if min_rating:
            # Get turfs with average rating >= min_rating
            turf_ids_with_min_rating = db.session.query(Review.turf_id).group_by(
                Review.turf_id
            ).having(func.avg(Review.rating) >= min_rating).subquery()
            
            query = query.filter(Turf.id.in_(turf_ids_with_min_rating))
        
        # Execute query
        turfs = query.all()
        
        # Filter by availability if date is provided
        if date:
            available_turfs = []
            for turf in turfs:
                available_slots = turf.get_available_slots(date)
                if available_slots:
                    turf.available_slots = available_slots
                    available_turfs.append(turf)
            turfs = available_turfs
        
        # Add favorite status for each turf if user is logged in
        if current_user.is_authenticated:
            user_favorites = {fav.turf_id for fav in current_user.favorites}
            for turf in turfs:
                turf.is_favorited = turf.id in user_favorites
        
        return render_template(
            'turf/search_results.html',
            turfs=turfs,
            city=city,
            date=date,
            min_price=min_price,
            max_price=max_price,
            indoor=indoor,
            has_parking=has_parking,
            has_changing_room=has_changing_room,
            has_shower=has_shower,
            has_floodlights=has_floodlights,
            has_equipment=has_equipment,
            min_rating=min_rating,
            surface_type=surface_type,
            advanced_search=True,
            title='Advanced Search Results'
        )
    
    # Populate the form with default values from request args
    if request.args:
        for key, value in request.args.items():
            if hasattr(form, key):
                field = getattr(form, key)
                if value.lower() == 'true':
                    field.data = True
                elif value.lower() == 'false':
                    field.data = False
                else:
                    field.data = value
    
    featured_cities = ['Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Kolkata', 'Hyderabad']
    return render_template('turf/advanced_search.html', form=form, cities=featured_cities, title='Advanced Search')
