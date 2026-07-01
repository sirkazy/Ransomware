# Ransomware Guardian — System Testing Guide

This guide describes how to run and test the complete Behavior-Based Ransomware Detection and Prevention Framework end-to-end.

---

## 📋 Prerequisites

Ensure you have the following installed:

* **Python 3.11+** (for the backend)
* **Flutter** (for the mobile application)
* **curl** or a web browser (for triggering the simulation)

---

## 🚀 Step 1: Start the Backend Service

1. Open a terminal and navigate to the `backend/` directory:

```bash
cd backend
```

2. Activate your virtual environment (if applicable) and install dependencies:

```bash
pip install -r requirements.txt
```

3. Start the Flask server:

```bash
python app.py
```

### Verification

You should see terminal logs indicating the background file monitor and sliding-window analyzer have started successfully:

```text
[INFO] File monitor started on: ~/Documents, ~/Downloads...
[INFO] API server running on http://0.0.0.0:5000
```

---

## 📱 Step 2: Start the Flutter Frontend

1. Open a new terminal and navigate to the `frontend/` directory:

```bash
cd frontend
```

2. Fetch Flutter package dependencies:

```bash
flutter pub get
```

3. Launch your target emulator/device (Android/iOS/Web) and run the app:

```bash
flutter run
```

### Note

By default, the app is pre-configured to connect to:

* `http://10.0.2.2:5000` (Android Emulators)
* `http://localhost:5000` (iOS Simulators)

To connect a physical device, update `_baseUrl` in:

```text
lib/services/api_service.dart
```

with your machine's local IP address.

---

## ⚡ Step 3: Trigger the Ransomware Simulation

With both backend and frontend running:

1. Open a new terminal window.
2. Trigger a safe, simulated ransomware attack inside the isolated test environment:

Rapid modification (WARNING)
```bash
curl -X POST http://localhost:5000/api/simulate -H "Content-Type: application/json" -d '{"type": "rapid_modification"}'
```
Bulk rename (WARNING)
```bash
curl -X POST http://localhost:5000/api/simulate -H "Content-Type: application/json" -d '{"type": "bulk_rename"}'
```
Mass extension change (CRITICAL)
```bash
curl -X POST http://localhost:5000/api/simulate -H "Content-Type: application/json" -d '{"type": "mass_extension"}'
```
Full attack (ALL RULES)
```bash
curl -X POST http://localhost:5000/api/simulate -H "Content-Type: application/json" -d '{"type": "all"}'curl -X POST http://localhost:5000/api/simulate
```

---

## 🔍 Step 4: Verify Detection & UI Enhancements

Observe the real-time interaction between the backend and the mobile application.

### 1. Verification of Layout & Auto-Refresh

#### Statistic Grid

The four statistic cards on the Dashboard screen should display their values cleanly without any yellow/black striped layout overflow warnings.

#### Real-Time Data

Watch the dashboard. Without manually refreshing, the statistics should automatically update every five seconds as the application polls the backend.

---

### 2. Verification of Alert Counts

1. Open the **Alerts** tab using the bottom navigation bar.
2. Review the filter chips at the top of the screen.

You should see dynamic counts displayed next to each category:

* All (X)
* Critical (X)
* Warning (X)
* Safe (X)

Swipe horizontally across the chips to verify that scrolling works smoothly without clipping or layout issues.

---

### 3. Verification of Critical Alert Badge

1. Trigger the simulator using the command shown in Step 3.
2. When a **CRITICAL** alert is generated on the backend (for example, files being renamed with the `.locked` extension inside the test directory):

* A notification badge should immediately appear on the **Alerts** navigation tab.
* The badge should display the current number of critical alerts detected.

---

### 4. Safe Directory Inspection

Inspect the isolated simulation directory:

```text
backend/test_files/
```

You should observe dummy files being:

* Created
* Modified
* Renamed to `.locked`
* Automatically cleaned up

This demonstrates ransomware-like behavior in a safe, academic testing environment without affecting real user files.

---

## ✅ Expected Outcome

If the system is functioning correctly:

* Backend monitoring services start successfully.
* Frontend connects to the backend API.
* Dashboard statistics update automatically.
* Alert counts update in real time.
* Critical alert badges appear when threats are detected.
* The ransomware simulator executes safely within the isolated test environment.
* Test artifacts are cleaned up automatically after execution.
