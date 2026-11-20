import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:learntz/features/gamification/gamification_models.dart';
import 'package:learntz/features/gamification/gamification_providers.dart';
import 'package:learntz/features/gamification/gamification_repository.dart';
import 'package:learntz/features/gamification/widgets/gamification_widgets.dart';
import 'package:learntz/features/learning/learning_models.dart';

class _StubGamificationRepository implements GamificationRepository {
  _StubGamificationRepository({
    required this.overview,
    required this.leaderboard,
  });

  LearnerGamificationOverview overview;
  GamificationLeaderboardData leaderboard;
  bool? lastSavedOptIn;
  String? lastSavedAlias;

  @override
  Future<LearnerGamificationOverview> getLearnerOverview(String learnerId) async =>
      overview;

  @override
  Future<GamificationLeaderboardData> getLeaderboard({
    required String learnerId,
    String period = 'weekly',
    String? subjectId,
    int limit = 25,
  }) async =>
      leaderboard;

  @override
  Future<void> updatePreferences({
    required String learnerId,
    required bool leaderboardOptIn,
    String? leaderboardAlias,
    String? timezone,
  }) async {
    lastSavedOptIn = leaderboardOptIn;
    lastSavedAlias = leaderboardAlias;
  }

  @override
  Future<List<ParentChildGamificationSummary>> getParentChildrenSummary() async =>
      const [];
}

