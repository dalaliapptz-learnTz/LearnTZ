import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/components/components.dart';
import '../../core/routing/app_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../auth/auth_screens.dart';
import '../gamification/gamification_providers.dart';
import '../gamification/widgets/gamification_widgets.dart';
import '../learners/learner_providers.dart';
import '../learners/providers/learner_auth_providers.dart';
import 'learning_models.dart';
import 'learning_providers.dart';

class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final overviewAsync = ref.watch(parentDashboardOverviewProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final isCompact = constraints.maxWidth < 600;
                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => context.go(AppRoutes.account),
                              icon: const Icon(Icons.arrow_back),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.parentDashboardTitle,
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                  Text(
                                    l10n.parentDashboardSubtitle,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => context.go(AppRoutes.accountSettings),
                                icon: const Icon(Icons.settings_outlined, size: 16),
                                label: const Text('Settings'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: FilledButton.icon(
                                onPressed: () => context.go(AppRoutes.addLearner),
                                icon: const Icon(Icons.add, size: 16),
                                label: const Text('+ Add Child'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      IconButton(
                        onPressed: () => context.go(AppRoutes.account),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n.parentDashboardTitle,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            Text(
                              l10n.parentDashboardSubtitle,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: () => context.go(AppRoutes.accountSettings),
                            icon: const Icon(Icons.settings_outlined, size: 18),
                            label: const Text('Settings'),
                          ),
                          FilledButton.icon(
                            onPressed: () => context.go(AppRoutes.addLearner),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('+ Add Child'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              // Family Subscription & Safety Status Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_user_rounded,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Family Learning Account Active • Subscribed to National Curriculum Tracks',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: const Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              overviewAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => AuthInlineMessage(
                  message: l10n.requestFailed,
                  isError: true,
                ),
                data: (learners) {
                  if (learners.isEmpty) {
                    return AppCard(
                      child: Column(
                        children: [
                          const Icon(Icons.people_outline, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            l10n.noLearnersRegistered,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          FilledButton(
                            onPressed: () => context.go(AppRoutes.addLearner),
                            child: Text(l10n.registerChildAction),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: [
                      for (final learner in learners) ...[
                        _ParentLearnerCard(learner: learner),
                        const SizedBox(height: 20),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ParentLearnerCard extends ConsumerWidget {
  const _ParentLearnerCard({required this.learner});

  final ParentLearnerOverview learner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final ratio = (learner.masteryPercent.clamp(0, 100)) / 100.0;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                child: Text(
                  learner.firstName.isNotEmpty ? learner.firstName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      learner.fullName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${learner.gradeName} • ${learner.systemName} • ${learner.schoolName}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              AppBadge(
                icon: Icons.local_fire_department,
                label: '${learner.streakDays} ${l10n.streakDaysSuffix}',
                variant: AppBadgeVariant.accent,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Mastery Bar
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.curriculumMasteryLabel,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Text(
                '${learner.masteryPercent}%',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: ratio,
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            '${learner.completedLessons} of ${learner.totalLessons} ${l10n.lessonsCompletedLabel} • ${l10n.averageQuizLabel}: ${learner.averageQuizScorePercent}%',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          ref.watch(parentChildrenGamificationSummaryProvider).maybeWhen(
                data: (summaries) {
                  final childSummary = summaries
                      .where((s) => s.learnerId == learner.learnerId)
                      .firstOrNull;
                  if (childSummary == null) return const SizedBox.shrink();
                  return ParentChildGamificationStrip(summary: childSummary);
                },
                orElse: () => const SizedBox.shrink(),
              ),
          if (learner.lastLessonAccessed != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${l10n.lastActiveLessonLabel}: ${learner.lastLessonAccessed!.subjectName} - ${learner.lastLessonAccessed!.lessonTitle} (${learner.lastLessonAccessed!.readingProgressPercent}%)',
                      style: Theme.of(context).textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Subjects Overview
          if (learner.subjectsOverview.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              l10n.subjectPerformanceLabel,
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final subj in learner.subjectsOverview)
                  AppBadge(
                    icon: subj.status == 'excelling'
                        ? Icons.trending_up
                        : subj.status == 'needs_practice'
                            ? Icons.priority_high
                            : Icons.check_circle_outline,
                    label: '${subj.subjectName}: ${subj.averageQuizScore}% (${subj.completedLessons}/${subj.totalLessons})',
                    variant: subj.status == 'excelling'
                        ? AppBadgeVariant.success
                        : subj.status == 'needs_practice'
                            ? AppBadgeVariant.error
                            : AppBadgeVariant.info,
                  ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          // Actions
          Wrap(
            alignment: WrapAlignment.end,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.childDevices(learner.learnerId)),
                icon: const Icon(Icons.devices_outlined, size: 16),
                label: const Text('Devices'),
              ),
              OutlinedButton(
                onPressed: () => context.go(AppRoutes.learnerProfile(learner.learnerId)),
                child: Text(l10n.learnerProfileTitle),
              ),
              FilledButton.icon(
                onPressed: () async {
                  await ref.read(activeLearnerProvider.notifier).select(learner.learnerId);
                  await ref.read(activeLearnerSessionProvider.notifier).startParentManagedChildMode(
                        learnerId: learner.learnerId,
                        firstName: learner.fullName.split(' ').first,
                        lastName: learner.fullName.split(' ').length > 1
                            ? learner.fullName.split(' ').last
                            : '',
                        learnerCode: learner.learnerId.substring(0, 8).toUpperCase(),
                        avatarPreset: 'lion_reader',
                        countryCode: 'TZ',
                        educationSystemId: '',
                        curriculumId: '',
                        educationLevelId: '',
                        gradeId: '',
                      );
                  if (context.mounted) {
                    context.go(AppRoutes.learnerDashboard);
                  }
                },
                icon: const Icon(Icons.play_arrow),
                label: Text(l10n.openLearningHubAction),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
