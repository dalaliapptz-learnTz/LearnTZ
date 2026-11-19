import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:learntz/features/exams/exam_v2_models.dart';
import 'package:learntz/features/exams/exam_v2_providers.dart';
import 'package:learntz/features/exams/exam_v2_repository.dart';
import 'package:learntz/features/exams/screens/exam_centre_v2_screen.dart';

class _FakeExamCentreV2Repository extends ExamCentreV2Repository {
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
}
