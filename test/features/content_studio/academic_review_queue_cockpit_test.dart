import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'package:learntz/features/content_studio/lesson_authoring_models.dart';
import 'package:learntz/features/content_studio/review_queue_models.dart';
import 'package:learntz/features/content_studio/review_queue_providers.dart';
import 'package:learntz/features/content_studio/review_queue_repository.dart';
import 'package:learntz/features/content_studio/screens/academic_review_queue_screen.dart';

class _FakeReviewQueueRepository extends AcademicReviewQueueRepository {
  _FakeReviewQueueRepository({
    this.throwUnauthorized = false,
    this.items = const [],
  });

  final bool throwUnauthorized;
  final List<ReviewQueueItem> items;
  static const String _fakeUserId = 'reviewer-user-1';

  final List<ReviewQueueQuery> recordedQueries = [];
  final List<String> claimedLessonIds = [];

  @override
  String? get currentUserId => _fakeUserId;

  @override
  Future<ReviewQueueSummary> getSummary({String? countryCode}) async {
    if (throwUnauthorized) {
      throw Exception(
        'Permission denied: academic review queue requires academic_reviewer or curriculum_admin role',
      );
    }
    return ReviewQueueSummary(
          countryCode: countryCode ?? 'ALL',
          awaitingReviewCount: 4,
          revisionRequestedCount: 2,
          approvedCount: 3,
          publishedCount: 9,
          assignedToMeCount: 1,
          capabilities: const LessonAuthoringCapabilities(
            canAuthor: false,
            canReview: true,
            canApprove: true,
            canPublish: true,
          ),
          filterOptions: const ReviewQueueFilterOptions(
            countries: [
              ReviewQueueCountryOption(
                countryCode: 'TZ',
                displayName: 'Tanzania',
              ),
              ReviewQueueCountryOption(
                countryCode: 'KE',
                displayName: 'Kenya',
              ),
            ],
            educationLevels: [
              ReviewQueueLevelOption(
                id: 'lvl-pri-tz',
                name: 'Primary Education',
                code: 'PRIMARY',
                countryCode: 'TZ',
              ),
            ],
            grades: [
              ReviewQueueGradeOption(
                id: 'grade-std4-tz',
                name: 'Standard IV',
                code: 'STANDARD_4',
                educationLevelId: 'lvl-pri-tz',
                countryCode: 'TZ',
              ),
              ReviewQueueGradeOption(
                id: 'grade-std5-tz',
                name: 'Standard V',
                code: 'STANDARD_5',
                educationLevelId: 'lvl-pri-tz',
                countryCode: 'TZ',
              ),
            ],
            subjects: [
              ReviewQueueSubjectOption(
                id: 'subj-math-std4',
                name: 'Mathematics',
                code: 'tie-pri-mathematics-standard4',
                gradeId: 'grade-std4-tz',
                gradeName: 'Standard IV',
                educationLevelId: 'lvl-pri-tz',
                countryCode: 'TZ',
              ),
              ReviewQueueSubjectOption(
                id: 'subj-sci-std5',
                name: 'Science',
                code: 'tie-pri-science-standard5',
                gradeId: 'grade-std5-tz',
                gradeName: 'Standard V',
                educationLevelId: 'lvl-pri-tz',
                countryCode: 'TZ',
              ),
            ],
          ),
        );
  }

