"""
Ransomware Guardian — Helper Utilities
Shared utility functions for timestamps, IDs, file operations.
"""

import hashlib
import os
import uuid
from datetime import datetime


def format_timestamp(dt=None):
    """Return an ISO 8601 formatted timestamp string."""
    if dt is None:
        dt = datetime.now()
    return dt.isoformat(timespec="seconds")


def generate_alert_id():
    """Generate a unique alert ID in the format ALT-XXXX."""
    short_id = uuid.uuid4().hex[:6].upper()
    return f"ALT-{short_id}"


def generate_event_id():
    """Generate a unique monitoring event ID in the format MON-XXXX."""
    short_id = uuid.uuid4().hex[:6].upper()
    return f"MON-{short_id}"


def get_file_extension(file_path):
    """Extract the file extension (lowercase, with dot)."""
    _, ext = os.path.splitext(file_path)
    return ext.lower()


def calculate_file_hash(file_path, algorithm="sha256"):
    """
    Calculate the hash of a file.
    Returns None if the file cannot be read.
    """
    try:
        hasher = hashlib.new(algorithm)
        with open(file_path, "rb") as f:
            for chunk in iter(lambda: f.read(8192), b""):
                hasher.update(chunk)
        return hasher.hexdigest()
    except (OSError, IOError):
        return None


def get_filename(file_path):
    """Extract just the filename from a full path."""
    return os.path.basename(file_path)


def is_ignored(file_path, ignored_patterns):
    """Check if a file path matches any ignored pattern."""
    for pattern in ignored_patterns:
        if pattern in file_path:
            return True
    return False


def truncate_path(file_path, max_length=60):
    """Truncate a long file path for display, keeping the end visible."""
    if len(file_path) <= max_length:
        return file_path
    return "..." + file_path[-(max_length - 3):]


def bytes_to_human(size_bytes):
    """Convert bytes to a human-readable string."""
    for unit in ["B", "KB", "MB", "GB"]:
        if size_bytes < 1024:
            return f"{size_bytes:.1f} {unit}"
        size_bytes /= 1024
    return f"{size_bytes:.1f} TB"
