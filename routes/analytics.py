from flask import Blueprint, render_template, request, jsonify
from flask_login import login_required, current_user
from models import Turf, Booking, Review, BookingStatus, User
from sqlalchemy import func, desc, cast, Date
from sqlalchemy.sql import text
from datetime import datetime, timedelta, date
import calendar
import logging

# Create Blueprint
analytics = Blueprint('analytics', __name__)

@analytics.route('/owner/analytics')
@login_required
def owner_analytics():
    """Main analytics dashboard for turf owners"""
    if not current_user.is_owner():
        return render_template('error.html', message="Access denied. Owner privileges required.")
    
    # Get owner's turfs
    turfs = Turf.query.filter_by(owner_id=current_user.id).all()
    
    return render_template('owner/analytics.html', turfs=turfs)

@analytics.route('/api/analytics/booking-stats')
@login_required
def booking_stats():
    """API endpoint for booking statistics"""
    if not current_user.is_owner():
        return jsonify({"error": "Access denied"}), 403
    
    turf_id = request.args.get('turf_id', type=int)
    period = request.args.get('period', 'month')  # day, week, month, year
    
    # Validate turf ownership
    if turf_id:
        turf = Turf.query.get_or_404(turf_id)
        if turf.owner_id != current_user.id:
            return jsonify({"error": "Access denied"}), 403
    
    # Define time period for query
    today = datetime.now().date()
    if period == 'day':
        start_date = today
    elif period == 'week':
        start_date = today - timedelta(days=7)
    elif period == 'month':
        start_date = today - timedelta(days=30)
    elif period == 'year':
        start_date = today - timedelta(days=365)
    else:
        start_date = today - timedelta(days=30)  # Default to month
    
    # Base query
    query = Booking.query.filter(Booking.booking_date >= start_date)
    
    # Filter by turf if specified
    if turf_id:
        query = query.filter_by(turf_id=turf_id)
    else:
        # Get all turfs owned by current user
        owned_turf_ids = [turf.id for turf in Turf.query.filter_by(owner_id=current_user.id)]
        query = query.filter(Booking.turf_id.in_(owned_turf_ids))
    
    # Get total counts
    total_bookings = query.count()
    confirmed_bookings = query.filter_by(status=BookingStatus.CONFIRMED).count()
    completed_bookings = query.filter_by(status=BookingStatus.COMPLETED).count()
    cancelled_bookings = query.filter_by(status=BookingStatus.CANCELLED).count()
    pending_bookings = query.filter_by(status=BookingStatus.PENDING).count()
    
    # Get total revenue (only from confirmed or completed bookings)
    revenue = query.filter(Booking.status.in_([BookingStatus.CONFIRMED, BookingStatus.COMPLETED])) \
                  .with_entities(func.sum(Booking.total_price)).scalar() or 0
    
    # Calculate average booking value
    avg_booking_value = revenue / (confirmed_bookings + completed_bookings) if (confirmed_bookings + completed_bookings) > 0 else 0
    
    # Get bookings grouped by date
    daily_bookings = query.with_entities(
        cast(Booking.booking_date, Date).label('date'),
        func.count().label('count')
    ).group_by(cast(Booking.booking_date, Date)).order_by(cast(Booking.booking_date, Date)).all()
    
    daily_data = []
    for day in daily_bookings:
        daily_data.append({
            'date': day.date.strftime('%Y-%m-%d'),
            'count': day.count
        })
    
    # Get bookings by time of day (grouped by hour)
    hourly_bookings = query.with_entities(
        func.extract('hour', Booking.start_time).label('hour'),
        func.count().label('count')
    ).group_by(func.extract('hour', Booking.start_time)).order_by(func.extract('hour', Booking.start_time)).all()
    
    hourly_data = []
    for hour_data in hourly_bookings:
        hourly_data.append({
            'hour': int(hour_data.hour),
            'count': hour_data.count
        })
    
    # Get bookings by status
    status_distribution = [
        {'status': 'Confirmed', 'count': confirmed_bookings},
        {'status': 'Completed', 'count': completed_bookings},
        {'status': 'Cancelled', 'count': cancelled_bookings},
        {'status': 'Pending', 'count': pending_bookings}
    ]
    
    return jsonify({
        'total_bookings': total_bookings,
        'confirmed_bookings': confirmed_bookings,
        'completed_bookings': completed_bookings,
        'cancelled_bookings': cancelled_bookings,
        'pending_bookings': pending_bookings,
        'total_revenue': round(revenue, 2),
        'avg_booking_value': round(avg_booking_value, 2),
        'daily_data': daily_data,
        'hourly_data': hourly_data,
        'status_distribution': status_distribution
    })

