// LearnTZ — Independent Learner Access & Device Management Models

enum LearnerAccessMode {
  parentManaged('parent_managed', 'Parent Device', 'Child accesses LearnTZ on parent device in supervised child mode'),
  independentDevice('independent_device', 'Own Device', 'Child signs in independently on their own phone, tablet, or computer'),
  setupLater('setup_later', 'Set Up Later', 'Decide device arrangement later from the parent dashboard');

  const LearnerAccessMode(this.code, this.label, this.description);

  final String code;
  final String label;
  final String description;

  static LearnerAccessMode fromCode(String? code) {
    for (final mode in LearnerAccessMode.values) {
      if (mode.code == code) return mode;
    }
    return LearnerAccessMode.parentManaged;
  }
}

class LearnerDevice {
  const LearnerDevice({
    required this.id,
    required this.deviceIdentifier,
    required this.deviceName,
    required this.deviceType,
    required this.isActive,
    required this.lastActiveAt,
    required this.lastSyncAt,
    required this.createdAt,
  });

  factory LearnerDevice.fromJson(Map<String, dynamic> json) {
    return LearnerDevice(
      id: json['id'] as String? ?? '',
      deviceIdentifier: json['device_identifier'] as String? ?? '',
      deviceName: json['device_name'] as String? ?? 'Device',
      deviceType: json['device_type'] as String? ?? 'phone',
      isActive: json['is_active'] as bool? ?? true,
      lastActiveAt: json['last_active_at'] != null
          ? DateTime.tryParse(json['last_active_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      lastSyncAt: json['last_sync_at'] != null
          ? DateTime.tryParse(json['last_sync_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  final String id;
  final String deviceIdentifier;
  final String deviceName;
  final String deviceType;
  final bool isActive;
  final DateTime lastActiveAt;
  final DateTime lastSyncAt;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'device_identifier': deviceIdentifier,
        'device_name': deviceName,
        'device_type': deviceType,
        'is_active': isActive,
        'last_active_at': lastActiveAt.toIso8601String(),
        'last_sync_at': lastSyncAt.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
      };
}

class LearnerActivationToken {
  const LearnerActivationToken({
    required this.tokenId,
    required this.tokenCode,
    required this.learnerId,
    required this.learnerCode,
    required this.learnerName,
    required this.expiresAt,
    required this.expiresInSeconds,
    this.qrPayload,
  });

  factory LearnerActivationToken.fromJson(Map<String, dynamic> json) {
    return LearnerActivationToken(
      tokenId: json['token_id'] as String? ?? '',
      tokenCode: json['token_code'] as String? ?? '',
      learnerId: json['learner_id'] as String? ?? '',
      learnerCode: json['learner_code'] as String? ?? '',
      learnerName: json['learner_name'] as String? ?? '',
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'] as String) ?? DateTime.now().add(const Duration(minutes: 15))
          : DateTime.now().add(const Duration(minutes: 15)),
      expiresInSeconds: (json['expires_in_seconds'] as num?)?.toInt() ?? 900,
      qrPayload: json['qr_payload'] as String?,
    );
  }

  final String tokenId;
  final String tokenCode;
  final String learnerId;
  final String learnerCode;
  final String learnerName;
  final DateTime expiresAt;
  final int expiresInSeconds;
  final String? qrPayload;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'token_id': tokenId,
        'token_code': tokenCode,
        'learner_id': learnerId,
        'learner_code': learnerCode,
        'learner_name': learnerName,
        'expires_at': expiresAt.toIso8601String(),
        'expires_in_seconds': expiresInSeconds,
        'qr_payload': qrPayload,
      };
}

class LearnerSessionProfile {
  const LearnerSessionProfile({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.fullName,
    required this.learnerCode,
    required this.avatarPreset,
    required this.countryCode,
    required this.educationSystemId,
    required this.curriculumId,
    required this.educationLevelId,
    required this.gradeId,
    required this.accessMode,
  });

  factory LearnerSessionProfile.fromJson(Map<String, dynamic> json) {
    return LearnerSessionProfile(
      id: json['id'] as String? ?? '',
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      fullName: json['full_name'] as String? ??
          '${json['first_name'] ?? ''} ${json['last_name'] ?? ''}'.trim(),
      learnerCode: json['learner_code'] as String? ?? '',
      avatarPreset: json['avatar_preset'] as String? ?? 'owl_scholar',
      countryCode: json['country_code'] as String? ?? 'TZ',
      educationSystemId: json['education_system_id'] as String? ?? '',
      curriculumId: json['curriculum_id'] as String? ?? '',
      educationLevelId: json['education_level_id'] as String? ?? '',
      gradeId: json['grade_id'] as String? ?? '',
      accessMode: LearnerAccessMode.fromCode(json['access_mode'] as String?),
    );
  }

  final String id;
  final String firstName;
  final String lastName;
  final String fullName;
  final String learnerCode;
  final String avatarPreset;
  final String countryCode;
  final String educationSystemId;
  final String curriculumId;
  final String educationLevelId;
  final String gradeId;
  final LearnerAccessMode accessMode;

  Map<String, dynamic> toJson() => {
        'id': id,
        'first_name': firstName,
        'last_name': lastName,
        'full_name': fullName,
        'learner_code': learnerCode,
        'avatar_preset': avatarPreset,
        'country_code': countryCode,
        'education_system_id': educationSystemId,
        'curriculum_id': curriculumId,
        'education_level_id': educationLevelId,
        'grade_id': gradeId,
        'access_mode': accessMode.code,
      };
}

class LearnerSession {
  const LearnerSession({
    required this.sessionToken,
    required this.sessionExpiresAt,
    required this.deviceId,
    required this.learner,
    this.isParentManagedMode = false,
  });

  factory LearnerSession.fromJson(Map<String, dynamic> json) {
    return LearnerSession(
      sessionToken: json['session_token'] as String? ?? '',
      sessionExpiresAt: json['session_expires_at'] != null
          ? DateTime.tryParse(json['session_expires_at'] as String) ??
              DateTime.now().add(const Duration(days: 30))
          : DateTime.now().add(const Duration(days: 30)),
      deviceId: json['device_id'] as String?,
      learner: LearnerSessionProfile.fromJson(
        json['learner'] as Map<String, dynamic>? ?? const {},
      ),
      isParentManagedMode: json['is_parent_managed_mode'] as bool? ?? false,
    );
  }

  final String sessionToken;
  final DateTime sessionExpiresAt;
  final String? deviceId;
  final LearnerSessionProfile learner;
  final bool isParentManagedMode;

  bool get isExpired => DateTime.now().isAfter(sessionExpiresAt);

  Map<String, dynamic> toJson() => {
        'session_token': sessionToken,
        'session_expires_at': sessionExpiresAt.toIso8601String(),
        'device_id': deviceId,
        'learner': learner.toJson(),
        'is_parent_managed_mode': isParentManagedMode,
      };
}

class LearnerDeviceManagement {
  const LearnerDeviceManagement({
    required this.learnerId,
    required this.learnerCode,
    required this.fullName,
    required this.avatarPreset,
    required this.accessMode,
    required this.accessStatus,
    required this.username,
    required this.hasCredentials,
    required this.credentialType,
    required this.devices,
    this.activeActivationToken,
  });

  factory LearnerDeviceManagement.fromJson(Map<String, dynamic> json) {
    final rawDevices = json['devices'] as List<dynamic>? ?? const [];
    final rawToken = json['active_activation_token'] as Map<String, dynamic>?;

    return LearnerDeviceManagement(
      learnerId: json['learner_id'] as String? ?? '',
      learnerCode: json['learner_code'] as String? ?? '',
      fullName: json['full_name'] as String? ?? '',
      avatarPreset: json['avatar_preset'] as String? ?? 'owl_scholar',
      accessMode: LearnerAccessMode.fromCode(json['access_mode'] as String?),
      accessStatus: json['access_status'] as String? ?? 'active',
      username: json['username'] as String?,
      hasCredentials: json['has_credentials'] as bool? ?? false,
      credentialType: json['credential_type'] as String?,
      devices: rawDevices
          .map((d) => LearnerDevice.fromJson(d as Map<String, dynamic>))
          .toList(growable: false),
      activeActivationToken:
          rawToken != null ? LearnerActivationToken.fromJson(rawToken) : null,
    );
  }

  final String learnerId;
  final String learnerCode;
  final String fullName;
  final String avatarPreset;
  final LearnerAccessMode accessMode;
  final String accessStatus;
  final String? username;
  final bool hasCredentials;
  final String? credentialType;
  final List<LearnerDevice> devices;
  final LearnerActivationToken? activeActivationToken;

  bool get isSuspended => accessStatus == 'suspended';
}
