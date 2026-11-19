import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:learntz/features/exams/exam_v2_models.dart';
import 'package:learntz/features/exams/exam_v2_providers.dart';
import 'package:learntz/features/exams/exam_v2_repository.dart';
import 'package:learntz/features/exams/screens/exam_centre_v2_screen.dart';
import 'package:learntz/features/exams/screens/exam_v2_paper_builder_screen.dart';

class _FakeExamCentreV2Repository extends ExamCentreV2Repository {
  final List<ExamV2ExaminationSummary> _savedExams = [];
  final List<ExamV2QuestionItem> _savedQuestions = [];
  final List<ExamV2PaperQuestion> _paperQuestions = [];
  int saveCalls = 0;
  int saveQuestionCalls = 0;

  @override
  Future<ExamV2PaperBuilderBundle> getPaperBuilder(String examinationId) async {
    final totalMarks = _paperQuestions.fold<double>(0, (s, q) => s + q.marks);
    return ExamV2PaperBuilderBundle(
      examination: {
        'id': examinationId,
        'title': 'English Language Terminal Examination — Standard III',
        'country_code': 'TZ',
        'country_name': 'Tanzania',
        'grade_name': 'Standard III',
        'subject_id': 'subj-tz-eng3',
        'subject_name': 'English Language',
        'examination_type_name': 'Terminal Examination',
        'duration_minutes': 90,
        'total_marks': totalMarks,
        'instructions': 'Read all questions carefully.',
        'status': 'draft',
      },
      isValid: _paperQuestions.isNotEmpty,
      validationIssues: _paperQuestions.isEmpty
          ? const ['Attach at least one question from Question Bank 2.0.']
          : const [],
      questionCount: _paperQuestions.length,
      sections: [
        ExamV2PaperSection(
          id: 'sec-a',
          sectionCode: 'A',
          title: 'Multiple Choice',
          questionFormat: 'multiple_choice',
          instructions: 'Choose the correct answer.',
          questionCount: _paperQuestions.length,
          marksAllocated: totalMarks,
          displayOrder: 1,
          questions: List.unmodifiable(_paperQuestions),
        ),
      ],
    );
  }

  @override
  Future<Map<String, dynamic>> addPaperQuestion({
    required String examinationId,
    required String sectionId,
    required String sourceQuestionId,
    double? marks,
  }) async {
    final src = _savedQuestions.firstWhere((q) => q.id == sourceQuestionId);
    final idx = _paperQuestions.length + 1;
    _paperQuestions.add(
      ExamV2PaperQuestion(
        id: 'pq-$idx',
        sectionId: sectionId,
        sourceQuestionId: src.id,
        sourceQuestionVersion: src.versionNumber,
        specificCompetenceCode: src.specificCompetenceCode,
        questionNumber: idx,
        displayOrder: idx,
        marks: marks ?? src.marks,
        questionType: src.questionType,
        questionText: src.questionText,
        options: src.options,
        correctAnswer: src.correctAnswer,
        markingRubric: src.markingRubric,
      ),
    );
    return {'id': 'pq-$idx', 'total_marks': marks ?? src.marks};
  }

  @override
  Future<ExamV2QuestionListResult> listQuestions(
    ExamV2SelectionKey selection, {
    String? specificCompetenceId,
    String? questionType,
    String? difficultyLevel,
    String? reviewStatus,
    String? search,
    int limit = 25,
    int offset = 0,
  }) async {
    return ExamV2QuestionListResult(
      totalCount: _savedQuestions.length,
      draftCount:
          _savedQuestions.where((q) => q.reviewStatus == 'draft').length,
      inReviewCount:
          _savedQuestions.where((q) => q.reviewStatus == 'in_review').length,
      approvedCount:
          _savedQuestions.where((q) => q.reviewStatus == 'approved').length,
      items: List.unmodifiable(_savedQuestions),
    );
  }

