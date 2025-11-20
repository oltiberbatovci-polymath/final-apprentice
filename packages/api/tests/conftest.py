"""
Configuration for pytest
"""
import pytest
import sys
import os

# Add src to path so we can import the app
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

# Set test database URL before importing app
os.environ['DATABASE_URL'] = 'sqlite:///:memory:'

from src.app import app as flask_app, db

@pytest.fixture
def app():
    """Create and configure a test app instance."""
    flask_app.config.update({
        'TESTING': True,
        'SQLALCHEMY_DATABASE_URI': 'sqlite:///:memory:',  # Use in-memory database for tests
        'SQLALCHEMY_TRACK_MODIFICATIONS': False,
    })
    
    # Create tables
    with flask_app.app_context():
        db.create_all()
        yield flask_app
        db.session.remove()
        db.drop_all()

@pytest.fixture
def client(app):
    """Create a test client for the app."""
    return app.test_client()

@pytest.fixture
def runner(app):
    """Create a test CLI runner for the app."""
    return app.test_cli_runner()
