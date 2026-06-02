class SystemStatus {
  final bool isSecure;
  final int threatsDetected;
  final int filesMonitored;
  final int suspiciousActivities;
  final bool isMonitoringActive;
  final List<double> threatActivityData;

  const SystemStatus({
    required this.isSecure,
    required this.threatsDetected,
    required this.filesMonitored,
    required this.suspiciousActivities,
    required this.isMonitoringActive,
    required this.threatActivityData,
  });

  factory SystemStatus.fromJson(Map<String, dynamic> json) {
    return SystemStatus(
      isSecure: json['is_secure'] as bool,
      threatsDetected: json['threats_detected'] as int,
      filesMonitored: json['files_monitored'] as int,
      suspiciousActivities: json['suspicious_activities'] as int,
      isMonitoringActive: json['is_monitoring_active'] as bool,
      threatActivityData: List<double>.from(
        (json['threat_activity_data'] as List).map((e) => (e as num).toDouble()),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_secure': isSecure,
      'threats_detected': threatsDetected,
      'files_monitored': filesMonitored,
      'suspicious_activities': suspiciousActivities,
      'is_monitoring_active': isMonitoringActive,
      'threat_activity_data': threatActivityData,
    };
  }
}
