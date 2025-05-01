from flask import Blueprint, render_template, request, redirect, url_for, flash, jsonify, abort
from flask_login import login_required, current_user
from sqlalchemy import desc

from app import db
from models import Notification
from forms import NotificationSettingsForm

notifications_bp = Blueprint('notifications', __name__)

@notifications_bp.route('/notifications')
@login_required
def list_notifications():
    """View all notifications for the current user"""
    # Get unread notifications
    unread_notifications = Notification.query.filter_by(
        user_id=current_user.id, read=False
    ).order_by(desc(Notification.created_at)).all()
    
    # Get read notifications (limit to recent 20)
    read_notifications = Notification.query.filter_by(
        user_id=current_user.id, read=True
    ).order_by(desc(Notification.created_at)).limit(20).all()
    
    return render_template('user/notifications.html', 
        unread_notifications=unread_notifications,
        read_notifications=read_notifications
    )

@notifications_bp.route('/notifications/mark_read/<int:notification_id>', methods=['POST'])
@login_required
def mark_as_read(notification_id):
    """Mark a notification as read"""
    notification = Notification.query.get_or_404(notification_id)
    
    # Security check - make sure the notification belongs to the current user
    if notification.user_id != current_user.id:
        abort(403)  # Forbidden
    
    notification.read = True
    db.session.commit()
    
    # If this is an Ajax request, return JSON response
    if request.headers.get('X-Requested-With') == 'XMLHttpRequest':
        return jsonify({'status': 'success'})
    
    return redirect(url_for('notifications.list_notifications'))

@notifications_bp.route('/notifications/mark_all_read', methods=['POST'])
@login_required
def mark_all_as_read():
    """Mark all notifications as read"""
    # Update all notifications for the current user
    Notification.query.filter_by(
        user_id=current_user.id, read=False
    ).update({Notification.read: True})
    
    db.session.commit()
    
    # If this is an Ajax request, return JSON response
    if request.headers.get('X-Requested-With') == 'XMLHttpRequest':
        return jsonify({'status': 'success'})
    
    flash('All notifications marked as read', 'success')
    return redirect(url_for('notifications.list_notifications'))

@notifications_bp.route('/notifications/settings', methods=['GET', 'POST'])
@login_required
def notification_settings():
    """Update notification preferences"""
    form = NotificationSettingsForm()
    
    # Get user's current notification settings from a user preferences table
    # or use defaults if not set yet
    if form.validate_on_submit():
        # Save the notification settings (in a real app, store these in a user preferences table)
        flash('Notification preferences updated!', 'success')
        return redirect(url_for('user.profile'))
    
    return render_template('user/notification_settings.html', form=form)

@notifications_bp.route('/api/notifications/count')
@login_required
def unread_count():
    """Get count of unread notifications (for AJAX calls)"""
    count = Notification.query.filter_by(user_id=current_user.id, read=False).count()
    
    return jsonify({
        'count': count
    })