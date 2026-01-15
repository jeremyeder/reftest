"""Helper utilities - E2E test file."""


def format_name(first: str, last: str) -> str:
    """Format a full name from first and last name."""
    return f"{first} {last}".strip()


def validate_email(email: str) -> bool:
    """Basic email validation."""
    return "@" in email and "." in email
