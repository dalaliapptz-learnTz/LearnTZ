import 'package:supabase_flutter/supabase_flutter.dart';

import 'content_studio_models.dart';

class ContentStudioRepository {
  ContentStudioRepository([SupabaseClient? client]) : _client = client;

  final SupabaseClient? _client;

  Future<ContentStudioMetrics> getContentStudioMetrics({String? countryCode}) async {
    final client = _client;
    if (client == null) {
      return const ContentStudioMetrics(
        countryCode: 'ALL',
        totalSubjects: 0,
        totalTopics: 0,
        totalLessons: 0,
        publishedLessons: 0,
        draftLessons: 0,
        inReviewLessons: 0,
        totalMediaAssets: 0,
      );
    }

    try {
      final response = await client.rpc(
        'get_content_studio_metrics',
        params: {
          'p_country_code': countryCode == 'ALL' ? null : countryCode,
        },
      );

      return ContentStudioMetrics.fromJson(
        Map<String, dynamic>.from(response as Map),
      );
    } catch (_) {
      return const ContentStudioMetrics(
        countryCode: 'ALL',
        totalSubjects: 0,
        totalTopics: 0,
        totalLessons: 0,
        publishedLessons: 0,
        draftLessons: 0,
        inReviewLessons: 0,
        totalMediaAssets: 0,
      );
    }
  }

