import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../content_studio_providers.dart';
import '../widgets/content_studio_overview_pane.dart';
import '../widgets/curriculum_explorer_tree.dart';
import '../widgets/subject_workspace_view.dart';

class ContentStudioDashboardScreen extends ConsumerWidget {
  const ContentStudioDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metricsAsync = ref.watch(contentStudioMetricsProvider);
    final catalogAsync = ref.watch(contentStudioCatalogProvider);
    final hierarchyAsync = ref.watch(contentStudioHierarchyProvider);
    final selectedSubjectId = ref.watch(selectedSubjectIdProvider);
    final selectedTab = ref.watch(selectedSubjectTabProvider);

    return Scaffold(
      backgroundColor: LearnTzColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1440),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 640;
                    if (isNarrow) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => context.go('/home'),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Content Studio',
                                  style: LearnTzTypography.h3.copyWith(
                                    fontWeight: FontWeight.w800,
                                    color: LearnTzColors.textPrimary,
                                  ),
                                ),
                              ),
                              const AppBadge(
                                label: 'Authoring',
                                variant: AppBadgeVariant.primary,
                                size: AppBadgeSize.sm,
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  label: 'Media Library',
                                  variant: AppButtonVariant.outlined,
                                  size: AppButtonSize.sm,
                                  icon: Icons.photo_library_outlined,
                                  onPressed: () =>
                                      context.push('/content/studio/media'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: AppButton(
                                  key: const Key('create-new-lesson-btn'),
                                  label: 'New Lesson',
                                  variant: AppButtonVariant.primary,
                                  size: AppButtonSize.sm,
                                  icon: Icons.add,
                                  onPressed: () =>
                                      context.push('/content/studio/editor'),
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
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => context.go('/home'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 10,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    'Content Management Studio',
                                    style: LearnTzTypography.h2.copyWith(
                                      fontWeight: FontWeight.w800,
                                      color: LearnTzColors.textPrimary,
                                    ),
                                  ),
                                  const AppBadge(
                                    label: 'Authoring & Editorial Cockpit',
                                    variant: AppBadgeVariant.primary,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Interactive Curriculum Authoring, Markdown Lesson Studio, Version History & Two-Party Review',
                                style: LearnTzTypography.bodyRegular.copyWith(
                                  color: LearnTzColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Wrap(
                          spacing: 8,
                          children: [
                            AppButton(
                              label: 'Media Library',
                              variant: AppButtonVariant.outlined,
                              size: AppButtonSize.md,
                              icon: Icons.photo_library_outlined,
                              onPressed: () =>
                                  context.push('/content/studio/media'),
                            ),
                            AppButton(
                              key: const Key('create-new-lesson-btn'),
                              label: 'New Lesson',
                              variant: AppButtonVariant.primary,
                              size: AppButtonSize.md,
                              icon: Icons.add,
                              onPressed: () =>
                                  context.push('/content/studio/editor'),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Main Workspace Layout: Left Sidebar Tree + Right Pane
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isDesktop = constraints.maxWidth >= 960;
                    final countries = hierarchyAsync.value ?? [];
                    final catalogSubjects = catalogAsync.value ?? [];

                    final treeWidget = CurriculumExplorerTree(
                      countries: countries,
                      catalogSubjects: catalogSubjects,
                      onSelectSubject: (subjectId, [tabIndex]) {
                        ref
                            .read(selectedSubjectIdProvider.notifier)
                            .select(subjectId);
                        if (tabIndex != null) {
                          ref
                              .read(selectedSubjectTabProvider.notifier)
                              .selectTab(tabIndex);
                        }
                      },
                      onSelectOverview: () {
                        ref
                            .read(selectedSubjectIdProvider.notifier)
                            .select(null);
                      },
                    );

                    final rightPaneWidget = selectedSubjectId != null
                        ? SubjectWorkspaceView(
                            subjectId: selectedSubjectId,
                            initialTab: selectedTab,
                            onClose: () {
                              ref
                                  .read(selectedSubjectIdProvider.notifier)
                                  .select(null);
                            },
                          )
                        : ContentStudioOverviewPane(
                            metricsAsync: metricsAsync,
                            catalogAsync: catalogAsync,
                            onSelectSubject: (subjectId) {
                              ref
                                  .read(selectedSubjectIdProvider.notifier)
                                  .select(subjectId);
                            },
                          );

                    if (isDesktop) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Sidebar: Curriculum Explorer Tree
                          SizedBox(
                            width: 320,
                            height: 820,
                            child: treeWidget,
                          ),
                          const SizedBox(width: 24),
                          // Right Main Workspace Pane
                          Expanded(
                            child: rightPaneWidget,
                          ),
                        ],
                      );
                    }

                    // Mobile / Tablet stacked layout
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ExpansionTile(
                          title: Row(
                            children: [
                              const Icon(Icons.account_tree,
                                  color: LearnTzColors.primary, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Curriculum Explorer Hierarchy',
                                style: LearnTzTypography.bodySmall.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          initiallyExpanded: false,
                          children: [
                            SizedBox(
                              height: 480,
                              child: treeWidget,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        rightPaneWidget,
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
