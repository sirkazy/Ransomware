import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import '../models/monitoring_model.dart';
import '../models/local_monitored_file.dart';
import '../models/alert_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'alerts_provider.dart';

class MonitoringProvider extends ChangeNotifier {
  final ApiService _apiService;
  final NotificationService _notificationService;

  List<MonitoringActivity> _activities = [];
  List<LocalMonitoredFile> _localFiles = [];
  bool _isLoading = false;
  String? _error;
  Timer? _simulationTimer;
  Timer? _localMonitorTimer;
  int _simulationIndex = 0;

  MonitoringProvider(this._apiService, this._notificationService);

  List<MonitoringActivity> get activities => _activities;
  List<LocalMonitoredFile> get localFiles => _localFiles;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get normalCount =>
      _activities.where((a) => a.status == 'normal').length;
  int get suspiciousCount =>
      _activities.where((a) => a.status == 'suspicious').length;
  int get blockedCount =>
      _activities.where((a) => a.status == 'blocked').length;

  Timer? _refreshTimer;

  Future<void> fetchActivities({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final backendActivities = await _apiService.getMonitoring();
      // Keep local activities at the top
      final localActivities = _activities.where((a) => a.id.startsWith('LOCAL-')).toList();
      _activities = [...localActivities, ...backendActivities];
    } catch (e) {
      _error = 'Failed to fetch monitoring data';
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  void startAutoRefresh({Duration interval = const Duration(seconds: 5)}) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) => fetchActivities(showLoading: false));
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  // ── Local File Monitoring ─────────────────────────────────────────

  void startLocalMonitoring({Duration interval = const Duration(seconds: 4)}) {
    _localMonitorTimer?.cancel();
    _localMonitorTimer = Timer.periodic(interval, (_) => _scanLocalFiles());
  }

  void stopLocalMonitoring() {
    _localMonitorTimer?.cancel();
    _localMonitorTimer = null;
  }