  @override
  Future<Map<String, dynamic>> saveQuestion({
    required ExamV2SelectionKey selection,
    required String specificCompetenceId,
    required String questionType,
    required String questionText,
    required Map<String, dynamic> correctAnswer,
    required List<dynamic> options,
    required Map<String, dynamic> markingRubric,
    required double marks,
    required String difficultyLevel,
    required String cognitiveTier,
    required String languageCode,
    required String explanation,
    required String sourceReference,
    required String copyrightNotice,
    String? questionId,
  }) async {
    saveQuestionCalls++;
    _savedQuestions.add(
      ExamV2QuestionItem(
        id: 'q-$saveQuestionCalls',
        countryCode: selection.countryCode,
        subjectId: selection.subjectId,
        subjectName: 'English Language',
        specificCompetenceId: specificCompetenceId,
        specificCompetenceCode: '1.1',
        specificCompetenceTitle: 'Develop listening and speaking skills',
        questionType: questionType,
        difficultyLevel: difficultyLevel,
        cognitiveTier: cognitiveTier,
        questionText: questionText,
        options: options,
        correctAnswer: correctAnswer,
        markingRubric: markingRubric,
        marks: marks,
        reviewStatus: 'draft',
        isPublished: false,
        versionNumber: 1,
      ),
    );
    return {
      'id': 'q-$saveQuestionCalls',
      'review_status': 'draft',
      'is_published': false,
      'version_number': 1,
    };
  }

  @override
  Future<ExamV2ExaminationListResult> listExaminations(
    ExamV2SelectionKey selection, {
    String? status,
    String? search,
    int limit = 20,
    int offset = 0,
  }) async {
    return ExamV2ExaminationListResult(
      totalCount: _savedExams.length,
      draftCount: _savedExams.where((e) => e.status == 'draft').length,
      underReviewCount:
          _savedExams.where((e) => e.status == 'submitted_for_review').length,
      approvedCount: 0,
      publishedCount: 0,
      items: List.unmodifiable(_savedExams),
    );
  }

  @override
  Future<Map<String, dynamic>> saveExamination({
    required ExamV2SelectionKey selection,
    required String title,
    required int academicYear,
    required String academicTerm,
    String? examinationDate,
    required int durationMinutes,
    required String languageCode,
    required String instructions,
    required String deliveryMode,
    required List<ExamV2SectionDraft> sections,
    required List<ExamV2CompetencyAllocation> competencies,
    String? examinationId,
  }) async {
    saveCalls++;
    final totalMarks =
        sections.fold<double>(0, (sum, s) => sum + s.marksAllocated);
    _savedExams.add(
      ExamV2ExaminationSummary(
        id: 'exam-$saveCalls',
        title: title,
        countryCode: selection.countryCode,
        countryName: 'Tanzania',
        curriculumName: 'Tanzania Institute of Education',
        curriculumVersionCode: 'TIE_PRIMARY_2023',
        educationLevelName: 'Primary Education',
        gradeName: 'Standard III',
        subjectName: 'English Language',
        examinationTypeName: 'Terminal Examination',
        academicYear: academicYear,
        academicTerm: academicTerm,
        durationMinutes: durationMinutes,
        totalMarks: totalMarks,
        languageCode: languageCode,
        deliveryMode: deliveryMode,
        status: 'draft',
        isPublished: false,
        versionNumber: 1,
        sectionCount: sections.length,
        competencyCount: competencies.length,
      ),
    );
    return {
      'id': 'exam-$saveCalls',
      'status': 'draft',
      'is_published': false,
      'total_marks': totalMarks,
      'version_number': 1,
    };
  }

  @override
  Future<List<ExamV2CountryOption>> getCountries() async {
    return const [
      ExamV2CountryOption(
        countryCode: 'TZ',
        displayName: 'Tanzania',
        curriculumId: 'cur-tz-tie',
        curriculumCode: 'TIE',
        curriculumName: 'Tanzania Institute of Education',
        curriculumVersionId: 'ver-tie-2023',
        curriculumVersionCode: 'TIE_PRIMARY_2023',
        curriculumVersionName: 'TIE Primary 2023',
      ),
      ExamV2CountryOption(
        countryCode: 'KE',
        displayName: 'Kenya',
        curriculumId: 'cur-ke-kicd',
        curriculumCode: 'KICD',
        curriculumName: 'Kenya Institute of Curriculum Development',
        curriculumVersionId: 'ver-ke-cbc',
        curriculumVersionCode: 'KICD_CBC_2024',
      ),
    ];
  }

  @override
  Future<List<ExamV2EducationLevelOption>> getEducationLevels(
    String countryCode,
  ) async {
    if (countryCode == 'TZ') {
      return const [
        ExamV2EducationLevelOption(
          id: 'lvl-tz-pri',
          curriculumId: 'cur-tz-tie',
          countryCode: 'TZ',
          code: 'PRIMARY',
          name: 'Primary Education',
          sequence: 1,
          gradeCount: 6,
        ),
      ];
    }
    return const [
      ExamV2EducationLevelOption(
        id: 'lvl-ke-pri',
        curriculumId: 'cur-ke-kicd',
        countryCode: 'KE',
        code: 'PRIMARY',
        name: 'Primary School (CBC)',
        sequence: 1,
        gradeCount: 6,
      ),
    ];
  }

