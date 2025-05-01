from flask import Blueprint, render_template, redirect, url_for, flash, request, abort
from flask_login import login_required, current_user
from datetime import datetime, timedelta
import json

from app import db
from models import User, Turf, Booking, BookingStatus, Dispute, UserRole
from forms import AdminProfileForm

admin = Blueprint('admin', __name__)

@admin.before_request
def check_admin():
    if not current_user.is_authenticated or not current_user.is_admin():
        abort(403)  # Forbidden

@admin.route('/dashboard')
@login_required
def dashboard():
    # Count of users by role
    users_count = User.query.filter_by(role=UserRole.USER).count()
    owners_count = User.query.filter_by(role=UserRole.OWNER).count()
    
    # Count of turfs and bookings
    turfs_count = Turf.query.count()
    
    # Current date for filtering
    current_date = datetime.utcnow().date()
    thirty_days_ago = current_date - timedelta(days=30)
    
    # Bookings in the last 30 days
    recent_bookings_count = Booking.query.filter(
        Booking.booking_date >= thirty_days_ago,
        Booking.status.in_([BookingStatus.CONFIRMED, BookingStatus.COMPLETED])
    ).count()
    
    # Revenue in the last 30 days
    recent_revenue = db.session.query(db.func.sum(Booking.total_price)).filter(
        Booking.booking_date >= thirty_days_ago,
        Booking.status == BookingStatus.COMPLETED,
        Booking.payment_status == 'paid'
    ).scalar() or 0
    
    # Open disputes
    open_disputes_count = Dispute.query.filter_by(status='open').count()
    
    # Get registration trends for chart (last 90 days)
    ninety_days_ago = current_date - timedelta(days=90)
    user_registrations = db.session.query(
        db.func.date_trunc('day', User.created_at).label('date'),
        db.func.count(User.id).label('count')
    ).filter(
        User.created_at >= ninety_days_ago,
        User.role == UserRole.USER
    ).group_by('date').order_by('date').all()
    
    owner_registrations = db.session.query(
        db.func.date_trunc('day', User.created_at).label('date'),
        db.func.count(User.id).label('count')
    ).filter(
        User.created_at >= ninety_days_ago,
        User.role == UserRole.OWNER
    ).group_by('date').order_by('date').all()
    
    # Format for chart.js
    dates = []
    user_counts = []
    owner_counts = []
    
    for date, count in user_registrations:
        dates.append(date.strftime('%Y-%m-%d'))
        user_counts.append(count)
    
    owner_dates = [date.strftime('%Y-%m-%d') for date, _ in owner_registrations]
    owner_counts_map = {date: count for date, count in owner_registrations}
    
    # Fill in missing owner counts for all dates
    for date in dates:
        owner_counts.append(owner_counts_map.get(date, 0))
    
    # Add any owner dates that might not be in user_dates
    for date in owner_dates:
        if date not in dates:
            dates.append(date)
            user_counts.append(0)
            owner_counts.append(owner_counts_map.get(date, 0))
    
    # Sort by date
    combined = sorted(zip(dates, user_counts, owner_counts), key=lambda x: x[0])
    dates = [c[0] for c in combined]
    user_counts = [c[1] for c in combined]
    owner_counts = [c[2] for c in combined]
    
    # Recent users
    recent_users = User.query.order_by(User.created_at.desc()).limit(5).all()
    
    # Recent bookings
    recent_bookings = Booking.query.order_by(Booking.created_at.desc()).limit(5).all()
    
    # Chart data
    chart_data = {
        'dates': dates,
        'user_counts': user_counts,
        'owner_counts': owner_counts
    }
    
    return render_template(
        'admin/dashboard.html',
        users_count=users_count,
        owners_count=owners_count,
        turfs_count=turfs_count,
        recent_bookings_count=recent_bookings_count,
        recent_revenue=recent_revenue,
        open_disputes_count=open_disputes_count,
        recent_users=recent_users,
        recent_bookings=recent_bookings,
        chart_data=json.dumps(chart_data),
        title='Admin Dashboard'
    )

