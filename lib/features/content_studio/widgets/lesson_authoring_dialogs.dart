import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../content_studio_models.dart';
import '../content_studio_providers.dart';
import '../lesson_authoring_models.dart';
import '../lesson_authoring_providers.dart';

/// Dialog for adding or editing a structured content block (all 12 types).
class LessonContentBlockDialog extends StatefulWidget {
  const LessonContentBlockDialog({
    super.key,
    this.existing,
    this.onPickMedia,
  });

  final LessonContentBlock? existing;
  final Future<MediaAssetItem?> Function()? onPickMedia;

  @override
  State<LessonContentBlockDialog> createState() =>
      _LessonContentBlockDialogState();
}

class _LessonContentBlockDialogState extends State<LessonContentBlockDialog> {
  final _formKey = GlobalKey<FormState>();
  late LessonContentBlockType _type;
  late final TextEditingController _titleCtrl;
  late final TextEditingController _contentCtrl;
  late final TextEditingController _mediaUrlCtrl;
  late final TextEditingController _captionCtrl;
  late final TextEditingController _altTextCtrl;
  String? _mediaAssetId;

  bool get _isMediaBlock =>
      _type == LessonContentBlockType.image ||
      _type == LessonContentBlockType.audio ||
      _type == LessonContentBlockType.video ||
      _type == LessonContentBlockType.diagram;