  @override
  Future<List<ExamV2GradeOption>> getGrades({
    required String curriculumId,
    required String educationLevelId,
  }) async {
    if (educationLevelId == 'lvl-tz-pri') {
      return const [
        ExamV2GradeOption(
          id: 'grd-tz-std3',
          curriculumId: 'cur-tz-tie',
          educationLevelId: 'lvl-tz-pri',
          code: 'STANDARD_3',
          name: 'Standard III',
          sequence: 3,
          subjectCount: 3,
        ),
        ExamV2GradeOption(
          id: 'grd-tz-std4',
          curriculumId: 'cur-tz-tie',
          educationLevelId: 'lvl-tz-pri',
          code: 'STANDARD_4',
          name: 'Standard IV',
          sequence: 4,
          subjectCount: 3,
        ),
      ];
    }
    return const [];
  }

  @override
  Future<List<ExamV2SubjectOption>> getSubjects({
    required String curriculumId,
    required String educationLevelId,
    required String gradeId,
  }) async {
    if (gradeId == 'grd-tz-std3') {
      return const [
        ExamV2SubjectOption(
          id: 'subj-tz-eng3',
          curriculumId: 'cur-tz-tie',
          educationLevelId: 'lvl-tz-pri',
          gradeId: 'grd-tz-std3',
          countryCode: 'TZ',
          code: 'tie-pri-english-standard3',
          name: 'English Language',
          officialName: 'English Language Syllabus — Standard III',
          mainCompetenceCount: 3,
          specificCompetenceCount: 5,
        ),
      ];
    }
    return const [];
  }

  @override
  Future<List<ExamV2ExaminationTypeOption>> getExaminationTypes({
    required String countryCode,
    String? educationLevelId,
  }) async {
    return [
      ExamV2ExaminationTypeOption(
        id: 'type-$countryCode-terminal',
        countryCode: countryCode,
        code: 'TERMINAL',
        name: 'Terminal Examination',
        description: 'End-of-term summative assessment.',
        defaultDurationMinutes: 90,
        defaultTotalMarks: 50,
        allowsOnlineDelivery: true,
        allowsPrintedDelivery: true,
        requiresAcademicReview: true,
      ),
    ];
  }

  @override
  Future<ExamV2ContextSummary> getAcademicContextSummary(
    ExamV2SelectionKey selection,
  ) async {
    return const ExamV2ContextSummary(
      context: ExamV2AcademicContext(
        countryCode: 'TZ',
        countryName: 'Tanzania',
        curriculumId: 'cur-tz-tie',
        curriculumCode: 'TIE',
        curriculumName: 'Tanzania Institute of Education',
        curriculumVersionId: 'ver-tie-2023',
        curriculumVersionCode: 'TIE_PRIMARY_2023',
        curriculumVersionName: 'TIE Primary 2023',
        educationLevelId: 'lvl-tz-pri',
        educationLevelCode: 'PRIMARY',
        educationLevelName: 'Primary Education',
        gradeId: 'grd-tz-std3',
        gradeCode: 'STANDARD_3',
        gradeName: 'Standard III',
        subjectId: 'subj-tz-eng3',
        subjectCode: 'tie-pri-english-standard3',
        subjectName: 'English Language',
        language: 'en',
        examinationTypeId: 'type-TZ-terminal',
        examinationTypeCode: 'TERMINAL',
        examinationTypeName: 'Terminal Examination',
        examinationTypeDescription: 'End-of-term summative assessment.',
        defaultDurationMinutes: 90,
        defaultTotalMarks: 50,
        allowsOnlineDelivery: true,
        allowsPrintedDelivery: true,
        requiresAcademicReview: true,
        suggestedExaminationTitle:
            'English Language Terminal Examination — Standard III',
      ),
      questionBankCount: 14,
      examinationPapersCount: 2,
      alignedLessonsCount: 5,
      mainCompetences: [
        ExamV2MainCompetence(
          id: 'mc-1',
          code: '1.0',
          title: 'Demonstrate mastery of basic English language skills',
          displayOrder: 1,
          specificCompetences: [
            ExamV2SpecificCompetence(
              id: 'sc-1',
              topicId: 'top-1',
              code: '1.1',
              title: 'Develop listening and speaking skills',
              assessmentCriteria: 'Dictated familiar words are written accurately',
              periodAllocation: 32,
              sourcePage: 10,
              questionCount: 6,
              subtopicCount: 4,
            ),
          ],
        ),
      ],
    );
  }
}

