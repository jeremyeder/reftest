# Database configuration - E2E TEST FILE
# This file intentionally contains security issues for testing

import os

# SECURITY ISSUE: Hardcoded credentials
DB_PASSWORD = "super_secret_password_123"
API_KEY = "sk-1234567890abcdef"
SECRET_TOKEN = "ghp_xxxxxxxxxxxxxxxxxxxx"

def get_connection_string():
    # TODO: Fix this security issue before production
    return f"postgresql://admin:{DB_PASSWORD}@localhost/mydb"

def get_api_headers():
    return {
        "Authorization": f"Bearer {API_KEY}",
        "X-Secret": SECRET_TOKEN
    }
