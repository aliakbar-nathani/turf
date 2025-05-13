import os
from flask import Blueprint, redirect, request, url_for, flash, render_template, jsonify, current_app
import stripe
from models import db, Booking, BookingStatus
from flask_login import login_required, current_user
import logging

# Set up Stripe API key
stripe.api_key = os.environ.get('STRIPE_SECRET_KEY')

# Create Blueprint
payment = Blueprint('payment', __name__)

# Helper function to get the base domain
def get_domain():
    if os.environ.get('REPLIT_DEPLOYMENT'):
        return os.environ.get('REPLIT_DEV_DOMAIN')
    else:
        domains = os.environ.get('REPLIT_DOMAINS', '').split(',')
        return domains[0] if domains else request.host

@payment.route('/create-checkout-session/<int:booking_id>', methods=['POST'])
@login_required
def create_checkout_session(booking_id):
    """
    Create a Stripe checkout session for a booking
    """
    try:
        # Get the booking
        booking = Booking.query.get_or_404(booking_id)
        
        # Ensure the booking belongs to the current user or the turf owner
        if booking.user_id != current_user.id and booking.turf.owner_id != current_user.id:
            flash('You do not have permission to process this payment', 'danger')
            return redirect(url_for('user.dashboard'))
        
        # Ensure booking is in payment_pending status
        if booking.status != BookingStatus.PAYMENT_PENDING:
            flash('This booking is not ready for payment', 'warning')
            return redirect(url_for('user.dashboard'))
        
        # Create the checkout session
        checkout_session = stripe.checkout.Session.create(
            payment_method_types=['card'],
            line_items=[
                {
                    'price_data': {
                        'currency': 'inr',
                        'product_data': {
                            'name': f'Booking for {booking.turf.name}',
                            'description': f'Date: {booking.booking_date}, Time: {booking.start_time} - {booking.end_time}',
                        },
                        'unit_amount': int(booking.total_price * 100),  # Amount in paise
                    },
                    'quantity': 1,
                },
            ],
            mode='payment',
            success_url=url_for('payment.success', booking_id=booking.id, _external=True),
            cancel_url=url_for('payment.cancel', booking_id=booking.id, _external=True),
            client_reference_id=str(booking.id),
        )
        
        # Update the booking with the payment ID
        booking.payment_id = checkout_session.id
        db.session.commit()
        
        # Redirect to Stripe Checkout
        return redirect(checkout_session.url, code=303)
    
    except Exception as e:
        logging.error(f"Stripe checkout error: {str(e)}")
        flash('Payment processing error. Please try again.', 'danger')
        return redirect(url_for('user.dashboard'))

@payment.route('/webhook', methods=['POST'])
def webhook():
    """
    Handle Stripe webhook events
    """
    payload = request.get_data(as_text=True)
    sig_header = request.headers.get('Stripe-Signature')

    try:
        # Verify webhook signature and extract the event
        event = stripe.Webhook.construct_event(
            payload, sig_header, os.environ.get('STRIPE_WEBHOOK_SECRET', '')
        )
    except ValueError as e:
        # Invalid payload
        logging.error(f"Invalid Stripe payload: {str(e)}")
        return jsonify(success=False), 400
    except stripe.error.SignatureVerificationError as e:
        # Invalid signature
        logging.error(f"Invalid Stripe signature: {str(e)}")
        return jsonify(success=False), 400

    # Handle the event
    if event['type'] == 'checkout.session.completed':
        session = event['data']['object']
        
        # Get booking ID from client_reference_id
        booking_id = int(session.get('client_reference_id', 0))
        if booking_id:
            # Update booking status
            booking = Booking.query.get(booking_id)
            if booking:
                booking.status = BookingStatus.CONFIRMED
                booking.payment_status = 'paid'
                db.session.commit()
                
                # TODO: Send confirmation email/notification
                logging.info(f"Payment completed for booking {booking_id}")
    
    # Return a success response to Stripe
    return jsonify(success=True)

@payment.route('/success/<int:booking_id>')
@login_required
def success(booking_id):
    """
    Handle successful payment
    """
    booking = Booking.query.get_or_404(booking_id)
    
    # Check if the booking status is already updated by the webhook
    if booking.status != BookingStatus.CONFIRMED:
        # If not, update it (in case webhook hasn't processed yet)
        booking.status = BookingStatus.CONFIRMED
        booking.payment_status = 'paid'
        db.session.commit()
    
    flash('Payment successful! Your booking has been confirmed.', 'success')
    return render_template('payment/success.html', booking=booking)

@payment.route('/cancel/<int:booking_id>')
@login_required
def cancel(booking_id):
    """
    Handle cancelled payment
    """
    booking = Booking.query.get_or_404(booking_id)
    
    flash('Payment was cancelled. Your booking is still pending.', 'warning')
    return render_template('payment/cancel.html', booking=booking)

# Mobile API endpoint for creating checkout session
@payment.route('/api/create-checkout-session/<int:booking_id>', methods=['POST'])
@login_required
def api_create_checkout_session(booking_id):
    """
    Create a Stripe checkout session for mobile app
    """
    try:
        # Get the booking
        booking = Booking.query.get_or_404(booking_id)
        
        # Ensure the booking belongs to the current user
        if booking.user_id != current_user.id:
            return jsonify({
                'success': False,
                'message': 'You do not have permission to process this payment'
            }), 403
        
        # Ensure booking is in payment_pending status
        if booking.status != BookingStatus.PAYMENT_PENDING:
            return jsonify({
                'success': False,
                'message': 'This booking is not ready for payment'
            }), 400
        
        # Create the checkout session
        checkout_session = stripe.checkout.Session.create(
            payment_method_types=['card'],
            line_items=[
                {
                    'price_data': {
                        'currency': 'inr',
                        'product_data': {
                            'name': f'Booking for {booking.turf.name}',
                            'description': f'Date: {booking.booking_date}, Time: {booking.start_time} - {booking.end_time}',
                        },
                        'unit_amount': int(booking.total_price * 100),  # Amount in paise
                    },
                    'quantity': 1,
                },
            ],
            mode='payment',
            success_url=url_for('payment.success', booking_id=booking.id, _external=True),
            cancel_url=url_for('payment.cancel', booking_id=booking.id, _external=True),
            client_reference_id=str(booking.id),
        )
        
        # Update the booking with the payment ID
        booking.payment_id = checkout_session.id
        db.session.commit()
        
        # Return checkout URL for mobile app
        return jsonify({
            'success': True,
            'checkout_url': checkout_session.url
        })
    
    except Exception as e:
        logging.error(f"Stripe checkout error: {str(e)}")
        return jsonify({
            'success': False,
            'message': 'Payment processing error. Please try again.'
        }), 500