import os
from sqlalchemy import create_engine, MetaData, Table, Column, Boolean
from sqlalchemy.sql import text

def add_auto_approve_column():
    """
    Adds the auto_approve_bookings column to the turf table.
    This migration script allows existing applications to add the column.
    """
    # Get the database URL from environment
    db_url = os.environ.get('DATABASE_URL')
    
    if not db_url:
        print("ERROR: DATABASE_URL environment variable not set.")
        return False
    
    try:
        engine = create_engine(db_url)
        conn = engine.connect()

        # Check if the column already exists
        result = conn.execute(text("SELECT column_name FROM information_schema.columns WHERE table_name = 'turf' AND column_name = 'auto_approve_bookings'"))
        if result.rowcount > 0:
            print("Column auto_approve_bookings already exists. Skipping migration.")
            conn.close()
            return True
            
        # Add the column
        conn.execute(text("ALTER TABLE turf ADD COLUMN auto_approve_bookings BOOLEAN DEFAULT FALSE"))
        
        print("Successfully added auto_approve_bookings column to turf table.")
        conn.close()
        return True
    except Exception as e:
        print(f"ERROR: Failed to add auto_approve_bookings column: {str(e)}")
        return False

if __name__ == "__main__":
    add_auto_approve_column()