@admin.route('/users')
@login_required
def users():
    role_filter = request.args.get('role', 'all')
    page = request.args.get('page', 1, type=int)
    
    # Build query
    query = User.query
    
    if role_filter != 'all':
        query = query.filter_by(role=role_filter)
    
    # Order by most recent first
    users = query.order_by(User.created_at.desc()).paginate(
        page=page, per_page=20, error_out=False
    )
    
    return render_template(
        'admin/users.html',
        users=users,
        role_filter=role_filter,
        title='Manage Users'
    )

@admin.route('/users/<int:user_id>', methods=['GET', 'POST'])
@login_required
def edit_user(user_id):
    user = User.query.get_or_404(user_id)
    form = AdminProfileForm()
    
    if form.validate_on_submit():
        user.username = form.username.data
        user.email = form.email.data
        user.phone_number = form.phone_number.data
        user.role = form.role.data
        
        # If password change is requested
        if form.new_password.data:
            user.set_password(form.new_password.data)
        
        db.session.commit()
        flash(f'User {user.username} has been updated!', 'success')
        return redirect(url_for('admin.users'))
    
    elif request.method == 'GET':
        form.username.data = user.username
        form.email.data = user.email
        form.phone_number.data = user.phone_number
        form.role.data = user.role
    
    return render_template('admin/edit_user.html', form=form, user=user, title='Edit User')

@admin.route('/turfs')
@login_required
def turfs():
    page = request.args.get('page', 1, type=int)
    active_filter = request.args.get('active', 'all')
    
    # Build query
    query = Turf.query
    
    if active_filter != 'all':
        query = query.filter_by(active=(active_filter == 'true'))
    
    # Order by most recent first
    turfs = query.order_by(Turf.created_at.desc()).paginate(
        page=page, per_page=10, error_out=False
    )
    
    return render_template(
        'admin/turfs.html',
        turfs=turfs,
        active_filter=active_filter,
        title='Manage Turfs'
    )

@admin.route('/turfs/<int:turf_id>/toggle', methods=['POST'])
@login_required
def toggle_turf(turf_id):
    turf = Turf.query.get_or_404(turf_id)
    turf.active = not turf.active
    db.session.commit()
    
    status = 'activated' if turf.active else 'deactivated'
    flash(f'Turf "{turf.name}" has been {status}!', 'success')
    return redirect(url_for('admin.turfs'))

@admin.route('/disputes')
@login_required
def disputes():
    status_filter = request.args.get('status', 'all')
    page = request.args.get('page', 1, type=int)
    
    # Build query
    query = Dispute.query
    
    if status_filter != 'all':
        query = query.filter_by(status=status_filter)
    
    # Order by most recent first
    disputes = query.order_by(Dispute.created_at.desc()).paginate(
        page=page, per_page=10, error_out=False
    )
    
    return render_template(
        'admin/disputes.html',
        disputes=disputes,
        status_filter=status_filter,
        title='Manage Disputes'
    )

@admin.route('/disputes/<int:dispute_id>', methods=['GET', 'POST'])
@login_required
def resolve_dispute(dispute_id):
    dispute = Dispute.query.get_or_404(dispute_id)
    
    if request.method == 'POST':
        action = request.form.get('action')
        resolution = request.form.get('resolution')
        
        if not resolution:
            flash('Please provide a resolution message.', 'danger')
            return redirect(url_for('admin.resolve_dispute', dispute_id=dispute.id))
        
        if action == 'resolve':
            dispute.status = 'resolved'
            dispute.resolution = resolution
            dispute.resolved_at = datetime.utcnow()
            
            flash('Dispute has been resolved!', 'success')
        elif action == 'close':
            dispute.status = 'closed'
            dispute.resolution = resolution
            dispute.resolved_at = datetime.utcnow()
            
            flash('Dispute has been closed without resolution.', 'info')
        
        db.session.commit()
        return redirect(url_for('admin.disputes'))
    
    # Get related booking and turf details
    booking = Booking.query.get(dispute.booking_id)
    turf = Turf.query.get(booking.turf_id) if booking else None
    
    return render_template(
        'admin/resolve_dispute.html',
        dispute=dispute,
        booking=booking,
        turf=turf,
        title='Resolve Dispute'
    )
