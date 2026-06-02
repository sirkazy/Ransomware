"""
Ransomware Guardian — API Controllers
Business logic for API endpoints. Fetches data from the database
and formats responses matching the Flutter frontend models.
"""

from storage.database import (
    get_system_status,
    get_alerts,
    get_alert_by_id,
    get_events,
)
from monitoring.response_handler import ResponseHandler
from utils.logger import get_logger

logger = get_logger("controllers")


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


def trigger_simulation(simulator):
    """
    Run the ransomware simulator and return results.
    """
    if simulator is None:
        return {"error": "Simulator not available"}, 503

    try:
        result = simulator.run_simulation()
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
        result = ResponseHandler.stop_process_action(alert_id)
    else:
        return {"error": f"Unknown action: {action}"}, 400

    return result, 200
