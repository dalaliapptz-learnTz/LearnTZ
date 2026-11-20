import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/tokens/design_tokens.dart';
import '../../core/routing/app_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../auth/auth_screens.dart';
import '../gamification/gamification_providers.dart';
import '../gamification/widgets/gamification_widgets.dart';
import '../learners/learner_providers.dart';
import 'learning_models.dart';
import 'learning_providers.dart';

class MasteryProgressBar extends StatelessWidget {
  const MasteryProgressBar({required this.summary, super.key});

  final LearnerLearningSummary summary;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ratio = (summary.masteryPercent.clamp(0, 100)) / 100.0;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.learningMasteryTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                '${summary.masteryPercent}%',
                key: const ValueKey('mastery-percent-label'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            key: const ValueKey('mastery-progress-indicator'),
            value: ratio,
            minHeight: 10,
            borderRadius: BorderRadius.circular(8),
          ),
          const SizedBox(height: 10),
          Text(
            l10n.learningMasteryStats(
              summary.completedLessons,
              summary.totalLessons,
              summary.averageQuizScorePercent,
            ),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

enum _LearnerHubTab { home, subjects, practice, profile }

class _ResolvedContinueLesson {
  const _ResolvedContinueLesson({
    required this.lessonId,
    required this.subjectName,
    required this.lessonTitle,
    this.topicTitle,
    this.estimatedMinutes,
    this.progressPercent = 0,
  });

  final String lessonId;
  final String subjectName;
  final String lessonTitle;
  final String? topicTitle;
  final int? estimatedMinutes;
  final int progressPercent;
}

class LearningHubScreen extends ConsumerStatefulWidget {
  const LearningHubScreen({super.key});

  @override
  ConsumerState<LearningHubScreen> createState() => _LearningHubScreenState();
}

class _LearningHubScreenState extends ConsumerState<LearningHubScreen> {
  _LearnerHubTab _selectedTab = _LearnerHubTab.home;

  void _selectTab(_LearnerHubTab tab) {
    if (_selectedTab == tab) return;
    setState(() => _selectedTab = tab);
  }

  _ResolvedContinueLesson? _resolveContinueLesson(
    LearningCatalogBundle? bundle,
    LearnerDashboardData? dashboard,
  ) {
    final resume = dashboard?.resumeLesson;
    if (resume != null) {
      return _ResolvedContinueLesson(
        lessonId: resume.lessonId,
        subjectName: resume.subjectName,
        lessonTitle: resume.lessonTitle,
        progressPercent: resume.readingProgressPercent,
      );
    }
    if (bundle == null) return null;

    _ResolvedContinueLesson? firstNotStarted;
    _ResolvedContinueLesson? firstAny;

    for (final subject in bundle.subjects) {
      final topics = bundle.topicsBySubject[subject.id] ?? const <LearningTopic>[];
      for (final topic in topics) {
        final lessons = bundle.lessonsByTopic[topic.id] ?? const <LearningLesson>[];
        for (final lesson in lessons) {
          final progress = bundle.progressByLesson[lesson.id];
          final candidate = _ResolvedContinueLesson(
            lessonId: lesson.id,
            subjectName: subject.name,
            lessonTitle: lesson.title,
            topicTitle: topic.title,
            estimatedMinutes: lesson.estimatedMinutes,
            progressPercent: progress?.readingProgressPercent ?? 0,
          );
          firstAny ??= candidate;
          if (progress != null && progress.status == 'in_progress') {
            return candidate;
          }
          if (progress == null || !progress.isCompleted) {
            firstNotStarted ??= candidate;
          }
        }
      }
    }

    return firstNotStarted ?? firstAny;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeLearner = ref.watch(activeLearnerProvider);

    if (activeLearner == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.learningHubTitle,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose a learner profile to start learning.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF475569),
                      ),
                ),
                const SizedBox(height: 20),
                _SelectLearnerPrompt(),
              ],
            ),
          ),
        ),
      );
    }

    final catalogAsync = ref.watch(activeLearnerLearningCatalogProvider);
    final dashboardAsync = ref.watch(learnerDashboardDataProvider(activeLearner.id));
    final dashboard = dashboardAsync.asData?.value;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 680;

    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 24,
              vertical: isMobile ? 16 : 24,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 920),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _LearnerGreetingHeader(
                      firstName: activeLearner.firstName,
                      fullName: activeLearner.fullName,
                      gradeLabel: dashboard?.gradeName,
                      countryCode: activeLearner.countryCode,
                      onSwitchLearner: () =>
                          ref.read(activeLearnerProvider.notifier).clear(),
                    ),
                    if (!isMobile) ...[
                      const SizedBox(height: 16),
                      _LearnerHubDesktopNav(
                        selectedTab: _selectedTab,
                        onSelect: _selectTab,
                      ),
                    ],
                    const SizedBox(height: 20),
                    catalogAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                      error: (_, _) => AuthInlineMessage(
                        message: l10n.requestFailed,
                        isError: true,
                      ),
                      data: (bundle) {
                        switch (_selectedTab) {
                          case _LearnerHubTab.home:
                            return _LearnerHomeTab(
                              learnerId: activeLearner.id,
                              bundle: bundle,
                              dashboard: dashboard,
                              continueLesson: _resolveContinueLesson(bundle, dashboard),
                              isMobile: isMobile,
                              onOpenSubjects: () => _selectTab(_LearnerHubTab.subjects),
                              onOpenPractice: () => _selectTab(_LearnerHubTab.practice),
                              onOpenProgress: () => _selectTab(_LearnerHubTab.profile),
                              onOpenSaved: () => context.go(AppRoutes.resourceLibrary),
                            );
                          case _LearnerHubTab.subjects:
                            return _LearnerSubjectsTab(
                              bundle: bundle,
                              gradeLabel: dashboard?.gradeName,
                              countryCode: activeLearner.countryCode,
                            );
                          case _LearnerHubTab.practice:
                            return _LearnerPracticeTab(
                              learnerId: activeLearner.id,
                            );
                          case _LearnerHubTab.profile:
                            return _LearnerProfileTab(
                              learnerId: activeLearner.id,
                              fullName: activeLearner.fullName,
                              gradeLabel: dashboard?.gradeName,
                              countryCode: activeLearner.countryCode,
                              bundle: bundle,
                              dashboard: dashboard,
                              onSwitchLearner: () =>
                                  ref.read(activeLearnerProvider.notifier).clear(),
                            );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (isMobile)
          _LearnerHubBottomNav(
            selectedTab: _selectedTab,
            onSelect: _selectTab,
          ),
      ],
    );
  }
}

class _LearnerGreetingHeader extends StatelessWidget {
  const _LearnerGreetingHeader({
    required this.firstName,
    required this.fullName,
    required this.gradeLabel,
    required this.countryCode,
    required this.onSwitchLearner,
  });

  final String firstName;
  final String fullName;
  final String? gradeLabel;
  final String countryCode;
  final VoidCallback onSwitchLearner;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cleanFirst = firstName.trim().isNotEmpty ? firstName.trim() : fullName;

