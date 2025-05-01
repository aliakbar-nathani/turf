from app import app, db
from models import User, Turf, TimeSlot, TurfImage, UserRole
from werkzeug.security import generate_password_hash
from datetime import datetime, time
import random

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
        
        # Commit to get user IDs
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
                'features': 'Air Conditioning,Digital Scoreboard,Pro Lighting,Premium Turf',
                'size': '7-a-side',
                'indoor': True,
                'image_url': 'https://images.unsplash.com/photo-1522778119026-d647f0596c20?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1170&q=80'
            },
            {
                'name': 'Sunset Grounds',
                'description': 'Beautiful outdoor turf located with a view of the sunset. Natural grass field maintained to professional standards. Includes running track around the perimeter.',
                'address': '789 Sunset Boulevard',
                'city': 'Bangalore',
                'state': 'Karnataka',
                'country': 'India',
                'postal_code': '560001',
                'base_price_per_hour': 1000,
                'features': 'Natural Grass,Running Track,Spectator Seating,Equipment Rental',
                'size': '11-a-side',
                'indoor': False,
                'image_url': 'https://images.unsplash.com/photo-1431324155629-1a6deb1dec8d?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1170&q=80'
            },
            {
                'name': 'Premier Futsal',
                'description': 'Specialized futsal court with smooth playing surface. Perfect for fast-paced futsal games with friends or league matches. Includes professional futsal goals and markings.',
                'address': '101 Futsal Street',
                'city': 'Chennai',
                'state': 'Tamil Nadu',
                'country': 'India',
                'postal_code': '600001',
                'base_price_per_hour': 800,
                'features': 'Futsal Goals,Ball Rental,Coaching Available,Tournaments',
                'size': 'Futsal',
                'indoor': True,
                'image_url': 'https://images.unsplash.com/photo-1542773049-6054c7ce5a06?ixlib=rb-4.0.3&ixid=MnwxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8&auto=format&fit=crop&w=1171&q=80'
            }
        ]
        
        # Time slot periods
        morning = [(8, 0), (9, 0), (10, 0), (11, 0)]
        afternoon = [(12, 0), (13, 0), (14, 0), (15, 0), (16, 0)]
        evening = [(17, 0), (18, 0), (19, 0), (20, 0)]
        
        # Create each turf with time slots
        for turf_info in turf_data:
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
                owner_id=owner.id
            )
            db.session.add(turf)
            db.session.flush()  # To get the turf ID
            
            # Add primary image
            image = TurfImage(
                url=turf_info['image_url'],
                is_primary=True,
                turf_id=turf.id
            )
            db.session.add(image)
            
            # Add time slots for each day of the week
            for day in range(7):  # 0=Monday, 6=Sunday
                # Add morning slots (standard pricing)
                for hour, minute in morning:
                    start = time(hour, minute)
                    end = time(hour + 1, minute)
                    slot = TimeSlot(
                        day_of_week=day,
                        start_time=start,
                        end_time=end,
                        price_adjustment=0,  # Standard price
                        turf_id=turf.id
                    )
                    db.session.add(slot)
                
                # Add afternoon slots (10% discount)
                for hour, minute in afternoon:
                    start = time(hour, minute)
                    end = time(hour + 1, minute)
                    slot = TimeSlot(
                        day_of_week=day,
                        start_time=start,
                        end_time=end,
                        price_adjustment=-10,  # 10% discount
                        turf_id=turf.id
                    )
                    db.session.add(slot)
                
                # Add evening slots (20% premium)
                for hour, minute in evening:
                    start = time(hour, minute)
                    end = time(hour + 1, minute)
                    slot = TimeSlot(
                        day_of_week=day,
                        start_time=start,
                        end_time=end,
                        price_adjustment=20,  # 20% premium
                        turf_id=turf.id
                    )
                    db.session.add(slot)
        
        # Commit all changes
        db.session.commit()
        print("Sample data created successfully!")

if __name__ == '__main__':
    create_sample_data()