class BiomarkerReading {
  final String id;
  final String type;
  final double value;
  final String source;
  final String recordedAt;

  const BiomarkerReading({
    required this.id,
    required this.type,
    required this.value,
    required this.source,
    required this.recordedAt,
  });

  factory BiomarkerReading.fromJson(Map<String, dynamic> j) {
    return BiomarkerReading(
      id:         j['id'] as String,
      type:       j['type'] as String,
      value:      (j['value'] as num).toDouble(),
      source:     j['source'] as String,
      recordedAt: j['recorded_at'] as String,
    );
  }
}
