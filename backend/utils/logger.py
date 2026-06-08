"""
Ransomware Guardian — Logging Configuration
Centralized logging with console and rotating file handlers.
"""

import logging
import os
from logging.handlers import RotatingFileHandler

import config


def setup_logger(name="guardian"):
    """
    Set up and return a configured logger.

    - Console handler: INFO level with readable format
    - File handler: rotating log file (5 MB max, 3 backups)
    """
    logger = logging.getLogger(name)

    if logger.handlers:
        return logger

    logger.setLevel(getattr(logging, config.LOG_LEVEL, logging.INFO))

    fmt = "[%(asctime)s] [%(levelname)-8s] [%(name)-20s] %(message)s"
    date_fmt = "%Y-%m-%d %H:%M:%S"
    formatter = logging.Formatter(fmt, datefmt=date_fmt)

    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    console_handler.setFormatter(formatter)
    logger.addHandler(console_handler)

    os.makedirs(config.LOGS_DIR, exist_ok=True)
    file_handler = RotatingFileHandler(
        config.LOG_FILE,
        maxBytes=config.LOG_MAX_BYTES,
        backupCount=config.LOG_BACKUP_COUNT,
    )
    file_handler.setLevel(logging.DEBUG)
    file_handler.setFormatter(formatter)
    logger.addHandler(file_handler)

    return logger


def get_logger(module_name):
    """
    Get a child logger for a specific module.
    Usage: logger = get_logger("file_monitor")
    """
    parent = setup_logger()
    return parent.getChild(module_name)
