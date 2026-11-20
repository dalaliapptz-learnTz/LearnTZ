import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_providers.dart';
import 'gamification_models.dart';
import 'gamification_repository.dart';

final gamificationRepositoryProvider = Provider<GamificationRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return client == null ? null : SupabaseGamificationRepository(client);
});

final learnerGamificationOverviewProvider = FutureProvider.autoDispose
    .family<LearnerGamificationOverview?, String>((ref, learnerId) async {
      final repo = ref.watch(gamificationRepositoryProvider);
      if (repo == null) return null;
      return repo.getLearnerOverview(learnerId);
    });

typedef LeaderboardQuery = ({
  String learnerId,
  String period,
  String? subjectId,
});

final gamificationLeaderboardProvider = FutureProvider.autoDispose
    .family<GamificationLeaderboardData?, LeaderboardQuery>((ref, query) async {
      final repo = ref.watch(gamificationRepositoryProvider);
      if (repo == null) return null;
      return repo.getLeaderboard(
        learnerId: query.learnerId,
        period: query.period,
        subjectId: query.subjectId,
      );
    });

final parentChildrenGamificationSummaryProvider = FutureProvider.autoDispose<
    List<ParentChildGamificationSummary>>((ref) async {
  final repo = ref.watch(gamificationRepositoryProvider);
  if (repo == null) return const [];
  return repo.getParentChildrenSummary();
});
