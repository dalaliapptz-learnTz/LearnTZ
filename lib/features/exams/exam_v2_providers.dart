import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'exam_v2_models.dart';
import 'exam_v2_repository.dart';

final examCentreV2RepositoryProvider = Provider<ExamCentreV2Repository>(
  (ref) => ExamCentreV2Repository(),
);

final examV2CountriesProvider =
    FutureProvider.autoDispose<List<ExamV2CountryOption>>(
  (ref) => ref.watch(examCentreV2RepositoryProvider).getCountries(),
);

final examV2EducationLevelsProvider = FutureProvider.autoDispose
    .family<List<ExamV2EducationLevelOption>, String>(
  (ref, countryCode) => ref
      .watch(examCentreV2RepositoryProvider)
      .getEducationLevels(countryCode),
);

final examV2GradesProvider = FutureProvider.autoDispose
    .family<List<ExamV2GradeOption>, ({String curriculumId, String levelId})>(
  (ref, params) => ref.watch(examCentreV2RepositoryProvider).getGrades(
        curriculumId: params.curriculumId,
        educationLevelId: params.levelId,
      ),
);

final examV2SubjectsProvider = FutureProvider.autoDispose.family<
    List<ExamV2SubjectOption>,
    ({String curriculumId, String levelId, String gradeId})>(
  (ref, params) => ref.watch(examCentreV2RepositoryProvider).getSubjects(
        curriculumId: params.curriculumId,
        educationLevelId: params.levelId,
        gradeId: params.gradeId,
      ),
);

final examV2ExaminationTypesProvider = FutureProvider.autoDispose.family<
    List<ExamV2ExaminationTypeOption>,
    ({String countryCode, String? levelId})>(
  (ref, params) =>
      ref.watch(examCentreV2RepositoryProvider).getExaminationTypes(
            countryCode: params.countryCode,
            educationLevelId: params.levelId,
          ),
);

final examV2ContextSummaryProvider = FutureProvider.autoDispose
    .family<ExamV2ContextSummary, ExamV2SelectionKey>(
  (ref, selection) => ref
      .watch(examCentreV2RepositoryProvider)
      .getAcademicContextSummary(selection),
);

final examV2ExaminationsListProvider = FutureProvider.autoDispose
    .family<ExamV2ExaminationListResult, ExamV2SelectionKey>(
  (ref, selection) => ref
      .watch(examCentreV2RepositoryProvider)
      .listExaminations(selection),
);

final examV2QuestionsListProvider = FutureProvider.autoDispose
    .family<ExamV2QuestionListResult, ExamV2SelectionKey>(
  (ref, selection) => ref
      .watch(examCentreV2RepositoryProvider)
      .listQuestions(selection),
);

final examV2PaperBuilderProvider = FutureProvider.autoDispose
    .family<ExamV2PaperBuilderBundle, String>(
  (ref, examinationId) => ref
      .watch(examCentreV2RepositoryProvider)
      .getPaperBuilder(examinationId),
);

final examV2ReviewQueueProvider = FutureProvider.autoDispose
    .family<ExamV2ReviewQueueResult, ({String? countryCode, String status})>(
  (ref, params) => ref
      .watch(examCentreV2RepositoryProvider)
      .listReviewQueue(
        countryCode: params.countryCode,
        status: params.status,
      ),
);

final examV2DashboardProvider = FutureProvider.autoDispose.family<
    ExamV2DashboardData,
    ({
      String? countryCode,
      String? educationLevelId,
      String? gradeId,
      String? subjectId,
    })>(
  (ref, params) => ref.watch(examCentreV2RepositoryProvider).getDashboard(
        countryCode: params.countryCode,
        educationLevelId: params.educationLevelId,
        gradeId: params.gradeId,
        subjectId: params.subjectId,
      ),
);
