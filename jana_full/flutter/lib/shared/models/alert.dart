class Alert {
  final String id;
  final String biomarkerType;
  final String severity;
  final String message;
  final String createdAt;
  final bool notified;

  const Alert({
    required this.id,
    required this.biomarkerType,
    required this.severity,
    required this.message,
    required this.createdAt,
    required this.notified,
  });

  factory Alert.fromJson(Map<String, dynamic> j) {
    return Alert(
      id:             j['id'] as String,
      biomarkerType:  j['biomarker_type'] as String,
      severity:       j['severity'] as String,
      message:        j['message'] as String,
      createdAt:      j['created_at'] as String,
      notified:       j['notified_at'] != null,
    );
  }

  bool get isCritical => severity == 'critical';
}
