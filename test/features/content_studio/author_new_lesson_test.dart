import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:learntz/core/routing/app_router.dart';
import 'package:learntz/features/content_studio/lesson_authoring_models.dart';
import 'package:learntz/features/content_studio/lesson_authoring_providers.dart';
import 'package:learntz/features/content_studio/lesson_authoring_repository.dart';
import 'package:learntz/features/content_studio/screens/author_new_lesson_screen.dart';
import 'package:learntz/features/curriculum/curriculum_explorer_screen.dart';
import 'package:learntz/features/learners/learner_models.dart';
import 'package:learntz/features/learners/learner_providers.dart';
import 'package:learntz/features/learning/learning_models.dart'
    hide LessonContentBlock;
import 'package:learntz/features/learning/learning_providers.dart';
import 'package:learntz/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

class _FakeAuthoringRepository extends LessonAuthoringRepository {
  _FakeAuthoringRepository({
    required this.capabilities,
  });

  final LessonAuthoringCapabilities capabilities;
  int saveCalls = 0;

  @override
  Future<LessonAuthoringCapabilities> getCapabilities({
    String? countryCode,
  }) async =>
      capabilities;

  @override
  Future<LessonAuthoringContext> getAuthoringContext({
    String? countryCode,
    String? curriculumId,
    String? educationLevelId,
    String? gradeId,
    String? subjectId,
  }) async {
    return LessonAuthoringContext(
      countryCode: countryCode ?? 'TZ',
      countryName: 'Tanzania',
      curriculumId: curriculumId ?? 'cur-tie',
      curriculumName: 'TIE National Curriculum',
      curriculumCode: 'TIE',
      curriculumVersionId: 'ver-tie-2023',
      curriculumVersionCode: 'TIE_PRIMARY_2023',
      curriculumVersionName: 'TIE National Primary Curriculum 2023',
      educationLevelId: educationLevelId ?? 'lvl-pri',
      educationLevelName: 'Primary Education',
      gradeId: gradeId,
      gradeName: gradeId == 'grd-3' ? 'Standard 3' : null,
      subjectId: subjectId,
      subjectName: subjectId == 'sub-eng-3' ? 'English Language' : null,
      capabilities: capabilities,
    );
  }

  @override
  Future<List<AuthoringGradeOption>> getGrades({
    required String curriculumId,
    String? educationLevelId,
  }) async =>
      const [
        AuthoringGradeOption(
          id: 'grd-3',
          curriculumId: 'cur-tie',
          educationLevelId: 'lvl-pri',
          educationLevelName: 'Primary Education',
          name: 'Standard 3',
          code: 'STANDARD_3',
          sequence: 3,
          subjectCount: 1,
        ),
        AuthoringGradeOption(
          id: 'grd-4',
          curriculumId: 'cur-tie',
          educationLevelId: 'lvl-pri',
          educationLevelName: 'Primary Education',
          name: 'Standard 4',
          code: 'STANDARD_4',
          sequence: 4,
          subjectCount: 1,
        ),
      ];

  @override
  Future<List<AuthoringSubjectOption>> getSubjects({
    required String curriculumId,
    required String gradeId,
    String? educationLevelId,
  }) async {
    if (gradeId == 'grd-3') {
      return const [
        AuthoringSubjectOption(
          id: 'sub-eng-3',
          countryCode: 'TZ',
          curriculumId: 'cur-tie',
          educationLevelId: 'lvl-pri',
          gradeId: 'grd-3',
          code: 'tie-pri-english-standard3',
          name: 'English Language',
          officialName:
              'English Language Syllabus for Primary Education — Standard III',
          mainCompetenceCount: 3,
        ),
      ];
    }
    return const [
      AuthoringSubjectOption(
        id: 'sub-eng-4',
        countryCode: 'TZ',
        curriculumId: 'cur-tie',
        educationLevelId: 'lvl-pri',
        gradeId: 'grd-4',
        code: 'tie-pri-english-standard4',
        name: 'English Language',
        officialName:
            'English Language Syllabus for Primary Education — Standard IV',
        mainCompetenceCount: 3,
      ),
    ];
  }

