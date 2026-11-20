import 'package:supabase_flutter/supabase_flutter.dart';

import 'gamification_models.dart';

abstract class GamificationRepository {
  Future<LearnerGamificationOverview> getLearnerOverview(String learnerId);

  Future<GamificationLeaderboardData> getLeaderboard({
    required String learnerId,
    String period = 'weekly',
    String? subjectId,
    int limit = 25,
  });

  Future<void> updatePreferences({
    required String learnerId,
    required bool leaderboardOptIn,
    String? leaderboardAlias,
    String? timezone,
  });

  Future<List<ParentChildGamificationSummary>> getParentChildrenSummary();
}

class SupabaseGamificationRepository implements GamificationRepository {
  SupabaseGamificationRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<LearnerGamificationOverview> getLearnerOverview(
    String learnerId,
  ) async {
    final response = await _client.rpc(
      'get_learner_gamification_overview',
      params: {'p_learner_id': learnerId},
    );
    return LearnerGamificationOverview.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  @override
  Future<GamificationLeaderboardData> getLeaderboard({
    required String learnerId,
    String period = 'weekly',
    String? subjectId,
    int limit = 25,
  }) async {
    final response = await _client.rpc(
      'get_gamification_leaderboard',
      params: {
        'p_learner_id': learnerId,
        'p_period': period,
        'p_subject_id': subjectId,
        'p_limit': limit,
      },
    );
    return GamificationLeaderboardData.fromJson(
      Map<String, dynamic>.from(response as Map),
    );
  }

  @override
  Future<void> updatePreferences({
    required String learnerId,
    required bool leaderboardOptIn,
    String? leaderboardAlias,
    String? timezone,
  }) async {
    await _client.rpc(
      'update_learner_gamification_preferences',
      params: {
        'p_learner_id': learnerId,
        'p_leaderboard_opt_in': leaderboardOptIn,
        'p_leaderboard_alias': leaderboardAlias,
        'p_timezone': timezone,
      },
    );
  }

  @override
  Future<List<ParentChildGamificationSummary>> getParentChildrenSummary() async {
    final response = await _client.rpc('get_parent_children_gamification_summary');
    final list = (response as List?) ?? const [];
    return list
        .map(
          (e) => ParentChildGamificationSummary.fromJson(
            Map<String, dynamic>.from(e as Map),
          ),
        )
        .toList();
  }
}
