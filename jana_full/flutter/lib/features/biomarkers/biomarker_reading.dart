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
    return BiomarkerReading(
      // id is always present — safe to cast
      id:         (j['id'] as String?) ?? '',

      // type may not be in the history response (the endpoint doesn't
      // return it), so we fall back to empty string rather than crashing
      type:       (j['type'] as String?) ?? '',

      // value comes as num (int or double) — always convert via toDouble()
      value:      (j['value'] as num).toDouble(),

      // source is nullable in some rows — default to 'manual'
      source: (j['source'] as String?) ?? 'unknown',

      // recorded_at is nullable — stored as String? and handled in _safeDate()
      recordedAt: j['recorded_at'] as String?,
    );
  }
}
