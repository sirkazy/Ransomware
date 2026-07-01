class LocalMonitoredFile {
  final String path;
  final String name;
  final int size;
  final DateTime lastModified;
  final String status; // 'secure', 'modified', 'deleted', 'encrypted'

  const LocalMonitoredFile({
    required this.path,
    required this.name,
    required this.size,
    required this.lastModified,
    required this.status,
  });

  LocalMonitoredFile copyWith({
    String? path,
    String? name,
    int? size,
    DateTime? lastModified,
    String? status,
  }) {
    return LocalMonitoredFile(
      path: path ?? this.path,
      name: name ?? this.name,
      size: size ?? this.size,
      lastModified: lastModified ?? this.lastModified,
      status: status ?? this.status,
    );
  }

  factory LocalMonitoredFile.fromJson(Map<String, dynamic> json) {
    return LocalMonitoredFile(
      path: json['path'] as String,
      name: json['name'] as String,
      size: json['size'] as int,
      lastModified: DateTime.parse(json['last_modified'] as String),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'path': path,
      'name': name,
      'size': size,
      'last_modified': lastModified.toIso8601String(),
      'status': status,
    };
  }
}
