import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/system_status.dart';
import '../services/api_service.dart';

class DashboardProvider extends ChangeNotifier {
  final ApiService _apiService;

  SystemStatus? _status;
  bool _isLoading = false;
  String? _error;
  Timer? _refreshTimer;

  DashboardProvider(this._apiService);

  // ── Getters ───────────────────────────────────────────────────────
  SystemStatus? get status => _status;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get isSecure => _status?.isSecure ?? true;
  int get threatsDetected => _status?.threatsDetected ?? 0;
  int get filesMonitored => _status?.filesMonitored ?? 0;
  int get suspiciousActivities => _status?.suspiciousActivities ?? 0;
  bool get isMonitoringActive => _status?.isMonitoringActive ?? false;
  List<double> get threatActivityData => _status?.threatActivityData ?? [];

  // ── Fetch Status ──────────────────────────────────────────────────
  Future<void> fetchStatus({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      _status = await _apiService.getStatus();
    } catch (e) {
      _error = 'Failed to fetch system status';
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  // ── Auto Refresh (simulates real-time feel) ───────────────────────
  void startAutoRefresh({Duration interval = const Duration(seconds: 5)}) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) => fetchStatus(showLoading: false));
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