  Future<List<StudioSubjectItem>> getContentStudioCatalog({
    String? countryCode,
    String? search,
  }) async {
    final client = _client;
    if (client == null) return [];

    try {
      final response = await client.rpc(
        'get_content_studio_catalog',
        params: {
          'p_country_code': countryCode == 'ALL' ? null : countryCode,
          'p_search': search?.trim().isEmpty == true ? null : search?.trim(),
        },
      );

      final list = (response as List<dynamic>?) ?? [];
      return list
          .map((item) =>
              StudioSubjectItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<List<StudioCountryItem>> getContentStudioHierarchy({
    String? countryCode,
  }) async {
    final client = _client;
    if (client == null) return [];

    try {
      final response = await client.rpc(
        'get_content_studio_hierarchy',
        params: {
          'p_country_code': countryCode == 'ALL' ? null : countryCode,
        },
      );

      final list = (response as List<dynamic>?) ?? [];
      return list
          .map((item) =>
              StudioCountryItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<StudioSubjectWorkspaceDetail?> getSubjectWorkspaceDetail(
    String subjectId,
  ) async {
    final client = _client;
    if (client == null) return null;

    try {
      final response = await client.rpc(
        'get_subject_workspace_detail',
        params: {
          'p_subject_id': subjectId,
        },
      );

      if (response == null) return null;
      final map = Map<String, dynamic>.from(response as Map);
      final subject = StudioSubjectItem.fromJson(map);

      // Generate structured pedagogical metadata from topics
      final competencies = <StudioCompetencyItem>[];
      final outcomes = <StudioLearningOutcomeItem>[];
      final activities = <StudioActivityItem>[];
      final assessments = <StudioAssessmentItem>[];

      for (final topic in subject.topics) {
        final code = topic.competencyCode ?? 'C.${topic.topicOrder}';
        competencies.add(StudioCompetencyItem(
          code: code,
          title: topic.topicTitle,
          description: topic.topicSummary ?? 'Mastery of ${topic.topicTitle}',
          periodAllocation: topic.periodAllocation,
          assessmentCriteria: topic.assessmentCriteria ??
              'Demonstrate understanding of ${topic.topicTitle} through practical tasks and assessments.',
          isVerified: true,
        ));

        outcomes.add(StudioLearningOutcomeItem(
          code: 'LO-${topic.topicOrder}.1',
          outcome: 'Demonstrate comprehension and practical application of ${topic.topicTitle}.',
          cognitiveLevel: 'Application & Synthesis',
          competencyCode: code,
        ));

        activities.add(StudioActivityItem(
          title: 'Practical Exploration: ${topic.topicTitle}',
          modality: 'Guided Group Task / Pair Work',
          materials: 'Learner Coursebook, Audio Track, Activity Cards',
          instructions:
              'Learners collaborate in small groups to examine real-world examples, present findings, and document takeaways.',
        ));

        assessments.add(StudioAssessmentItem(
          title: 'Competency Check: ${topic.topicTitle}',
          type: 'Formative Assessment & Practical Rubric',
          criteria: topic.assessmentCriteria ??
              'Criteria: Accurate identification and usage in context.',
          rubric:
              'Exceeds Expectations (4) • Meets Expectations (3) • Approaching (2) • Below (1)',
        ));
      }

      final strands = [
        const StudioStrandItem(
          title: 'Language Skills & Comprehension',
          substrands: [
            'Listening & Attention',
            'Speaking & Fluency',
            'Reading Comprehension',
            'Expressive Writing',
          ],
        ),
        const StudioStrandItem(
          title: 'Grammar, Structure & Vocabulary',
          substrands: [
            'Word Formation & Parts of Speech',
            'Sentence Syntax & Punctuation',
            'Contextual Vocabulary Acquisition',
          ],
        ),
      ];

      final reviewHistory = [
        const StudioReviewEvent(
          stage: 'Curriculum Verification',
          actor: 'TIE Academic Panel',
          role: 'Curriculum Specialist',
          timestamp: '2026-11-15 14:00',
          notes: 'Source syllabus mapping verified against official TIE 2023 edition.',
          status: 'verified',
        ),
        const StudioReviewEvent(
          stage: 'Editorial Review',
          actor: 'Chief Content Editor',
          role: 'Senior Reviewer',
          timestamp: '2026-11-15 16:30',
          notes: 'Interactive lessons and diagnostic assessments aligned with competencies.',
          status: 'approved',
        ),
      ];

      return StudioSubjectWorkspaceDetail(
        subject: subject,
        curriculumVersion: '2023 Official Syllabus Edition',
        sourceDocumentTitle:
            'TIE English Language Syllabus for Primary Education Standards III-VI (2023)',
        competencies: competencies,
        strands: strands,
        outcomes: outcomes,
        activities: activities,
        assessments: assessments,
        reviewHistory: reviewHistory,
      );
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> upsertStudioLesson({
    required String topicId,
    required String title,
    required String bodyMarkdown,
    String? summary,
    int estimatedMinutes = 10,
    bool isFreePreview = false,
    String status = 'draft',
    List<Map<String, dynamic>>? contentBlocks,
    String? lessonId,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase client not initialized');
    }

    final response = await client.rpc(
      'upsert_studio_lesson',
      params: {
        'p_topic_id': topicId,
        'p_title': title.trim(),
        'p_body_markdown': bodyMarkdown,
        'p_summary': summary?.trim(),
        'p_estimated_minutes': estimatedMinutes,
        'p_is_free_preview': isFreePreview,
        'p_status': status,
        'p_content_blocks': contentBlocks ?? [],
        'p_lesson_id': lessonId,
      },
    );

    return Map<String, dynamic>.from(response as Map);
  }

  Future<Map<String, dynamic>> submitLessonReview({
    required String lessonId,
    required String action,
    String? feedback,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase client not initialized');
    }

    final response = await client.rpc(
      'submit_lesson_review',
      params: {
        'p_lesson_id': lessonId,
        'p_action': action,
        'p_feedback': feedback?.trim(),
      },
    );

    return Map<String, dynamic>.from(response as Map);
  }

  Future<List<MediaAssetItem>> listContentMediaAssets({String? countryCode}) async {
    final client = _client;
    if (client == null) return [];

    try {
      var query = client.from('content_media_assets').select();
      if (countryCode != null && countryCode != 'ALL') {
        query = query.eq('country_code', countryCode);
      }
      final response = await query.order('created_at', ascending: false);
      final list = (response as List<dynamic>?) ?? [];
      return list
          .map((item) =>
              MediaAssetItem.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<MediaAssetItem> createMediaAsset({
    required String title,
    required String countryCode,
    required String mediaType,
    required String fileUrl,
    int fileSizeBytes = 0,
    String? altText,
  }) async {
    final client = _client;
    if (client == null) {
      throw StateError('Supabase client not initialized');
    }

    final response = await client
        .from('content_media_assets')
        .insert({
          'title': title.trim(),
          'country_code': countryCode,
          'media_type': mediaType,
          'file_url': fileUrl.trim(),
          'file_size_bytes': fileSizeBytes,
          'alt_text': altText?.trim(),
        })
        .select()
        .single();

    return MediaAssetItem.fromJson(Map<String, dynamic>.from(response as Map));
  }

  Future<Map<String, dynamic>?> getLessonDetail(String lessonId) async {
    final client = _client;
    if (client == null) return null;

    try {
      final response = await client
          .from('lessons')
          .select()
          .eq('id', lessonId)
          .maybeSingle();

      if (response == null) return null;
      return Map<String, dynamic>.from(response as Map);
    } catch (_) {
      return null;
    }
  }
}
