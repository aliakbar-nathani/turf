from flask import Blueprint, render_template, request, jsonify, flash, redirect, url_for
from flask_login import login_required, current_user
from sqlalchemy import desc

from app import db
from models import Notification, NotificationSetting
from forms import NotificationSettingsForm

notifications = Blueprint('notifications', __name__, url_prefix='/notifications')

@notifications.route('/')
@login_required
def list_notifications():
    """Display user's notifications"""
    # Get unread notifications
    unread_notifications = Notification.query.filter_by(
        user_id=current_user.id, 
        read=False
    ).order_by(desc(Notification.created_at)).all()
    
    # Get read notifications (limit to 20 most recent)
    read_notifications = Notification.query.filter_by(
        user_id=current_user.id, 
        read=True
    ).order_by(desc(Notification.created_at)).limit(20).all()
    
    return render_template(
        'user/notifications.html',
        unread_notifications=unread_notifications,
        read_notifications=read_notifications
    )

@notifications.route('/<int:notification_id>/read', methods=['POST'])
@login_required
def mark_as_read(notification_id):
    """Mark a notification as read"""
    notification = Notification.query.filter_by(
        id=notification_id, 
        user_id=current_user.id
    ).first_or_404()
    
    notification.read = True
    db.session.commit()
    
    # Check if it's an AJAX request
    if request.headers.get('X-Requested-With') == 'XMLHttpRequest':
        return jsonify({
            'status': 'success',
            'message': 'Notification marked as read'
        })
    
    # If not AJAX, redirect back to notifications
    flash('Notification marked as read', 'success')
    return redirect(url_for('notifications.list_notifications'))

@notifications.route('/mark-all-read', methods=['POST'])
@login_required
def mark_all_as_read():
    """Mark all notifications as read"""
    Notification.query.filter_by(
        user_id=current_user.id, 
        read=False
    ).update({Notification.read: True})
    
    db.session.commit()
    
    flash('All notifications marked as read', 'success')
    return redirect(url_for('notifications.list_notifications'))

@notifications.route('/notifications/settings', methods=['GET', 'POST'])
@login_required
def notification_settings():
    """Manage notification settings"""
    # Get or create notification settings for the user
    settings = NotificationSetting.query.filter_by(user_id=current_user.id).first()
    if not settings:
        settings = NotificationSetting(user_id=current_user.id)
        db.session.add(settings)
        db.session.commit()
    
    form = NotificationSettingsForm(obj=settings)
    
    if form.validate_on_submit():
        form.populate_obj(settings)
        db.session.commit()
        flash('Notification settings updated successfully', 'success')
        return redirect(url_for('notifications.notification_settings'))
    
    return render_template('user/notification_settings.html', form=form)

@notifications.route('/api/notifications/count')
@login_required
def get_notification_count():
    """Return the count of unread notifications for API usage"""
    count = Notification.query.filter_by(
        user_id=current_user.id, 
        read=False
    ).count()
    
    return jsonify({'count': count})