import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../content_studio_models.dart';
import '../content_studio_providers.dart';

class ContentStudioOverviewPane extends ConsumerWidget {
  const ContentStudioOverviewPane({
    super.key,
    required this.metricsAsync,
    required this.catalogAsync,
    this.onSelectSubject,
  });

  final AsyncValue<ContentStudioMetrics> metricsAsync;
  final AsyncValue<List<StudioSubjectItem>> catalogAsync;
  final void Function(String subjectId)? onSelectSubject;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCountry = ref.watch(contentStudioCountryFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metrics Grid
        metricsAsync.when(
          data: (m) => LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 800;
              return GridView.count(
                crossAxisCount: isWide ? 4 : 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: isWide ? 1.6 : 1.3,
                children: [
                  _buildKpiCard(
                    label: 'Total Lessons',
                    value: '${m.totalLessons}',
                    subtitle:
                        '${m.totalTopics} topics across ${m.totalSubjects} subjects',
                    icon: Icons.auto_stories,
                    color: LearnTzColors.primary,
                  ),
                  _buildKpiCard(
                    label: 'Published Lessons',
                    value: '${m.publishedLessons}',
                    subtitle: 'Active curriculum material',
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF15803D),
                  ),
                  _buildKpiCard(
                    label: 'Drafts & Revisions',
                    value: '${m.draftLessons}',
                    subtitle: '${m.inReviewLessons} in review queue',
                    icon: Icons.edit_note,
                    color: LearnTzColors.accent,
                  ),
                  _buildKpiCard(
                    label: 'Media Assets',
                    value: '${m.totalMediaAssets}',
                    subtitle: 'Diagrams, audio, & illustrations',
                    icon: Icons.perm_media_outlined,
                    color: const Color(0xFF7C3AED),
                  ),
                ],
              );
            },
          ),
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 24),

        // Filter Bar (Country Chips & Search)
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                'Market Filter:',
                style: LearnTzTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ['ALL', 'TZ', 'KE', 'UG', 'RW', 'BI', 'SS'].map((code) {
                      final isSelected = selectedCountry == code;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(code == 'ALL' ? 'All Markets' : code),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              ref
                                  .read(contentStudioCountryFilterProvider.notifier)
                                  .setCountry(code);
                            }
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 200,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search subjects, topics...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  onChanged: (val) {
                    ref
                        .read(contentStudioSearchQueryProvider.notifier)
                        .setQuery(val);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Curriculum Catalog Tree
        Text(
          'Curriculum Content Tree',
          style: LearnTzTypography.h3.copyWith(
            fontWeight: FontWeight.bold,
            color: LearnTzColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        catalogAsync.when(
          data: (subjects) {
            if (subjects.isEmpty) {
              return AppCard(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      const Icon(Icons.menu_book,
                          size: 48, color: LearnTzColors.neutral400),
                      const SizedBox(height: 12),
                      Text(
                        'No curriculum content found matching filters.',
                        style: LearnTzTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppButton(
                        label: 'Author First Lesson',
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.sm,
                        onPressed: () =>
                            context.push('/content/studio/editor'),
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subjects.length,
              itemBuilder: (context, sIndex) {
                final subject = subjects[sIndex];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Subject Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: LearnTzColors.primary
                                        .withValues(alpha: 0.1),
                                    child: const Icon(
                                      Icons.subject,
                                      color: LearnTzColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          subject.subjectName,
                                          style: LearnTzTypography.h3.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        Text(
                                          'Code: ${subject.subjectCode} • Country: ${subject.countryCode}',
                                          style: LearnTzTypography.bodySmall
                                              .copyWith(
                                            color: LearnTzColors.textSecondary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                AppBadge(
                                  label: '${subject.topics.length} Topics',
                                  variant: AppBadgeVariant.neutral,
                                ),
                                AppButton(
                                  label: 'Open Workspace',
                                  variant: AppButtonVariant.outlined,
                                  size: AppButtonSize.sm,
                                  icon: Icons.dashboard_outlined,
                                  onPressed: () {
                                    ref
                                        .read(selectedSubjectIdProvider.notifier)
                                        .select(subject.subjectId);
                                    ref
                                        .read(recentSubjectIdsProvider.notifier)
                                        .add(subject.subjectId);
                                    onSelectSubject?.call(subject.subjectId);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),

                        // Topics & Lessons
                        if (subject.topics.isEmpty)
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'No topics yet under this subject.',
                              style: LearnTzTypography.bodySmall.copyWith(
                                color: LearnTzColors.textSecondary,
                              ),
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: subject.topics.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, tIndex) {
                              final topic = subject.topics[tIndex];
                              return ExpansionTile(
                                tilePadding: EdgeInsets.zero,
                                title: Text(
                                  'Topic ${topic.topicOrder}: ${topic.topicTitle}',
                                  style:
                                      LearnTzTypography.bodyLarge.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Text(
                                  '${topic.lessons.length} lessons',
                                  style: LearnTzTypography.caption,
                                ),
                                trailing: Wrap(
                                  spacing: 8,
                                  crossAxisAlignment:
                                      WrapCrossAlignment.center,
                                  children: [
                                    if (topic.competencyCode != null)
                                      AppBadge(
                                        label: topic.competencyCode!,
                                        variant: AppBadgeVariant.primary,
                                        size: AppBadgeSize.sm,
                                      ),
                                    const Icon(Icons.expand_more, size: 20),
                                  ],
                                ),
                                children: [
                                  if (topic.lessons.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 8),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'No lessons published yet under this topic.',
                                            style: LearnTzTypography.bodySmall
                                                .copyWith(
                                              color:
                                                  LearnTzColors.textSecondary,
                                            ),
                                          ),
                                          AppButton(
                                            label: 'Add Lesson',
                                            variant:
                                                AppButtonVariant.outlined,
                                            size: AppButtonSize.sm,
                                            icon: Icons.add,
                                            onPressed: () => context.push(
                                              '/content/studio/editor',
                                              extra: {
                                                'topicId': topic.topicId,
                                                'topicTitle':
                                                    topic.topicTitle,
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    ...topic.lessons.map((lesson) {
                                      return Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 6),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: LearnTzColors.neutral50,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: LearnTzColors.neutral200,
                                          ),
                                        ),
                                        child: Row(
                                          children: [
                                            Icon(
                                              lesson.isFreePreview
                                                  ? Icons.lock_open
                                                  : Icons.article_outlined,
                                              size: 18,
                                              color: lesson.isPublished
                                                  ? const Color(0xFF15803D)
                                                  : LearnTzColors.textSecondary,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    lesson.lessonTitle,
                                                    style: LearnTzTypography
                                                        .bodySmall
                                                        .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  Text(
                                                    '~${lesson.estimatedMinutes} mins • v${lesson.versionNumber}',
                                                    style: LearnTzTypography
                                                        .caption
                                                        .copyWith(
                                                      color: LearnTzColors
                                                          .textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: lesson.isPublished
                                                    ? const Color(0xFFDCFCE7)
                                                    : const Color(0xFFFEF3C7),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                lesson.status.displayName,
                                                style: LearnTzTypography
                                                    .caption
                                                    .copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: lesson.isPublished
                                                      ? const Color(
                                                          0xFF166534)
                                                      : const Color(
                                                          0xFF92400E),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.edit_note,
                                                  size: 20),
                                              tooltip: 'Edit in Studio',
                                              onPressed: () => context.push(
                                                '/content/studio/editor',
                                                extra: {
                                                  'lessonId': lesson.lessonId,
                                                  'topicId': topic.topicId,
                                                  'title': lesson.lessonTitle,
                                                  'summary':
                                                      lesson.lessonSummary,
                                                  'minutes':
                                                      lesson.estimatedMinutes,
                                                  'freePreview':
                                                      lesson.isFreePreview,
                                                  'status':
                                                      lesson.status.dbValue,
                                                  'versionNumber':
                                                      lesson.versionNumber,
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (err, _) => AppCard(
            padding: const EdgeInsets.all(24),
            child: Text('Error loading curriculum catalog: $err'),
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: LearnTzTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: LearnTzColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Icon(icon, size: 20, color: color),
            ],
          ),
          Text(
            value,
            style: LearnTzTypography.h2.copyWith(
              fontWeight: FontWeight.bold,
              color: LearnTzColors.textPrimary,
            ),
          ),
          Text(
            subtitle,
            style: LearnTzTypography.caption.copyWith(
              color: LearnTzColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
