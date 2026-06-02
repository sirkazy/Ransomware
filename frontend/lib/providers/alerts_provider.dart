import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/alert_model.dart';
import '../services/api_service.dart';

class AlertsProvider extends ChangeNotifier {
  final ApiService _apiService;

  List<AlertModel> _alerts = [];
  bool _isLoading = false;
  String? _error;
  String _selectedFilter = 'all';

  AlertsProvider(this._apiService);

  // ── Getters ───────────────────────────────────────────────────────
  List<AlertModel> get alerts => _filteredAlerts;
  List<AlertModel> get allAlerts => _alerts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get selectedFilter => _selectedFilter;

  int get criticalCount =>
      _alerts.where((a) => a.severity == 'critical').length;
  int get warningCount =>
      _alerts.where((a) => a.severity == 'warning').length;
  int get safeCount =>
      _alerts.where((a) => a.severity == 'safe').length;

  List<AlertModel> get _filteredAlerts {
    if (_selectedFilter == 'all') return _alerts;
    return _alerts.where((a) => a.severity == _selectedFilter).toList();
  }

  Timer? _refreshTimer;

  // ── Fetch Alerts ──────────────────────────────────────────────────
  Future<void> fetchAlerts({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final newAlerts = await _apiService.getAlerts();
      // Sort by timestamp, newest first
      newAlerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      _alerts = newAlerts;
    } catch (e) {
      _error = 'Failed to fetch alerts';
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
    _refreshTimer = Timer.periodic(interval, (_) => fetchAlerts(showLoading: false));
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  // ── Filter ────────────────────────────────────────────────────────
  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  // ── Find alert by ID ─────────────────────────────────────────────
  AlertModel? getAlertById(String id) {
    try {
      return _alerts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
