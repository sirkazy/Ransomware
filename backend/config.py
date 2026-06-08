"""
Ransomware Guardian — Configuration
Central configuration for all system components.
"""

import os

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
STORAGE_DIR = os.path.join(BASE_DIR, "storage")
LOGS_DIR = os.path.join(BASE_DIR, "logs")
TEST_FILES_DIR = os.path.join(BASE_DIR, "test_files")

MONITORED_DIRECTORIES = [
    os.path.expanduser("~/Documents"),
    os.path.expanduser("~/Downloads"),
    TEST_FILES_DIR,
]

MAX_FILE_MODIFICATIONS = 30
TIME_WINDOW_SECONDS = 60
EXTENSION_CHANGE_THRESHOLD = 5
RAPID_ACCESS_THRESHOLD = 20
RENAME_THRESHOLD = 10

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

API_HOST = "0.0.0.0"
API_PORT = 5000
API_PREFIX = "/api"
DEBUG_MODE = True

DB_PATH = os.path.join(STORAGE_DIR, "guardian.db")
LOGS_JSON_PATH = os.path.join(STORAGE_DIR, "logs.json")
ALERTS_JSON_PATH = os.path.join(STORAGE_DIR, "alerts.json")

LOG_FILE = os.path.join(LOGS_DIR, "guardian.log")
LOG_LEVEL = "INFO"
LOG_MAX_BYTES = 5 * 1024 * 1024
LOG_BACKUP_COUNT = 3

SIMULATION_FILE_COUNT = 50
SIMULATION_DELAY = 0.05
