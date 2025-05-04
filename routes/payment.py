from flask import Blueprint, render_template, redirect, url_for, flash, request, abort
from flask_login import login_required, current_user
import stripe
import os
import json

from app import db
from models import Booking, BookingStatus, Turf, Notification, NotificationType

payment = Blueprint('payment', __name__)

# Setup Stripe
stripe.api_key = os.environ.get('STRIPE_SECRET_KEY')
YOUR_DOMAIN = os.environ.get('REPLIT_DEV_DOMAIN', '') if os.environ.get('REPLIT_DEPLOYMENT', '') != '' else os.environ.get('REPLIT_DOMAINS', '').split(',')[0]

@payment.route('/checkout/<int:booking_id>', methods=['GET'])
@login_required
def checkout(booking_id):
    booking = Booking.query.get_or_404(booking_id)
    
    # Check if booking belongs to current user
    if booking.user_id != current_user.id:
        abort(403)
    
    # Check if booking is in confirmed or payment_pending status
    if booking.status != BookingStatus.CONFIRMED and booking.status != BookingStatus.PAYMENT_PENDING:
        flash('This booking cannot be processed for payment.', 'danger')
        return redirect(url_for('user.bookings'))
    
    # Check if booking is already paid
    if booking.payment_status == 'paid':
        flash('This booking has already been paid for.', 'info')
        return redirect(url_for('user.bookings'))
    
    # Get turf details
    turf = Turf.query.get(booking.turf_id)
    
    return render_template(
        'payment/checkout.html',
        booking=booking,
        turf=turf,
        title='Complete Payment'
    )

@payment.route('/create-checkout-session/<int:booking_id>', methods=['POST'])
@login_required
def create_checkout_session(booking_id):
    booking = Booking.query.get_or_404(booking_id)
    
    # Check if booking belongs to current user
    if booking.user_id != current_user.id:
        abort(403)
    
    # Get turf details
    turf = Turf.query.get(booking.turf_id)
    
    try:
        checkout_session = stripe.checkout.Session.create(
            payment_method_types=['card'],
            line_items=[
                {
                    'price_data': {
                        'currency': 'inr',
                        'product_data': {
                            'name': f'Booking for {turf.name}',
                            'description': f'Date: {booking.booking_date}, Time: {booking.start_time.strftime("%H:%M")} - {booking.end_time.strftime("%H:%M")}',
                        },
                        'unit_amount': int(booking.total_price * 100),  # amount in cents
                    },
                    'quantity': 1,
                },
            ],
            mode='payment',
            success_url='https://' + YOUR_DOMAIN + f'/payment/success/{booking_id}',
            cancel_url='https://' + YOUR_DOMAIN + f'/payment/cancel/{booking_id}',
            client_reference_id=str(booking.id),
            metadata={
                'booking_id': booking.id,
                'user_id': current_user.id
            }
        )
        
        # Update booking with payment information
        booking.payment_id = checkout_session.id
        db.session.commit()
        
        return redirect(checkout_session.url, code=303)
    except Exception as e:
        flash(f'An error occurred: {str(e)}', 'danger')
        return redirect(url_for('payment.checkout', booking_id=booking.id))

