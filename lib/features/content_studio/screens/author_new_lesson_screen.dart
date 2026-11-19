import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/design_system/components/components.dart';
import '../../../core/design_system/tokens/design_tokens.dart';
import '../content_studio_models.dart';
import '../content_studio_providers.dart';
import '../lesson_authoring_models.dart';
import '../lesson_authoring_providers.dart';
import '../widgets/lesson_authoring_dialogs.dart';
import '../widgets/lesson_preview_pane.dart';
import '../widgets/searchable_curriculum_dropdown.dart';

/// Production-ready Curriculum-Driven Lesson Authoring Workflow:
/// Step 1: Inherited Curriculum Context + Four Cascading Dropdowns
///   (Grade/Class -> Subject -> Main Competence -> Specific Competence)
/// Step 2: Lesson Studio (A. Lesson Info, B. Outcomes, C. Content Builder,
///   D. Teaching Activities, E. Assessment Builder, F. Preview & Review Workflow)
class AuthorNewLessonScreen extends ConsumerStatefulWidget {
  const AuthorNewLessonScreen({
    super.key,
    this.launchContext,
  });

  final AuthorLessonLaunchContext? launchContext;

  @override
  ConsumerState<AuthorNewLessonScreen> createState() =>
      _AuthorNewLessonScreenState();
}

