import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'content_studio_models.dart';
import 'lesson_authoring_models.dart';

class LessonAuthoringRepository {
  LessonAuthoringRepository([SupabaseClient? client])
      : _client = client,
        _storage = const FlutterSecureStorage();

  final SupabaseClient? _client;
  final FlutterSecureStorage _storage;

  static const int maxMediaFileSizeBytes = 26214400; // 25 MB
  static const String mediaBucketName = 'lesson-media';
  static const Set<String> allowedExtensions = {
    'png',
    'jpg',
    'jpeg',
    'webp',
    'svg',
    'mp3',
    'm4a',
    'ogg',
    'wav',
    'mp4',
    'webm',
    'pdf',
  };

  Future<LessonAuthoringCapabilities> getCapabilities({
    String? countryCode,
  }) async {
    final client = _client;
    if (client == null || client.auth.currentSession == null) {
      return const LessonAuthoringCapabilities();
    }
    try {
      final response = await client.rpc(
        'get_lesson_authoring_capabilities',
        params: {'p_country_code': countryCode},
      );
      if (response is Map) {
        return LessonAuthoringCapabilities.fromJson(
          Map<String, dynamic>.from(response),
        );
      }
      return const LessonAuthoringCapabilities();
    } catch (_) {
      return const LessonAuthoringCapabilities();
    }
  }