    final greeting = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Hello, $cleanFirst!',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          "Let's continue learning today.",
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: const Color(0xFF475569),
              ),
        ),
      ],
    );

    Widget buildLearnerPill({required bool expandFullWidth}) {
      final nameColumn = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                  height: 1.2,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            gradeLabel != null && gradeLabel!.isNotEmpty
                ? '$gradeLabel · $countryCode'
                : countryCode,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF64748B),
                  height: 1.2,
                ),
          ),
        ],
      );

      return Container(
        width: expandFullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          mainAxisSize: expandFullWidth ? MainAxisSize.max : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 17,
              backgroundColor: const Color(0xFFE0F2FE),
              child: Text(
                cleanFirst.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  color: Color(0xFF0F4C81),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (expandFullWidth)
              Expanded(child: nameColumn)
            else
              Flexible(child: nameColumn),
            const SizedBox(width: 10),
            TextButton(
              onPressed: onSwitchLearner,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF0F4C81),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
              child: Text(l10n.switchLearnerAction),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 640) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              greeting,
              const SizedBox(height: 12),
              buildLearnerPill(expandFullWidth: true),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: greeting),
            const SizedBox(width: 16),
            buildLearnerPill(expandFullWidth: false),
          ],
        );
      },
    );
  }
}

class _LearnerHubDesktopNav extends StatelessWidget {
  const _LearnerHubDesktopNav({
    required this.selectedTab,
    required this.onSelect,
  });

