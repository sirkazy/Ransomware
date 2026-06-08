"""
Ransomware Guardian — Behavior Analyzer
Analyzes file events to detect suspicious ransomware-like patterns.
Uses a sliding window to track event frequency and characteristics.
"""

import threading
import time
from collections import defaultdict, deque
from datetime import datetime, timedelta

import config
from utils.constants import EventType, EventStatus, ActionType, ThreatLevel
from utils.helpers import get_file_extension, format_timestamp
from utils.logger import get_logger

logger = get_logger("behavior_analyzer")


class AnalysisResult:
    """Result of a behavioral analysis pass."""

    def __init__(self, score=0, threat_level=ThreatLevel.SAFE, reason="",
                 affected_files=None, action=ActionType.FILE_MODIFIED,
                 status=EventStatus.NORMAL):
        self.score = score
        self.threat_level = threat_level
        self.reason = reason
        self.affected_files = affected_files or []
        self.action = action
        self.status = status

    def __repr__(self):
        return (
            f"AnalysisResult(score={self.score}, level={self.threat_level}, "
            f"reason='{self.reason}')"
        )


class BehaviorAnalyzer:
    """
    Tracks file events in a sliding time window and identifies
    suspicious patterns consistent with ransomware behavior.
    """

    def __init__(self, event_queue, detection_callback=None):
        self.event_queue = event_queue
        self.detection_callback = detection_callback
        self._running = False

        self._events = deque()
        self._lock = threading.Lock()

        self._modification_count = 0
        self._rename_count = 0
        self._extension_changes = []
        self._affected_files = set()

    def process_loop(self):
        """
        Main processing loop. Runs in a background thread.
        Pulls events from the queue and analyzes them.
        """
        self._running = True
        logger.info("Behavior analyzer started")

        while self._running:
            try:
                if not self.event_queue.empty():
                    event = self.event_queue.get(timeout=1)
                    result = self.analyze_event(event)

                    if result.score > 0 and self.detection_callback:
                        self.detection_callback(event, result)
                else:
                    time.sleep(0.5)

                self._cleanup_window()

            except Exception as e:
                logger.error("Error in analyzer loop: %s", e)
                time.sleep(1)

        logger.info("Behavior analyzer stopped")

    def analyze_event(self, event):
        """
        Analyze a single file event against behavioral rules.
        Returns an AnalysisResult with a suspicion score and details.
        """
        event_type = event["event_type"]
        file_path = event["file_path"]
        dest_path = event.get("dest_path")
        extension = event.get("extension", "")
        now = datetime.now()

        with self._lock:
            self._events.append({"event": event, "time": now})
            self._affected_files.add(file_path)

        score = 0
        reasons = []
        action = self._event_to_action(event_type)
        status = EventStatus.NORMAL

        if event_type == EventType.MODIFIED:
            self._modification_count += 1
            window_count = self._count_events_in_window(EventType.MODIFIED)

            if window_count > config.MAX_FILE_MODIFICATIONS:
                score += 60
                reasons.append(
                    f"Rapid file modifications detected: {window_count} files "
                    f"modified in {config.TIME_WINDOW_SECONDS}s "
                    f"(threshold: {config.MAX_FILE_MODIFICATIONS})"
                )
                action = ActionType.RAPID_MODIFICATION
                status = EventStatus.SUSPICIOUS

        if event_type == EventType.RENAMED and dest_path:
            self._rename_count += 1
            new_ext = get_file_extension(dest_path)

            if new_ext in config.SUSPICIOUS_EXTENSIONS:
                score += 80
                self._extension_changes.append(dest_path)
                reasons.append(
                    f"File renamed to suspicious extension '{new_ext}': "
                    f"{file_path} → {dest_path}"
                )
                action = ActionType.ENCRYPTION_DETECTED
                status = EventStatus.BLOCKED

        if event_type == EventType.RENAMED:
            rename_count = self._count_events_in_window(EventType.RENAMED)
            if rename_count > config.RENAME_THRESHOLD:
                score += 50
                reasons.append(
                    f"Bulk file renaming detected: {rename_count} files "
                    f"renamed in {config.TIME_WINDOW_SECONDS}s"
                )
                action = ActionType.BULK_RENAME
                status = EventStatus.SUSPICIOUS

        extension_change_count = len(self._extension_changes)
        if extension_change_count > config.EXTENSION_CHANGE_THRESHOLD:
            score += 40
            reasons.append(
                f"Multiple extension changes detected: "
                f"{extension_change_count} suspicious extension changes"
            )

        if score >= 70:
            threat_level = ThreatLevel.CRITICAL
        elif score >= 30:
            threat_level = ThreatLevel.WARNING
        else:
            threat_level = ThreatLevel.SAFE

        reason = " | ".join(reasons) if reasons else ""

        result = AnalysisResult(
            score=min(score, 100),
            threat_level=threat_level,
            reason=reason,
            affected_files=list(self._affected_files),
            action=action,
            status=status,
        )

        if score > 0:
            logger.warning(
                "Suspicious activity (score=%d, level=%s): %s",
                score, threat_level, reason,
            )

        return result

    def _count_events_in_window(self, event_type):
        """Count events of a specific type within the time window."""
        cutoff = datetime.now() - timedelta(seconds=config.TIME_WINDOW_SECONDS)
        with self._lock:
            return sum(
                1 for item in self._events
                if item["time"] >= cutoff
                and item["event"]["event_type"] == event_type
            )

    def _cleanup_window(self):
        """Remove events older than the time window."""
        cutoff = datetime.now() - timedelta(seconds=config.TIME_WINDOW_SECONDS)
        with self._lock:
            while self._events and self._events[0]["time"] < cutoff:
                self._events.popleft()

            self._extension_changes = self._extension_changes[-50:]

    def _event_to_action(self, event_type):
        """Map event type to a human-readable action string."""
        mapping = {
            EventType.CREATED: ActionType.FILE_CREATED,
            EventType.MODIFIED: ActionType.FILE_MODIFIED,
            EventType.DELETED: ActionType.FILE_DELETED,
            EventType.RENAMED: ActionType.FILE_RENAMED,
        }
        return mapping.get(event_type, ActionType.FILE_MODIFIED)

    def stop(self):
        """Stop the analyzer processing loop."""
        self._running = False

    def reset(self):
        """Reset all counters and windows."""
        with self._lock:
            self._events.clear()
            self._modification_count = 0
            self._rename_count = 0
            self._extension_changes.clear()
            self._affected_files.clear()
