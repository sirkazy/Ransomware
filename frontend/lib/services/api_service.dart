import 'package:dio/dio.dart';
import '../models/alert_model.dart';
import '../models/monitoring_model.dart';
import '../models/system_status.dart';
import '../constants/mock_data.dart';

class ApiService {
  late final Dio _dio;

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

  Future<SystemStatus> getStatus() async {
    try {
      final response = await _dio.get('/status');
      return SystemStatus.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      return MockData.systemStatus;
    }
  }

  Future<List<AlertModel>> getAlerts() async {
    try {
      final response = await _dio.get('/alerts');
      final data = response.data as List;
      return data
          .map((json) => AlertModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return MockData.alerts;
    }
  }

  Future<List<MonitoringActivity>> getMonitoring() async {
    try {
      final response = await _dio.get('/monitoring');
      final data = response.data as List;
      return data
          .map((json) =>
              MonitoringActivity.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return MockData.monitoringActivities;
    }
  }
}