@payment.route('/success/<int:booking_id>')
@login_required
def payment_success(booking_id):
    booking = Booking.query.get_or_404(booking_id)
    
    # Check if booking belongs to current user
    if booking.user_id != current_user.id:
        abort(403)
    
    # Verify payment with Stripe (in a real app, this would be handled by a webhook)
    if booking.payment_id:
        try:
            session = stripe.checkout.Session.retrieve(booking.payment_id)
            if session.payment_status == 'paid':
                booking.payment_status = 'paid'
                # If booking was in payment_pending status, update it to confirmed
                if booking.status == BookingStatus.PAYMENT_PENDING:
                    booking.status = BookingStatus.CONFIRMED
                db.session.commit()
                
                # Create a notification for the user
                notification = Notification(
                    user_id=booking.user_id,
                    type=NotificationType.PAYMENT_SUCCESS,
                    title='Payment Successful',
                    message=f'Your payment for booking #{booking.id} has been successfully processed.',
                    booking_id=booking.id,
                    turf_id=booking.turf_id
                )
                db.session.add(notification)
                db.session.commit()
            else:
                # This is unlikely to happen in this flow, but added for completeness
                flash('Payment has not been completed yet.', 'warning')
                return redirect(url_for('payment.checkout', booking_id=booking.id))
        except Exception as e:
            flash(f'An error occurred while verifying payment: {str(e)}', 'danger')
    
    turf = Turf.query.get(booking.turf_id)
    
    return render_template(
        'payment/success.html',
        booking=booking,
        turf=turf,
        title='Payment Successful'
    )

@payment.route('/cancel/<int:booking_id>')
@login_required
def payment_cancel(booking_id):
    booking = Booking.query.get_or_404(booking_id)
    
    # Check if booking belongs to current user
    if booking.user_id != current_user.id:
        abort(403)
    
    turf = Turf.query.get(booking.turf_id)
    
    return render_template(
        'payment/cancel.html',
        booking=booking,
        turf=turf,
        title='Payment Cancelled'
    )

@payment.route('/mobile-checkout/<int:booking_id>', methods=['GET', 'POST'])
def mobile_checkout(booking_id):
    """
    Endpoint for mobile app to create a checkout session
    Returns a JSON response with the Stripe checkout URL
    """
    if request.method == 'GET':
        # Just return info that this is a POST endpoint
        return json.dumps({
            'success': False,
            'message': 'This endpoint requires a POST request'
        }), 400, {'Content-Type': 'application/json'}
        
    booking = Booking.query.get_or_404(booking_id)
    
    # Validate the booking belongs to the correct user
    auth_header = request.headers.get('Authorization')
    if not auth_header or not auth_header.startswith('Bearer '):
        return json.dumps({
            'success': False,
            'message': 'Authorization required'
        }), 401, {'Content-Type': 'application/json'}

    token = auth_header.split(' ')[1]
    try:
        import jwt
        from datetime import datetime, timezone
        
        secret_key = os.environ.get('JWT_SECRET_KEY', 'fallback_secret_for_dev')
        payload = jwt.decode(token, secret_key, algorithms=['HS256'])
        
        # Check token expiration
        if datetime.now(timezone.utc).timestamp() > payload.get('exp', 0):
            return json.dumps({
                'success': False,
                'message': 'Token expired'
            }), 401, {'Content-Type': 'application/json'}
            
        user_id = payload.get('user_id')
        
        if booking.user_id != user_id:
            return json.dumps({
                'success': False,
                'message': 'Unauthorized access to this booking'
            }), 403, {'Content-Type': 'application/json'}
    
    except Exception as e:
        return json.dumps({
            'success': False,
            'message': f'Authorization failed: {str(e)}'
        }), 401, {'Content-Type': 'application/json'}
    
    # Check if booking is in valid status for payment
    if booking.status != BookingStatus.CONFIRMED and booking.status != BookingStatus.PAYMENT_PENDING:
        return json.dumps({
            'success': False,
            'message': 'This booking cannot be processed for payment'
        }), 400, {'Content-Type': 'application/json'}
    
    # Check if booking is already paid
    if booking.payment_status == 'paid':
        return json.dumps({
            'success': False,
            'message': 'This booking has already been paid for'
        }), 400, {'Content-Type': 'application/json'}
    
    # Get turf details
    turf = Turf.query.get(booking.turf_id)
    
    try:
        checkout_session = stripe.checkout.Session.create(
            payment_method_types=['card'],
            line_items=[
                {
                    'price_data': {
                        'currency': 'usd',  # Changed to USD for international compatibility
                        'product_data': {
                            'name': f'Booking for {turf.name}',
                            'description': f'Date: {booking.booking_date}, Time: {booking.start_time.strftime("%H:%M")} - {booking.end_time.strftime("%H:%M")}',
                            'images': [turf.image_url] if turf.image_url else [],
                        },
                        'unit_amount': int(booking.total_price * 100),  # amount in cents
                    },
                    'quantity': 1,
                },
            ],
            mode='payment',
            success_url='https://' + YOUR_DOMAIN + f'/payment/mobile-success/{booking_id}',
            cancel_url='https://' + YOUR_DOMAIN + f'/payment/mobile-cancel/{booking_id}',
            client_reference_id=str(booking.id),
            metadata={
                'booking_id': booking.id,
                'user_id': user_id,
                'platform': 'mobile'
            }
        )
        
        # Update booking with payment information
        booking.payment_id = checkout_session.id
        db.session.commit()
        
        return json.dumps({
            'success': True,
            'checkout_url': checkout_session.url,
            'session_id': checkout_session.id
        }), 200, {'Content-Type': 'application/json'}
        
    except Exception as e:
        return json.dumps({
            'success': False,
            'message': f'An error occurred: {str(e)}'
        }), 500, {'Content-Type': 'application/json'}

