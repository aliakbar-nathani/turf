from app import app, db
from models import User, Booking, Turf, UserRole, BookingStatus, Review
from datetime import datetime, timedelta, time
import random

def create_analytics_data():
    """Create detailed analytics data for owner dashboard"""
    with app.app_context():
        # Check if we already have enough analytics data (at least 50 bookings)
        booking_count = Booking.query.count()
        if booking_count >= 50:
            print(f"Analytics data already exists ({booking_count} bookings). Skipping...")
            return
        
        print("Creating analytics data...")
        
        # Get existing users and turfs
        users = User.query.filter_by(role=UserRole.USER).all()
        owners = User.query.filter_by(role=UserRole.OWNER).all()
        turfs = Turf.query.all()
        
        if not users or not owners or not turfs:
            print("Error: Need users, owners and turfs before creating analytics data")
            return
        
        # Booking statuses with weighted distribution
        statuses = [
            (BookingStatus.CONFIRMED, 40),
            (BookingStatus.COMPLETED, 35),
            (BookingStatus.CANCELLED, 10),
            (BookingStatus.PENDING, 5),
            (BookingStatus.PAYMENT_PENDING, 5),
            (BookingStatus.NEGOTIATING, 5)
        ]
        
        # Payment methods with weights
        payment_methods = [
            ('pay_online', 75),
            ('pay_on_arrival', 25)
        ]
        
        # Payment statuses based on booking status
        def get_payment_status(status):
            if status in [BookingStatus.CONFIRMED, BookingStatus.COMPLETED]:
                return 'paid'
            elif status == BookingStatus.PAYMENT_PENDING:
                return 'pending'
            else:
                return 'unpaid'
        
        # Create bookings spread over the last 6 months
        today = datetime.now().date()
        start_date = today - timedelta(days=180)  # 6 months ago
        
        # Create 100 bookings with various statuses
        for i in range(100):
            # Select random user and turf
            user = random.choice(users)
            turf = random.choice(turfs)
            
            # Generate random date within last 6 months
            days_ago = random.randint(0, 180)
            booking_date = today - timedelta(days=days_ago)
            
            # Generate random time slot
            start_hour = random.randint(8, 20)  # Between a0m and 8pm
            duration = random.choice([1, 2, 3])  # 1, 2 or 3 hours
            start_time = time(start_hour, 0)
            end_time = time(start_hour + duration, 0)
            
            # Calculate price (base_price * duration + random adjustment)
            base_price = turf.base_price_per_hour
            price_adjustment = random.uniform(-0.1, 0.2)  # -10% to +20%
            total_price = base_price * duration * (1 + price_adjustment)
            total_price = round(total_price, 2)
            original_price = total_price
            
            # Randomly select if there was a negotiation
            had_negotiation = random.random() < 0.3  # 30% chance
            if had_negotiation:
                discount = random.uniform(0.05, 0.15)  # 5% to 15% discount
                user_proposed_price = total_price * (1 - discount)
                user_proposed_price = round(user_proposed_price, 2)
            else:
                user_proposed_price = None
            
            # Select status with weighted distribution
            status = random.choices(
                [s[0] for s in statuses],
                weights=[s[1] for s in statuses],
                k=1
            )[0]
            
            # Select payment method with weighted distribution
            payment_method = random.choices(
                [pm[0] for pm in payment_methods],
                weights=[pm[1] for pm in payment_methods],
                k=1
            )[0]
            
            # Get payment status based on booking status
            payment_status = get_payment_status(status)
            
            # Generate random payment ID for completed payments
            payment_id = f"py_{random.randint(100000, 999999)}" if payment_status == 'paid' else None
            
            # Create booking with random notes
            notes_options = [
                "Please have water bottles available",
                "We'll bring our own equipment",
                "Need extra time for setup before the game",
                "Birthday celebration game",
                "Corporate team building event",
                "School tournament",
                "We might be 10 minutes late",
                "Requesting corner area for coaching",
                None, None, None  # Higher chance of no notes
            ]
            
            # Create booking
            booking = Booking(
                user_id=user.id,
                turf_id=turf.id,
                booking_date=booking_date,
                start_time=start_time,
                end_time=end_time,
                total_price=total_price,
                original_price=original_price,
                user_proposed_price=user_proposed_price,
                status=status,
                payment_status=payment_status,
                payment_method=payment_method,
                payment_id=payment_id,
                notes=random.choice(notes_options),
                created_at=datetime.combine(booking_date - timedelta(days=random.randint(1, 14)), 
                                          time(random.randint(8, 20), random.randint(0, 59)))
            )
            
            # Set updated_at based on status
            if status in [BookingStatus.CONFIRMED, BookingStatus.COMPLETED, BookingStatus.CANCELLED]:
                days_after_creation = random.randint(1, 3)
                booking.updated_at = booking.created_at + timedelta(days=days_after_creation)
            else:
                booking.updated_at = booking.created_at
                
            db.session.add(booking)
            
            # Add reviews for completed bookings (70% chance)
            if status == BookingStatus.COMPLETED and random.random() < 0.7:
                # Create review 1-7 days after booking
                review_date = datetime.combine(
                    booking_date + timedelta(days=random.randint(1, 7)),
                    time(random.randint(8, 20), random.randint(0, 59))
                )
                
                # Generate random rating weighted towards positive
                rating_weights = [1, 3, 6, 45, 45]  # Weights for 1-5 stars
                rating = random.choices(range(1, 6), weights=rating_weights, k=1)[0]
                
                # Generate appropriate comment based on rating
                if rating >= 4:
                    comments = [
                        f"Great experience at {turf.name}! The facilities were clean and well-maintained.",
                        f"Excellent turf quality. Will definitely book again.",
                        f"Friendly staff and perfect playing conditions.",
                        f"Best turf in the area. The floodlights were perfect for our evening game.",
                        f"Smooth booking process and great value for money.",
                        f"Perfect for our team practice. Refreshments were available as promised."
                    ]
                elif rating == 3:
                    comments = [
                        f"Decent facilities but could be cleaner.",
                        f"Good location but the turf needs some maintenance.",
                        f"Average experience. Nothing special but got the job done.",
                        f"Staff was helpful but had to wait for the previous group to leave.",
                        f"OK for casual games but not for serious training."
                    ]
                else:
                    comments = [
                        f"Disappointed with the condition of the turf.",
                        f"Poor maintenance and facilities.",
                        f"Not worth the price. Won't be returning.",
                        f"Booking was confirmed but the turf wasn't prepared on arrival.",
                        f"Had issues with the staff and facilities weren't as advertised."
                    ]
                
                review = Review(
                    user_id=user.id,
                    turf_id=turf.id,
                    booking_id=booking.id,
                    rating=rating,
                    comment=random.choice(comments),
                    created_at=review_date,
                    updated_at=review_date
                )
                
                # Add owner response for some reviews (40% chance)
                if random.random() < 0.4:
                    # Owner responds 1-3 days after review
                    response_date = review_date + timedelta(days=random.randint(1, 3))
                    
                    if rating >= 4:
                        responses = [
                            f"Thank you for your positive feedback! We're glad you enjoyed your time at {turf.name}.",
                            f"Thanks for the great review! Hope to see you again soon.",
                            f"We appreciate your kind words and look forward to hosting you again."
                        ]
                    elif rating == 3:
                        responses = [
                            f"Thank you for your feedback. We'll work on improving the issues you mentioned.",
                            f"We appreciate your honest review and will address these concerns.",
                            f"Thanks for letting us know about your experience. We're working on improvements."
                        ]
                    else:
                        responses = [
                            f"We're sorry to hear about your experience. Please contact us directly to discuss further.",
                            f"We apologize for not meeting your expectations. We're addressing these issues promptly.",
                            f"Thank you for bringing this to our attention. We've already started making improvements."
                        ]
                    
                    review.owner_response = random.choice(responses)
                    review.owner_response_date = response_date
                
                db.session.add(review)
        
        db.session.commit()
        print(f"Created 100 bookings and related analytics data successfully!")

if __name__ == "__main__":
    create_analytics_data()