  @override
  Future<List<AuthoringMainCompetenceOption>> getMainCompetences({
    required String subjectId,
  }) async =>
      [
        AuthoringMainCompetenceOption(
          id: 'mc-1-$subjectId',
          subjectId: subjectId,
          code: '1.0',
          title: 'Demonstrate mastery of basic English language skills',
          specificCompetenceCount: 2,
        ),
        AuthoringMainCompetenceOption(
          id: 'mc-2-$subjectId',
          subjectId: subjectId,
          code: '2.0',
          title: 'Comprehend oral and written information',
          specificCompetenceCount: 1,
        ),
      ];

  @override
  Future<List<AuthoringSpecificCompetenceOption>> getSpecificCompetences({
    required String mainCompetenceId,
  }) async =>
      [
        AuthoringSpecificCompetenceOption(
          id: 'sc-1-$mainCompetenceId',
          mainCompetenceId: mainCompetenceId,
          subjectId: 'sub-eng-3',
          topicId: 'top-1',
          topicTitle: 'Develop listening and speaking skills',
          code: '1.1',
          title: 'Develop listening and speaking skills',
          periodAllocation: 30,
          assessmentCriteria: 'Dictated words are written correctly',
          sourcePage: 8,
          subtopics: const [
            AuthoringSubtopicOption(
              id: 'subtop-1',
              topicId: 'top-1',
              title: '(a) Write dictated words',
            ),
          ],
        ),
      ];

  @override
  Future<Map<String, dynamic>?> loadLocalRecoveryDraft(String draftKey) async =>
      null;

  @override
  Future<void> saveLocalRecoveryDraft(
    String draftKey,
    Map<String, dynamic> payload,
  ) async {}

  @override
  Future<void> clearLocalRecoveryDraft(String draftKey) async {}

  @override
  Future<Map<String, dynamic>> saveDraft({
    required String countryCode,
    required String curriculumId,
    String? curriculumVersionId,
    required String educationLevelId,
    required String gradeId,
    required String subjectId,
    required String mainCompetenceId,
    required String specificCompetenceId,
    required String topicId,
    String? subtopicId,
    required String title,
    required String bodyMarkdown,
    String? summary,
    int estimatedMinutes = 20,
    String languageCode = 'en',
    String difficultyLevel = 'standard',
    String lessonType = 'core_instruction',
    bool isFreePreview = false,
    List<String> learningObjectives = const [],
    List<LessonLearningOutcome> learningOutcomes = const [],
    List<LessonContentBlock> contentBlocks = const [],
    List<LessonTeachingActivity> teachingActivities = const [],
    String? assessmentCriteria,
    String? changeSummary,
    String? lessonId,
  }) async {
    saveCalls++;
    return {
      'id': lessonId ?? 'saved-lesson-1',
      'title': title,
      'status': 'draft',
      'is_published': false,
      'version_number': saveCalls,
    };
  }

  @override
  Future<Map<String, dynamic>> getLessonBundle(String lessonId) async {
    return {
      'lesson': {
        'id': lessonId,
        'country_code': 'TZ',
        'curriculum_id': 'cur-tie',
        'education_level_id': 'lvl-pri',
        'grade_id': 'grd-3',
        'subject_id': 'sub-eng-3',
        'main_competence_id': 'mc-1-sub-eng-3',
        'specific_competence_id': 'sc-1-mc-1-sub-eng-3',
        'topic_id': 'top-1',
        'title': 'Dictated Words Practice',
        'summary': 'Short summary',
        'body_markdown': '# Dictated Words Practice',
        'estimated_minutes': 25,
        'language_code': 'en',
        'difficulty_level': 'standard',
        'lesson_type': 'core_instruction',
        'is_free_preview': false,
        'learning_objectives': ['Write dictated words'],
        'learning_outcomes': [
          {
            'id': 'lo-1',
            'outcome': 'Spell 10 dictated words accurately',
            'cognitive_level': 'application',
            'assessable': true,
          }
        ],
        'content_blocks': [
          {
            'id': 'b-1',
            'type': 'text_explanation',
            'title': 'Listening Carefully',
            'content': 'Listen twice before writing each word.',
          }
        ],
        'teaching_activities': const [],
        'status': 'draft',
        'is_published': false,
        'version_number': saveCalls == 0 ? 1 : saveCalls,
      },
      'questions': const [],
      'revisions': [
        {
          'id': 'rev-1',
          'version_number': 1,
          'title': 'Dictated Words Practice',
          'status': 'draft',
          'change_summary': 'Initial draft',
        }
      ],
      'review_events': const [],
    };
  }
}

