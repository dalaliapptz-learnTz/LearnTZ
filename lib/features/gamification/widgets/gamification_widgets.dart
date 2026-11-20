import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_card.dart';
import '../../learning/learning_models.dart';
import '../gamification_models.dart';
import '../gamification_providers.dart';

IconData gamificationBadgeIcon(String iconName) {
  switch (iconName) {
    case 'menu_book':
      return Icons.menu_book_rounded;
    case 'auto_stories':
      return Icons.auto_stories_rounded;
    case 'school':
      return Icons.school_rounded;
    case 'local_fire_department':
      return Icons.local_fire_department_rounded;
    case 'bolt':
      return Icons.bolt_rounded;
    case 'workspace_premium':
      return Icons.workspace_premium_rounded;
    case 'quiz':
      return Icons.quiz_rounded;
    case 'verified':
      return Icons.verified_rounded;
    case 'assignment_turned_in':
      return Icons.assignment_turned_in_rounded;
    case 'trending_up':
      return Icons.trending_up_rounded;
    case 'emoji_events':
      return Icons.emoji_events_rounded;
    case 'calculate':
      return Icons.calculate_rounded;
    case 'psychology':
      return Icons.psychology_rounded;
    case 'favorite':
      return Icons.favorite_rounded;
    default:
      return Icons.stars_rounded;
  }
}

Color gamificationTierColor(String tier) {
  switch (tier) {
    case 'platinum':
      return const Color(0xFF4338CA);
    case 'gold':
      return const Color(0xFFD97706);
    case 'silver':
      return const Color(0xFF475569);
    default:
      return const Color(0xFFB45309);
  }
}

/// Prominently displays the 3 mandatory Gamification System 2.0 features
/// directly on the main Learners Hub dashboard:
///   1. Learning Streaks + 7-day local activity calendar
///   2. Verified XP Balance + Badges & Achievements
///   3. Cohort Leaderboards & Rankings + Privacy status
class GamificationDashboardSection extends ConsumerWidget {
  const GamificationDashboardSection({
    required this.learnerId,
    required this.subjects,
    super.key,
  });

  final String learnerId;
  final List<LearningSubject> subjects;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(learnerGamificationOverviewProvider(learnerId));

