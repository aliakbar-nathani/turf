from app import app  # noqa: F401
from create_sample_data import create_sample_data

# Create sample data for MVP
create_sample_data()

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=5000, debug=True)
