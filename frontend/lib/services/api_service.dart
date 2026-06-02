import 'package:dio/dio.dart';
import '../models/alert_model.dart';
import '../models/monitoring_model.dart';
import '../models/system_status.dart';
import '../constants/mock_data.dart';

class ApiService {
  late final Dio _dio;

  // Change this to your Flask backend URL when ready.
  // For Android emulator use: http://10.0.2.2:5000/api
  // For physical device use your machine's local IP.
  static const String _baseUrl = 'http://10.0.2.2:5000/api';

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 5),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  // ── GET /status ───────────────────────────────────────────────────
  Future<SystemStatus> getStatus() async {
    try {
      final response = await _dio.get('/status');
      return SystemStatus.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      // Fallback to mock data when backend is unavailable
      return MockData.systemStatus;
    }
  }

  // ── GET /alerts ───────────────────────────────────────────────────
  Future<List<AlertModel>> getAlerts() async {
    try {
      final response = await _dio.get('/alerts');
      final data = response.data as List;
      return data
          .map((json) => AlertModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to mock data when backend is unavailable
      return MockData.alerts;
    }
  }

  // ── GET /monitoring ───────────────────────────────────────────────
  Future<List<MonitoringActivity>> getMonitoring() async {
    try {
      final response = await _dio.get('/monitoring');
      final data = response.data as List;
      return data
          .map((json) =>
              MonitoringActivity.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Fallback to mock data when backend is unavailable
      return MockData.monitoringActivities;
    }
  }
}
