"""
Ransomware Guardian — File Monitor
Real-time file system monitoring using watchdog.
Captures file creation, modification, deletion, and rename events.
"""

import os
import threading
from queue import Queue

from watchdog.events import FileSystemEventHandler
from watchdog.observers import Observer

import config
from utils.constants import EventType, EventStatus, ActionType
from utils.helpers import is_ignored, get_file_extension
from utils.logger import get_logger

logger = get_logger("file_monitor")


class FileEventHandler(FileSystemEventHandler):
    """
    Handles file system events detected by watchdog.
    Events are placed into a thread-safe queue for the
    BehaviorAnalyzer to process asynchronously.
    """

    def __init__(self, event_queue):
        super().__init__()
        self.event_queue = event_queue

    def _should_ignore(self, path):
        """Check if this file event should be ignored."""
        if path is None:
            return True
        return is_ignored(path, config.IGNORED_PATTERNS)

    def _enqueue(self, event_type, src_path, dest_path=None):
        """Put an event into the processing queue."""
        if self._should_ignore(src_path):
            return

        # Skip directory events — we only care about files
        event_data = {
            "event_type": event_type,
            "file_path": src_path,
            "dest_path": dest_path,
            "extension": get_file_extension(src_path),
        }
        self.event_queue.put(event_data)
        logger.debug("Event queued: %s → %s", event_type, src_path)

    def on_created(self, event):
        """Called when a file or directory is created."""
        if not event.is_directory:
            self._enqueue(EventType.CREATED, event.src_path)

    def on_modified(self, event):
        """Called when a file or directory is modified."""
        if not event.is_directory:
            self._enqueue(EventType.MODIFIED, event.src_path)

    def on_deleted(self, event):
        """Called when a file or directory is deleted."""
        if not event.is_directory:
            self._enqueue(EventType.DELETED, event.src_path)

    def on_moved(self, event):
        """Called when a file or directory is moved/renamed."""
        if not event.is_directory:
            self._enqueue(EventType.RENAMED, event.src_path, event.dest_path)


class FileMonitor:
    """
    Manages watchdog Observers for all monitored directories.
    Runs continuously in the background via threading.
    """

    def __init__(self, event_queue):
        self.event_queue = event_queue
        self.observers = []
        self.handler = FileEventHandler(event_queue)
        self._running = False

    def start(self):
        """Start monitoring all configured directories."""
        self._running = True
        logger.info("Starting file monitoring...")

        for directory in config.MONITORED_DIRECTORIES:
            # Create directory if it doesn't exist (especially test_files)
            os.makedirs(directory, exist_ok=True)

            if not os.path.isdir(directory):
                logger.warning("Skipping non-existent directory: %s", directory)
                continue

            observer = Observer()
            observer.schedule(self.handler, directory, recursive=True)
            observer.daemon = True
            observer.start()
            self.observers.append(observer)
            logger.info("Monitoring directory: %s", directory)

        logger.info(
            "File monitor started — watching %d directories",
            len(self.observers),
        )

    def stop(self):
        """Stop all observers gracefully."""
        self._running = False
        for observer in self.observers:
            observer.stop()
        for observer in self.observers:
            observer.join(timeout=5)
        self.observers.clear()
        logger.info("File monitor stopped")

    @property
    def is_running(self):
        return self._running and len(self.observers) > 0
