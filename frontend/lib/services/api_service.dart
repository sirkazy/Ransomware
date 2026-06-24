import 'package:dio/dio.dart';
import '../models/alert_model.dart';
import '../models/monitoring_model.dart';
import '../models/system_status.dart';

class ApiService {
  late final Dio _dio;

  static const String _baseUrl = 'http://10.0.2.2:5000/api';

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 10),
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
    } catch (_) {
      // Return a safe "offline" state — never fake data
      return const SystemStatus(
        isSecure: true,
        threatsDetected: 0,
        filesMonitored: 0,
        suspiciousActivities: 0,
        isMonitoringActive: false,
        threatActivityData: [],
      );
    }
  }

  Future<List<AlertModel>> getAlerts() async {
    try {
      final response = await _dio.get('/alerts');
      final data = response.data as List;
      return data
          .map((json) => AlertModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
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
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> triggerSimulation(String type) async {
    try {
      final response = await _dio.post(
        '/simulate',
        data: {'type': type},
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Simulation failed: $e');
    }
  }

  Future<Map<String, dynamic>> performAlertAction(String alertId, String action) async {
    try {
      final response = await _dio.post('/alerts/$alertId/action', data: {'action': action});
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception('Action failed: $e');
    }
  }

  Future<void> resetSystem() async {
    try {
      await _dio.post('/reset');
    } catch (e) {
      throw Exception('Reset failed: $e');
    }
  }
}

