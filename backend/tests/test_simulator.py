"""
Tests for the Ransomware Simulator.
Verifies safe file creation, modification, and cleanup.
"""

import os
import sys

sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import pytest

import config
from simulation.simulator import RansomwareSimulator

TEST_DIR = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "sim_test_files"
)


@pytest.fixture
def simulator():
    """Create a simulator with a test-specific directory."""
    config.TEST_FILES_DIR = TEST_DIR
    config.SIMULATION_FILE_COUNT = 10
    config.SIMULATION_DELAY = 0.01

    sim = RansomwareSimulator()
    sim.test_dir = TEST_DIR
    yield sim

    sim.cleanup()
    if os.path.exists(TEST_DIR):
        for f in os.listdir(TEST_DIR):
            os.remove(os.path.join(TEST_DIR, f))
        os.rmdir(TEST_DIR)


class TestSimulatorSetup:
    """Tests for file creation phase."""

    def test_creates_test_files(self, simulator):
        """Simulator should create the configured number of files."""
        count = simulator.setup_test_files()
        assert count == 10
        assert len(os.listdir(TEST_DIR)) == 10

    def test_files_have_content(self, simulator):
        """Created files should contain text content."""
        simulator.setup_test_files()
        for filepath in simulator.created_files[:3]:
            with open(filepath, "r") as f:
                content = f.read()
            assert len(content) > 0

    def test_files_have_valid_extensions(self, simulator):
        """Created files should have standard document extensions."""
        simulator.setup_test_files()
        valid_exts = {".txt", ".docx", ".xlsx", ".pdf", ".csv", ".md"}
        for filepath in simulator.created_files:
            _, ext = os.path.splitext(filepath)
            assert ext in valid_exts


class TestSimulatorModification:
    """Tests for rapid modification phase."""

    def test_modifies_files(self, simulator):
        """Simulator should modify all created files."""
        simulator.setup_test_files()
        modified = simulator.simulate_rapid_modifications()
        assert modified == 10

    def test_files_content_changed(self, simulator):
        """Modified files should have additional content."""
        simulator.setup_test_files()

        original = {}
        for filepath in simulator.created_files[:3]:
            with open(filepath, "r") as f:
                original[filepath] = f.read()

        simulator.simulate_rapid_modifications()

        for filepath, orig_content in original.items():
            with open(filepath, "r") as f:
                new_content = f.read()
            assert len(new_content) > len(orig_content)


class TestSimulatorRename:
    """Tests for extension change phase."""

    def test_renames_files(self, simulator):
        """Simulator should rename files to suspicious extensions."""
        simulator.setup_test_files()
        renamed = simulator.simulate_extension_changes()
        assert renamed > 0

    def test_uses_suspicious_extensions(self, simulator):
        """Renamed files should have suspicious extensions."""
        simulator.setup_test_files()
        simulator.simulate_extension_changes()

        suspicious = config.SUSPICIOUS_EXTENSIONS[:3]
        for original, renamed in simulator.renamed_files.items():
            _, ext = os.path.splitext(renamed)
            assert ext in suspicious


class TestSimulatorCleanup:
    """Tests for cleanup and safety."""

    def test_cleanup_removes_files(self, simulator):
        """Cleanup should remove all test files."""
        simulator.setup_test_files()
        simulator.simulate_rapid_modifications()
        simulator.simulate_extension_changes()
        simulator.cleanup()

        remaining = os.listdir(TEST_DIR) if os.path.exists(TEST_DIR) else []
        assert len(remaining) == 0

    def test_full_simulation(self, simulator):
        """Full simulation should run without errors."""
        result = simulator.run_simulation()

        assert "files_created" in result
        assert "files_modified" in result
        assert "files_renamed" in result
        assert result["files_created"] == 10

    def test_simulator_only_touches_test_dir(self, simulator):
        """Simulator should never create files outside test_files."""
        simulator.run_simulation()

        parent = os.path.dirname(TEST_DIR)
        for item in os.listdir(parent):
            item_path = os.path.join(parent, item)
            if item_path == TEST_DIR:
                continue
            assert "document_" not in item
