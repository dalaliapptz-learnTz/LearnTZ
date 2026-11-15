import 'dart:math';

/// Child Draft Model for LearnTZ Parent Onboarding
class ChildDraft {
  const ChildDraft({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.dateOfBirth,
    this.gender = 'prefer_not_to_say',
    required this.countryCode,
    required this.educationSystemId,
    required this.systemName,
    required this.curriculumId,
    required this.curriculumName,
    required this.educationLevelId,
    required this.levelName,
    required this.gradeId,
    required this.gradeName,
    this.schoolId,
    this.schoolName,
    this.schoolLocation,
    this.avatarPreset = 'owl_scholar',
  });

  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final DateTime dateOfBirth;
  final String? gender;
  final String countryCode;
  final String educationSystemId;
  final String systemName;
  final String curriculumId;
  final String curriculumName;
  final String educationLevelId;
  final String levelName;
  final String gradeId;
  final String gradeName;
  final String? schoolId;
  final String? schoolName;
  final String? schoolLocation;
  final String avatarPreset;

  String get fullName {
    if (middleName != null && middleName!.trim().isNotEmpty) {
      return '$firstName $middleName $lastName';
    }
    return '$firstName $lastName';
  }

  int get ageYears {
    final now = DateTime.now();
    int age = now.year - dateOfBirth.year;
    if (now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day)) {
      age--;
    }
    return age;
  }

  static String generateId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }

  ChildDraft copyWith({
    String? id,
    String? firstName,
    String? middleName,
    String? lastName,
    DateTime? dateOfBirth,
    String? gender,
    String? countryCode,
    String? educationSystemId,
    String? systemName,
    String? curriculumId,
    String? curriculumName,
    String? educationLevelId,
    String? levelName,
    String? gradeId,
    String? gradeName,
    String? schoolId,
    String? schoolName,
    String? schoolLocation,
    String? avatarPreset,
  }) {
    return ChildDraft(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      middleName: middleName ?? this.middleName,
      lastName: lastName ?? this.lastName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      countryCode: countryCode ?? this.countryCode,
      educationSystemId: educationSystemId ?? this.educationSystemId,
      systemName: systemName ?? this.systemName,
      curriculumId: curriculumId ?? this.curriculumId,
      curriculumName: curriculumName ?? this.curriculumName,
      educationLevelId: educationLevelId ?? this.educationLevelId,
      levelName: levelName ?? this.levelName,
      gradeId: gradeId ?? this.gradeId,
      gradeName: gradeName ?? this.gradeName,
      schoolId: schoolId ?? this.schoolId,
      schoolName: schoolName ?? this.schoolName,
      schoolLocation: schoolLocation ?? this.schoolLocation,
      avatarPreset: avatarPreset ?? this.avatarPreset,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'first_name': firstName,
      'middle_name': middleName,
      'last_name': lastName,
      'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
      'gender': gender,
      'country_code': countryCode,
      'education_system_id': educationSystemId,
      'system_name': systemName,
      'curriculum_id': curriculumId,
      'curriculum_name': curriculumName,
      'education_level_id': educationLevelId,
      'level_name': levelName,
      'grade_id': gradeId,
      'grade_name': gradeName,
      'school_id': schoolId,
      'school_name': schoolName,
      'school_location': schoolLocation,
      'avatar_preset': avatarPreset,
    };
  }

  factory ChildDraft.fromJson(Map<String, dynamic> json) {
    return ChildDraft(
      id: json['id'] as String? ?? generateId(),
      firstName: json['first_name'] as String,
      middleName: json['middle_name'] as String?,
      lastName: json['last_name'] as String,
      dateOfBirth: DateTime.parse(json['date_of_birth'] as String),
      gender: json['gender'] as String? ?? 'prefer_not_to_say',
      countryCode: json['country_code'] as String,
      educationSystemId: json['education_system_id'] as String,
      systemName: json['system_name'] as String? ?? '',
      curriculumId: json['curriculum_id'] as String,
      curriculumName: json['curriculum_name'] as String? ?? '',
      educationLevelId: json['education_level_id'] as String,
      levelName: json['level_name'] as String? ?? '',
      gradeId: json['grade_id'] as String,
      gradeName: json['grade_name'] as String? ?? '',
      schoolId: json['school_id'] as String?,
      schoolName: json['school_name'] as String?,
      schoolLocation: json['school_location'] as String?,
      avatarPreset: json['avatar_preset'] as String? ?? 'owl_scholar',
    );
  }
}