@analytics.route('/api/analytics/revenue-stats')
@login_required
def revenue_stats():
    """API endpoint for revenue statistics"""
    if not current_user.is_owner():
        return jsonify({"error": "Access denied"}), 403
    
    turf_id = request.args.get('turf_id', type=int)
    period = request.args.get('period', 'month')  # day, week, month, year
    
    # Validate turf ownership
    if turf_id:
        turf = Turf.query.get_or_404(turf_id)
        if turf.owner_id != current_user.id:
            return jsonify({"error": "Access denied"}), 403
    
    # Define time period for query
    today = datetime.now().date()
    if period == 'day':
        start_date = today
        previous_start = today - timedelta(days=1)
    elif period == 'week':
        start_date = today - timedelta(days=7)
        previous_start = start_date - timedelta(days=7)
    elif period == 'month':
        start_date = today - timedelta(days=30)
        previous_start = start_date - timedelta(days=30)
    elif period == 'year':
        start_date = today - timedelta(days=365)
        previous_start = start_date - timedelta(days=365)
    else:
        start_date = today - timedelta(days=30)  # Default to month
        previous_start = start_date - timedelta(days=30)
    
    # Base query
    query = Booking.query.filter(
        Booking.booking_date >= start_date,
        Booking.status.in_([BookingStatus.CONFIRMED, BookingStatus.COMPLETED])
    )
    
    # Previous period query for comparison
    prev_query = Booking.query.filter(
        Booking.booking_date >= previous_start,
        Booking.booking_date < start_date,
        Booking.status.in_([BookingStatus.CONFIRMED, BookingStatus.COMPLETED])
    )
    
    # Filter by turf if specified
    if turf_id:
        query = query.filter_by(turf_id=turf_id)
        prev_query = prev_query.filter_by(turf_id=turf_id)
    else:
        # Get all turfs owned by current user
        owned_turf_ids = [turf.id for turf in Turf.query.filter_by(owner_id=current_user.id)]
        query = query.filter(Booking.turf_id.in_(owned_turf_ids))
        prev_query = prev_query.filter(Booking.turf_id.in_(owned_turf_ids))
    
    # Get total revenue
    current_revenue = query.with_entities(func.sum(Booking.total_price)).scalar() or 0
    previous_revenue = prev_query.with_entities(func.sum(Booking.total_price)).scalar() or 0
    
    # Calculate revenue change
    revenue_change = 0
    if previous_revenue > 0:
        revenue_change = ((current_revenue - previous_revenue) / previous_revenue) * 100
    
    # Get revenue by payment method
    payment_method_revenue = query.with_entities(
        Booking.payment_method,
        func.sum(Booking.total_price).label('revenue')
    ).group_by(Booking.payment_method).all()
    
    payment_methods = []
    for method in payment_method_revenue:
        payment_methods.append({
            'method': 'Online Payment' if method.payment_method == 'pay_online' else 'Pay on Arrival',
            'revenue': round(method.revenue, 2)
        })
    
    # Get daily revenue
    daily_revenue = query.with_entities(
        cast(Booking.booking_date, Date).label('date'),
        func.sum(Booking.total_price).label('revenue')
    ).group_by(cast(Booking.booking_date, Date)).order_by(cast(Booking.booking_date, Date)).all()
    
    daily_data = []
    for day in daily_revenue:
        daily_data.append({
            'date': day.date.strftime('%Y-%m-%d'),
            'revenue': round(day.revenue, 2)
        })
    
    # Get revenue by turf (if multiple turfs)
    turf_revenue = []
    if not turf_id:
        turf_data = query.with_entities(
            Booking.turf_id,
            func.sum(Booking.total_price).label('revenue')
        ).group_by(Booking.turf_id).all()
        
        for data in turf_data:
            turf = Turf.query.get(data.turf_id)
            turf_revenue.append({
                'turf_name': turf.name,
                'revenue': round(data.revenue, 2)
            })
    
    return jsonify({
        'current_revenue': round(current_revenue, 2),
        'previous_revenue': round(previous_revenue, 2),
        'revenue_change': round(revenue_change, 2),
        'payment_methods': payment_methods,
        'daily_revenue': daily_data,
        'turf_revenue': turf_revenue
    })

