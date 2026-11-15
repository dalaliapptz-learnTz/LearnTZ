import 'child_draft.dart';
import 'onboarding_step.dart';

/// Persistent Session State for LearnTZ Parent Onboarding
class OnboardingSession {
  const OnboardingSession({
    this.step = OnboardingStep.notStarted,
    this.countryCode = 'TZ',
    this.countryName = 'Tanzania',
    this.parentFullName,
    this.phoneNumber,
    this.email,
    this.children = const [],
    this.isPhoneVerified = false,
    this.acceptedTerms = false,
    this.acceptedPrivacy = false,
    required this.lastUpdated,
  });

  final OnboardingStep step;
  final String countryCode;
  final String countryName;
  final String? parentFullName;
  final String? phoneNumber;
  final String? email;
  final List<ChildDraft> children;
  final bool isPhoneVerified;
  final bool acceptedTerms;
  final bool acceptedPrivacy;
  final DateTime lastUpdated;

  static OnboardingSession initial() {
    return OnboardingSession(
      lastUpdated: DateTime.now(),
    );
  }

  OnboardingSession copyWith({
    OnboardingStep? step,
    String? countryCode,
    String? countryName,
    String? parentFullName,
    String? phoneNumber,
    String? email,
    List<ChildDraft>? children,
    bool? isPhoneVerified,
    bool? acceptedTerms,
    bool? acceptedPrivacy,
    DateTime? lastUpdated,
  }) {
    return OnboardingSession(
      step: step ?? this.step,
      countryCode: countryCode ?? this.countryCode,
      countryName: countryName ?? this.countryName,
      parentFullName: parentFullName ?? this.parentFullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      children: children ?? this.children,
      isPhoneVerified: isPhoneVerified ?? this.isPhoneVerified,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      acceptedPrivacy: acceptedPrivacy ?? this.acceptedPrivacy,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'step': step.serializedName,
      'country_code': countryCode,
      'country_name': countryName,
      'parent_full_name': parentFullName,
      'phone_number': phoneNumber,
      'email': email,
      'children': children.map((c) => c.toJson()).toList(),
      'is_phone_verified': isPhoneVerified,
      'accepted_terms': acceptedTerms,
      'accepted_privacy': acceptedPrivacy,
      'last_updated': lastUpdated.toIso8601String(),
    };
  }

  factory OnboardingSession.fromJson(Map<String, dynamic> json) {
    return OnboardingSession(
      step: OnboardingStep.fromSerialized(json['step'] as String?),
      countryCode: json['country_code'] as String? ?? 'TZ',
      countryName: json['country_name'] as String? ?? 'Tanzania',
      parentFullName: json['parent_full_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      children: (json['children'] as List<dynamic>?)
              ?.map((item) => ChildDraft.fromJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      isPhoneVerified: json['is_phone_verified'] as bool? ?? false,
      acceptedTerms: json['accepted_terms'] as bool? ?? false,
      acceptedPrivacy: json['accepted_privacy'] as bool? ?? false,
      lastUpdated: json['last_updated'] != null
          ? DateTime.tryParse(json['last_updated'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
