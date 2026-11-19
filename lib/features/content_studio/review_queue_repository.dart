import 'package:supabase_flutter/supabase_flutter.dart';

import 'review_queue_models.dart';

class AcademicReviewQueueRepository {
  AcademicReviewQueueRepository([SupabaseClient? client]) : _client = client;

  final SupabaseClient? _client;

  SupabaseClient get _db => _client ?? Supabase.instance.client;

  String? get currentUserId => _db.auth.currentUser?.id;

  Future<ReviewQueueSummary> getSummary({String? countryCode}) async {
    final res = await _db.rpc(
      'get_academic_review_queue_summary',
      params: {
        'p_country_code':
            (countryCode == null || countryCode == 'ALL') ? null : countryCode,
      },
    );
    return ReviewQueueSummary.fromJson(
      Map<String, dynamic>.from(res as Map),
    );
  }

  Future<ReviewQueuePage> listQueue(ReviewQueueQuery query) async {
    final res = await _db.rpc(
      'list_academic_review_queue',
      params: {
        'p_country_code': (query.countryCode == null || query.countryCode == 'ALL')
            ? null
            : query.countryCode,
        'p_education_level_id': query.educationLevelId,
        'p_grade_id': query.gradeId,
        'p_subject_id': query.subjectId,
        'p_status': query.status,
        'p_search':
            (query.search == null || query.search!.trim().isEmpty)
                ? null
                : query.search!.trim(),
        'p_assigned_reviewer_id': query.assignedReviewerId,
        'p_only_unassigned': query.onlyUnassigned,
        'p_limit': query.limit,
        'p_offset': query.offset,
      },
    );
    return ReviewQueuePage.fromJson(
      Map<String, dynamic>.from(res as Map),
    );
  }

  Future<Map<String, dynamic>> assignReviewer({
    required String lessonId,
    String? reviewerId,
  }) async {
    final res = await _db.rpc(
      'assign_lesson_reviewer',
      params: {
        'p_lesson_id': lessonId,
        'p_reviewer_id': reviewerId,
      },
    );
    return Map<String, dynamic>.from(res as Map);
  }
}
