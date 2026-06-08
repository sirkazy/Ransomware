"""
Ransomware Guardian — API Routes
Flask Blueprint defining all REST API endpoints.
"""

from flask import Blueprint, jsonify, request

from api.controllers import (
    get_status_data,
    get_alerts_data,
    get_monitoring_data,
    trigger_simulation,
    handle_alert_action,
)
from utils.logger import get_logger

logger = get_logger("routes")

_simulator = None


def set_simulator(simulator):
    """Set the simulator reference for the /simulate endpoint."""
    global _simulator
    _simulator = simulator


api_bp = Blueprint("api", __name__, url_prefix="/api")


@api_bp.route("/status", methods=["GET"])
def status():
    """Return current system monitoring status."""
    data, status_code = get_status_data()
    return jsonify(data), status_code


@api_bp.route("/alerts", methods=["GET"])
def alerts():
    """Return all threat alerts."""
    data, status_code = get_alerts_data()
    return jsonify(data), status_code


@api_bp.route("/monitoring", methods=["GET"])
def monitoring():
    """Return recent monitoring events."""
    data, status_code = get_monitoring_data()
    return jsonify(data), status_code


@api_bp.route("/simulate", methods=["POST"])
def simulate():
    """Trigger a ransomware simulation for testing."""
    data, status_code = trigger_simulation(_simulator)
    return jsonify(data), status_code


@api_bp.route("/alerts/<alert_id>/action", methods=["POST"])
def alert_action(alert_id):
    """Execute an action on a specific alert."""
    body = request.get_json(silent=True) or {}
    action = body.get("action", "ignore")
    data, status_code = handle_alert_action(alert_id, action)
    return jsonify(data), status_code


@api_bp.errorhandler(404)
def not_found(error):
    return jsonify({"error": "Endpoint not found"}), 404


@api_bp.errorhandler(500)
def internal_error(error):
    logger.error("Internal server error: %s", error)
    return jsonify({"error": "Internal server error"}), 500
