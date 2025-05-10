from app import app, db
from sqlalchemy import Column, Text, text

# Run this script to add the 'notes' column to the booking table
def add_notes_column():
    """
    Adds the notes column to the booking table.
    This migration script allows existing applications to add the column.
    """
    with app.app_context():
        # Check if we need to migrate
        engine = db.engine
        inspector = db.inspect(engine)
        columns = [col['name'] for col in inspector.get_columns('booking')]
        
        if 'notes' not in columns:
            print("Adding 'notes' column to booking table...")
            try:
                # Add the column using SQLAlchemy core
                with engine.connect() as conn:
                    conn.execute(text('ALTER TABLE booking ADD COLUMN notes TEXT;'))
                    conn.commit()
                print("Successfully added 'notes' column.")
            except Exception as e:
                print(f"Error adding column: {e}")
        else:
            print("Column 'notes' already exists in booking table.")

if __name__ == "__main__":
    add_notes_column()