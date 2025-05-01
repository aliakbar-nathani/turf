from app import app, db
from models import Booking
from sqlalchemy import text

def add_payment_method_column():
    """
    Adds the payment_method column to the booking table.
    This migration script allows existing applications to add the column.
    """
    with app.app_context():
        # Check if column exists
        from sqlalchemy import inspect
        inspector = inspect(db.engine)
        columns = [col['name'] for col in inspector.get_columns('booking')]
        
        if 'payment_method' not in columns:
            print("Adding payment_method column to booking table...")
            # Add the column with the default value
            with db.engine.connect() as connection:
                connection.execute(text('ALTER TABLE booking ADD COLUMN payment_method VARCHAR(20) NOT NULL DEFAULT \'pay_online\''))
                connection.commit()
            print("Column added successfully.")
        else:
            print("payment_method column already exists in booking table. Skipping.")

if __name__ == "__main__":
    add_payment_method_column()