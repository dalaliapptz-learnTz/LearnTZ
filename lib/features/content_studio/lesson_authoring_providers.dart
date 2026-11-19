import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth/auth_providers.dart';
import 'lesson_authoring_models.dart';
import 'lesson_authoring_repository.dart';

final lessonAuthoringRepositoryProvider =
    Provider<LessonAuthoringRepository>((ref) {
  try {
    return LessonAuthoringRepository(Supabase.instance.client);
  } catch (_) {
    return LessonAuthoringRepository();
  }
});

final lessonAuthoringCapabilitiesProvider = FutureProvider.autoDispose
    .family<LessonAuthoringCapabilities, String?>((ref, countryCode) async {
  ref.watch(authStateChangesProvider);
  final repo = ref.watch(lessonAuthoringRepositoryProvider);
  return repo.getCapabilities(countryCode: countryCode);
});

final authoringGradesProvider = FutureProvider.autoDispose
    .family<List<AuthoringGradeOption>, ({String curriculumId, String? levelId})>(
  (ref, args) async {
    final repo = ref.watch(lessonAuthoringRepositoryProvider);
    return repo.getGrades(
      curriculumId: args.curriculumId,
      educationLevelId: args.levelId,
    );
  },
);

final authoringSubjectsProvider = FutureProvider.autoDispose.family<
    List<AuthoringSubjectOption>,
    ({String curriculumId, String gradeId, String? levelId})>(
  (ref, args) async {
    final repo = ref.watch(lessonAuthoringRepositoryProvider);
    return repo.getSubjects(
      curriculumId: args.curriculumId,
      gradeId: args.gradeId,
      educationLevelId: args.levelId,
    );
  },
);

final authoringMainCompetencesProvider = FutureProvider.autoDispose
    .family<List<AuthoringMainCompetenceOption>, String>(
  (ref, subjectId) async {
    final repo = ref.watch(lessonAuthoringRepositoryProvider);
    return repo.getMainCompetences(subjectId: subjectId);
  },
);

final authoringSpecificCompetencesProvider = FutureProvider.autoDispose
    .family<List<AuthoringSpecificCompetenceOption>, String>(
  (ref, mainCompetenceId) async {
    final repo = ref.watch(lessonAuthoringRepositoryProvider);
    return repo.getSpecificCompetences(mainCompetenceId: mainCompetenceId);
  },
);