  Future<void> pickAndAddLocalFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        for (final pickedFile in result.files) {
          final path = pickedFile.path;
          if (path == null) continue;

          // Check if already monitored
          if (_localFiles.any((f) => f.path == path)) continue;

          final ioFile = File(path);
          if (await ioFile.exists()) {
            final stat = await ioFile.stat();
            final name = pickedFile.name;
            
            _localFiles.add(
              LocalMonitoredFile(
                path: path,
                name: name,
                size: stat.size,
                lastModified: stat.modified,
                status: 'secure',
              ),
            );

            // Log activity
            _activities.insert(
              0,
              MonitoringActivity(
                id: 'LOCAL-ADD-${DateTime.now().millisecondsSinceEpoch}',
                action: 'File Scanned',
                filePath: path,
                status: 'normal',
                timestamp: DateTime.now(),
              ),
            );
          }
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error picking files: $e');
    }
  }

  void removeLocalFile(String path) {
    _localFiles.removeWhere((f) => f.path == path);
    // Remove activities associated with this file
    _activities.removeWhere((a) => a.filePath == path);
    notifyListeners();
  }

  Future<void> _scanLocalFiles() async {
    bool hasChanges = false;
    for (int i = 0; i < _localFiles.length; i++) {
      final file = _localFiles[i];
      if (file.status == 'encrypted' || file.status == 'deleted') {
        continue;
      }

      final ioFile = File(file.path);
      if (!await ioFile.exists()) {
        _localFiles[i] = file.copyWith(status: 'deleted');
        hasChanges = true;

        // Log deleted activity
        _activities.insert(
          0,
          MonitoringActivity(
            id: 'LOCAL-DEL-${DateTime.now().millisecondsSinceEpoch}',
            action: 'File Deleted',
            filePath: file.path,
            status: 'suspicious',
            timestamp: DateTime.now(),
          ),
        );
      } else {
        try {
          final stat = await ioFile.stat();
          final size = stat.size;
          final lastMod = stat.modified;

          if (size != file.size || lastMod.isAfter(file.lastModified)) {
            _localFiles[i] = file.copyWith(
              size: size,
              lastModified: lastMod,
              status: 'modified',
            );
            hasChanges = true;

            // Log modified activity
            _activities.insert(
              0,
              MonitoringActivity(
                id: 'LOCAL-MOD-${DateTime.now().millisecondsSinceEpoch}',
                action: 'File Modified',
                filePath: file.path,
                status: 'normal',
                timestamp: DateTime.now(),
              ),
            );
          }
        } catch (_) {}
      }
    }

    if (hasChanges) {
      notifyListeners();
    }
  }

  void simulateAttackOnFile(String path, AlertsProvider alertsProvider) {
    final index = _localFiles.indexWhere((f) => f.path == path);
    if (index != -1) {
      final file = _localFiles[index];

      // Delay execution by 3 seconds to allow user to minimize the app
      Future.delayed(const Duration(seconds: 3), () {
        final latestIndex = _localFiles.indexWhere((f) => f.path == path);
        if (latestIndex != -1) {
          _localFiles[latestIndex] = file.copyWith(status: 'encrypted');

          // Log activity
          _activities.insert(
            0,
            MonitoringActivity(
              id: 'LOCAL-ENC-${DateTime.now().millisecondsSinceEpoch}',
              action: 'Encryption Detected',
              filePath: file.path,
              status: 'blocked',
              timestamp: DateTime.now(),
            ),
          );

          // Trigger critical alert
          final alertId = 'LOCAL-ALERT-${DateTime.now().millisecondsSinceEpoch}';
          alertsProvider.addLocalAlert(
            AlertModel(
              id: alertId,
              title: 'Device Ransomware Threat',
              description: 'A ransomware simulation was triggered targeting local file "${file.name}". Unauthorized modification of user data was intercepted.',
              severity: 'critical',
              timestamp: DateTime.now(),
              detectionReason: 'High entropy write request to file structure: ${file.path}',
              affectedFiles: [file.path],
              suggestedAction: 'Isolate device network connection and quarantine affected paths.',
            ),
          );

          // Trigger system notification
          _notificationService.showThreatNotification(
            title: 'Ransomware Guardian: Threat Detected',
            body: 'Local file "${file.name}" is potentially targeted by ransomware (simulated).',
          );

          notifyListeners();
        }
      });
    }
  }

  void resetLocalMonitoring() {
    // Restore all files to 'secure' status and update baseline to current disk values
    for (int i = 0; i < _localFiles.length; i++) {
      final file = _localFiles[i];
      final ioFile = File(file.path);
      if (ioFile.existsSync()) {
        final stat = ioFile.statSync();
        _localFiles[i] = file.copyWith(
          status: 'secure',
          size: stat.size,
          lastModified: stat.modified,
        );
      } else {
        _localFiles[i] = file.copyWith(status: 'secure');
      }
    }
    // Remove local simulation activities from the feed
    _activities.removeWhere((a) => a.id.startsWith('LOCAL-'));
    notifyListeners();
  }

  void restoreFileStatus(String path) {
    final index = _localFiles.indexWhere((f) => f.path == path);
    if (index != -1) {
      final file = _localFiles[index];
      final ioFile = File(file.path);
      if (ioFile.existsSync()) {
        final stat = ioFile.statSync();
        _localFiles[index] = file.copyWith(
          status: 'secure',
          size: stat.size,
          lastModified: stat.modified,
        );
      } else {
        _localFiles[index] = file.copyWith(status: 'secure');
      }

      // Log resolve activity
      _activities.insert(
        0,
        MonitoringActivity(
          id: 'LOCAL-RSLV-${DateTime.now().millisecondsSinceEpoch}',
          action: 'Protection Restored',
          filePath: file.path,
          status: 'normal',
          timestamp: DateTime.now(),
        ),
      );
      notifyListeners();
    }
  }

  // ── Simulator ─────────────────────────────────────────────────────

  void startSimulation() {
    _simulationTimer?.cancel();
    final extraActivities = [
      MonitoringActivity(
        id: 'SIM-001',
        action: 'File Scanned',
        filePath: '/home/user/Documents/invoice_q4.pdf',
        status: 'normal',
        timestamp: DateTime.now(),
      ),
      MonitoringActivity(
        id: 'SIM-002',
        action: 'Hash Verified',
        filePath: '/usr/bin/python3',
        status: 'normal',
        timestamp: DateTime.now(),
      ),
      MonitoringActivity(
        id: 'SIM-003',
        action: 'Outbound Connection',
        filePath: '203.0.113.42:8080 (TCP)',
        status: 'suspicious',
        timestamp: DateTime.now(),
      ),
    ];

    _simulationTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      if (_simulationIndex < extraActivities.length) {
        _activities.insert(0, extraActivities[_simulationIndex]);
        _simulationIndex++;
        notifyListeners();
      }
    });
  }

  void stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _refreshTimer?.cancel();
    _localMonitorTimer?.cancel();
    super.dispose();
  }
}
