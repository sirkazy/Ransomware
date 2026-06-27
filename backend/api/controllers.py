"""
Ransomware Guardian — API Controllers
Business logic for API endpoints. Fetches data from the database
and formats responses matching the Flutter frontend models.
"""

import psutil

from storage.database import (
    get_system_status,
    get_alerts,
    get_alert_by_id,
    get_events,
    reset_system as db_reset_system,
    delete_alert,
)
from monitoring.response_handler import ResponseHandler
from utils.logger import get_logger
import config

logger = get_logger("controllers")


import os

def find_suspicious_process():
    """
    Use psutil to scan running processes and find the one with the most
    open file handles in any monitored directory. Returns a dict with
    pid, name, and open_files_count, or None if nothing suspicious found.
    Excludes the backend's own process to avoid self-termination.
    """
    monitored = config.MONITORED_DIRECTORIES
    best = None
    best_count = 0
    my_pid = os.getpid()

    for proc in psutil.process_iter(["pid", "name", "open_files"]):
        try:
            pid = proc.info["pid"]
            if pid == my_pid:
                continue

            files = proc.info.get("open_files") or []
            count = sum(
                1 for f in files
                if any(str(f.path).startswith(str(d)) for d in monitored)
            )
            if count > best_count:
                best_count = count
                best = {
                    "pid": pid,
                    "name": proc.info["name"],
                    "open_files_count": count,
                }
        except (psutil.NoSuchProcess, psutil.AccessDenied):
            continue

    return best


def get_status_data():
    """
    Build the system status response.
    Matches Flutter's SystemStatus model.
    """
    try:
        status = get_system_status()
        return status, 200
    except Exception as e:
        logger.error("Failed to fetch system status: %s", e)
        return {"error": "Failed to fetch system status"}, 500


def get_alerts_data():
    """
    Fetch all alerts, newest first.
    Matches Flutter's List<AlertModel>.
    """
    try:
        alerts = get_alerts(limit=50)
        return alerts, 200
    except Exception as e:
        logger.error("Failed to fetch alerts: %s", e)
        return {"error": "Failed to fetch alerts"}, 500


def get_monitoring_data():
    """
    Fetch recent monitoring events.
    Matches Flutter's List<MonitoringActivity>.
    """
    try:
        events = get_events(limit=100)
        return events, 200
    except Exception as e:
        logger.error("Failed to fetch monitoring data: %s", e)
        return {"error": "Failed to fetch monitoring events"}, 500


def trigger_simulation(simulator, sim_type="all"):
    """
    Run the ransomware simulator and return results.
    """
    if simulator is None:
        return {"error": "Simulator not available"}, 503

    try:
        result = simulator.run_simulation(sim_type)
        return {
            "message": "Simulation completed successfully",
            "files_created": result.get("files_created", 0),
            "files_modified": result.get("files_modified", 0),
            "files_renamed": result.get("files_renamed", 0),
            "alert_triggered": result.get("alert_triggered", False),
        }, 200
    except Exception as e:
        logger.error("Simulation failed: %s", e)
        return {"error": f"Simulation failed: {str(e)}"}, 500


def handle_alert_action(alert_id, action):
    """
    Handle an action on a specific alert (ignore/quarantine/stop).
    For stop_process, automatically scans running processes to find the
    most suspicious one (most open file handles in monitored dirs).
    """
    alert = get_alert_by_id(alert_id)
    if alert is None:
        return {"error": f"Alert {alert_id} not found"}, 404

    action = action.lower()

    if action == "ignore":
        result = ResponseHandler.ignore_action(alert_id)
    elif action == "quarantine":
        result = ResponseHandler.quarantine_action(alert_id)
    elif action == "stop_process":
        suspicious = find_suspicious_process()
        pid = suspicious["pid"] if suspicious else None
        result = ResponseHandler.stop_process_action(alert_id, pid=pid)
        if suspicious:
            result["process_name"] = suspicious["name"]
            result["pid"] = pid
    else:
        return {"error": f"Unknown action: {action}"}, 400

    # If the mitigation action succeeded, delete the resolved alert from active database
    if result.get("success"):
        delete_alert(alert_id)

    return result, 200


def reset_system_data(analyzer=None):
    """
    Reset all stored alerts and monitoring events back to a clean state.
    Also resets the behavior analyzer's internal sliding window counters.
    """
    try:
        db_reset_system()
        if analyzer is not None:
            try:
                analyzer.reset()
            except Exception:
                pass
        logger.info("System reset by user request")
        return {"success": True, "message": "System reset to secure state"}, 200
    except Exception as e:
        logger.error("Reset failed: %s", e)
        return {"error": f"Reset failed: {str(e)}"}, 500
