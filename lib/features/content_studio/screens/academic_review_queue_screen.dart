import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../../../core/routing/app_router.dart';
import '../lesson_authoring_models.dart';
import '../review_queue_models.dart';
import '../review_queue_providers.dart';

class AcademicReviewQueueScreen extends ConsumerStatefulWidget {
  const AcademicReviewQueueScreen({
    super.key,
    this.initialCountryCode,
    this.onOpenLesson,
  });

  final String? initialCountryCode;
  final Future<void> Function(AuthorLessonLaunchContext context)? onOpenLesson;

  @override
  ConsumerState<AcademicReviewQueueScreen> createState() =>
      _AcademicReviewQueueScreenState();
}

class _AcademicReviewQueueScreenState
    extends ConsumerState<AcademicReviewQueueScreen> {
  static const _pageSize = 15;

  final _searchCtrl = TextEditingController();

  String? _countryCode;
  String? _educationLevelId;
  String? _gradeId;
  String? _subjectId;
  String _status = 'all_reviewable';
  String _assignmentFilter = 'all'; // 'all' | 'assigned_to_me' | 'unassigned'
  String _appliedSearch = '';
  int _offset = 0;

  String? _claimingLessonId;
  String? _feedbackBanner;
  bool _feedbackIsError = false;

  @override
  void initState() {
    super.initState();
    _countryCode = widget.initialCountryCode;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  ReviewQueueQuery _buildQuery() {
    final repo = ref.read(academicReviewQueueRepositoryProvider);
    final currentUid = repo.currentUserId;
    return ReviewQueueQuery(
      countryCode: _countryCode,
      educationLevelId: _educationLevelId,
      gradeId: _gradeId,
      subjectId: _subjectId,
      status: _status,
      search: _appliedSearch.isEmpty ? null : _appliedSearch,
      assignedReviewerId:
          _assignmentFilter == 'assigned_to_me' ? currentUid : null,
      onlyUnassigned: _assignmentFilter == 'unassigned',
      limit: _pageSize,
      offset: _offset,
    );
  }

  void _refreshAll() {
    ref.invalidate(reviewQueueSummaryProvider(_countryCode));
    ref.invalidate(reviewQueuePageProvider(_buildQuery()));
  }

  void _clearFilters() {
    _searchCtrl.clear();
    setState(() {
      _countryCode = null;
      _educationLevelId = null;
      _gradeId = null;
      _subjectId = null;
      _status = 'all_reviewable';
      _assignmentFilter = 'all';
      _appliedSearch = '';
      _offset = 0;
    });
  }

  Future<void> _claimLesson(ReviewQueueItem item) async {
    setState(() {
      _claimingLessonId = item.lessonId;
      _feedbackBanner = null;
    });
    try {
      final repo = ref.read(academicReviewQueueRepositoryProvider);
      await repo.assignReviewer(lessonId: item.lessonId);
      if (!mounted) return;
      setState(() {
        _claimingLessonId = null;
        _feedbackBanner = 'Assigned "${item.title}" to you for review.';
        _feedbackIsError = false;
      });
      _refreshAll();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _claimingLessonId = null;
        _feedbackBanner = e.toString().replaceFirst('Exception: ', '');
        _feedbackIsError = true;
      });
    }
  }

  Future<void> _openLessonForReview(ReviewQueueItem item) async {
    final launchCtx = item.toLaunchContext();
    if (widget.onOpenLesson != null) {
      await widget.onOpenLesson!(launchCtx);
      return;
    }
    await context.push(AppRoutes.authorNewLesson, extra: launchCtx);
    if (mounted) {
      _refreshAll();
    }
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return '—';
    final local = dt.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final m = months[local.month - 1];
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');
    return '${local.day} $m ${local.year}, $hh:$mm';
  }

  (String label, AppBadgeVariant variant, Color accent) _statusMeta(
    String status,
  ) {
    switch (status) {
      case 'in_review':
        return (
          'Awaiting Review',
          AppBadgeVariant.warning,
          const Color(0xFFF59E0B),
        );
      case 'revision_requested':
        return (
          'Revision Requested',
          AppBadgeVariant.error,
          const Color(0xFFDC2626),
        );
      case 'approved':
        return (
          'Approved',
          AppBadgeVariant.primary,
          const Color(0xFF0F4C81),
        );
      case 'published':
        return (
          'Published',
          AppBadgeVariant.success,
          const Color(0xFF15803D),
        );
      default:
        return (
          status.replaceAll('_', ' '),
          AppBadgeVariant.neutral,
          LearnTzColors.textSecondary,
        );
    }
  }

  bool _isPermissionError(Object error) {
    final msg = error.toString().toLowerCase();
    return msg.contains('permission denied') ||
        msg.contains('authentication required') ||
        msg.contains('42501');
  }

  @override
  Widget build(BuildContext context) {
    final query = _buildQuery();
    final summaryAsync = ref.watch(reviewQueueSummaryProvider(_countryCode));
    final pageAsync = ref.watch(reviewQueuePageProvider(query));

    return Scaffold(
      backgroundColor: LearnTzColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, summaryAsync.value),
                  const SizedBox(height: 16),
                  if (_feedbackBanner != null) ...[
                    _buildFeedbackBanner(),
                    const SizedBox(height: 16),
                  ],
                  summaryAsync.when(
                    loading: () => _buildKpiLoading(),
                    error: (err, _) => _buildErrorCard(
                      error: err,
                      onRetry: _refreshAll,
                    ),
                    data: (summary) => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryKpis(summary),
                        const SizedBox(height: 16),
                        _buildFilterBar(summary.filterOptions),
                        const SizedBox(height: 16),
                        _buildQueueSection(pageAsync, summary),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ReviewQueueSummary? summary) {
    final roleLabel = summary == null
        ? 'Academic Governance'
        : summary.capabilities.canPublish
            ? 'Curriculum Admin / Publisher'
            : 'Academic Reviewer';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 720;
        if (isNarrow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go(AppRoutes.contentStudio);
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Academic Review Queue',
                      style: LearnTzTypography.h3.copyWith(
                        fontWeight: FontWeight.w800,
                        color: LearnTzColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  AppBadge(
                    label: roleLabel,
                    variant: AppBadgeVariant.primary,
                    size: AppBadgeSize.sm,
                  ),
                  AppButton(
                    key: const Key('review-queue-refresh-btn'),
                    label: 'Refresh',
                    variant: AppButtonVariant.outlined,
                    size: AppButtonSize.sm,
                    icon: Icons.refresh,
                    onPressed: _refreshAll,
                  ),
                  AppButton(
                    label: 'Content Studio',
                    variant: AppButtonVariant.outlined,
                    size: AppButtonSize.sm,
                    icon: Icons.edit_note_outlined,
                    onPressed: () => context.push(AppRoutes.contentStudio),
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
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.contentStudio);
                }
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 10,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Academic Review Queue',
                        style: LearnTzTypography.h2.copyWith(
                          fontWeight: FontWeight.w800,
                          color: LearnTzColors.textPrimary,
                        ),
                      ),
                      AppBadge(
                        label: roleLabel,
                        variant: AppBadgeVariant.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Two-party academic quality review, curriculum alignment verification, approval & publication governance',
                    style: LearnTzTypography.bodyRegular.copyWith(
                      color: LearnTzColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            AppButton(
              key: const Key('review-queue-refresh-btn'),
              label: 'Refresh',
              variant: AppButtonVariant.outlined,
              size: AppButtonSize.md,
              icon: Icons.refresh,
              onPressed: _refreshAll,
            ),
            const SizedBox(width: 8),
            AppButton(
              label: 'Content Studio',
              variant: AppButtonVariant.outlined,
              size: AppButtonSize.md,
              icon: Icons.edit_note_outlined,
              onPressed: () => context.push(AppRoutes.contentStudio),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeedbackBanner() {
    final bg = _feedbackIsError
        ? const Color(0xFFFEF2F2)
        : const Color(0xFFF0FDF4);
    final border = _feedbackIsError
        ? const Color(0xFFFECACA)
        : const Color(0xFFBBF7D0);
    final fg = _feedbackIsError
        ? const Color(0xFF991B1B)
        : const Color(0xFF166534);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(
            _feedbackIsError ? Icons.error_outline : Icons.check_circle_outline,
            color: fg,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _feedbackBanner!,
              style: LearnTzTypography.bodyRegular.copyWith(
                color: fg,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18, color: fg),
            onPressed: () => setState(() => _feedbackBanner = null),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiLoading() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
              'Loading Academic Review Queue metrics...',
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryKpis(ReviewQueueSummary summary) {
    final cards = [
      _KpiCardData(
        keyName: 'kpi-awaiting-review',
        label: 'Awaiting Review',
        count: summary.awaitingReviewCount,
        subtitle: '${summary.assignedToMeCount} assigned to you',
        accent: const Color(0xFFF59E0B),
        icon: Icons.pending_actions_outlined,
        targetStatus: 'in_review',
      ),
      _KpiCardData(
        keyName: 'kpi-revision-requested',
        label: 'Revision Requested',
        count: summary.revisionRequestedCount,
        subtitle: 'Returned to author',
        accent: const Color(0xFFDC2626),
        icon: Icons.rate_review_outlined,
        targetStatus: 'revision_requested',
      ),
      _KpiCardData(
        keyName: 'kpi-approved',
        label: 'Approved',
        count: summary.approvedCount,
        subtitle: 'Ready to publish',
        accent: const Color(0xFF0F4C81),
        icon: Icons.verified_outlined,
        targetStatus: 'approved',
      ),
      _KpiCardData(
        keyName: 'kpi-published',
        label: 'Published',
        count: summary.publishedCount,
        subtitle: 'Live for learners',
        accent: const Color(0xFF15803D),
        icon: Icons.public_outlined,
        targetStatus: 'published',
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 960
            ? 4
            : constraints.maxWidth >= 560
                ? 2
                : 1;
        final itemWidth = (constraints.maxWidth - (cols - 1) * 12) / cols;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: cards.map((card) {
            final isSelected = _status == card.targetStatus;
            return SizedBox(
              width: itemWidth,
              child: InkWell(
                key: Key(card.keyName),
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  setState(() {
                    _status =
                        isSelected ? 'all_reviewable' : card.targetStatus;
                    _offset = 0;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? card.accent : LearnTzColors.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: card.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(card.icon, color: card.accent, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              card.label,
                              style: LearnTzTypography.bodySmall.copyWith(
                                color: LearnTzColors.textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${card.count}',
                              style: LearnTzTypography.h2.copyWith(
                                color: LearnTzColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              card.subtitle,
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
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildFilterBar(ReviewQueueFilterOptions options) {
    final filteredLevels = _countryCode == null
        ? options.educationLevels
        : options.educationLevels
            .where((l) => l.countryCode == _countryCode)
            .toList();

    final filteredGrades = options.grades.where((g) {
      if (_countryCode != null && g.countryCode != _countryCode) return false;
      if (_educationLevelId != null &&
          g.educationLevelId != _educationLevelId) {
        return false;
      }
      return true;
    }).toList();

    final filteredSubjects = options.subjects.where((s) {
      if (_countryCode != null && s.countryCode != _countryCode) return false;
      if (_educationLevelId != null &&
          s.educationLevelId != _educationLevelId) {
        return false;
      }
      if (_gradeId != null && s.gradeId != _gradeId) return false;
      return true;
    }).toList();

    final validLevelId =
        filteredLevels.any((l) => l.id == _educationLevelId)
            ? _educationLevelId
            : null;
    final validGradeId =
        filteredGrades.any((g) => g.id == _gradeId) ? _gradeId : null;
    final validSubjectId =
        filteredSubjects.any((s) => s.id == _subjectId) ? _subjectId : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LearnTzColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.filter_list,
                size: 18,
                color: Color(0xFF0F4C81),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Filter Queue',
                  style: LearnTzTypography.bodyRegular.copyWith(
                    fontWeight: FontWeight.w700,
                    color: LearnTzColors.textPrimary,
                  ),
                ),
              ),
              TextButton.icon(
                key: const Key('review-queue-clear-filters-btn'),
                onPressed: _clearFilters,
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear Filters'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 680;
              final fieldWidth = isNarrow
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 36) / 4;
              return Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  // Search field
                  SizedBox(
                    width: isNarrow
                        ? constraints.maxWidth
                        : (constraints.maxWidth - 12) / 2,
                    child: TextField(
                      key: const Key('review-queue-search-field'),
                      controller: _searchCtrl,
                      decoration: InputDecoration(
                        labelText: 'Search by lesson title or competence',
                        prefixIcon: const Icon(Icons.search, size: 18),
                        suffixIcon: _searchCtrl.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() {
                                    _appliedSearch = '';
                                    _offset = 0;
                                  });
                                },
                              )
                            : null,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onSubmitted: (val) {
                        setState(() {
                          _appliedSearch = val.trim();
                          _offset = 0;
                        });
                      },
                      onChanged: (val) {
                        setState(() {
                          _appliedSearch = val.trim();
                          _offset = 0;
                        });
                      },
                    ),
                  ),

                  // Status dropdown
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<String>(
                      key: const Key('review-queue-status-dropdown'),
                      initialValue: _status,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Lesson Status',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'all_reviewable',
                          child: Text('All Reviewable'),
                        ),
                        DropdownMenuItem(
                          value: 'in_review',
                          child: Text('Awaiting Review'),
                        ),
                        DropdownMenuItem(
                          value: 'revision_requested',
                          child: Text('Revision Requested'),
                        ),
                        DropdownMenuItem(
                          value: 'approved',
                          child: Text('Approved'),
                        ),
                        DropdownMenuItem(
                          value: 'published',
                          child: Text('Published'),
                        ),
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All Workflow States'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          _status = val;
                          _offset = 0;
                        });
                      },
                    ),
                  ),

                  // Assignment dropdown
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<String>(
                      key: const Key('review-queue-assignment-dropdown'),
                      initialValue: _assignmentFilter,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Reviewer Assignment',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('All Assignments'),
                        ),
                        DropdownMenuItem(
                          value: 'assigned_to_me',
                          child: Text('Assigned to Me'),
                        ),
                        DropdownMenuItem(
                          value: 'unassigned',
                          child: Text('Unassigned Only'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val == null) return;
                        setState(() {
                          _assignmentFilter = val;
                          _offset = 0;
                        });
                      },
                    ),
                  ),

                  // Country dropdown
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<String?>(
                      key: const Key('review-queue-country-dropdown'),
                      initialValue: _countryCode,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Country',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Countries'),
                        ),
                        ...options.countries.map(
                          (c) => DropdownMenuItem<String?>(
                            value: c.countryCode,
                            child: Text('${c.displayName} (${c.countryCode})'),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _countryCode = val;
                          _educationLevelId = null;
                          _gradeId = null;
                          _subjectId = null;
                          _offset = 0;
                        });
                      },
                    ),
                  ),

                  // Education Level dropdown
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<String?>(
                      key: const Key('review-queue-level-dropdown'),
                      initialValue: validLevelId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Education Level',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Levels'),
                        ),
                        ...filteredLevels.map(
                          (l) => DropdownMenuItem<String?>(
                            value: l.id,
                            child: Text(l.name),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _educationLevelId = val;
                          _gradeId = null;
                          _subjectId = null;
                          _offset = 0;
                        });
                      },
                    ),
                  ),

                  // Grade dropdown
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<String?>(
                      key: const Key('review-queue-grade-dropdown'),
                      initialValue: validGradeId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Grade / Class',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Grades'),
                        ),
                        ...filteredGrades.map(
                          (g) => DropdownMenuItem<String?>(
                            value: g.id,
                            child: Text(g.name),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _gradeId = val;
                          _subjectId = null;
                          _offset = 0;
                        });
                      },
                    ),
                  ),

                  // Subject dropdown
                  SizedBox(
                    width: fieldWidth,
                    child: DropdownButtonFormField<String?>(
                      key: const Key('review-queue-subject-dropdown'),
                      initialValue: validSubjectId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Subject',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Subjects'),
                        ),
                        ...filteredSubjects.map(
                          (s) => DropdownMenuItem<String?>(
                            value: s.id,
                            child: Text(
                              s.displayLabel,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _subjectId = val;
                          _offset = 0;
                        });
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQueueSection(
    AsyncValue<ReviewQueuePage> pageAsync,
    ReviewQueueSummary summary,
  ) {
    return pageAsync.when(
      loading: () => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(36),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: LearnTzColors.border),
        ),
        child: const Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Loading review queue...'),
          ],
        ),
      ),
      error: (err, _) => _buildErrorCard(
        error: err,
        onRetry: _refreshAll,
      ),
      data: (page) {
        if (page.items.isEmpty) {
          return Container(
            key: const Key('review-queue-empty-state'),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: LearnTzColors.border),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 44,
                  color: LearnTzColors.textSecondary,
                ),
                const SizedBox(height: 12),
                Text(
                  'No lessons match the current queue filters',
                  style: LearnTzTypography.h3.copyWith(
                    color: LearnTzColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Try adjusting the status, country, subject, or search filters, or refresh to check for new submissions.',
                  style: LearnTzTypography.bodyRegular.copyWith(
                    color: LearnTzColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Reset Filters',
                  variant: AppButtonVariant.outlined,
                  size: AppButtonSize.sm,
                  onPressed: _clearFilters,
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Showing ${page.offset + 1}–${page.offset + page.items.length} of ${page.totalCount} lessons',
                    style: LearnTzTypography.bodySmall.copyWith(
                      color: LearnTzColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'Page ${page.currentPage} of ${page.totalPages}',
                  style: LearnTzTypography.bodySmall.copyWith(
                    color: LearnTzColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...page.items.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildQueueItemCard(item, summary),
              ),
            ),
            const SizedBox(height: 8),
            _buildPaginationControls(page),
          ],
        );
      },
    );
  }

  Widget _buildQueueItemCard(
    ReviewQueueItem item,
    ReviewQueueSummary summary,
  ) {
    final (statusLabel, badgeVariant, accent) = _statusMeta(item.status);
    final isClaiming = _claimingLessonId == item.lessonId;
    final currentUid =
        ref.read(academicReviewQueueRepositoryProvider).currentUserId;
    final canClaim = item.status == 'in_review' &&
        item.reviewerId == null &&
        item.authorId != currentUid &&
        (summary.capabilities.canReview || summary.capabilities.canPublish);

    return Container(
      key: Key('review-queue-item-${item.lessonId}'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: LearnTzColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title + Badges + Actions
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 720;
              final titleBlock = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AppBadge(
                        label: statusLabel,
                        variant: badgeVariant,
                        size: AppBadgeSize.sm,
                      ),
                      AppBadge(
                        label: '${item.countryName} (${item.countryCode})',
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
                    style: LearnTzTypography.h3.copyWith(
                      color: LearnTzColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );

              final actionButtons = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (canClaim)
                    AppButton(
                      key: Key('claim-review-btn-${item.lessonId}'),
                      label: isClaiming ? 'Claiming...' : 'Claim Review',
                      variant: AppButtonVariant.outlined,
                      size: AppButtonSize.sm,
                      icon: Icons.assignment_ind_outlined,
                      onPressed: isClaiming ? null : () => _claimLesson(item),
                    ),
                  AppButton(
                    key: Key('open-review-btn-${item.lessonId}'),
                    label: 'Open for Review',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.sm,
                    icon: Icons.open_in_new,
                    onPressed: () => _openLessonForReview(item),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    titleBlock,
                    const SizedBox(height: 12),
                    actionButtons,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: titleBlock),
                  const SizedBox(width: 12),
                  actionButtons,
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          // Curriculum alignment strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: LearnTzColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 16,
                  runSpacing: 6,
                  children: [
                    _MetaChip(
                      icon: Icons.school_outlined,
                      label: 'Curriculum',
                      value: item.curriculumName,
                    ),
                    _MetaChip(
                      icon: Icons.layers_outlined,
                      label: 'Grade',
                      value: '${item.gradeName} (${item.educationLevelName})',
                    ),
                    _MetaChip(
                      icon: Icons.menu_book_outlined,
                      label: 'Subject',
                      value: item.subjectName,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Main Competence: ${item.formattedMainCompetence}',
                  style: LearnTzTypography.bodySmall.copyWith(
                    color: LearnTzColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Specific Competence: ${item.formattedSpecificCompetence}',
                  style: LearnTzTypography.bodySmall.copyWith(
                    color: LearnTzColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Governance metadata footer
          Wrap(
            spacing: 20,
            runSpacing: 8,
            children: [
              _MetaChip(
                icon: Icons.person_outline,
                label: 'Author',
                value: item.authorName,
              ),
              _MetaChip(
                icon: Icons.schedule_outlined,
                label: 'Submitted',
                value: _formatDate(item.submittedAt ?? item.updatedAt),
              ),
              _MetaChip(
                icon: Icons.verified_user_outlined,
                label: 'Assigned Reviewer',
                value: item.reviewerName ?? 'Unassigned',
                valueColor: item.reviewerName == null
                    ? const Color(0xFFD97706)
                    : accent,
              ),
              _MetaChip(
                icon: Icons.quiz_outlined,
                label: 'Questions',
                value: '${item.questionCount}',
              ),
            ],
          ),
          if (item.reviewNotes != null && item.reviewNotes!.trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Text(
                  'Latest review note: ${item.reviewNotes}',
                  style: LearnTzTypography.bodySmall.copyWith(
                    color: const Color(0xFF92400E),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls(ReviewQueuePage page) {
    final hasPrev = page.offset > 0;
    return SizedBox(
      width: double.infinity,
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          AppButton(
            key: const Key('review-queue-prev-page-btn'),
            label: 'Previous',
            variant: AppButtonVariant.outlined,
            size: AppButtonSize.sm,
            icon: Icons.chevron_left,
            onPressed: hasPrev
                ? () {
                    setState(() {
                      _offset = (_offset - _pageSize).clamp(0, page.totalCount);
                    });
                  }
                : null,
          ),
          Text(
            'Page ${page.currentPage} of ${page.totalPages}',
            style: LearnTzTypography.bodySmall.copyWith(
              color: LearnTzColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          AppButton(
            key: const Key('review-queue-next-page-btn'),
            label: 'Next',
            variant: AppButtonVariant.outlined,
            size: AppButtonSize.sm,
            icon: Icons.chevron_right,
            onPressed: page.hasMore
                ? () {
                    setState(() {
                      _offset = _offset + _pageSize;
                    });
                  }
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard({
    required Object error,
    required VoidCallback onRetry,
  }) {
    final isDenied = _isPermissionError(error);
    return Container(
      key: Key(isDenied ? 'review-queue-unauthorized' : 'review-queue-error'),
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDenied ? const Color(0xFFFECACA) : LearnTzColors.border,
        ),
      ),
      child: Column(
        children: [
          Icon(
            isDenied ? Icons.lock_outline : Icons.error_outline,
            size: 40,
            color: const Color(0xFFDC2626),
          ),
          const SizedBox(height: 12),
          Text(
            isDenied
                ? 'Academic Review Access Required'
                : 'Unable to Load Academic Review Queue',
            style: LearnTzTypography.h3.copyWith(
              color: LearnTzColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            isDenied
                ? 'This workspace is restricted to authorized Academic Reviewers and Curriculum Administrators.'
                : error.toString(),
            style: LearnTzTypography.bodyRegular.copyWith(
              color: LearnTzColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (!isDenied) ...[
            const SizedBox(height: 16),
            AppButton(
              label: 'Retry',
              variant: AppButtonVariant.primary,
              size: AppButtonSize.sm,
              icon: Icons.refresh,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}

class _KpiCardData {
  const _KpiCardData({
    required this.keyName,
    required this.label,
    required this.count,
    required this.subtitle,
    required this.accent,
    required this.icon,
    required this.targetStatus,
  });

  final String keyName;
  final String label;
  final int count;
  final String subtitle;
  final Color accent;
  final IconData icon;
  final String targetStatus;
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: LearnTzColors.textSecondary),
        const SizedBox(width: 5),
        Text(
          '$label: ',
          style: LearnTzTypography.bodySmall.copyWith(
            color: LearnTzColors.textSecondary,
          ),
        ),
        Flexible(
          child: Text(
            value,
            style: LearnTzTypography.bodySmall.copyWith(
              color: valueColor ?? LearnTzColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