    return overviewAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (overview) {
        if (overview == null) return const SizedBox.shrink();
        final style = overview.ageTier.style;
        final unreadBadgeNotif = overview.recentNotifications
            .where((n) => !n.isRead)
            .firstOrNull;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (unreadBadgeNotif != null) ...[
              _AchievementUnlockedBanner(
                notification: unreadBadgeNotif,
                style: style,
                onTap: () => _openBadgesDialog(context, overview),
              ),
              const SizedBox(height: 14),
            ],
            // Top 3 Gamification Summary Cards (3 columns on BOTH desktop and mobile!)
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 860;
                final streakCard = _StreakOverviewCard(
                  overview: overview,
                  style: style,
                  compact: !isWide,
                );
                final xpBadgesCard = _XpAndBadgesCard(
                  overview: overview,
                  style: style,
                  compact: !isWide,
                  onViewBadges: () => _openBadgesDialog(context, overview),
                );
                final leaderboardCard = _LeaderboardPreviewCard(
                  overview: overview,
                  style: style,
                  compact: !isWide,
                  onOpenLeaderboard: () => _openLeaderboardDialog(
                    context,
                    overview: overview,
                    subjects: subjects,
                  ),
                );

                if (isWide) {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 4, child: streakCard),
                        const SizedBox(width: 12),
                        Expanded(flex: 4, child: xpBadgesCard),
                        const SizedBox(width: 12),
                        Expanded(flex: 3, child: leaderboardCard),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: streakCard),
                        const SizedBox(width: 8),
                        Expanded(child: xpBadgesCard),
                        const SizedBox(width: 8),
                        Expanded(child: leaderboardCard),
                      ],
                    ),
                    if (overview.weeklyCalendar.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _WeeklyCalendarStripCard(
                        overview: overview,
                        style: style,
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }

  void _openBadgesDialog(
    BuildContext context,
    LearnerGamificationOverview overview,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 680),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      color: overview.ageTier.style.badgeAccent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        overview.ageTier.style.badgeTitle,
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: BadgesCollectionView(overview: overview),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openLeaderboardDialog(
    BuildContext context, {
    required LearnerGamificationOverview overview,
    required List<LearningSubject> subjects,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 720),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.leaderboard_rounded,
                      color: overview.ageTier.style.rankAccent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        overview.ageTier.style.rankLabel,
                        style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: LeaderboardPanelView(
                    learnerId: overview.learnerId,
                    initialOptIn: overview.leaderboardOptIn,
                    initialAlias: overview.leaderboardAlias,
                    ageTier: overview.ageTier,
                    subjects: subjects,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AchievementUnlockedBanner extends StatelessWidget {
  const _AchievementUnlockedBanner({
    required this.notification,
    required this.style,
    required this.onTap,
  });

  final BadgeNotificationItem notification;
  final GamificationTierStyle style;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: style.badgeTint,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: style.badgeAccent.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Icon(Icons.workspace_premium_rounded, color: style.badgeAccent, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                    ),
                    Text(
                      notification.body,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF475569),
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, size: 18, color: style.badgeAccent),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeeklyCalendarStripCard extends StatelessWidget {
  const _WeeklyCalendarStripCard({
    required this.overview,
    required this.style,
  });

  final LearnerGamificationOverview overview;
  final GamificationTierStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final day in overview.weeklyCalendar)
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: day.isActive
                        ? style.streakAccent
                        : const Color(0xFFF1F5F9),
                    border: day.isToday
                        ? Border.all(color: style.streakAccent, width: 2)
                        : null,
                  ),
                  child: Icon(
                    day.isActive ? Icons.check_rounded : Icons.circle,
                    size: day.isActive ? 14 : 4,
                    color: day.isActive ? Colors.white : const Color(0xFFCBD5E1),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  day.dayLabel.length > 2
                      ? day.dayLabel.substring(0, 2)
                      : day.dayLabel,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: day.isToday ? FontWeight.w800 : FontWeight.w500,
                    color: day.isToday
                        ? style.streakAccent
                        : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _StreakOverviewCard extends StatelessWidget {
  const _StreakOverviewCard({
    required this.overview,
    required this.style,
    this.compact = false,
  });

  final LearnerGamificationOverview overview;
  final GamificationTierStyle style;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return Container(
        key: const ValueKey('gamification-streak-card'),
        constraints: const BoxConstraints(minHeight: 118),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, style.streakTint],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: style.streakAccent.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: style.streakAccent,
                borderRadius: BorderRadius.circular(9),
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.white,
                size: 17,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${overview.currentStreak} ${overview.currentStreak == 1 ? 'Day' : 'Days'} Streak',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                height: 1.15,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Best: ${overview.longestStreak} ${overview.longestStreak == 1 ? 'day' : 'days'}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return AppCard(
      key: const ValueKey('gamification-streak-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: style.streakTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: style.streakAccent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${overview.currentStreak} ${overview.currentStreak == 1 ? 'Day' : 'Days'} Streak',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                    ),
                    Text(
                      'Best: ${overview.longestStreak} ${overview.longestStreak == 1 ? 'day' : 'days'}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 7-day learner-local activity calendar
          Row(
            children: [
              for (final day in overview.weeklyCalendar)
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: day.isActive
                              ? style.streakAccent
                              : const Color(0xFFF1F5F9),
                          border: day.isToday
                              ? Border.all(color: style.streakAccent, width: 2)
                              : null,
                        ),
                        child: Icon(
                          day.isActive ? Icons.check_rounded : Icons.circle,
                          size: day.isActive ? 14 : 5,
                          color: day.isActive
                              ? Colors.white
                              : const Color(0xFFCBD5E1),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        day.dayLabel.length > 2
                            ? day.dayLabel.substring(0, 2)
                            : day.dayLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              day.isToday ? FontWeight.w800 : FontWeight.w500,
                          color: day.isToday
                              ? style.streakAccent
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            style.encouragement,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF475569),
                ),
          ),
        ],
      ),
    );
  }
}

class _XpAndBadgesCard extends StatelessWidget {
  const _XpAndBadgesCard({
    required this.overview,
    required this.style,
    required this.onViewBadges,
    this.compact = false,
  });

  final LearnerGamificationOverview overview;
  final GamificationTierStyle style;
  final VoidCallback onViewBadges;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final nextMilestone = overview.badges
        .where((b) => !b.isEarned)
        .firstOrNull;

