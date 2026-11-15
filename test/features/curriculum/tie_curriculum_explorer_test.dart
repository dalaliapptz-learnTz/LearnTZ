import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:learntz/features/curriculum/curriculum_explorer_screen.dart';
import 'package:learntz/features/learners/learner_models.dart';
import 'package:learntz/features/learners/learner_providers.dart';
import 'package:learntz/features/learning/learning_models.dart';
import 'package:learntz/features/learning/learning_providers.dart';
import 'package:learntz/features/learning/learning_repository.dart';
import 'package:learntz/l10n/generated/app_localizations.dart';

class _FakeLearningRepository implements LearningRepository {
  _FakeLearningRepository(this.subjects);

  final List<CurriculumExplorerSubject> subjects;

  @override
  Future<List<CurriculumExplorerSubject>> getCurriculumExplorerTree({
    required String countryCode,
    required String educationSystemId,
    String? educationLevelId,
    String? gradeId,
  }) async {
    return subjects;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final sampleSubtopic = CurriculumExplorerSubtopic.fromJson({
    'subtopic_id': 'st-1',
    'title': 'Kutambua na Kutamka Sauti za Herufi',
    'learning_outcome': 'Mwanafunzi aweze kutambua sauti za herufi na kuzitamka kwa usahihi.',
    'period_allocation': 12,
    'source_page': 14,
    'display_order': 1,
  });

  final sampleTopic = CurriculumExplorerTopic.fromJson({
    'topic_id': 'top-1',
    'title': 'Kusoma kwa Ufahamu',
    'summary': 'Umahiri wa kusoma matini mbalimbali na kueleza maudhui.',
    'display_order': 1,
    'competency_code': 'KIS.III.1',
    'period_allocation': 48,
    'assessment_criteria': 'Mwanafunzi anasoma kwa ufasaha na kujibu maswali ya ufahamu.',
    'source_page': 12,
    'subtopics': [
      sampleSubtopic.toJsonMap(),
    ],
    'lessons': [
      {
        'lesson_id': 'les-1',
        'title': 'Sauti na Maneno',
        'estimated_minutes': 20,
        'is_free_preview': true,
        'display_order': 1,
      },
    ],
  });

  final sampleSubjectKiswahili = CurriculumExplorerSubject.fromJson({
    'subject_id': 'sub-kis',
    'subject_name': 'Kiswahili',
    'official_name': 'Muhtasari wa Somo la Kiswahili Elimu ya Msingi Darasa la III – VI',
    'subject_code': 'KIS',
    'description': 'Mtaala rasmi wa lugha ya Kiswahili kwa shule za msingi.',
    'classification': 'compulsory',
    'language': 'sw',
    'grade_id': 'grd-3',
    'display_order': 1,
    'topics': [
      sampleTopic.toJsonMap(),
    ],
  });

  final sampleSubjectChinese = CurriculumExplorerSubject.fromJson({
    'subject_id': 'sub-chi',
    'subject_name': 'Chinese Language',
    'official_name': 'Muhtasari wa Somo la Lugha ya Kichina Elimu ya Msingi Darasa la III-VI',
    'subject_code': 'CHI',
    'description': 'Somo la hiari la lugha ya Kichina kwa shule za msingi.',
    'classification': 'elective',
    'language': 'zh',
    'grade_id': 'grd-3',
    'display_order': 8,
    'topics': [
      {
        'topic_id': 'top-chi-1',
        'title': 'Pinyin and Greetings',
        'summary': 'Basic Mandarin phonetics and introductory dialogues.',
        'competency_code': 'CHI.III.1',
        'period_allocation': 32,
        'assessment_criteria': 'Learner accurately pronounces 4 tones and greets in Mandarin.',
        'source_page': 8,
        'subtopics': [
          {
            'subtopic_id': 'st-chi-1',
            'title': 'Initials and Finals',
            'learning_outcome': 'Produce pinyin initials and finals accurately.',
            'period_allocation': 16,
            'source_page': 9,
            'display_order': 1,
          },
        ],
        'lessons': [],
      },
    ],
  });

  group('CurriculumExplorer Models — Official TIE Data Parsing', () {
    test('CurriculumExplorerSubtopic parses all TIE attributes correctly', () {
      expect(sampleSubtopic.subtopicId, 'st-1');
      expect(sampleSubtopic.title, 'Kutambua na Kutamka Sauti za Herufi');
      expect(sampleSubtopic.learningOutcome, contains('kuzitamka kwa usahihi'));
      expect(sampleSubtopic.periodAllocation, 12);
      expect(sampleSubtopic.sourcePage, 14);
      expect(sampleSubtopic.displayOrder, 1);
    });

    test('CurriculumExplorerTopic parses competency codes and period allocations', () {
      expect(sampleTopic.topicId, 'top-1');
      expect(sampleTopic.title, 'Kusoma kwa Ufahamu');
      expect(sampleTopic.competencyCode, 'KIS.III.1');
      expect(sampleTopic.periodAllocation, 48);
      expect(sampleTopic.assessmentCriteria, contains('kujibu maswali ya ufahamu'));
      expect(sampleTopic.sourcePage, 12);
      expect(sampleTopic.subtopics.length, 1);
      expect(sampleTopic.lessons.length, 1);
    });

    test('CurriculumExplorerSubject calculates total periods, subtopics, and classification', () {
      expect(sampleSubjectKiswahili.subjectName, 'Kiswahili');
      expect(sampleSubjectKiswahili.officialName, contains('Muhtasari wa Somo la Kiswahili'));
      expect(sampleSubjectKiswahili.effectiveDisplayName, contains('Muhtasari wa Somo la Kiswahili'));
      expect(sampleSubjectKiswahili.isCompulsory, isTrue);
      expect(sampleSubjectKiswahili.isElective, isFalse);
      expect(sampleSubjectKiswahili.totalPeriods, 48);
      expect(sampleSubjectKiswahili.totalSubtopics, 1);
      expect(sampleSubjectKiswahili.totalLessons, 1);

      expect(sampleSubjectChinese.isCompulsory, isFalse);
      expect(sampleSubjectChinese.isElective, isTrue);
      expect(sampleSubjectChinese.totalPeriods, 32);
      expect(sampleSubjectChinese.totalSubtopics, 1);
      expect(sampleSubjectChinese.totalLessons, 0);
    });
  });

  group('CurriculumExplorerScreen Widget Tests', () {
    const catalog = EducationCatalog(
      countries: [
        EducationCountry(code: 'TZ', name: 'Tanzania'),
      ],
      systems: [
        EducationSystem(
          id: 'sys-tz',
          countryCode: 'TZ',
          name: 'Tanzania National Education System',
        ),
      ],
      curricula: [
        Curriculum(
          id: 'tz-curr-id',
          countryCode: 'TZ',
          educationSystemId: 'sys-tz',
          name: 'Tanzania Institute of Education',
          code: 'TIE',
        ),
      ],
      levels: [
        EducationLevel(
          id: 'lvl-pri',
          curriculumId: 'tz-curr-id',
          code: 'PRIMARY',
          name: 'Primary Education',
          sequence: 1,
        ),
      ],
      grades: [
        EducationGrade(
          id: 'grd-3',
          curriculumId: 'tz-curr-id',
          educationLevelId: 'lvl-pri',
          code: 'STANDARD_3',
          name: 'Standard III',
          sequence: 3,
        ),
      ],
      schools: [],
    );

    Widget buildTestWidget({
      required List<CurriculumExplorerSubject> subjects,
    }) {
      final fakeRepo = _FakeLearningRepository(subjects);

      return ProviderScope(
        overrides: [
          educationCatalogProvider.overrideWith((ref) => Future.value(catalog)),
          learningRepositoryProvider.overrideWithValue(fakeRepo),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: CurriculumExplorerScreen(),
          ),
        ),
      );
    }

    testWidgets('renders TIE Authority Banner and displays subjects with badges', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(
          subjects: [sampleSubjectKiswahili, sampleSubjectChinese],
        ),
      );
      await tester.pumpAndSettle();

      // Check title and authority banner
      expect(find.text('Curriculum Explorer'), findsOneWidget);
      expect(find.text('Official TIE 2023 Curriculum'), findsOneWidget);
      expect(find.text('TIE Verified'), findsOneWidget);
      expect(find.text('View Syllabus Info'), findsOneWidget);

      // Check subject card titles and badges
      expect(find.text('Kiswahili'), findsOneWidget);
      expect(find.text('Compulsory'), findsOneWidget);
      expect(find.text('Chinese Language'), findsOneWidget);
      expect(find.text('Elective'), findsOneWidget);
      expect(find.text('48 periods'), findsOneWidget);
      expect(find.text('32 periods'), findsOneWidget);
    });

