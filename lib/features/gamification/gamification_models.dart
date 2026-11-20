import 'package:material_ui/material_ui.dart';

enum GamificationAgeTier {
  primary,
  oLevel,
  aLevel;

  static GamificationAgeTier fromApi(String? value) {
    switch (value) {
      case 'a_level':
        return GamificationAgeTier.aLevel;
      case 'o_level':
        return GamificationAgeTier.oLevel;
      default:
        return GamificationAgeTier.primary;
    }
  }

  /// Age-adaptive visual styling tokens:
  /// - Primary: colourful, friendly and encouraging
  /// - O-Level: modern, competitive and academically focused
  /// - A-Level: sophisticated, subject-oriented and mastery-focused
  GamificationTierStyle get style {
    switch (this) {
      case GamificationAgeTier.primary:
        return const GamificationTierStyle(
          streakAccent: Color(0xFFEA580C),
          streakTint: Color(0xFFFFF7ED),
          xpAccent: Color(0xFF0284C7),
          xpTint: Color(0xFFE0F2FE),
          rankAccent: Color(0xFF15803D),
          rankTint: Color(0xFFDCFCE7),
          badgeAccent: Color(0xFFD97706),
          badgeTint: Color(0xFFFEF3C7),
          encouragement: 'Keep your streak glowing!',
          rankLabel: 'Class Standings',
          badgeTitle: 'My Stars & Badges',
        );
      case GamificationAgeTier.oLevel:
        return const GamificationTierStyle(
          streakAccent: Color(0xFFD97706),
          streakTint: Color(0xFFFEF3C7),
          xpAccent: Color(0xFF0F4C81),
          xpTint: Color(0xFFE0F2FE),
          rankAccent: Color(0xFF0F766E),
          rankTint: Color(0xFFCCFBF1),
          badgeAccent: Color(0xFF4338CA),
          badgeTint: Color(0xFFE0E7FF),
          encouragement: 'Stay consistent and climb the rankings.',
          rankLabel: 'Cohort Leaderboard',
          badgeTitle: 'Achievements & Milestones',
        );
      case GamificationAgeTier.aLevel:
        return const GamificationTierStyle(
          streakAccent: Color(0xFF0F4C81),
          streakTint: Color(0xFFF1F5F9),
          xpAccent: Color(0xFF1E293B),
          xpTint: Color(0xFFF1F5F9),
          rankAccent: Color(0xFF0F4C81),
          rankTint: Color(0xFFEFF6FF),
          badgeAccent: Color(0xFF334155),
          badgeTint: Color(0xFFF1F5F9),
          encouragement: 'Sustained daily mastery builds exam readiness.',
          rankLabel: 'Subject & Cohort Rankings',
          badgeTitle: 'Mastery Credentials',
        );
    }
  }
}

class GamificationTierStyle {
  const GamificationTierStyle({
    required this.streakAccent,
    required this.streakTint,
    required this.xpAccent,
    required this.xpTint,
    required this.rankAccent,
    required this.rankTint,
    required this.badgeAccent,
    required this.badgeTint,
    required this.encouragement,
    required this.rankLabel,
    required this.badgeTitle,
  });

  final Color streakAccent;
  final Color streakTint;
  final Color xpAccent;
  final Color xpTint;
  final Color rankAccent;
  final Color rankTint;
  final Color badgeAccent;
  final Color badgeTint;
  final String encouragement;
  final String rankLabel;
  final String badgeTitle;
}

class DailyActivityDay {
  const DailyActivityDay({
    required this.date,
    required this.dayLabel,
    required this.isToday,
    required this.isActive,
    required this.xpEarned,
    required this.lessonsCompleted,
  });

  final String date;
  final String dayLabel;
  final bool isToday;
  final bool isActive;
  final int xpEarned;
  final int lessonsCompleted;

