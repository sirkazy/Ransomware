"""
Tests for the Flask API endpoints.
Uses Flask's test client to verify response formats and status codes.
"""

import json
import os
import sys

# Add backend to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest

import config
from storage.database import init_db, add_alert, add_event, clear_alerts, clear_events

# Override DB path for tests
config.DB_PATH = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "test_guardian.db"
)


@pytest.fixture(autouse=True)
def setup_db():
    """Initialize a clean test database for each test."""
    init_db()
    clear_alerts()
    clear_events()
    yield
    # Cleanup
    if os.path.exists(config.DB_PATH):
        os.remove(config.DB_PATH)


@pytest.fixture
def client():
    """Create a Flask test client."""
    from app import create_app
    app = create_app()
    app.config["TESTING"] = True
    with app.test_client() as client:
        yield client


@pytest.fixture
def sample_alert():
    """Add a sample alert to the database."""
    alert_id = "ALT-TEST01"
    add_alert(
        alert_id=alert_id,
        title="Test Ransomware Alert",
        description="Test alert for API testing.",
        severity="critical",
        detection_reason="Automated test detection",
        affected_files=["/test/file1.txt", "/test/file2.txt"],
        suggested_action="Run tests again.",
    )
    return alert_id


@pytest.fixture
def sample_events():
    """Add sample monitoring events to the database."""
    for i in range(5):
        add_event(
            event_type="modified",
            file_path=f"/home/user/doc_{i}.txt",
            status="normal",
            action="File Modified",
        )
    add_event(
        event_type="renamed",
        file_path="/home/user/suspicious.txt",
        status="suspicious",
        action="File Renamed",
    )


class TestStatusEndpoint:
    """Tests for GET /api/status."""

    def test_status_returns_200(self, client):
        """Status endpoint should return 200."""
        response = client.get("/api/status")
        assert response.status_code == 200

    def test_status_has_required_fields(self, client):
        """Status response should match Flutter SystemStatus model."""
        response = client.get("/api/status")
        data = json.loads(response.data)

        required_fields = [
            "is_secure",
            "threats_detected",
            "files_monitored",
            "suspicious_activities",
            "is_monitoring_active",
            "threat_activity_data",
        ]
        for field in required_fields:
            assert field in data, f"Missing field: {field}"

    def test_status_data_types(self, client):
        """Status fields should have correct data types."""
        response = client.get("/api/status")
        data = json.loads(response.data)

        assert isinstance(data["is_secure"], bool)
        assert isinstance(data["threats_detected"], int)
        assert isinstance(data["files_monitored"], int)
        assert isinstance(data["is_monitoring_active"], bool)
        assert isinstance(data["threat_activity_data"], list)


class TestAlertsEndpoint:
    """Tests for GET /api/alerts."""

    def test_alerts_returns_200(self, client):
        """Alerts endpoint should return 200."""
        response = client.get("/api/alerts")
        assert response.status_code == 200

    def test_alerts_returns_list(self, client):
        """Alerts endpoint should return a JSON list."""
        response = client.get("/api/alerts")
        data = json.loads(response.data)
        assert isinstance(data, list)

    def test_alerts_with_data(self, client, sample_alert):
        """Alerts endpoint should return inserted alerts."""
        response = client.get("/api/alerts")
        data = json.loads(response.data)
        assert len(data) >= 1
        assert data[0]["id"] == sample_alert

    def test_alert_has_required_fields(self, client, sample_alert):
        """Alert objects should match Flutter AlertModel."""
        response = client.get("/api/alerts")
        data = json.loads(response.data)
        alert = data[0]

        required_fields = [
            "id", "title", "description", "severity",
            "timestamp", "detection_reason", "affected_files",
            "suggested_action",
        ]
        for field in required_fields:
            assert field in alert, f"Missing field: {field}"


class TestMonitoringEndpoint:
    """Tests for GET /api/monitoring."""

    def test_monitoring_returns_200(self, client):
        """Monitoring endpoint should return 200."""
        response = client.get("/api/monitoring")
        assert response.status_code == 200

    def test_monitoring_returns_list(self, client):
        """Monitoring endpoint should return a JSON list."""
        response = client.get("/api/monitoring")
        data = json.loads(response.data)
        assert isinstance(data, list)

    def test_monitoring_with_events(self, client, sample_events):
        """Monitoring endpoint should return logged events."""
        response = client.get("/api/monitoring")
        data = json.loads(response.data)
        assert len(data) >= 6


class TestAlertActionEndpoint:
    """Tests for POST /api/alerts/<id>/action."""

    def test_ignore_action(self, client, sample_alert):
        """Ignore action should return success."""
        response = client.post(
            f"/api/alerts/{sample_alert}/action",
            json={"action": "ignore"},
        )
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data["success"] is True

    def test_quarantine_action(self, client, sample_alert):
        """Quarantine action should return success."""
        response = client.post(
            f"/api/alerts/{sample_alert}/action",
            json={"action": "quarantine"},
        )
        assert response.status_code == 200
        data = json.loads(response.data)
        assert data["success"] is True

    def test_invalid_alert_id(self, client):
        """Non-existent alert ID should return 404."""
        response = client.post(
            "/api/alerts/FAKE-ID/action",
            json={"action": "ignore"},
        )
        assert response.status_code == 404

    def test_invalid_action(self, client, sample_alert):
        """Unknown action should return 400."""
        response = client.post(
            f"/api/alerts/{sample_alert}/action",
            json={"action": "delete_everything"},
        )
        assert response.status_code == 400


class TestRootEndpoint:
    """Tests for the root API info endpoint."""

    def test_root_returns_200(self, client):
        response = client.get("/")
        assert response.status_code == 200

    def test_root_has_api_info(self, client):
        response = client.get("/")
        data = json.loads(response.data)
        assert "name" in data
        assert "Ransomware Guardian" in data["name"]
