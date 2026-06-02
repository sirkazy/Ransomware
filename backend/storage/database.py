"""
Ransomware Guardian — Database Module
SQLite storage for monitoring events and alerts, with JSON backup.
"""

import json
import os
import sqlite3
import threading
from datetime import datetime, timedelta

import config
from utils.helpers import format_timestamp, generate_event_id
from utils.logger import get_logger

logger = get_logger("database")

# Thread-local storage for SQLite connections (SQLite is not thread-safe)
_local = threading.local()


def _get_connection():
    """Get a thread-local SQLite connection."""
    if not hasattr(_local, "connection") or _local.connection is None:
        os.makedirs(config.STORAGE_DIR, exist_ok=True)
        _local.connection = sqlite3.connect(config.DB_PATH)
        _local.connection.row_factory = sqlite3.Row
        _local.connection.execute("PRAGMA journal_mode=WAL")
    return _local.connection


def init_db():
    """Initialize the database tables."""
    conn = _get_connection()
    cursor = conn.cursor()

    # ── Monitoring Events Table ────────────────────────────────────
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS monitoring_events (
            id          TEXT PRIMARY KEY,
            event_type  TEXT NOT NULL,
            file_path   TEXT NOT NULL,
            timestamp   TEXT NOT NULL,
            status      TEXT NOT NULL DEFAULT 'normal',
            action      TEXT NOT NULL DEFAULT 'File Modified',
            details     TEXT DEFAULT ''
        )
    """)

    # ── Alerts Table ───────────────────────────────────────────────
    cursor.execute("""
        CREATE TABLE IF NOT EXISTS alerts (
            id                TEXT PRIMARY KEY,
            title             TEXT NOT NULL,
            description       TEXT NOT NULL,
            severity          TEXT NOT NULL DEFAULT 'safe',
            timestamp         TEXT NOT NULL,
            detection_reason  TEXT NOT NULL DEFAULT '',
            affected_files    TEXT NOT NULL DEFAULT '[]',
            suggested_action  TEXT NOT NULL DEFAULT ''
        )
    """)

    # ── Indexes ────────────────────────────────────────────────────
    cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_events_timestamp
        ON monitoring_events(timestamp DESC)
    """)
    cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_alerts_timestamp
        ON alerts(timestamp DESC)
    """)
    cursor.execute("""
        CREATE INDEX IF NOT EXISTS idx_alerts_severity
        ON alerts(severity)
    """)

    conn.commit()
    logger.info("Database initialized successfully")


# ═══════════════════════════════════════════════════════════════════════
# Monitoring Events
# ═══════════════════════════════════════════════════════════════════════

def add_event(event_type, file_path, status="normal", action="File Modified",
              details=""):
    """Insert a monitoring event into the database."""
    conn = _get_connection()
    event_id = generate_event_id()
    timestamp = format_timestamp()

    conn.execute(
        """INSERT INTO monitoring_events
           (id, event_type, file_path, timestamp, status, action, details)
           VALUES (?, ?, ?, ?, ?, ?, ?)""",
        (event_id, event_type, file_path, timestamp, status, action, details),
    )
    conn.commit()

    # Also write to JSON log
    _append_json_log({
        "id": event_id,
        "event_type": event_type,
        "file_path": file_path,
        "timestamp": timestamp,
        "status": status,
        "action": action,
        "details": details,
    })

    return event_id


def get_events(limit=100):
    """Retrieve recent monitoring events."""
    conn = _get_connection()
    cursor = conn.execute(
        """SELECT id, action, file_path, status, timestamp
           FROM monitoring_events
           ORDER BY timestamp DESC
           LIMIT ?""",
        (limit,),
    )
    rows = cursor.fetchall()

    return [
        {
            "id": row["id"],
            "action": row["action"],
            "file_path": row["file_path"],
            "status": row["status"],
            "timestamp": row["timestamp"],
        }
        for row in rows
    ]


def get_event_count_in_window(seconds=None):
    """Count events within the configured time window."""
    if seconds is None:
        seconds = config.TIME_WINDOW_SECONDS
    conn = _get_connection()
    cutoff = format_timestamp(datetime.now() - timedelta(seconds=seconds))
    cursor = conn.execute(
        "SELECT COUNT(*) as cnt FROM monitoring_events WHERE timestamp >= ?",
        (cutoff,),
    )
    return cursor.fetchone()["cnt"]


def clear_events():
    """Delete all monitoring events."""
    conn = _get_connection()
    conn.execute("DELETE FROM monitoring_events")
    conn.commit()
    logger.info("All monitoring events cleared")


# ═══════════════════════════════════════════════════════════════════════
# Alerts
# ═══════════════════════════════════════════════════════════════════════

def add_alert(alert_id, title, description, severity, detection_reason,
              affected_files, suggested_action):
    """Insert an alert into the database."""
    conn = _get_connection()
    timestamp = format_timestamp()
    files_json = json.dumps(affected_files)

    conn.execute(
        """INSERT INTO alerts
           (id, title, description, severity, timestamp,
            detection_reason, affected_files, suggested_action)
           VALUES (?, ?, ?, ?, ?, ?, ?, ?)""",
        (alert_id, title, description, severity, timestamp,
         detection_reason, files_json, suggested_action),
    )
    conn.commit()

    # Also write to alerts JSON
    _append_json_alert({
        "id": alert_id,
        "title": title,
        "description": description,
        "severity": severity,
        "timestamp": timestamp,
        "detection_reason": detection_reason,
        "affected_files": affected_files,
        "suggested_action": suggested_action,
    })

    logger.info("Alert stored: %s [%s] — %s", alert_id, severity, title)
    return alert_id


def get_alerts(limit=50):
    """Retrieve all alerts, newest first."""
    conn = _get_connection()
    cursor = conn.execute(
        """SELECT id, title, description, severity, timestamp,
                  detection_reason, affected_files, suggested_action
           FROM alerts
           ORDER BY timestamp DESC
           LIMIT ?""",
        (limit,),
    )
    rows = cursor.fetchall()

    return [
        {
            "id": row["id"],
            "title": row["title"],
            "description": row["description"],
            "severity": row["severity"],
            "timestamp": row["timestamp"],
            "detection_reason": row["detection_reason"],
            "affected_files": json.loads(row["affected_files"]),
            "suggested_action": row["suggested_action"],
        }
        for row in rows
    ]


def get_alert_by_id(alert_id):
    """Retrieve a single alert by ID."""
    conn = _get_connection()
    cursor = conn.execute(
        """SELECT id, title, description, severity, timestamp,
                  detection_reason, affected_files, suggested_action
           FROM alerts WHERE id = ?""",
        (alert_id,),
    )
    row = cursor.fetchone()
    if row is None:
        return None

    return {
        "id": row["id"],
        "title": row["title"],
        "description": row["description"],
        "severity": row["severity"],
        "timestamp": row["timestamp"],
        "detection_reason": row["detection_reason"],
        "affected_files": json.loads(row["affected_files"]),
        "suggested_action": row["suggested_action"],
    }


def get_alert_counts():
    """Get counts of alerts by severity."""
    conn = _get_connection()
    cursor = conn.execute(
        """SELECT severity, COUNT(*) as cnt
           FROM alerts GROUP BY severity"""
    )
    counts = {"safe": 0, "warning": 0, "critical": 0}
    for row in cursor.fetchall():
        counts[row["severity"]] = row["cnt"]
    return counts


def clear_alerts():
    """Delete all alerts."""
    conn = _get_connection()
    conn.execute("DELETE FROM alerts")
    conn.commit()
    logger.info("All alerts cleared")


# ═══════════════════════════════════════════════════════════════════════
# System Status (aggregated)
# ═══════════════════════════════════════════════════════════════════════

def get_system_status():
    """
    Build system status object matching the Flutter SystemStatus model.
    """
    conn = _get_connection()

    # Total threats (warning + critical alerts)
    cursor = conn.execute(
        "SELECT COUNT(*) as cnt FROM alerts WHERE severity IN ('warning', 'critical')"
    )
    threats_detected = cursor.fetchone()["cnt"]

    # Total monitored events (proxy for "files monitored")
    cursor = conn.execute("SELECT COUNT(*) as cnt FROM monitoring_events")
    files_monitored = cursor.fetchone()["cnt"]

    # Suspicious activities
    cursor = conn.execute(
        "SELECT COUNT(*) as cnt FROM monitoring_events WHERE status = 'suspicious'"
    )
    suspicious_activities = cursor.fetchone()["cnt"]

    # Recent critical alerts → system not secure
    cursor = conn.execute(
        """SELECT COUNT(*) as cnt FROM alerts
           WHERE severity = 'critical'
           AND timestamp >= ?""",
        (format_timestamp(datetime.now() - timedelta(hours=1)),),
    )
    recent_critical = cursor.fetchone()["cnt"]
    is_secure = recent_critical == 0

    # Threat activity data (events per hour for last 12 hours)
    threat_activity_data = []
    now = datetime.now()
    for i in range(11, -1, -1):
        start = format_timestamp(now - timedelta(hours=i + 1))
        end = format_timestamp(now - timedelta(hours=i))
        cursor = conn.execute(
            """SELECT COUNT(*) as cnt FROM monitoring_events
               WHERE status IN ('suspicious', 'blocked')
               AND timestamp >= ? AND timestamp < ?""",
            (start, end),
        )
        threat_activity_data.append(float(cursor.fetchone()["cnt"]))

    return {
        "is_secure": is_secure,
        "threats_detected": threats_detected,
        "files_monitored": files_monitored,
        "suspicious_activities": suspicious_activities,
        "is_monitoring_active": True,
        "threat_activity_data": threat_activity_data,
    }


# ═══════════════════════════════════════════════════════════════════════
# JSON File Backup
# ═══════════════════════════════════════════════════════════════════════

_json_lock = threading.Lock()


def _append_json_log(entry):
    """Append an event to the JSON log file."""
    _append_to_json_file(config.LOGS_JSON_PATH, entry)


def _append_json_alert(entry):
    """Append an alert to the JSON alerts file."""
    _append_to_json_file(config.ALERTS_JSON_PATH, entry)


def _append_to_json_file(file_path, entry):
    """Thread-safe append to a JSON array file."""
    with _json_lock:
        os.makedirs(os.path.dirname(file_path), exist_ok=True)
        data = []
        if os.path.exists(file_path):
            try:
                with open(file_path, "r") as f:
                    data = json.load(f)
            except (json.JSONDecodeError, IOError):
                data = []

        data.append(entry)

        with open(file_path, "w") as f:
            json.dump(data, f, indent=2)
