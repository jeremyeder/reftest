"""Tests for helper utilities."""
from src.utils.helper import format_name, validate_email


def test_format_name():
    assert format_name("John", "Doe") == "John Doe"


def test_validate_email():
    assert validate_email("test@example.com") is True
    assert validate_email("invalid") is False