Widget _wrapScreen(_FakeExamCentreV2Repository repo) {
  return ProviderScope(
    overrides: [
      examCentreV2RepositoryProvider.overrideWithValue(repo),
    ],
    child: const MaterialApp(
      home: ExamCentreV2Screen(),
    ),
  );
}

Future<void> _selectDropdownOption(
  WidgetTester tester,
  String dropdownKey,
  String optionLabel,
) async {
  final dd = find.byKey(Key(dropdownKey));
  await tester.ensureVisible(dd);
  await tester.tap(dd);
  await tester.pumpAndSettle();

  final option = find.text(optionLabel).last;
  await tester.ensureVisible(option);
  await tester.tap(option);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    '5-step cascading academic selection unlocks verified TIE Standard III English competencies and clears dependents on parent change',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeExamCentreV2Repository();
      await tester.pumpWidget(_wrapScreen(repo));
      await tester.pumpAndSettle();

      // Initially locked until all 5 steps are selected
      expect(find.byKey(const Key('exam-v2-locked-notice')), findsOneWidget);
      expect(
        find.byKey(const Key('exam-v2-verified-workspace')),
        findsNothing,
      );

      // Step 1 -> Country: Tanzania
      await _selectDropdownOption(tester, 'exam-v2-step1-country', 'Tanzania');
      // Step 2 -> Education Level: Primary Education
      await _selectDropdownOption(
        tester,
        'exam-v2-step2-level',
        'Primary Education',
      );
      // Step 3 -> Grade: Standard III
      await _selectDropdownOption(
        tester,
        'exam-v2-step3-grade',
        'Standard III',
      );
      // Step 4 -> Subject: English Language
      await _selectDropdownOption(
        tester,
        'exam-v2-step4-subject',
        'English Language',
      );
      // Step 5 -> Examination Type: Terminal Examination
      await _selectDropdownOption(
        tester,
        'exam-v2-step5-exam-type',
        'Terminal Examination',
      );

      // Verified workspace now renders official curriculum competencies
      expect(
        find.byKey(const Key('exam-v2-verified-workspace')),
        findsOneWidget,
      );
      expect(
        find.text('English Language Terminal Examination — Standard III'),
        findsOneWidget,
      );
      expect(find.text('TIE_PRIMARY_2023'), findsOneWidget);
      expect(
        find.text('Demonstrate mastery of basic English language skills'),
        findsOneWidget,
      );
      expect(
        find.text('Develop listening and speaking skills'),
        findsOneWidget,
      );

      // Changing Step 1 Country to Kenya clears all dependent selections and re-locks workspace
      await _selectDropdownOption(tester, 'exam-v2-step1-country', 'Kenya');
      expect(find.byKey(const Key('exam-v2-locked-notice')), findsOneWidget);
      expect(
        find.byKey(const Key('exam-v2-verified-workspace')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'renders cleanly on mobile viewport (390x844) without layout overflow',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeExamCentreV2Repository();
      await tester.pumpWidget(_wrapScreen(repo));
      await tester.pumpAndSettle();

      expect(find.text('Examination Centre 2.0'), findsOneWidget);
      expect(find.byKey(const Key('exam-v2-locked-notice')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Phase 2: Create Examination dialog calculates total marks dynamically and saves draft to list',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeExamCentreV2Repository();
      await tester.pumpWidget(_wrapScreen(repo));
      await tester.pumpAndSettle();

      await _selectDropdownOption(tester, 'exam-v2-step1-country', 'Tanzania');
      await _selectDropdownOption(
        tester,
        'exam-v2-step2-level',
        'Primary Education',
      );
      await _selectDropdownOption(
        tester,
        'exam-v2-step3-grade',
        'Standard III',
      );
      await _selectDropdownOption(
        tester,
        'exam-v2-step4-subject',
        'English Language',
      );
      await _selectDropdownOption(
        tester,
        'exam-v2-step5-exam-type',
        'Terminal Examination',
      );

      final createBtn = find.byKey(const Key('exam-v2-create-exam-btn'));
      await tester.ensureVisible(createBtn);
      await tester.tap(createBtn);
      await tester.pumpAndSettle();

      // Default 3 starter sections = 50 marks; adding a 4th section adds 10 -> 60 marks
      expect(find.text('Total Marks: 50'), findsOneWidget);
      await tester.ensureVisible(
        find.byKey(const Key('exam-v2-add-section-btn')),
      );
      await tester.tap(find.byKey(const Key('exam-v2-add-section-btn')));
      await tester.pumpAndSettle();
      expect(find.text('Total Marks: 60'), findsOneWidget);

      await tester.tap(find.byKey(const Key('exam-v2-save-draft-btn')));
      await tester.pumpAndSettle();

      expect(repo.saveCalls, 1);
      expect(find.text('60 marks'), findsOneWidget);
      expect(find.text('4 sections'), findsOneWidget);
    },
  );

  testWidgets(
    'Phase 3: Question Bank 2.0 dialog creates curriculum-mapped question and refreshes list',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeExamCentreV2Repository();
      await tester.pumpWidget(_wrapScreen(repo));
      await tester.pumpAndSettle();

      await _selectDropdownOption(tester, 'exam-v2-step1-country', 'Tanzania');
      await _selectDropdownOption(
        tester,
        'exam-v2-step2-level',
        'Primary Education',
      );
      await _selectDropdownOption(
        tester,
        'exam-v2-step3-grade',
        'Standard III',
      );
      await _selectDropdownOption(
        tester,
        'exam-v2-step4-subject',
        'English Language',
      );
      await _selectDropdownOption(
        tester,
        'exam-v2-step5-exam-type',
        'Terminal Examination',
      );

      final createQBtn = find.byKey(const Key('exam-v2-create-question-btn'));
      await tester.ensureVisible(createQBtn);
      await tester.tap(createQBtn);
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('exam-v2-q-statement-field')),
        'Choose the opposite of the word "big":',
      );
      await tester.enterText(
        find.byKey(const Key('exam-v2-q-options-field')),
        'Tall\nSmall\nLong\nWide',
      );
      await tester.enterText(
        find.byKey(const Key('exam-v2-q-answer-field')),
        'Small',
      );

      await tester.tap(find.byKey(const Key('exam-v2-q-save-draft-btn')));
      await tester.pumpAndSettle();

      expect(repo.saveQuestionCalls, 1);
      expect(
        find.text('Choose the opposite of the word "big":'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Phase 4: Paper Builder attaches versioned question snapshot and renders formatted Print Preview with Marking Guide',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 960);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeExamCentreV2Repository();
      const selection = ExamV2SelectionKey(
        countryCode: 'TZ',
        educationLevelId: 'lvl-tz-pri',
        gradeId: 'grd-tz-std3',
        subjectId: 'subj-tz-eng3',
        examinationTypeId: 'type-TZ-terminal',
      );
      await repo.saveQuestion(
        selection: selection,
        specificCompetenceId: 'sc-1',
        questionType: 'multiple_choice',
        questionText: 'The opposite of big is:',
        correctAnswer: const {'answer': 'Small'},
        options: const ['Tall', 'Small', 'Long', 'Wide'],
        markingRubric: const {},
        marks: 2,
        difficultyLevel: 'easy',
        cognitiveTier: 'knowledge',
        languageCode: 'en',
        explanation: '',
        sourceReference: '',
        copyrightNotice: '',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            examCentreV2RepositoryProvider.overrideWithValue(repo),
          ],
          child: const MaterialApp(
            home: ExamV2PaperBuilderScreen(
              examinationId: 'exam-1',
              selection: selection,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('paper-add-q-sec-A')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('paper-bank-pick-q-1')));
      await tester.pumpAndSettle();

      expect(find.text('The opposite of big is:'), findsOneWidget);

      await tester.tap(find.byKey(const Key('paper-builder-preview-tab')));
      await tester.pumpAndSettle();

      expect(find.text('UNITED REPUBLIC OF TANZANIA'), findsOneWidget);
      expect(find.textContaining('1. The opposite of big is:'), findsOneWidget);
      expect(find.text('Marking Guide: Small'), findsNothing);

      await tester.tap(
        find.byKey(const Key('paper-builder-marking-guide-chip')),
      );
      await tester.pumpAndSettle();

      expect(find.text('Marking Guide: Small'), findsOneWidget);
    },
  );
}
