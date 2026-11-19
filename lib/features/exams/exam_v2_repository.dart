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

  Future<ExamV2ExaminationListResult> listExaminations(
    ExamV2SelectionKey selection, {
    String? status,
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await _db.rpc(
      'list_exam_v2_examinations',
      params: {
        'p_country_code': selection.countryCode,
        'p_education_level_id': selection.educationLevelId,
        'p_grade_id': selection.gradeId,
        'p_subject_id': selection.subjectId,
        'p_examination_type_id': selection.examinationTypeId,
        'p_status': status,
        'p_search': (search == null || search.trim().isEmpty) ? null : search.trim(),
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    return ExamV2ExaminationListResult.fromJson(
      Map<String, dynamic>.from(res as Map),
    );
  }

  Future<Map<String, dynamic>> saveExamination({
    required ExamV2SelectionKey selection,
    required String title,
    required int academicYear,
    required String academicTerm,
    String? examinationDate,
    required int durationMinutes,
    required String languageCode,
    required String instructions,
    required String deliveryMode,
    required List<ExamV2SectionDraft> sections,
    required List<ExamV2CompetencyAllocation> competencies,
    String? examinationId,
  }) async {
    final res = await _db.rpc(
      'save_exam_v2_examination',
      params: {
        'p_country_code': selection.countryCode,
        'p_education_level_id': selection.educationLevelId,
        'p_grade_id': selection.gradeId,
        'p_subject_id': selection.subjectId,
        'p_examination_type_id': selection.examinationTypeId,
        'p_title': title.trim(),
        'p_academic_year': academicYear,
        'p_academic_term': academicTerm.trim(),
        'p_examination_date': examinationDate,
        'p_duration_minutes': durationMinutes,
        'p_language_code': languageCode,
        'p_instructions': instructions.trim(),
        'p_delivery_mode': deliveryMode,
        'p_sections': sections.map((s) => s.toJson()).toList(),
        'p_competencies': competencies.map((c) => c.toJson()).toList(),
        'p_examination_id': examinationId,
      },
    );
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> transitionExaminationStatus({
    required String examinationId,
    required String action,
    String comments = '',
  }) async {
    final res = await _db.rpc(
      'transition_exam_v2_status',
      params: {
        'p_examination_id': examinationId,
        'p_action': action,
        'p_comments': comments,
      },
    );
    return Map<String, dynamic>.from(res as Map);
  }

  Future<ExamV2QuestionListResult> listQuestions(
    ExamV2SelectionKey selection, {
    String? specificCompetenceId,
    String? questionType,
    String? difficultyLevel,
    String? reviewStatus,
    String? search,
    int limit = 25,
    int offset = 0,
  }) async {
    final res = await _db.rpc(
      'list_exam_v2_questions',
      params: {
        'p_country_code': selection.countryCode,
        'p_education_level_id': selection.educationLevelId,
        'p_grade_id': selection.gradeId,
        'p_subject_id': selection.subjectId,
        'p_specific_competence_id': specificCompetenceId,
        'p_question_type': questionType,
        'p_difficulty_level': difficultyLevel,
        'p_review_status': reviewStatus,
        'p_search':
            (search == null || search.trim().isEmpty) ? null : search.trim(),
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    return ExamV2QuestionListResult.fromJson(
      Map<String, dynamic>.from(res as Map),
    );
  }

  Future<Map<String, dynamic>> saveQuestion({
    required ExamV2SelectionKey selection,
    required String specificCompetenceId,
    required String questionType,
    required String questionText,
    required Map<String, dynamic> correctAnswer,
    required List<dynamic> options,
    required Map<String, dynamic> markingRubric,
    required double marks,
    required String difficultyLevel,
    required String cognitiveTier,
    required String languageCode,
    required String explanation,
    required String sourceReference,
    required String copyrightNotice,
    String? questionId,
  }) async {
    final res = await _db.rpc(
      'save_exam_v2_question',
      params: {
        'p_country_code': selection.countryCode,
        'p_education_level_id': selection.educationLevelId,
        'p_grade_id': selection.gradeId,
        'p_subject_id': selection.subjectId,
        'p_specific_competence_id': specificCompetenceId,
        'p_question_type': questionType,
        'p_question_text': questionText.trim(),
        'p_correct_answer': correctAnswer,
        'p_options': options,
        'p_marking_rubric': markingRubric,
        'p_marks': marks,
        'p_difficulty_level': difficultyLevel,
        'p_cognitive_tier': cognitiveTier,
        'p_language_code': languageCode,
        'p_explanation': explanation.trim(),
        'p_source_reference': sourceReference.trim(),
        'p_copyright_notice': copyrightNotice.trim(),
        'p_question_id': questionId,
      },
    );
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> transitionQuestionStatus({
    required String questionId,
    required String action,
    String comments = '',
  }) async {
    final res = await _db.rpc(
      'transition_exam_v2_question_status',
      params: {
        'p_question_id': questionId,
        'p_action': action,
        'p_comments': comments,
      },
    );
    return Map<String, dynamic>.from(res as Map);
  }

  Future<ExamV2PaperBuilderBundle> getPaperBuilder(String examinationId) async {
    final res = await _db.rpc(
      'get_exam_v2_paper_builder',
      params: {'p_examination_id': examinationId},
    );
    return ExamV2PaperBuilderBundle.fromJson(
      Map<String, dynamic>.from(res as Map),
    );
  }

  Future<Map<String, dynamic>> addPaperQuestion({
    required String examinationId,
    required String sectionId,
    required String sourceQuestionId,
    double? marks,
  }) async {
    final res = await _db.rpc(
      'add_exam_v2_paper_question',
      params: {
        'p_examination_id': examinationId,
        'p_section_id': sectionId,
        'p_source_question_id': sourceQuestionId,
        'p_marks': marks,
      },
    );
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> reorderPaperQuestions({
    required String examinationId,
    required String sectionId,
    required List<String> orderedIds,
  }) async {
    final res = await _db.rpc(
      'reorder_exam_v2_paper_questions',
      params: {
        'p_examination_id': examinationId,
        'p_section_id': sectionId,
        'p_ordered_ids': orderedIds,
      },
    );
    return Map<String, dynamic>.from(res as Map);
  }

  Future<Map<String, dynamic>> removePaperQuestion(
    String examinationQuestionId,
  ) async {
    final res = await _db.rpc(
      'remove_exam_v2_paper_question',
      params: {'p_examination_question_id': examinationQuestionId},
    );
    return Map<String, dynamic>.from(res as Map);
  }

  Future<ExamV2ReviewQueueResult> listReviewQueue({
    String? countryCode,
    String status = 'all_reviewable',
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    final res = await _db.rpc(
      'list_exam_v2_review_queue',
      params: {
        'p_country_code': countryCode,
        'p_status': status,
        'p_search':
            (search == null || search.trim().isEmpty) ? null : search.trim(),
        'p_limit': limit,
        'p_offset': offset,
      },
    );
    return ExamV2ReviewQueueResult.fromJson(
      Map<String, dynamic>.from(res as Map),
    );
  }

  Future<Map<String, dynamic>> recordReviewDecision({
    required String examinationId,
    required String action,
    required String comments,
    Map<String, bool> checklist = const {},
  }) async {
    final res = await _db.rpc(
      'record_exam_v2_review_decision',
      params: {
        'p_examination_id': examinationId,
        'p_action': action,
        'p_comments': comments,
        'p_checklist': checklist,
      },
    );
    return Map<String, dynamic>.from(res as Map);
  }

  Future<ExamV2DashboardData> getDashboard({
    String? countryCode,
    String? educationLevelId,
    String? gradeId,
    String? subjectId,
  }) async {
    final res = await _db.rpc(
      'get_exam_v2_dashboard',
      params: {
        'p_country_code': countryCode,
        'p_education_level_id': educationLevelId,
        'p_grade_id': gradeId,
        'p_subject_id': subjectId,
      },
    );
    return ExamV2DashboardData.fromJson(
      Map<String, dynamic>.from(res as Map),
    );
  }

  Future<Map<String, dynamic>> createSession({
    required String examinationId,
    required String title,
    required DateTime startsAt,
    required DateTime endsAt,
    String deliveryMode = 'online',
    String venue = '',
    String instructions = '',
  }) async {
    final res = await _db.rpc(
      'create_exam_v2_session',
      params: {
        'p_examination_id': examinationId,
        'p_title': title.trim(),
        'p_starts_at': startsAt.toUtc().toIso8601String(),
        'p_ends_at': endsAt.toUtc().toIso8601String(),
        'p_delivery_mode': deliveryMode,
        'p_venue': venue.trim(),
        'p_instructions': instructions.trim(),
      },
    );
    return Map<String, dynamic>.from(res as Map);
  }
}