void main() {
  final sampleOverview = LearnerGamificationOverview(
    learnerId: 'learner-1',
    ageTier: GamificationAgeTier.primary,
    gradeName: 'Standard III',
    levelName: 'Primary',
    countryCode: 'TZ',
    timezone: 'Africa/Dar_es_Salaam',
    totalXp: 125,
    weeklyXp: 65,
    monthlyXp: 125,
    currentStreak: 4,
    longestStreak: 7,
    leaderboardOptIn: false,
    weeklyRank: 2,
    cohortParticipants: 12,
    weeklyCalendar: const [
      DailyActivityDay(date: '2026-11-14', dayLabel: 'Sat', isToday: false, isActive: false, xpEarned: 0, lessonsCompleted: 0),
      DailyActivityDay(date: '2026-11-15', dayLabel: 'Sun', isToday: false, isActive: false, xpEarned: 0, lessonsCompleted: 0),
      DailyActivityDay(date: '2026-11-16', dayLabel: 'Mon', isToday: false, isActive: false, xpEarned: 0, lessonsCompleted: 0),
      DailyActivityDay(date: '2026-11-17', dayLabel: 'Tue', isToday: false, isActive: true, xpEarned: 25, lessonsCompleted: 1),
      DailyActivityDay(date: '2026-11-18', dayLabel: 'Wed', isToday: false, isActive: true, xpEarned: 30, lessonsCompleted: 1),
      DailyActivityDay(date: '2026-11-19', dayLabel: 'Thu', isToday: false, isActive: true, xpEarned: 35, lessonsCompleted: 1),
      DailyActivityDay(date: '2026-11-20', dayLabel: 'Fri', isToday: true, isActive: true, xpEarned: 35, lessonsCompleted: 1),
    ],
    badges: [
      AchievementBadgeItem(
        badgeKey: 'first_lesson',
        name: 'First Step',
        description: 'Complete your first verified lesson on LearnTZ',
        category: 'learning',
        iconName: 'menu_book',
        tier: 'bronze',
        xpReward: 10,
        targetValue: 1,
        currentValue: 1,
        progressPercent: 100,
        status: 'earned',
        awardedAt: DateTime.utc(2026, 11, 17),
      ),
      const AchievementBadgeItem(
        badgeKey: 'lesson_explorer_5',
        name: 'Lesson Explorer',
        description: 'Complete 5 curriculum lessons',
        category: 'learning',
        iconName: 'auto_stories',
        tier: 'silver',
        xpReward: 25,
        targetValue: 5,
        currentValue: 3,
        progressPercent: 60,
        status: 'in_progress',
      ),
      const AchievementBadgeItem(
        badgeKey: 'exam_finisher',
        name: 'Exam Ready',
        description: 'Complete a verified practice examination',
        category: 'assessment',
        iconName: 'assignment_turned_in',
        tier: 'gold',
        xpReward: 50,
        targetValue: 1,
        currentValue: 0,
        progressPercent: 0,
        status: 'locked',
      ),
    ],
    recentNotifications: [
      BadgeNotificationItem(
        id: 'notif-1',
        title: 'Achievement Unlocked: First Step',
        body: 'Complete your first verified lesson on LearnTZ',
        isRead: false,
        createdAt: DateTime.utc(2026, 11, 20),
      ),
    ],
    recentXpEvents: const [
      XpLedgerEventItem(
        id: 'ev-1',
        eventType: 'lesson_completed',
        xpAmount: 25,
        activityDate: '2026-11-20',
        metadata: {'lesson_title': 'Naming People, Places and Things'},
      ),
    ],
  );

  const sampleLeaderboard = GamificationLeaderboardData(
    period: 'weekly',
    cohortLabel: 'Standard III · TZ',
    myStanding: LearnerLeaderboardStanding(
      rank: 2,
      displayLabel: 'Amina H.',
      xp: 65,
      currentStreak: 4,
      badgesCount: 1,
      isOptedIn: false,
    ),
    entries: [
      LeaderboardEntry(
        rank: 1,
        displayLabel: 'StarScholar',
        xp: 120,
        currentStreak: 6,
        badgesCount: 3,
        isCurrentLearner: false,
      ),
    ],
  );

  const sampleSubjects = [
    LearningSubject(
      id: 'subj-1',
      countryCode: 'TZ',
      curriculumId: 'curr-1',
      educationLevelId: 'lvl-1',
      code: 'eng',
      name: 'English Language',
      description: '',
      displayOrder: 1,
    ),
  ];

  test('Age-adaptive tiers return distinct presentation copy and styles', () {
    expect(GamificationAgeTier.fromApi('primary').style.badgeTitle, 'My Stars & Badges');
    expect(GamificationAgeTier.fromApi('o_level').style.badgeTitle, 'Achievements & Milestones');
    expect(GamificationAgeTier.fromApi('a_level').style.badgeTitle, 'Mastery Credentials');
  });

  testWidgets(
    'GamificationDashboardSection renders Streaks, XP & Badges, and Leaderboard on mobile (390x844) without overflow',
    (tester) async {
      final repo = _StubGamificationRepository(
        overview: sampleOverview,
        leaderboard: sampleLeaderboard,
      );

      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            gamificationRepositoryProvider.overrideWithValue(repo),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: GamificationDashboardSection(
                  learnerId: 'learner-1',
                  subjects: sampleSubjects,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // All 3 core pillars visible directly on dashboard
      expect(find.byKey(const ValueKey('gamification-streak-card')), findsOneWidget);
      expect(find.text('4 Days Streak'), findsOneWidget);
      expect(find.text('Best: 7 days'), findsOneWidget);

      expect(find.byKey(const ValueKey('gamification-xp-balance')), findsOneWidget);
      expect(find.text('125 XP'), findsOneWidget);
      expect(find.text('Next: Lesson Explorer'), findsOneWidget);

      expect(find.byKey(const ValueKey('gamification-leaderboard-card')), findsOneWidget);
      expect(find.text('Rank #2'), findsOneWidget);
      expect(find.text('Private mode'), findsOneWidget);

      // Open Badges dialog and check earned/in-progress/locked badges
      await tester.ensureVisible(find.byKey(const ValueKey('gamification-view-badges-btn')));
      await tester.tap(find.byKey(const ValueKey('gamification-view-badges-btn')));
      await tester.pumpAndSettle();
      expect(find.text('First Step'), findsOneWidget);
      expect(find.text('Lesson Explorer'), findsOneWidget);
      expect(find.text('Exam Ready'), findsOneWidget);
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Open Rankings & Privacy dialog and toggle opt-in
      await tester.ensureVisible(find.byKey(const ValueKey('gamification-open-leaderboard-btn')));
      await tester.tap(find.byKey(const ValueKey('gamification-open-leaderboard-btn')));
      await tester.pumpAndSettle();
      expect(find.text('Ranking Privacy Controls'), findsOneWidget);
      expect(find.text('StarScholar'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('leaderboard-privacy-switch')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('leaderboard-save-privacy-btn')));
      await tester.pumpAndSettle();
      expect(repo.lastSavedOptIn, isTrue);
    },
  );

  testWidgets('ParentChildGamificationStrip displays child XP, streaks, and recent badges', (tester) async {
    const summary = ParentChildGamificationSummary(
      learnerId: 'learner-1',
      fullName: 'Amina Hassan',
      totalXp: 240,
      weeklyXp: 90,
      currentStreak: 5,
      longestStreak: 9,
      leaderboardOptIn: true,
      earnedBadgesCount: 3,
      recentBadges: [
        ParentChildBadgePreview(
          badgeKey: 'first_lesson',
          name: 'First Step',
          tier: 'bronze',
          iconName: 'menu_book',
        ),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ParentChildGamificationStrip(summary: summary),
        ),
      ),
    );

    expect(find.text('240 XP (90 this wk)'), findsOneWidget);
    expect(find.text('5d streak (best 9d)'), findsOneWidget);
    expect(find.text('3 badges'), findsOneWidget);
    expect(find.text('First Step'), findsOneWidget);
  });
}
