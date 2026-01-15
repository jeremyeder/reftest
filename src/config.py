"""Configuration with intentional security issues for testing."""

# SECURITY ISSUE: Hardcoded API key
API_KEY = "sk-1234567890abcdef"

# SECURITY ISSUE: Hardcoded password
DATABASE_PASSWORD = "super_secret_password_123"

# SECURITY ISSUE: Hardcoded secret
JWT_SECRET = "my-jwt-secret-key-12345"


def get_api_key():
    """Return the hardcoded API key."""
    return API_KEY