  @override
  void initState() {
    super.initState();
    final b = widget.existing;
    _type = b?.type ?? LessonContentBlockType.textExplanation;
    _titleCtrl = TextEditingController(text: b?.title ?? '');
    _contentCtrl = TextEditingController(text: b?.content ?? '');
    _mediaUrlCtrl = TextEditingController(text: b?.mediaUrl ?? '');
    _captionCtrl = TextEditingController(text: b?.caption ?? '');
    _altTextCtrl = TextEditingController(text: b?.altText ?? '');
    _mediaAssetId = b?.mediaAssetId;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _contentCtrl.dispose();
    _mediaUrlCtrl.dispose();
    _captionCtrl.dispose();
    _altTextCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectFromLibrary() async {
    if (widget.onPickMedia == null) return;
    final asset = await widget.onPickMedia!();
    if (asset != null && mounted) {
      setState(() {
        _mediaAssetId = asset.id;
        _mediaUrlCtrl.text = asset.fileUrl;
        if (_titleCtrl.text.trim().isEmpty) {
          _titleCtrl.text = asset.title;
        }
        if (_altTextCtrl.text.trim().isEmpty && asset.altText != null) {
          _altTextCtrl.text = asset.altText!;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Add Content Section' : 'Edit Content Section',
        style: LearnTzTypography.h3.copyWith(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<LessonContentBlockType>(
                  key: const Key('content-block-type-dropdown'),
                  initialValue: _type,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Content Block Type *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: LessonContentBlockType.values
                      .map(
                        (t) => DropdownMenuItem(
                          value: t,
                          child: Text(t.label),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _type = v);
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('content-block-title-input'),
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Section Title *',
                    hintText: 'e.g. Introduction to Consonant Blends',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Section title is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  key: const Key('content-block-body-input'),
                  controller: _contentCtrl,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: _isMediaBlock
                        ? 'Teaching Notes / Transcript / Description'
                        : 'Instructional Content *',
                    hintText: 'Write clear, grade-appropriate instructional content...',
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) {
                    if (!_isMediaBlock && (v == null || v.trim().isEmpty)) {
                      return 'Instructional content is required';
                    }
                    return null;
                  },
                ),
                if (_isMediaBlock) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _mediaUrlCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Media Storage Path / URL *',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Select or upload a media asset'
                              : null,
                        ),
                      ),
                      if (widget.onPickMedia != null) ...[
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _selectFromLibrary,
                          icon: const Icon(Icons.perm_media_outlined, size: 16),
                          label: const Text('Media Library'),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _captionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Caption',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _altTextCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Accessibility Alt Text / Audio Transcript',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AppButton(
          key: const Key('save-content-block-btn'),
          label: widget.existing == null ? 'Add Section' : 'Save Section',
          variant: AppButtonVariant.primary,
          size: AppButtonSize.sm,
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(
              LessonContentBlock(
                id: widget.existing?.id ??
                    'blk_${DateTime.now().microsecondsSinceEpoch}',
                type: _type,
                title: _titleCtrl.text.trim(),
                content: _contentCtrl.text.trim(),
                mediaAssetId: _mediaAssetId,
                mediaUrl: _mediaUrlCtrl.text.trim().isEmpty
                    ? null
                    : _mediaUrlCtrl.text.trim(),
                caption: _captionCtrl.text.trim().isEmpty
                    ? null
                    : _captionCtrl.text.trim(),
                altText: _altTextCtrl.text.trim().isEmpty
                    ? null
                    : _altTextCtrl.text.trim(),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Dialog for adding/editing a Teaching & Learning Activity.
class TeachingActivityDialog extends StatefulWidget {
  const TeachingActivityDialog({super.key, this.existing});

  final LessonTeachingActivity? existing;

  @override
  State<TeachingActivityDialog> createState() => _TeachingActivityDialogState();
}

class _TeachingActivityDialogState extends State<TeachingActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleCtrl;
  late final TextEditingController _instructionsCtrl;
  late final TextEditingController _objectiveCtrl;
  late final TextEditingController _materialsCtrl;
  late final TextEditingController _expectedCtrl;
  late final TextEditingController _criteriaCtrl;
  late int _minutes;
  late String _activityType;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _titleCtrl = TextEditingController(text: a?.title ?? '');
    _instructionsCtrl = TextEditingController(text: a?.instructions ?? '');
    _objectiveCtrl = TextEditingController(text: a?.learningObjective ?? '');
    _materialsCtrl = TextEditingController(text: a?.requiredMaterials ?? '');
    _expectedCtrl = TextEditingController(text: a?.expectedResponse ?? '');
    _criteriaCtrl = TextEditingController(text: a?.assessmentCriteria ?? '');
    _minutes = a?.estimatedMinutes ?? 10;
    _activityType = a?.activityType ?? 'individual';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _instructionsCtrl.dispose();
    _objectiveCtrl.dispose();
    _materialsCtrl.dispose();
    _expectedCtrl.dispose();
    _criteriaCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.existing == null ? 'Add Teaching Activity' : 'Edit Teaching Activity',
        style: LearnTzTypography.h3.copyWith(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  key: const Key('activity-title-input'),
                  controller: _titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Activity Title *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _activityType,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Activity Type *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'individual', child: Text('Individual')),
                          DropdownMenuItem(value: 'pair', child: Text('Pair Work')),
                          DropdownMenuItem(value: 'group', child: Text('Group Work')),
                          DropdownMenuItem(
                              value: 'practical', child: Text('Practical Task')),
                          DropdownMenuItem(
                              value: 'interactive',
                              child: Text('Interactive Activity')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _activityType = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 140,
                      child: DropdownButtonFormField<int>(
                        initialValue: _minutes,
                        decoration: const InputDecoration(
                          labelText: 'Est. Time',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [5, 10, 15, 20, 30, 40]
                            .map((m) => DropdownMenuItem(
                                value: m, child: Text('$m min')))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _minutes = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _objectiveCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Learning Objective *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('activity-instructions-input'),
                  controller: _instructionsCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Instructions *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _materialsCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Required Materials',
                    hintText: 'e.g. Audio track, flashcards, exercise book',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _expectedCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Expected Learner Response',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _criteriaCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Assessment Criteria',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AppButton(
          key: const Key('save-activity-btn'),
          label: 'Save Activity',
          variant: AppButtonVariant.primary,
          size: AppButtonSize.sm,
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(
              LessonTeachingActivity(
                id: widget.existing?.id ??
                    'act_${DateTime.now().microsecondsSinceEpoch}',
                title: _titleCtrl.text.trim(),
                instructions: _instructionsCtrl.text.trim(),
                learningObjective: _objectiveCtrl.text.trim(),
                requiredMaterials: _materialsCtrl.text.trim(),
                estimatedMinutes: _minutes,
                activityType: _activityType,
                expectedResponse: _expectedCtrl.text.trim(),
                assessmentCriteria: _criteriaCtrl.text.trim(),
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Dialog for creating/editing an Assessment Question linked to question_bank & Learning Outcomes.
class AssessmentQuestionDialog extends StatefulWidget {
  const AssessmentQuestionDialog({
    super.key,
    required this.learningOutcomes,
    this.existing,
  });

  final List<LessonLearningOutcome> learningOutcomes;
  final LessonAssessmentQuestion? existing;

  @override
  State<AssessmentQuestionDialog> createState() =>
      _AssessmentQuestionDialogState();
}

class _AssessmentQuestionDialogState extends State<AssessmentQuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  late LessonQuestionType _type;
  late String _difficulty;
  late String _cognitiveTier;
  String? _outcomeRef;
  late final TextEditingController _questionCtrl;
  late final TextEditingController _optionsCtrl;
  late final TextEditingController _correctCtrl;
  late final TextEditingController _explanationCtrl;
  late final TextEditingController _criteriaCtrl;
  late final TextEditingController _marksCtrl;

  @override
  void initState() {
    super.initState();
    final q = widget.existing;
    _type = q?.questionType ?? LessonQuestionType.multipleChoice;
    _difficulty = q?.difficultyLevel ?? 'medium';
    _cognitiveTier = q?.cognitiveTier ?? 'knowledge';
    _outcomeRef = q?.learningOutcomeRef ??
        (widget.learningOutcomes.isNotEmpty
            ? widget.learningOutcomes.first.id
            : null);
    _questionCtrl = TextEditingController(text: q?.questionText ?? '');
    _optionsCtrl = TextEditingController(
      text: q != null && q.options.isNotEmpty
          ? q.options.join('\n')
          : 'Option A\nOption B\nOption C\nOption D',
    );
    _correctCtrl = TextEditingController(
      text: q?.correctAnswer is String
          ? q!.correctAnswer as String
          : (q?.correctAnswer?.toString() ?? ''),
    );
    _explanationCtrl = TextEditingController(text: q?.explanation ?? '');
    _criteriaCtrl = TextEditingController(text: q?.assessmentCriteria ?? '');
    _marksCtrl = TextEditingController(
      text: (q?.marks ?? 1).toStringAsFixed(0),
    );
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _optionsCtrl.dispose();
    _correctCtrl.dispose();
    _explanationCtrl.dispose();
    _criteriaCtrl.dispose();
    _marksCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final needsOptions = _type == LessonQuestionType.multipleChoice ||
        _type == LessonQuestionType.matching;

    return AlertDialog(
      title: Text(
        widget.existing == null
            ? 'Add Assessment Question'
            : 'Edit Assessment Question',
        style: LearnTzTypography.h3.copyWith(fontWeight: FontWeight.w700),
      ),
      content: SizedBox(
        width: 580,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<LessonQuestionType>(
                  key: const Key('assessment-question-type-dropdown'),
                  initialValue: _type,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Question Type *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  items: LessonQuestionType.values
                      .map((t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.label),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _type = v);
                  },
                ),
                const SizedBox(height: 10),
                if (widget.learningOutcomes.isNotEmpty) ...[
                  DropdownButtonFormField<String?>(
                    initialValue: widget.learningOutcomes
                            .any((o) => o.id == _outcomeRef)
                        ? _outcomeRef
                        : null,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Aligned Learning Outcome',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: widget.learningOutcomes
                        .map((o) => DropdownMenuItem<String?>(
                              value: o.id,
                              child: Text(
                                o.outcome,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ))
                        .toList(),
                    onChanged: (v) => setState(() => _outcomeRef = v),
                  ),
                  const SizedBox(height: 10),
                ],
                TextFormField(
                  key: const Key('assessment-question-text-input'),
                  controller: _questionCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Question / Task Prompt *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                if (needsOptions) ...[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _optionsCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      labelText: _type == LessonQuestionType.matching
                          ? 'Matching Pairs (one per line, e.g. Ship -> Short vowel)'
                          : 'Answer Options (one per line) *',
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                TextFormField(
                  key: const Key('assessment-correct-answer-input'),
                  controller: _correctCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Correct Answer / Expected Rubric Response *',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _difficulty,
                        decoration: const InputDecoration(
                          labelText: 'Difficulty',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'easy', child: Text('Easy')),
                          DropdownMenuItem(
                              value: 'medium', child: Text('Medium')),
                          DropdownMenuItem(value: 'hard', child: Text('Hard')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _difficulty = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _cognitiveTier,
                        decoration: const InputDecoration(
                          labelText: 'Cognitive Tier',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'knowledge', child: Text('Knowledge')),
                          DropdownMenuItem(
                              value: 'comprehension',
                              child: Text('Comprehension')),
                          DropdownMenuItem(
                              value: 'application', child: Text('Application')),
                          DropdownMenuItem(
                              value: 'analysis', child: Text('Analysis')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => _cognitiveTier = v);
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 90,
                      child: TextFormField(
                        controller: _marksCtrl,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Marks *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) {
                          final n = double.tryParse(v ?? '');
                          if (n == null || n <= 0 || n > 100) {
                            return '1-100';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _explanationCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Explanation / Learner Feedback',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _criteriaCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Assessment Criteria',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        AppButton(
          key: const Key('save-assessment-question-btn'),
          label: 'Save Question',
          variant: AppButtonVariant.primary,
          size: AppButtonSize.sm,
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            final opts = needsOptions
                ? _optionsCtrl.text
                    .split('\n')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList()
                : (_type == LessonQuestionType.trueFalse
                    ? const ['True', 'False']
                    : const <String>[]);
            Navigator.of(context).pop(
              LessonAssessmentQuestion(
                id: widget.existing?.id,
                questionType: _type,
                questionText: _questionCtrl.text.trim(),
                correctAnswer: {'answer': _correctCtrl.text.trim()},
                options: opts,
                explanation: _explanationCtrl.text.trim(),
                marks: double.tryParse(_marksCtrl.text.trim()) ?? 1.0,
                difficultyLevel: _difficulty,
                learningOutcomeRef: _outcomeRef,
                assessmentCriteria: _criteriaCtrl.text.trim(),
                cognitiveTier: _cognitiveTier,
              ),
            );
          },
        ),
      ],
    );
  }
}

/// Reusable Media Library Picker & Secure Uploader Dialog.
class LessonMediaLibraryPickerDialog extends ConsumerStatefulWidget {
  const LessonMediaLibraryPickerDialog({
    super.key,
    required this.countryCode,
    this.subjectId,
  });

  final String countryCode;
  final String? subjectId;

  @override
  ConsumerState<LessonMediaLibraryPickerDialog> createState() =>
      _LessonMediaLibraryPickerDialogState();
}

class _LessonMediaLibraryPickerDialogState
    extends ConsumerState<LessonMediaLibraryPickerDialog> {
  bool _showUploadForm = false;
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  final _attributionCtrl = TextEditingController();
  final _altTextCtrl = TextEditingController();
  final _transcriptCtrl = TextEditingController();
  String _mediaType = 'image';
  String _licenseType = 'unverified';
  Uint8List? _selectedFileBytes;
  String? _selectedFileName;
  bool _isUploading = false;
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _sourceCtrl.dispose();
    _attributionCtrl.dispose();
    _altTextCtrl.dispose();
    _transcriptCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    const typeGroup = XTypeGroup(
      label: 'Lesson Media',
      extensions: [
        'png',
        'jpg',
        'jpeg',
        'webp',
        'svg',
        'mp3',
        'm4a',
        'ogg',
        'wav',
        'mp4',
        'webm',
        'pdf',
      ],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (bytes.length > 26214400) {
      setState(() => _error = 'File exceeds maximum allowed size of 25 MB.');
      return;
    }
    setState(() {
      _selectedFileBytes = bytes;
      _selectedFileName = file.name;
      _error = null;
      if (_titleCtrl.text.trim().isEmpty) {
        _titleCtrl.text = file.name.replaceAll(RegExp(r'\.[^.]+$'), '');
      }
    });
  }

  Future<void> _upload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFileBytes == null || _selectedFileName == null) {
      setState(() => _error = 'Please choose a file to upload.');
      return;
    }
    setState(() {
      _isUploading = true;
      _error = null;
    });
    try {
      final repo = ref.read(lessonAuthoringRepositoryProvider);
      final asset = await repo.uploadAndRegisterMediaAsset(
        title: _titleCtrl.text.trim(),
        countryCode: widget.countryCode,
        mediaType: _mediaType,
        subjectId: widget.subjectId,
        description: _descCtrl.text.trim(),
        sourceReference: _sourceCtrl.text.trim(),
        licenseType: _licenseType,
        attribution: _attributionCtrl.text.trim(),
        altText: _altTextCtrl.text.trim(),
        transcript: _transcriptCtrl.text.trim(),
        fileBytes: _selectedFileBytes,
        fileName: _selectedFileName,
      );
      ref.invalidate(contentMediaAssetsProvider);
      if (mounted) Navigator.of(context).pop(asset);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final assetsAsync = ref.watch(contentMediaAssetsProvider);

    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.perm_media_outlined, color: Color(0xFF0F4C81)),
          const SizedBox(width: 8),
          const Expanded(child: Text('Media Library')),
          TextButton.icon(
            onPressed: () => setState(() => _showUploadForm = !_showUploadForm),
            icon: Icon(_showUploadForm ? Icons.list : Icons.upload_file),
            label: Text(_showUploadForm ? 'Browse Library' : 'Upload New'),
          ),
        ],
      ),
      content: SizedBox(
        width: 600,
        height: 460,
        child: _showUploadForm
            ? Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF3C7),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF59E0B)),
                        ),
                        child: Text(
                          'All uploaded media starts as Pending Copyright & Academic Review. Do not upload unlicensed third-party content.',
                          style: LearnTzTypography.caption.copyWith(
                            color: const Color(0xFF92400E),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_error != null) ...[
                        Text(_error!,
                            style: const TextStyle(color: LearnTzColors.error)),
                        const SizedBox(height: 8),
                      ],
                      OutlinedButton.icon(
                        onPressed: _isUploading ? null : _pickFile,
                        icon: const Icon(Icons.attach_file),
                        label: Text(_selectedFileName ??
                            'Choose File (max 25 MB, mobile-optimized)'),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Asset Title *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _mediaType,
                              decoration: const InputDecoration(
                                labelText: 'Media Type',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'image', child: Text('Image')),
                                DropdownMenuItem(
                                    value: 'audio', child: Text('Audio')),
                                DropdownMenuItem(
                                    value: 'video', child: Text('Video')),
                                DropdownMenuItem(
                                    value: 'diagram', child: Text('Diagram')),
                                DropdownMenuItem(
                                    value: 'illustration',
                                    child: Text('Illustration')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _mediaType = v);
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _licenseType,
                              decoration: const InputDecoration(
                                labelText: 'Copyright / License',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              items: const [
                                DropdownMenuItem(
                                    value: 'unverified',
                                    child: Text('Unverified (Pending Review)')),
                                DropdownMenuItem(
                                    value: 'original_learntz',
                                    child: Text('Original LearnTZ Work')),
                                DropdownMenuItem(
                                    value: 'creative_commons',
                                    child: Text('Creative Commons')),
                                DropdownMenuItem(
                                    value: 'public_domain',
                                    child: Text('Public Domain')),
                                DropdownMenuItem(
                                    value: 'licensed_third_party',
                                    child: Text('Licensed Third Party')),
                              ],
                              onChanged: (v) {
                                if (v != null) setState(() => _licenseType = v);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _sourceCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Source Reference',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _attributionCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Attribution / Creator',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _altTextCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Accessibility Description (Alt Text) *',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _transcriptCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Transcript (for Audio / Video)',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            : assetsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading media: $e')),
                data: (assets) {
                  if (assets.isEmpty) {
                    return const Center(
                      child: Text(
                        'No media assets found yet. Click "Upload New" to add one.',
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: assets.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final asset = assets[index];
                      return ListTile(
                        leading: const Icon(Icons.perm_media_outlined,
                            color: Color(0xFF0F4C81)),
                        title: Text(asset.title),
                        subtitle: Text(
                          '${asset.mediaType.toUpperCase()} • ${asset.countryCode} • ${asset.altText ?? asset.fileUrl}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.add_circle_outline,
                            color: Color(0xFF15803D)),
                        onTap: () => Navigator.of(context).pop(asset),
                      );
                    },
                  );
                },
              ),
      ),
      actions: [
        TextButton(
          onPressed: _isUploading ? null : () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
        if (_showUploadForm)
          AppButton(
            label: 'Upload to Storage',
            variant: AppButtonVariant.primary,
            size: AppButtonSize.sm,
            isLoading: _isUploading,
            onPressed: _isUploading ? null : _upload,
          ),
      ],
    );
  }
}
