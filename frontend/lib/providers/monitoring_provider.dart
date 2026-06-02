import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/monitoring_model.dart';
import '../services/api_service.dart';

class MonitoringProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<MonitoringActivity> _activities = [];
  bool _isLoading = false;
  String? _error;
  Timer? _simulationTimer;
  int _simulationIndex = 0;

  MonitoringProvider(this._apiService);

  // ── Getters ───────────────────────────────────────────────────────
  List<MonitoringActivity> get activities => _activities;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get normalCount =>
      _activities.where((a) => a.status == 'normal').length;
  int get suspiciousCount =>
      _activities.where((a) => a.status == 'suspicious').length;
  int get blockedCount =>
      _activities.where((a) => a.status == 'blocked').length;

  Timer? _refreshTimer;

  // ── Fetch Activities ──────────────────────────────────────────────
  Future<void> fetchActivities({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _activities = await _apiService.getMonitoring();
    } catch (e) {
      _error = 'Failed to fetch monitoring data';
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  // ── Auto Refresh ──────────────────────────────────────────────────
  void startAutoRefresh({Duration interval = const Duration(seconds: 5)}) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) => fetchActivities(showLoading: false));
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  // ── Simulate live activity (for demo) ─────────────────────────────
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
    super.dispose();
  }
}
