import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:learntz/features/content_studio/content_studio_models.dart';
import 'package:learntz/features/content_studio/content_studio_providers.dart';
import 'package:learntz/features/content_studio/screens/content_studio_dashboard_screen.dart';
import 'package:learntz/features/content_studio/widgets/curriculum_explorer_tree.dart';
import 'package:learntz/features/content_studio/widgets/subject_workspace_view.dart';

void main() {
  group('Content Management Studio Multi-Country Models Tests', () {
    test('StudioCountryItem and nested hierarchy parses JSON accurately', () {
      final json = {
        'country_code': 'TZ',
        'country_name': 'Tanzania',
        'product_name': 'LearnTZ',
        'currency_code': 'TZS',
        'is_enabled': true,
        'authority_name': 'Tanzania Institute of Education',
        'authority_code': 'TIE',
        'active_version': '2023 Edition',
        'total_levels': 3,
        'total_grades': 7,
        'total_subjects': 12,
        'total_lessons': 140,
        'education_levels': [
          {
            'level_id': 'lvl-1',
            'level_name': 'Primary Education',
            'level_code': 'PRIMARY',
            'level_sequence': 1,
            'grades': [
              {
                'grade_id': 'grd-3',
                'grade_name': 'Standard 3',
                'grade_code': 'STANDARD_3',
                'grade_sequence': 3,
                'subjects': [
                  {
                    'subject_id': 'sub-eng-std3',
                    'subject_name': 'English Language',
                    'subject_code': 'tie-pri-english-standard3',
                    'country_code': 'TZ',
                    'subject_order': 1,
                    'education_level_id': 'lvl-1',
                    'education_level_name': 'Primary Education',
                    'grade_id': 'grd-3',
                    'grade_name': 'Standard 3',
                    'official_name':
                        'English Language Syllabus for Primary Education Standards III-VI',
                    'classification': 'Core Subject',
                    'language': 'English',
                    'is_published': true,
                    'topics': [
                      {
                        'topic_id': 'top-1',
                        'topic_title': 'Greeting and Introducing Oneself',
                        'topic_summary': 'Greetings and self-introductions in formal and informal contexts',
                        'topic_order': 1,
                        'topic_is_published': true,
                        'competency_code': '1.1',
                        'period_allocation': 30,
                        'assessment_criteria': 'Learner can greet politely and introduce self.',
                        'source_page': 14,
                        'lessons': [
                          {
                            'lesson_id': 'les-1',
                            'lesson_title': 'Morning Greetings and Expressions',
                            'estimated_minutes': 15,
                            'is_free_preview': true,
                            'lesson_order': 1,
                            'lesson_status': 'published',
                            'lesson_is_published': true,
                            'version_number': 2,
                          }
                        ],
                      }
                    ],
                  }
                ],
              }
            ],
          }
        ],
      };

      final country = StudioCountryItem.fromJson(json);
      expect(country.countryCode, 'TZ');
      expect(country.countryName, 'Tanzania');
      expect(country.authorityCode, 'TIE');
      expect(country.flagEmoji, '🇹🇿');
      expect(country.educationLevels.length, 1);

      final level = country.educationLevels.first;
      expect(level.levelName, 'Primary Education');
      expect(level.grades.length, 1);

      final grade = level.grades.first;
      expect(grade.gradeName, 'Standard 3');
      expect(grade.subjects.length, 1);

      final subject = grade.subjects.first;
      expect(subject.subjectName, 'English Language');
      expect(subject.subjectCode, 'tie-pri-english-standard3');
      expect(subject.isPublished, isTrue);
      expect(subject.topics.length, 1);
      expect(subject.totalLessons, 1);
      expect(subject.totalPeriods, 30);
    });

    test('StudioCountryItem flags coverage for all 6 EAC nations', () {
      const codes = ['TZ', 'KE', 'UG', 'RW', 'BI', 'SS'];
      const expectedFlags = ['🇹🇿', '🇰🇪', '🇺🇬', '🇷🇼', '🇧🇮', '🇸🇸'];

      for (var i = 0; i < codes.length; i++) {
        final item = StudioCountryItem(
          countryCode: codes[i],
          countryName: 'Country',
          productName: 'Learn',
          currencyCode: 'USD',
          authorityName: 'Authority',
          authorityCode: 'AUTH',
        );
        expect(item.flagEmoji, expectedFlags[i]);
      }
    });
  });

  group('Content Management Studio Redesign Widget Tests', () {
    final mockCountries = [
      const StudioCountryItem(
        countryCode: 'TZ',
        countryName: 'Tanzania',
        productName: 'LearnTZ',
        currencyCode: 'TZS',
        authorityName: 'Tanzania Institute of Education',
        authorityCode: 'TIE',
        educationLevels: [
          StudioEducationLevelItem(
            levelId: 'tz-pri',
            levelName: 'Primary Education',
            levelCode: 'PRIMARY',
            grades: [
              StudioGradeItem(
                gradeId: 'tz-std3',
                gradeName: 'Standard 3',
                gradeCode: 'STANDARD_3',
                subjects: [
                  StudioSubjectItem(
                    subjectId: 'tie-pri-english-standard3',
                    subjectName: 'English Language',
                    subjectCode: 'tie-pri-english-standard3',
                    countryCode: 'TZ',
                    topics: [
                      StudioTopicItem(
                        topicId: 't-1',
                        topicTitle: 'Greeting and Introducing Oneself',
                        topicOrder: 1,
                        isPublished: true,
                        competencyCode: '1.1',
                        periodAllocation: 30,
                        assessmentCriteria: 'Assess oral competence.',
                        lessons: [
                          StudioLessonItem(
                            lessonId: 'l-1',
                            lessonTitle: 'Morning Greetings',
                            status: ContentWorkflowStatus.published,
                            isPublished: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      const StudioCountryItem(
        countryCode: 'KE',
        countryName: 'Kenya',
        productName: 'LearnKE',
        currencyCode: 'KES',
        authorityName: 'Kenya Institute of Curriculum Development',
        authorityCode: 'KICD',
      ),
      const StudioCountryItem(
        countryCode: 'UG',
        countryName: 'Uganda',
        productName: 'LearnUG',
        currencyCode: 'UGX',
        authorityName: 'National Curriculum Development Centre',
        authorityCode: 'NCDC',
      ),
      const StudioCountryItem(
        countryCode: 'RW',
        countryName: 'Rwanda',
        productName: 'LearnRW',
        currencyCode: 'RWF',
        authorityName: 'Rwanda Basic Education Board',
        authorityCode: 'REB',
      ),
      const StudioCountryItem(
        countryCode: 'BI',
        countryName: 'Burundi',
        productName: 'LearnBI',
        currencyCode: 'BIF',
        authorityName: 'Bureau de l\'Education Fondamentale',
        authorityCode: 'BEPES',
      ),
      const StudioCountryItem(
        countryCode: 'SS',
        countryName: 'South Sudan',
        productName: 'LearnSS',
        currencyCode: 'SSP',
        authorityName: 'Ministry of General Education and Instruction',
        authorityCode: 'MOGEI',
      ),
    ];

    final mockCatalog = [
      const StudioSubjectItem(
        subjectId: 'tie-pri-english-standard3',
        subjectName: 'English Language Standard 3',
        subjectCode: 'tie-pri-english-standard3',
        countryCode: 'TZ',
        gradeName: 'Standard 3',
        topics: [
          StudioTopicItem(
            topicId: 't-1',
            topicTitle: 'Greeting and Introducing Oneself',
            topicOrder: 1,
            isPublished: true,
            competencyCode: '1.1',
            periodAllocation: 30,
            assessmentCriteria: 'Learner greets accurately.',
            lessons: [
              StudioLessonItem(
                lessonId: 'l-1',
                lessonTitle: 'Morning Greetings',
                estimatedMinutes: 15,
                status: ContentWorkflowStatus.published,
                isPublished: true,
              ),
            ],
          ),
        ],
      ),
    ];

    const mockMetrics = ContentStudioMetrics(
      countryCode: 'ALL',
      totalSubjects: 6,
      totalTopics: 28,
      totalLessons: 75,
      publishedLessons: 55,
      draftLessons: 15,
      inReviewLessons: 5,
      totalMediaAssets: 24,
    );

    testWidgets('CurriculumExplorerTree renders EAC nations and authorities',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 320,
                height: 800,
                child: CurriculumExplorerTree(
                  countries: mockCountries,
                  catalogSubjects: mockCatalog,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Curriculum Explorer'), findsOneWidget);
      expect(find.text('All Markets Overview'), findsOneWidget);

      // EAC Countries
      expect(find.text('Tanzania (TZ)'), findsOneWidget);
      expect(find.text('Kenya (KE)'), findsOneWidget);
      expect(find.text('Uganda (UG)'), findsOneWidget);
      expect(find.text('Rwanda (RW)'), findsOneWidget);
      expect(find.text('Burundi (BI)'), findsOneWidget);
      expect(find.text('South Sudan (SS)'), findsOneWidget);

      // Authorities
      expect(find.text('TIE'), findsOneWidget);
      expect(find.text('KICD'), findsOneWidget);
      expect(find.text('NCDC'), findsOneWidget);
      expect(find.text('REB'), findsOneWidget);
      expect(find.text('BEPES'), findsOneWidget);
      expect(find.text('MOGEI'), findsOneWidget);
    });

    testWidgets(
        'SubjectWorkspaceView renders breadcrumbs, header and 13 dedicated curriculum tabs',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final workspaceDetail = StudioSubjectWorkspaceDetail(
        subject: mockCatalog.first,
        curriculumVersion: '2023 Official Syllabus Edition',
        sourceDocumentTitle:
            'TIE English Language Syllabus for Primary Education Standards III-VI (2023)',
        competencies: const [
          StudioCompetencyItem(
            code: '1.1',
            title: 'Greeting and Introducing Oneself',
            description: 'Oral expressions in formal and informal situations',
            periodAllocation: 30,
            assessmentCriteria: 'Assess oral fluency and polite conventions.',
            isVerified: true,
          ),
        ],
        strands: const [
          StudioStrandItem(
            title: 'Oral Communication',
            substrands: ['Listening', 'Speaking & Dialogues'],
          ),
        ],
        outcomes: const [
          StudioLearningOutcomeItem(
            code: 'LO-1.1',
            outcome: 'Learners demonstrate correct greetings based on time of day.',
            cognitiveLevel: 'Application',
            competencyCode: '1.1',
          ),
        ],
        activities: const [
          StudioActivityItem(
            title: 'Classroom Greeting Roleplay',
            modality: 'Pair Work',
            materials: 'Flashcards, Audio Prompt',
            instructions: 'Learners roleplay dialogue in pairs.',
          ),
        ],
        assessments: const [
          StudioAssessmentItem(
            title: 'Greeting Competency Quiz',
            type: 'Formative Assessment',
            criteria: 'Oral greeting criteria',
            rubric: '4-level rubric',
          ),
        ],
        reviewHistory: const [
          StudioReviewEvent(
            stage: 'Academic Review',
            actor: 'TIE Specialist',
            role: 'Reviewer',
            timestamp: '2026-11-15 10:00',
            notes: 'Verified against 2023 edition.',
            status: 'approved',
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            subjectWorkspaceDetailProvider('tie-pri-english-standard3')
                .overrideWith((ref) async => workspaceDetail),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SubjectWorkspaceView(
                subjectId: 'tie-pri-english-standard3',
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Subject Header & Breadcrumbs
      expect(find.text('English Language Standard 3'), findsWidgets);
      expect(find.text('Curriculum'), findsOneWidget);
      expect(find.text('🇹🇿 Tanzania'), findsOneWidget);
      expect(find.text('Standard 3'), findsWidgets);

      // Verify all 13 Tabs are present
      expect(find.widgetWithText(Tab, 'Overview'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Syllabus'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Competencies'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Strands'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Outcomes'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Topics'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Lessons'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Activities'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Assessments'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Resources'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Curriculum Mapping'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Review & Approval'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Version History'), findsOneWidget);

      // Switch to Competencies Tab
      await tester.tap(find.widgetWithText(Tab, 'Competencies'));
      await tester.pumpAndSettle();
      expect(find.text('Competence 1.1'), findsOneWidget);
      expect(find.text('TIE Verified'), findsOneWidget);

      // Switch to Review & Approval Tab
      await tester.ensureVisible(find.widgetWithText(Tab, 'Review & Approval'));
      await tester.tap(find.widgetWithText(Tab, 'Review & Approval'));
      await tester.pumpAndSettle();
      expect(find.text('Academic Review'), findsOneWidget);
      expect(find.text('APPROVED'), findsOneWidget);
    });

    testWidgets(
        'ContentStudioDashboardScreen integrates Explorer Tree and seamlessly opens Subject Workspace',
        (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final workspaceDetail = StudioSubjectWorkspaceDetail(
        subject: mockCatalog.first,
        curriculumVersion: '2023 Official Syllabus Edition',
        sourceDocumentTitle:
            'TIE English Language Syllabus for Primary Education Standards III-VI (2023)',
        competencies: const [
          StudioCompetencyItem(
            code: '1.1',
            title: 'Greeting and Introducing Oneself',
            isVerified: true,
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            contentStudioMetricsProvider.overrideWith((ref) async => mockMetrics),
            contentStudioCatalogProvider.overrideWith((ref) async => mockCatalog),
            contentStudioHierarchyProvider.overrideWith((ref) async => mockCountries),
            subjectWorkspaceDetailProvider('tie-pri-english-standard3')
                .overrideWith((ref) async => workspaceDetail),
          ],
          child: const MaterialApp(
            home: ContentStudioDashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Top Header
      expect(find.text('Content Management Studio'), findsOneWidget);
      expect(find.text('Authoring & Editorial Cockpit'), findsOneWidget);
      expect(find.text('New Lesson'), findsOneWidget);
      expect(find.text('Media Library'), findsOneWidget);

      // Left Explorer Tree
      expect(find.text('Curriculum Explorer'), findsOneWidget);
      expect(find.text('Tanzania (TZ)'), findsOneWidget);

      // Right Overview Dashboard
      expect(find.text('Total Lessons'), findsOneWidget);
      expect(find.text('75'), findsOneWidget);
      expect(find.text('Published Lessons'), findsOneWidget);
      expect(find.text('55'), findsOneWidget);
      expect(find.text('English Language Standard 3'), findsWidgets);

      // Tap "Open Workspace" to transition to 13-tab Subject Workspace
      await tester.tap(find.text('Open Workspace').first);
      await tester.pumpAndSettle();

      // Breadcrumb and Tabs should appear in the main workspace pane
      expect(find.text('Curriculum'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Competencies'), findsOneWidget);
      expect(find.widgetWithText(Tab, 'Curriculum Mapping'), findsOneWidget);
    });
  });
}
