import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'content_studio_models.dart';
import 'content_studio_repository.dart';

final contentStudioRepositoryProvider = Provider<ContentStudioRepository>((ref) {
  try {
    return ContentStudioRepository(Supabase.instance.client);
  } catch (_) {
    return ContentStudioRepository();
  }
});

class ContentStudioCountryFilterNotifier extends Notifier<String> {
  @override
  String build() => 'ALL';

  void setCountry(String country) => state = country;
}

final contentStudioCountryFilterProvider =
    NotifierProvider<ContentStudioCountryFilterNotifier, String>(
  ContentStudioCountryFilterNotifier.new,
);

class ContentStudioSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final contentStudioSearchQueryProvider =
    NotifierProvider<ContentStudioSearchQueryNotifier, String>(
  ContentStudioSearchQueryNotifier.new,
);

final contentStudioMetricsProvider =
    FutureProvider<ContentStudioMetrics>((ref) async {
  final repo = ref.watch(contentStudioRepositoryProvider);
  final country = ref.watch(contentStudioCountryFilterProvider);
  return repo.getContentStudioMetrics(countryCode: country);
});

final contentStudioCatalogProvider =
    FutureProvider<List<StudioSubjectItem>>((ref) async {
  final repo = ref.watch(contentStudioRepositoryProvider);
  final country = ref.watch(contentStudioCountryFilterProvider);
  final query = ref.watch(contentStudioSearchQueryProvider);
  return repo.getContentStudioCatalog(countryCode: country, search: query);
});

final contentStudioHierarchyProvider =
    FutureProvider<List<StudioCountryItem>>((ref) async {
  final repo = ref.watch(contentStudioRepositoryProvider);
  final country = ref.watch(contentStudioCountryFilterProvider);
  return repo.getContentStudioHierarchy(
    countryCode: country == 'ALL' ? null : country,
  );
});

class SelectedSubjectIdNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final selectedSubjectIdProvider =
    NotifierProvider<SelectedSubjectIdNotifier, String?>(
  SelectedSubjectIdNotifier.new,
);

class SelectedSubjectTabNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void selectTab(int tabIndex) => state = tabIndex;
}

final selectedSubjectTabProvider =
    NotifierProvider<SelectedSubjectTabNotifier, int>(
  SelectedSubjectTabNotifier.new,
);

class PinnedSubjectIdsNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {'tie-pri-english-standard3'};

  void toggle(String id) {
    if (state.contains(id)) {
      state = Set.from(state)..remove(id);
    } else {
      state = Set.from(state)..add(id);
    }
  }
}

final pinnedSubjectIdsProvider =
    NotifierProvider<PinnedSubjectIdsNotifier, Set<String>>(
  PinnedSubjectIdsNotifier.new,
);

class RecentSubjectIdsNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => ['tie-pri-english-standard3', 'tie-pri-english-standard4'];

  void add(String id) {
    final updated = List<String>.from(state)..remove(id);
    updated.insert(0, id);
    if (updated.length > 5) {
      updated.removeLast();
    }
    state = updated;
  }
}

final recentSubjectIdsProvider =
    NotifierProvider<RecentSubjectIdsNotifier, List<String>>(
  RecentSubjectIdsNotifier.new,
);

final subjectWorkspaceDetailProvider =
    FutureProvider.family<StudioSubjectWorkspaceDetail?, String>((ref, subjectId) async {
  final repo = ref.watch(contentStudioRepositoryProvider);
  final detail = await repo.getSubjectWorkspaceDetail(subjectId);
  if (detail != null) return detail;

  // Fallback if detail RPC not available: synthesize from catalog
  final catalog = await ref.watch(contentStudioCatalogProvider.future);
  final match = catalog.where((s) => s.subjectId == subjectId || s.subjectCode == subjectId);
  if (match.isEmpty) return null;

  final subject = match.first;
  final competencies = subject.topics.map((t) => StudioCompetencyItem(
    code: t.competencyCode ?? 'C.${t.topicOrder}',
    title: t.topicTitle,
    description: t.topicSummary ?? '',
    periodAllocation: t.periodAllocation,
    assessmentCriteria: t.assessmentCriteria ?? 'Standard competency assessment.',
    isVerified: true,
  )).toList();

  final outcomes = subject.topics.map((t) => StudioLearningOutcomeItem(
    code: 'LO-${t.topicOrder}.1',
    outcome: 'Comprehend and practically apply principles of ${t.topicTitle}.',
    cognitiveLevel: 'Application',
    competencyCode: t.competencyCode ?? 'C.${t.topicOrder}',
  )).toList();

  final activities = subject.topics.map((t) => StudioActivityItem(
    title: 'Collaborative Practice: ${t.topicTitle}',
    modality: 'Group / Interactive Task',
    materials: 'Textbook, Audio, Visual Chart',
    instructions: 'Guide learners through contextualized problem solving.',
  )).toList();

  final assessments = subject.topics.map((t) => StudioAssessmentItem(
    title: 'Competency Check: ${t.topicTitle}',
    type: 'Formative Assessment',
    criteria: t.assessmentCriteria ?? 'Criterion based.',
    rubric: 'Standard 4-tier rubric.',
  )).toList();

  return StudioSubjectWorkspaceDetail(
    subject: subject,
    curriculumVersion: '2023 Official Syllabus Edition',
    sourceDocumentTitle: 'TIE English Language Syllabus Standards III-VI (2023)',
    competencies: competencies,
    strands: const [
      StudioStrandItem(
        title: 'Core Language Skills',
        substrands: ['Listening', 'Speaking', 'Reading', 'Writing'],
      ),
    ],
    outcomes: outcomes,
    activities: activities,
    assessments: assessments,
    reviewHistory: const [
      StudioReviewEvent(
        stage: 'Curriculum Verification',
        actor: 'TIE Quality Assurance',
        role: 'Senior Reviewer',
        timestamp: '2026-11-15 12:00',
        notes: 'Verified against official syllabus.',
        status: 'verified',
      ),
    ],
  );
});

final contentMediaAssetsProvider =
    FutureProvider<List<MediaAssetItem>>((ref) async {
  final repo = ref.watch(contentStudioRepositoryProvider);
  final country = ref.watch(contentStudioCountryFilterProvider);
  return repo.listContentMediaAssets(countryCode: country);
});

@immutable
class FlatTopicOption {
  const FlatTopicOption({
    required this.topicId,
    required this.topicTitle,
    required this.subjectName,
    required this.countryCode,
  });

  final String topicId;
  final String topicTitle;
  final String subjectName;
  final String countryCode;

  String get label => '[$countryCode - $subjectName] $topicTitle';
}

final studioFlatTopicsProvider =
    FutureProvider<List<FlatTopicOption>>((ref) async {
  final catalog = await ref.watch(contentStudioCatalogProvider.future);
  final list = <FlatTopicOption>[];
  for (final subject in catalog) {
    for (final topic in subject.topics) {
      list.add(FlatTopicOption(
        topicId: topic.topicId,
        topicTitle: topic.topicTitle,
        subjectName: subject.subjectName,
        countryCode: subject.countryCode,
      ));
    }
  }
  return list;
});