    if (compact) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('gamification-view-badges-btn'),
          onTap: onViewBadges,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            key: const ValueKey('gamification-xp-badges-card'),
            constraints: const BoxConstraints(minHeight: 118),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, style.xpTint],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: style.xpAccent.withValues(alpha: 0.28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: style.xpAccent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: Colors.white,
                    size: 17,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${overview.totalXp} XP',
                  key: const ValueKey('gamification-xp-balance'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  nextMilestone != null
                      ? 'Next: ${nextMilestone.name}'
                      : '${overview.earnedBadgesCount}/${overview.badges.length} badges',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Badges →',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: style.xpAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AppCard(
      key: const ValueKey('gamification-xp-badges-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: style.xpTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.bolt_rounded, color: style.xpAccent, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${overview.totalXp} XP',
                      key: const ValueKey('gamification-xp-balance'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                    ),
                    Text(
                      '+${overview.weeklyXp} XP this week · ${overview.earnedBadgesCount}/${overview.badges.length} badges',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (nextMilestone != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  gamificationBadgeIcon(nextMilestone.iconName),
                  size: 16,
                  color: style.badgeAccent,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Next: ${nextMilestone.name}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF334155),
                        ),
                  ),
                ),
                Text(
                  '${nextMilestone.currentValue}/${nextMilestone.targetValue}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (nextMilestone.progressPercent.clamp(0, 100)) / 100.0,
                minHeight: 6,
                backgroundColor: const Color(0xFFE2E8F0),
                valueColor: AlwaysStoppedAnimation<Color>(style.badgeAccent),
              ),
            ),
          ],
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('gamification-view-badges-btn'),
              onPressed: onViewBadges,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: const Icon(Icons.emoji_events_outlined, size: 16),
              label: const Text('View badges'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardPreviewCard extends StatelessWidget {
  const _LeaderboardPreviewCard({
    required this.overview,
    required this.style,
    required this.onOpenLeaderboard,
    this.compact = false,
  });

  final LearnerGamificationOverview overview;
  final GamificationTierStyle style;
  final VoidCallback onOpenLeaderboard;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final rankText = overview.weeklyRank != null
        ? '#${overview.weeklyRank}'
        : '—';

    if (compact) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          key: const ValueKey('gamification-open-leaderboard-btn'),
          onTap: onOpenLeaderboard,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            key: const ValueKey('gamification-leaderboard-card'),
            constraints: const BoxConstraints(minHeight: 118),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, style.rankTint],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: style.rankAccent.withValues(alpha: 0.28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: style.rankAccent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                    Icons.leaderboard_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Rank $rankText',
                  key: const ValueKey('gamification-weekly-rank'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  overview.leaderboardOptIn ? 'Public ranking' : 'Private mode',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Rankings →',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    color: style.rankAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AppCard(
      key: const ValueKey('gamification-leaderboard-card'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: style.rankTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.leaderboard_rounded,
                  color: style.rankAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rank $rankText',
                      key: const ValueKey('gamification-weekly-rank'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                    ),
                    Text(
                      overview.gradeName != null && overview.gradeName!.isNotEmpty
                          ? '${overview.gradeName} · ${overview.countryCode}'
                          : overview.countryCode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: overview.leaderboardOptIn
                  ? const Color(0xFFDCFCE7)
                  : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  overview.leaderboardOptIn
                      ? Icons.public_rounded
                      : Icons.lock_outline_rounded,
                  size: 13,
                  color: overview.leaderboardOptIn
                      ? const Color(0xFF15803D)
                      : const Color(0xFF475569),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    overview.leaderboardOptIn ? 'Public ranking' : 'Private mode',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: overview.leaderboardOptIn
                          ? const Color(0xFF15803D)
                          : const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                key: const ValueKey('gamification-open-leaderboard-btn'),
                onPressed: onOpenLeaderboard,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                label: const Text('Rankings & privacy'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Filterable Earned / In-Progress / Locked Badge Collection (reused in Dialog & Profile tab)
class BadgesCollectionView extends StatefulWidget {
  const BadgesCollectionView({required this.overview, super.key});

  final LearnerGamificationOverview overview;

  @override
  State<BadgesCollectionView> createState() => _BadgesCollectionViewState();
}

class _BadgesCollectionViewState extends State<BadgesCollectionView> {
  String _filter = 'all'; // 'all' | 'earned' | 'in_progress' | 'locked'

  @override
  Widget build(BuildContext context) {
    final badges = widget.overview.badges.where((b) {
      if (_filter == 'all') return true;
      return b.status == _filter;
    }).toList();

    final filters = <(String key, String label)>[
      ('all', 'All (${widget.overview.badges.length})'),
      ('earned', 'Earned (${widget.overview.earnedBadgesCount})'),
      (
        'in_progress',
        'In Progress (${widget.overview.badges.where((b) => b.isInProgress).length})',
      ),
      (
        'locked',
        'Locked (${widget.overview.badges.where((b) => b.isLocked).length})',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in filters)
              ChoiceChip(
                label: Text(f.$2),
                selected: _filter == f.$1,
                onSelected: (_) => setState(() => _filter = f.$1),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (badges.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text('No badges in this category yet. Keep learning to unlock more!'),
          )
        else
          for (final badge in badges) ...[
            _BadgeRowCard(badge: badge),
            const SizedBox(height: 10),
          ],
      ],
    );
  }
}

class _BadgeRowCard extends StatelessWidget {
  const _BadgeRowCard({required this.badge});

  final AchievementBadgeItem badge;

  @override
  Widget build(BuildContext context) {
    final tierColor = gamificationTierColor(badge.tier);
    final isLocked = badge.isLocked;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: badge.isEarned
            ? tierColor.withValues(alpha: 0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: badge.isEarned
              ? tierColor.withValues(alpha: 0.35)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isLocked
                  ? const Color(0xFFF1F5F9)
                  : tierColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isLocked
                  ? Icons.lock_outline_rounded
                  : gamificationBadgeIcon(badge.iconName),
              color: isLocked ? const Color(0xFF94A3B8) : tierColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      badge.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: isLocked
                                ? const Color(0xFF64748B)
                                : const Color(0xFF0F172A),
                          ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: badge.isEarned
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badge.isEarned
                            ? 'Earned'
                            : badge.isInProgress
                                ? 'In progress'
                                : 'Locked',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: badge.isEarned
                              ? const Color(0xFF15803D)
                              : const Color(0xFF475569),
                        ),
                      ),
                    ),
                    if (badge.xpReward > 0)
                      Text(
                        '+${badge.xpReward} XP',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: tierColor,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  badge.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                ),
                const SizedBox(height: 8),
                if (badge.isEarned && badge.awardedAt != null)
                  Text(
                    'Earned on ${badge.awardedAt!.year}-${badge.awardedAt!.month.toString().padLeft(2, '0')}-${badge.awardedAt!.day.toString().padLeft(2, '0')}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF15803D),
                    ),
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: (badge.progressPercent.clamp(0, 100)) / 100.0,
                            minHeight: 6,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(tierColor),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${badge.currentValue}/${badge.targetValue}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cohort-scoped Leaderboard Panel with Weekly/Monthly/Subject filters + Child-Safe Privacy Controls
class LeaderboardPanelView extends ConsumerStatefulWidget {
  const LeaderboardPanelView({
    required this.learnerId,
    required this.initialOptIn,
    required this.ageTier,
    required this.subjects,
    this.initialAlias,
    super.key,
  });

  final String learnerId;
  final bool initialOptIn;
  final String? initialAlias;
  final GamificationAgeTier ageTier;
  final List<LearningSubject> subjects;

  @override
  ConsumerState<LeaderboardPanelView> createState() => _LeaderboardPanelViewState();
}

class _LeaderboardPanelViewState extends ConsumerState<LeaderboardPanelView> {
  String _period = 'weekly';
  String? _subjectId;
  late bool _optIn = widget.initialOptIn;
  late final TextEditingController _aliasController = TextEditingController(
    text: widget.initialAlias ?? '',
  );
  bool _savingPrefs = false;
  String? _statusMessage;

  @override
  void dispose() {
    _aliasController.dispose();
    super.dispose();
  }

  Future<void> _savePrivacyPreferences() async {
    final repo = ref.read(gamificationRepositoryProvider);
    if (repo == null) return;
    setState(() {
      _savingPrefs = true;
      _statusMessage = null;
    });
    try {
      await repo.updatePreferences(
        learnerId: widget.learnerId,
        leaderboardOptIn: _optIn,
        leaderboardAlias: _aliasController.text.trim(),
      );
      ref.invalidate(learnerGamificationOverviewProvider(widget.learnerId));
      ref.invalidate(
        gamificationLeaderboardProvider((
          learnerId: widget.learnerId,
          period: _period,
          subjectId: _subjectId,
        )),
      );
      if (mounted) {
        setState(() {
          _statusMessage = _optIn
              ? 'Leaderboard participation enabled.'
              : 'Private mode saved. You are hidden from public rankings.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _statusMessage = 'Could not save preferences: $e');
      }
    } finally {
      if (mounted) setState(() => _savingPrefs = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaderboardAsync = ref.watch(
      gamificationLeaderboardProvider((
        learnerId: widget.learnerId,
        period: _period,
        subjectId: _subjectId,
      )),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Privacy & Child-Safety Controls
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shield_outlined, size: 18, color: Color(0xFF0F4C81)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Ranking Privacy Controls',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  Switch(
                    key: const ValueKey('leaderboard-privacy-switch'),
                    value: _optIn,
                    onChanged: (val) => setState(() => _optIn = val),
                  ),
                ],
              ),
              Text(
                'Optional participation. Only your chosen nickname or first name + initial is shown — never your full name, school, or contact details.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _aliasController,
                      maxLength: 24,
                      decoration: const InputDecoration(
                        labelText: 'Optional nickname (e.g. StarLearner)',
                        isDense: true,
                        counterText: '',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    key: const ValueKey('leaderboard-save-privacy-btn'),
                    onPressed: _savingPrefs ? null : _savePrivacyPreferences,
                    child: Text(_savingPrefs ? 'Saving...' : 'Save'),
                  ),
                ],
              ),
              if (_statusMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  _statusMessage!,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF15803D),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Period & Subject Filters
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ChoiceChip(
              label: const Text('Weekly'),
              selected: _period == 'weekly',
              onSelected: (_) => setState(() => _period = 'weekly'),
            ),
            ChoiceChip(
              label: const Text('Monthly'),
              selected: _period == 'monthly',
              onSelected: (_) => setState(() => _period = 'monthly'),
            ),
            ChoiceChip(
              label: const Text('All Time'),
              selected: _period == 'all_time',
              onSelected: (_) => setState(() => _period = 'all_time'),
            ),
            if (widget.subjects.isNotEmpty)
              DropdownButton<String?>(
                value: _subjectId,
                hint: const Text('All subjects'),
                underline: const SizedBox.shrink(),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All subjects'),
                  ),
                  for (final s in widget.subjects)
                    DropdownMenuItem<String?>(
                      value: s.id,
                      child: Text(s.name),
                    ),
                ],
                onChanged: (val) => setState(() => _subjectId = val),
              ),
          ],
        ),
        const SizedBox(height: 14),
        leaderboardAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (_, _) => const Text('Could not load cohort rankings right now.'),
          data: (data) {
            if (data == null) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data.cohortLabel.isNotEmpty)
                  Text(
                    'Cohort: ${data.cohortLabel}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: const Color(0xFF475569),
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                if (data.myStanding != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0F2FE),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF0F4C81).withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '#${data.myStanding!.rank}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F4C81),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${data.myStanding!.displayLabel} (You)',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                data.myStanding!.isOptedIn
                                    ? 'Visible to your cohort'
                                    : 'Private — only visible to you & your parent',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF475569),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${data.myStanding!.xp} XP',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F4C81),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (data.entries.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: const Text(
                      'No learners have joined the public leaderboard for this cohort yet. Turn on Ranking Privacy Controls above to be the first!',
                    ),
                  )
                else
                  for (final entry in data.entries) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: entry.isCurrentLearner
                            ? const Color(0xFFF0F9FF)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: entry.isCurrentLearner
                              ? const Color(0xFF0F4C81)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 32,
                            child: Text(
                              '#${entry.rank}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: entry.rank <= 3
                                    ? const Color(0xFFD97706)
                                    : const Color(0xFF475569),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              entry.displayLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Text(
                            '${entry.xp} XP',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0F4C81),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            Icons.local_fire_department_rounded,
                            size: 15,
                            color: const Color(0xFFEA580C),
                          ),
                          Text(
                            '${entry.currentStreak}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
              ],
            );
          },
        ),
      ],
    );
  }
}

/// Parent Dashboard summary strip showing each child's verified XP, streaks, and recent badges
class ParentChildGamificationStrip extends StatelessWidget {
  const ParentChildGamificationStrip({required this.summary, super.key});

  final ParentChildGamificationSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              _MiniMetric(
                icon: Icons.bolt_rounded,
                color: const Color(0xFF0F4C81),
                label: '${summary.totalXp} XP (${summary.weeklyXp} this wk)',
              ),
              _MiniMetric(
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFEA580C),
                label: '${summary.currentStreak}d streak (best ${summary.longestStreak}d)',
              ),
              _MiniMetric(
                icon: Icons.emoji_events_rounded,
                color: const Color(0xFFD97706),
                label: '${summary.earnedBadgesCount} badges',
              ),
            ],
          ),
          if (summary.recentBadges.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final b in summary.recentBadges)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          gamificationBadgeIcon(b.iconName),
                          size: 13,
                          color: gamificationTierColor(b.tier),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          b.name,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF334155),
          ),
        ),
      ],
    );
  }
}
