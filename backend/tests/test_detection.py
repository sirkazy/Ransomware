"""
Tests for the Detection Engine.
Verifies that detection rules correctly classify behavior patterns.
"""

import os
import sys

# Add backend to path
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest
from monitoring.detection_engine import DetectionEngine, DetectionRule
from monitoring.behavior_analyzer import AnalysisResult
from utils.constants import ThreatLevel, ActionType, EventStatus


@pytest.fixture
def engine():
    """Create a fresh detection engine for each test."""
    return DetectionEngine()


@pytest.fixture
def base_event():
    """Create a base file event for testing."""
    return {
        "event_type": "modified",
        "file_path": "/home/user/Documents/test.txt",
        "dest_path": None,
        "extension": ".txt",
    }


class TestDetectionEngine:
    """Tests for rule-based detection logic."""

    def test_safe_activity_no_alert(self, engine, base_event):
        """Normal activity should not trigger any alert."""
        result = AnalysisResult(score=0, threat_level=ThreatLevel.SAFE)
        alert = engine.evaluate(base_event, result)
        assert alert is None

    def test_rapid_modification_triggers_warning(self, engine, base_event):
        """Rapid file modifications should trigger a warning alert."""
        result = AnalysisResult(
            score=55,
            threat_level=ThreatLevel.WARNING,
            reason="Rapid file modifications detected: 35 files modified in 60s (threshold: 30)",
            affected_files=["/home/user/Documents/test.txt"],
            action=ActionType.RAPID_MODIFICATION,
            status=EventStatus.SUSPICIOUS,
        )
        alert = engine.evaluate(base_event, result)

        assert alert is not None
        assert alert["severity"] == ThreatLevel.WARNING
        assert "Rapid" in alert["title"]
        assert alert["id"].startswith("ALT-")

    def test_ransomware_extension_triggers_critical(self, engine):
        """Files renamed to ransomware extensions should trigger critical."""
        event = {
            "event_type": "renamed",
            "file_path": "/home/user/Documents/report.docx",
            "dest_path": "/home/user/Documents/report.docx.locked",
            "extension": ".docx",
        }
        result = AnalysisResult(
            score=80,
            threat_level=ThreatLevel.CRITICAL,
            reason="File renamed to suspicious extension '.locked': report.docx → report.docx.locked",
            affected_files=[event["file_path"]],
            action=ActionType.ENCRYPTION_DETECTED,
            status=EventStatus.BLOCKED,
        )
        alert = engine.evaluate(event, result)

        assert alert is not None
        assert alert["severity"] == ThreatLevel.CRITICAL
        assert "Encryption" in alert["title"] or "Extension" in alert["title"]

    def test_bulk_rename_triggers_warning(self, engine, base_event):
        """Bulk file renaming should trigger a warning."""
        result = AnalysisResult(
            score=45,
            threat_level=ThreatLevel.WARNING,
            reason="Bulk file renaming detected: 15 files renamed in 60s",
            affected_files=[f"/home/user/doc_{i}.txt" for i in range(15)],
        )
        alert = engine.evaluate(base_event, result)

        assert alert is not None
        assert alert["severity"] == ThreatLevel.WARNING

    def test_multiple_extension_changes_critical(self, engine, base_event):
        """Multiple extension changes should trigger critical."""
        result = AnalysisResult(
            score=90,
            threat_level=ThreatLevel.CRITICAL,
            reason="Multiple extension changes detected: 10 suspicious extension changes",
            affected_files=[f"/home/user/file_{i}.txt" for i in range(10)],
        )
        alert = engine.evaluate(base_event, result)

        assert alert is not None
        assert alert["severity"] == ThreatLevel.CRITICAL

    def test_alert_has_required_fields(self, engine, base_event):
        """Generated alerts should contain all required fields."""
        result = AnalysisResult(
            score=60,
            threat_level=ThreatLevel.WARNING,
            reason="Rapid file modifications detected: 35 files modified in 60s (threshold: 30)",
            affected_files=["/home/user/test.txt"],
        )
        alert = engine.evaluate(base_event, result)

        assert alert is not None
        required_fields = [
            "id", "title", "description", "severity",
            "detection_reason", "affected_files", "suggested_action",
        ]
        for field in required_fields:
            assert field in alert, f"Missing field: {field}"

    def test_highest_severity_wins(self, engine):
        """When multiple rules trigger, the highest severity should win."""
        event = {
            "event_type": "renamed",
            "file_path": "/home/user/test.txt",
            "dest_path": "/home/user/test.txt.locked",
            "extension": ".txt",
        }
        # This reason triggers both bulk rename AND suspicious extension
        result = AnalysisResult(
            score=90,
            threat_level=ThreatLevel.CRITICAL,
            reason=(
                "Bulk file renaming detected: 15 files renamed in 60s | "
                "File renamed to suspicious extension '.locked'"
            ),
            affected_files=[event["file_path"]],
        )
        alert = engine.evaluate(event, result)

        assert alert is not None
        assert alert["severity"] == ThreatLevel.CRITICAL


class TestDetectionRule:
    """Tests for individual detection rule behavior."""

    def test_rule_evaluation(self):
        """A rule should return triggered=True when condition is met."""
        rule = DetectionRule(
            name="test_rule",
            condition_fn=lambda e, r: r.score > 50,
            threat_level=ThreatLevel.WARNING,
            title_template="Test Alert",
            description_template="Test description",
        )
        event = {"event_type": "modified", "file_path": "/test"}
        result = AnalysisResult(score=60)

        evaluation = rule.evaluate(event, result)
        assert evaluation["triggered"] is True

    def test_rule_no_trigger(self):
        """A rule should return triggered=False when condition is not met."""
        rule = DetectionRule(
            name="test_rule",
            condition_fn=lambda e, r: r.score > 90,
            threat_level=ThreatLevel.CRITICAL,
            title_template="Test",
            description_template="Test",
        )
        event = {"event_type": "modified", "file_path": "/test"}
        result = AnalysisResult(score=30)

        evaluation = rule.evaluate(event, result)
        assert evaluation["triggered"] is False