  factory DailyActivityDay.fromJson(Map<String, dynamic> json) {
    return DailyActivityDay(
      date: (json['date'] as String?) ?? '',
      dayLabel: (json['day_label'] as String?) ?? '',
      isToday: (json['is_today'] as bool?) ?? false,
      isActive: (json['is_active'] as bool?) ?? false,
      xpEarned: (json['xp_earned'] as num?)?.toInt() ?? 0,
      lessonsCompleted: (json['lessons_completed'] as num?)?.toInt() ?? 0,
    );
  }
}

class AchievementBadgeItem {
  const AchievementBadgeItem({
    required this.badgeKey,
    required this.name,
    required this.description,
    required this.category,
    required this.iconName,
    required this.tier,
    required this.xpReward,
    required this.targetValue,
    required this.currentValue,
    required this.progressPercent,
    required this.status,
    this.awardedAt,
  });

  final String badgeKey;
  final String name;
  final String description;
  final String category;
  final String iconName;
  final String tier;
  final int xpReward;
  final int targetValue;
  final int currentValue;
  final int progressPercent;
  final String status; // 'earned' | 'in_progress' | 'locked'
  final DateTime? awardedAt;

  bool get isEarned => status == 'earned';
  bool get isInProgress => status == 'in_progress';
  bool get isLocked => status == 'locked';

