import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/routing/app_router.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/app_card.dart';
import '../learners/learner_providers.dart';
import 'learning_models.dart';
import 'learning_providers.dart';

class RevisionCentreScreen extends ConsumerWidget {
  const RevisionCentreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final activeLearner = ref.watch(activeLearnerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => context.go(AppRoutes.learn),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.revisionCentreTitle,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(
                          l10n.revisionCentreSubtitle,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => context.go(AppRoutes.resourceLibrary),
                    icon: const Icon(Icons.menu_book_outlined, size: 18),
                    label: Text(l10n.resourceLibraryTitle),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (activeLearner == null)
                AppCard(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Text(
                        l10n.noLearnersDescription,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ),
                )
              else ...[
                _RevisionOverviewHeader(learnerId: activeLearner.id),
                const SizedBox(height: 24),
                _WeakTopicDrillsSection(learnerId: activeLearner.id),
                const SizedBox(height: 24),
                _FlashcardDecksSection(learnerId: activeLearner.id),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _RevisionOverviewHeader extends ConsumerWidget {
  const _RevisionOverviewHeader({required this.learnerId});

  final String learnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final overviewAsync = ref.watch(learnerRevisionOverviewProvider(learnerId));

    return overviewAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => AppCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('${l10n.requestFailed}: $e'),
        ),
      ),
      data: (overview) {
        final colorScheme = Theme.of(context).colorScheme;
        return AppCard(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: overview.readinessIndex / 100.0,
                            strokeWidth: 8,
                            backgroundColor: colorScheme.surfaceContainerHighest,
                            color: overview.readinessIndex >= 70
                                ? Colors.green
                                : (overview.readinessIndex >= 40
                                    ? Colors.orange
                                    : Colors.red),
                          ),
                        ),
                        Text(
                          '${overview.readinessIndex}%',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.examReadinessScore,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            overview.readinessIndex >= 75
                                ? l10n.examReadinessHigh
                                : (overview.readinessIndex >= 50
                                    ? l10n.examReadinessModerate
                                    : l10n.examReadinessNeedsWork),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _MetricPill(
                      label: l10n.masteredTopicsCount,
                      value: '${overview.masteredTopicsCount}',
                      icon: Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                    const SizedBox(width: 12),
                    _MetricPill(
                      label: l10n.proficientTopicsCount,
                      value: '${overview.proficientTopicsCount}',
                      icon: Icons.trending_up_outlined,
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _MetricPill(
                      label: l10n.flashcardsAvailable,
                      value: '${overview.flashcardDecksCount}',
                      icon: Icons.style_outlined,
                      color: Colors.purple,
                    ),
                    const SizedBox(width: 12),
                    _MetricPill(
                      label: l10n.resourcesAvailable,
                      value: '${overview.learningResourcesCount}',
                      icon: Icons.folder_open_outlined,
                      color: Colors.teal,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeakTopicDrillsSection extends ConsumerStatefulWidget {
  const _WeakTopicDrillsSection({required this.learnerId});

  final String learnerId;

  @override
  ConsumerState<_WeakTopicDrillsSection> createState() =>
      _WeakTopicDrillsSectionState();
}

class _WeakTopicDrillsSectionState
    extends ConsumerState<_WeakTopicDrillsSection> {
  String? _selectedSubjectId;
  String? _selectedCompetenceId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final catalogAsync =
        ref.watch(learnerRevisionDrillCatalogProvider(widget.learnerId));

    return catalogAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => AppCard(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('${l10n.requestFailed}: $e'),
        ),
      ),
      data: (subjects) {
        if (subjects.isEmpty) {
          return AppCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.celebration_outlined, color: Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.noWeakAreasFound,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Validate selected subject & competence against live catalog
        final activeSubjectId =
            subjects.any((s) => s.subjectId == _selectedSubjectId)
                ? _selectedSubjectId
                : subjects.first.subjectId;
        final activeSubject = subjects.firstWhere(
          (s) => s.subjectId == activeSubjectId,
          orElse: () => subjects.first,
        );

        final competences = activeSubject.competences;
        final activeCompetenceId = competences.any(
          (c) => c.mainCompetenceId == _selectedCompetenceId,
        )
            ? _selectedCompetenceId
            : null; // null = All Main Competences in selected Subject

        final visibleCompetences = activeCompetenceId == null
            ? competences
            : competences
                .where((c) => c.mainCompetenceId == activeCompetenceId)
                .toList();

        // First drillable specific competence for quick Start Drill button
        final firstDrillable = visibleCompetences
            .expand((c) => c.specificCompetences)
            .where((sc) => sc.topicId != null && sc.topicId!.isNotEmpty)
            .firstOrNull;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.weakAreaDrillsTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Categorized by Subject, Main Competence & Specific Competence',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: const Color(0xFF64748B),
                          ),
                    ),
                  ],
                ),
                if (firstDrillable != null)
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        context.go(AppRoutes.lessonQuiz(firstDrillable.topicId!)),
                    icon: const Icon(Icons.bolt_rounded, size: 18),
                    label: Text(l10n.startWeakAreaDrill),
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Level 1: Subject Filter Chips
            Text(
              '1. Subject',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F4C81),
                  ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final subject in subjects)
                  ChoiceChip(
                    key: ValueKey('drill-subject-${subject.subjectId}'),
                    label: Text(subject.subjectName),
                    selected: subject.subjectId == activeSubject.subjectId,
                    onSelected: (_) {
                      setState(() {
                        _selectedSubjectId = subject.subjectId;
                        _selectedCompetenceId = null;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 14),

            // Level 2: Main Competence Dropdown Filter
            if (competences.isNotEmpty) ...[
              Text(
                '2. Main Competence',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF15803D),
                    ),
              ),
              const SizedBox(height: 6),
              DropdownButtonFormField<String?>(
                key: ValueKey(
                  'drill-comp-${activeSubject.subjectId}-${activeCompetenceId ?? 'all'}',
                ),
                initialValue: activeCompetenceId,
                isExpanded: true,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text(
                      'All Competences (${competences.length})',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  for (final comp in competences)
                    DropdownMenuItem<String?>(
                      value: comp.mainCompetenceId,
                      child: Text(
                        comp.code.isNotEmpty
                            ? '${comp.code} · ${comp.title}'
                            : comp.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (val) => setState(() => _selectedCompetenceId = val),
              ),
              const SizedBox(height: 16),
            ],

            // Level 3: Specific Competences grouped under each Main Competence
            Text(
              '3. Specific Competences',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFB45309),
                  ),
            ),
            const SizedBox(height: 8),
            for (final comp in visibleCompetences) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0F2FE),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            comp.code.isNotEmpty ? comp.code : 'COMP',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F4C81),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            comp.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Divider(height: 1),
                    const SizedBox(height: 8),
                    if (comp.specificCompetences.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Text(
                          'No specific competences published under this competence yet.',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      )
                    else
                      for (final sc in comp.specificCompetences) ...[
                        _SpecificCompetenceDrillRow(
                          item: sc,
                          attemptsLabel: l10n.attemptsLabel,
                          drillLabel: l10n.drillAction,
                          onDrill: sc.topicId != null && sc.topicId!.isNotEmpty
                              ? () =>
                                  context.go(AppRoutes.lessonQuiz(sc.topicId!))
                              : () => context.go(AppRoutes.learn),
                        ),
                        const SizedBox(height: 8),
                      ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        );
      },
    );
  }
}

class _SpecificCompetenceDrillRow extends StatelessWidget {
  const _SpecificCompetenceDrillRow({
    required this.item,
    required this.attemptsLabel,
    required this.drillLabel,
    required this.onDrill,
  });

