"""
Ransomware Guardian — Ransomware Simulator
Safely simulates ransomware-like behavior for testing the detection system.

SAFETY: This module ONLY operates on files inside the configured
test_files directory. It never touches real user data. All operations
are reversible via the cleanup method.
"""

import os
import random
import time

import config
from utils.logger import get_logger

logger = get_logger("simulator")

SAMPLE_CONTENTS = [
    "Quarterly financial report for Q4 2025.\nRevenue: $1.2M\n",
    "Meeting notes from team standup.\nAction items: review PR, deploy.\n",
    "Project proposal: AI-driven analytics platform.\nBudget: $50K\n",
    "Employee onboarding checklist.\n1. Setup laptop\n2. Access VPN\n",
    "Research paper draft: Behavioral Ransomware Detection.\n",
    "Invoice #2025-0042\nAmount: $3,500.00\nDue: 2025-12-15\n",
    "Client presentation slides — marketing campaign Q1.\n",
    "Database schema documentation.\nTables: users, orders, products.\n",
]

SAMPLE_EXTENSIONS = [".txt", ".docx", ".xlsx", ".pdf", ".csv", ".md"]


class RansomwareSimulator:
    """
    Simulates ransomware-like file operations for testing.

    Operations:
    1. Creates dummy files in test_files/
    2. Modifies files rapidly
    3. Renames files to suspicious extensions
    4. Cleans up after simulation
    """

    def __init__(self):
        self.test_dir = config.TEST_FILES_DIR
        self.created_files = []
        self.renamed_files = {}

    def setup_test_files(self, count=None):
        """Create dummy files for simulation."""
        if count is None:
            count = config.SIMULATION_FILE_COUNT

        os.makedirs(self.test_dir, exist_ok=True)

        self.created_files = []
        for i in range(count):
            ext = random.choice(SAMPLE_EXTENSIONS)
            filename = f"document_{i:03d}{ext}"
            filepath = os.path.join(self.test_dir, filename)

            content = random.choice(SAMPLE_CONTENTS)
            with open(filepath, "w") as f:
                f.write(content)

            self.created_files.append(filepath)

        logger.info(
            "Created %d test files in %s",
            len(self.created_files), self.test_dir,
        )
        return len(self.created_files)

    def simulate_rapid_modifications(self):
        """
        Simulate rapid file modifications — a key ransomware indicator.
        Modifies all test files in quick succession.
        """
        modified_count = 0

        for filepath in self.created_files:
            if not os.path.exists(filepath):
                continue
            try:
                with open(filepath, "a") as f:
                    f.write(f"\n[MODIFIED] Encrypted content block {random.randint(1000, 9999)}\n")
                modified_count += 1
                time.sleep(config.SIMULATION_DELAY)
            except OSError as e:
                logger.error("Failed to modify %s: %s", filepath, e)

        logger.info("Rapidly modified %d files", modified_count)
        return modified_count

    def simulate_extension_changes(self, count=20):
        """
        Simulate renaming files to suspicious extensions.
        This is the strongest ransomware behavior indicator.
        """
        renamed_count = 0
        suspicious_exts = config.SUSPICIOUS_EXTENSIONS[:3]

        for filepath in self.created_files[:count]:
            if not os.path.exists(filepath):
                continue
            try:
                ext = random.choice(suspicious_exts)
                new_path = filepath + ext
                os.rename(filepath, new_path)
                self.renamed_files[filepath] = new_path
                renamed_count += 1
                time.sleep(config.SIMULATION_DELAY)
            except OSError as e:
                logger.error("Failed to rename %s: %s", filepath, e)

        logger.info(
            "Renamed %d files to suspicious extensions", renamed_count,
        )
        return renamed_count

    def simulate_bulk_standard_renames(self, count=15):
        """
        Simulate renaming files to standard safe extensions (e.g. adding .bak).
        Triggers the Bulk Rename warning rule without triggering the suspicious extension rule.
        """
        renamed_count = 0
        for filepath in self.created_files[:count]:
            if not os.path.exists(filepath):
                continue
            try:
                new_path = filepath + ".bak"
                os.rename(filepath, new_path)
                self.renamed_files[filepath] = new_path
                renamed_count += 1
                time.sleep(config.SIMULATION_DELAY)
            except OSError as e:
                logger.error("Failed to rename %s: %s", filepath, e)

        logger.info(
            "Renamed %d files to standard extensions", renamed_count,
        )
        return renamed_count

    def run_simulation(self, sim_type="all"):
        """
        Execute the selected simulation scenario.
        Allowed types: 'rapid_modification', 'bulk_rename', 'mass_extension', 'all'
        """
        logger.info("=" * 50)
        logger.info("🧪 Starting ransomware simulation scenario: %s...", sim_type)
        logger.info("=" * 50)

        # Clear tracking
        self.created_files = []
        self.renamed_files = {}

        files_created = 0
        files_modified = 0
        files_renamed = 0

        if sim_type == "rapid_modification":
            files_created = self.setup_test_files(count=50)
            time.sleep(1)
            files_modified = self.simulate_rapid_modifications()
        elif sim_type == "bulk_rename":
            files_created = self.setup_test_files(count=15)
            time.sleep(1)
            files_renamed = self.simulate_bulk_standard_renames(count=15)
        elif sim_type == "mass_extension":
            files_created = self.setup_test_files(count=15)
            time.sleep(1)
            files_renamed = self.simulate_extension_changes(count=15)
        else:  # "all"
            files_created = self.setup_test_files(count=50)
            time.sleep(1)
            files_modified = self.simulate_rapid_modifications()
            time.sleep(1)
            files_renamed = self.simulate_extension_changes(count=20)

        time.sleep(2)
        self.cleanup()

        result = {
            "files_created": files_created,
            "files_modified": files_modified,
            "files_renamed": files_renamed,
            "alert_triggered": files_renamed > 0 or files_modified > 30,
        }

        logger.info("=" * 50)
        logger.info("🧪 Simulation complete: %s", result)
        logger.info("=" * 50)

        return result

    def cleanup(self):
        """
        Remove all test files and restore original state.
        """
        cleaned = 0

        for original, renamed in self.renamed_files.items():
            try:
                if os.path.exists(renamed):
                    os.remove(renamed)
                    cleaned += 1
            except OSError:
                pass

        for filepath in self.created_files:
            try:
                if os.path.exists(filepath):
                    os.remove(filepath)
                    cleaned += 1
            except OSError:
                pass

        self.created_files.clear()
        self.renamed_files.clear()

        logger.info("Cleaned up %d test files", cleaned)