@payment.route('/mobile-success/<int:booking_id>')
def mobile_payment_success(booking_id):
    """Simple success page that mobile app WebView can display"""
    return render_template(
        'payment/mobile_success.html',
        booking_id=booking_id,
        title='Payment Successful'
    )

@payment.route('/mobile-cancel/<int:booking_id>')
def mobile_payment_cancel(booking_id):
    """Simple cancel page that mobile app WebView can display"""
    return render_template(
        'payment/mobile_cancel.html',
        booking_id=booking_id,
        title='Payment Cancelled'
    )

@payment.route('/webhook', methods=['POST'])
def webhook():
    payload = request.get_data(as_text=True)
    sig_header = request.headers.get('Stripe-Signature')
    
    # In production you would have a real webhook secret
    webhook_secret = os.environ.get('STRIPE_WEBHOOK_SECRET')

    try:
        if webhook_secret:
            event = stripe.Webhook.construct_event(
                payload, sig_header, webhook_secret
            )
        else:
            # For testing without a webhook secret
            data = json.loads(payload)
            event = {"type": data.get("type"), "data": {"object": data}}
    except ValueError as e:
        # Invalid payload
        return 'Invalid payload', 400
    except Exception as e:
        # Handle other errors, including Stripe signature verification errors
        return f'Error processing webhook: {str(e)}', 400

    # Handle specific events
    if event['type'] == 'checkout.session.completed':
        try:
            session = event['data']['object']
            booking_id = session.get('metadata', {}).get('booking_id')
            
            if booking_id:
                booking = Booking.query.get(int(booking_id))
                if booking:
                    booking.payment_status = 'paid'
                    
                    # If booking was in payment_pending status, update it to confirmed
                    if booking.status == BookingStatus.PAYMENT_PENDING:
                        booking.status = BookingStatus.CONFIRMED
                    
                    db.session.commit()
                    
                    # Create notification for user about successful payment
                    notification = Notification(
                        user_id=booking.user_id,
                        type=NotificationType.PAYMENT_SUCCESS,
                        title='Payment Successful',
                        message=f'Your payment for booking #{booking.id} has been successfully processed.',
                        booking_id=booking.id,
                        turf_id=booking.turf_id
                    )
                    db.session.add(notification)
                    db.session.commit()
                    
                    # Log the payment platform (web or mobile)
                    platform = session.get('metadata', {}).get('platform', 'web')
                    print(f"Payment completed on {platform} platform for booking #{booking_id}")
        except Exception as e:
            print(f"Error processing webhook: {str(e)}")
            # Continue processing rather than failing the whole webhook
    
    return 'Success', 200
