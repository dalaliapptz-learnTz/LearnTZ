import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'review_queue_models.dart';
import 'review_queue_repository.dart';

final academicReviewQueueRepositoryProvider =
    Provider<AcademicReviewQueueRepository>(
  (ref) => AcademicReviewQueueRepository(),
);

final reviewQueueSummaryProvider =
    FutureProvider.autoDispose.family<ReviewQueueSummary, String?>(
  (ref, countryCode) async {
    final repo = ref.watch(academicReviewQueueRepositoryProvider);
    return repo.getSummary(countryCode: countryCode);
  },
);

final reviewQueuePageProvider =
    FutureProvider.autoDispose.family<ReviewQueuePage, ReviewQueueQuery>(
  (ref, query) async {
    final repo = ref.watch(academicReviewQueueRepositoryProvider);
    return repo.listQueue(query);
  },
);
