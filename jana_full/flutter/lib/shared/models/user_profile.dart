class UserProfile {
  final String id;
  final String fullName;
  final String? dateOfBirth;
  final String? gender;
  final String? doctorEmail;
  final double? heightCm;
  final double? weightKg;
  final String? avatarUrl;

  const UserProfile({
    required this.id,
    required this.fullName,
    this.dateOfBirth,
    this.gender,
    this.doctorEmail,
    this.heightCm,
    this.weightKg,
    this.avatarUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> j) {
    return UserProfile(
      id:          j['id'] as String,
      fullName:    j['full_name'] as String,
      dateOfBirth: j['date_of_birth'] as String?,
      gender:      j['gender'] as String?,
      doctorEmail: j['doctor_email'] as String?,
      heightCm:    (j['height_cm'] as num?)?.toDouble(),
      weightKg:    (j['weight_kg'] as num?)?.toDouble(),
      avatarUrl:   j['avatar_url'] as String?,
    );
  }

  String get heightDisplay =>
      heightCm != null ? '${heightCm!.toStringAsFixed(0)} cm' : '--';
  String get weightDisplay =>
      weightKg != null ? '${weightKg!.toStringAsFixed(1)} kg' : '--';

  String get bmiDisplay {
    if (heightCm == null || weightKg == null) return '--';
    final h = heightCm! / 100;
    return (weightKg! / (h * h)).toStringAsFixed(1);
  }

  String get bmiLabel {
    if (heightCm == null || weightKg == null) return '';
    final h = heightCm! / 100;
    final bmi = weightKg! / (h * h);
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25.0) return 'Normal';
    if (bmi < 30.0) return 'Overweight';
    return 'Obese';
  }
}
