import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../../../core/routing/app_router.dart';
import '../../content_studio/widgets/searchable_curriculum_dropdown.dart';
import '../exam_v2_models.dart';
import '../exam_v2_providers.dart';
import '../widgets/exam_v2_creation_dialog.dart';
import '../widgets/exam_v2_question_dialog.dart';
import '../widgets/exam_v2_review_dialog.dart';
import 'exam_v2_paper_builder_screen.dart';

class ExamCentreV2Screen extends ConsumerStatefulWidget {
  const ExamCentreV2Screen({super.key});

  @override
  ConsumerState<ExamCentreV2Screen> createState() => _ExamCentreV2ScreenState();
}

class _ExamCentreV2ScreenState extends ConsumerState<ExamCentreV2Screen> {
  ExamV2CountryOption? _selectedCountry;
  ExamV2EducationLevelOption? _selectedLevel;
  ExamV2GradeOption? _selectedGrade;
  ExamV2SubjectOption? _selectedSubject;
  ExamV2ExaminationTypeOption? _selectedExamType;

  String _activeNavSection = 'overview';

  bool get _isContextComplete =>
      _selectedCountry != null &&
      _selectedLevel != null &&
      _selectedGrade != null &&
      _selectedSubject != null &&
      _selectedExamType != null;

  ExamV2SelectionKey? get _selectionKey {
    if (!_isContextComplete) return null;
    return ExamV2SelectionKey(
      countryCode: _selectedCountry!.countryCode,
      educationLevelId: _selectedLevel!.id,
      gradeId: _selectedGrade!.id,
      subjectId: _selectedSubject!.id,
      examinationTypeId: _selectedExamType!.id,
    );
  }

  void _onCountryChanged(
    String? countryCode,
    List<ExamV2CountryOption> countries,
  ) {
    final match =
        countries.where((c) => c.countryCode == countryCode).firstOrNull;
    setState(() {
      _selectedCountry = match;
      _selectedLevel = null;
      _selectedGrade = null;
      _selectedSubject = null;
      _selectedExamType = null;
    });
  }

  void _onLevelChanged(
    String? levelId,
    List<ExamV2EducationLevelOption> levels,
  ) {
    final match = levels.where((l) => l.id == levelId).firstOrNull;
    setState(() {
      _selectedLevel = match;
      _selectedGrade = null;
      _selectedSubject = null;
      _selectedExamType = null;
    });
  }

  void _onGradeChanged(String? gradeId, List<ExamV2GradeOption> grades) {
    final match = grades.where((g) => g.id == gradeId).firstOrNull;
    setState(() {
      _selectedGrade = match;
      _selectedSubject = null;
    });
  }

  void _onSubjectChanged(
    String? subjectId,
    List<ExamV2SubjectOption> subjects,
  ) {
    final match = subjects.where((s) => s.id == subjectId).firstOrNull;
    setState(() {
      _selectedSubject = match;
    });
  }

  void _onExamTypeChanged(
    String? examTypeId,
    List<ExamV2ExaminationTypeOption> types,
  ) {
    final match = types.where((t) => t.id == examTypeId).firstOrNull;
    setState(() {
      _selectedExamType = match;
    });
  }

  void _resetSelection() {
    setState(() {
      _selectedCountry = null;
      _selectedLevel = null;
      _selectedGrade = null;
      _selectedSubject = null;
      _selectedExamType = null;
    });
  }

  void _handleNavSelect(_ExamNavItem item) {
    if (item.externalRoute != null) {
      context.push(item.externalRoute!);
      return;
    }
    setState(() => _activeNavSection = item.id);
  }

