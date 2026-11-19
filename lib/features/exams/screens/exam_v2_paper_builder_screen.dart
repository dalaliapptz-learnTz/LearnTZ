import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../exam_v2_models.dart';
import '../exam_v2_providers.dart';

class ExamV2PaperBuilderScreen extends ConsumerStatefulWidget {
  const ExamV2PaperBuilderScreen({
    super.key,
    required this.examinationId,
    required this.selection,
  });

  final String examinationId;
  final ExamV2SelectionKey selection;

  @override
  ConsumerState<ExamV2PaperBuilderScreen> createState() =>
      _ExamV2PaperBuilderScreenState();
}

class _ExamV2PaperBuilderScreenState
    extends ConsumerState<ExamV2PaperBuilderScreen> {
  int _tabIndex = 0; // 0 = Compose Paper, 1 = Formatted Print Preview
  bool _showMarkingGuide = false;
  bool _isMutating = false;
  String? _banner;
  bool _bannerIsError = false;

  void _refresh() {
    ref.invalidate(examV2PaperBuilderProvider(widget.examinationId));
    ref.invalidate(examV2ExaminationsListProvider(widget.selection));
  }

  Future<void> _pickAndAddQuestion(ExamV2PaperSection section) async {
    final questionsResult = await ref
        .read(examCentreV2RepositoryProvider)
        .listQuestions(widget.selection);

    if (!mounted) return;
    final picked = await showDialog<ExamV2QuestionItem>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640, maxHeight: 600),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(18, 14, 10, 14),
                decoration: const BoxDecoration(
                  color: Color(0xFF0F4C81),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Add Question to Section ${section.sectionCode}: ${section.title}',
                        style: LearnTzTypography.bodyRegular.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: questionsResult.items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'No questions available in Question Bank 2.0 for this subject yet. Create questions first, then attach them here.',
                            style: LearnTzTypography.bodySmall.copyWith(
                              color: LearnTzColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(14),
                        itemCount: questionsResult.items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (_, idx) {
                          final q = questionsResult.items[idx];
                          return InkWell(
                            key: Key('paper-bank-pick-${q.id}'),
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => Navigator.of(ctx).pop(q),
                            child: Container(
                              padding: const EdgeInsets.all(12),
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
                                    runSpacing: 4,
                                    children: [
                                      AppBadge(
                                        label:
                                            q.questionType.replaceAll('_', ' '),
                                        variant: AppBadgeVariant.primary,
                                        size: AppBadgeSize.sm,
                                      ),
                                      AppBadge(
                                        label:
                                            '${q.marks.toStringAsFixed(0)} marks',
                                        variant: AppBadgeVariant.success,
                                        size: AppBadgeSize.sm,
                                      ),
                                      if (q.specificCompetenceCode != null)
                                        AppBadge(
                                          label:
                                              'SC ${q.specificCompetenceCode}',
                                          variant: AppBadgeVariant.neutral,
                                          size: AppBadgeSize.sm,
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    q.questionText,
                                    style: LearnTzTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: LearnTzColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );

    if (picked == null || !mounted) return;
    setState(() {
      _isMutating = true;
      _banner = null;
    });
    try {
      await ref.read(examCentreV2RepositoryProvider).addPaperQuestion(
            examinationId: widget.examinationId,
            sectionId: section.id,
            sourceQuestionId: picked.id,
          );
      if (!mounted) return;
      setState(() {
        _isMutating = false;
        _banner =
            'Attached versioned snapshot to Section ${section.sectionCode}.';
        _bannerIsError = false;
      });
      _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isMutating = false;
        _banner = e.toString().replaceFirst('Exception: ', '');
        _bannerIsError = true;
      });
    }
  }

  Future<void> _moveQuestion(
    ExamV2PaperSection section,
    int index,
    int delta,
  ) async {
    final target = index + delta;
    if (target < 0 || target >= section.questions.length) return;
    final ids = section.questions.map((q) => q.id).toList();
    final item = ids.removeAt(index);
    ids.insert(target, item);

    setState(() => _isMutating = true);
    try {
      await ref.read(examCentreV2RepositoryProvider).reorderPaperQuestions(
            examinationId: widget.examinationId,
            sectionId: section.id,
            orderedIds: ids,
          );
      if (!mounted) return;
      setState(() => _isMutating = false);
      _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isMutating = false;
        _banner = e.toString().replaceFirst('Exception: ', '');
        _bannerIsError = true;
      });
    }
  }

  Future<void> _removeQuestion(String paperQuestionId) async {
    setState(() => _isMutating = true);
    try {
      await ref
          .read(examCentreV2RepositoryProvider)
          .removePaperQuestion(paperQuestionId);
      if (!mounted) return;
      setState(() {
        _isMutating = false;
        _banner = 'Question removed and paper renumbered.';
        _bannerIsError = false;
      });
      _refresh();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isMutating = false;
        _banner = e.toString().replaceFirst('Exception: ', '');
        _bannerIsError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bundleAsync =
        ref.watch(examV2PaperBuilderProvider(widget.examinationId));

    return Scaffold(
      backgroundColor: LearnTzColors.background,
      body: SafeArea(
        child: bundleAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Unable to load Paper Builder: $err',
                style: LearnTzTypography.bodyRegular.copyWith(
                  color: const Color(0xFFDC2626),
                ),
              ),
            ),
          ),
          data: (bundle) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1120),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top Bar
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Paper Builder • ${bundle.title}',
                                style: LearnTzTypography.h3.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: LearnTzColors.textPrimary,
                                ),
                              ),
                              Text(
                                '${bundle.countryName} • ${bundle.gradeName} • ${bundle.subjectName} • ${bundle.totalMarks.toStringAsFixed(0)} marks • ${bundle.questionCount} questions',
                                style: LearnTzTypography.caption.copyWith(
                                  color: LearnTzColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Mode toggle
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        AppButton(
                          key: const Key('paper-builder-compose-tab'),
                          label: 'Compose Paper',
                          icon: Icons.edit_document,
                          variant: _tabIndex == 0
                              ? AppButtonVariant.primary
                              : AppButtonVariant.outlined,
                          size: AppButtonSize.sm,
                          onPressed: () => setState(() => _tabIndex = 0),
                        ),
                        AppButton(
                          key: const Key('paper-builder-preview-tab'),
                          label: 'Print Preview',
                          icon: Icons.print_outlined,
                          variant: _tabIndex == 1
                              ? AppButtonVariant.primary
                              : AppButtonVariant.outlined,
                          size: AppButtonSize.sm,
                          onPressed: () => setState(() => _tabIndex = 1),
                        ),
                        if (_tabIndex == 1)
                          FilterChip(
                            key: const Key('paper-builder-marking-guide-chip'),
                            label: const Text('Show Marking Guide'),
                            selected: _showMarkingGuide,
                            onSelected: (v) =>
                                setState(() => _showMarkingGuide = v),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    if (_banner != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _bannerIsError
                              ? const Color(0xFFFEF2F2)
                              : const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _bannerIsError
                                ? const Color(0xFFFECACA)
                                : const Color(0xFFBBF7D0),
                          ),
                        ),
                        child: Text(
                          _banner!,
                          style: LearnTzTypography.bodySmall.copyWith(
                            color: _bannerIsError
                                ? const Color(0xFF991B1B)
                                : const Color(0xFF166534),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    if (_tabIndex == 0)
                      _buildComposeView(bundle)
                    else
                      _buildPrintPreview(bundle),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComposeView(ExamV2PaperBuilderBundle bundle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Validation Strip
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: bundle.isValid
                ? const Color(0xFFF0FDF4)
                : const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: bundle.isValid
                  ? const Color(0xFFBBF7D0)
                  : const Color(0xFFFDE68A),
            ),
          ),
          child: Row(
            children: [
              Icon(
                bundle.isValid
                    ? Icons.check_circle_outline
                    : Icons.warning_amber_outlined,
                color: bundle.isValid
                    ? const Color(0xFF15803D)
                    : const Color(0xFFD97706),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  bundle.isValid
                      ? 'Paper validation passed: ${bundle.sections.length} section(s), ${bundle.questionCount} versioned question(s), ${bundle.totalMarks.toStringAsFixed(0)} total marks.'
                      : bundle.validationIssues.join(' '),
                  style: LearnTzTypography.bodySmall.copyWith(
                    color: bundle.isValid
                        ? const Color(0xFF166534)
                        : const Color(0xFF92400E),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Sections
        ...bundle.sections.map((section) {
          return Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: LearnTzColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppBadge(
                          label: 'SECTION ${section.sectionCode}',
                          variant: AppBadgeVariant.primary,
                          size: AppBadgeSize.sm,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            section.title,
                            style: LearnTzTypography.bodyRegular.copyWith(
                              fontWeight: FontWeight.w800,
                              color: LearnTzColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppButton(
                      key: Key('paper-add-q-sec-${section.sectionCode}'),
                      label: 'Add from Question Bank',
                      icon: Icons.add,
                      variant: AppButtonVariant.outlined,
                      size: AppButtonSize.sm,
                      onPressed: _isMutating
                          ? null
                          : () => _pickAndAddQuestion(section),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (section.questions.isEmpty)
                  Text(
                    'No questions attached to Section ${section.sectionCode} yet.',
                    style: LearnTzTypography.bodySmall.copyWith(
                      color: LearnTzColors.textSecondary,
                    ),
                  )
                else
                  ...List.generate(section.questions.length, (idx) {
                    final q = section.questions[idx];
                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: LearnTzColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(0xFF0F4C81),
                            child: Text(
                              '${q.questionNumber}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  q.questionText,
                                  style: LearnTzTypography.bodySmall.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: LearnTzColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Text(
                                      '${q.marks.toStringAsFixed(0)} marks',
                                      style: LearnTzTypography.caption.copyWith(
                                        color: const Color(0xFF15803D),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      'Snapshot v${q.sourceQuestionVersion}',
                                      style: LearnTzTypography.caption.copyWith(
                                        color: LearnTzColors.textSecondary,
                                      ),
                                    ),
                                    if (q.specificCompetenceCode != null)
                                      Text(
                                        'SC ${q.specificCompetenceCode}',
                                        style: LearnTzTypography.caption
                                            .copyWith(
                                          color: const Color(0xFF0F4C81),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_upward, size: 16),
                            onPressed: _isMutating || idx == 0
                                ? null
                                : () => _moveQuestion(section, idx, -1),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_downward, size: 16),
                            onPressed: _isMutating ||
                                    idx == section.questions.length - 1
                                ? null
                                : () => _moveQuestion(section, idx, 1),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 16,
                              color: Color(0xFFDC2626),
                            ),
                            onPressed: _isMutating
                                ? null
                                : () => _removeQuestion(q.id),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPrintPreview(ExamV2PaperBuilderBundle bundle) {
    final countryHeader = bundle.countryCode == 'TZ'
        ? 'UNITED REPUBLIC OF TANZANIA'
        : bundle.countryName.toUpperCase();

    return Container(
      key: const Key('paper-builder-print-preview'),
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            countryHeader,
            textAlign: TextAlign.center,
            style: LearnTzTypography.bodyRegular.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'LEARN TZ • EXAMINATION CENTRE',
            textAlign: TextAlign.center,
            style: LearnTzTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: const Color(0xFF0F4C81),
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            bundle.subjectName.toUpperCase(),
            textAlign: TextAlign.center,
            style: LearnTzTypography.h3.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            '${bundle.examTypeName.toUpperCase()} — ${bundle.gradeName.toUpperCase()}',
            textAlign: TextAlign.center,
            style: LearnTzTypography.bodyRegular.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 24,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: [
              const Text('Name: ____________________________'),
              const Text('Date: ______________'),
              Text('Time: ${bundle.durationMinutes} Minutes'),
              Text('Total Marks: ${bundle.totalMarks.toStringAsFixed(0)}'),
            ],
          ),
          const Divider(height: 28),
          Text(
            'INSTRUCTIONS',
            style: LearnTzTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(bundle.instructions, style: LearnTzTypography.bodySmall),
          const SizedBox(height: 20),
          ...bundle.sections.map((section) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SECTION ${section.sectionCode}: ${section.title.toUpperCase()} (${section.marksAllocated.toStringAsFixed(0)} Marks)',
                    style: LearnTzTypography.bodyRegular.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F4C81),
                    ),
                  ),
                  if (section.instructions.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      section.instructions,
                      style: LearnTzTypography.bodySmall.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  ...section.questions.map((q) {
                    const letters = ['A', 'B', 'C', 'D', 'E', 'F'];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${q.questionNumber}. ${q.questionText}  [${q.marks.toStringAsFixed(0)} marks]',
                            style: LearnTzTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (q.options.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            ...List.generate(q.options.length, (oi) {
                              final letter = oi < letters.length
                                  ? letters[oi]
                                  : '${oi + 1}';
                              return Padding(
                                padding:
                                    const EdgeInsets.only(left: 18, bottom: 2),
                                child: Text(
                                  '$letter. ${q.options[oi]}',
                                  style: LearnTzTypography.bodySmall,
                                ),
                              );
                            }),
                          ],
                          if (_showMarkingGuide &&
                              (q.correctAnswer != null ||
                                  q.markingRubric != null)) ...[
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0FDF4),
                                borderRadius: BorderRadius.circular(6),
                                border:
                                    Border.all(color: const Color(0xFFBBF7D0)),
                              ),
                              child: Text(
                                'Marking Guide: ${q.correctAnswer?['answer'] ?? q.markingRubric?['guidance'] ?? 'See rubric'}',
                                style: LearnTzTypography.caption.copyWith(
                                  color: const Color(0xFF166534),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
