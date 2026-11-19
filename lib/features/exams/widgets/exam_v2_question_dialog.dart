import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../exam_v2_models.dart';
import '../exam_v2_providers.dart';

class ExamV2QuestionDialog extends ConsumerStatefulWidget {
  const ExamV2QuestionDialog({
    super.key,
    required this.selection,
    required this.summary,
  });

  final ExamV2SelectionKey selection;
  final ExamV2ContextSummary summary;

  @override
  ConsumerState<ExamV2QuestionDialog> createState() =>
      _ExamV2QuestionDialogState();
}

class _ExamV2QuestionDialogState extends ConsumerState<ExamV2QuestionDialog> {
  final _questionCtrl = TextEditingController();
  final _optionsCtrl = TextEditingController();
  final _answerCtrl = TextEditingController();
  final _rubricCtrl = TextEditingController();
  final _marksCtrl = TextEditingController(text: '2');
  final _explanationCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  final _copyrightCtrl = TextEditingController(text: 'LearnTZ Original');

  String? _selectedSpecificCompetenceId;
  String _questionType = 'multiple_choice';
  String _difficultyLevel = 'medium';
  String _cognitiveTier = 'comprehension';

  bool _isSaving = false;
  String? _errorText;

  static const _formats = [
    ('multiple_choice', 'Multiple Choice'),
    ('matching', 'Matching'),
    ('fill_in_the_blank', 'Fill in the Blanks'),
    ('comprehension', 'Reading Comprehension'),
    ('short_answer', 'Short Answer'),
    ('writing', 'Writing / Composition'),
    ('true_false', 'True or False'),
    ('sentence_construction', 'Sentence Construction'),
    ('ordering', 'Ordering & Sequencing'),
    ('word_completion', 'Word Completion'),
    ('image_based', 'Image-Based'),
    ('audio_based', 'Audio-Based'),
    ('oral_assessment', 'Oral Assessment'),
    ('essay', 'Essay / Extended Response'),
  ];

  bool get _isManualMarkingFormat => const {
        'writing',
        'comprehension',
        'short_answer',
        'sentence_construction',
        'oral_assessment',
        'essay',
      }.contains(_questionType);

  List<ExamV2SpecificCompetence> get _allSpecificCompetences => [
        for (final mc in widget.summary.mainCompetences)
          ...mc.specificCompetences,
      ];

  @override
  void initState() {
    super.initState();
    final all = _allSpecificCompetences;
    if (all.isNotEmpty) {
      _selectedSpecificCompetenceId = all.first.id;
    }
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _optionsCtrl.dispose();
    _answerCtrl.dispose();
    _rubricCtrl.dispose();
    _marksCtrl.dispose();
    _explanationCtrl.dispose();
    _sourceCtrl.dispose();
    _copyrightCtrl.dispose();
    super.dispose();
  }

