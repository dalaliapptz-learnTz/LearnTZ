// LearnTZ — Independent Learner Auth & Session Providers

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/state/app_providers.dart';
import '../models/learner_access_models.dart';
import '../services/learner_auth_service.dart';

final learnerAuthServiceProvider = Provider<LearnerAuthService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return LearnerAuthService(client: client);
});

class LearnerSessionNotifier extends Notifier<AsyncValue<LearnerSession?>> {
  @override
  AsyncValue<LearnerSession?> build() {
    return const AsyncValue.data(null);
  }

  LearnerAuthService get _service => ref.read(learnerAuthServiceProvider);

  Future<void> init() async {
    try {
      final session = await _service.getActiveSession();
      if (session != null) {
        state = AsyncValue.data(session);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<LearnerSession> signInWithCredential({
    required String identifier,
    required String secret,
    String? deviceName,
    String? deviceType,
  }) async {
    state = const AsyncValue.loading();
    try {
      final session = await _service.authenticateCredential(
        identifier: identifier,
        secret: secret,
        deviceName: deviceName,
        deviceType: deviceType,
      );
      state = AsyncValue.data(session);
      return session;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<LearnerSession> linkDevice({
    required String tokenCode,
    String? deviceName,
    String? deviceType,
  }) async {
    state = const AsyncValue.loading();
    try {
      final session = await _service.linkDevice(
        tokenCode: tokenCode,
        deviceName: deviceName,
        deviceType: deviceType,
      );
      state = AsyncValue.data(session);
      return session;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<LearnerSession> startParentManagedChildMode({
    required String learnerId,
    required String firstName,
    required String lastName,
    required String learnerCode,
    required String avatarPreset,
    required String countryCode,
    required String educationSystemId,
    required String curriculumId,
    required String educationLevelId,
    required String gradeId,
  }) async {
    final session = await _service.startParentManagedChildSession(
      learnerId: learnerId,
      firstName: firstName,
      lastName: lastName,
      learnerCode: learnerCode,
      avatarPreset: avatarPreset,
      countryCode: countryCode,
      educationSystemId: educationSystemId,
      curriculumId: curriculumId,
      educationLevelId: educationLevelId,
      gradeId: gradeId,
    );
    state = AsyncValue.data(session);
    return session;
  }

  Future<void> signOut() async {
    await _service.signOut();
    state = const AsyncValue.data(null);
  }
}

final activeLearnerSessionProvider =
    NotifierProvider<LearnerSessionNotifier, AsyncValue<LearnerSession?>>(
  LearnerSessionNotifier.new,
);

final isChildModeActiveProvider = Provider<bool>((ref) {
  final session = ref.watch(activeLearnerSessionProvider).asData?.value;
  return session != null;
});

final learnerDeviceManagementProvider =
    FutureProvider.family<LearnerDeviceManagement, String>((ref, learnerId) async {
  final service = ref.watch(learnerAuthServiceProvider);
  return service.getDeviceManagement(learnerId);
});