void main() {
  group('Author New Lesson — UI, Cascading Dropdowns & Responsive Tests', () {
    testWidgets(
      'TC-01: Curriculum Explorer shows Create New Lesson entry point for authorized authors',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final fakeRepo = _FakeAuthoringRepository(
          capabilities: const LessonAuthoringCapabilities(
            authenticated: true,
            canAuthor: true,
            roles: ['content_author'],
          ),
        );

        final router = GoRouter(
          initialLocation: AppRoutes.curriculumExplorer,
          routes: [
            GoRoute(
              path: AppRoutes.curriculumExplorer,
              builder: (_, _) => const Scaffold(
                body: CurriculumExplorerScreen(),
              ),
            ),
            GoRoute(
              path: AppRoutes.authorNewLesson,
              builder: (_, state) => AuthorNewLessonScreen(
                launchContext: state.extra as AuthorLessonLaunchContext?,
              ),
            ),
          ],
        );

        const catalog = EducationCatalog(
          countries: [
            EducationCountry(
              code: 'TZ',
              name: 'Tanzania',
            ),
          ],
          systems: [
            EducationSystem(
              id: 'sys-tz',
              countryCode: 'TZ',
              name: 'Tanzania National System',
              isEnabled: true,
            ),
          ],
          curricula: [
            Curriculum(
              id: 'cur-tie',
              countryCode: 'TZ',
              educationSystemId: 'sys-tz',
              code: 'TIE',
              name: 'TIE National Curriculum',
              isEnabled: true,
            ),
          ],
          levels: [
            EducationLevel(
              id: 'lvl-pri',
              curriculumId: 'cur-tie',
              code: 'PRIMARY',
              name: 'Primary Education',
              sequence: 1,
              isEnabled: true,
            ),
          ],
          grades: [
            EducationGrade(
              id: 'grd-3',
              educationLevelId: 'lvl-pri',
              curriculumId: 'cur-tie',
              code: 'STANDARD_3',
              name: 'Standard 3',
              sequence: 3,
              isEnabled: true,
            ),
          ],
          schools: [],
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              lessonAuthoringRepositoryProvider.overrideWithValue(fakeRepo),
              educationCatalogProvider.overrideWith((ref) async => catalog),
              curriculumExplorerTreeProvider.overrideWith(
                (ref, args) async => const <CurriculumExplorerSubject>[],
              ),
            ],
            child: MaterialApp.router(
              routerConfig: router,
              localizationsDelegates: const [
                AppLocalizations.delegate,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(
          find.byKey(const Key('explorer-create-new-lesson-btn')),
          findsOneWidget,
        );

        await tester.tap(find.byKey(const Key('explorer-create-new-lesson-btn')));
        await tester.pumpAndSettle();

        // TC-02: Breadcrumb inherits Tanzania & TIE National Curriculum
        expect(find.text('Author New Lesson'), findsOneWidget);
        expect(
          find.byKey(const Key('curriculum-context-breadcrumb')),
          findsOneWidget,
        );
        expect(
          find.textContaining('TIE National Curriculum (TIE_PRIMARY_2023)'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'TC-02, TC-07, TC-08: Four cascading dropdowns filter, search, and clear dependent selections when parent changes',
      (tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final fakeRepo = _FakeAuthoringRepository(
          capabilities: const LessonAuthoringCapabilities(
            authenticated: true,
            canAuthor: true,
            roles: ['content_author'],
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              lessonAuthoringRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: const MaterialApp(
              home: AuthorNewLessonScreen(
                launchContext: AuthorLessonLaunchContext(
                  countryCode: 'TZ',
                  countryName: 'Tanzania',
                  curriculumId: 'cur-tie',
                  educationLevelId: 'lvl-pri',
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // 1. Open Grade dropdown, search for "Standard 3" (TC-08) and select
        await tester.tap(find.byKey(const Key('author-grade-dropdown')));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('curriculum-dropdown-search-input')),
          'Standard 3',
        );
        await tester.pumpAndSettle();
        expect(find.text('Standard 3'), findsWidgets);
        expect(find.text('Standard 4'), findsNothing);
        await tester.tap(find.text('Standard 3').last);
        await tester.pumpAndSettle();

        // 2. Select Subject
        await tester.tap(find.byKey(const Key('author-subject-dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('English Language').last);
        await tester.pumpAndSettle();

        // 3. Select Main Competence
        await tester.tap(
          find.byKey(const Key('author-main-competence-dropdown')),
        );
        await tester.pumpAndSettle();
        await tester.tap(
          find.text('Demonstrate mastery of basic English language skills'),
        );
        await tester.pumpAndSettle();

        // 4. Select Specific Competence
        await tester.tap(
          find.byKey(const Key('author-specific-competence-dropdown')),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.text('Develop listening and speaking skills'));
        await tester.pumpAndSettle();

        expect(
          find.text('Verified Official Competence Reference'),
          findsOneWidget,
        );

        // TC-07: Changing Grade clears Subject, Main Competence, and Specific Competence
        await tester.tap(find.byKey(const Key('author-grade-dropdown')));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Standard 4'));
        await tester.pumpAndSettle();

        expect(
          find.text('Verified Official Competence Reference'),
          findsNothing,
        );
        expect(find.text('Select Subject first'), findsOneWidget);
        expect(find.text('Select Main Competence first'), findsOneWidget);
      },
    );

    testWidgets(
      'TC-15 & TC-16: Lesson Studio, Preview (Desktop/Mobile toggle), and Responsive Mobile Layout work cleanly',
      (tester) async {
        // Test mobile viewport first (TC-16)
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() => tester.view.resetPhysicalSize());

        final fakeRepo = _FakeAuthoringRepository(
          capabilities: const LessonAuthoringCapabilities(
            authenticated: true,
            canAuthor: true,
            roles: ['content_author'],
          ),
        );

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              lessonAuthoringRepositoryProvider.overrideWithValue(fakeRepo),
            ],
            child: const MaterialApp(
              home: AuthorNewLessonScreen(
                launchContext: AuthorLessonLaunchContext(
                  countryCode: 'TZ',
                  curriculumId: 'cur-tie',
                  educationLevelId: 'lvl-pri',
                  gradeId: 'grd-3',
                  subjectId: 'sub-eng-3',
                  mainCompetenceId: 'mc-1-sub-eng-3',
                  specificCompetenceId: 'sc-1-mc-1-sub-eng-3',
                  topicId: 'top-1',
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Proceed to Lesson Studio
        await tester.ensureVisible(
          find.byKey(const Key('proceed-to-lesson-studio-btn')),
        );
        await tester.tap(find.byKey(const Key('proceed-to-lesson-studio-btn')));
        await tester.pumpAndSettle();

        // Enter lesson title & objective in Section A
        await tester.ensureVisible(
          find.byKey(const Key('studio-lesson-title-input')),
        );
        await tester.enterText(
          find.byKey(const Key('studio-lesson-title-input')),
          'Dictated Words Practice',
        );
        await tester.ensureVisible(
          find.byKey(const Key('studio-objective-input')),
        );
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('studio-objective-input')),
          'Write dictated familiar words accurately',
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();

        // Scroll TabBar horizontally to Preview tab and tap (TC-15)
        await tester.ensureVisible(find.widgetWithText(Tab, 'Preview'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(Tab, 'Preview'));
        await tester.pumpAndSettle();

        expect(find.text('Learner Lesson Preview'), findsOneWidget);
        expect(find.text('Dictated Words Practice'), findsWidgets);
        expect(
          find.text('Write dictated familiar words accurately'),
          findsOneWidget,
        );

        // Toggle Mobile preview mode
        await tester.ensureVisible(find.text('Mobile'));
        await tester.tap(find.text('Mobile'));
        await tester.pumpAndSettle();
        expect(find.text('Dictated Words Practice'), findsWidgets);
      },
    );
  });
}