  static const _navItems = [
    _ExamNavItem(
      id: 'overview',
      label: 'Overview',
      subtitle: 'Academic context & overview',
      icon: Icons.dashboard_outlined,
      phaseBadge: 'Phase 1',
    ),
    _ExamNavItem(
      id: 'examinations',
      label: 'Examinations',
      subtitle: 'Create & manage papers',
      icon: Icons.assignment_outlined,
    ),
    _ExamNavItem(
      id: 'question_bank',
      label: 'Question Bank 2.0',
      subtitle: 'Curriculum-mapped items',
      icon: Icons.quiz_outlined,
    ),
    _ExamNavItem(
      id: 'paper_builder',
      label: 'Paper Builder',
      subtitle: 'Compose structured papers',
      icon: Icons.article_outlined,
    ),
    _ExamNavItem(
      id: 'candidates',
      label: 'Candidates',
      subtitle: 'Registration & allocation',
      icon: Icons.groups_outlined,
      phaseBadge: 'Phase 7',
    ),
    _ExamNavItem(
      id: 'sessions',
      label: 'Examination Sessions',
      subtitle: 'Timetables & attendance',
      icon: Icons.event_note_outlined,
      phaseBadge: 'Phase 7',
    ),
    _ExamNavItem(
      id: 'online_exams',
      label: 'Online Examinations',
      subtitle: 'Past papers & timed runner',
      icon: Icons.laptop_chromebook_outlined,
      externalRoute: AppRoutes.examCentre,
    ),
    _ExamNavItem(
      id: 'marking',
      label: 'Marking & Assessment',
      subtitle: 'Auto & manual marking',
      icon: Icons.grading_outlined,
      phaseBadge: 'Phase 9',
    ),
    _ExamNavItem(
      id: 'analytics',
      label: 'Results & Analytics',
      subtitle: 'Competency performance',
      icon: Icons.insights_outlined,
      externalRoute: AppRoutes.mockIntelligence,
    ),
    _ExamNavItem(
      id: 'review',
      label: 'Review & Approval',
      subtitle: 'Academic quality assurance',
      icon: Icons.fact_check_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 1024;
        return Scaffold(
          backgroundColor: LearnTzColors.background,
          drawer: isDesktop
              ? null
              : Drawer(
                  backgroundColor: Colors.white,
                  child: SafeArea(child: _buildSidebar(closeDrawer: true)),
                ),
          body: SafeArea(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isDesktop)
                  Container(
                    width: 268,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        right: BorderSide(color: LearnTzColors.border),
                      ),
                    ),
                    child: _buildSidebar(closeDrawer: false),
                  ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 28 : 16,
                      vertical: 20,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1180),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTopBar(context, isDesktop: isDesktop),
                            const SizedBox(height: 16),
                            _buildBreadcrumbStrip(),
                            const SizedBox(height: 16),
                            if (_activeNavSection == 'review') ...[
                              _buildReviewApprovalCockpit(),
                            ] else ...[
                              if (_activeNavSection != 'overview' &&
                                  _activeNavSection != 'examinations' &&
                                  _activeNavSection != 'question_bank' &&
                                  _activeNavSection != 'paper_builder') ...[
                                _buildUpcomingPhaseBanner(),
                                const SizedBox(height: 16),
                              ],
                              _buildAcademicSelectionCard(),
                              const SizedBox(height: 20),
                              if (_isContextComplete)
                                _buildVerifiedContextWorkspace()
                              else
                                _buildLockedWorkspaceNotice(),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSidebar({required bool closeDrawer}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F4C81),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.school_outlined,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Examination Centre',
                          style: LearnTzTypography.bodyRegular.copyWith(
                            fontWeight: FontWeight.w800,
                            color: LearnTzColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Design 2.0 • Academic Workspace',
                          style: LearnTzTypography.caption.copyWith(
                            color: LearnTzColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
          child: Text(
            'ACADEMIC MANAGEMENT',
            style: LearnTzTypography.caption.copyWith(
              color: LearnTzColors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            itemCount: _navItems.length,
            itemBuilder: (context, index) {
              final item = _navItems[index];
              final isSelected = _activeNavSection == item.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Material(
                  color: isSelected
                      ? const Color(0xFF0F4C81).withValues(alpha: 0.09)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      if (closeDrawer) Navigator.of(context).pop();
                      _handleNavSelect(item);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 19,
                            color: isSelected
                                ? const Color(0xFF0F4C81)
                                : LearnTzColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label,
                                  style: LearnTzTypography.bodySmall.copyWith(
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: isSelected
                                        ? const Color(0xFF0F4C81)
                                        : LearnTzColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  item.subtitle,
                                  style: LearnTzTypography.caption.copyWith(
                                    color: LearnTzColors.textSecondary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          if (item.phaseBadge != null && item.id != 'overview')
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.phaseBadge!,
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(BuildContext context, {required bool isDesktop}) {
    final titleWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Examination Centre 2.0',
              style: (isDesktop ? LearnTzTypography.h2 : LearnTzTypography.h3)
                  .copyWith(
                fontWeight: FontWeight.w800,
                color: LearnTzColors.textPrimary,
              ),
            ),
            const AppBadge(
              label: 'Phase 1 • Curriculum-Driven',
              variant: AppBadgeVariant.primary,
              size: AppBadgeSize.sm,
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Select the official 5-step academic context before creating or accessing curriculum-aligned examinations.',
          style: LearnTzTypography.bodySmall.copyWith(
            color: LearnTzColors.textSecondary,
          ),
        ),
      ],
    );

    if (!isDesktop) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Builder(
                builder: (ctx) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.examCentre);
                  }
                },
              ),
              const Spacer(),
              if (_selectedCountry != null)
                AppButton(
                  key: const Key('exam-v2-reset-btn'),
                  label: 'Reset',
                  variant: AppButtonVariant.outlined,
                  size: AppButtonSize.sm,
                  icon: Icons.restart_alt,
                  onPressed: _resetSelection,
                ),
            ],
          ),
          const SizedBox(height: 4),
          titleWidget,
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.examCentre);
            }
          },
        ),
        const SizedBox(width: 4),
        Expanded(child: titleWidget),
        if (_selectedCountry != null) ...[
          const SizedBox(width: 8),
          AppButton(
            key: const Key('exam-v2-reset-btn'),
            label: 'Reset',
            variant: AppButtonVariant.outlined,
            size: AppButtonSize.sm,
            icon: Icons.restart_alt,
            onPressed: _resetSelection,
          ),
        ],
      ],
    );
  }

  Widget _buildBreadcrumbStrip() {
    final parts = <String>[
      _selectedCountry?.displayName ?? 'Select Country',
      if (_selectedCountry?.curriculumVersionCode != null)
        '${_selectedCountry!.curriculumName} (${_selectedCountry!.curriculumVersionCode})',
      if (_selectedLevel != null) _selectedLevel!.name,
      if (_selectedGrade != null) _selectedGrade!.name,
      if (_selectedSubject != null) _selectedSubject!.name,
      if (_selectedExamType != null) _selectedExamType!.name,
    ];

    return Container(
      key: const Key('exam-v2-breadcrumb'),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F4C81),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_tree_outlined, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              parts.join('  →  '),
              style: LearnTzTypography.bodySmall.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewApprovalCockpit() {
    final queueKey = (
      countryCode: _selectedCountry?.countryCode,
      status: 'all_reviewable',
    );
    final queueAsync = ref.watch(examV2ReviewQueueProvider(queueKey));

    return Container(
      key: const Key('exam-v2-review-cockpit'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LearnTzColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Examination Review & Approval Queue',
                    style: LearnTzTypography.h3.copyWith(
                      color: const Color(0xFF0F4C81),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Two-party academic quality assurance, reviewer checklist verification, and controlled publication.',
                    style: LearnTzTypography.caption.copyWith(
                      color: LearnTzColors.textSecondary,
                    ),
                  ),
                ],
              ),
              AppButton(
                label: 'Refresh Queue',
                icon: Icons.refresh,
                variant: AppButtonVariant.outlined,
                size: AppButtonSize.sm,
                onPressed: () =>
                    ref.invalidate(examV2ReviewQueueProvider(queueKey)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          queueAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (err, _) => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Text(
                err.toString(),
                style: LearnTzTypography.bodySmall.copyWith(
                  color: const Color(0xFF991B1B),
                ),
              ),
            ),
            data: (queue) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _ContextPill(
                        label: 'Awaiting Review',
                        value: '${queue.awaitingReviewCount}',
                      ),
                      _ContextPill(
                        label: 'Revision Requested',
                        value: '${queue.revisionRequestedCount}',
                      ),
                      _ContextPill(
                        label: 'Approved',
                        value: '${queue.approvedCount}',
                      ),
                      _ContextPill(
                        label: 'Published',
                        value: '${queue.publishedCount}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (queue.items.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: LearnTzColors.border),
                      ),
                      child: Text(
                        'No examinations are currently awaiting review or publication.',
                        style: LearnTzTypography.bodySmall.copyWith(
                          color: LearnTzColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    ...queue.items.map((item) {
                      final statusVariant = switch (item.status) {
                        'approved' => AppBadgeVariant.primary,
                        'revision_requested' => AppBadgeVariant.error,
                        'published' => AppBadgeVariant.success,
                        _ => AppBadgeVariant.warning,
                      };
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: LearnTzColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              children: [
                                AppBadge(
                                  label: item.status.replaceAll('_', ' '),
                                  variant: statusVariant,
                                  size: AppBadgeSize.sm,
                                ),
                                AppBadge(
                                  label:
                                      '${item.countryName} • ${item.gradeName} • ${item.subjectName}',
                                  variant: AppBadgeVariant.neutral,
                                  size: AppBadgeSize.sm,
                                ),
                                AppBadge(
                                  label: 'v${item.versionNumber}',
                                  variant: AppBadgeVariant.neutral,
                                  size: AppBadgeSize.sm,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item.title,
                              style: LearnTzTypography.bodyRegular.copyWith(
                                fontWeight: FontWeight.w700,
                                color: LearnTzColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Author: ${item.authorName} • ${item.totalMarks.toStringAsFixed(0)} marks • ${item.questionCount} questions • ${item.competencyCount} competencies',
                              style: LearnTzTypography.caption.copyWith(
                                color: LearnTzColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                AppButton(
                                  label: 'Inspect Paper',
                                  icon: Icons.article_outlined,
                                  variant: AppButtonVariant.outlined,
                                  size: AppButtonSize.sm,
                                  onPressed: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            ExamV2PaperBuilderScreen(
                                          examinationId: item.examinationId,
                                          selection: item.toSelectionKey(),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                AppButton(
                                  key: Key(
                                    'exam-v2-review-decide-${item.examinationId}',
                                  ),
                                  label: 'Review & Decide',
                                  icon: Icons.fact_check_outlined,
                                  variant: AppButtonVariant.primary,
                                  size: AppButtonSize.sm,
                                  onPressed: () async {
                                    final changed = await showDialog<bool>(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) => ExamV2ReviewDialog(
                                        item: item,
                                        canPublish: queue.canPublish,
                                      ),
                                    );
                                    if (changed == true && mounted) {
                                      ref.invalidate(
                                        examV2ReviewQueueProvider(queueKey),
                                      );
                                    }
                                  },
                                ),
                              ],
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
    );
  }

  Widget _buildUpcomingPhaseBanner() {
    final item = _navItems.firstWhere(
      (n) => n.id == _activeNavSection,
      orElse: () => _navItems.first,
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.construction_outlined, color: Color(0xFFD97706)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${item.label} is scheduled for ${item.phaseBadge ?? 'an upcoming phase'}. Complete the 5-step academic selection below to inspect the verified curriculum context now.',
              style: LearnTzTypography.bodySmall.copyWith(
                color: const Color(0xFF92400E),
              ),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _activeNavSection = 'overview'),
            child: const Text('Back to Overview'),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademicSelectionCard() {
    final countriesAsync = ref.watch(examV2CountriesProvider);

    final levelsAsync = _selectedCountry == null
        ? const AsyncValue<List<ExamV2EducationLevelOption>>.data([])
        : ref.watch(
            examV2EducationLevelsProvider(_selectedCountry!.countryCode),
          );

    final gradesAsync = (_selectedCountry == null || _selectedLevel == null)
        ? const AsyncValue<List<ExamV2GradeOption>>.data([])
        : ref.watch(
            examV2GradesProvider((
              curriculumId: _selectedLevel!.curriculumId,
              levelId: _selectedLevel!.id,
            )),
          );

    final subjectsAsync = (_selectedCountry == null ||
            _selectedLevel == null ||
            _selectedGrade == null)
        ? const AsyncValue<List<ExamV2SubjectOption>>.data([])
        : ref.watch(
            examV2SubjectsProvider((
              curriculumId: _selectedLevel!.curriculumId,
              levelId: _selectedLevel!.id,
              gradeId: _selectedGrade!.id,
            )),
          );

    final examTypesAsync = (_selectedCountry == null || _selectedLevel == null)
        ? const AsyncValue<List<ExamV2ExaminationTypeOption>>.data([])
        : ref.watch(
            examV2ExaminationTypesProvider((
              countryCode: _selectedCountry!.countryCode,
              levelId: _selectedLevel!.id,
            )),
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LearnTzColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Academic Selection Workflow',
            style: LearnTzTypography.h3.copyWith(
              color: const Color(0xFF0F4C81),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'All five selections are populated from live LearnTZ curriculum records. Changing an earlier selection automatically resets dependent fields.',
            style: LearnTzTypography.bodySmall.copyWith(
              color: LearnTzColors.textSecondary,
            ),
          ),
          const SizedBox(height: 18),

          // STEP 01: Country
          SearchableCurriculumDropdown<String>(
            fieldKey: const Key('exam-v2-step1-country'),
            stepNumber: 1,
            label: 'Country',
            hint: 'Select country...',
            options: (countriesAsync.value ?? const [])
                .map(
                  (c) => CurriculumDropdownOption<String>(
                    value: c.countryCode,
                    label: c.displayName,
                    code: c.countryCode,
                    subtitle: c.curriculumVersionCode != null
                        ? '${c.curriculumName} (${c.curriculumVersionCode})'
                        : c.curriculumName,
                    searchTerms:
                        '${c.displayName} ${c.countryCode} ${c.curriculumName}',
                  ),
                )
                .toList(),
            selectedValue: _selectedCountry?.countryCode,
            isLoading: countriesAsync.isLoading,
            errorMessage: countriesAsync.hasError
                ? countriesAsync.error.toString()
                : null,
            emptyMessage: 'No enabled countries with curricula found.',
            onSelected: (val) =>
                _onCountryChanged(val, countriesAsync.value ?? const []),
          ),
          const SizedBox(height: 14),

          // STEP 02: Education Level
          SearchableCurriculumDropdown<String>(
            fieldKey: const Key('exam-v2-step2-level'),
            stepNumber: 2,
            label: 'Education Level',
            hint: 'Select education level...',
            options: (levelsAsync.value ?? const [])
                .map(
                  (l) => CurriculumDropdownOption<String>(
                    value: l.id,
                    label: l.name,
                    code: l.code,
                    subtitle: '${l.gradeCount} configured grades/classes',
                    searchTerms: '${l.name} ${l.code}',
                  ),
                )
                .toList(),
            selectedValue: _selectedLevel?.id,
            isDisabled: _selectedCountry == null,
            disabledReason: 'Select Country first',
            isLoading: levelsAsync.isLoading,
            errorMessage:
                levelsAsync.hasError ? levelsAsync.error.toString() : null,
            emptyMessage: 'No education levels configured for this country.',
            onSelected: (val) =>
                _onLevelChanged(val, levelsAsync.value ?? const []),
          ),
          const SizedBox(height: 14),

          // STEP 03: Grade / Form / Class
          SearchableCurriculumDropdown<String>(
            fieldKey: const Key('exam-v2-step3-grade'),
            stepNumber: 3,
            label: 'Grade / Form / Class',
            hint: 'Select grade, form, or class...',
            options: (gradesAsync.value ?? const [])
                .map(
                  (g) => CurriculumDropdownOption<String>(
                    value: g.id,
                    label: g.name,
                    code: g.code,
                    subtitle: '${g.subjectCount} published subjects',
                    searchTerms: '${g.name} ${g.code}',
                  ),
                )
                .toList(),
            selectedValue: _selectedGrade?.id,
            isDisabled: _selectedLevel == null,
            disabledReason: 'Select Education Level first',
            isLoading: gradesAsync.isLoading,
            errorMessage:
                gradesAsync.hasError ? gradesAsync.error.toString() : null,
            emptyMessage: 'No grades configured for this education level.',
            onSelected: (val) =>
                _onGradeChanged(val, gradesAsync.value ?? const []),
          ),
          const SizedBox(height: 14),

          // STEP 04: Subject
          SearchableCurriculumDropdown<String>(
            fieldKey: const Key('exam-v2-step4-subject'),
            stepNumber: 4,
            label: 'Subject',
            hint: 'Select official curriculum subject...',
            options: (subjectsAsync.value ?? const [])
                .map(
                  (s) => CurriculumDropdownOption<String>(
                    value: s.id,
                    label: s.name,
                    code: s.code,
                    subtitle:
                        '${s.mainCompetenceCount} Main • ${s.specificCompetenceCount} Specific Competences',
                    searchTerms: '${s.name} ${s.code} ${s.officialName ?? ''}',
                  ),
                )
                .toList(),
            selectedValue: _selectedSubject?.id,
            isDisabled: _selectedGrade == null,
            disabledReason: 'Select Grade / Form / Class first',
            isLoading: subjectsAsync.isLoading,
            errorMessage:
                subjectsAsync.hasError ? subjectsAsync.error.toString() : null,
            emptyMessage: 'No published subjects found for this grade.',
            onSelected: (val) =>
                _onSubjectChanged(val, subjectsAsync.value ?? const []),
          ),
          const SizedBox(height: 14),

          // STEP 05: Examination Type
          SearchableCurriculumDropdown<String>(
            fieldKey: const Key('exam-v2-step5-exam-type'),
            stepNumber: 5,
            label: 'Type of Examination',
            hint: 'Select examination type...',
            options: (examTypesAsync.value ?? const [])
                .map(
                  (t) => CurriculumDropdownOption<String>(
                    value: t.id,
                    label: t.name,
                    code: t.code,
                    subtitle:
                        '${t.defaultDurationMinutes} mins • ${t.defaultTotalMarks.toStringAsFixed(0)} marks',
                    searchTerms: '${t.name} ${t.code} ${t.description}',
                  ),
                )
                .toList(),
            selectedValue: _selectedExamType?.id,
            isDisabled: _selectedSubject == null,
            disabledReason: 'Select Subject first',
            isLoading: examTypesAsync.isLoading,
            errorMessage: examTypesAsync.hasError
                ? examTypesAsync.error.toString()
                : null,
            emptyMessage: 'No examination types configured for this country.',
            onSelected: (val) =>
                _onExamTypeChanged(val, examTypesAsync.value ?? const []),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedWorkspaceNotice() {
    return Container(
      key: const Key('exam-v2-locked-notice'),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LearnTzColors.border),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.lock_clock_outlined,
            size: 38,
            color: Color(0xFF0F4C81),
          ),
          const SizedBox(height: 10),
          Text(
            'Complete All 5 Academic Selections to Unlock Curriculum Competencies',
            style: LearnTzTypography.h3.copyWith(
              color: LearnTzColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            'Once Country, Education Level, Grade/Form/Class, Subject, and Examination Type are selected, LearnTZ validates the hierarchy on the server and loads the official curriculum competencies and live question bank counts.',
            style: LearnTzTypography.bodySmall.copyWith(
              color: LearnTzColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVerifiedContextWorkspace() {
    final key = _selectionKey!;
    final summaryAsync = ref.watch(examV2ContextSummaryProvider(key));

    return summaryAsync.when(
      loading: () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: LearnTzColors.border),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
            SizedBox(width: 12),
            Flexible(
              child: Text(
                'Validating academic hierarchy and loading official competencies...',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      error: (err, _) => Container(
        key: const Key('exam-v2-context-error'),
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFFEF2F2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFECACA)),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 32),
            const SizedBox(height: 8),
            Text(
              'Academic Context Validation Failed',
              style: LearnTzTypography.h3.copyWith(
                color: const Color(0xFF991B1B),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              err.toString(),
              style: LearnTzTypography.bodySmall.copyWith(
                color: const Color(0xFF991B1B),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      data: (summary) => Column(
        key: const Key('exam-v2-verified-workspace'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSelectedContextSummaryCard(summary),
          const SizedBox(height: 16),
          if (_activeNavSection == 'question_bank') ...[
            _buildQuestionBankV2Section(key, summary),
            const SizedBox(height: 16),
          ] else ...[
            _buildExaminationsSection(key, summary),
            const SizedBox(height: 16),
            _buildQuestionBankV2Section(key, summary),
            const SizedBox(height: 16),
          ],
          _buildRealMetricsStrip(summary),
          const SizedBox(height: 16),
          _buildCompetencesSection(summary),
        ],
      ),
    );
  }

  Future<void> _openCreateQuestionDialog(
    ExamV2SelectionKey selection,
    ExamV2ContextSummary summary,
  ) async {
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ExamV2QuestionDialog(
        selection: selection,
        summary: summary,
      ),
    );
    if (created == true && mounted) {
      ref.invalidate(examV2QuestionsListProvider(selection));
      ref.invalidate(examV2ContextSummaryProvider(selection));
    }
  }

  Widget _buildQuestionBankV2Section(
    ExamV2SelectionKey selection,
    ExamV2ContextSummary summary,
  ) {
    final questionsAsync = ref.watch(examV2QuestionsListProvider(selection));

    return Container(
      key: const Key('exam-v2-question-bank-section'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LearnTzColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question Bank 2.0',
                    style: LearnTzTypography.h3.copyWith(
                      color: LearnTzColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Reusable curriculum-mapped questions for ${summary.context.gradeName} ${summary.context.subjectName}',
                    style: LearnTzTypography.caption.copyWith(
                      color: LearnTzColors.textSecondary,
                    ),
                  ),
                ],
              ),
              AppButton(
                key: const Key('exam-v2-create-question-btn'),
                label: 'Create Question',
                icon: Icons.add,
                variant: AppButtonVariant.outlined,
                size: AppButtonSize.sm,
                onPressed: () =>
                    _openCreateQuestionDialog(selection, summary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          questionsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (err, _) => Text(
              'Unable to load Question Bank 2.0: $err',
              style: LearnTzTypography.bodySmall.copyWith(
                color: const Color(0xFFDC2626),
              ),
            ),
            data: (result) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _ContextPill(
                        label: 'Total Questions',
                        value: '${result.totalCount}',
                      ),
                      _ContextPill(
                        label: 'Drafts',
                        value: '${result.draftCount}',
                      ),
                      _ContextPill(
                        label: 'In Review',
                        value: '${result.inReviewCount}',
                      ),
                      _ContextPill(
                        label: 'Approved',
                        value: '${result.approvedCount}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (result.items.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: LearnTzColors.border),
                      ),
                      child: Text(
                        'No questions mapped to this subject yet. Click "Create Question" to author curriculum-aligned items with answer keys or marking rubrics.',
                        style: LearnTzTypography.bodySmall.copyWith(
                          color: LearnTzColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    ...result.items.take(10).map((q) {
                      final statusVariant = switch (q.reviewStatus) {
                        'approved' => AppBadgeVariant.success,
                        'in_review' => AppBadgeVariant.warning,
                        'revision_requested' => AppBadgeVariant.error,
                        _ => AppBadgeVariant.neutral,
                      };
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: LearnTzColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                AppBadge(
                                  label: q.reviewStatus.replaceAll('_', ' '),
                                  variant: statusVariant,
                                  size: AppBadgeSize.sm,
                                ),
                                AppBadge(
                                  label: q.questionType.replaceAll('_', ' '),
                                  variant: AppBadgeVariant.primary,
                                  size: AppBadgeSize.sm,
                                ),
                                AppBadge(
                                  label:
                                      '${q.marks.toStringAsFixed(0)} marks • ${q.difficultyLevel}',
                                  variant: AppBadgeVariant.neutral,
                                  size: AppBadgeSize.sm,
                                ),
                                if (q.specificCompetenceCode != null)
                                  AppBadge(
                                    label: 'SC ${q.specificCompetenceCode}',
                                    variant: AppBadgeVariant.neutral,
                                    size: AppBadgeSize.sm,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              q.questionText,
                              style: LearnTzTypography.bodySmall.copyWith(
                                color: LearnTzColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (q.specificCompetenceTitle != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Competence: ${q.specificCompetenceCode ?? ''} ${q.specificCompetenceTitle}',
                                style: LearnTzTypography.caption.copyWith(
                                  color: LearnTzColors.textSecondary,
                                ),
                              ),
                            ],
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
    );
  }

  Future<void> _openCreateExaminationDialog(
    ExamV2SelectionKey selection,
    ExamV2ContextSummary summary,
  ) async {
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ExamV2CreationDialog(
        selection: selection,
        summary: summary,
      ),
    );
    if (created == true && mounted) {
      ref.invalidate(examV2ExaminationsListProvider(selection));
      ref.invalidate(examV2ContextSummaryProvider(selection));
    }
  }

  Widget _buildExaminationsSection(
    ExamV2SelectionKey selection,
    ExamV2ContextSummary summary,
  ) {
    final examsAsync = ref.watch(examV2ExaminationsListProvider(selection));

    return Container(
      key: const Key('exam-v2-examinations-section'),
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LearnTzColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Examinations for This Context',
                    style: LearnTzTypography.h3.copyWith(
                      color: LearnTzColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Real database records for ${summary.context.gradeName} ${summary.context.subjectName} (${summary.context.examinationTypeName})',
                    style: LearnTzTypography.caption.copyWith(
                      color: LearnTzColors.textSecondary,
                    ),
                  ),
                ],
              ),
              AppButton(
                key: const Key('exam-v2-create-exam-btn'),
                label: 'Create Examination',
                icon: Icons.add,
                variant: AppButtonVariant.primary,
                size: AppButtonSize.sm,
                onPressed: () =>
                    _openCreateExaminationDialog(selection, summary),
              ),
            ],
          ),
          const SizedBox(height: 14),
          examsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
            error: (err, _) => Text(
              'Unable to load examinations: $err',
              style: LearnTzTypography.bodySmall.copyWith(
                color: const Color(0xFFDC2626),
              ),
            ),
            data: (result) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 8,
                    children: [
                      _ContextPill(
                        label: 'Total',
                        value: '${result.totalCount}',
                      ),
                      _ContextPill(
                        label: 'Drafts',
                        value: '${result.draftCount}',
                      ),
                      _ContextPill(
                        label: 'Under Review',
                        value: '${result.underReviewCount}',
                      ),
                      _ContextPill(
                        label: 'Approved',
                        value: '${result.approvedCount}',
                      ),
                      _ContextPill(
                        label: 'Published',
                        value: '${result.publishedCount}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (result.items.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: LearnTzColors.border),
                      ),
                      child: Text(
                        'No examinations created yet for this academic context. Click "Create Examination" to configure metadata, official curriculum coverage, and blueprint sections.',
                        style: LearnTzTypography.bodySmall.copyWith(
                          color: LearnTzColors.textSecondary,
                        ),
                      ),
                    )
                  else
                    ...result.items.map((exam) {
                      final badgeVariant = switch (exam.status) {
                        'published' || 'active' || 'results_released' =>
                          AppBadgeVariant.success,
                        'approved' => AppBadgeVariant.primary,
                        'submitted_for_review' || 'under_review' =>
                          AppBadgeVariant.warning,
                        'revision_requested' => AppBadgeVariant.error,
                        _ => AppBadgeVariant.neutral,
                      };
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: LearnTzColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 6,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                AppBadge(
                                  label: exam.status.replaceAll('_', ' '),
                                  variant: badgeVariant,
                                  size: AppBadgeSize.sm,
                                ),
                                AppBadge(
                                  label:
                                      '${exam.academicYear} • ${exam.academicTerm}',
                                  variant: AppBadgeVariant.neutral,
                                  size: AppBadgeSize.sm,
                                ),
                                AppBadge(
                                  label: 'v${exam.versionNumber}',
                                  variant: AppBadgeVariant.neutral,
                                  size: AppBadgeSize.sm,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              exam.title,
                              style: LearnTzTypography.bodyRegular.copyWith(
                                fontWeight: FontWeight.w700,
                                color: LearnTzColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 14,
                              runSpacing: 4,
                              children: [
                                Text(
                                  '${exam.totalMarks.toStringAsFixed(0)} marks',
                                  style: LearnTzTypography.caption.copyWith(
                                    color: const Color(0xFF15803D),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  '${exam.durationMinutes} mins',
                                  style: LearnTzTypography.caption.copyWith(
                                    color: LearnTzColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '${exam.sectionCount} sections',
                                  style: LearnTzTypography.caption.copyWith(
                                    color: LearnTzColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  '${exam.competencyCount} competencies',
                                  style: LearnTzTypography.caption.copyWith(
                                    color: LearnTzColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            AppButton(
                              key: Key('exam-v2-open-paper-builder-${exam.id}'),
                              label: 'Open Paper Builder',
                              icon: Icons.article_outlined,
                              variant: AppButtonVariant.outlined,
                              size: AppButtonSize.sm,
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => ExamV2PaperBuilderScreen(
                                      examinationId: exam.id,
                                      selection: selection,
                                    ),
                                  ),
                                );
                              },
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
    );
  }

  Widget _buildSelectedContextSummaryCard(ExamV2ContextSummary summary) {
    final ctx = summary.context;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF15803D), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const AppBadge(
                label: 'Verified Academic Context',
                variant: AppBadgeVariant.success,
                size: AppBadgeSize.sm,
              ),
              if (ctx.curriculumVersionCode != null)
                AppBadge(
                  label: ctx.curriculumVersionCode!,
                  variant: AppBadgeVariant.primary,
                  size: AppBadgeSize.sm,
                ),
              if (ctx.requiresAcademicReview)
                const AppBadge(
                  label: 'Academic Review Required',
                  variant: AppBadgeVariant.warning,
                  size: AppBadgeSize.sm,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            ctx.suggestedExaminationTitle,
            style: LearnTzTypography.h3.copyWith(
              color: LearnTzColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (ctx.examinationTypeDescription.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              ctx.examinationTypeDescription,
              style: LearnTzTypography.bodySmall.copyWith(
                color: LearnTzColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _ContextPill(label: 'Country', value: ctx.countryName),
              _ContextPill(
                label: 'Curriculum',
                value: ctx.curriculumName,
              ),
              _ContextPill(
                label: 'Education Level',
                value: ctx.educationLevelName,
              ),
              _ContextPill(label: 'Grade', value: ctx.gradeName),
              _ContextPill(label: 'Subject', value: ctx.subjectName),
              _ContextPill(
                label: 'Examination Type',
                value: ctx.examinationTypeName,
              ),
              _ContextPill(
                label: 'Default Duration',
                value: '${ctx.defaultDurationMinutes} minutes',
              ),
              _ContextPill(
                label: 'Default Marks',
                value: '${ctx.defaultTotalMarks.toStringAsFixed(0)} marks',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRealMetricsStrip(ExamV2ContextSummary summary) {
    final items = [
      (
        'Main Competences',
        '${summary.mainCompetences.length}',
        const Color(0xFF0F4C81),
        Icons.account_tree_outlined,
      ),
      (
        'Specific Competences',
        '${summary.totalSpecificCompetences}',
        const Color(0xFF15803D),
        Icons.checklist_rtl_outlined,
      ),
      (
        'Question Bank Items',
        '${summary.questionBankCount}',
        const Color(0xFFF59E0B),
        Icons.quiz_outlined,
      ),
      (
        'Existing Papers',
        '${summary.examinationPapersCount}',
        const Color(0xFF0F4C81),
        Icons.description_outlined,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 820
            ? 4
            : constraints.maxWidth >= 460
                ? 2
                : 1;
        final w = (constraints.maxWidth - (cols - 1) * 12) / cols;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: items.map((item) {
            return SizedBox(
              width: w,
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: LearnTzColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: item.$3.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(item.$4, color: item.$3, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$1,
                            style: LearnTzTypography.caption.copyWith(
                              color: LearnTzColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            item.$2,
                            style: LearnTzTypography.h3.copyWith(
                              color: LearnTzColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCompetencesSection(ExamV2ContextSummary summary) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: LearnTzColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Official Curriculum Competency Mapping',
            style: LearnTzTypography.h3.copyWith(
              color: LearnTzColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Loaded directly from verified LearnTZ curriculum records (${summary.context.curriculumVersionCode ?? summary.context.curriculumCode}). Every examination item in Phases 2–4 maps to these official competencies.',
            style: LearnTzTypography.bodySmall.copyWith(
              color: LearnTzColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          if (summary.mainCompetences.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No published curriculum competencies found for this subject yet.',
                style: LearnTzTypography.bodySmall.copyWith(
                  color: LearnTzColors.textSecondary,
                ),
              ),
            )
          else
            ...summary.mainCompetences.map((mc) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: LearnTzColors.border),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF0F4C81),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              mc.code,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              mc.title,
                              style: LearnTzTypography.bodyRegular.copyWith(
                                color: LearnTzColors.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...mc.specificCompetences.map((sc) {
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: LearnTzColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF15803D)
                                          .withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(5),
                                    ),
                                    child: Text(
                                      sc.code,
                                      style: const TextStyle(
                                        color: Color(0xFF15803D),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      sc.title,
                                      style: LearnTzTypography.bodySmall
                                          .copyWith(
                                        color: LearnTzColors.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (sc.assessmentCriteria != null &&
                                  sc.assessmentCriteria!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Assessment criteria: ${sc.assessmentCriteria}',
                                  style: LearnTzTypography.caption.copyWith(
                                    color: LearnTzColors.textSecondary,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 12,
                                runSpacing: 4,
                                children: [
                                  Text(
                                    '${sc.questionCount} bank questions',
                                    style: LearnTzTypography.caption.copyWith(
                                      color: const Color(0xFF0F4C81),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    '${sc.subtopicCount} learning activities',
                                    style: LearnTzTypography.caption.copyWith(
                                      color: LearnTzColors.textSecondary,
                                    ),
                                  ),
                                  if (sc.periodAllocation != null)
                                    Text(
                                      '${sc.periodAllocation} periods',
                                      style: LearnTzTypography.caption.copyWith(
                                        color: LearnTzColors.textSecondary,
                                      ),
                                    ),
                                  if (sc.sourcePage != null)
                                    Text(
                                      'Syllabus p.${sc.sourcePage}',
                                      style: LearnTzTypography.caption.copyWith(
                                        color: LearnTzColors.textSecondary,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _ExamNavItem {
  const _ExamNavItem({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.icon,
    this.phaseBadge,
    this.externalRoute,
  });

  final String id;
  final String label;
  final String subtitle;
  final IconData icon;
  final String? phaseBadge;
  final String? externalRoute;
}

class _ContextPill extends StatelessWidget {
  const _ContextPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LearnTzColors.border),
      ),
      child: RichText(
        text: TextSpan(
          style: LearnTzTypography.caption.copyWith(
            color: LearnTzColors.textSecondary,
          ),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: LearnTzTypography.caption.copyWith(
                color: LearnTzColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