  final _LearnerHubTab selectedTab;
  final ValueChanged<_LearnerHubTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final items = <(
      _LearnerHubTab tab,
      String label,
      IconData icon,
      IconData activeIcon,
    )>[
      (_LearnerHubTab.home, 'Home', Icons.home_outlined, Icons.home_rounded),
      (
        _LearnerHubTab.subjects,
        'Subjects',
        Icons.menu_book_outlined,
        Icons.menu_book_rounded,
      ),
      (
        _LearnerHubTab.practice,
        'Practice',
        Icons.quiz_outlined,
        Icons.quiz_rounded,
      ),
      (
        _LearnerHubTab.profile,
        'Profile',
        Icons.person_outline_rounded,
        Icons.person_rounded,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          for (final item in items)
            Expanded(
              child: InkWell(
                key: ValueKey('learner-nav-${item.$1.name}'),
                onTap: () => onSelect(item.$1),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: selectedTab == item.$1
                        ? const Color(0xFF0F4C81)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        selectedTab == item.$1 ? item.$4 : item.$3,
                        size: 18,
                        color: selectedTab == item.$1
                            ? Colors.white
                            : const Color(0xFF475569),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.$2,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: selectedTab == item.$1
                              ? Colors.white
                              : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _LearnerHubBottomNav extends StatelessWidget {
  const _LearnerHubBottomNav({
    required this.selectedTab,
    required this.onSelect,
  });

  final _LearnerHubTab selectedTab;
  final ValueChanged<_LearnerHubTab> onSelect;

  @override
  Widget build(BuildContext context) {
    final items = <(
      _LearnerHubTab tab,
      String label,
      IconData icon,
      IconData activeIcon,
    )>[
      (_LearnerHubTab.home, 'Home', Icons.home_outlined, Icons.home_rounded),
      (
        _LearnerHubTab.subjects,
        'Subjects',
        Icons.menu_book_outlined,
        Icons.menu_book_rounded,
      ),
      (
        _LearnerHubTab.practice,
        'Practice',
        Icons.quiz_outlined,
        Icons.quiz_rounded,
      ),
      (
        _LearnerHubTab.profile,
        'Profile',
        Icons.person_outline_rounded,
        Icons.person_rounded,
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            for (final item in items)
              Expanded(
                child: InkWell(
                  key: ValueKey('learner-nav-${item.$1.name}'),
                  onTap: () => onSelect(item.$1),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selectedTab == item.$1 ? item.$4 : item.$3,
                          size: 22,
                          color: selectedTab == item.$1
                              ? const Color(0xFF0F4C81)
                              : const Color(0xFF64748B),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.$2,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selectedTab == item.$1
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selectedTab == item.$1
                                ? const Color(0xFF0F4C81)
                                : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _LearnerHomeTab extends StatelessWidget {
  const _LearnerHomeTab({
    required this.learnerId,
    required this.bundle,
    required this.dashboard,
    required this.continueLesson,
    required this.isMobile,
    required this.onOpenSubjects,
    required this.onOpenPractice,
    required this.onOpenProgress,
    required this.onOpenSaved,
  });

  final String learnerId;
  final LearningCatalogBundle? bundle;
  final LearnerDashboardData? dashboard;
  final _ResolvedContinueLesson? continueLesson;
  final bool isMobile;
  final VoidCallback onOpenSubjects;
  final VoidCallback onOpenPractice;
  final VoidCallback onOpenProgress;
  final VoidCallback onOpenSaved;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ContinueLearningHeroCard(
          lesson: continueLesson,
          gradeLabel: dashboard?.gradeName,
          onOpenSubjects: onOpenSubjects,
        ),
        const SizedBox(height: 20),
        // Gamification System 2.0: Learning Streaks, Verified XP & Badges, Leaderboards
        GamificationDashboardSection(
          learnerId: learnerId,
          subjects: bundle?.subjects ?? const [],
        ),
        const SizedBox(height: 24),
        Text(
          'My Learning',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final crossAxisCount = constraints.maxWidth >= 680 ? 4 : 2;
            const spacing = 12.0;
            final cardWidth =
                (constraints.maxWidth - (spacing * (crossAxisCount - 1))) /
                    crossAxisCount;

            final tiles = <Widget>[
              _LearningDestinationTile(
                key: const ValueKey('hub-tile-subjects'),
                title: 'My Subjects',
                subtitle: 'Explore lessons',
                icon: Icons.menu_book_rounded,
                accentColor: const Color(0xFF0F4C81),
                tintColor: const Color(0xFFE0F2FE),
                onTap: onOpenSubjects,
              ),
              _LearningDestinationTile(
                key: const ValueKey('hub-tile-practice'),
                title: 'Practice',
                subtitle: 'Test your knowledge',
                icon: Icons.quiz_rounded,
                accentColor: const Color(0xFF15803D),
                tintColor: const Color(0xFFDCFCE7),
                onTap: onOpenPractice,
              ),
              _LearningDestinationTile(
                key: const ValueKey('hub-tile-progress'),
                title: 'My Progress',
                subtitle: 'See your improvement',
                icon: Icons.trending_up_rounded,
                accentColor: const Color(0xFFB45309),
                tintColor: const Color(0xFFFEF3C7),
                onTap: onOpenProgress,
              ),
              _LearningDestinationTile(
                key: const ValueKey('hub-tile-saved'),
                title: 'Saved Lessons',
                subtitle: 'Learn again anytime',
                icon: Icons.bookmark_rounded,
                accentColor: const Color(0xFF4338CA),
                tintColor: const Color(0xFFE0E7FF),
                onTap: onOpenSaved,
              ),
            ];

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final tile in tiles)
                  SizedBox(width: cardWidth, child: tile),
              ],
            );
          },
        ),
        if (bundle != null) ...[
          const SizedBox(height: 24),
          MasteryProgressBar(summary: bundle!.summary),
        ],
        if (dashboard != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      size: 20,
                      color: Color(0xFFF59E0B),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Today: ${dashboard!.todayCompletedLessons}/${dashboard!.dailyTargetLessons} lessons',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0F172A),
                          ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.local_fire_department_rounded,
                        size: 16,
                        color: Color(0xFFEA580C),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${dashboard!.streakDays} day streak',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF9A3412),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ContinueLearningHeroCard extends StatelessWidget {
  const _ContinueLearningHeroCard({
    required this.lesson,
    required this.gradeLabel,
    required this.onOpenSubjects,
  });

  final _ResolvedContinueLesson? lesson;
  final String? gradeLabel;
  final VoidCallback onOpenSubjects;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F4C81), Color(0xFF1D63A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F4C81).withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: lesson == null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroPill(label: 'START LEARNING'),
                const SizedBox(height: 12),
                const Text(
                  'Explore your subjects',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pick a subject to start your first lesson today.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onOpenSubjects,
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F4C81),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.menu_book_rounded, size: 18),
                  label: const Text(
                    'Browse subjects',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroPill(label: 'CONTINUE LEARNING'),
                const SizedBox(height: 12),
                Text(
                  lesson!.subjectName,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  lesson!.lessonTitle,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 10,
                  runSpacing: 6,
                  children: [
                    if (gradeLabel != null && gradeLabel!.isNotEmpty)
                      Text(
                        gradeLabel!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 13,
                        ),
                      ),
                    if (lesson!.estimatedMinutes != null)
                      Text(
                        '${lesson!.estimatedMinutes} min',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 13,
                        ),
                      ),
                    if (lesson!.progressPercent > 0)
                      Text(
                        '${lesson!.progressPercent}% complete',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
                if (lesson!.progressPercent > 0) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (lesson!.progressPercent.clamp(0, 100)) / 100.0,
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.24),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF4ADE80),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton.icon(
                  key: const ValueKey('continue-learning-cta'),
                  onPressed: () =>
                      context.go(AppRoutes.lessonReader(lesson!.lessonId)),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF0F4C81),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text(
                    'Continue lesson',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  const _HeroPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _LearningDestinationTile extends StatelessWidget {
  const _LearningDestinationTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.tintColor,
    required this.onTap,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color tintColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: tintColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF64748B),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LearnerSubjectsTab extends StatelessWidget {
  const _LearnerSubjectsTab({
    required this.bundle,
    required this.gradeLabel,
    required this.countryCode,
  });

  final LearningCatalogBundle? bundle;
  final String? gradeLabel;
  final String countryCode;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (bundle == null || bundle!.subjects.isEmpty) {
      return AppCard(child: Text(l10n.noSubjectsPublished));
    }

    // Put subjects with available lessons first so learners immediately see actionable lessons.
    final sortedSubjects = [...bundle!.subjects]..sort((a, b) {
      final aCount = _countSubjectLessons(a.id, bundle!);
      final bCount = _countSubjectLessons(b.id, bundle!);
      if (aCount > 0 && bCount == 0) return -1;
      if (aCount == 0 && bCount > 0) return 1;
      return a.displayOrder.compareTo(b.displayOrder);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'My Subjects',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    gradeLabel != null && gradeLabel!.isNotEmpty
                        ? 'Your lessons for $gradeLabel ($countryCode)'
                        : 'Select a subject to open its lessons.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: const Color(0xFF64748B),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < sortedSubjects.length; i++) ...[
          _SubjectSectionCard(
            subject: sortedSubjects[i],
            topics: bundle!.topicsBySubject[sortedSubjects[i].id] ?? const [],
            lessonsByTopic: bundle!.lessonsByTopic,
            progressByLesson: bundle!.progressByLesson,
            initiallyExpanded:
                i == 0 && _countSubjectLessons(sortedSubjects[i].id, bundle!) > 0,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  int _countSubjectLessons(String subjectId, LearningCatalogBundle bundle) {
    var count = 0;
    final topics = bundle.topicsBySubject[subjectId] ?? const <LearningTopic>[];
    for (final topic in topics) {
      count += (bundle.lessonsByTopic[topic.id] ?? const <LearningLesson>[]).length;
    }
    return count;
  }
}

class _LearnerPracticeTab extends StatelessWidget {
  const _LearnerPracticeTab({required this.learnerId});

  final String learnerId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Practice',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
        ),
        const SizedBox(height: 4),
        Text(
          'Test your knowledge, revise weak topics, and prepare for exams.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: const Color(0xFF64748B),
              ),
        ),
        const SizedBox(height: 16),
        _PracticeActionCard(
          title: 'Revision & Flashcards',
          subtitle: 'Review key concepts and strengthen topics you need help with.',
          icon: Icons.style_rounded,
          accentColor: const Color(0xFF15803D),
          tintColor: const Color(0xFFDCFCE7),
          actionLabel: 'Start revision',
          onTap: () => context.go(AppRoutes.revisionCentre),
        ),
        const SizedBox(height: 12),
        _PracticeActionCard(
          title: 'Practice Examinations',
          subtitle: 'Take timed practice papers and get instant scores.',
          icon: Icons.school_rounded,
          accentColor: const Color(0xFF0F4C81),
          tintColor: const Color(0xFFE0F2FE),
          actionLabel: 'Open exams',
          onTap: () => context.go(AppRoutes.examCentre),
        ),
        const SizedBox(height: 12),
        _PracticeActionCard(
          title: 'Academic Challenges',
          subtitle: 'Join friendly subject quizzes and earn badges.',
          icon: Icons.emoji_events_rounded,
          accentColor: const Color(0xFFB45309),
          tintColor: const Color(0xFFFEF3C7),
          actionLabel: 'View challenges',
          onTap: () => context.go(AppRoutes.challenges),
        ),
        const SizedBox(height: 20),
        _LearnerRecommendationsSection(learnerId: learnerId),
      ],
    );
  }
}

class _PracticeActionCard extends StatelessWidget {
  const _PracticeActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.tintColor,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Color tintColor;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isCompact = constraints.maxWidth < 460;
          final headerRow = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: tintColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                    ),
                  ],
                ),
              ),
              if (!isCompact) ...[
                const SizedBox(width: 12),
                FilledButton.tonal(
                  onPressed: onTap,
                  child: Text(actionLabel),
                ),
              ],
            ],
          );

