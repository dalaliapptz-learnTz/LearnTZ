/// LearnTZ Parent Onboarding State Machine Steps
enum OnboardingStep {
  notStarted,
  countrySelected,
  parentRegistered,
  phoneVerificationPending,
  phoneVerified,
  childRegistrationPending,
  childrenAdded,
  profileConfirmationPending,
  completed;

  String get serializedName {
    switch (this) {
      case OnboardingStep.notStarted:
        return 'NOT_STARTED';
      case OnboardingStep.countrySelected:
        return 'COUNTRY_SELECTED';
      case OnboardingStep.parentRegistered:
        return 'PARENT_REGISTERED';
      case OnboardingStep.phoneVerificationPending:
        return 'PHONE_VERIFICATION_PENDING';
      case OnboardingStep.phoneVerified:
        return 'PHONE_VERIFIED';
      case OnboardingStep.childRegistrationPending:
        return 'CHILD_REGISTRATION_PENDING';
      case OnboardingStep.childrenAdded:
        return 'CHILDREN_ADDED';
      case OnboardingStep.profileConfirmationPending:
        return 'PROFILE_CONFIRMATION_PENDING';
      case OnboardingStep.completed:
        return 'COMPLETED';
    }
  }

  static OnboardingStep fromSerialized(String? value) {
    switch (value) {
      case 'COUNTRY_SELECTED':
        return OnboardingStep.countrySelected;
      case 'PARENT_REGISTERED':
        return OnboardingStep.parentRegistered;
      case 'PHONE_VERIFICATION_PENDING':
        return OnboardingStep.phoneVerificationPending;
      case 'PHONE_VERIFIED':
        return OnboardingStep.phoneVerified;
      case 'CHILD_REGISTRATION_PENDING':
        return OnboardingStep.childRegistrationPending;
      case 'CHILDREN_ADDED':
        return OnboardingStep.childrenAdded;
      case 'PROFILE_CONFIRMATION_PENDING':
        return OnboardingStep.profileConfirmationPending;
      case 'COMPLETED':
        return OnboardingStep.completed;
      case 'NOT_STARTED':
      default:
        return OnboardingStep.notStarted;
    }
  }

  /// Whether the user can navigate forward to this step without skipping prerequisites
  bool canAdvanceTo(OnboardingStep target) {
    return target.index <= index + 1;
  }
}
