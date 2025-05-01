from flask import Blueprint, render_template, redirect, url_for, flash, request, abort
from flask_login import login_required, current_user
import stripe
import os

from app import db
from models import Booking, BookingStatus, Turf

payment = Blueprint('payment', __name__)

# Setup Stripe
stripe.api_key = os.environ.get('STRIPE_SECRET_KEY', 'sk_test_placeholder')
YOUR_DOMAIN = os.environ.get('REPLIT_DEV_DOMAIN') if os.environ.get('REPLIT_DEPLOYMENT') != '' else os.environ.get('REPLIT_DOMAINS', '').split(',')[0]

@payment.route('/checkout/<int:booking_id>', methods=['GET'])
@login_required
def checkout(booking_id):
    booking = Booking.query.get_or_404(booking_id)
    
    # Check if booking belongs to current user
    if booking.user_id != current_user.id:
        abort(403)
    
    # Check if booking is in confirmed status
    if booking.status != BookingStatus.CONFIRMED:
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

@payment.route('/webhook', methods=['POST'])
def webhook():
    payload = request.get_data(as_text=True)
    sig_header = request.headers.get('Stripe-Signature')

    try:
        event = stripe.Webhook.construct_event(
            payload, sig_header, os.environ.get('STRIPE_WEBHOOK_SECRET', 'whsec_placeholder')
        )
    except ValueError as e:
        # Invalid payload
        return 'Invalid payload', 400
    except stripe.error.SignatureVerificationError as e:
        # Invalid signature
        return 'Invalid signature', 400

    # Handle specific events
    if event['type'] == 'checkout.session.completed':
        session = event['data']['object']
        booking_id = session.get('metadata', {}).get('booking_id')
        
        if booking_id:
            booking = Booking.query.get(int(booking_id))
            if booking:
                booking.payment_status = 'paid'
                db.session.commit()
    
    return 'Success', 200