          if (!isCompact) return headerRow;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              headerRow,
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: onTap,
                  child: Text(actionLabel),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LearnerProfileTab extends ConsumerWidget {
  const _LearnerProfileTab({
    required this.learnerId,
    required this.fullName,
    required this.gradeLabel,
    required this.countryCode,
    required this.bundle,
    required this.dashboard,
    required this.onSwitchLearner,
  });

  final String learnerId;
  final String fullName;
  final String? gradeLabel;
  final String countryCode;
  final LearningCatalogBundle? bundle;
  final LearnerDashboardData? dashboard;
  final VoidCallback onSwitchLearner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final gamificationAsync =
        ref.watch(learnerGamificationOverviewProvider(learnerId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Progress & Profile',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: const Color(0xFF0F172A),
              ),
        ),
        const SizedBox(height: 12),
        if (bundle != null) ...[
          MasteryProgressBar(summary: bundle!.summary),
          const SizedBox(height: 16),
        ],
        gamificationAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
          data: (overview) {
            if (overview == null) return const SizedBox.shrink();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        overview.ageTier.style.badgeTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 12),
                      BadgesCollectionView(overview: overview),
                    ],
                  ),
                ),
                if (overview.recentXpEvents.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Verified XP Activity',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 8),
                        for (final ev in overview.recentXpEvents.take(5))
                          ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.bolt_rounded,
                              size: 18,
                              color: Color(0xFF0F4C81),
                            ),
                            title: Text(ev.displayLabel),
                            subtitle: Text(ev.activityDate),
                            trailing: Text(
                              '+${ev.xpAmount} XP',
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),
              ],
            );
          },
        ),
        _LearnerMasteryOverviewSection(learnerId: learnerId),
        const SizedBox(height: 16),
        _OfflineSyncStatusBar(learnerId: learnerId),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.badge_outlined, color: Color(0xFF0F4C81)),
                title: const Text('Academic Profile & Badges'),
                subtitle: Text(
                  gradeLabel != null && gradeLabel!.isNotEmpty
                      ? '$fullName · $gradeLabel ($countryCode)'
                      : '$fullName · $countryCode',
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: () => context.go(AppRoutes.socialProfile),
              ),
              const Divider(height: 1),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF475569)),
                title: Text(l10n.switchLearnerAction),
                subtitle: const Text('Switch to another learner profile on this device'),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: onSwitchLearner,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SelectLearnerPrompt extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final learnersAsync = ref.watch(parentLearnersProvider);
    return learnersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          AuthInlineMessage(message: l10n.requestFailed, isError: true),
      data: (learners) {
        if (learners.isEmpty) {
          return AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.noLearnersTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(l10n.noLearnersDescription),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => context.go(AppRoutes.addLearner),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: Text(l10n.addLearnerAction),
                ),
              ],
            ),
          );
        }
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.selectActiveLearnerTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final learner in learners)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: Text(learner.fullName),
                  subtitle: Text(learner.countryCode),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => ref
                      .read(activeLearnerProvider.notifier)
                      .select(learner.id),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _SubjectSectionCard extends StatefulWidget {
  const _SubjectSectionCard({
    required this.subject,
    required this.topics,
    required this.lessonsByTopic,
    required this.progressByLesson,
    this.initiallyExpanded = false,
  });

  final LearningSubject subject;
  final List<LearningTopic> topics;
  final Map<String, List<LearningLesson>> lessonsByTopic;
  final Map<String, LearnerProgressRecord> progressByLesson;
  final bool initiallyExpanded;

  @override
  State<_SubjectSectionCard> createState() => _SubjectSectionCardState();
}

class _SubjectSectionCardState extends State<_SubjectSectionCard> {
  late bool _expanded = widget.initiallyExpanded;

  (IconData icon, Color accent, Color tint) _subjectVisual(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('math') || lower.contains('hisabati')) {
      return (Icons.calculate_rounded, const Color(0xFF0F4C81), const Color(0xFFE0F2FE));
    }
    if (lower.contains('science') || lower.contains('sayansi')) {
      return (Icons.science_rounded, const Color(0xFF15803D), const Color(0xFFDCFCE7));
    }
    if (lower.contains('english')) {
      return (Icons.menu_book_rounded, const Color(0xFFB45309), const Color(0xFFFEF3C7));
    }
    if (lower.contains('kiswahili') || lower.contains('kusoma')) {
      return (Icons.auto_stories_rounded, const Color(0xFF0F766E), const Color(0xFFCCFBF1));
    }
    return (Icons.school_rounded, const Color(0xFF4338CA), const Color(0xFFE0E7FF));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final visual = _subjectVisual(widget.subject.name);

    var totalLessons = 0;
    var completedLessons = 0;
    for (final topic in widget.topics) {
      final lessons = widget.lessonsByTopic[topic.id] ?? const <LearningLesson>[];
      totalLessons += lessons.length;
      for (final lesson in lessons) {
        if (widget.progressByLesson[lesson.id]?.isCompleted ?? false) {
          completedLessons++;
        }
      }
    }
    final percent = totalLessons == 0
        ? 0
        : ((completedLessons / totalLessons) * 100).round();

    final topicsWithLessons = widget.topics
        .where((t) => (widget.lessonsByTopic[t.id] ?? const []).isNotEmpty)
        .toList();
    final upcomingTopics = widget.topics
        .where((t) => (widget.lessonsByTopic[t.id] ?? const []).isEmpty)
        .toList();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: visual.$3,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(visual.$1, color: visual.$2, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.subject.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        totalLessons > 0
                            ? '$totalLessons ${totalLessons == 1 ? 'lesson' : 'lessons'} · $percent% completed'
                            : '${widget.topics.length} ${widget.topics.length == 1 ? 'topic' : 'topics'} · Lessons coming soon',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: const Color(0xFF64748B),
                            ),
                      ),
                      if (totalLessons > 0) ...[
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: completedLessons / totalLessons,
                            minHeight: 5,
                            backgroundColor: const Color(0xFFE2E8F0),
                            valueColor: AlwaysStoppedAnimation<Color>(visual.$2),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFF64748B),
                ),
              ],
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 14),
            const Divider(height: 1),
            const SizedBox(height: 12),
            if (topicsWithLessons.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Lessons for this subject are being prepared.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF64748B),
                      ),
                ),
              )
            else
              for (final topic in topicsWithLessons) ...[
                Text(
                  topic.title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF334155),
                      ),
                ),
                const SizedBox(height: 6),
                for (final lesson
                    in widget.lessonsByTopic[topic.id] ?? const <LearningLesson>[])
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                    leading: Icon(
                      (widget.progressByLesson[lesson.id]?.isCompleted ?? false)
                          ? Icons.check_circle_rounded
                          : Icons.play_circle_outline_rounded,
                      color: (widget.progressByLesson[lesson.id]?.isCompleted ??
                              false)
                          ? const Color(0xFF15803D)
                          : const Color(0xFF0F4C81),
                    ),
                    title: Text(
                      lesson.title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      '${lesson.estimatedMinutes} min'
                      '${(widget.progressByLesson[lesson.id]?.isCompleted ?? false) ? ' · Completed' : (widget.progressByLesson[lesson.id]?.status == 'in_progress' ? ' · In progress' : '')}'
                      '${widget.progressByLesson[lesson.id]?.bestQuizScorePercent != null ? ' · ${l10n.bestScoreLabel(widget.progressByLesson[lesson.id]!.bestQuizScorePercent!)}' : ''}',
                    ),
                    trailing: const Icon(Icons.arrow_forward_rounded, size: 18),
                    onTap: () => context.go(AppRoutes.lessonReader(lesson.id)),
                  ),
                const SizedBox(height: 8),
              ],
            if (upcomingTopics.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Upcoming topics (${upcomingTopics.length})',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF64748B),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final topic in upcomingTopics)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Text(
                        topic.title,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF475569),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class LessonReaderScreen extends ConsumerStatefulWidget {
  const LessonReaderScreen({required this.lessonId, super.key});

  final String lessonId;

  @override
  ConsumerState<LessonReaderScreen> createState() => _LessonReaderScreenState();
}

