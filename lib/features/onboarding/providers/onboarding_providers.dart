import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/country_configuration.dart';
import '../../../core/state/app_providers.dart';
import '../models/child_draft.dart';
import '../models/onboarding_session.dart';
import '../models/onboarding_step.dart';
import '../services/onboarding_repository.dart';
import '../services/onboarding_storage_service.dart';

final onboardingStorageProvider = Provider<OnboardingStorageService>((ref) {
  return OnboardingStorageService();
});

final onboardingRepositoryProvider = Provider<OnboardingRepository?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  if (client == null) return null;
  final env = ref.watch(appEnvironmentProvider);
  return OnboardingRepository(
    client,
    redirectUrl: env.authRedirectUrl,
    environmentName: env.name,
  );
});

final onboardingSessionProvider =
    NotifierProvider<OnboardingSessionNotifier, OnboardingSession>(
  OnboardingSessionNotifier.new,
);

class OnboardingSessionNotifier extends Notifier<OnboardingSession> {
  @override
  OnboardingSession build() {
    return OnboardingSession.initial();
  }

  Future<void> restoreSession() async {
    final storage = ref.read(onboardingStorageProvider);
    final saved = await storage.loadSession();
    if (saved != null && saved.step != OnboardingStep.completed) {
      state = saved;
    }
  }

  void selectCountry(CountryConfiguration country) {
    state = state.copyWith(
      countryCode: country.countryCode,
      countryName: country.displayName,
      step: OnboardingStep.countrySelected,
      lastUpdated: DateTime.now(),
    );
    _persist();
  }

  void setParentRegistration({
    required String fullName,
    required String phoneNumber,
    String? email,
  }) {
    state = state.copyWith(
      parentFullName: fullName,
      phoneNumber: phoneNumber,
      email: email,
      step: OnboardingStep.phoneVerificationPending,
      lastUpdated: DateTime.now(),
    );
    _persist();
  }

  void markPhoneVerified() {
    state = state.copyWith(
      isPhoneVerified: true,
      step: OnboardingStep.phoneVerified,
      lastUpdated: DateTime.now(),
    );
    _persist();
  }

  void addChildDraft(ChildDraft draft) {
    final existingIndex = state.children.indexWhere((c) => c.id == draft.id);
    List<ChildDraft> updatedChildren;
    if (existingIndex >= 0) {
      updatedChildren = List.from(state.children)..[existingIndex] = draft;
    } else {
      updatedChildren = [...state.children, draft];
    }

    state = state.copyWith(
      children: updatedChildren,
      step: OnboardingStep.childrenAdded,
      lastUpdated: DateTime.now(),
    );
    _persist();
  }

  void removeChildDraft(String id) {
    final updated = state.children.where((c) => c.id != id).toList();
    state = state.copyWith(
      children: updated,
      step: updated.isEmpty
          ? OnboardingStep.childRegistrationPending
          : OnboardingStep.childrenAdded,
      lastUpdated: DateTime.now(),
    );
    _persist();
  }

  void setConsent({required bool terms, required bool privacy}) {
    state = state.copyWith(
      acceptedTerms: terms,
      acceptedPrivacy: privacy,
      lastUpdated: DateTime.now(),
    );
    _persist();
  }

  void setStep(OnboardingStep newStep) {
    state = state.copyWith(step: newStep, lastUpdated: DateTime.now());
    _persist();
  }

  Future<void> markCompleted() async {
    state = state.copyWith(
      step: OnboardingStep.completed,
      lastUpdated: DateTime.now(),
    );
    final storage = ref.read(onboardingStorageProvider);
    await storage.clearSession();
  }

  Future<void> reset() async {
    state = OnboardingSession.initial();
    final storage = ref.read(onboardingStorageProvider);
    await storage.clearSession();
  }

  void _persist() {
    final storage = ref.read(onboardingStorageProvider);
    storage.saveSession(state);
  }
}
