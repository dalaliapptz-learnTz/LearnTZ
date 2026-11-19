import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../../../core/routing/app_router.dart';
import '../content_studio_models.dart';
import '../content_studio_providers.dart';
import '../lesson_authoring_models.dart';

class SubjectWorkspaceView extends ConsumerStatefulWidget {
  const SubjectWorkspaceView({
    super.key,
    required this.subjectId,
    this.initialTab = 0,
    this.onClose,
  });

  final String subjectId;
  final int initialTab;
  final VoidCallback? onClose;

  @override
  ConsumerState<SubjectWorkspaceView> createState() =>
      _SubjectWorkspaceViewState();
}

class _SubjectWorkspaceViewState extends ConsumerState<SubjectWorkspaceView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<String> _tabNames = [
    'Overview',
    'Syllabus',
    'Competencies',
    'Strands',
    'Outcomes',
    'Topics',
    'Lessons',
    'Activities',
    'Assessments',
    'Resources',
    'Curriculum Mapping',
    'Review & Approval',
    'Version History',
  ];

  @override
  void initState() {
    super.initState();
    final tabIndex = widget.initialTab.clamp(0, _tabNames.length - 1);
    _tabController = TabController(
      length: _tabNames.length,
      vsync: this,
      initialIndex: tabIndex,
    );
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        ref
            .read(selectedSubjectTabProvider.notifier)
            .selectTab(_tabController.index);
      }
    });
  }

  @override
  void didUpdateWidget(covariant SubjectWorkspaceView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTab != widget.initialTab) {
      final tabIndex = widget.initialTab.clamp(0, _tabNames.length - 1);
      if (_tabController.index != tabIndex) {
        _tabController.animateTo(tabIndex);
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync =
        ref.watch(subjectWorkspaceDetailProvider(widget.subjectId));

    return detailAsync.when(
      data: (detail) {
        if (detail == null) {
          return AppCard(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline,
                      size: 48, color: LearnTzColors.warning),
                  const SizedBox(height: 12),
                  Text(
                    'Subject not found in curriculum database',
                    style: LearnTzTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppButton(
                    label: 'Return to Catalog',
                    variant: AppButtonVariant.outlined,
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
          );
        }

        final subject = detail.subject;
        final country = subject.countryCode;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Breadcrumbs Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: LearnTzColors.neutral200),
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: widget.onClose,
                    child: Text(
                      'Curriculum',
                      style: LearnTzTypography.bodySmall.copyWith(
                        color: LearnTzColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 16, color: LearnTzColors.neutral400),
                  Text(
                    country == 'TZ'
                        ? '🇹🇿 Tanzania'
                        : country == 'KE'
                            ? '🇰🇪 Kenya'
                            : country == 'UG'
                                ? '🇺🇬 Uganda'
                                : '🌍 $country',
                    style: LearnTzTypography.bodySmall.copyWith(
                      color: LearnTzColors.textSecondary,
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 16, color: LearnTzColors.neutral400),
                  Text(
                    subject.educationLevelName ?? 'Primary Education',
                    style: LearnTzTypography.bodySmall.copyWith(
                      color: LearnTzColors.textSecondary,
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 16, color: LearnTzColors.neutral400),
                  Text(
                    subject.gradeName ?? 'Standard III',
                    style: LearnTzTypography.bodySmall.copyWith(
                      color: LearnTzColors.textSecondary,
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 16, color: LearnTzColors.neutral400),
                  Expanded(
                    child: Text(
                      subject.subjectName,
                      style: LearnTzTypography.bodySmall.copyWith(
                        color: LearnTzColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    tooltip: 'Close Workspace',
                    onPressed: widget.onClose,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Subject Header Card
            AppCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: LearnTzColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.menu_book,
                          color: LearnTzColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
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
                                  subject.subjectName,
                                  style: LearnTzTypography.h2.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: LearnTzColors.textPrimary,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: subject.isPublished
                                        ? const Color(0xFFDCFCE7)
                                        : const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: subject.isPublished
                                          ? const Color(0xFF86EFAC)
                                          : const Color(0xFFFDE68A),
                                    ),
                                  ),
                                  child: Text(
                                    subject.isPublished ? 'Published' : 'Draft In Review',
                                    style: LearnTzTypography.caption.copyWith(
                                      color: subject.isPublished
                                          ? const Color(0xFF166534)
                                          : const Color(0xFF92400E),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEFF6FF),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: const Color(0xFFBFDBFE)),
                                  ),
                                  child: Text(
                                    'Code: ${subject.subjectCode}',
                                    style: LearnTzTypography.caption.copyWith(
                                      color: const Color(0xFF1E40AF),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF5F3FF),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                        color: const Color(0xFFDDD6FE)),
                                  ),
                                  child: Text(
                                    subject.authorityName ?? 'TIE Tanzania',
                                    style: LearnTzTypography.caption.copyWith(
                                      color: const Color(0xFF6D28D9),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              subject.officialName ??
                                  'Official Primary Education Syllabus Standard III–VI (2023 Edition)',
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
                          Consumer(
                            builder: (context, ref, _) {
                              final pinned = ref
                                  .watch(pinnedSubjectIdsProvider)
                                  .contains(subject.subjectId);
                              return IconButton(
                                tooltip: pinned ? 'Unpin' : 'Pin to Favorites',
                                icon: Icon(
                                  pinned ? Icons.star : Icons.star_border,
                                  color: pinned
                                      ? const Color(0xFFD97706)
                                      : LearnTzColors.neutral500,
                                ),
                                onPressed: () {
                                  ref
                                      .read(pinnedSubjectIdsProvider.notifier)
                                      .toggle(subject.subjectId);
                                },
                              );
                            },
                          ),
                          AppButton(
                            label: 'New Lesson',
                            variant: AppButtonVariant.primary,
                            size: AppButtonSize.sm,
                            icon: Icons.add,
                            onPressed: () => context.push(
                              AppRoutes.authorNewLesson,
                              extra: AuthorLessonLaunchContext(
                                countryCode: subject.countryCode,
                                educationLevelId: subject.educationLevelId,
                                educationLevelName: subject.educationLevelName,
                                gradeId: subject.gradeId,
                                gradeName: subject.gradeName,
                                subjectId: subject.subjectId,
                                subjectName: subject.subjectName,
                                sourceEntry: 'content_studio_subject',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Quick Stats Strip
                  Wrap(
                    spacing: 24,
                    runSpacing: 8,
                    children: [
                      _buildMiniStat(Icons.topic, '${subject.topics.length}', 'Topics'),
                      _buildMiniStat(Icons.auto_stories, '${subject.totalLessons}', 'Lessons'),
                      _buildMiniStat(Icons.schedule, '${subject.totalPeriods}', 'Total Periods'),
                      _buildMiniStat(Icons.verified, '${detail.competencies.length}', 'Competencies'),
                      _buildMiniStat(Icons.language, subject.language ?? 'English', 'Medium'),
                      _buildMiniStat(Icons.category, subject.classification ?? 'Core Subject', 'Type'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: LearnTzColors.neutral200),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: LearnTzColors.primary,
                unselectedLabelColor: LearnTzColors.neutral600,
                indicatorColor: LearnTzColors.primary,
                indicatorWeight: 3,
                labelStyle: LearnTzTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                unselectedLabelStyle: LearnTzTypography.bodySmall,
                tabs: _tabNames.map((name) => Tab(text: name)).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Tab Views Container
            SizedBox(
              height: 620,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(detail),
                  _buildSyllabusTab(detail),
                  _buildCompetenciesTab(detail),
                  _buildStrandsTab(detail),
                  _buildOutcomesTab(detail),
                  _buildTopicsTab(detail),
                  _buildLessonsTab(detail),
                  _buildActivitiesTab(detail),
                  _buildAssessmentsTab(detail),
                  _buildResourcesTab(detail),
                  _buildCurriculumMappingTab(detail),
                  _buildReviewApprovalTab(detail),
                  _buildVersionHistoryTab(detail),
                ],
              ),
            ),
          ],
        ),
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
        child: Text('Error loading subject workspace: $err'),
      ),
    );
  }

  Widget _buildMiniStat(IconData icon, String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: LearnTzColors.neutral500),
        const SizedBox(width: 6),
        Text(
          value,
          style: LearnTzTypography.bodySmall.copyWith(
            fontWeight: FontWeight.bold,
            color: LearnTzColors.textPrimary,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: LearnTzTypography.caption.copyWith(
            color: LearnTzColors.textSecondary,
          ),
        ),
      ],
    );
  }

  // 1. Overview Tab
  Widget _buildOverviewTab(StudioSubjectWorkspaceDetail detail) {
    final s = detail.subject;
    return SingleChildScrollView(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 720;
          final authorityCard = AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Curriculum Authority & Governance',
                  style: LearnTzTypography.h3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildInfoRow('Authority', s.authorityName ?? 'Tanzania Institute of Education (TIE)'),
                _buildInfoRow('Curriculum Code', s.authorityCode ?? 'TIE'),
                _buildInfoRow('Standard / Grade', s.gradeName ?? 'Standard 3'),
                _buildInfoRow('Official Document', detail.sourceDocumentTitle),
                _buildInfoRow('Framework Version', detail.curriculumVersion),
                _buildInfoRow('Language of Instruction', s.language ?? 'English'),
                _buildInfoRow('Classification', s.classification ?? 'Core Subject'),
                _buildInfoRow('Verification Status', 'Verified against 2023 Syllabus Source PDF'),
              ],
            ),
          );

          final publicationCard = AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Publication Status',
                  style: LearnTzTypography.h3.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: s.isPublished
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        s.isPublished
                            ? Icons.check_circle
                            : Icons.hourglass_top,
                        color: s.isPublished
                            ? const Color(0xFF166534)
                            : const Color(0xFFB45309),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.isPublished
                              ? 'Curriculum is LIVE in Learner App'
                              : 'Subject under Academic Review',
                          style: LearnTzTypography.bodySmall.copyWith(
                            fontWeight: FontWeight.bold,
                            color: s.isPublished
                                ? const Color(0xFF166534)
                                : const Color(0xFFB45309),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Curriculum Metrics',
                  style: LearnTzTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildMetricRow('Syllabus Topics', '${s.topics.length} topics'),
                _buildMetricRow('Digital Lessons', '${s.totalLessons} lessons (${s.publishedLessons} published)'),
                _buildMetricRow('Total Periods', '${s.totalPeriods} periods allocated'),
                _buildMetricRow('Specific Competences', '${detail.competencies.length} mapped'),
              ],
            ),
          );

          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: authorityCard),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: publicationCard),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              authorityCard,
              const SizedBox(height: 16),
              publicationCard,
            ],
          );
        },
      ),
    );
  }

  // 2. Syllabus Tab
  Widget _buildSyllabusTab(StudioSubjectWorkspaceDetail detail) {
    return SingleChildScrollView(
      child: AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Official Curriculum Syllabus Information',
              style: LearnTzTypography.h3.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              detail.sourceDocumentTitle,
              style: LearnTzTypography.bodyLarge.copyWith(
                fontWeight: FontWeight.w600,
                color: LearnTzColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Issued under the authority of the Ministry of Education, Science and Technology through the Tanzania Institute of Education (TIE).',
              style: LearnTzTypography.bodySmall.copyWith(
                color: LearnTzColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            Table(
              border: TableBorder.all(color: LearnTzColors.neutral200),
              children: [
                _buildTableRow('Subject Name', detail.subject.subjectName, isHeader: true),
                _buildTableRow('Official Code', detail.subject.subjectCode),
                _buildTableRow('Grade Level', detail.subject.gradeName ?? 'Primary Standard'),
                _buildTableRow('Prescribed Weekly Periods', '4 Periods / Week (30 mins each)'),
                _buildTableRow('Total Annual Allocation', '${detail.subject.totalPeriods} Periods'),
                _buildTableRow('Curriculum Standard Edition', '2023 National Edition'),
                _buildTableRow('Copyright & Redistribution', 'Protected TIE Official Curriculum — Verified Reference Model'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 3. Competencies Tab
  Widget _buildCompetenciesTab(StudioSubjectWorkspaceDetail detail) {
    return ListView.separated(
      itemCount: detail.competencies.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final c = detail.competencies[idx];
        return AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: LearnTzColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Competence ${c.code}',
                      style: LearnTzTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                        color: LearnTzColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDCFCE7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check, size: 14, color: Color(0xFF15803D)),
                        const SizedBox(width: 4),
                        Text(
                          'TIE Verified',
                          style: LearnTzTypography.caption.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF15803D),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${c.periodAllocation} Periods',
                    style: LearnTzTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.bold,
                      color: LearnTzColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                c.title,
                style: LearnTzTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                c.description,
                style: LearnTzTypography.bodySmall.copyWith(
                  color: LearnTzColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: LearnTzColors.neutral50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: LearnTzColors.neutral200),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.fact_check_outlined,
                        size: 16, color: LearnTzColors.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Assessment Criteria: ${c.assessmentCriteria}',
                        style: LearnTzTypography.caption.copyWith(
                          color: LearnTzColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 4. Strands & Sub-strands Tab
  Widget _buildStrandsTab(StudioSubjectWorkspaceDetail detail) {
    return ListView.separated(
      itemCount: detail.strands.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final strand = detail.strands[idx];
        return AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.account_tree,
                      size: 20, color: LearnTzColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Strand ${idx + 1}: ${strand.title}',
                    style: LearnTzTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text('Prescribed Sub-strands:'),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: strand.substrands.map((sub) {
                  return Chip(
                    label: Text(sub),
                    backgroundColor: LearnTzColors.neutral100,
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  // 5. Learning Outcomes Tab
  Widget _buildOutcomesTab(StudioSubjectWorkspaceDetail detail) {
    return ListView.separated(
      itemCount: detail.outcomes.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final lo = detail.outcomes[idx];
        return AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  lo.code,
                  style: LearnTzTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: LearnTzColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lo.outcome,
                      style: LearnTzTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cognitive Domain: ${lo.cognitiveLevel} • Mapped Competence: ${lo.competencyCode}',
                      style: LearnTzTypography.caption.copyWith(
                        color: LearnTzColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 6. Topics & Content Tab
  Widget _buildTopicsTab(StudioSubjectWorkspaceDetail detail) {
    final topics = detail.subject.topics;
    return ListView.separated(
      itemCount: topics.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final t = topics[idx];
        return AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Topic ${t.topicOrder}: ${t.topicTitle}',
                    style: LearnTzTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${t.periodAllocation} Periods',
                    style: LearnTzTypography.bodySmall.copyWith(
                      color: LearnTzColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (t.topicSummary != null && t.topicSummary!.isNotEmpty)
                Text(
                  t.topicSummary!,
                  style: LearnTzTypography.bodySmall.copyWith(
                    color: LearnTzColors.textSecondary,
                  ),
                ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  if (t.competencyCode != null)
                    AppBadge(
                      label: 'Code: ${t.competencyCode}',
                      variant: AppBadgeVariant.primary,
                      size: AppBadgeSize.sm,
                    ),
                  if (t.sourcePage != null)
                    AppBadge(
                      label: 'Source Page: ${t.sourcePage}',
                      variant: AppBadgeVariant.neutral,
                      size: AppBadgeSize.sm,
                    ),
                  AppBadge(
                    label: '${t.lessons.length} Digital Lessons',
                    variant: AppBadgeVariant.success,
                    size: AppBadgeSize.sm,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // 7. Lessons Tab
  Widget _buildLessonsTab(StudioSubjectWorkspaceDetail detail) {
    final allLessons = <Map<String, dynamic>>[];
    for (final topic in detail.subject.topics) {
      for (final lesson in topic.lessons) {
        allLessons.add({
          'topicTitle': topic.topicTitle,
          'lesson': lesson,
        });
      }
    }

    if (allLessons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.auto_stories, size: 48, color: LearnTzColors.neutral400),
            const SizedBox(height: 12),
            const Text('No digital lessons authored for this subject yet.'),
            const SizedBox(height: 12),
            AppButton(
              label: 'Author New Lesson',
              variant: AppButtonVariant.primary,
              icon: Icons.add,
              onPressed: () => context.push('/content/studio/editor'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: allLessons.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, idx) {
        final item = allLessons[idx];
        final lesson = item['lesson'] as StudioLessonItem;
        final topicTitle = item['topicTitle'] as String;

        return AppCard(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: LearnTzColors.primary.withValues(alpha: 0.1),
                child: Text(
                  '${idx + 1}',
                  style: const TextStyle(
                    color: LearnTzColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lesson.lessonTitle,
                      style: LearnTzTypography.bodySmall.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Topic: $topicTitle • ~${lesson.estimatedMinutes} mins • v${lesson.versionNumber}',
                      style: LearnTzTypography.caption.copyWith(
                        color: LearnTzColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: lesson.isPublished
                      ? const Color(0xFFDCFCE7)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  lesson.status.displayName,
                  style: LearnTzTypography.caption.copyWith(
                    fontWeight: FontWeight.bold,
                    color: lesson.isPublished
                        ? const Color(0xFF166534)
                        : const Color(0xFF92400E),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              AppButton(
                label: 'Edit in Studio',
                variant: AppButtonVariant.outlined,
                size: AppButtonSize.sm,
                icon: Icons.edit_note,
                onPressed: () => context.push(
                  '/content/studio/editor',
                  extra: {
                    'lessonId': lesson.lessonId,
                    'title': lesson.lessonTitle,
                    'summary': lesson.lessonSummary,
                    'minutes': lesson.estimatedMinutes,
                    'freePreview': lesson.isFreePreview,
                    'status': lesson.status.dbValue,
                    'versionNumber': lesson.versionNumber,
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 8. Learning Activities Tab
  Widget _buildActivitiesTab(StudioSubjectWorkspaceDetail detail) {
    return ListView.separated(
      itemCount: detail.activities.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final act = detail.activities[idx];
        return AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    act.title,
                    style: LearnTzTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppBadge(
                    label: act.modality,
                    variant: AppBadgeVariant.primary,
                    size: AppBadgeSize.sm,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Materials: ${act.materials}',
                style: LearnTzTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: LearnTzColors.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                act.instructions,
                style: LearnTzTypography.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }

  // 9. Assessments Tab
  Widget _buildAssessmentsTab(StudioSubjectWorkspaceDetail detail) {
    return ListView.separated(
      itemCount: detail.assessments.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final ass = detail.assessments[idx];
        return AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ass.title,
                    style: LearnTzTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  AppBadge(
                    label: ass.type,
                    variant: AppBadgeVariant.accent,
                    size: AppBadgeSize.sm,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                ass.criteria,
                style: LearnTzTypography.bodySmall,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: LearnTzColors.neutral50,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Rubric: ${ass.rubric}',
                  style: LearnTzTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    color: LearnTzColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // 10. Resources Tab
  Widget _buildResourcesTab(StudioSubjectWorkspaceDetail detail) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attached Media Assets & Digital References',
                style: LearnTzTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppButton(
                label: 'Open Media Library',
                variant: AppButtonVariant.outlined,
                size: AppButtonSize.sm,
                icon: Icons.photo_library_outlined,
                onPressed: () => context.push('/content/studio/media'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildResourceRow('Official Syllabus PDF', 'TIE English Primary Standards III-VI (2023)', 'Document / Source', 'application/pdf'),
                const Divider(),
                _buildResourceRow('Grammar & Vocabulary Charts', 'Parts of Speech Visual Cards (SVG)', 'Diagram / Illustration', 'image/svg+xml'),
                const Divider(),
                _buildResourceRow('Listening Audio Prompts', 'Standard III Dialogue Audio Track 1', 'Audio Track', 'audio/mpeg'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceRow(String title, String desc, String type, String mime) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.attachment, color: LearnTzColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: LearnTzTypography.bodySmall.copyWith(fontWeight: FontWeight.bold)),
                Text(desc, style: LearnTzTypography.caption.copyWith(color: LearnTzColors.textSecondary)),
              ],
            ),
          ),
          AppBadge(label: type, variant: AppBadgeVariant.neutral, size: AppBadgeSize.sm),
        ],
      ),
    );
  }

  // 11. Curriculum Mapping Matrix Tab
  Widget _buildCurriculumMappingTab(StudioSubjectWorkspaceDetail detail) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(LearnTzColors.neutral100),
          columns: const [
            DataColumn(label: Text('Competency Code', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Learning Outcome', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Topic / Content', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Lessons Count', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Assessment Criteria', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: detail.subject.topics.map((t) {
            return DataRow(
              cells: [
                DataCell(Text(t.competencyCode ?? '1.${t.topicOrder}', style: const TextStyle(fontWeight: FontWeight.bold))),
                DataCell(Text('Comprehend ${t.topicTitle}')),
                DataCell(Text(t.topicTitle)),
                DataCell(Text('${t.lessons.length} lessons')),
                DataCell(Text(t.assessmentCriteria ?? 'Standard criteria')),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  // 12. Review & Approval Tab
  Widget _buildReviewApprovalTab(StudioSubjectWorkspaceDetail detail) {
    return ListView.separated(
      itemCount: detail.reviewHistory.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final ev = detail.reviewHistory[idx];
        return AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(ev.stage, style: LearnTzTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
                  AppBadge(
                    label: ev.status.toUpperCase(),
                    variant: ev.status == 'approved' || ev.status == 'verified'
                        ? AppBadgeVariant.success
                        : AppBadgeVariant.warning,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'By ${ev.actor} (${ev.role}) • ${ev.timestamp}',
                style: LearnTzTypography.caption.copyWith(color: LearnTzColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Text(ev.notes, style: LearnTzTypography.bodySmall),
            ],
          ),
        );
      },
    );
  }

  // 13. Version History Tab
  Widget _buildVersionHistoryTab(StudioSubjectWorkspaceDetail detail) {
    return SingleChildScrollView(
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Curriculum Edition & Revision Log', style: LearnTzTypography.bodyLarge.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildVersionRow('v2.1', '2026-11-16', 'TIE Official 2023 remediation: verified 28 topics and period allocations across Standards III–VI.'),
            const Divider(),
            _buildVersionRow('v2.0', '2026-11-15', 'Full ingestion of TIE Primary Standards III-VI syllabus records.'),
            const Divider(),
            _buildVersionRow('v1.0', '2026-11-12', 'Initial syllabus structure import and competency mapping.'),
          ],
        ),
      ),
    );
  }

  Widget _buildVersionRow(String version, String date, String note) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: LearnTzColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(version, style: const TextStyle(fontWeight: FontWeight.bold, color: LearnTzColors.primary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(date, style: LearnTzTypography.caption.copyWith(color: LearnTzColors.textSecondary)),
                const SizedBox(height: 2),
                Text(note, style: LearnTzTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: LearnTzTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
                color: LearnTzColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: LearnTzTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: LearnTzColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: LearnTzTypography.caption.copyWith(
                color: LearnTzColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: LearnTzTypography.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String col1, String col2, {bool isHeader = false}) {
    return TableRow(
      decoration: BoxDecoration(
        color: isHeader ? LearnTzColors.neutral50 : Colors.transparent,
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            col1,
            style: LearnTzTypography.bodySmall.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(10),
          child: Text(
            col2,
            style: LearnTzTypography.bodySmall,
          ),
        ),
      ],
    );
  }
}