class _LessonReaderScreenState extends ConsumerState<LessonReaderScreen> {
  double _readingProgress = 25;
  bool _isSaving = false;
  String? _statusMessage;

  Future<void> _saveProgress({required bool complete}) async {
    final learner = ref.read(activeLearnerProvider);
    final repo = ref.read(learningRepositoryProvider);
    if (learner == null || repo == null) return;
    setState(() {
      _isSaving = true;
      _statusMessage = null;
    });
    try {
      final updated = await repo.upsertLessonProgress(
        learnerId: learner.id,
        lessonId: widget.lessonId,
        readingProgressPercent: complete ? 100 : _readingProgress.round(),
        markCompleted: complete,
      );
      ref.invalidate(activeLearnerLearningCatalogProvider);
      ref.invalidate(learnerGamificationOverviewProvider(learner.id));
      if (mounted) {
        setState(() {
          _readingProgress = updated.readingProgressPercent.toDouble();
          _statusMessage = complete
              ? AppLocalizations.of(context)!.lessonCompletedMessage
              : AppLocalizations.of(context)!.lessonProgressSavedMessage(
                  updated.readingProgressPercent,
                );
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _statusMessage = error.toString());
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeLearner = ref.watch(activeLearnerProvider);
    final lessonAsync = ref.watch(lessonDetailProvider(widget.lessonId));

    if (activeLearner == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.selectActiveLearnerTitle),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: () => context.go(AppRoutes.learn),
                child: Text(l10n.learningHubTitle),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: lessonAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                AuthInlineMessage(message: l10n.requestFailed, isError: true),
            data: (lesson) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextButton.icon(
                    onPressed: () => context.go(AppRoutes.learn),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(l10n.learningHubTitle),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    lesson.title,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${activeLearner.fullName} • ${lesson.estimatedMinutes} min',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  if (lesson.summary != null &&
                      lesson.summary!.isNotEmpty) ...[
                    AppCard(
                      child: Text(
                        lesson.summary!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                  _InteractiveLessonBlocksView(
                    blocks: lesson.effectiveContentBlocks,
                  ),
                  const SizedBox(height: 16),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.readingProgressLabel(_readingProgress.round()),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Slider(
                          value: _readingProgress,
                          min: 0,
                          max: 100,
                          divisions: 4,
                          label: '${_readingProgress.round()}%',
                          onChanged: _isSaving
                              ? null
                              : (val) => setState(() => _readingProgress = val),
                        ),
                        if (_statusMessage != null) ...[
                          AuthInlineMessage(
                            message: _statusMessage!,
                            isError: false,
                          ),
                          const SizedBox(height: 8),
                        ],
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: [
                            OutlinedButton(
                              onPressed: _isSaving
                                  ? null
                                  : () => _saveProgress(complete: false),
                              child: Text(l10n.saveProgressAction),
                            ),
                            FilledButton.icon(
                              onPressed: _isSaving
                                  ? null
                                  : () => _saveProgress(complete: true),
                              icon: const Icon(Icons.check_circle_outline),
                              label: Text(l10n.markLessonCompletedAction),
                            ),
                            FilledButton.tonalIcon(
                              onPressed: () => context.go(
                                AppRoutes.lessonQuiz(widget.lessonId),
                              ),
                              icon: const Icon(Icons.quiz_outlined),
                              label: Text(l10n.takePracticeQuizAction),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class PracticeQuizScreen extends ConsumerStatefulWidget {
  const PracticeQuizScreen({required this.lessonId, super.key});

  final String lessonId;

  @override
  ConsumerState<PracticeQuizScreen> createState() => _PracticeQuizScreenState();
}

class _PracticeQuizScreenState extends ConsumerState<PracticeQuizScreen> {
  final Map<String, int> _selectedOptions = {};
  QuizSubmissionResult? _submissionResult;
  bool _isSubmitting = false;
  String? _errorMessage;

  // Modern multi-type assessment state
  final Map<String, dynamic> _assessmentAnswers = {};
  AssessmentSubmissionResult? _assessmentResult;

  Future<void> _submitQuiz(PracticeQuiz quiz) async {
    final learner = ref.read(activeLearnerProvider);
    final repo = ref.read(learningRepositoryProvider);
    if (learner == null || repo == null) return;
    if (quiz.questions.any((q) => !_selectedOptions.containsKey(q.id))) {
      setState(
        () => _errorMessage =
            AppLocalizations.of(context)!.answerAllQuestionsError,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final indices = [
        for (final q in quiz.questions) _selectedOptions[q.id]!,
      ];
      final result = await repo.submitQuizAttempt(
        learnerId: learner.id,
        quizId: quiz.id,
        selectedIndices: indices,
      );
      ref.invalidate(activeLearnerLearningCatalogProvider);
      ref.invalidate(learnerGamificationOverviewProvider(learner.id));
      if (mounted) {
        setState(() => _submissionResult = result);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.toString());
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitAssessment({
    required String topicId,
    required List<QuestionBankItem> questions,
  }) async {
    final learner = ref.read(activeLearnerProvider);
    final repo = ref.read(learningRepositoryProvider);
    if (learner == null || repo == null) return;

    if (questions.any((q) => !_assessmentAnswers.containsKey(q.id))) {
      setState(
        () => _errorMessage =
            AppLocalizations.of(context)!.answerAllQuestionsError,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final payload = [
        for (final q in questions)
          {
            'question_id': q.id,
            'answer': _assessmentAnswers[q.id],
          },
      ];
      final result = await repo.submitAssessmentAttempt(
        learnerId: learner.id,
        topicId: topicId,
        answers: payload,
      );
      ref.invalidate(activeLearnerLearningCatalogProvider);
      ref.invalidate(learnerGamificationOverviewProvider(learner.id));
      if (mounted) {
        setState(() => _assessmentResult = result);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = error.toString());
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final activeLearner = ref.watch(activeLearnerProvider);
    final lessonAsync = ref.watch(lessonDetailProvider(widget.lessonId));
    final quizAsync = ref.watch(lessonQuizProvider(widget.lessonId));

    if (activeLearner == null) {
      return Padding(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: FilledButton(
            onPressed: () => context.go(AppRoutes.learn),
            child: Text(l10n.learningHubTitle),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 780),
          child: lessonAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                AuthInlineMessage(message: l10n.requestFailed, isError: true),
            data: (lesson) {
              final topicQuestionsAsync =
                  ref.watch(topicAssessmentQuestionsProvider(lesson.topicId));

              return topicQuestionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => _buildLegacyQuizView(context, quizAsync, l10n),
                data: (topicQuestions) {
                  if (topicQuestions.isNotEmpty) {
                    return _buildModernAssessmentView(
                      context,
                      lesson,
                      topicQuestions,
                      l10n,
                    );
                  }
                  return _buildLegacyQuizView(context, quizAsync, l10n);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildModernAssessmentView(
    BuildContext context,
    LearningLesson lesson,
    List<QuestionBankItem> questions,
    AppLocalizations l10n,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextButton.icon(
          onPressed: () => context.go(AppRoutes.lessonReader(widget.lessonId)),
          icon: const Icon(Icons.arrow_back),
          label: Text(l10n.backToLessonAction),
        ),
        const SizedBox(height: 8),
        Text(
          lesson.title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 16),
        if (_assessmentResult != null) ...[
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _assessmentResult!.passed
                            ? l10n.assessmentPassedTitle(
                                _assessmentResult!.scorePercent,
                              )
                            : l10n.assessmentTryAgainTitle(
                                _assessmentResult!.scorePercent,
                              ),
                        key: const ValueKey('quiz-result-heading'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    _buildMasteryPill(context, _assessmentResult!.masteryStatus, l10n),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.assessmentScoreSummary(
                    _assessmentResult!.correctCount,
                    _assessmentResult!.totalQuestions,
                    _masteryLabel(_assessmentResult!.masteryStatus, l10n),
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => context.go(AppRoutes.learn),
                  child: Text(l10n.backToLearningHubAction),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (_errorMessage != null) ...[
          AuthInlineMessage(message: _errorMessage!, isError: true),
          const SizedBox(height: 12),
        ],
        for (final (qIndex, q) in questions.indexed) ...[
          _buildQuestionBankCard(context, qIndex, q, l10n),
          const SizedBox(height: 12),
        ],
        FilledButton.icon(
          key: const ValueKey('submit-quiz-button'),
          onPressed: _isSubmitting
              ? null
              : () => _submitAssessment(
                    topicId: lesson.topicId,
                    questions: questions,
                  ),
          icon: const Icon(Icons.send_outlined),
          label: Text(l10n.submitQuizAction),
        ),
      ],
    );
  }

  Widget _buildMasteryPill(
    BuildContext context,
    String status,
    AppLocalizations l10n,
  ) {
    Color bg;
    Color fg;
    IconData icon;
    if (status == 'mastered') {
      bg = LearnTzColors.accent100;
      fg = LearnTzColors.accent900;
      icon = Icons.stars;
    } else if (status == 'proficient') {
      bg = LearnTzColors.successBg;
      fg = LearnTzColors.successText;
      icon = Icons.verified;
    } else {
      bg = LearnTzColors.infoBg;
      fg = LearnTzColors.infoText;
      icon = Icons.timelapse;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 4),
          Text(
            _masteryLabel(status, l10n),
            style: TextStyle(color: fg, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  String _masteryLabel(String status, AppLocalizations l10n) {
    switch (status) {
      case 'mastered':
        return l10n.masteryStatusMastered;
      case 'proficient':
        return l10n.masteryStatusProficient;
      default:
        return l10n.masteryStatusInProgress;
    }
  }

  Widget _buildQuestionBankCard(
    BuildContext context,
    int qIndex,
    QuestionBankItem q,
    AppLocalizations l10n,
  ) {
    final theme = Theme.of(context);
    final graded = _assessmentResult?.results
        .where((r) => r.questionId == q.id)
        .firstOrNull;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Chip(
                label: Text(
                  _questionTypeLabel(q.questionType, l10n),
                  style: const TextStyle(fontSize: 11),
                ),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              const SizedBox(width: 8),
              Text(
                q.difficultyLevel.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.outline,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (graded != null)
                Icon(
                  graded.isCorrect ? Icons.check_circle : Icons.cancel,
                  color: graded.isCorrect ? Colors.green : Colors.red,
                  size: 20,
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${qIndex + 1}. ${q.questionText}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          _buildQuestionInput(context, q, l10n),
          if (graded != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: graded.isCorrect
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!graded.isCorrect) ...[
                    Text(
                      l10n.correctAnswerLabel(graded.correctAnswer.toString()),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  if (graded.explanation.isNotEmpty)
                    Text(
                      '${l10n.explanationLabel}: ${graded.explanation}',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestionInput(
    BuildContext context,
    QuestionBankItem q,
    AppLocalizations l10n,
  ) {
    switch (q.questionType) {
      case 'true_false':
        final current = _assessmentAnswers[q.id] as bool?;
        return Row(
          children: [
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: current == true
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
              ),
              onPressed: _isSubmitting
                  ? null
                  : () => setState(() => _assessmentAnswers[q.id] = true),
              child: Text(l10n.trueOption),
            ),
            const SizedBox(width: 12),
            FilledButton.tonal(
              style: FilledButton.styleFrom(
                backgroundColor: current == false
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
              ),
              onPressed: _isSubmitting
                  ? null
                  : () => setState(() => _assessmentAnswers[q.id] = false),
              child: Text(l10n.falseOption),
            ),
          ],
        );

      case 'fill_in_the_blank':
        return TextFormField(
          initialValue: _assessmentAnswers[q.id]?.toString(),
          decoration: InputDecoration(
            hintText: l10n.fillBlankHint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          enabled: !_isSubmitting,
          onChanged: (val) => _assessmentAnswers[q.id] = val.trim(),
        );

      case 'short_answer':
        return TextFormField(
          initialValue: _assessmentAnswers[q.id]?.toString(),
          decoration: InputDecoration(
            hintText: l10n.shortAnswerHint,
            border: const OutlineInputBorder(),
            isDense: true,
          ),
          maxLines: 2,
          enabled: !_isSubmitting,
          onChanged: (val) => _assessmentAnswers[q.id] = val.trim(),
        );

      case 'matching':
        final currentMap =
            (_assessmentAnswers[q.id] as Map<String, dynamic>?) ?? {};
        return Column(
          children: [
            for (final p in q.matchingPremises) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        p.text,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    const Icon(Icons.arrow_forward, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        key: ValueKey('matching-${q.id}-${p.id}'),
                        initialValue: currentMap[p.id]?.toString(),
                        hint: Text(
                          l10n.matchingSelectPlaceholder,
                          style: const TextStyle(fontSize: 12),
                        ),
                        isExpanded: true,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          isDense: true,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                        ),
                        items: [
                          for (final r in q.matchingResponses)
                            DropdownMenuItem<String>(
                              value: r.id,
                              child: Text(r.text),
                            ),
                        ],
                        onChanged: _isSubmitting
                            ? null
                            : (val) {
                                if (val != null) {
                                  setState(() {
                                    final updated = Map<String, dynamic>.from(
                                      currentMap,
                                    );
                                    updated[p.id] = val;
                                    _assessmentAnswers[q.id] = updated;
                                  });
                                }
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );

      case 'multiple_choice':
      default:
        final options = q.options ?? const [];
        return RadioGroup<int>(
          groupValue: _assessmentAnswers[q.id] as int?,
          onChanged: _isSubmitting
              ? (_) {}
              : (val) {
                  if (val != null) {
                    setState(() => _assessmentAnswers[q.id] = val);
                  }
                },
          child: Column(
            children: [
              for (final (optIndex, option) in options.indexed)
                RadioListTile<int>(
                  value: optIndex,
                  title: Text(option),
                  contentPadding: EdgeInsets.zero,
                ),
            ],
          ),
        );
    }
  }

  String _questionTypeLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case 'multiple_choice':
        return l10n.questionTypeMultipleChoice;
      case 'true_false':
        return l10n.questionTypeTrueFalse;
      case 'fill_in_the_blank':
        return l10n.questionTypeFillBlank;
      case 'matching':
        return l10n.questionTypeMatching;
      case 'short_answer':
        return l10n.questionTypeShortAnswer;
      default:
        return type;
    }
  }

  Widget _buildLegacyQuizView(
    BuildContext context,
    AsyncValue<PracticeQuiz?> quizAsync,
    AppLocalizations l10n,
  ) {
    return quizAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          AuthInlineMessage(message: l10n.requestFailed, isError: true),
      data: (quiz) {
        if (quiz == null) {
          return AppCard(child: Text(l10n.noQuizForLesson));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextButton.icon(
              onPressed: () =>
                  context.go(AppRoutes.lessonReader(widget.lessonId)),
              icon: const Icon(Icons.arrow_back),
              label: Text(l10n.backToLessonAction),
            ),
            const SizedBox(height: 8),
            Text(
              quiz.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            if (_submissionResult != null) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _submissionResult!.passed
                          ? l10n.quizPassedTitle(
                              _submissionResult!.scorePercent,
                            )
                          : l10n.quizTryAgainTitle(
                              _submissionResult!.scorePercent,
                            ),
                      key: const ValueKey('quiz-result-heading'),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.quizScoreSummary(
                        _submissionResult!.correctCount,
                        _submissionResult!.totalQuestions,
                        _submissionResult!.bestQuizScorePercent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => context.go(AppRoutes.learn),
                      child: Text(l10n.backToLearningHubAction),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (_errorMessage != null) ...[
              AuthInlineMessage(message: _errorMessage!, isError: true),
              const SizedBox(height: 12),
            ],
            for (final (qIndex, q) in quiz.questions.indexed) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${qIndex + 1}. ${q.prompt}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    RadioGroup<int>(
                      groupValue: _selectedOptions[q.id],
                      onChanged: _isSubmitting
                          ? (_) {}
                          : (val) {
                              if (val != null) {
                                setState(() => _selectedOptions[q.id] = val);
                              }
                            },
                      child: Column(
                        children: [
                          for (final (optIndex, option) in q.options.indexed)
                            RadioListTile<int>(
                              value: optIndex,
                              title: Text(option),
                              contentPadding: EdgeInsets.zero,
                            ),
                        ],
                      ),
                    ),
                    if (_submissionResult != null &&
                        qIndex < _submissionResult!.results.length &&
                        _submissionResult!
                            .results[qIndex]
                            .explanation
                            .isNotEmpty)
                      Text(
                        _submissionResult!.results[qIndex].explanation,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            FilledButton.icon(
              key: const ValueKey('submit-quiz-button'),
              onPressed: _isSubmitting ? null : () => _submitQuiz(quiz),
              icon: const Icon(Icons.send_outlined),
              label: Text(l10n.submitQuizAction),
            ),
          ],
        );
      },
    );
  }
}

class _InteractiveLessonBlocksView extends StatelessWidget {
  const _InteractiveLessonBlocksView({required this.blocks});

  final List<LessonContentBlock> blocks;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in blocks) ...[
          _buildBlock(context, block),
          const SizedBox(height: 14),
        ],
      ],
    );
  }

  Widget _buildBlock(BuildContext context, LessonContentBlock block) {
    switch (block.type) {
      case 'callout':
        return _CalloutBlockWidget(block: block);
      case 'definition':
        return _DefinitionBlockWidget(block: block);
      case 'example':
        return _ExampleBlockWidget(block: block);
      case 'diagram':
        return _DiagramBlockWidget(block: block);
      case 'checkpoint':
        return _InlineCheckpointWidget(block: block);
      case 'markdown':
      default:
        final paragraphs = (block.body ?? '')
            .split('\n\n')
            .map((p) => p.trim())
            .where((p) => p.isNotEmpty)
            .toList();
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final p in paragraphs) ...[
                Text(
                  p
                      .replaceAll('# ', '')
                      .replaceAll('## ', '')
                      .replaceAll('### ', ''),
                  style: p.startsWith('#')
                      ? Theme.of(context).textTheme.titleLarge
                      : Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        );
    }
  }
}

class _CalloutBlockWidget extends StatelessWidget {
  const _CalloutBlockWidget({required this.block});

  final LessonContentBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWarning = block.style == 'warning';
    final isTip = block.style == 'tip';

    final Color accentColor = isWarning
        ? Colors.amber.shade700
        : isTip
            ? Colors.green.shade700
            : theme.colorScheme.primary;

    final IconData iconData = isWarning
        ? Icons.warning_amber_rounded
        : isTip
            ? Icons.lightbulb_outline
            : Icons.info_outline;

    return AppCard(
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: accentColor, width: 4)),
        ),
        padding: const EdgeInsets.only(left: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(iconData, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    block.title ??
                        (isTip ? 'Tip' : isWarning ? 'Warning' : 'Note'),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (block.content != null && block.content!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                block.content!,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DefinitionBlockWidget extends StatelessWidget {
  const _DefinitionBlockWidget({required this.block});

  final LessonContentBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Chip(
                avatar: const Icon(Icons.bookmark_outline, size: 16),
                label: Text(l10n.definitionLabel),
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              if (block.pronunciation != null) ...[
                const SizedBox(width: 8),
                Text(
                  block.pronunciation!,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontStyle: FontStyle.italic),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            block.term ?? '',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            block.definition ?? '',
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontStyle: FontStyle.italic),
          ),
          if (block.example != null && block.example!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${l10n.exampleLabel}: ${block.example!}',
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ExampleBlockWidget extends StatelessWidget {
  const _ExampleBlockWidget({required this.block});

  final LessonContentBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.school_outlined,
                color: theme.colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                block.title ?? l10n.exampleLabel,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (block.problem != null) ...[
            const SizedBox(height: 8),
            Text(block.problem!, style: theme.textTheme.bodyLarge),
          ],
          if (block.steps.isNotEmpty) ...[
            const SizedBox(height: 12),
            for (final (index, step) in block.steps.indexed) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Text(
                        '${index + 1}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(step, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                ),
              ),
            ],
          ],
          if (block.takeaway != null && block.takeaway!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.takeawayLabel}: ${block.takeaway!}',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DiagramBlockWidget extends StatelessWidget {
  const _DiagramBlockWidget({required this.block});

  final LessonContentBlock block;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Column(
        children: [
          Container(
            height: 160,
            width: double.infinity,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_outlined,
                    size: 48,
                    color: theme.colorScheme.outline,
                  ),
                  if (block.altText != null) ...[
                    const SizedBox(height: 8),
                    Text(block.altText!, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ),
          if (block.caption != null) ...[
            const SizedBox(height: 8),
            Text(
              block.caption!,
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineCheckpointWidget extends StatefulWidget {
  const _InlineCheckpointWidget({required this.block});

  final LessonContentBlock block;

  @override
  State<_InlineCheckpointWidget> createState() =>
      _InlineCheckpointWidgetState();
}

class _InlineCheckpointWidgetState extends State<_InlineCheckpointWidget> {
  int? _selectedIndex;
  bool _checked = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isCorrect = _selectedIndex == widget.block.correctIndex;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.quiz_outlined,
                color: theme.colorScheme.secondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.checkpointTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.secondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (widget.block.question != null) ...[
            const SizedBox(height: 8),
            Text(widget.block.question!, style: theme.textTheme.bodyLarge),
          ],
          const SizedBox(height: 12),
          RadioGroup<int>(
            groupValue: _selectedIndex,
            onChanged: _checked
                ? (_) {}
                : (val) {
                    if (val != null) {
                      setState(() => _selectedIndex = val);
                    }
                  },
            child: Column(
              children: [
                for (final (idx, opt) in widget.block.options.indexed)
                  RadioListTile<int>(
                    value: idx,
                    title: Text(opt),
                    contentPadding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (!_checked)
            FilledButton.tonal(
              onPressed: _selectedIndex != null
                  ? () => setState(() => _checked = true)
                  : null,
              child: Text(l10n.checkAnswerAction),
            )
          else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isCorrect
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCorrect ? Colors.green : Colors.red,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCorrect ? Icons.check_circle : Icons.cancel_outlined,
                        color: isCorrect ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isCorrect
                            ? l10n.checkpointCorrect
                            : l10n.checkpointIncorrect,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isCorrect ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  if (widget.block.explanation != null &&
                      widget.block.explanation!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      widget.block.explanation!,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OfflineSyncStatusBar extends ConsumerWidget {
  const _OfflineSyncStatusBar({required this.learnerId});

  final String learnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final syncState = ref.watch(offlineSyncNotifierProvider);
    final hasPending = syncState.pendingCount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: hasPending
            ? Colors.amber.withValues(alpha: 0.12)
            : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasPending
              ? Colors.amber.withValues(alpha: 0.4)
              : Theme.of(context).dividerColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasPending ? Icons.cloud_upload_outlined : Icons.cloud_done_outlined,
            size: 20,
            color: hasPending ? Colors.amber.shade800 : Colors.green,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              hasPending
                  ? l10n.syncStatusPending(syncState.pendingCount)
                  : l10n.syncStatusSynced,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: hasPending ? FontWeight.bold : FontWeight.normal,
                  ),
            ),
          ),
          if (hasPending)
            FilledButton.tonal(
              onPressed: syncState.isSyncing
                  ? null
                  : () async {
                      final result = await ref
                          .read(offlineSyncNotifierProvider.notifier)
                          .flushQueue(learnerId);
                      if (context.mounted && result != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.syncSuccessMessage)),
                        );
                      }
                    },
              child: syncState.isSyncing
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        const SizedBox(width: 8),
                        Text(l10n.syncingAction),
                      ],
                    )
                  : Text(l10n.syncNowAction),
            ),
        ],
      ),
    );
  }
}

class _LearnerRecommendationsSection extends ConsumerWidget {
  const _LearnerRecommendationsSection({required this.learnerId});

  final String learnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final recsAsync = ref.watch(learnerRecommendationsProvider(learnerId));

    return recsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (recommendations) {
        if (recommendations.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.recommendationsTitle,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.recommendationsSubtitle,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            for (final rec in recommendations) ...[
              _RecommendationCard(
                recommendation: rec,
                learnerId: learnerId,
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class _RecommendationCard extends ConsumerStatefulWidget {
  const _RecommendationCard({
    required this.recommendation,
    required this.learnerId,
  });

  final LearnerRecommendation recommendation;
  final String learnerId;

  @override
  ConsumerState<_RecommendationCard> createState() =>
      _RecommendationCardState();
}

class _RecommendationCardState extends ConsumerState<_RecommendationCard> {
  bool _isDismissing = false;

  Future<void> _dismiss() async {
    final repo = ref.read(learningRepositoryProvider);
    if (repo == null) return;
    setState(() => _isDismissing = true);
    try {
      await repo.dismissLearnerRecommendation(
        learnerId: widget.learnerId,
        recommendationId: widget.recommendation.id,
      );
      ref.invalidate(learnerRecommendationsProvider(widget.learnerId));
    } catch (_) {
      if (mounted) setState(() => _isDismissing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final rec = widget.recommendation;

    Color badgeBg;
    Color badgeFg;
    String badgeText;
    IconData badgeIcon;

    if (rec.recommendationType == 'remedial') {
      badgeBg = Colors.orange.shade100;
      badgeFg = Colors.orange.shade900;
      badgeText = l10n.remedialPill;
      badgeIcon = Icons.fitness_center;
    } else if (rec.recommendationType == 'advanced') {
      badgeBg = Colors.purple.shade100;
      badgeFg = Colors.purple.shade900;
      badgeText = l10n.advancedPill;
      badgeIcon = Icons.trending_up;
    } else {
      badgeBg = Colors.blue.shade100;
      badgeFg = Colors.blue.shade900;
      badgeText = l10n.spacedRepetitionPill;
      badgeIcon = Icons.update;
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(badgeIcon, size: 14, color: badgeFg),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeFg,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                rec.subjectName,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: l10n.dismissRecommendationAction,
                onPressed: _isDismissing ? null : _dismiss,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(rec.title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(rec.reason, style: theme.textTheme.bodyMedium),
          if (rec.lessonId != null) ...[
            const SizedBox(height: 12),
            FilledButton.tonalIcon(
              onPressed: () =>
                  context.go(AppRoutes.lessonReader(rec.lessonId!)),
              icon: const Icon(Icons.play_arrow_outlined, size: 18),
              label: Text(l10n.startRecommendedLessonAction),
            ),
          ],
        ],
      ),
    );
  }
}

class _LearnerMasteryOverviewSection extends ConsumerWidget {
  const _LearnerMasteryOverviewSection({required this.learnerId});

  final String learnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final reportAsync = ref.watch(learnerMasteryReportProvider(learnerId));

    return reportAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (report) {
        if (report.totalTopics == 0) return const SizedBox.shrink();

        final theme = Theme.of(context);
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.insights_outlined,
                    color: theme.colorScheme.primary,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.masteryReportTitle,
                      style: theme.textTheme.titleLarge,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.speed, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${report.readinessIndex}% ${l10n.readinessIndexLabel}',
                          style: TextStyle(
                            color: theme.colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildMasteryTierStat(
                    context,
                    count: report.masteredTopics,
                    label: l10n.topicsMasteredLabel,
                    color: Colors.amber.shade700,
                  ),
                  _buildMasteryTierStat(
                    context,
                    count: report.proficientTopics,
                    label: l10n.topicsProficientLabel,
                    color: Colors.green.shade700,
                  ),
                  _buildMasteryTierStat(
                    context,
                    count: report.inProgressTopics,
                    label: l10n.topicsInProgressLabel,
                    color: Colors.blue.shade700,
                  ),
                  _buildMasteryTierStat(
                    context,
                    count: report.notStartedTopics,
                    label: l10n.topicsNotStartedLabel,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
              if (report.overallAccuracyRate > 0) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      '${l10n.overallAccuracyLabel}: ',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '${report.overallAccuracyRate}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildMasteryTierStat(
    BuildContext context, {
    required int count,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style:
                Theme.of(context).textTheme.labelSmall?.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}
