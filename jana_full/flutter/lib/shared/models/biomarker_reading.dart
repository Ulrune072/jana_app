class BiomarkerReading {
  final String id;
  final String type;
  final double value;
  final String source;      // nullable in DB, we default to 'manual'
  final String? recordedAt; // nullable in DB, handled safely everywhere

  const BiomarkerReading({
    required this.id,
    required this.type,
    required this.value,
    required this.source,
    this.recordedAt,
  });

  factory BiomarkerReading.fromJson(Map<String, dynamic> j) {
    final id = j['id'];
    final value = j['value'];

    if (id == null) throw Exception('BiomarkerReading JSON missing id: $j');
    if (value == null) throw Exception('BiomarkerReading JSON missing value: $j');

    return BiomarkerReading(
      id: id as String,
      type: (j['type'] as String?) ?? '',
      value: (value as num).toDouble(),
      source: (j['source'] as String?) ?? 'unknown',
      recordedAt: j['recorded_at'] as String?,
    );
  }
}
