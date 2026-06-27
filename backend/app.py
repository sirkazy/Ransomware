"""
Ransomware Guardian — Application Entry Point
Initializes all system components and starts the Flask API server
alongside the background monitoring engine.

Usage:
    python app.py
"""

import os
import signal
import sys
import threading
from queue import Queue

from flask import Flask
from flask_cors import CORS

import config
from api.routes import api_bp, set_simulator, set_analyzer
from monitoring.behavior_analyzer import BehaviorAnalyzer
from monitoring.detection_engine import DetectionEngine
from monitoring.file_monitor import FileMonitor
from monitoring.response_handler import ResponseHandler
from simulation.simulator import RansomwareSimulator
from storage.database import init_db, add_event
from utils.constants import EventStatus
from utils.logger import setup_logger, get_logger

setup_logger()
logger = get_logger("app")


def create_app():
    """Create and configure the Flask application."""
    app = Flask(__name__)
    CORS(app, resources={r"/api/*": {"origins": "*"}})
    app.register_blueprint(api_bp)

    @app.route("/")
    def index():
        return {
            "name": "Ransomware Guardian API",
            "version": "1.0.0",
            "status": "running",
            "endpoints": [
                "GET  /api/status",
                "GET  /api/alerts",
                "GET  /api/monitoring",
                "POST /api/simulate",
                "POST /api/alerts/<id>/action",
            ],
        }

    return app


def start_monitoring():
    """
    Initialize and start the monitoring pipeline:
    FileMonitor → BehaviorAnalyzer → DetectionEngine → ResponseHandler

    Returns all component references for graceful shutdown.
    """
    event_queue = Queue()

    detection_engine = DetectionEngine()

    response_handler = ResponseHandler(detection_engine)

    def on_detection(event, analysis_result):
        """Callback when analyzer detects suspicious behavior."""
        response_handler.handle(event, analysis_result)

    def on_normal_event(event):
        """Callback for normal events — log them."""
        response_handler.handle_normal_event(event)

    analyzer = BehaviorAnalyzer(
        event_queue=event_queue,
        detection_callback=on_detection,
    )

    original_loop = analyzer.process_loop

    def enhanced_loop():
        """Enhanced loop that also logs non-suspicious events."""
        analyzer._running = True
        logger.info("Enhanced behavior analyzer started")

        while analyzer._running:
            try:
                if not analyzer.event_queue.empty():
                    event = analyzer.event_queue.get(timeout=1)
                    result = analyzer.analyze_event(event)

                    if result.score > 0 and analyzer.detection_callback:
                        analyzer.detection_callback(event, result)
                    else:
                        on_normal_event(event)
                else:
                    import time
                    time.sleep(0.5)

                analyzer._cleanup_window()

            except Exception as e:
                logger.error("Error in analyzer loop: %s", e)
                import time
                time.sleep(1)

    file_monitor = FileMonitor(event_queue)

    monitor_thread = threading.Thread(
        target=file_monitor.start,
        name="FileMonitor",
        daemon=True,
    )
    monitor_thread.start()

    analyzer_thread = threading.Thread(
        target=enhanced_loop,
        name="BehaviorAnalyzer",
        daemon=True,
    )
    analyzer_thread.start()

    logger.info("Monitoring pipeline started (2 background threads)")

    return {
        "file_monitor": file_monitor,
        "analyzer": analyzer,
        "detection_engine": detection_engine,
        "response_handler": response_handler,
        "event_queue": event_queue,
    }


def main():
    """Main entry point — start everything."""
    logger.info("=" * 60)
    logger.info("  Ransomware Guardian — Starting Up")
    logger.info("=" * 60)

    os.makedirs(config.STORAGE_DIR, exist_ok=True)
    os.makedirs(config.LOGS_DIR, exist_ok=True)
    os.makedirs(config.TEST_FILES_DIR, exist_ok=True)

    init_db()
    logger.info("Database initialized")

    components = start_monitoring()
    logger.info("Monitoring pipeline active")

    simulator = RansomwareSimulator()
    set_simulator(simulator)
    set_analyzer(components["analyzer"])
    logger.info("Simulator ready")

    def shutdown(signum, frame):
        logger.info("Shutting down gracefully...")
        components["file_monitor"].stop()
        components["analyzer"].stop()
        logger.info("Goodbye!")
        sys.exit(0)

    signal.signal(signal.SIGINT, shutdown)
    signal.signal(signal.SIGTERM, shutdown)

    app = create_app()

    logger.info("=" * 60)
    logger.info("  API Server: http://%s:%s", config.API_HOST, config.API_PORT)
    logger.info("  Monitoring: %d directories", len(config.MONITORED_DIRECTORIES))
    logger.info("  Test files: %s", config.TEST_FILES_DIR)
    logger.info("=" * 60)

    app.run(
        host=config.API_HOST,
        port=config.API_PORT,
        debug=False,
        use_reloader=False,
    )


if __name__ == "__main__":
    main()
