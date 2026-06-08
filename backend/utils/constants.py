"""
Ransomware Guardian — Constants
Threat levels, event types, and status enums.
"""


class ThreatLevel:
    """Threat severity classification."""
    SAFE = "safe"
    WARNING = "warning"
    CRITICAL = "critical"


class EventType:
    """File system event types."""
    CREATED = "created"
    MODIFIED = "modified"
    DELETED = "deleted"
    RENAMED = "renamed"
    MOVED = "moved"


class EventStatus:
    """Monitoring event status classifications."""
    NORMAL = "normal"
    SUSPICIOUS = "suspicious"
    BLOCKED = "blocked"


class ActionType:
    """File action descriptions for the monitoring feed."""
    FILE_CREATED = "File Created"
    FILE_MODIFIED = "File Modified"
    FILE_DELETED = "File Deleted"
    FILE_RENAMED = "File Renamed"
    BULK_RENAME = "Bulk Rename Detected"
    EXTENSION_CHANGE = "Extension Change"
    ENCRYPTION_DETECTED = "Encryption Detected"
    PROCESS_BLOCKED = "Process Blocked"
    RAPID_MODIFICATION = "Rapid Modification"
    FILE_SCANNED = "File Scanned"


WATCHDOG_EVENT_MAP = {
    "created": EventType.CREATED,
    "modified": EventType.MODIFIED,
    "deleted": EventType.DELETED,
    "moved": EventType.RENAMED,
}

SUGGESTED_ACTIONS = {
    ThreatLevel.SAFE: (
        "No action required. System files are intact. "
        "Continue regular monitoring schedule."
    ),
    ThreatLevel.WARNING: (
        "Monitor the process for further suspicious activity. "
        "If file modifications continue, consider quarantining the source."
    ),
    ThreatLevel.CRITICAL: (
        "Immediately isolate the affected directory and terminate "
        "the suspicious process. Run a full system scan and restore "
        "files from backup if available."
    ),
}