class _AuthorNewLessonScreenState extends ConsumerState<AuthorNewLessonScreen>
    with SingleTickerProviderStateMixin {
  // Phase toggle: 0 = Curriculum Selection (4 cascading dropdowns), 1 = Lesson Studio
  int _phase = 0;

  // Inherited & active curriculum context
  bool _isLoadingContext = true;
  String? _contextError;
  LessonAuthoringContext? _authoringContext;

  // Four cascading dropdown selections (actual DB IDs only)
  String? _selectedCurriculumId;
  String? _selectedLevelId;
  String? _selectedGradeId;
  String? _selectedSubjectId;
  String? _selectedMainCompetenceId;
  String? _selectedSpecificCompetenceId;
  String? _selectedSubtopicId;

  // Resolved option objects for breadcrumb & inherited metadata display
  AuthoringGradeOption? _selectedGradeObj;
  AuthoringSubjectOption? _selectedSubjectObj;
  AuthoringMainCompetenceOption? _selectedMainCompObj;
  AuthoringSpecificCompetenceOption? _selectedSpecCompObj;

  // Lesson Studio state
  String? _lessonId;
  String _workflowStatus = 'draft';
  bool _isPublished = false;
  int _versionNumber = 1;
  bool _isSaving = false;
  String? _bannerMessage;
  bool _bannerIsError = false;
  Map<String, dynamic>? _recoverableDraft;

  late final TextEditingController _titleCtrl;
  late final TextEditingController _shortDescCtrl;
  late final TextEditingController _assessmentCriteriaCtrl;
  late final TextEditingController _objectiveInputCtrl;
  late final TextEditingController _outcomeInputCtrl;
  late final TextEditingController _outcomeEvidenceCtrl;
  late final TextEditingController _reviewCommentCtrl;
  late final TextEditingController _changeSummaryCtrl;

  int _estimatedMinutes = 25;
  String _languageCode = 'en';
  String _difficultyLevel = 'standard';
  String _lessonType = 'core_instruction';
  bool _isFreePreview = false;
  String _outcomeCognitiveLevel = 'application';

  final List<String> _learningObjectives = [];
  final List<LessonLearningOutcome> _learningOutcomes = [];
  final List<LessonContentBlock> _contentBlocks = [];
  final List<LessonTeachingActivity> _teachingActivities = [];
  final List<LessonAssessmentQuestion> _questions = [];
  final List<LessonRevisionRecord> _revisions = [];
  final List<LessonReviewAuditEvent> _reviewEvents = [];

  late TabController _studioTabController;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController();
    _shortDescCtrl = TextEditingController();
    _assessmentCriteriaCtrl = TextEditingController();
    _objectiveInputCtrl = TextEditingController();
    _outcomeInputCtrl = TextEditingController();
    _outcomeEvidenceCtrl = TextEditingController();
    _reviewCommentCtrl = TextEditingController();
    _changeSummaryCtrl = TextEditingController();
    _studioTabController = TabController(length: 7, vsync: this);

    final launch = widget.launchContext;
    if (launch != null) {
      _lessonId = launch.lessonId;
      _selectedCurriculumId = launch.curriculumId;
      _selectedLevelId = launch.educationLevelId;
      _selectedGradeId = launch.gradeId;
      _selectedSubjectId = launch.subjectId;
      _selectedMainCompetenceId = launch.mainCompetenceId;
      _selectedSpecificCompetenceId = launch.specificCompetenceId;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialContext());
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _shortDescCtrl.dispose();
    _assessmentCriteriaCtrl.dispose();
    _objectiveInputCtrl.dispose();
    _outcomeInputCtrl.dispose();
    _outcomeEvidenceCtrl.dispose();
    _reviewCommentCtrl.dispose();
    _changeSummaryCtrl.dispose();
    _studioTabController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialContext() async {
    setState(() {
      _isLoadingContext = true;
      _contextError = null;
    });
    try {
      final repo = ref.read(lessonAuthoringRepositoryProvider);
      final launch = widget.launchContext;
      final ctx = await repo.getAuthoringContext(
        countryCode: launch?.countryCode,
        curriculumId: _selectedCurriculumId,
        educationLevelId: _selectedLevelId,
        gradeId: _selectedGradeId,
        subjectId: _selectedSubjectId,
      );

      if (!mounted) return;
      setState(() {
        _authoringContext = ctx;
        _selectedCurriculumId = ctx.curriculumId;
        _selectedLevelId = ctx.educationLevelId;
        _selectedGradeId ??= ctx.gradeId;
        _selectedSubjectId ??= ctx.subjectId;
        _isLoadingContext = false;
      });

      if (_lessonId != null && _lessonId!.isNotEmpty) {
        await _loadExistingLessonBundle(_lessonId!);
      } else {
        await _checkLocalRecoveryDraft();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _contextError = e.toString();
        _isLoadingContext = false;
      });
    }
  }

  Future<void> _loadExistingLessonBundle(String lessonId) async {
    try {
      final repo = ref.read(lessonAuthoringRepositoryProvider);
      final bundle = await repo.getLessonBundle(lessonId);
      final lesson = Map<String, dynamic>.from(bundle['lesson'] as Map);
      final rawQuestions = (bundle['questions'] as List<dynamic>? ?? const []);
      final rawRevisions = (bundle['revisions'] as List<dynamic>? ?? const []);
      final rawEvents = (bundle['review_events'] as List<dynamic>? ?? const []);

      if (!mounted) return;
      setState(() {
        _lessonId = lesson['id'] as String?;
        _selectedCurriculumId = lesson['curriculum_id'] as String? ?? _selectedCurriculumId;
        _selectedLevelId = lesson['education_level_id'] as String? ?? _selectedLevelId;
        _selectedGradeId = lesson['grade_id'] as String? ?? _selectedGradeId;
        _selectedSubjectId = lesson['subject_id'] as String? ?? _selectedSubjectId;
        _selectedMainCompetenceId = lesson['main_competence_id'] as String?;
        _selectedSpecificCompetenceId = lesson['specific_competence_id'] as String?;
        _selectedSubtopicId = lesson['subtopic_id'] as String?;

        _titleCtrl.text = lesson['title'] as String? ?? '';
        _shortDescCtrl.text = lesson['summary'] as String? ?? '';
        _assessmentCriteriaCtrl.text = lesson['assessment_criteria'] as String? ?? '';
        _estimatedMinutes = (lesson['estimated_minutes'] as num?)?.toInt() ?? 25;
        _languageCode = lesson['language_code'] as String? ?? 'en';
        _difficultyLevel = lesson['difficulty_level'] as String? ?? 'standard';
        _lessonType = lesson['lesson_type'] as String? ?? 'core_instruction';
        _isFreePreview = lesson['is_free_preview'] as bool? ?? false;
        _workflowStatus = lesson['status'] as String? ?? 'draft';
        _isPublished = lesson['is_published'] as bool? ?? false;
        _versionNumber = (lesson['version_number'] as num?)?.toInt() ?? 1;

        _learningObjectives
          ..clear()
          ..addAll(
            (lesson['learning_objectives'] as List<dynamic>? ?? const [])
                .map((e) => e.toString()),
          );
        _learningOutcomes
          ..clear()
          ..addAll(
            (lesson['learning_outcomes'] as List<dynamic>? ?? const []).map(
              (e) => LessonLearningOutcome.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            ),
          );
        _contentBlocks
          ..clear()
          ..addAll(
            (lesson['content_blocks'] as List<dynamic>? ?? const []).map(
              (e) => LessonContentBlock.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            ),
          );
        _teachingActivities
          ..clear()
          ..addAll(
            (lesson['teaching_activities'] as List<dynamic>? ?? const []).map(
              (e) => LessonTeachingActivity.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            ),
          );
        _questions
          ..clear()
          ..addAll(
            rawQuestions.map(
              (e) => LessonAssessmentQuestion.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            ),
          );
        _revisions
          ..clear()
          ..addAll(
            rawRevisions.map(
              (e) => LessonRevisionRecord.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            ),
          );
        _reviewEvents
          ..clear()
          ..addAll(
            rawEvents.map(
              (e) => LessonReviewAuditEvent.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            ),
          );

        if (_selectedSpecificCompetenceId != null) {
          _phase = 1;
        }
      });

      // Hydrate real curriculum display objects so Review Queue launches show full
      // Country -> Curriculum -> Grade -> Subject -> Competence metadata immediately.
      final curId = _selectedCurriculumId;
      final lvlId = _selectedLevelId;
      final grdId = _selectedGradeId;
      final subjId = _selectedSubjectId;
      final mainId = _selectedMainCompetenceId;
      final specId = _selectedSpecificCompetenceId;
      final lessonCountry = lesson['country_code'] as String?;

      if (curId != null && curId.isNotEmpty) {
        if (lessonCountry != null &&
            lessonCountry.isNotEmpty &&
            _authoringContext?.countryCode != lessonCountry) {
          final updatedCtx = await repo.getAuthoringContext(
            countryCode: lessonCountry,
            curriculumId: curId,
            educationLevelId: lvlId,
            gradeId: grdId,
            subjectId: subjId,
          );
          if (mounted) {
            setState(() => _authoringContext = updatedCtx);
          }
        }
        AuthoringGradeOption? hydratedGrade;
        AuthoringSubjectOption? hydratedSubject;
        AuthoringMainCompetenceOption? hydratedMain;
        AuthoringSpecificCompetenceOption? hydratedSpec;

        if (grdId != null && grdId.isNotEmpty) {
          final grades = await repo.getGrades(
            curriculumId: curId,
            educationLevelId: lvlId,
          );
          hydratedGrade = grades.where((g) => g.id == grdId).firstOrNull;
        }
        if (grdId != null &&
            grdId.isNotEmpty &&
            subjId != null &&
            subjId.isNotEmpty) {
          final subjects = await repo.getSubjects(
            curriculumId: curId,
            gradeId: grdId,
            educationLevelId: lvlId,
          );
          hydratedSubject = subjects.where((s) => s.id == subjId).firstOrNull;
        }
        if (subjId != null &&
            subjId.isNotEmpty &&
            mainId != null &&
            mainId.isNotEmpty) {
          final mains = await repo.getMainCompetences(subjectId: subjId);
          hydratedMain = mains.where((m) => m.id == mainId).firstOrNull;
        }
        if (mainId != null &&
            mainId.isNotEmpty &&
            specId != null &&
            specId.isNotEmpty) {
          final specs =
              await repo.getSpecificCompetences(mainCompetenceId: mainId);
          hydratedSpec = specs.where((s) => s.id == specId).firstOrNull;
        }

        if (mounted) {
          setState(() {
            _selectedGradeObj ??= hydratedGrade;
            _selectedSubjectObj ??= hydratedSubject;
            _selectedMainCompObj ??= hydratedMain;
            _selectedSpecCompObj ??= hydratedSpec;
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bannerMessage = 'Could not load lesson bundle: $e';
        _bannerIsError = true;
      });
    }
  }

  String get _draftStorageKey =>
      _lessonId ??
      '${_selectedGradeId ?? 'g'}_${_selectedSubjectId ?? 's'}_${_selectedSpecificCompetenceId ?? 'sc'}';

  Future<void> _checkLocalRecoveryDraft() async {
    final repo = ref.read(lessonAuthoringRepositoryProvider);
    final saved = await repo.loadLocalRecoveryDraft(_draftStorageKey);
    if (saved != null && mounted && _titleCtrl.text.isEmpty) {
      setState(() => _recoverableDraft = saved);
    }
  }

  Future<void> _autoBackupLocalDraft() async {
    if (_phase != 1) return;
    final repo = ref.read(lessonAuthoringRepositoryProvider);
    await repo.saveLocalRecoveryDraft(_draftStorageKey, {
      'title': _titleCtrl.text,
      'summary': _shortDescCtrl.text,
      'estimated_minutes': _estimatedMinutes,
      'language_code': _languageCode,
      'difficulty_level': _difficultyLevel,
      'lesson_type': _lessonType,
      'learning_objectives': _learningObjectives,
      'learning_outcomes': _learningOutcomes.map((o) => o.toJson()).toList(),
      'content_blocks': _contentBlocks.map((b) => b.toJson()).toList(),
      'teaching_activities':
          _teachingActivities.map((a) => a.toJson()).toList(),
      'assessment_criteria': _assessmentCriteriaCtrl.text,
    });
  }

  void _applyRecoveredDraft() {
    final data = _recoverableDraft;
    if (data == null) return;
    setState(() {
      _titleCtrl.text = data['title'] as String? ?? '';
      _shortDescCtrl.text = data['summary'] as String? ?? '';
      _estimatedMinutes = (data['estimated_minutes'] as num?)?.toInt() ?? 25;
      _languageCode = data['language_code'] as String? ?? 'en';
      _difficultyLevel = data['difficulty_level'] as String? ?? 'standard';
      _lessonType = data['lesson_type'] as String? ?? 'core_instruction';
      _assessmentCriteriaCtrl.text = data['assessment_criteria'] as String? ?? '';
      _learningObjectives
        ..clear()
        ..addAll(
          (data['learning_objectives'] as List<dynamic>? ?? const [])
              .map((e) => e.toString()),
        );
      _learningOutcomes
        ..clear()
        ..addAll(
          (data['learning_outcomes'] as List<dynamic>? ?? const []).map(
            (e) => LessonLearningOutcome.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          ),
        );
      _contentBlocks
        ..clear()
        ..addAll(
          (data['content_blocks'] as List<dynamic>? ?? const []).map(
            (e) => LessonContentBlock.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          ),
        );
      _teachingActivities
        ..clear()
        ..addAll(
          (data['teaching_activities'] as List<dynamic>? ?? const []).map(
            (e) => LessonTeachingActivity.fromJson(
              Map<String, dynamic>.from(e as Map),
            ),
          ),
        );
      _recoverableDraft = null;
      _bannerMessage = 'Recovered unsaved local draft.';
      _bannerIsError = false;
    });
  }

  // Strict cascading selection handlers (Section 3)
  void _onGradeChanged(String? gradeId, List<AuthoringGradeOption> grades) {
    final match = grades.where((g) => g.id == gradeId).firstOrNull;
    setState(() {
      _selectedGradeId = gradeId;
      _selectedGradeObj = match;
      if (match != null) {
        _selectedLevelId = match.educationLevelId;
      }
      // Clear ALL dependent selections
      _selectedSubjectId = null;
      _selectedSubjectObj = null;
      _selectedMainCompetenceId = null;
      _selectedMainCompObj = null;
      _selectedSpecificCompetenceId = null;
      _selectedSpecCompObj = null;
      _selectedSubtopicId = null;
    });
  }

  void _onSubjectChanged(
    String? subjectId,
    List<AuthoringSubjectOption> subjects,
  ) {
    final match = subjects.where((s) => s.id == subjectId).firstOrNull;
    setState(() {
      _selectedSubjectId = subjectId;
      _selectedSubjectObj = match;
      if (match != null && match.language.isNotEmpty) {
        _languageCode = match.language;
      }
      // Clear ALL dependent selections
      _selectedMainCompetenceId = null;
      _selectedMainCompObj = null;
      _selectedSpecificCompetenceId = null;
      _selectedSpecCompObj = null;
      _selectedSubtopicId = null;
    });
  }

  void _onMainCompetenceChanged(
    String? mainId,
    List<AuthoringMainCompetenceOption> mains,
  ) {
    final match = mains.where((m) => m.id == mainId).firstOrNull;
    setState(() {
      _selectedMainCompetenceId = mainId;
      _selectedMainCompObj = match;
      // Clear dependent selection
      _selectedSpecificCompetenceId = null;
      _selectedSpecCompObj = null;
      _selectedSubtopicId = null;
    });
  }

  void _onSpecificCompetenceChanged(
    String? specId,
    List<AuthoringSpecificCompetenceOption> specs,
  ) {
    final match = specs.where((s) => s.id == specId).firstOrNull;
    setState(() {
      _selectedSpecificCompetenceId = specId;
      _selectedSpecCompObj = match;
      _selectedSubtopicId = null;
      if (match?.assessmentCriteria != null &&
          _assessmentCriteriaCtrl.text.trim().isEmpty) {
        _assessmentCriteriaCtrl.text = match!.assessmentCriteria!;
      }
    });
  }

  bool get _allFourSelectionsComplete =>
      _selectedGradeId != null &&
      _selectedSubjectId != null &&
      _selectedMainCompetenceId != null &&
      _selectedSpecificCompetenceId != null;

  String get _breadcrumbText {
    final ctx = _authoringContext;
    final parts = <String>[
      ctx?.countryName ?? widget.launchContext?.countryName ?? 'Tanzania',
      if ((ctx?.curriculumName ?? widget.launchContext?.curriculumName) != null)
        '${ctx?.curriculumName ?? widget.launchContext!.curriculumName}'
            '${ctx?.curriculumVersionCode != null ? ' (${ctx!.curriculumVersionCode})' : ''}',
      if ((ctx?.educationLevelName ??
              _selectedGradeObj?.educationLevelName ??
              widget.launchContext?.educationLevelName) !=
          null)
        ctx?.educationLevelName ??
            _selectedGradeObj?.educationLevelName ??
            widget.launchContext!.educationLevelName!,
      if ((_selectedGradeObj?.name ??
              ctx?.gradeName ??
              widget.launchContext?.gradeName) !=
          null)
        _selectedGradeObj?.name ??
            ctx?.gradeName ??
            widget.launchContext!.gradeName!,
      if ((_selectedSubjectObj?.name ??
              ctx?.subjectName ??
              widget.launchContext?.subjectName) !=
          null)
        _selectedSubjectObj?.name ??
            ctx?.subjectName ??
            widget.launchContext!.subjectName!,
    ];
    return parts.join(' → ');
  }

  String _compileMarkdownFromBlocks() {
    final buf = StringBuffer();
    if (_titleCtrl.text.trim().isNotEmpty) {
      buf.writeln('# ${_titleCtrl.text.trim()}');
      buf.writeln();
    }
    if (_shortDescCtrl.text.trim().isNotEmpty) {
      buf.writeln(_shortDescCtrl.text.trim());
      buf.writeln();
    }
    for (final block in _contentBlocks) {
      if (block.type == LessonContentBlockType.heading) {
        buf.writeln('## ${block.title}');
      } else {
        buf.writeln('### ${block.title} (${block.type.label})');
      }
      if (block.content.isNotEmpty) {
        buf.writeln(block.content);
      }
      if (block.mediaUrl != null && block.mediaUrl!.isNotEmpty) {
        buf.writeln('![${block.altText ?? block.title}](${block.mediaUrl})');
      }
      buf.writeln();
    }
    return buf.toString().trim();
  }

  Future<bool> _saveDraft() async {
    final ctx = _authoringContext;
    if (ctx == null || !_allFourSelectionsComplete) {
      setState(() {
        _bannerMessage =
            'Complete all four curriculum selections before saving.';
        _bannerIsError = true;
      });
      return false;
    }

    if (_titleCtrl.text.trim().isEmpty) {
      setState(() {
        _bannerMessage = 'Lesson title is required before saving.';
        _bannerIsError = true;
      });
      return false;
    }

    final topicId = _selectedSpecCompObj?.topicId ?? widget.launchContext?.topicId;
    if (topicId == null || topicId.isEmpty) {
      setState(() {
        _bannerMessage =
            'Selected Specific Competence is not linked to a database topic record.';
        _bannerIsError = true;
      });
      return false;
    }

    setState(() {
      _isSaving = true;
      _bannerMessage = null;
      _bannerIsError = false;
    });

    try {
      final repo = ref.read(lessonAuthoringRepositoryProvider);
      final result = await repo.saveDraft(
        countryCode: ctx.countryCode,
        curriculumId: _selectedCurriculumId!,
        curriculumVersionId: ctx.curriculumVersionId,
        educationLevelId: _selectedLevelId ?? ctx.educationLevelId!,
        gradeId: _selectedGradeId!,
        subjectId: _selectedSubjectId!,
        mainCompetenceId: _selectedMainCompetenceId!,
        specificCompetenceId: _selectedSpecificCompetenceId!,
        topicId: topicId,
        subtopicId: _selectedSubtopicId,
        title: _titleCtrl.text.trim(),
        summary: _shortDescCtrl.text.trim(),
        bodyMarkdown: _compileMarkdownFromBlocks(),
        estimatedMinutes: _estimatedMinutes,
        languageCode: _languageCode,
        difficultyLevel: _difficultyLevel,
        lessonType: _lessonType,
        isFreePreview: _isFreePreview,
        learningObjectives: _learningObjectives,
        learningOutcomes: _learningOutcomes,
        contentBlocks: _contentBlocks,
        teachingActivities: _teachingActivities,
        assessmentCriteria: _assessmentCriteriaCtrl.text.trim(),
        changeSummary: _changeSummaryCtrl.text.trim().isEmpty
            ? 'Saved lesson draft in Lesson Studio'
            : _changeSummaryCtrl.text.trim(),
        lessonId: _lessonId,
      );

      final savedId = result['id'] as String?;
      if (savedId != null) {
        _lessonId = savedId;
        // Persist any locally staged assessment questions to question_bank
        for (var i = 0; i < _questions.length; i++) {
          final q = _questions[i];
          if (q.id == null) {
            final qRes = await repo.upsertQuestion(
              lessonId: savedId,
              question: q,
            );
            _questions[i] = LessonAssessmentQuestion(
              id: qRes['id'] as String?,
              questionType: q.questionType,
              questionText: q.questionText,
              correctAnswer: q.correctAnswer,
              options: q.options,
              explanation: q.explanation,
              marks: q.marks,
              difficultyLevel: q.difficultyLevel,
              learningOutcomeRef: q.learningOutcomeRef,
              assessmentCriteria: q.assessmentCriteria,
              cognitiveTier: q.cognitiveTier,
            );
          }
        }
      }

      await repo.clearLocalRecoveryDraft(_draftStorageKey);
      ref.invalidate(contentStudioMetricsProvider);
      ref.invalidate(contentStudioCatalogProvider);

      if (_lessonId != null) {
        await _loadExistingLessonBundle(_lessonId!);
      }

      if (!mounted) return true;
      setState(() {
        _workflowStatus = result['status'] as String? ?? 'draft';
        _isPublished = result['is_published'] as bool? ?? false;
        _versionNumber = (result['version_number'] as num?)?.toInt() ?? _versionNumber;
        _changeSummaryCtrl.clear();
        _bannerMessage =
            'Draft saved (v$_versionNumber). Lesson remains unpublished until approved and published.';
        _bannerIsError = false;
      });
      return true;
    } catch (e) {
      if (!mounted) return false;
      setState(() {
        _bannerMessage = 'Save failed: $e';
        _bannerIsError = true;
      });
      return false;
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _transitionWorkflow(String action) async {
    if (action == 'submit_for_review') {
      // Save latest changes first before submitting
      if (_workflowStatus == 'draft' || _workflowStatus == 'revision_requested') {
        final saved = await _saveDraft();
        if (!saved) return;
      }
    }

    if (_lessonId == null) {
      setState(() {
        _bannerMessage = 'Please save the draft before running workflow actions.';
        _bannerIsError = true;
      });
      return;
    }

    if (action == 'request_revision' && _reviewCommentCtrl.text.trim().isEmpty) {
      setState(() {
        _bannerMessage =
            'Please enter revision feedback comments before requesting revisions.';
        _bannerIsError = true;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _bannerMessage = null;
      _bannerIsError = false;
    });

    try {
      final repo = ref.read(lessonAuthoringRepositoryProvider);
      final result = await repo.transitionWorkflow(
        lessonId: _lessonId!,
        action: action,
        comments: _reviewCommentCtrl.text.trim().isEmpty
            ? null
            : _reviewCommentCtrl.text.trim(),
      );

      ref.invalidate(contentStudioMetricsProvider);
      ref.invalidate(contentStudioCatalogProvider);
      await _loadExistingLessonBundle(_lessonId!);

      if (!mounted) return;
      setState(() {
        _workflowStatus = result['status'] as String? ?? _workflowStatus;
        _isPublished = result['is_published'] as bool? ?? false;
        _reviewCommentCtrl.clear();
        _bannerMessage =
            'Workflow updated to ${_statusLabel(_workflowStatus)}.';
        _bannerIsError = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bannerMessage = 'Workflow action failed: $e';
        _bannerIsError = true;
      });
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _statusLabel(String status) {
    return switch (status) {
      'draft' => 'DRAFT',
      'in_review' => 'SUBMITTED FOR REVIEW',
      'revision_requested' => 'REVISION REQUESTED',
      'approved' => 'APPROVED',
      'published' => 'PUBLISHED',
      'archived' => 'ARCHIVED',
      _ => status.toUpperCase(),
    };
  }

  AppBadgeVariant _statusVariant(String status) {
    return switch (status) {
      'published' => AppBadgeVariant.success,
      'approved' => AppBadgeVariant.primary,
      'in_review' || 'revision_requested' => AppBadgeVariant.warning,
      _ => AppBadgeVariant.neutral,
    };
  }

  Future<MediaAssetItem?> _openMediaLibraryPicker() async {
    return showDialog<MediaAssetItem>(
      context: context,
      builder: (_) => LessonMediaLibraryPickerDialog(
        countryCode: _authoringContext?.countryCode ?? 'TZ',
        subjectId: _selectedSubjectId,
      ),
    );
  }

  Future<void> _addOrEditBlock([int? editIndex]) async {
    final existing = editIndex != null ? _contentBlocks[editIndex] : null;
    final result = await showDialog<LessonContentBlock>(
      context: context,
      builder: (_) => LessonContentBlockDialog(
        existing: existing,
        onPickMedia: _openMediaLibraryPicker,
      ),
    );
    if (result != null && mounted) {
      setState(() {
        if (editIndex != null) {
          _contentBlocks[editIndex] = result;
        } else {
          _contentBlocks.add(result);
        }
      });
      await _autoBackupLocalDraft();
    }
  }

  Future<void> _addOrEditActivity([int? editIndex]) async {
    final existing = editIndex != null ? _teachingActivities[editIndex] : null;
    final result = await showDialog<LessonTeachingActivity>(
      context: context,
      builder: (_) => TeachingActivityDialog(existing: existing),
    );
    if (result != null && mounted) {
      setState(() {
        if (editIndex != null) {
          _teachingActivities[editIndex] = result;
        } else {
          _teachingActivities.add(result);
        }
      });
      await _autoBackupLocalDraft();
    }
  }

  Future<void> _addOrEditQuestion([int? editIndex]) async {
    final existing = editIndex != null ? _questions[editIndex] : null;
    final result = await showDialog<LessonAssessmentQuestion>(
      context: context,
      builder: (_) => AssessmentQuestionDialog(
        learningOutcomes: _learningOutcomes,
        existing: existing,
      ),
    );
    if (result == null || !mounted) return;

    if (_lessonId != null) {
      try {
        final repo = ref.read(lessonAuthoringRepositoryProvider);
        final saved = await repo.upsertQuestion(
          lessonId: _lessonId!,
          question: result,
        );
        final persisted = LessonAssessmentQuestion(
          id: saved['id'] as String?,
          questionType: result.questionType,
          questionText: result.questionText,
          correctAnswer: result.correctAnswer,
          options: result.options,
          explanation: result.explanation,
          marks: result.marks,
          difficultyLevel: result.difficultyLevel,
          learningOutcomeRef: result.learningOutcomeRef,
          assessmentCriteria: result.assessmentCriteria,
          cognitiveTier: result.cognitiveTier,
        );
        setState(() {
          if (editIndex != null) {
            _questions[editIndex] = persisted;
          } else {
            _questions.add(persisted);
          }
        });
      } catch (e) {
        setState(() {
          _bannerMessage = 'Failed to save assessment question: $e';
          _bannerIsError = true;
        });
      }
    } else {
      setState(() {
        if (editIndex != null) {
          _questions[editIndex] = result;
        } else {
          _questions.add(result);
        }
      });
    }
  }

  Future<void> _deleteQuestion(int index) async {
    final q = _questions[index];
    if (q.id != null) {
      try {
        await ref
            .read(lessonAuthoringRepositoryProvider)
            .deleteQuestion(q.id!);
      } catch (e) {
        if (mounted) {
          setState(() {
            _bannerMessage = 'Failed to delete question: $e';
            _bannerIsError = true;
          });
        }
        return;
      }
    }
    if (mounted) {
      setState(() => _questions.removeAt(index));
    }
  }

  @override
  Widget build(BuildContext context) {
    final capabilities =
        _authoringContext?.capabilities ?? const LessonAuthoringCapabilities();
    final isNarrow = MediaQuery.sizeOf(context).width < 680;

    return Scaffold(
      backgroundColor: LearnTzColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_phase == 1 && _lessonId == null) {
              setState(() => _phase = 0);
            } else {
              context.pop();
            }
          },
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(
                _lessonId == null
                    ? 'Author New Lesson'
                    : 'Lesson Authoring Studio',
                style: LearnTzTypography.h3.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF0F4C81),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isNarrow) ...[
              const SizedBox(width: 10),
              AppBadge(
                label: _statusLabel(_workflowStatus),
                variant: _statusVariant(_workflowStatus),
                size: AppBadgeSize.sm,
              ),
              const SizedBox(width: 6),
              AppBadge(
                label: 'v$_versionNumber',
                variant: AppBadgeVariant.neutral,
                size: AppBadgeSize.sm,
              ),
            ],
          ],
        ),
        actions: [
          if (_phase == 1 && !isNarrow)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Wrap(
                spacing: 8,
                children: [
                  if (capabilities.canAuthor &&
                      (_workflowStatus == 'draft' ||
                          _workflowStatus == 'revision_requested'))
                    AppButton(
                      key: const Key('author-save-draft-btn'),
                      label: 'Save Draft',
                      variant: AppButtonVariant.outlined,
                      size: AppButtonSize.sm,
                      icon: Icons.save_outlined,
                      isLoading: _isSaving,
                      onPressed: _isSaving ? null : _saveDraft,
                    ),
                  if (capabilities.canAuthor &&
                      (_workflowStatus == 'draft' ||
                          _workflowStatus == 'revision_requested'))
                    AppButton(
                      key: const Key('author-submit-review-btn'),
                      label: 'Submit for Review',
                      variant: AppButtonVariant.primary,
                      size: AppButtonSize.sm,
                      icon: Icons.send_outlined,
                      isLoading: _isSaving,
                      onPressed: _isSaving
                          ? null
                          : () => _transitionWorkflow('submit_for_review'),
                    ),
                ],
              ),
            ),
        ],
      ),
      body: _isLoadingContext
          ? const Center(child: CircularProgressIndicator())
          : _contextError != null
              ? _buildContextErrorState()
              : Column(
                  children: [
                    // Inherited Curriculum Breadcrumb Strip
                    _buildBreadcrumbStrip(),
                    if (_phase == 1 && isNarrow)
                      Container(
                        width: double.infinity,
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            AppBadge(
                              label: _statusLabel(_workflowStatus),
                              variant: _statusVariant(_workflowStatus),
                              size: AppBadgeSize.sm,
                            ),
                            AppBadge(
                              label: 'v$_versionNumber',
                              variant: AppBadgeVariant.neutral,
                              size: AppBadgeSize.sm,
                            ),
                            if (capabilities.canAuthor &&
                                (_workflowStatus == 'draft' ||
                                    _workflowStatus == 'revision_requested'))
                              AppButton(
                                key: const Key('author-save-draft-btn'),
                                label: 'Save Draft',
                                variant: AppButtonVariant.outlined,
                                size: AppButtonSize.sm,
                                icon: Icons.save_outlined,
                                isLoading: _isSaving,
                                onPressed: _isSaving ? null : _saveDraft,
                              ),
                            if (capabilities.canAuthor &&
                                (_workflowStatus == 'draft' ||
                                    _workflowStatus == 'revision_requested'))
                              AppButton(
                                key: const Key('author-submit-review-btn'),
                                label: 'Submit',
                                variant: AppButtonVariant.primary,
                                size: AppButtonSize.sm,
                                icon: Icons.send_outlined,
                                isLoading: _isSaving,
                                onPressed: _isSaving
                                    ? null
                                    : () => _transitionWorkflow(
                                          'submit_for_review',
                                        ),
                              ),
                          ],
                        ),
                      ),
                    if (_bannerMessage != null) _buildFeedbackBanner(),
                    if (_recoverableDraft != null && _phase == 1)
                      _buildRecoveryBanner(),
                    Expanded(
                      child: _phase == 0
                          ? _buildCurriculumSelectionStep()
                          : _buildLessonStudioWorkspace(capabilities),
                    ),
                  ],
                ),
    );
  }

  Widget _buildContextErrorState() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: AppCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline,
                  size: 44, color: LearnTzColors.error),
              const SizedBox(height: 12),
              Text(
                'Unable to open Lesson Authoring Studio',
                style: LearnTzTypography.h3.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _contextError!,
                style: LearnTzTypography.bodySmall
                    .copyWith(color: LearnTzColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              AppButton(
                label: 'Try Again',
                variant: AppButtonVariant.primary,
                onPressed: _loadInitialContext,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBreadcrumbStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF0F4C81),
        border: Border(bottom: BorderSide(color: Color(0xFF1E3A8A))),
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1280),
          child: Row(
            children: [
              const Icon(Icons.account_tree_outlined,
                  size: 16, color: Colors.white70),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _breadcrumbText,
                  key: const Key('curriculum-context-breadcrumb'),
                  style: LearnTzTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (_phase == 1 && _lessonId == null)
                TextButton.icon(
                  onPressed: () => setState(() => _phase = 0),
                  icon: const Icon(Icons.swap_horiz,
                      size: 16, color: Colors.white),
                  label: const Text(
                    'Change Curriculum',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedbackBanner() {
    return Container(
      width: double.infinity,
      color: _bannerIsError ? LearnTzColors.errorBg : LearnTzColors.successBg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Icon(
            _bannerIsError ? Icons.error_outline : Icons.check_circle_outline,
            size: 18,
            color: _bannerIsError ? LearnTzColors.error : LearnTzColors.success,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _bannerMessage!,
              style: LearnTzTypography.bodySmall.copyWith(
                color:
                    _bannerIsError ? LearnTzColors.error : LearnTzColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => setState(() => _bannerMessage = null),
          ),
        ],
      ),
    );
  }

  Widget _buildRecoveryBanner() {
    return Container(
      width: double.infinity,
      color: const Color(0xFFFEF3C7),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          const Icon(Icons.restore, size: 18, color: Color(0xFF92400E)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Unsaved local lesson work was detected for this competence.',
              style: LearnTzTypography.bodySmall.copyWith(
                color: const Color(0xFF92400E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _applyRecoveredDraft,
            child: const Text('Recover Draft'),
          ),
          TextButton(
            onPressed: () => setState(() => _recoverableDraft = null),
            child: const Text('Dismiss'),
          ),
        ],
      ),
    );
  }

  /// STEP 1: Four Cascading Curriculum Dropdowns (Section 3)
  Widget _buildCurriculumSelectionStep() {
    final curriculumId = _selectedCurriculumId;

    final gradesAsync = curriculumId == null
        ? const AsyncValue<List<AuthoringGradeOption>>.data([])
        : ref.watch(authoringGradesProvider(
            (curriculumId: curriculumId, levelId: _selectedLevelId),
          ));

    final subjectsAsync = (curriculumId == null || _selectedGradeId == null)
        ? const AsyncValue<List<AuthoringSubjectOption>>.data([])
        : ref.watch(authoringSubjectsProvider((
            curriculumId: curriculumId,
            gradeId: _selectedGradeId!,
            levelId: _selectedLevelId,
          )));

    final mainCompsAsync = _selectedSubjectId == null
        ? const AsyncValue<List<AuthoringMainCompetenceOption>>.data([])
        : ref.watch(authoringMainCompetencesProvider(_selectedSubjectId!));

    final specCompsAsync = _selectedMainCompetenceId == null
        ? const AsyncValue<List<AuthoringSpecificCompetenceOption>>.data([])
        : ref.watch(
            authoringSpecificCompetencesProvider(_selectedMainCompetenceId!),
          );

    // Sync resolved metadata objects from fetched lists without mutating during build
    final grades = gradesAsync.asData?.value ?? const <AuthoringGradeOption>[];
    final subjects =
        subjectsAsync.asData?.value ?? const <AuthoringSubjectOption>[];
    final mainComps =
        mainCompsAsync.asData?.value ?? const <AuthoringMainCompetenceOption>[];
    final specComps = specCompsAsync.asData?.value ??
        const <AuthoringSpecificCompetenceOption>[];

    if (_selectedGradeId != null && _selectedGradeObj?.id != _selectedGradeId) {
      final found = grades.where((g) => g.id == _selectedGradeId).firstOrNull;
      if (found != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedGradeObj = found);
        });
      }
    }
    if (_selectedSubjectId != null &&
        _selectedSubjectObj?.id != _selectedSubjectId) {
      final found =
          subjects.where((s) => s.id == _selectedSubjectId).firstOrNull;
      if (found != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedSubjectObj = found);
        });
      }
    }
    if (_selectedMainCompetenceId != null &&
        _selectedMainCompObj?.id != _selectedMainCompetenceId) {
      final found = mainComps
          .where((m) => m.id == _selectedMainCompetenceId)
          .firstOrNull;
      if (found != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedMainCompObj = found);
        });
      }
    }
    if (_selectedSpecificCompetenceId != null &&
        _selectedSpecCompObj?.id != _selectedSpecificCompetenceId) {
      final found = specComps
          .where((s) => s.id == _selectedSpecificCompetenceId)
          .firstOrNull;
      if (found != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _selectedSpecCompObj = found);
        });
      }
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 880),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Indicator
              Wrap(
                spacing: 10,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _stepPill(1, 'Select Official Curriculum Alignment', true),
                  const Icon(Icons.chevron_right,
                      size: 18, color: LearnTzColors.neutral400),
                  _stepPill(2, 'Lesson Studio & Preview', false),
                ],
              ),
              const SizedBox(height: 20),

              AppCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Step 1: Curriculum Alignment Selection',
                      style: LearnTzTypography.h2.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF0F4C81),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Select the official Grade/Class, Subject, Main Competence, and Specific Competence from the verified curriculum database. Changing any parent selection automatically resets dependent fields.',
                      style: LearnTzTypography.bodySmall.copyWith(
                        color: LearnTzColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Dropdown 1: Grade/Class
                    SearchableCurriculumDropdown<String>(
                      fieldKey: const Key('author-grade-dropdown'),
                      stepNumber: 1,
                      label: 'Grade / Class',
                      hint: 'Select official grade or class...',
                      selectedValue: _selectedGradeId,
                      isLoading: gradesAsync.isLoading,
                      isDisabled: curriculumId == null,
                      disabledReason: 'No active curriculum selected',
                      errorMessage: gradesAsync.hasError
                          ? gradesAsync.error.toString()
                          : null,
                      onRetry: curriculumId == null
                          ? null
                          : () => ref.invalidate(authoringGradesProvider((
                                curriculumId: curriculumId,
                                levelId: _selectedLevelId,
                              ))),
                      emptyMessage:
                          'No grades configured for this curriculum and education level.',
                      options: grades
                          .map((g) => CurriculumDropdownOption<String>(
                                value: g.id,
                                label: g.name,
                                code: g.code,
                                subtitle: g.educationLevelName,
                                badgeText: '${g.subjectCount} subjects',
                                searchTerms: '${g.name} ${g.code}',
                              ))
                          .toList(),
                      onSelected: (val) => _onGradeChanged(val, grades),
                    ),
                    const SizedBox(height: 18),

                    // Dropdown 2: Subject
                    SearchableCurriculumDropdown<String>(
                      fieldKey: const Key('author-subject-dropdown'),
                      stepNumber: 2,
                      label: 'Subject',
                      hint: 'Select subject for this grade...',
                      selectedValue: _selectedSubjectId,
                      isLoading: subjectsAsync.isLoading,
                      isDisabled: _selectedGradeId == null,
                      disabledReason: 'Select Grade / Class first',
                      errorMessage: subjectsAsync.hasError
                          ? subjectsAsync.error.toString()
                          : null,
                      onRetry: (curriculumId == null || _selectedGradeId == null)
                          ? null
                          : () => ref.invalidate(authoringSubjectsProvider((
                                curriculumId: curriculumId,
                                gradeId: _selectedGradeId!,
                                levelId: _selectedLevelId,
                              ))),
                      emptyMessage:
                          'No published grade-scoped subjects available for this grade yet.',
                      options: subjects
                          .map((s) => CurriculumDropdownOption<String>(
                                value: s.id,
                                label: s.name,
                                code: s.code,
                                subtitle: s.officialName,
                                badgeText:
                                    '${s.mainCompetenceCount} competences',
                                searchTerms:
                                    '${s.name} ${s.officialName} ${s.code}',
                              ))
                          .toList(),
                      onSelected: (val) => _onSubjectChanged(val, subjects),
                    ),
                    const SizedBox(height: 18),

                    // Dropdown 3: Main Competence
                    SearchableCurriculumDropdown<String>(
                      fieldKey: const Key('author-main-competence-dropdown'),
                      stepNumber: 3,
                      label: 'Main Competence',
                      hint: 'Select official main competence...',
                      selectedValue: _selectedMainCompetenceId,
                      isLoading: mainCompsAsync.isLoading,
                      isDisabled: _selectedSubjectId == null,
                      disabledReason: 'Select Subject first',
                      errorMessage: mainCompsAsync.hasError
                          ? mainCompsAsync.error.toString()
                          : null,
                      onRetry: _selectedSubjectId == null
                          ? null
                          : () => ref.invalidate(
                                authoringMainCompetencesProvider(
                                    _selectedSubjectId!),
                              ),
                      emptyMessage:
                          'No official main competences have been ingested for this subject.',
                      options: mainComps
                          .map((m) => CurriculumDropdownOption<String>(
                                value: m.id,
                                label: m.title,
                                code: m.code,
                                badgeText:
                                    '${m.specificCompetenceCount} specific',
                                searchTerms: '${m.code} ${m.title}',
                              ))
                          .toList(),
                      onSelected: (val) =>
                          _onMainCompetenceChanged(val, mainComps),
                    ),
                    const SizedBox(height: 18),

                    // Dropdown 4: Specific Competence
                    SearchableCurriculumDropdown<String>(
                      fieldKey:
                          const Key('author-specific-competence-dropdown'),
                      stepNumber: 4,
                      label: 'Specific Competence',
                      hint: 'Select official specific competence...',
                      selectedValue: _selectedSpecificCompetenceId,
                      isLoading: specCompsAsync.isLoading,
                      isDisabled: _selectedMainCompetenceId == null,
                      disabledReason: 'Select Main Competence first',
                      errorMessage: specCompsAsync.hasError
                          ? specCompsAsync.error.toString()
                          : null,
                      onRetry: _selectedMainCompetenceId == null
                          ? null
                          : () => ref.invalidate(
                                authoringSpecificCompetencesProvider(
                                    _selectedMainCompetenceId!),
                              ),
                      emptyMessage:
                          'No specific competences found under this main competence.',
                      options: specComps
                          .map((sc) => CurriculumDropdownOption<String>(
                                value: sc.id,
                                label: sc.title,
                                code: sc.code,
                                subtitle: sc.assessmentCriteria ??
                                    (sc.periodAllocation != null
                                        ? '${sc.periodAllocation} periods'
                                        : null),
                                badgeText: sc.periodAllocation != null
                                    ? '${sc.periodAllocation} periods'
                                    : null,
                                searchTerms:
                                    '${sc.code} ${sc.title} ${sc.assessmentCriteria ?? ''}',
                              ))
                          .toList(),
                      onSelected: (val) =>
                          _onSpecificCompetenceChanged(val, specComps),
                    ),

                    // Official Curriculum Details Preview when Specific Competence selected
                    if (_selectedSpecCompObj != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF15803D).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                const Color(0xFF15803D).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.verified,
                                    size: 16, color: Color(0xFF15803D)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Verified Official Competence Reference',
                                    style: LearnTzTypography.bodySmall.copyWith(
                                      color: const Color(0xFF15803D),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Code ${_selectedSpecCompObj!.code}: ${_selectedSpecCompObj!.title}',
                              style: LearnTzTypography.bodySmall
                                  .copyWith(fontWeight: FontWeight.w600),
                            ),
                            if (_selectedSpecCompObj!.assessmentCriteria != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  'Assessment Criteria: ${_selectedSpecCompObj!.assessmentCriteria}',
                                  style: LearnTzTypography.caption.copyWith(
                                    color: LearnTzColors.textSecondary,
                                  ),
                                ),
                              ),
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Wrap(
                                spacing: 12,
                                children: [
                                  if (_selectedSpecCompObj!.periodAllocation !=
                                      null)
                                    Text(
                                      'Periods: ${_selectedSpecCompObj!.periodAllocation}',
                                      style: LearnTzTypography.caption,
                                    ),
                                  if (_selectedSpecCompObj!.sourcePage != null)
                                    Text(
                                      'Syllabus Page: p.${_selectedSpecCompObj!.sourcePage}',
                                      style: LearnTzTypography.caption,
                                    ),
                                  Text(
                                    'Subtopics available: ${_selectedSpecCompObj!.subtopics.length}',
                                    style: LearnTzTypography.caption,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    Align(
                      alignment: Alignment.centerRight,
                      child: AppButton(
                        key: const Key('proceed-to-lesson-studio-btn'),
                        label: 'Open Lesson Studio',
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.sm,
                        icon: Icons.arrow_forward,
                        onPressed: _allFourSelectionsComplete
                            ? () {
                                setState(() => _phase = 1);
                                _checkLocalRecoveryDraft();
                              }
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stepPill(int number, String label, bool active) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF0F4C81) : LearnTzColors.neutral300,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: LearnTzTypography.bodySmall.copyWith(
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active
                  ? const Color(0xFF0F4C81)
                  : LearnTzColors.textSecondary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  /// STEP 2: Full Lesson Studio Workspace (Sections A–G + Review & Version History)
  Widget _buildLessonStudioWorkspace(LessonAuthoringCapabilities capabilities) {
    return Column(
      children: [
        Container(
          color: Colors.white,
          child: TabBar(
            controller: _studioTabController,
            isScrollable: true,
            labelColor: const Color(0xFF0F4C81),
            unselectedLabelColor: LearnTzColors.textSecondary,
            indicatorColor: const Color(0xFF0F4C81),
            tabs: [
              const Tab(icon: Icon(Icons.info_outline, size: 18), text: 'A. Lesson Info'),
              Tab(
                icon: const Icon(Icons.verified_outlined, size: 18),
                text: 'B. Outcomes (${_learningOutcomes.length})',
              ),
              Tab(
                icon: const Icon(Icons.view_agenda_outlined, size: 18),
                text: 'C. Content (${_contentBlocks.length})',
              ),
              Tab(
                icon: const Icon(Icons.groups_outlined, size: 18),
                text: 'D. Activities (${_teachingActivities.length})',
              ),
              Tab(
                icon: const Icon(Icons.quiz_outlined, size: 18),
                text: 'E. Assessment (${_questions.length})',
              ),
              const Tab(
                icon: Icon(Icons.visibility_outlined, size: 18),
                text: 'Preview',
              ),
              Tab(
                icon: const Icon(Icons.gavel_outlined, size: 18),
                text: 'Review & History (v$_versionNumber)',
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: TabBarView(
            controller: _studioTabController,
            children: [
              _buildSectionALessonInfo(),
              _buildSectionBLearningOutcomes(),
              _buildSectionCContentBuilder(),
              _buildSectionDTeachingActivities(),
              _buildSectionEAssessmentBuilder(),
              _buildPreviewTab(),
              _buildReviewAndHistoryTab(capabilities),
            ],
          ),
        ),
      ],
    );
  }

  Widget _studioScrollContainer(Widget child) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: child,
        ),
      ),
    );
  }

  /// Section A: Lesson Information
  Widget _buildSectionALessonInfo() {
    final subtopics = _selectedSpecCompObj?.subtopics ?? const <AuthoringSubtopicOption>[];

    return _studioScrollContainer(
      AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'A. Lesson Information & Inherited Curriculum Alignment',
              style: LearnTzTypography.h3.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F4C81),
              ),
            ),
            const SizedBox(height: 12),

            // Inherited read-only curriculum metadata chips
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: LearnTzColors.neutral50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: LearnTzColors.neutral200),
              ),
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _metaChip('Grade', _selectedGradeObj?.name ?? _authoringContext?.gradeName ?? '—'),
                  _metaChip('Subject', _selectedSubjectObj?.name ?? _authoringContext?.subjectName ?? '—'),
                  _metaChip(
                    'Main Competence',
                    _selectedMainCompObj != null
                        ? '${_selectedMainCompObj!.code} ${_selectedMainCompObj!.title}'
                        : '—',
                  ),
                  _metaChip(
                    'Specific Competence',
                    _selectedSpecCompObj != null
                        ? '${_selectedSpecCompObj!.code} ${_selectedSpecCompObj!.title}'
                        : '—',
                  ),
                  _metaChip(
                    'Official Topic',
                    _selectedSpecCompObj?.topicTitle ??
                        _selectedSpecCompObj?.title ??
                        '—',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              key: const Key('studio-lesson-title-input'),
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Lesson Title *',
                hintText: 'e.g. Listening and Writing Dictated Familiar Words',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                setState(() {});
                _autoBackupLocalDraft();
              },
            ),
            const SizedBox(height: 12),

            TextField(
              key: const Key('studio-lesson-summary-input'),
              controller: _shortDescCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Short Description *',
                hintText: 'Concise overview of what this lesson covers...',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                setState(() {});
                _autoBackupLocalDraft();
              },
            ),
            const SizedBox(height: 12),

            // Subtopic selector (ONLY from existing real DB subtopics)
            if (subtopics.isNotEmpty) ...[
              DropdownButtonFormField<String?>(
                key: const Key('studio-subtopic-dropdown'),
                initialValue: subtopics.any((s) => s.id == _selectedSubtopicId)
                    ? _selectedSubtopicId
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Subtopic / Specific Learning Activity (Official Syllabus)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('None (applies to full specific competence)'),
                  ),
                  ...subtopics.map(
                    (st) => DropdownMenuItem<String?>(
                      value: st.id,
                      child: Text(st.title, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedSubtopicId = v),
              ),
              const SizedBox(height: 12),
            ],

            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= 640;
                final fields = [
                  DropdownButtonFormField<int>(
                    initialValue: _estimatedMinutes,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Estimated Duration',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [10, 15, 20, 25, 30, 35, 40, 45, 60]
                        .map((m) => DropdownMenuItem(
                            value: m, child: Text('$m minutes')))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _estimatedMinutes = v);
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _languageCode,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Language of Instruction',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(value: 'en', child: Text('English (en)')),
                      DropdownMenuItem(value: 'sw', child: Text('Kiswahili (sw)')),
                      DropdownMenuItem(value: 'fr', child: Text('Français (fr)')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _languageCode = v);
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _difficultyLevel,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Difficulty Level',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'foundational', child: Text('Foundational')),
                      DropdownMenuItem(
                          value: 'standard', child: Text('Standard')),
                      DropdownMenuItem(
                          value: 'intermediate', child: Text('Intermediate')),
                      DropdownMenuItem(
                          value: 'advanced', child: Text('Advanced')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _difficultyLevel = v);
                    },
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: _lessonType,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Lesson Type',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'core_instruction',
                          child: Text('Core Instruction')),
                      DropdownMenuItem(
                          value: 'guided_practice',
                          child: Text('Guided Practice')),
                      DropdownMenuItem(
                          value: 'practical', child: Text('Practical')),
                      DropdownMenuItem(
                          value: 'revision', child: Text('Revision')),
                      DropdownMenuItem(
                          value: 'assessment_prep',
                          child: Text('Assessment Preparation')),
                      DropdownMenuItem(
                          value: 'enrichment', child: Text('Enrichment')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _lessonType = v);
                    },
                  ),
                ];

                if (isWide) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: fields[0]),
                          const SizedBox(width: 12),
                          Expanded(child: fields[1]),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: fields[2]),
                          const SizedBox(width: 12),
                          Expanded(child: fields[3]),
                        ],
                      ),
                    ],
                  );
                }
                return Column(
                  children: [
                    for (final f in fields) ...[f, const SizedBox(height: 12)],
                  ],
                );
              },
            ),
            const SizedBox(height: 16),

            // Learning Objectives List
            Text(
              'Learning Objectives *',
              style: LearnTzTypography.bodyLarge
                  .copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('studio-objective-input'),
                    controller: _objectiveInputCtrl,
                    decoration: const InputDecoration(
                      hintText:
                          'Add a clear learning objective for this lesson...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: (_) => _addObjective(),
                  ),
                ),
                const SizedBox(width: 8),
                AppButton(
                  key: const Key('studio-add-objective-btn'),
                  label: 'Add',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.sm,
                  icon: Icons.add,
                  onPressed: _addObjective,
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_learningObjectives.isEmpty)
              Text(
                'Add at least one learning objective (required before submitting for review).',
                style: LearnTzTypography.caption
                    .copyWith(color: LearnTzColors.textSecondary),
              )
            else
              ..._learningObjectives.asMap().entries.map((entry) {
                return ListTile(
                  dense: true,
                  leading: const Icon(Icons.flag_outlined,
                      size: 18, color: Color(0xFF15803D)),
                  title: Text(entry.value),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, size: 18),
                    onPressed: () {
                      setState(() => _learningObjectives.removeAt(entry.key));
                      _autoBackupLocalDraft();
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  void _addObjective() {
    final text = _objectiveInputCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _learningObjectives.add(text);
      _objectiveInputCtrl.clear();
    });
    _autoBackupLocalDraft();
  }

  Widget _metaChip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: LearnTzColors.neutral200),
      ),
      child: RichText(
        text: TextSpan(
          style: LearnTzTypography.caption.copyWith(
            color: LearnTzColors.textPrimary,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF0F4C81),
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  /// Section B: Measurable Learning Outcomes
  Widget _buildSectionBLearningOutcomes() {
    return _studioScrollContainer(
      AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'B. Measurable Learning Outcomes',
              style: LearnTzTypography.h3.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F4C81),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Define assessable, grade-appropriate outcomes aligned to Specific Competence ${_selectedSpecCompObj?.code ?? ''}.',
              style: LearnTzTypography.bodySmall
                  .copyWith(color: LearnTzColors.textSecondary),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const Key('studio-outcome-input'),
              controller: _outcomeInputCtrl,
              decoration: const InputDecoration(
                labelText: 'Measurable Outcome *',
                hintText:
                    'e.g. Spell at least 8 out of 10 dictated familiar words accurately',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _outcomeCognitiveLevel,
                    decoration: const InputDecoration(
                      labelText: 'Cognitive Level',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: 'knowledge', child: Text('Knowledge')),
                      DropdownMenuItem(
                          value: 'comprehension', child: Text('Comprehension')),
                      DropdownMenuItem(
                          value: 'application', child: Text('Application')),
                      DropdownMenuItem(
                          value: 'analysis', child: Text('Analysis')),
                      DropdownMenuItem(
                          value: 'synthesis', child: Text('Synthesis')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _outcomeCognitiveLevel = v);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _outcomeEvidenceCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Assessment Evidence',
                      hintText: 'e.g. Written dictation checklist',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                AppButton(
                  key: const Key('studio-add-outcome-btn'),
                  label: 'Add Outcome',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.sm,
                  icon: Icons.add,
                  onPressed: () {
                    final text = _outcomeInputCtrl.text.trim();
                    if (text.isEmpty) return;
                    setState(() {
                      _learningOutcomes.add(
                        LessonLearningOutcome(
                          id: 'lo_${DateTime.now().microsecondsSinceEpoch}',
                          outcome: text,
                          cognitiveLevel: _outcomeCognitiveLevel,
                          assessable: true,
                          assessmentEvidence: _outcomeEvidenceCtrl.text.trim(),
                        ),
                      );
                      _outcomeInputCtrl.clear();
                      _outcomeEvidenceCtrl.clear();
                    });
                    _autoBackupLocalDraft();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_learningOutcomes.isEmpty)
              const AppCard(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No learning outcomes defined yet. At least one measurable outcome is required before review submission.',
                  ),
                ),
              )
            else
              ..._learningOutcomes.asMap().entries.map((entry) {
                final lo = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: const Icon(Icons.verified_outlined,
                        color: Color(0xFF15803D)),
                    title: Text(lo.outcome),
                    subtitle: Text(
                      'Level: ${lo.cognitiveLevel}'
                      '${lo.assessmentEvidence.isNotEmpty ? ' • Evidence: ${lo.assessmentEvidence}' : ''}',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () {
                        setState(() => _learningOutcomes.removeAt(entry.key));
                        _autoBackupLocalDraft();
                      },
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  /// Section C: Structured 12-Type Section-Based Content Builder
  Widget _buildSectionCContentBuilder() {
    return _studioScrollContainer(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'C. Lesson Content Builder',
                            style: LearnTzTypography.h3.copyWith(
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F4C81),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Organize instructional sections in a logical teaching sequence. Supports all 12 block types and Media Library integration.',
                            style: LearnTzTypography.bodySmall
                                .copyWith(color: LearnTzColors.textSecondary),
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
                          size: AppButtonSize.sm,
                          icon: Icons.perm_media_outlined,
                          onPressed: () async {
                            final asset = await _openMediaLibraryPicker();
                            if (asset != null && mounted) {
                              setState(() {
                                _contentBlocks.add(
                                  LessonContentBlock(
                                    id: 'blk_${DateTime.now().microsecondsSinceEpoch}',
                                    type: asset.mediaType == 'audio'
                                        ? LessonContentBlockType.audio
                                        : asset.mediaType == 'video'
                                            ? LessonContentBlockType.video
                                            : asset.mediaType == 'diagram'
                                                ? LessonContentBlockType.diagram
                                                : LessonContentBlockType.image,
                                    title: asset.title,
                                    content: asset.altText ?? '',
                                    mediaAssetId: asset.id,
                                    mediaUrl: asset.fileUrl,
                                    altText: asset.altText,
                                  ),
                                );
                              });
                              await _autoBackupLocalDraft();
                            }
                          },
                        ),
                        AppButton(
                          key: const Key('add-content-section-btn'),
                          label: 'Add Section',
                          variant: AppButtonVariant.primary,
                          size: AppButtonSize.sm,
                          icon: Icons.add,
                          onPressed: () => _addOrEditBlock(),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_contentBlocks.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: LearnTzColors.neutral50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: LearnTzColors.neutral200),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.view_agenda_outlined,
                            size: 36, color: LearnTzColors.neutral400),
                        const SizedBox(height: 8),
                        const Text(
                          'No content sections yet. Add headings, explanations, worked examples, multimedia, vocabulary, and a summary.',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        AppButton(
                          label: 'Add First Section',
                          variant: AppButtonVariant.primary,
                          size: AppButtonSize.sm,
                          onPressed: () => _addOrEditBlock(),
                        ),
                      ],
                    ),
                  )
                else
                  ..._contentBlocks.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final block = entry.value;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              children: [
                                IconButton(
                                  tooltip: 'Move Up',
                                  icon: const Icon(Icons.arrow_upward, size: 18),
                                  onPressed: idx == 0
                                      ? null
                                      : () {
                                          setState(() {
                                            final item =
                                                _contentBlocks.removeAt(idx);
                                            _contentBlocks.insert(idx - 1, item);
                                          });
                                          _autoBackupLocalDraft();
                                        },
                                ),
                                IconButton(
                                  tooltip: 'Move Down',
                                  icon:
                                      const Icon(Icons.arrow_downward, size: 18),
                                  onPressed: idx == _contentBlocks.length - 1
                                      ? null
                                      : () {
                                          setState(() {
                                            final item =
                                                _contentBlocks.removeAt(idx);
                                            _contentBlocks.insert(idx + 1, item);
                                          });
                                          _autoBackupLocalDraft();
                                        },
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Wrap(
                                    spacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      AppBadge(
                                        label: '${idx + 1}. ${block.type.label}',
                                        variant: AppBadgeVariant.primary,
                                        size: AppBadgeSize.sm,
                                      ),
                                      Text(
                                        block.title,
                                        style: LearnTzTypography.bodyRegular
                                            .copyWith(
                                                fontWeight: FontWeight.w700),
                                      ),
                                    ],
                                  ),
                                  if (block.content.isNotEmpty) ...[
                                    const SizedBox(height: 6),
                                    Text(
                                      block.content,
                                      style: LearnTzTypography.bodySmall,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                  if (block.mediaUrl != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Media: ${block.mediaUrl}',
                                      style: LearnTzTypography.caption.copyWith(
                                        color: const Color(0xFF0F4C81),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Edit Section',
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _addOrEditBlock(idx),
                            ),
                            IconButton(
                              tooltip: 'Delete Section',
                              icon: const Icon(Icons.delete_outline,
                                  size: 18, color: LearnTzColors.error),
                              onPressed: () {
                                setState(() => _contentBlocks.removeAt(idx));
                                _autoBackupLocalDraft();
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Section D: Teaching and Learning Activities
  Widget _buildSectionDTeachingActivities() {
    return _studioScrollContainer(
      AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'D. Teaching & Learning Activities',
                        style: LearnTzTypography.h3.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F4C81),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Design individual, pair, group, practical, and interactive learner activities.',
                        style: LearnTzTypography.bodySmall
                            .copyWith(color: LearnTzColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                AppButton(
                  key: const Key('add-teaching-activity-btn'),
                  label: 'Add Activity',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.sm,
                  icon: Icons.add,
                  onPressed: () => _addOrEditActivity(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_teachingActivities.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No teaching activities added yet. Click "Add Activity" to design structured learner practice.',
                  ),
                ),
              )
            else
              ..._teachingActivities.asMap().entries.map((entry) {
                final idx = entry.key;
                final act = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(act.title,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        AppBadge(
                          label: act.activityType.toUpperCase(),
                          variant: AppBadgeVariant.warning,
                          size: AppBadgeSize.sm,
                        ),
                        Text('${act.estimatedMinutes} min',
                            style: LearnTzTypography.caption),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(act.instructions),
                        if (act.requiredMaterials.isNotEmpty)
                          Text('Materials: ${act.requiredMaterials}',
                              style: LearnTzTypography.caption),
                        if (act.assessmentCriteria.isNotEmpty)
                          Text('Criteria: ${act.assessmentCriteria}',
                              style: LearnTzTypography.caption),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _addOrEditActivity(idx),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: LearnTzColors.error),
                          onPressed: () {
                            setState(() => _teachingActivities.removeAt(idx));
                            _autoBackupLocalDraft();
                          },
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  /// Section E: Assessment Builder (Integrated with existing public.question_bank)
  Widget _buildSectionEAssessmentBuilder() {
    return _studioScrollContainer(
      AppCard(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'E. Assessment Builder (Question Bank Integration)',
                        style: LearnTzTypography.h3.copyWith(
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F4C81),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Questions are stored directly in the shared LearnTZ Question Bank and linked to this lesson and its learning outcomes.',
                        style: LearnTzTypography.bodySmall
                            .copyWith(color: LearnTzColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                AppButton(
                  key: const Key('add-assessment-question-btn'),
                  label: 'Add Question',
                  variant: AppButtonVariant.primary,
                  size: AppButtonSize.sm,
                  icon: Icons.add,
                  onPressed: () => _addOrEditQuestion(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _assessmentCriteriaCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Overall Lesson Assessment Criteria',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (_) => _autoBackupLocalDraft(),
            ),
            const SizedBox(height: 16),
            if (_questions.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(
                  child: Text(
                    'No assessment questions linked yet. Supports MCQ, True/False, Short Answer, Matching, Fill-in-the-blank, Listening, Oral Response, and Practical Tasks.',
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            else
              ..._questions.asMap().entries.map((entry) {
                final idx = entry.key;
                final q = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(
                      'Q${idx + 1}. ${q.questionText}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${q.questionType.label} • ${q.marks.toStringAsFixed(0)} marks • ${q.difficultyLevel}'
                      '${q.id != null ? ' • Saved in Question Bank' : ' • Will sync on Draft Save'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _addOrEditQuestion(idx),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 18, color: LearnTzColors.error),
                          onPressed: () => _deleteQuestion(idx),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  /// Section G: Learner Preview Tab
  Widget _buildPreviewTab() {
    return _studioScrollContainer(
      LessonPreviewPane(
        title: _titleCtrl.text,
        shortDescription: _shortDescCtrl.text,
        breadcrumb: _breadcrumbText,
        estimatedMinutes: _estimatedMinutes,
        languageCode: _languageCode,
        difficultyLevel: _difficultyLevel,
        lessonType: _lessonType,
        learningObjectives: _learningObjectives,
        learningOutcomes: _learningOutcomes,
        contentBlocks: _contentBlocks,
        activities: _teachingActivities,
        questions: _questions,
        mainCompetenceLabel: _selectedMainCompObj != null
            ? '${_selectedMainCompObj!.code} — ${_selectedMainCompObj!.title}'
            : null,
        specificCompetenceLabel: _selectedSpecCompObj != null
            ? '${_selectedSpecCompObj!.code} — ${_selectedSpecCompObj!.title}'
            : null,
      ),
    );
  }

  /// Section H: Academic Review, Role-Gated Workflow & Version History
  Widget _buildReviewAndHistoryTab(LessonAuthoringCapabilities capabilities) {
    return _studioScrollContainer(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Editorial Lifecycle & Academic Review Governance',
                  style: LearnTzTypography.h3.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F4C81),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Lifecycle: Draft → Submitted for Review → Revision Requested / Approved → Published. '
                  'Drafts remain strictly unpublished until approved and published by an authorized publishing role.',
                  style: LearnTzTypography.bodySmall
                      .copyWith(color: LearnTzColors.textSecondary),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _changeSummaryCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Draft Change Summary (recorded in version history)',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const Key('review-comments-input'),
                  controller: _reviewCommentCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Academic Review / Revision Comments',
                    hintText:
                        'Required when requesting revisions; optional for submission/approval/publishing.',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    if (capabilities.canAuthor &&
                        (_workflowStatus == 'draft' ||
                            _workflowStatus == 'revision_requested'))
                      AppButton(
                        label: 'Save Draft',
                        variant: AppButtonVariant.outlined,
                        size: AppButtonSize.sm,
                        icon: Icons.save_outlined,
                        isLoading: _isSaving,
                        onPressed: _isSaving ? null : _saveDraft,
                      ),
                    if (capabilities.canAuthor &&
                        (_workflowStatus == 'draft' ||
                            _workflowStatus == 'revision_requested'))
                      AppButton(
                        label: 'Submit for Academic Review',
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.sm,
                        icon: Icons.send_outlined,
                        isLoading: _isSaving,
                        onPressed: _isSaving
                            ? null
                            : () => _transitionWorkflow('submit_for_review'),
                      ),
                    if (capabilities.canReview &&
                        _workflowStatus == 'in_review')
                      AppButton(
                        key: const Key('request-revision-btn'),
                        label: 'Request Revision',
                        variant: AppButtonVariant.outlined,
                        size: AppButtonSize.sm,
                        icon: Icons.edit_note,
                        isLoading: _isSaving,
                        onPressed: _isSaving
                            ? null
                            : () => _transitionWorkflow('request_revision'),
                      ),
                    if (capabilities.canApprove &&
                        _workflowStatus == 'in_review')
                      AppButton(
                        key: const Key('approve-lesson-btn'),
                        label: 'Approve Lesson',
                        variant: AppButtonVariant.secondary,
                        size: AppButtonSize.sm,
                        icon: Icons.check_circle_outline,
                        isLoading: _isSaving,
                        onPressed: _isSaving
                            ? null
                            : () => _transitionWorkflow('approve'),
                      ),
                    if (capabilities.canPublish &&
                        _workflowStatus == 'approved')
                      AppButton(
                        key: const Key('publish-lesson-btn'),
                        label: 'Publish to Learners',
                        variant: AppButtonVariant.primary,
                        size: AppButtonSize.sm,
                        icon: Icons.cloud_upload_outlined,
                        isLoading: _isSaving,
                        onPressed: _isSaving
                            ? null
                            : () => _transitionWorkflow('publish'),
                      ),
                    if (capabilities.canPublish && _isPublished)
                      AppButton(
                        label: 'Start Controlled Revision',
                        variant: AppButtonVariant.outlined,
                        size: AppButtonSize.sm,
                        icon: Icons.history_edu,
                        isLoading: _isSaving,
                        onPressed: _isSaving
                            ? null
                            : () => _transitionWorkflow('reopen_draft'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Version History
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Version History (${_revisions.length})',
                  style: LearnTzTypography.h3
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                if (_revisions.isEmpty)
                  Text(
                    'Version snapshots will appear here once the draft is saved.',
                    style: LearnTzTypography.bodySmall
                        .copyWith(color: LearnTzColors.textSecondary),
                  )
                else
                  ..._revisions.map(
                    (rev) => ListTile(
                      dense: true,
                      leading: AppBadge(
                        label: 'v${rev.versionNumber}',
                        variant: AppBadgeVariant.neutral,
                        size: AppBadgeSize.sm,
                      ),
                      title: Text(rev.title),
                      subtitle: Text(
                        '${rev.changeSummary ?? 'Saved revision'} • Status: ${rev.status}',
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Review Audit Timeline
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Academic Review Audit Trail (${_reviewEvents.length})',
                  style: LearnTzTypography.h3
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                if (_reviewEvents.isEmpty)
                  Text(
                    'Workflow events and reviewer feedback will be logged here.',
                    style: LearnTzTypography.bodySmall
                        .copyWith(color: LearnTzColors.textSecondary),
                  )
                else
                  ..._reviewEvents.map(
                    (ev) => ListTile(
                      dense: true,
                      leading: const Icon(Icons.history, size: 18),
                      title: Text(
                        '${ev.action.replaceAll('_', ' ').toUpperCase()} (v${ev.versionNumber})',
                      ),
                      subtitle: Text(
                        '${ev.fromStatus ?? 'new'} → ${ev.toStatus}'
                        '${ev.comments != null ? ' • ${ev.comments}' : ''}',
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
