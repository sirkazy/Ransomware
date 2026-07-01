import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/alert_model.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';

class AlertsProvider extends ChangeNotifier {
  final ApiService _apiService;
  final NotificationService _notificationService;

  List<AlertModel> _alerts = [];
  bool _isLoading = false;
  String? _error;
  String _selectedFilter = 'all';
  bool _isFirstFetch = true;

  AlertsProvider(this._apiService, this._notificationService);

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

  List<AlertModel> _localAlerts = [];
  Timer? _refreshTimer;

  List<AlertModel> get localAlerts => _localAlerts;

  void addLocalAlert(AlertModel alert) {
    _localAlerts.add(alert);
    _alerts = [..._alerts, alert];
    _alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  void clearLocalAlerts() {
    _localAlerts.clear();
    fetchAlerts(showLoading: false);
  }

  Future<void> fetchAlerts({bool showLoading = true}) async {
    if (showLoading) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      final newAlerts = await _apiService.getAlerts();
      final incomingAlerts = [...newAlerts, ..._localAlerts];
      incomingAlerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      debugPrint('AlertsProvider: fetched ${incomingAlerts.length} alerts (existing in state: ${_alerts.length})');

      // Trigger system notifications only for new alerts (skip during first fetch of app launch)
      if (!_isFirstFetch) {
        final existingIds = _alerts.map((a) => a.id).toSet();
        for (final alert in incomingAlerts) {
          if (!existingIds.contains(alert.id)) {
            debugPrint('AlertsProvider: Detected new alert: ID=${alert.id}, Title=${alert.title}, Severity=${alert.severity}');
            if (alert.severity == 'critical' || alert.severity == 'warning') {
              debugPrint('AlertsProvider: Triggering notification for alert ID=${alert.id}');
              _notificationService.showThreatNotification(
                title: 'Ransomware Guardian: ${alert.title}',
                body: alert.description,
              );
            }
          }
        }
      } else {
        _isFirstFetch = false;
        debugPrint('AlertsProvider: Skipping notifications for first fetch (app launch)');
      }

      _alerts = incomingAlerts;
    } catch (e) {
      _error = 'Failed to fetch alerts';
      debugPrint('AlertsProvider: Error fetching alerts: $e');
    } finally {
      if (showLoading) {
        _isLoading = false;
      }
      notifyListeners();
    }
  }

  void startAutoRefresh({Duration interval = const Duration(seconds: 5)}) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(interval, (_) => fetchAlerts(showLoading: false));
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  void setFilter(String filter) {
    _selectedFilter = filter;
    notifyListeners();
  }

  AlertModel? getAlertById(String id) {
    try {
      return _alerts.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  void removeLocalAlert(String alertId) {
    _localAlerts.removeWhere((a) => a.id == alertId);
    _alerts.removeWhere((a) => a.id == alertId);
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