  Future<void> _save({required bool submitForReview}) async {
    final scId = _selectedSpecificCompetenceId;
    if (scId == null || scId.isEmpty) {
      setState(() => _errorText = 'Select an official specific competence.');
      return;
    }
    final qText = _questionCtrl.text.trim();
    if (qText.length < 3) {
      setState(() => _errorText = 'Enter a clear question statement.');
      return;
    }
    final marks = double.tryParse(_marksCtrl.text.trim()) ?? 0;
    if (marks <= 0) {
      setState(() => _errorText = 'Marks must be greater than 0.');
      return;
    }
    if (!_isManualMarkingFormat && _answerCtrl.text.trim().isEmpty) {
      setState(
        () => _errorText = 'Provide the correct answer key for this question.',
      );
      return;
    }
    if (_isManualMarkingFormat &&
        _rubricCtrl.text.trim().isEmpty &&
        _answerCtrl.text.trim().isEmpty) {
      setState(
        () => _errorText =
            'Provide a marking rubric or model answer for manual marking.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _errorText = null;
    });

    try {
      final repo = ref.read(examCentreV2RepositoryProvider);
      final parsedOptions = _optionsCtrl.text
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final saved = await repo.saveQuestion(
        selection: widget.selection,
        specificCompetenceId: scId,
        questionType: _questionType,
        questionText: qText,
        correctAnswer: _answerCtrl.text.trim().isEmpty
            ? const {}
            : {'answer': _answerCtrl.text.trim()},
        options: parsedOptions,
        markingRubric: _rubricCtrl.text.trim().isEmpty
            ? const {}
            : {'guidance': _rubricCtrl.text.trim()},
        marks: marks,
        difficultyLevel: _difficultyLevel,
        cognitiveTier: _cognitiveTier,
        languageCode: widget.summary.context.language,
        explanation: _explanationCtrl.text.trim(),
        sourceReference: _sourceCtrl.text.trim(),
        copyrightNotice: _copyrightCtrl.text.trim(),
      );

      if (submitForReview) {
        await repo.transitionQuestionStatus(
          questionId: saved['id'] as String,
          action: 'submit_for_review',
          comments: 'Submitted from Question Bank 2.0.',
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
    final allSpecs = _allSpecificCompetences;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 740, maxHeight: 820),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF0F4C81),
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.quiz_outlined, color: Colors.white),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Question Bank 2.0 Item',
                          style: LearnTzTypography.h3.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${ctx.countryName} • ${ctx.gradeName} • ${ctx.subjectName}',
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
                    DropdownButtonFormField<String>(
                      key: const Key('exam-v2-q-competence-dropdown'),
                      initialValue: _selectedSpecificCompetenceId,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Official Specific Competence *',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: allSpecs
                          .map(
                            (sc) => DropdownMenuItem<String>(
                              value: sc.id,
                              child: Text(
                                '${sc.code} ${sc.title}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedSpecificCompetenceId = v),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<String>(
                            key: const Key('exam-v2-q-format-dropdown'),
                            initialValue: _questionType,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Question Format',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: _formats
                                .map(
                                  (f) => DropdownMenuItem(
                                    value: f.$1,
                                    child: Text(f.$2),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _questionType = v);
                            },
                          ),
                        ),
                        SizedBox(
                          width: 140,
                          child: DropdownButtonFormField<String>(
                            initialValue: _difficultyLevel,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Difficulty',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'easy',
                                child: Text('Easy'),
                              ),
                              DropdownMenuItem(
                                value: 'medium',
                                child: Text('Medium'),
                              ),
                              DropdownMenuItem(
                                value: 'hard',
                                child: Text('Hard'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _difficultyLevel = v);
                              }
                            },
                          ),
                        ),
                        SizedBox(
                          width: 160,
                          child: DropdownButtonFormField<String>(
                            initialValue: _cognitiveTier,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Cognitive Tier',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'knowledge',
                                child: Text('Knowledge'),
                              ),
                              DropdownMenuItem(
                                value: 'comprehension',
                                child: Text('Comprehension'),
                              ),
                              DropdownMenuItem(
                                value: 'application',
                                child: Text('Application'),
                              ),
                              DropdownMenuItem(
                                value: 'analysis',
                                child: Text('Analysis'),
                              ),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _cognitiveTier = v);
                              }
                            },
                          ),
                        ),
                        SizedBox(
                          width: 110,
                          child: TextField(
                            key: const Key('exam-v2-q-marks-field'),
                            controller: _marksCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Marks *',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('exam-v2-q-statement-field'),
                      controller: _questionCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Question Statement *',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_questionType == 'multiple_choice' ||
                        _questionType == 'matching' ||
                        _questionType == 'ordering') ...[
                      TextField(
                        key: const Key('exam-v2-q-options-field'),
                        controller: _optionsCtrl,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Options (one per line)',
                          hintText: 'Tall\nSmall\nLong\nWide',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      key: const Key('exam-v2-q-answer-field'),
                      controller: _answerCtrl,
                      decoration: InputDecoration(
                        labelText: _isManualMarkingFormat
                            ? 'Model Answer (optional)'
                            : 'Correct Answer Key *',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('exam-v2-q-rubric-field'),
                      controller: _rubricCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: _isManualMarkingFormat
                            ? 'Marking Rubric / Scoring Criteria *'
                            : 'Marking Rubric (optional)',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _explanationCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Explanation / Marking Note',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 310,
                          child: TextField(
                            controller: _sourceCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Source Reference',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 310,
                          child: TextField(
                            controller: _copyrightCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Copyright / Attribution',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
                    key: const Key('exam-v2-q-save-draft-btn'),
                    label: _isSaving ? 'Saving...' : 'Save Draft',
                    variant: AppButtonVariant.outlined,
                    size: AppButtonSize.sm,
                    icon: Icons.save_outlined,
                    onPressed: _isSaving
                        ? null
                        : () => _save(submitForReview: false),
                  ),
                  AppButton(
                    key: const Key('exam-v2-q-submit-btn'),
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
