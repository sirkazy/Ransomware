"""
Ransomware Guardian — Detection Engine
Rule-based engine that evaluates behavior analysis results
and determines whether an alert should be raised.
"""

from utils.constants import ThreatLevel, SUGGESTED_ACTIONS
from utils.helpers import generate_alert_id
from utils.logger import get_logger

logger = get_logger("detection_engine")


class DetectionRule:
    """Represents a single detection rule."""

    def __init__(self, name, condition_fn, threat_level, title_template,
                 description_template):
        self.name = name
        self.condition_fn = condition_fn
        self.threat_level = threat_level
        self.title_template = title_template
        self.description_template = description_template

    def evaluate(self, event, analysis_result):
        """Evaluate this rule against an event and its analysis result."""
        if self.condition_fn(event, analysis_result):
            return {
                "triggered": True,
                "threat_level": self.threat_level,
                "title": self.title_template,
                "description": self.description_template,
            }
        return {"triggered": False}


class DetectionEngine:
    """
    Applies a set of detection rules to behavioral analysis results.
    When rules trigger, it creates alert descriptors for the response handler.
    """

    def __init__(self):
        self.rules = self._build_rules()

    def _build_rules(self):
        """Define all detection rules."""
        return [
            DetectionRule(
                name="mass_modification",
                condition_fn=lambda e, r: (
                    r.score >= 50
                    and "Rapid file modifications" in r.reason
                ),
                threat_level=ThreatLevel.WARNING,
                title_template="Rapid File Modification Detected",
                description_template=(
                    "An unusually high number of file modifications were "
                    "detected in a short time period. This pattern is "
                    "consistent with ransomware encryption behavior."
                ),
            ),

            DetectionRule(
                name="ransomware_extension",
                condition_fn=lambda e, r: (
                    r.score >= 70
                    and "suspicious extension" in r.reason
                ),
                threat_level=ThreatLevel.CRITICAL,
                title_template="Ransomware Encryption Detected",
                description_template=(
                    "Files are being renamed with known ransomware "
                    "extensions. This is a strong indicator of active "
                    "ransomware encryption activity."
                ),
            ),

            DetectionRule(
                name="bulk_rename",
                condition_fn=lambda e, r: (
                    r.score >= 40
                    and "Bulk file renaming" in r.reason
                ),
                threat_level=ThreatLevel.WARNING,
                title_template="Bulk File Rename Operation",
                description_template=(
                    "A large number of files were renamed in rapid "
                    "succession. This could indicate ransomware preparing "
                    "to encrypt files or a mass file operation."
                ),
            ),

            DetectionRule(
                name="extension_flood",
                condition_fn=lambda e, r: (
                    "Multiple extension changes" in r.reason
                ),
                threat_level=ThreatLevel.CRITICAL,
                title_template="Mass Extension Change Attack",
                description_template=(
                    "Multiple files have had their extensions changed "
                    "to known ransomware extensions. Immediate action "
                    "is recommended to prevent further damage."
                ),
            ),
        ]

    def evaluate(self, event, analysis_result):
        """
        Run all detection rules against the analysis result.
        Returns the highest-severity alert descriptor, or None if
        no rules triggered.
        """
        if analysis_result.score == 0:
            return None

        triggered_results = []

        for rule in self.rules:
            result = rule.evaluate(event, analysis_result)
            if result["triggered"]:
                triggered_results.append(result)
                logger.info(
                    "Rule triggered: %s [%s]",
                    rule.name, result["threat_level"],
                )

        if not triggered_results:
            return None

        severity_order = {
            ThreatLevel.SAFE: 0,
            ThreatLevel.WARNING: 1,
            ThreatLevel.CRITICAL: 2,
        }
        triggered_results.sort(
            key=lambda r: severity_order.get(r["threat_level"], 0),
            reverse=True,
        )
        best = triggered_results[0]

        alert = {
            "id": generate_alert_id(),
            "title": best["title"],
            "description": best["description"],
            "severity": best["threat_level"],
            "detection_reason": analysis_result.reason,
            "affected_files": analysis_result.affected_files[:10],
            "suggested_action": SUGGESTED_ACTIONS.get(
                best["threat_level"],
                SUGGESTED_ACTIONS[ThreatLevel.WARNING],
            ),
        }

        logger.warning(
            "Alert generated: %s [%s] — %s",
            alert["id"], alert["severity"], alert["title"],
        )

        return alert