  @override
  Future<ReviewQueuePage> listQueue(ReviewQueueQuery query) async {
    recordedQueries.add(query);
    if (throwUnauthorized) {
      throw Exception('Permission denied');
    }

    final filtered = items.where((item) {
      if (query.countryCode != null && item.countryCode != query.countryCode) {
        return false;
      }
      if (query.subjectId != null && item.subjectId != query.subjectId) {
        return false;
      }
      if (query.gradeId != null && item.gradeId != query.gradeId) {
        return false;
      }
      if (query.status == 'all_reviewable') {
        if (!['in_review', 'revision_requested', 'approved']
            .contains(item.status)) {
          return false;
        }
      } else if (query.status != 'all' && item.status != query.status) {
        return false;
      }
      if (query.search != null && query.search!.isNotEmpty) {
        final s = query.search!.toLowerCase();
        if (!item.title.toLowerCase().contains(s) &&
            !item.subjectName.toLowerCase().contains(s)) {
          return false;
        }
      }
      if (query.onlyUnassigned && item.reviewerId != null) {
        return false;
      }
      return true;
    }).toList();

    final start = query.offset.clamp(0, filtered.length);
    final end = (start + query.limit).clamp(0, filtered.length);
    final pageItems = filtered.sublist(start, end);

    return ReviewQueuePage(
      totalCount: filtered.length,
      limit: query.limit,
      offset: query.offset,
      hasMore: end < filtered.length,
      items: pageItems,
    );
  }

  @override
  Future<Map<String, dynamic>> assignReviewer({
    required String lessonId,
    String? reviewerId,
  }) async {
    claimedLessonIds.add(lessonId);
    return {
      'lesson_id': lessonId,
      'reviewer_id': reviewerId ?? _fakeUserId,
    };
  }
}

List<ReviewQueueItem> _sampleItems() {
  return [
    ReviewQueueItem(
      lessonId: 'lesson-math-401',
      title: 'Adding and Subtracting Like Fractions',
      countryCode: 'TZ',
      countryName: 'Tanzania',
      curriculumId: 'cur-tie',
      curriculumName: 'TIE National Curriculum',
      educationLevelId: 'lvl-pri-tz',
      educationLevelName: 'Primary Education',
      gradeId: 'grade-std4-tz',
      gradeName: 'Standard IV',
      subjectId: 'subj-math-std4',
      subjectName: 'Mathematics',
      subjectCode: 'tie-pri-mathematics-standard4',
      mainCompetenceCode: '1.0',
      mainCompetenceTitle: 'Demonstrate mastery of elementary mathematical skills',
      specificCompetenceCode: '1.2',
      specificCompetenceTitle: 'Use mathematical operations',
      authorId: 'author-1',
      authorName: 'Amina Juma',
      reviewerId: null,
      reviewerName: null,
      submittedAt: DateTime(2026, 11, 18, 9, 30),
      status: 'in_review',
      isPublished: false,
      versionNumber: 1,
      questionCount: 4,
    ),
    ReviewQueueItem(
      lessonId: 'lesson-sci-501',
      title: 'States of Matter and Physical Changes',
      countryCode: 'TZ',
      countryName: 'Tanzania',
      curriculumId: 'cur-tie',
      curriculumName: 'TIE National Curriculum',
      educationLevelId: 'lvl-pri-tz',
      educationLevelName: 'Primary Education',
      gradeId: 'grade-std5-tz',
      gradeName: 'Standard V',
      subjectId: 'subj-sci-std5',
      subjectName: 'Science',
      subjectCode: 'tie-pri-science-standard5',
      mainCompetenceCode: '1.0',
      mainCompetenceTitle: 'Demonstrate mastery of scientific theories',
      specificCompetenceCode: '1.1',
      specificCompetenceTitle:
          'Demonstrate an understanding of basic concepts of matter, energy and force',
      authorId: 'author-2',
      authorName: 'Baraka Mushi',
      reviewerId: 'reviewer-user-1',
      reviewerName: 'Dr. Neema Kileo',
      submittedAt: DateTime(2026, 11, 17, 14, 15),
      status: 'revision_requested',
      isPublished: false,
      versionNumber: 2,
      reviewNotes: 'Add a classroom observation table for melting ice.',
      questionCount: 5,
    ),
  ];
}

