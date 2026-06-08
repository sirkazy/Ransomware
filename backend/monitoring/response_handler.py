"""
Ransomware Guardian — Response Handler
Handles responses when ransomware activity is detected.
Stores alerts, logs events, and optionally terminates processes.
"""

import time

import psutil

from storage.database import add_alert, add_event
from utils.constants import EventStatus
from utils.logger import get_logger

logger = get_logger("response_handler")

ALERT_COOLDOWN_SECONDS = 30

NORMAL_EVENT_THROTTLE = 1.0


class ResponseHandler:
    """
    Processes detection alerts and executes appropriate responses:
    1. Store alert in database
    2. Log monitoring event
    3. Update system status
    4. Optionally terminate suspicious processes
    """

    def __init__(self, detection_engine):
        self.detection_engine = detection_engine
        self._last_alert_time = {}
        self._last_normal_log_time = 0

    def handle(self, event, analysis_result):
        """
        Called by the BehaviorAnalyzer when suspicious activity is found.
        Runs the detection engine and executes the response.
        """
        try:
            add_event(
                event_type=event["event_type"],
                file_path=event["file_path"],
                status=analysis_result.status,
                action=analysis_result.action,
                details=analysis_result.reason,
            )
        except Exception as e:
            logger.error("Failed to log event: %s", e)

        alert = self.detection_engine.evaluate(event, analysis_result)

        if alert is None:
            logger.info(
                "Suspicious activity noted but no alert rule triggered "
                "(score=%d)", analysis_result.score,
            )
            return None

        now = time.time()
        title = alert["title"]
        if title in self._last_alert_time:
            time_since_last = now - self._last_alert_time[title]
            if time_since_last < ALERT_COOLDOWN_SECONDS:
                logger.debug("Debouncing alert: %s", title)
                return None

        self._last_alert_time[title] = now

        try:
            add_alert(
                alert_id=alert["id"],
                title=alert["title"],
                description=alert["description"],
                severity=alert["severity"],
                detection_reason=alert["detection_reason"],
                affected_files=alert["affected_files"],
                suggested_action=alert["suggested_action"],
            )
        except Exception as e:
            logger.error("Failed to store alert: %s", e)

        logger.warning(
            "🚨 ALERT %s [%s]: %s — %d files affected",
            alert["id"],
            alert["severity"].upper(),
            alert["title"],
            len(alert["affected_files"]),
        )

        return alert

    def handle_normal_event(self, event):
        """
        Log a normal (non-suspicious) file event to the database.
        Called for events with score 0.
        """
        now = time.time()
        if now - self._last_normal_log_time < NORMAL_EVENT_THROTTLE:
            return
        self._last_normal_log_time = now

        try:
            action_map = {
                "created": "File Created",
                "modified": "File Modified",
                "deleted": "File Deleted",
                "renamed": "File Renamed",
            }
            add_event(
                event_type=event["event_type"],
                file_path=event["file_path"],
                status=EventStatus.NORMAL,
                action=action_map.get(event["event_type"], "File Modified"),
                details="",
            )
        except Exception as e:
            logger.error("Failed to log normal event: %s", e)

    @staticmethod
    def quarantine_action(alert_id):
        """
        Mock quarantine action — logs the quarantine for demo purposes.
        In a real system, this would isolate the affected files.
        """
        logger.info("🔒 Quarantine action executed for alert %s", alert_id)
        return {
            "success": True,
            "message": f"Alert {alert_id} — files quarantined successfully",
            "action": "quarantine",
        }

    @staticmethod
    def ignore_action(alert_id):
        """
        Mark an alert as ignored.
        """
        logger.info("✓ Alert %s ignored by user", alert_id)
        return {
            "success": True,
            "message": f"Alert {alert_id} — marked as ignored",
            "action": "ignore",
        }

    @staticmethod
    def stop_process_action(alert_id, pid=None):
        """
        Attempt to stop a suspicious process.
        For safety, this only terminates processes if a valid PID is provided
        and the process name matches known simulation processes.
        """
        if pid is None:
            logger.info(
                "⛔ Stop process action for alert %s (no PID — mock)",
                alert_id,
            )
            return {
                "success": True,
                "message": f"Alert {alert_id} — process stop simulated",
                "action": "stop_process",
            }

        try:
            proc = psutil.Process(pid)
            proc_name = proc.name()

            safe_names = ["python", "python3", "simulator"]
            if any(safe in proc_name.lower() for safe in safe_names):
                proc.terminate()
                logger.warning(
                    "⛔ Process %d (%s) terminated for alert %s",
                    pid, proc_name, alert_id,
                )
                return {
                    "success": True,
                    "message": (
                        f"Process {pid} ({proc_name}) terminated successfully"
                    ),
                    "action": "stop_process",
                }
            else:
                logger.warning(
                    "Refused to terminate process %d (%s) — not a known "
                    "safe target", pid, proc_name,
                )
                return {
                    "success": False,
                    "message": "Process not in safe termination list",
                    "action": "stop_process",
                }
        except psutil.NoSuchProcess:
            return {
                "success": False,
                "message": f"Process {pid} not found",
                "action": "stop_process",
            }
        except psutil.AccessDenied:
            return {
                "success": False,
                "message": f"Access denied to process {pid}",
                "action": "stop_process",
            }