  factory AchievementBadgeItem.fromJson(Map<String, dynamic> json) {
    return AchievementBadgeItem(
      badgeKey: (json['badge_key'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      description: (json['description'] as String?) ?? '',
      category: (json['category'] as String?) ?? 'learning',
      iconName: (json['icon_name'] as String?) ?? 'stars',
      tier: (json['tier'] as String?) ?? 'bronze',
      xpReward: (json['xp_reward'] as num?)?.toInt() ?? 0,
      targetValue: (json['target_value'] as num?)?.toInt() ?? 1,
      currentValue: (json['current_value'] as num?)?.toInt() ?? 0,
      progressPercent: (json['progress_percent'] as num?)?.toInt() ?? 0,
      status: (json['status'] as String?) ?? 'locked',
      awardedAt: json['awarded_at'] != null
          ? DateTime.tryParse(json['awarded_at'].toString())
          : null,
    );
  }
}

class BadgeNotificationItem {
  const BadgeNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final bool isRead;
  final DateTime? createdAt;

  factory BadgeNotificationItem.fromJson(Map<String, dynamic> json) {
    return BadgeNotificationItem(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      body: (json['body'] as String?) ?? '',
      isRead: (json['is_read'] as bool?) ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

class XpLedgerEventItem {
  const XpLedgerEventItem({
    required this.id,
    required this.eventType,
    required this.xpAmount,
    required this.activityDate,
    this.metadata = const {},
    this.createdAt,
  });

  final String id;
  final String eventType;
  final int xpAmount;
  final String activityDate;
  final Map<String, dynamic> metadata;
  final DateTime? createdAt;

  String get displayLabel {
    switch (eventType) {
      case 'lesson_completed':
        return 'Completed lesson${metadata['lesson_title'] != null ? ': ${metadata['lesson_title']}' : ''}';
      case 'quiz_passed':
        return 'Passed lesson quiz';
      case 'quiz_perfect_bonus':
        return 'Perfect 100% score bonus';
      case 'assessment_passed':
        return 'Passed topic practice';
      case 'exam_completed':
        return 'Completed exam${metadata['exam_title'] != null ? ': ${metadata['exam_title']}' : ''}';
      case 'badge_reward':
        return 'Badge unlocked${metadata['badge_name'] != null ? ': ${metadata['badge_name']}' : ''}';
      default:
        return 'Verified learning activity';
    }
  }

  factory XpLedgerEventItem.fromJson(Map<String, dynamic> json) {
    return XpLedgerEventItem(
      id: (json['id'] as String?) ?? '',
      eventType: (json['event_type'] as String?) ?? '',
      xpAmount: (json['xp_amount'] as num?)?.toInt() ?? 0,
      activityDate: (json['activity_date'] as String?) ?? '',
      metadata: json['metadata'] is Map
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : const {},
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

class LearnerGamificationOverview {
  const LearnerGamificationOverview({
    required this.learnerId,
    required this.ageTier,
    required this.countryCode,
    required this.timezone,
    required this.totalXp,
    required this.weeklyXp,
    required this.monthlyXp,
    required this.currentStreak,
    required this.longestStreak,
    required this.leaderboardOptIn,
    required this.cohortParticipants,
    required this.weeklyCalendar,
    required this.badges,
    required this.recentNotifications,
    required this.recentXpEvents,
    this.gradeName,
    this.levelName,
    this.leaderboardAlias,
    this.weeklyRank,
  });

  final String learnerId;
  final GamificationAgeTier ageTier;
  final String? gradeName;
  final String? levelName;
  final String countryCode;
  final String timezone;
  final int totalXp;
  final int weeklyXp;
  final int monthlyXp;
  final int currentStreak;
  final int longestStreak;
  final bool leaderboardOptIn;
  final String? leaderboardAlias;
  final int? weeklyRank;
  final int cohortParticipants;
  final List<DailyActivityDay> weeklyCalendar;
  final List<AchievementBadgeItem> badges;
  final List<BadgeNotificationItem> recentNotifications;
  final List<XpLedgerEventItem> recentXpEvents;

  int get earnedBadgesCount => badges.where((b) => b.isEarned).length;

  factory LearnerGamificationOverview.fromJson(Map<String, dynamic> json) {
    final calRaw = (json['weekly_calendar'] as List?) ?? const [];
    final badgesRaw = (json['badges'] as List?) ?? const [];
    final notifRaw = (json['recent_notifications'] as List?) ?? const [];
    final eventsRaw = (json['recent_xp_events'] as List?) ?? const [];

    return LearnerGamificationOverview(
      learnerId: (json['learner_id'] as String?) ?? '',
      ageTier: GamificationAgeTier.fromApi(json['age_tier'] as String?),
      gradeName: json['grade_name'] as String?,
      levelName: json['level_name'] as String?,
      countryCode: (json['country_code'] as String?) ?? 'TZ',
      timezone: (json['timezone'] as String?) ?? 'Africa/Dar_es_Salaam',
      totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
      weeklyXp: (json['weekly_xp'] as num?)?.toInt() ?? 0,
      monthlyXp: (json['monthly_xp'] as num?)?.toInt() ?? 0,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
      leaderboardOptIn: (json['leaderboard_opt_in'] as bool?) ?? false,
      leaderboardAlias: json['leaderboard_alias'] as String?,
      weeklyRank: (json['weekly_rank'] as num?)?.toInt(),
      cohortParticipants: (json['cohort_participants'] as num?)?.toInt() ?? 0,
      weeklyCalendar: calRaw
          .map((e) => DailyActivityDay.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      badges: badgesRaw
          .map((e) => AchievementBadgeItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      recentNotifications: notifRaw
          .map((e) => BadgeNotificationItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      recentXpEvents: eventsRaw
          .map((e) => XpLedgerEventItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.displayLabel,
    required this.xp,
    required this.currentStreak,
    required this.badgesCount,
    required this.isCurrentLearner,
  });

  final int rank;
  final String displayLabel;
  final int xp;
  final int currentStreak;
  final int badgesCount;
  final bool isCurrentLearner;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      displayLabel: (json['display_label'] as String?) ?? 'Learner',
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      badgesCount: (json['badges_count'] as num?)?.toInt() ?? 0,
      isCurrentLearner: (json['is_current_learner'] as bool?) ?? false,
    );
  }
}

class LearnerLeaderboardStanding {
  const LearnerLeaderboardStanding({
    required this.rank,
    required this.displayLabel,
    required this.xp,
    required this.currentStreak,
    required this.badgesCount,
    required this.isOptedIn,
  });

  final int rank;
  final String displayLabel;
  final int xp;
  final int currentStreak;
  final int badgesCount;
  final bool isOptedIn;

  factory LearnerLeaderboardStanding.fromJson(Map<String, dynamic> json) {
    return LearnerLeaderboardStanding(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      displayLabel: (json['display_label'] as String?) ?? 'You',
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      badgesCount: (json['badges_count'] as num?)?.toInt() ?? 0,
      isOptedIn: (json['is_opted_in'] as bool?) ?? false,
    );
  }
}

class GamificationLeaderboardData {
  const GamificationLeaderboardData({
    required this.period,
    required this.cohortLabel,
    required this.entries,
    this.subjectId,
    this.myStanding,
  });

  final String period;
  final String? subjectId;
  final String cohortLabel;
  final LearnerLeaderboardStanding? myStanding;
  final List<LeaderboardEntry> entries;

  factory GamificationLeaderboardData.fromJson(Map<String, dynamic> json) {
    final entriesRaw = (json['entries'] as List?) ?? const [];
    return GamificationLeaderboardData(
      period: (json['period'] as String?) ?? 'weekly',
      subjectId: json['subject_id'] as String?,
      cohortLabel: (json['cohort_label'] as String?) ?? '',
      myStanding: json['my_standing'] is Map
          ? LearnerLeaderboardStanding.fromJson(
              Map<String, dynamic>.from(json['my_standing'] as Map),
            )
          : null,
      entries: entriesRaw
          .map((e) => LeaderboardEntry.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}

class ParentChildBadgePreview {
  const ParentChildBadgePreview({
    required this.badgeKey,
    required this.name,
    required this.tier,
    required this.iconName,
    this.awardedAt,
  });

  final String badgeKey;
  final String name;
  final String tier;
  final String iconName;
  final DateTime? awardedAt;

  factory ParentChildBadgePreview.fromJson(Map<String, dynamic> json) {
    return ParentChildBadgePreview(
      badgeKey: (json['badge_key'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      tier: (json['tier'] as String?) ?? 'bronze',
      iconName: (json['icon_name'] as String?) ?? 'stars',
      awardedAt: json['awarded_at'] != null
          ? DateTime.tryParse(json['awarded_at'].toString())
          : null,
    );
  }
}

class ParentChildGamificationSummary {
  const ParentChildGamificationSummary({
    required this.learnerId,
    required this.fullName,
    required this.totalXp,
    required this.weeklyXp,
    required this.currentStreak,
    required this.longestStreak,
    required this.leaderboardOptIn,
    required this.earnedBadgesCount,
    required this.recentBadges,
    this.lastActiveDate,
  });

  final String learnerId;
  final String fullName;
  final int totalXp;
  final int weeklyXp;
  final int currentStreak;
  final int longestStreak;
  final bool leaderboardOptIn;
  final int earnedBadgesCount;
  final List<ParentChildBadgePreview> recentBadges;
  final String? lastActiveDate;

  factory ParentChildGamificationSummary.fromJson(Map<String, dynamic> json) {
    final badgesRaw = (json['recent_badges'] as List?) ?? const [];
    return ParentChildGamificationSummary(
      learnerId: (json['learner_id'] as String?) ?? '',
      fullName: (json['full_name'] as String?) ?? '',
      totalXp: (json['total_xp'] as num?)?.toInt() ?? 0,
      weeklyXp: (json['weekly_xp'] as num?)?.toInt() ?? 0,
      currentStreak: (json['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (json['longest_streak'] as num?)?.toInt() ?? 0,
      leaderboardOptIn: (json['leaderboard_opt_in'] as bool?) ?? false,
      earnedBadgesCount: (json['earned_badges_count'] as num?)?.toInt() ?? 0,
      lastActiveDate: json['last_active_date']?.toString(),
      recentBadges: badgesRaw
          .map((e) => ParentChildBadgePreview.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }
}
