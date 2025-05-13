from app import app, db
from models import User, UserRole, Turf, TurfImage, TimeSlot, Booking, Review
from datetime import datetime, time
import random
from werkzeug.security import generate_password_hash

def create_sample_data():
    """Create sample users and turfs for testing"""
    with app.app_context():
        # Check if we already have sample data
        if User.query.filter_by(email='user@example.com').first():
            print("Sample data already exists. Skipping...")
            return
        
        print("Creating sample data...")
        
        # Create sample users
        # 1. Regular user
        user = User(
            username='john_player',
            email='user@example.com',
            phone_number='9876543210',
            role=UserRole.USER
        )
        user.set_password('password123')
        db.session.add(user)
        
        # 2. Turf owner
        owner = User(
            username='mike_owner',
            email='owner@example.com',
            phone_number='8765432109',
            role=UserRole.OWNER
        )
        owner.set_password('password123')
        db.session.add(owner)
        
        # 3. Admin
        admin = User(
            username='admin',
            email='admin@example.com',
            phone_number='7654321098',
            role=UserRole.ADMIN
        )
        admin.set_password('admin123')
        db.session.add(admin)
        
        # Commit users to database
        db.session.commit()
        
        # Create sample turfs for the owner
        turf_data = [
            {
                'name': 'Green Valley FC',
                'description': 'State-of-the-art football turf with high-quality artificial grass, perfect for 5-a-side games. Includes floodlights for evening matches and a small pavilion for players.',
                'address': '123 Sports Lane',
                'city': 'Mumbai',
                'state': 'Maharashtra',
                'country': 'India',
                'postal_code': '400001',
                'base_price_per_hour': 1200,
                'features': 'Floodlights,Parking,Changing Rooms,Refreshments',
                'size': '5-a-side',
                'indoor': False,
                'image_url': 'https://images.unsplash.com/photo-1510051710065-f8543352c455?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1170&q=80'
            },
            {
                'name': 'Indoor Arena',
                'description': 'Climate-controlled indoor football arena with professional-grade turf. Perfect for playing in any weather conditions. Equipped with digital scoreboards and professional lighting.',
                'address': '456 Indoor Complex',
                'city': 'Delhi',
                'state': 'Delhi',
                'country': 'India',
                'postal_code': '110001',
                'base_price_per_hour': 1500,
                'features': 'Floodlights,Parking,Changing Rooms,Showers,Equipment,Refreshments',
                'size': '7-a-side',
                'indoor': True,
                'image_url': 'https://images.unsplash.com/photo-1608245449230-4ac19066d2d0?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1074&q=80'
            },
            {
                'name': 'Sunset Beach Soccer',
                'description': 'Unique beach soccer field with natural sand surface. Located right next to the beach, offers a different football experience with stunning sunset views.',
                'address': '789 Beach Road',
                'city': 'Goa',
                'state': 'Goa',
                'country': 'India',
                'postal_code': '403001',
                'base_price_per_hour': 1000,
                'features': 'Floodlights,Refreshments,Equipment',
                'size': '5-a-side',
                'indoor': False,
                'image_url': 'https://images.unsplash.com/photo-1518604100146-5d424ab3faae?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1170&q=80'
            },
            {
                'name': 'Academy Fields',
                'description': 'Professional training center with multiple high-quality fields. Used by local professional clubs for training, now available for public bookings.',
                'address': '101 Academy Street',
                'city': 'Bangalore',
                'state': 'Karnataka',
                'country': 'India',
                'postal_code': '560001',
                'base_price_per_hour': 1800,
                'features': 'Floodlights,Parking,Changing Rooms,Showers,Equipment,Refreshments',
                'size': '11-a-side',
                'indoor': False,
                'image_url': 'https://images.unsplash.com/photo-1532087853-cc278694b5db?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1170&q=80'
            }
        ]
        
        for turf_info in turf_data:
            # Create turf
            turf = Turf(
                name=turf_info['name'],
                description=turf_info['description'],
                address=turf_info['address'],
                city=turf_info['city'],
                state=turf_info['state'],
                country=turf_info['country'],
                postal_code=turf_info['postal_code'],
                base_price_per_hour=turf_info['base_price_per_hour'],
                features=turf_info['features'],
                size=turf_info['size'],
                indoor=turf_info['indoor'],
                owner_id=owner.id,
                active=True,
                auto_approve_bookings=False
            )
            
            db.session.add(turf)
            db.session.flush()  # To get the turf.id
            
            # Add primary image
            image = TurfImage(
                url=turf_info['image_url'],
                is_primary=True,
                turf_id=turf.id
            )
            db.session.add(image)
            
            # Create time slots for each day of the week
            for day in range(7):  # 0=Monday, 6=Sunday
                # Morning slots (cheaper)
                morning_slot = TimeSlot(
                    day_of_week=day,
                    start_time=time(8, 0),
                    end_time=time(12, 0),
                    price_adjustment=-10.0,  # 10% cheaper
                    turf_id=turf.id
                )
                db.session.add(morning_slot)
                
                # Afternoon slots (standard price)
                afternoon_slot = TimeSlot(
                    day_of_week=day,
                    start_time=time(12, 0),
                    end_time=time(16, 0),
                    price_adjustment=0.0,  # standard price
                    turf_id=turf.id
                )
                db.session.add(afternoon_slot)
                
                # Evening slots (more expensive)
                evening_slot = TimeSlot(
                    day_of_week=day,
                    start_time=time(16, 0),
                    end_time=time(22, 0),
                    price_adjustment=15.0,  # 15% more expensive
                    turf_id=turf.id
                )
                db.session.add(evening_slot)
        
        # Commit all the changes
        db.session.commit()
        
        print("Sample data created successfully!")

if __name__ == "__main__":
    create_sample_data()