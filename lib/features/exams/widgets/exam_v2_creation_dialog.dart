import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../exam_v2_models.dart';
import '../exam_v2_providers.dart';

class ExamV2CreationDialog extends ConsumerStatefulWidget {
  const ExamV2CreationDialog({
    super.key,
    required this.selection,
    required this.summary,
  });

  final ExamV2SelectionKey selection;
  final ExamV2ContextSummary summary;

  @override
  ConsumerState<ExamV2CreationDialog> createState() =>
      _ExamV2CreationDialogState();
}

class _ExamV2CreationDialogState extends ConsumerState<ExamV2CreationDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _termCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _instructionsCtrl;

  String _deliveryMode = 'hybrid';
  final Set<String> _selectedCompetenceIds = {};
  final List<ExamV2SectionDraft> _sections = [];

  bool _isSaving = false;
  String? _errorText;

  static const _questionFormats = [
    ('multiple_choice', 'Multiple Choice'),
    ('matching', 'Matching Items'),
    ('fill_in_the_blank', 'Fill in the Blanks'),
    ('short_answer', 'Short Answers'),
    ('comprehension', 'Reading Comprehension'),
    ('writing', 'Writing / Composition'),
    ('true_false', 'True or False'),
    ('sentence_construction', 'Sentence Construction'),
    ('ordering', 'Ordering & Sequencing'),
    ('essay', 'Essay / Extended Response'),
  ];

  @override
  void initState() {
    super.initState();
    final ctx = widget.summary.context;
    _titleCtrl = TextEditingController(text: ctx.suggestedExaminationTitle);
    _yearCtrl = TextEditingController(text: '${DateTime.now().year}');
    _termCtrl = TextEditingController(text: 'Term I');
    _durationCtrl = TextEditingController(text: '${ctx.defaultDurationMinutes}');
    _instructionsCtrl = TextEditingController(
      text:
          'Read all questions carefully. Answer all questions unless otherwise instructed. Write neatly.',
    );

    // Pre-select first 2 official specific competences where available
    for (final mc in widget.summary.mainCompetences) {
      for (final sc in mc.specificCompetences) {
        if (_selectedCompetenceIds.length < 2) {
          _selectedCompetenceIds.add(sc.id);
        }
      }
    }

    // Default editable starter blueprint (can be added, removed, renamed, reordered)
    _sections.addAll(const [
      ExamV2SectionDraft(
        sectionCode: 'A',
        title: 'Multiple Choice',
        questionFormat: 'multiple_choice',
        questionCount: 10,
        marksAllocated: 20,
        displayOrder: 1,
      ),
      ExamV2SectionDraft(
        sectionCode: 'B',
        title: 'Fill in the Blanks',
        questionFormat: 'fill_in_the_blank',
        questionCount: 5,
        marksAllocated: 15,
        displayOrder: 2,
      ),
      ExamV2SectionDraft(
        sectionCode: 'C',
        title: 'Short Answers',
        questionFormat: 'short_answer',
        questionCount: 5,
        marksAllocated: 15,
        displayOrder: 3,
      ),
    ]);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _yearCtrl.dispose();
    _termCtrl.dispose();
    _durationCtrl.dispose();
    _instructionsCtrl.dispose();
    super.dispose();
  }

  double get _calculatedTotalMarks =>
      _sections.fold(0.0, (sum, s) => sum + s.marksAllocated);

  void _addSection() {
    final nextIdx = _sections.length + 1;
    final code = String.fromCharCode(64 + nextIdx.clamp(1, 26));
    setState(() {
      _sections.add(
        ExamV2SectionDraft(
          sectionCode: code,
          title: 'Section $code',
          questionFormat: 'short_answer',
          questionCount: 5,
          marksAllocated: 10,
          displayOrder: nextIdx,
        ),
      );
    });
  }

  void _removeSection(int index) {
    setState(() {
      _sections.removeAt(index);
      for (var i = 0; i < _sections.length; i++) {
        _sections[i] = _sections[i].copyWith(
          sectionCode: String.fromCharCode(65 + i),
          displayOrder: i + 1,
        );
      }
    });
  }

  Future<void> _save({required bool submitForReview}) async {
    final title = _titleCtrl.text.trim();
    if (title.length < 3) {
      setState(() => _errorText = 'Please enter an examination title.');
      return;
    }
    if (submitForReview && (_sections.isEmpty || _calculatedTotalMarks <= 0)) {
      setState(() {
        _errorText =
            'At least one blueprint section with marks > 0 is required before submitting for review.';
      });
      return;
    }
    if (submitForReview && _selectedCompetenceIds.isEmpty) {
      setState(() {
        _errorText =
            'Select at least one official curriculum competence before submitting for review.';
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final repo = ref.read(examCentreV2RepositoryProvider);
      final year = int.tryParse(_yearCtrl.text.trim()) ?? DateTime.now().year;
      final duration = int.tryParse(_durationCtrl.text.trim()) ??
          widget.summary.context.defaultDurationMinutes;

      final perCompMarks = _selectedCompetenceIds.isEmpty
          ? 0.0
          : (_calculatedTotalMarks / _selectedCompetenceIds.length);

      final competencies = _selectedCompetenceIds
          .map(
            (scId) => ExamV2CompetencyAllocation(
              specificCompetenceId: scId,
              allocatedMarks: perCompMarks,
              targetQuestionCount: 5,
            ),
          )
          .toList();

      final saved = await repo.saveExamination(
        selection: widget.selection,
        title: title,
        academicYear: year,
        academicTerm: _termCtrl.text.trim().isEmpty
            ? 'Term I'
            : _termCtrl.text.trim(),
        durationMinutes: duration.clamp(15, 360),
        languageCode: widget.summary.context.language,
        instructions: _instructionsCtrl.text.trim(),
        deliveryMode: _deliveryMode,
        sections: _sections,
        competencies: competencies,
      );

      if (submitForReview) {
        final examId = saved['id'] as String;
        await repo.transitionExaminationStatus(
          examinationId: examId,
          action: 'submit_for_review',
          comments: 'Submitted from Examination Centre 2.0 wizard.',
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctx = widget.summary.context;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 780, maxHeight: 820),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF0F4C81),
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.assignment_add, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create New Examination',
                          style: LearnTzTypography.h3.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${ctx.countryName} • ${ctx.gradeName} • ${ctx.subjectName} • ${ctx.examinationTypeName}',
                          style: LearnTzTypography.caption.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(false),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorText != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: Text(
                          _errorText!,
                          style: LearnTzTypography.bodySmall.copyWith(
                            color: const Color(0xFF991B1B),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // Section 1: Metadata
                    Text(
                      '1. Examination Details',
                      style: LearnTzTypography.bodyRegular.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F4C81),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      key: const Key('exam-v2-title-field'),
                      controller: _titleCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Examination Title *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 140,
                          child: TextField(
                            controller: _yearCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Academic Year',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 160,
                          child: TextField(
                            controller: _termCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Academic Term',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 160,
                          child: TextField(
                            controller: _durationCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Duration (mins)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 190,
                          child: DropdownButtonFormField<String>(
                            initialValue: _deliveryMode,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Delivery Mode',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'hybrid',
                                child: Text('Online & Printed'),
                              ),
                              DropdownMenuItem(
                                value: 'online',
                                child: Text('Online Only'),
                              ),
                              DropdownMenuItem(
                                value: 'printed',
                                child: Text('Printed Only'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _deliveryMode = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _instructionsCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Candidate Instructions',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Section 2: Official Curriculum Coverage
                    Text(
                      '2. Official Curriculum Coverage (${_selectedCompetenceIds.length} selected)',
                      style: LearnTzTypography.bodyRegular.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F4C81),
                      ),
                    ),
                    const SizedBox(height: 6),
                    ...widget.summary.mainCompetences.map((mc) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 4),
                            child: Text(
                              '${mc.code} ${mc.title}',
                              style: LearnTzTypography.bodySmall.copyWith(
                                fontWeight: FontWeight.w700,
                                color: LearnTzColors.textPrimary,
                              ),
                            ),
                          ),
                          ...mc.specificCompetences.map((sc) {
                            final checked =
                                _selectedCompetenceIds.contains(sc.id);
                            return CheckboxListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: checked,
                              title: Text(
                                '${sc.code} ${sc.title}',
                                style: LearnTzTypography.bodySmall,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    _selectedCompetenceIds.add(sc.id);
                                  } else {
                                    _selectedCompetenceIds.remove(sc.id);
                                  }
                                });
                              },
                            );
                          }),
                        ],
                      );
                    }),
                    const SizedBox(height: 20),

                    // Section 3: Blueprint Sections
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '3. Examination Blueprint Sections',
                            style: LearnTzTypography.bodyRegular.copyWith(
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F4C81),
                            ),
                          ),
                        ),
                        AppBadge(
                          key: const Key('exam-v2-total-marks-badge'),
                          label:
                              'Total Marks: ${_calculatedTotalMarks.toStringAsFixed(0)}',
                          variant: AppBadgeVariant.success,
                          size: AppBadgeSize.sm,
                        ),
                        const SizedBox(width: 8),
                        TextButton.icon(
                          key: const Key('exam-v2-add-section-btn'),
                          onPressed: _addSection,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Add Section'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...List.generate(_sections.length, (i) {
                      final sec = _sections[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: LearnTzColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AppBadge(
                                  label: 'Section ${sec.sectionCode}',
                                  variant: AppBadgeVariant.primary,
                                  size: AppBadgeSize.sm,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    sec.title,
                                    style: LearnTzTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    size: 18,
                                    color: Color(0xFFDC2626),
                                  ),
                                  onPressed: _sections.length <= 1
                                      ? null
                                      : () => _removeSection(i),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              children: [
                                SizedBox(
                                  width: 210,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: sec.questionFormat,
                                    isExpanded: true,
                                    decoration: const InputDecoration(
                                      labelText: 'Question Format',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    items: _questionFormats
                                        .map(
                                          (f) => DropdownMenuItem(
                                            value: f.$1,
                                            child: Text(f.$2),
                                          ),
                                        )
                                        .toList(),
                                    onChanged: (v) {
                                      if (v == null) return;
                                      final label = _questionFormats
                                          .firstWhere((f) => f.$1 == v)
                                          .$2;
                                      setState(() {
                                        _sections[i] = sec.copyWith(
                                          questionFormat: v,
                                          title: label,
                                        );
                                      });
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 110,
                                  child: TextFormField(
                                    initialValue: '${sec.questionCount}',
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Questions',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    onChanged: (v) {
                                      final parsed = int.tryParse(v);
                                      if (parsed != null && parsed > 0) {
                                        setState(() {
                                          _sections[i] = sec.copyWith(
                                            questionCount: parsed,
                                          );
                                        });
                                      }
                                    },
                                  ),
                                ),
                                SizedBox(
                                  width: 110,
                                  child: TextFormField(
                                    initialValue:
                                        sec.marksAllocated.toStringAsFixed(0),
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Marks',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    onChanged: (v) {
                                      final parsed = double.tryParse(v);
                                      if (parsed != null && parsed > 0) {
                                        setState(() {
                                          _sections[i] = sec.copyWith(
                                            marksAllocated: parsed,
                                          );
                                        });
                                      }
                                    },
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
            ),

            // Footer actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                border: Border(top: BorderSide(color: LearnTzColors.border)),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14),
                ),
              ),
              child: Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.end,
                children: [
                  AppButton(
                    label: 'Cancel',
                    variant: AppButtonVariant.outlined,
                    size: AppButtonSize.sm,
                    onPressed: _isSaving
                        ? null
                        : () => Navigator.of(context).pop(false),
                  ),
                  AppButton(
                    key: const Key('exam-v2-save-draft-btn'),
                    label: _isSaving ? 'Saving...' : 'Save Draft',
                    variant: AppButtonVariant.outlined,
                    size: AppButtonSize.sm,
                    icon: Icons.save_outlined,
                    onPressed: _isSaving
                        ? null
                        : () => _save(submitForReview: false),
                  ),
                  AppButton(
                    key: const Key('exam-v2-submit-review-btn'),
                    label: 'Submit for Review',
                    variant: AppButtonVariant.primary,
                    size: AppButtonSize.sm,
                    icon: Icons.send_outlined,
                    onPressed: _isSaving
                        ? null
                        : () => _save(submitForReview: true),
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