    testWidgets('opens TIE official syllabus catalog dialog with ISBNs and documents', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(
          subjects: [sampleSubjectKiswahili, sampleSubjectChinese],
        ),
      );
      await tester.pumpAndSettle();

      // Tap "View Syllabus Info"
      await tester.tap(find.text('View Syllabus Info'));
      await tester.pumpAndSettle();

      // Verify dialog content
      expect(find.text('Official TIE Syllabus Details'), findsOneWidget);
      expect(find.textContaining('Issuing Authority: Taasisi ya Elimu Tanzania (TIE)'), findsOneWidget);
      expect(find.text('TZ-TIE-PRI-KIS'), findsOneWidget);
      expect(find.text('TZ-TIE-PRI-MATH'), findsOneWidget);
      expect(find.text('TZ-TIE-PRI-CHI'), findsOneWidget);
      expect(find.textContaining('ISBN: 978-9987-09-866-8'), findsOneWidget);

      // Close dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Official TIE Syllabus Details'), findsNothing);
    });

    testWidgets('filters subjects by classification: Compulsory and Elective', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(
          subjects: [sampleSubjectKiswahili, sampleSubjectChinese],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kiswahili'), findsOneWidget);
      expect(find.text('Chinese Language'), findsOneWidget);

      // Filter by Compulsory Only
      await tester.tap(find.text('Compulsory Only'));
      await tester.pumpAndSettle();

      expect(find.text('Kiswahili'), findsOneWidget);
      expect(find.text('Chinese Language'), findsNothing);

      // Filter by Electives Only
      await tester.tap(find.text('Electives Only'));
      await tester.pumpAndSettle();

      expect(find.text('Kiswahili'), findsNothing);
      expect(find.text('Chinese Language'), findsOneWidget);

      // Reset to All Subjects
      await tester.tap(find.text('All Subjects'));
      await tester.pumpAndSettle();

      expect(find.text('Kiswahili'), findsOneWidget);
      expect(find.text('Chinese Language'), findsOneWidget);
    });

    testWidgets('expands subject to show competency code, period allocation and subtopics', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(
          subjects: [sampleSubjectKiswahili],
        ),
      );
      await tester.pumpAndSettle();

      // Tap on Kiswahili to expand the ExpansionTile
      await tester.tap(find.text('Kiswahili'));
      await tester.pumpAndSettle();

      // Verify expanded syllabus elements
      expect(find.text('Syllabus Reference'), findsOneWidget);
      expect(find.text('Muhtasari wa Somo la Kiswahili Elimu ya Msingi Darasa la III – VI'), findsOneWidget);
      expect(find.text('KIS.III.1'), findsOneWidget);
      expect(find.text('Kusoma kwa Ufahamu'), findsOneWidget);
      expect(find.textContaining('Assessment Criteria: Mwanafunzi anasoma kwa ufasaha'), findsOneWidget);
      expect(find.text('Learning Outcomes & Specific Competences'), findsOneWidget);
      expect(find.text('Kutambua na Kutamka Sauti za Herufi'), findsOneWidget);
      expect(find.text('Sauti na Maneno'), findsOneWidget);
      expect(find.text('Study'), findsOneWidget);
    });

    testWidgets('search query filters topics and subtopics matching keyword', (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        buildTestWidget(
          subjects: [sampleSubjectKiswahili, sampleSubjectChinese],
        ),
      );
      await tester.pumpAndSettle();

      // Enter search query "Pinyin"
      await tester.enterText(find.byType(TextField), 'Pinyin');
      await tester.pumpAndSettle();

      expect(find.text('Chinese Language'), findsOneWidget);
      expect(find.text('Kiswahili'), findsNothing);

      // Clear search
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      expect(find.text('Chinese Language'), findsOneWidget);
      expect(find.text('Kiswahili'), findsOneWidget);
    });
  });
}

extension on CurriculumExplorerSubtopic {
  Map<String, dynamic> toJsonMap() {
    return {
      'subtopic_id': subtopicId,
      'title': title,
      'learning_outcome': learningOutcome,
      'period_allocation': periodAllocation,
      'source_page': sourcePage,
      'display_order': displayOrder,
    };
  }
}

extension on CurriculumExplorerTopic {
  Map<String, dynamic> toJsonMap() {
    return {
      'topic_id': topicId,
      'title': title,
      'summary': summary,
      'display_order': displayOrder,
      'competency_code': competencyCode,
      'period_allocation': periodAllocation,
      'assessment_criteria': assessmentCriteria,
      'source_page': sourcePage,
      'subtopics': subtopics.map((s) => s.toJsonMap()).toList(),
      'lessons': lessons
          .map(
            (l) => {
              'lesson_id': l.lessonId,
              'title': l.title,
              'estimated_minutes': l.estimatedMinutes,
              'is_free_preview': l.isFreePreview,
              'display_order': l.displayOrder,
            },
          )
          .toList(),
    };
  }
}
