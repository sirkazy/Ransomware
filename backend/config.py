"""
Ransomware Guardian — Configuration
Central configuration for all system components.
"""

import os

# ── Base Paths ─────────────────────────────────────────────────────────
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
STORAGE_DIR = os.path.join(BASE_DIR, "storage")
LOGS_DIR = os.path.join(BASE_DIR, "logs")
TEST_FILES_DIR = os.path.join(BASE_DIR, "test_files")

# ── Monitored Directories ─────────────────────────────────────────────
# Add or remove directories to monitor.
# The test_files directory is always included for simulation.
MONITORED_DIRECTORIES = [
    os.path.expanduser("~/Documents"),
    os.path.expanduser("~/Downloads"),
    TEST_FILES_DIR,
]

# ── Detection Thresholds ──────────────────────────────────────────────
MAX_FILE_MODIFICATIONS = 30       # Max modifications before alert
TIME_WINDOW_SECONDS = 60          # Sliding window for counting events
EXTENSION_CHANGE_THRESHOLD = 5    # Bulk extension changes to trigger alert
RAPID_ACCESS_THRESHOLD = 20       # Same-file access count threshold
RENAME_THRESHOLD = 10             # Bulk renames to trigger alert

# ── Suspicious File Extensions ────────────────────────────────────────
SUSPICIOUS_EXTENSIONS = [
    ".locked",
    ".encrypted",
    ".crypt",
    ".enc",
    ".ransom",
    ".crypto",
    ".locky",
    ".wcry",
    ".wncry",
    ".zzzzz",
]

# ── Ignored Patterns ──────────────────────────────────────────────────
# Files/directories to ignore during monitoring
IGNORED_PATTERNS = [
    "__pycache__",
    ".DS_Store",
    ".git",
    ".swp",
    ".tmp",
    "~$",
    ".pyc",
    "node_modules",
]

# ── API Configuration ─────────────────────────────────────────────────
API_HOST = "0.0.0.0"
API_PORT = 5000
API_PREFIX = "/api"
DEBUG_MODE = True

# ── Database ──────────────────────────────────────────────────────────
DB_PATH = os.path.join(STORAGE_DIR, "guardian.db")
LOGS_JSON_PATH = os.path.join(STORAGE_DIR, "logs.json")
ALERTS_JSON_PATH = os.path.join(STORAGE_DIR, "alerts.json")

# ── Logging ───────────────────────────────────────────────────────────
LOG_FILE = os.path.join(LOGS_DIR, "guardian.log")
LOG_LEVEL = "INFO"
LOG_MAX_BYTES = 5 * 1024 * 1024   # 5 MB max log file size
LOG_BACKUP_COUNT = 3              # Keep 3 rotated log files

# ── Simulation ────────────────────────────────────────────────────────
SIMULATION_FILE_COUNT = 50        # Number of dummy files to create
SIMULATION_DELAY = 0.05           # Delay between simulated operations (seconds)