  final RevisionDrillSpecificCompetence item;
  final String attemptsLabel;
  final String drillLabel;
  final VoidCallback onDrill;

  @override
  Widget build(BuildContext context) {
    final isNew = item.quizzesAttempted == 0;
    final accuracy = item.accuracyRate;
    final badgeColor = isNew
        ? const Color(0xFF0F4C81)
        : (accuracy < 50
            ? const Color(0xFFDC2626)
            : (accuracy < 75
                ? const Color(0xFFD97706)
                : const Color(0xFF15803D)));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              isNew ? 'New' : '${accuracy.toStringAsFixed(0)}%',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                color: badgeColor,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.code.isNotEmpty
                      ? '${item.code} · ${item.title}'
                      : item.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${item.quizzesAttempted} $attemptsLabel'
                  '${item.questionCount > 0 ? ' · ${item.questionCount} questions' : ''}',
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onDrill,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(drillLabel),
          ),
        ],
      ),
    );
  }
}

class _FlashcardDecksSection extends ConsumerWidget {
  const _FlashcardDecksSection({required this.learnerId});

  final String learnerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final decksAsync = ref.watch(
      flashcardDecksProvider((learnerId: learnerId, subjectId: null)),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.flashcardsSectionTitle,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        decksAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('${l10n.requestFailed}: $e'),
          data: (decks) {
            if (decks.isEmpty) {
              return AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(l10n.noFlashcardDecksAvailable),
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 600;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: isWide ? 2 : 1,
                    mainAxisExtent: 150,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: decks.length,
                  itemBuilder: (context, index) {
                    final deck = decks[index];
                    return AppCard(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    deck.subjectName,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.timer_outlined,
                                  size: 14,
                                  color: Theme.of(context).textTheme.bodySmall?.color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${deck.estimatedMinutes} ${l10n.minutesShort}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              deck.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              deck.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const Spacer(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${deck.cardCount} ${l10n.cardsLabel}',
                                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                ),
                                TextButton.icon(
                                  onPressed: () {
                                    context.go(
                                      AppRoutes.flashcardStudy(deck.id),
                                    );
                                  },
                                  icon: const Icon(Icons.play_arrow, size: 16),
                                  label: Text(l10n.studyFlashcardsAction),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ],
    );
  }
}
