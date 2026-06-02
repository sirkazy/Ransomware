class AlertModel {
  final String id;
  final String title;
  final String description;
  final String severity; // critical, warning, safe
  final DateTime timestamp;
  final String detectionReason;
  final List<String> affectedFiles;
  final String suggestedAction;

  const AlertModel({
    required this.id,
    required this.title,
    required this.description,
    required this.severity,
    required this.timestamp,
    required this.detectionReason,
    required this.affectedFiles,
    required this.suggestedAction,
  });

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      severity: json['severity'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      detectionReason: json['detection_reason'] as String,
      affectedFiles: List<String>.from(json['affected_files'] as List),
      suggestedAction: json['suggested_action'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'severity': severity,
      'timestamp': timestamp.toIso8601String(),
      'detection_reason': detectionReason,
      'affected_files': affectedFiles,
      'suggested_action': suggestedAction,
    };
  }
}
