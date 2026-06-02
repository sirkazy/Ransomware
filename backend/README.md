# Ransomware Guardian — Backend

**Behavior-Based Ransomware Detection and Prevention Framework**

A lightweight Python Flask backend that monitors file system activity in real-time, detects suspicious ransomware-like behavior using rule-based analysis, and exposes monitoring data through a REST API for a Flutter mobile frontend.

> ⚠️ This is a **final year project prototype** for academic purposes. It is NOT a production antivirus system.

---

## Architecture

```
┌─────────────────────────────────────────────────────┐
│                  Flutter Mobile App                  │
│              (Dashboard, Alerts, Monitoring)          │
└───────────────────────┬─────────────────────────────┘
                        │ HTTP (REST API)
                        ▼
┌─────────────────────────────────────────────────────┐
│                   Flask API Server                   │
│         /api/status  /api/alerts  /api/monitoring     │
└───────────────────────┬─────────────────────────────┘
                        │
          ┌─────────────┼─────────────┐
          ▼             ▼             ▼
   ┌────────────┐ ┌──────────┐ ┌───────────┐
   │  Response   │ │ Detection│ │  Behavior │
   │  Handler    │ │  Engine  │ │  Analyzer │
   └─────┬──────┘ └────┬─────┘ └─────┬─────┘
         │              │             │
         ▼              │             ▼
   ┌──────────┐         │      ┌────────────┐
   │  SQLite   │         │      │   File     │
   │ Database  │◄────────┘      │  Monitor   │
   └──────────┘                 │ (watchdog) │
                                └────────────┘
```

---

## Quick Start

### 1. Install Dependencies

```bash
cd backend
pip install -r requirements.txt
```

### 2. Run the Backend

```bash
python app.py
```

The server starts on `http://0.0.0.0:5000` with:
- **File monitoring** running in the background
- **Behavior analysis** processing events in real-time
- **Flask API** serving data to the Flutter frontend

### 3. Test the API

```bash
# System status
curl http://localhost:5000/api/status

# All alerts
curl http://localhost:5000/api/alerts

# Monitoring events
curl http://localhost:5000/api/monitoring

# Trigger simulation
curl -X POST http://localhost:5000/api/simulate

# Execute action on alert
curl -X POST http://localhost:5000/api/alerts/ALT-XXXXX/action \
  -H "Content-Type: application/json" \
  -d '{"action": "quarantine"}'
```

### 4. Run Tests

```bash
cd backend
python -m pytest tests/ -v
```

---

## API Documentation

### `GET /api/status`

Returns the current system monitoring status.

**Response:**
```json
{
  "is_secure": true,
  "threats_detected": 3,
  "files_monitored": 1247,
  "suspicious_activities": 7,
  "is_monitoring_active": true,
  "threat_activity_data": [1, 0, 2, 1, 0, 3, 1, 0, 1, 2, 0, 1]
}
```

### `GET /api/alerts`

Returns all threat alerts, newest first.

**Response:**
```json
[
  {
    "id": "ALT-A1B2C3",
    "title": "Ransomware Encryption Detected",
    "description": "Files are being renamed with known ransomware extensions.",
    "severity": "critical",
    "timestamp": "2026-06-02T03:45:00",
    "detection_reason": "File renamed to suspicious extension '.locked'",
    "affected_files": ["/home/user/Documents/report.docx"],
    "suggested_action": "Immediately isolate the affected directory..."
  }
]
```

### `GET /api/monitoring`

Returns recent file monitoring events.

**Response:**
```json
[
  {
    "id": "MON-D4E5F6",
    "action": "File Modified",
    "file_path": "/home/user/Documents/report.docx",
    "status": "normal",
    "timestamp": "2026-06-02T03:45:00"
  }
]
```

### `POST /api/simulate`

Triggers a safe ransomware simulation for testing.

**Response:**
```json
{
  "message": "Simulation completed successfully",
  "files_created": 50,
  "files_modified": 50,
  "files_renamed": 20,
  "alert_triggered": true
}
```

### `POST /api/alerts/<id>/action`

Execute an action on a specific alert.

**Request Body:**
```json
{
  "action": "quarantine"  // "ignore", "quarantine", or "stop_process"
}
```

---

## Detection Rules

| Rule | Trigger | Severity |
|------|---------|----------|
| Mass Modification | > 30 files modified in 60s | WARNING |
| Ransomware Extension | Files renamed to `.locked`, `.encrypted`, etc. | CRITICAL |
| Bulk Rename | > 10 files renamed in 60s | WARNING |
| Extension Flood | > 5 suspicious extension changes | CRITICAL |

---

## Configuration

Edit `config.py` to customize:

| Setting | Default | Description |
|---------|---------|-------------|
| `MONITORED_DIRECTORIES` | ~/Documents, ~/Downloads | Directories to watch |
| `MAX_FILE_MODIFICATIONS` | 30 | Threshold for rapid modification alert |
| `TIME_WINDOW_SECONDS` | 60 | Sliding window duration |
| `SUSPICIOUS_EXTENSIONS` | .locked, .encrypted, .crypt, ... | Known ransomware extensions |
| `API_PORT` | 5000 | Flask server port |

---

## Project Structure

```
backend/
├── app.py                     # Entry point — starts API + monitoring
├── config.py                  # Configuration constants
├── requirements.txt           # Python dependencies
├── monitoring/
│   ├── file_monitor.py        # Watchdog-based file watcher
│   ├── behavior_analyzer.py   # Pattern analysis engine
│   ├── detection_engine.py    # Rule-based threat classification
│   └── response_handler.py    # Alert generation + actions
├── api/
│   ├── routes.py              # Flask endpoints
│   └── controllers.py         # Business logic
├── storage/
│   └── database.py            # SQLite + JSON storage
├── simulation/
│   └── simulator.py           # Safe ransomware simulator
├── utils/
│   ├── logger.py              # Logging configuration
│   ├── helpers.py             # Utility functions
│   └── constants.py           # Enums and constants
└── tests/
    ├── test_detection.py      # Detection engine tests
    ├── test_api.py            # API endpoint tests
    └── test_simulator.py      # Simulator tests
```

---

## Flutter Integration

The Flutter frontend's `ApiService` is pre-configured to connect to this backend:

```dart
// In lib/services/api_service.dart
static const String _baseUrl = 'http://10.0.2.2:5000/api';
```

- **Android Emulator**: Use `10.0.2.2` (maps to host machine's localhost)
- **Physical Device**: Use your machine's local IP address
- **iOS Simulator**: Use `localhost`

---

## License

Academic use only — Final Year Project.
