class MonitoringActivity {
  final String id;
  final String action;
  final String filePath;
  final String status;
  final DateTime timestamp;

  const MonitoringActivity({
    required this.id,
    required this.action,
    required this.filePath,
    required this.status,
    required this.timestamp,
  });

  factory MonitoringActivity.fromJson(Map<String, dynamic> json) {
    return MonitoringActivity(
      id: json['id'] as String,
      action: json['action'] as String,
      filePath: json['file_path'] as String,
      status: json['status'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'action': action,
      'file_path': filePath,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