Widget _wrapApp(Widget child, _FakeReviewQueueRepository repo) {
  return ProviderScope(
    overrides: [
      academicReviewQueueRepositoryProvider.overrideWithValue(repo),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  testWidgets(
    'renders DB-derived KPI summary counts and queue items with curriculum metadata',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeReviewQueueRepository(items: _sampleItems());

      await tester.pumpWidget(
        _wrapApp(const AcademicReviewQueueScreen(), repo),
      );
      await tester.pumpAndSettle();

      expect(find.text('Academic Review Queue'), findsOneWidget);
      expect(find.text('Awaiting Review'), findsWidgets);
      expect(find.text('4'), findsWidgets);
      expect(find.text('2'), findsWidgets);
      expect(find.text('3'), findsWidgets);
      expect(find.text('9'), findsWidgets);

      expect(find.text('Adding and Subtracting Like Fractions'), findsOneWidget);
      expect(find.text('States of Matter and Physical Changes'), findsOneWidget);
      expect(find.textContaining('1.2 Use mathematical operations'), findsOneWidget);
      expect(find.textContaining('Amina Juma'), findsOneWidget);
      expect(find.textContaining('Dr. Neema Kileo'), findsOneWidget);
    },
  );

  testWidgets(
    'selecting Open for Review launches AuthorLessonLaunchContext with exact lessonId',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeReviewQueueRepository(items: _sampleItems());
      AuthorLessonLaunchContext? capturedContext;

      await tester.pumpWidget(
        _wrapApp(
          AcademicReviewQueueScreen(
            onOpenLesson: (ctx) async {
              capturedContext = ctx;
            },
          ),
          repo,
        ),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('open-review-btn-lesson-math-401')),
      );
      await tester.tap(find.byKey(const Key('open-review-btn-lesson-math-401')));
      await tester.pumpAndSettle();

      expect(capturedContext, isNotNull);
      expect(capturedContext!.lessonId, 'lesson-math-401');
      expect(capturedContext!.countryCode, 'TZ');
      expect(capturedContext!.subjectId, 'subj-math-std4');
      expect(capturedContext!.sourceEntry, 'academic_review_queue');
    },
  );

  testWidgets(
    'Claim Review assigns lesson via repository and shows confirmation',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeReviewQueueRepository(items: _sampleItems());

      await tester.pumpWidget(
        _wrapApp(const AcademicReviewQueueScreen(), repo),
      );
      await tester.pumpAndSettle();

      final claimBtn = find.byKey(const Key('claim-review-btn-lesson-math-401'));
      expect(claimBtn, findsOneWidget);
      await tester.ensureVisible(claimBtn);
      await tester.tap(claimBtn);
      await tester.pumpAndSettle();

      expect(repo.claimedLessonIds, ['lesson-math-401']);
      expect(
        find.textContaining('Assigned "Adding and Subtracting Like Fractions"'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'KPI click and search filter narrow queue and show empty state when unmatched',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeReviewQueueRepository(items: _sampleItems());

      await tester.pumpWidget(
        _wrapApp(const AcademicReviewQueueScreen(), repo),
      );
      await tester.pumpAndSettle();

      // Click Revision Requested KPI card
      await tester.tap(find.byKey(const Key('kpi-revision-requested')));
      await tester.pumpAndSettle();

      expect(find.text('States of Matter and Physical Changes'), findsOneWidget);
      expect(find.text('Adding and Subtracting Like Fractions'), findsNothing);

      // Search for a non-existent lesson title
      await tester.enterText(
        find.byKey(const Key('review-queue-search-field')),
        'NonExistentLessonXYZ',
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('review-queue-empty-state')), findsOneWidget);
    },
  );

  testWidgets(
    'unauthorized users receive clear Academic Review Access Required state',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeReviewQueueRepository(throwUnauthorized: true);

      await tester.pumpWidget(
        _wrapApp(const AcademicReviewQueueScreen(), repo),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('review-queue-unauthorized')), findsOneWidget);
      expect(find.text('Academic Review Access Required'), findsOneWidget);
    },
  );

  testWidgets(
    'renders cleanly on mobile viewport (390x844) without layout overflow',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final repo = _FakeReviewQueueRepository(items: _sampleItems());

      await tester.pumpWidget(
        _wrapApp(const AcademicReviewQueueScreen(), repo),
      );
      await tester.pumpAndSettle();

      expect(find.text('Academic Review Queue'), findsOneWidget);
      expect(find.text('Adding and Subtracting Like Fractions'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
