import 'package:supabase_flutter/supabase_flutter.dart';

import 'exam_v2_models.dart';

class ExamCentreV2Repository {
  ExamCentreV2Repository([SupabaseClient? client]) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _db => _client ?? Supabase.instance.client;

  Future<List<ExamV2CountryOption>> getCountries() async {
    final res = await _db.rpc('get_exam_v2_countries');
    return (res as List<dynamic>? ?? const [])
        .map((e) => ExamV2CountryOption.fromJson(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  Future<List<ExamV2EducationLevelOption>> getEducationLevels(
    String countryCode,
  ) async {
    final res = await _db.rpc(
      'get_exam_v2_education_levels',
      params: {'p_country_code': countryCode},
    );
    return (res as List<dynamic>? ?? const [])
        .map((e) => ExamV2EducationLevelOption.fromJson(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  Future<List<ExamV2GradeOption>> getGrades({
    required String curriculumId,
    required String educationLevelId,
  }) async {
    final res = await _db.rpc(
      'get_exam_v2_grades',
      params: {
        'p_curriculum_id': curriculumId,
        'p_education_level_id': educationLevelId,
      },
    );
    return (res as List<dynamic>? ?? const [])
        .map((e) => ExamV2GradeOption.fromJson(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  Future<List<ExamV2SubjectOption>> getSubjects({
    required String curriculumId,
    required String educationLevelId,
    required String gradeId,
  }) async {
    final res = await _db.rpc(
      'get_exam_v2_subjects',
      params: {
        'p_curriculum_id': curriculumId,
        'p_education_level_id': educationLevelId,
        'p_grade_id': gradeId,
      },
    );
    return (res as List<dynamic>? ?? const [])
        .map((e) => ExamV2SubjectOption.fromJson(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  Future<List<ExamV2ExaminationTypeOption>> getExaminationTypes({
    required String countryCode,
    String? educationLevelId,
  }) async {
    final res = await _db.rpc(
      'get_exam_v2_examination_types',
      params: {
        'p_country_code': countryCode,
        'p_education_level_id': educationLevelId,
      },
    );
    return (res as List<dynamic>? ?? const [])
        .map((e) => ExamV2ExaminationTypeOption.fromJson(
              Map<String, dynamic>.from(e as Map),
            ))
        .toList();
  }

  Future<ExamV2ContextSummary> getAcademicContextSummary(
    ExamV2SelectionKey selection,
  ) async {
    final res = await _db.rpc(
      'get_exam_v2_academic_context_summary',
      params: {
        'p_country_code': selection.countryCode,
        'p_education_level_id': selection.educationLevelId,
        'p_grade_id': selection.gradeId,
        'p_subject_id': selection.subjectId,
        'p_examination_type_id': selection.examinationTypeId,
      },
    );
    return ExamV2ContextSummary.fromJson(
      Map<String, dynamic>.from(res as Map),
    );
  }
}