@analytics.route('/api/analytics/customer-stats')
@login_required
def customer_stats():
    """API endpoint for customer statistics"""
    if not current_user.is_owner():
        return jsonify({"error": "Access denied"}), 403
    
    turf_id = request.args.get('turf_id', type=int)
    period = request.args.get('period', 'month')  # day, week, month, year
    
    # Validate turf ownership
    if turf_id:
        turf = Turf.query.get_or_404(turf_id)
        if turf.owner_id != current_user.id:
            return jsonify({"error": "Access denied"}), 403
    
    # Define time period for query
    today = datetime.now().date()
    if period == 'day':
        start_date = today
    elif period == 'week':
        start_date = today - timedelta(days=7)
    elif period == 'month':
        start_date = today - timedelta(days=30)
    elif period == 'year':
        start_date = today - timedelta(days=365)
    else:
        start_date = today - timedelta(days=30)  # Default to month
    
    # Base query
    query = Booking.query.filter(Booking.booking_date >= start_date)
    
    # Filter by turf if specified
    if turf_id:
        query = query.filter_by(turf_id=turf_id)
    else:
        # Get all turfs owned by current user
        owned_turf_ids = [turf.id for turf in Turf.query.filter_by(owner_id=current_user.id)]
        query = query.filter(Booking.turf_id.in_(owned_turf_ids))
    
    # Get unique customers count
    unique_customers = query.with_entities(Booking.user_id).distinct().count()
    
    # Get returning vs new customers
    # This is simplified - in production you'd track first booking date per customer
    total_customers = query.with_entities(Booking.user_id).distinct().all()
    total_customers_ids = [c.user_id for c in total_customers]
    
    # Count customers with multiple bookings
    repeat_customers = 0
    for user_id in total_customers_ids:
        bookings = query.filter_by(user_id=user_id).count()
        if bookings > 1:
            repeat_customers += 1
    
    new_customers = unique_customers - repeat_customers
    
    # Get top customers
    top_customers_data = query.with_entities(
        Booking.user_id,
        func.count().label('booking_count'),
        func.sum(Booking.total_price).label('total_spent')
    ).group_by(Booking.user_id).order_by(func.sum(Booking.total_price).desc()).limit(5).all()
    
    top_customers = []
    for data in top_customers_data:
        user = User.query.get(data.user_id)
        top_customers.append({
            'username': user.username,
            'booking_count': data.booking_count,
            'total_spent': round(data.total_spent, 2)
        })
    
    # Get customer satisfaction from reviews
    review_query = Review.query.join(Booking).filter(
        Booking.booking_date >= start_date
    )
    
    if turf_id:
        review_query = review_query.filter(Review.turf_id == turf_id)
    else:
        review_query = review_query.filter(Review.turf_id.in_(owned_turf_ids))
    
    avg_rating = review_query.with_entities(func.avg(Review.rating)).scalar() or 0
    rating_count = review_query.count()
    
    # Get rating distribution
    rating_distribution = []
    for i in range(1, 6):
        count = review_query.filter(Review.rating == i).count()
        rating_distribution.append({
            'rating': i,
            'count': count
        })
    
    return jsonify({
        'unique_customers': unique_customers,
        'repeat_customers': repeat_customers,
        'new_customers': new_customers,
        'repeat_customer_rate': round((repeat_customers / unique_customers * 100) if unique_customers > 0 else 0, 2),
        'top_customers': top_customers,
        'avg_rating': round(avg_rating, 2),
        'rating_count': rating_count,
        'rating_distribution': rating_distribution
    })