  Future<LessonAuthoringContext> getAuthoringContext({
    String? countryCode,
    String? curriculumId,
    String? educationLevelId,
    String? gradeId,
    String? subjectId,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase client is not configured.');
    }
    final response = await client.rpc(
      'get_lesson_authoring_context',
      params: {
        'p_country_code': countryCode,
        'p_curriculum_id': curriculumId,
        'p_education_level_id': educationLevelId,
        'p_grade_id': gradeId,
        'p_subject_id': subjectId,
      },
    );
    return LessonAuthoringContext.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  Future<List<AuthoringGradeOption>> getGrades({
    required String curriculumId,
    String? educationLevelId,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase client is not configured.');
    }
    final response = await client.rpc(
      'get_authoring_grades',
      params: {
        'p_curriculum_id': curriculumId,
        'p_education_level_id': educationLevelId,
      },
    );
    final list = (response as List<dynamic>?) ?? const [];
    return list
        .map((e) =>
            AuthoringGradeOption.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<AuthoringSubjectOption>> getSubjects({
    required String curriculumId,
    required String gradeId,
    String? educationLevelId,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase client is not configured.');
    }
    final response = await client.rpc(
      'get_authoring_subjects',
      params: {
        'p_curriculum_id': curriculumId,
        'p_grade_id': gradeId,
        'p_education_level_id': educationLevelId,
      },
    );
    final list = (response as List<dynamic>?) ?? const [];
    return list
        .map((e) => AuthoringSubjectOption.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<AuthoringMainCompetenceOption>> getMainCompetences({
    required String subjectId,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase client is not configured.');
    }
    final response = await client.rpc(
      'get_authoring_main_competences',
      params: {'p_subject_id': subjectId},
    );
    final list = (response as List<dynamic>?) ?? const [];
    return list
        .map((e) => AuthoringMainCompetenceOption.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<List<AuthoringSpecificCompetenceOption>> getSpecificCompetences({
    required String mainCompetenceId,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase client is not configured.');
    }
    final response = await client.rpc(
      'get_authoring_specific_competences',
      params: {'p_main_competence_id': mainCompetenceId},
    );
    final list = (response as List<dynamic>?) ?? const [];
    return list
        .map((e) => AuthoringSpecificCompetenceOption.fromJson(
            Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<Map<String, dynamic>> saveDraft({
    required String countryCode,
    required String curriculumId,
    String? curriculumVersionId,
    required String educationLevelId,
    required String gradeId,
    required String subjectId,
    required String mainCompetenceId,
    required String specificCompetenceId,
    required String topicId,
    String? subtopicId,
    required String title,
    required String bodyMarkdown,
    String? summary,
    int estimatedMinutes = 20,
    String languageCode = 'en',
    String difficultyLevel = 'standard',
    String lessonType = 'core_instruction',
    bool isFreePreview = false,
    List<String> learningObjectives = const [],
    List<LessonLearningOutcome> learningOutcomes = const [],
    List<LessonContentBlock> contentBlocks = const [],
    List<LessonTeachingActivity> teachingActivities = const [],
    String? assessmentCriteria,
    String? changeSummary,
    String? lessonId,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase client is not configured.');
    }
    final response = await client.rpc(
      'save_authored_lesson',
      params: {
        'p_country_code': countryCode,
        'p_curriculum_id': curriculumId,
        'p_curriculum_version_id': curriculumVersionId,
        'p_education_level_id': educationLevelId,
        'p_grade_id': gradeId,
        'p_subject_id': subjectId,
        'p_main_competence_id': mainCompetenceId,
        'p_specific_competence_id': specificCompetenceId,
        'p_topic_id': topicId,
        'p_subtopic_id': subtopicId,
        'p_title': title.trim(),
        'p_body_markdown': bodyMarkdown,
        'p_summary': summary?.trim(),
        'p_estimated_minutes': estimatedMinutes,
        'p_language_code': languageCode,
        'p_difficulty_level': difficultyLevel,
        'p_lesson_type': lessonType,
        'p_is_free_preview': isFreePreview,
        'p_learning_objectives': learningObjectives,
        'p_learning_outcomes': learningOutcomes.map((o) => o.toJson()).toList(),
        'p_content_blocks': contentBlocks.map((b) => b.toJson()).toList(),
        'p_teaching_activities':
            teachingActivities.map((a) => a.toJson()).toList(),
        'p_assessment_criteria': assessmentCriteria?.trim(),
        'p_change_summary': changeSummary?.trim(),
        'p_lesson_id': lessonId,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> transitionWorkflow({
    required String lessonId,
    required String action,
    String? comments,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase client is not configured.');
    }
    final response = await client.rpc(
      'transition_lesson_workflow',
      params: {
        'p_lesson_id': lessonId,
        'p_action': action,
        'p_comments': comments?.trim(),
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> getLessonBundle(String lessonId) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase client is not configured.');
    }
    final response = await client.rpc(
      'get_authored_lesson_bundle',
      params: {'p_lesson_id': lessonId},
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> upsertQuestion({
    required String lessonId,
    required LessonAssessmentQuestion question,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase client is not configured.');
    }
    final response = await client.rpc(
      'upsert_lesson_assessment_question',
      params: {
        'p_lesson_id': lessonId,
        'p_question_type': question.questionType.dbValue,
        'p_question_text': question.questionText.trim(),
        'p_correct_answer': question.correctAnswer,
        'p_options': question.options,
        'p_explanation': question.explanation.trim(),
        'p_marks': question.marks,
        'p_difficulty_level': question.difficultyLevel,
        'p_learning_outcome_ref': question.learningOutcomeRef,
        'p_assessment_criteria': question.assessmentCriteria.trim(),
        'p_cognitive_tier': question.cognitiveTier,
        'p_question_id': question.id,
      },
    );
    return Map<String, dynamic>.from(response as Map);
  }

  Future<void> deleteQuestion(String questionId) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase client is not configured.');
    }
    await client.rpc(
      'delete_lesson_assessment_question',
      params: {'p_question_id': questionId},
    );
  }

  Future<MediaAssetItem> uploadAndRegisterMediaAsset({
    required String title,
    required String countryCode,
    required String mediaType,
    String? subjectId,
    String? description,
    String? sourceReference,
    String licenseType = 'unverified',
    String? attribution,
    String? altText,
    String? transcript,
    Uint8List? fileBytes,
    String? fileName,
    String? mimeType,
    String? externalFileUrl,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase client is not configured.');
    }

    String resolvedUrl = externalFileUrl?.trim() ?? '';
    String? storagePath;
    int fileSize = 0;

    if (fileBytes != null && fileName != null) {
      if (fileBytes.length > maxMediaFileSizeBytes) {
        throw ArgumentError('File exceeds maximum allowed size of 25 MB.');
      }
      final ext = fileName.contains('.')
          ? fileName.split('.').last.toLowerCase()
          : '';
      if (!allowedExtensions.contains(ext)) {
        throw ArgumentError(
          'Unsupported file type ".$ext". Allowed: ${allowedExtensions.join(', ')}',
        );
      }

      final sanitized = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      storagePath = '${countryCode.toUpperCase()}/$mediaType/${timestamp}_$sanitized';
      fileSize = fileBytes.length;

      await client.storage.from(mediaBucketName).uploadBinary(
            storagePath,
            fileBytes,
            fileOptions: FileOptions(
              contentType: mimeType ?? _inferMimeType(ext),
              upsert: false,
            ),
          );
      resolvedUrl = '$mediaBucketName/$storagePath';
    }

    if (resolvedUrl.isEmpty) {
      throw ArgumentError('Either a file upload or a valid file reference is required.');
    }

    final response = await client.rpc(
      'register_lesson_media_asset',
      params: {
        'p_title': title.trim(),
        'p_country_code': countryCode,
        'p_media_type': mediaType,
        'p_file_url': resolvedUrl,
        'p_subject_id': subjectId,
        'p_description': description?.trim(),
        'p_storage_bucket': storagePath != null ? mediaBucketName : null,
        'p_storage_object_path': storagePath,
        'p_mime_type': mimeType,
        'p_file_size_bytes': fileSize,
        'p_source_reference': sourceReference?.trim(),
        'p_license_type': licenseType,
        'p_attribution': attribution?.trim(),
        'p_alt_text': altText?.trim(),
        'p_transcript': transcript?.trim(),
      },
    );

    return MediaAssetItem.fromJson(Map<String, dynamic>.from(response as Map));
  }

  /// Persist unsaved draft locally for recovery after accidental tab/app closure.
  Future<void> saveLocalRecoveryDraft(
    String draftKey,
    Map<String, dynamic> payload,
  ) async {
    try {
      await _storage.write(
        key: 'learntz_lesson_draft_$draftKey',
        value: jsonEncode(payload),
      );
    } catch (_) {
      // Non-fatal in test or restricted environments
    }
  }

  Future<Map<String, dynamic>?> loadLocalRecoveryDraft(String draftKey) async {
    try {
      final raw = await _storage.read(key: 'learntz_lesson_draft_$draftKey');
      if (raw == null || raw.isEmpty) return null;
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  Future<void> clearLocalRecoveryDraft(String draftKey) async {
    try {
      await _storage.delete(key: 'learntz_lesson_draft_$draftKey');
    } catch (_) {}
  }

  String _inferMimeType(String ext) {
    return switch (ext) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      'svg' => 'image/svg+xml',
      'mp3' => 'audio/mpeg',
      'm4a' => 'audio/mp4',
      'ogg' => 'audio/ogg',
      'wav' => 'audio/wav',
      'mp4' => 'video/mp4',
      'webm' => 'video/webm',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }
}