@analytics.route('/api/analytics/usage-stats')
@login_required
def usage_stats():
    """API endpoint for usage statistics"""
    if not current_user.is_owner():
        return jsonify({"error": "Access denied"}), 403
    
    turf_id = request.args.get('turf_id', type=int)
    period = request.args.get('period', 'month')  # day, week, month, year
    
    # Validate turf ownership
    if turf_id:
        turf = Turf.query.get_or_404(turf_id)
        if turf.owner_id != current_user.id:
            return jsonify({"error": "Access denied"}), 403
    
    # Define time period for query
    today = datetime.now().date()
    if period == 'day':
        start_date = today
    elif period == 'week':
        start_date = today - timedelta(days=7)
    elif period == 'month':
        start_date = today - timedelta(days=30)
    elif period == 'year':
        start_date = today - timedelta(days=365)
    else:
        start_date = today - timedelta(days=30)  # Default to month
    
    # Base query for completed and confirmed bookings
    query = Booking.query.filter(
        Booking.booking_date >= start_date,
        Booking.status.in_([BookingStatus.CONFIRMED, BookingStatus.COMPLETED])
    )
    
    # Filter by turf if specified
    if turf_id:
        query = query.filter_by(turf_id=turf_id)
    else:
        # Get all turfs owned by current user
        owned_turf_ids = [turf.id for turf in Turf.query.filter_by(owner_id=current_user.id)]
        query = query.filter(Booking.turf_id.in_(owned_turf_ids))
    
    # Get usage by day of week
    weekday_usage = query.with_entities(
        func.extract('dow', Booking.booking_date).label('weekday'),
        func.count().label('count')
    ).group_by(func.extract('dow', Booking.booking_date)).all()
    
    weekday_data = [0] * 7  # Initialize with zeros for all days
    for day in weekday_usage:
        # PostgreSQL's extract(dow) returns 0 for Sunday and 1-6 for Monday-Saturday
        weekday = int(day.weekday)
        # Convert to 0 for Monday, 6 for Sunday to match JavaScript's getDay()
        weekday = (weekday + 6) % 7
        weekday_data[weekday] = day.count
    
    # Get usage by hour
    hourly_usage = query.with_entities(
        func.extract('hour', Booking.start_time).label('hour'),
        func.count().label('count')
    ).group_by(func.extract('hour', Booking.start_time)).order_by(func.extract('hour', Booking.start_time)).all()
    
    hourly_data = []
    for hour_data in hourly_usage:
        hourly_data.append({
            'hour': int(hour_data.hour),
            'count': hour_data.count
        })
    
    # Compute utilization rate (total booked hours / total available hours)
    # This is a simplification - ideally you'd account for actual operating hours
    
    # Get total booked hours
    total_booked_hours = 0
    bookings = query.all()
    for booking in bookings:
        start_hour = booking.start_time.hour
        end_hour = booking.end_time.hour
        total_booked_hours += (end_hour - start_hour)
    
    # Calculate available hours based on time period and turfs
    days_in_period = (today - start_date).days + 1
    
    # Assume operating hours from 8am to 10pm (14 hours per day)
    operating_hours_per_day = 14
    
    if turf_id:
        total_available_hours = days_in_period * operating_hours_per_day
    else:
        # For multiple turfs, multiply by the number of turfs
        turf_count = len(owned_turf_ids)
        total_available_hours = days_in_period * operating_hours_per_day * turf_count
    
    utilization_rate = (total_booked_hours / total_available_hours) * 100 if total_available_hours > 0 else 0
    
    # Get peak usage times (top 3 hours)
    peak_hours = sorted(hourly_data, key=lambda x: x['count'], reverse=True)[:3]
    
    # Get peak days (top 3 days)
    weekday_names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
    peak_days = []
    for i, count in enumerate(weekday_data):
        peak_days.append({'day': weekday_names[i], 'count': count})
    
    peak_days = sorted(peak_days, key=lambda x: x['count'], reverse=True)[:3]
    
    return jsonify({
        'weekday_data': [
            {'day': 'Monday', 'count': weekday_data[0]},
            {'day': 'Tuesday', 'count': weekday_data[1]},
            {'day': 'Wednesday', 'count': weekday_data[2]},
            {'day': 'Thursday', 'count': weekday_data[3]},
            {'day': 'Friday', 'count': weekday_data[4]},
            {'day': 'Saturday', 'count': weekday_data[5]},
            {'day': 'Sunday', 'count': weekday_data[6]}
        ],
        'hourly_data': hourly_data,
        'utilization_rate': round(utilization_rate, 2),
        'total_booked_hours': total_booked_hours,
        'peak_hours': peak_hours,
        'peak_days': peak_days
    })