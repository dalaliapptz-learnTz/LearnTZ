// LearnTZ — Independent Learner Auth & Device Service

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/learner_access_models.dart';

class LearnerAuthService {
  LearnerAuthService({
    this.client,
    FlutterSecureStorage? storage,
  })  : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final SupabaseClient? client;
  final FlutterSecureStorage _storage;

  // In-memory fallback for test harnesses or unsupported platforms
  final Map<String, String> _inMemoryStorage = {};
  static const _sessionKey = 'learntz_active_learner_session_v1';

  Future<void> _writeSecure(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (_) {
      _inMemoryStorage[key] = value;
    }
  }

  Future<String?> _readSecure(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value ?? _inMemoryStorage[key];
    } catch (_) {
      return _inMemoryStorage[key];
    }
  }

  Future<void> _deleteSecure(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (_) {
      _inMemoryStorage.remove(key);
    }
  }

  /// Get currently stored active learner session
  Future<LearnerSession?> getActiveSession() async {
    final raw = await _readSecure(_sessionKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final session = LearnerSession.fromJson(json);
      if (session.isExpired) {
        await signOut();
        return null;
      }
      return session;
    } catch (_) {
      await _deleteSecure(_sessionKey);
      return null;
    }
  }

  /// Authenticate child on independent device using Learner ID / Username + PIN / Password
  Future<LearnerSession> authenticateCredential({
    required String identifier,
    required String secret,
    String? deviceIdentifier,
    String? deviceName,
    String? deviceType,
  }) async {
    final devId = deviceIdentifier ?? 'device_${DateTime.now().millisecondsSinceEpoch}';
    final devName = deviceName ?? 'My Device';
    final devType = deviceType ?? 'phone';

    if (client != null) {
      final response = await client!.rpc(
        'authenticate_learner_credential',
        params: {
          'p_identifier': identifier.trim(),
          'p_secret': secret.trim(),
          'p_device_identifier': devId,
          'p_device_name': devName,
          'p_device_type': devType,
        },
      );

      final data = response as Map<String, dynamic>;
      final session = LearnerSession.fromJson(data);
      await _writeSecure(_sessionKey, jsonEncode(session.toJson()));
      return session;
    }

    // Mock fallback for test environment
    final mockSession = LearnerSession(
      sessionToken: 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      sessionExpiresAt: DateTime.now().add(const Duration(days: 30)),
      deviceId: 'mock_dev_id',
      learner: LearnerSessionProfile(
        id: 'mock_learner_id',
        firstName: 'Baraka',
        lastName: 'Mrema',
        fullName: 'Baraka Mrema',
        learnerCode: identifier.toUpperCase(),
        avatarPreset: 'lion_reader',
        countryCode: 'TZ',
        educationSystemId: 'sys-tz',
        curriculumId: 'cur-necta',
        educationLevelId: 'lvl-pri',
        gradeId: 'grd-std4',
        accessMode: LearnerAccessMode.independentDevice,
      ),
    );
    await _writeSecure(_sessionKey, jsonEncode(mockSession.toJson()));
    return mockSession;
  }

  /// Link new device using 6-character single-use activation code (or QR code scan)
  Future<LearnerSession> linkDevice({
    required String tokenCode,
    String? deviceIdentifier,
    String? deviceName,
    String? deviceType,
  }) async {
    final devId = deviceIdentifier ?? 'device_${DateTime.now().millisecondsSinceEpoch}';
    final devName = deviceName ?? 'Independent Tablet';
    final devType = deviceType ?? 'tablet';

    if (client != null) {
      final response = await client!.rpc(
        'link_learner_device',
        params: {
          'p_token_code': tokenCode.trim().toUpperCase(),
          'p_device_identifier': devId,
          'p_device_name': devName,
          'p_device_type': devType,
        },
      );

      final data = response as Map<String, dynamic>;
      final session = LearnerSession.fromJson(data);
      await _writeSecure(_sessionKey, jsonEncode(session.toJson()));
      return session;
    }

    // Mock fallback
    final mockSession = LearnerSession(
      sessionToken: 'mock_link_token_${DateTime.now().millisecondsSinceEpoch}',
      sessionExpiresAt: DateTime.now().add(const Duration(days: 30)),
      deviceId: 'linked_dev_id',
      learner: LearnerSessionProfile(
        id: 'linked_learner_id',
        firstName: 'Neema',
        lastName: 'Kweka',
        fullName: 'Neema Kweka',
        learnerCode: 'LTZ-26-881920',
        avatarPreset: 'cheetah_runner',
        countryCode: 'TZ',
        educationSystemId: 'sys-tz',
        curriculumId: 'cur-necta',
        educationLevelId: 'lvl-pri',
        gradeId: 'grd-std3',
        accessMode: LearnerAccessMode.independentDevice,
      ),
    );
    await _writeSecure(_sessionKey, jsonEncode(mockSession.toJson()));
    return mockSession;
  }

  /// Enter parent-managed child mode on the parent's device
  Future<LearnerSession> startParentManagedChildSession({
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
    final session = LearnerSession(
      sessionToken: 'parent_managed_${DateTime.now().millisecondsSinceEpoch}',
      sessionExpiresAt: DateTime.now().add(const Duration(hours: 12)),
      deviceId: null,
      isParentManagedMode: true,
      learner: LearnerSessionProfile(
        id: learnerId,
        firstName: firstName,
        lastName: lastName,
        fullName: '$firstName $lastName'.trim(),
        learnerCode: learnerCode,
        avatarPreset: avatarPreset,
        countryCode: countryCode,
        educationSystemId: educationSystemId,
        curriculumId: curriculumId,
        educationLevelId: educationLevelId,
        gradeId: gradeId,
        accessMode: LearnerAccessMode.parentManaged,
      ),
    );
    await _writeSecure(_sessionKey, jsonEncode(session.toJson()));
    return session;
  }

  /// Validate session token against backend
  Future<bool> validateSession(String token) async {
    if (client == null) return true;
    try {
      final res = await client!.rpc(
        'validate_learner_session',
        params: {'p_session_token': token},
      );
      final map = res as Map<String, dynamic>;
      return map['valid'] as bool? ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Sign out learner from independent device or child mode
  Future<void> signOut() async {
    await _deleteSecure(_sessionKey);
  }

  // --- PARENT CONTROL METHODS ---

  /// Set learner access arrangement and PIN/password
  Future<Map<String, dynamic>> setAccessMode({
    required String learnerId,
    required LearnerAccessMode accessMode,
    String? username,
    String? credentialType,
    String? secret,
  }) async {
    if (client != null) {
      final res = await client!.rpc(
        'set_learner_access_mode',
        params: {
          'p_learner_id': learnerId,
          'p_access_mode': accessMode.code,
          'p_username': username,
          'p_credential_type': credentialType,
          'p_secret': secret,
        },
      );
      return res as Map<String, dynamic>;
    }
    return {
      'learner_id': learnerId,
      'access_mode': accessMode.code,
      'status': 'active',
    };
  }

  /// Parent generates temporary device linking code (15-min expiry)
  Future<LearnerActivationToken> generateActivationToken(String learnerId) async {
    if (client != null) {
      final res = await client!.rpc(
        'generate_learner_activation_token',
        params: {'p_learner_id': learnerId},
      );
      return LearnerActivationToken.fromJson(res as Map<String, dynamic>);
    }

    return LearnerActivationToken(
      tokenId: 'tok_${DateTime.now().millisecondsSinceEpoch}',
      tokenCode: 'LTZ-${DateTime.now().millisecondsSinceEpoch % 10000}',
      learnerId: learnerId,
      learnerCode: 'LTZ-26-881920',
      learnerName: 'Learner',
      expiresAt: DateTime.now().add(const Duration(minutes: 15)),
      expiresInSeconds: 900,
    );
  }

  /// Parent revokes child device access
  Future<bool> revokeDevice({
    required String learnerId,
    required String deviceId,
  }) async {
    if (client != null) {
      final res = await client!.rpc(
        'revoke_learner_device',
        params: {
          'p_learner_id': learnerId,
          'p_device_id': deviceId,
        },
      );
      return res as bool? ?? true;
    }
    return true;
  }

  /// Parent resets child PIN or password
  Future<bool> resetPin({
    required String learnerId,
    required String newPin,
    String credentialType = 'pin',
  }) async {
    if (client != null) {
      final res = await client!.rpc(
        'reset_learner_pin',
        params: {
          'p_learner_id': learnerId,
          'p_new_pin': newPin,
          'p_credential_type': credentialType,
        },
      );
      return res as bool? ?? true;
    }
    return true;
  }

  /// Parent suspends or reactivates child access
  Future<bool> toggleAccessStatus({
    required String learnerId,
    required bool suspend,
  }) async {
    if (client != null) {
      final res = await client!.rpc(
        'toggle_learner_access_status',
        params: {
          'p_learner_id': learnerId,
          'p_suspend': suspend,
        },
      );
      return res as bool? ?? true;
    }
    return true;
  }

  /// Parent retrieves device management data for a child
  Future<LearnerDeviceManagement> getDeviceManagement(String learnerId) async {
    if (client != null) {
      final res = await client!.rpc(
        'get_learner_device_management',
        params: {'p_learner_id': learnerId},
      );
      return LearnerDeviceManagement.fromJson(res as Map<String, dynamic>);
    }

    return LearnerDeviceManagement(
      learnerId: learnerId,
      learnerCode: 'LTZ-26-881920',
      fullName: 'Baraka Mrema',
      avatarPreset: 'lion_reader',
      accessMode: LearnerAccessMode.parentManaged,
      accessStatus: 'active',
      username: 'baraka-4921',
      hasCredentials: true,
      credentialType: 'pin',
      devices: const [],
    );
  }

  /// Multi-device sync: push local offline events to cloud
  Future<Map<String, dynamic>> syncOfflineActivity({
    required String learnerId,
    String? sessionToken,
    required List<Map<String, dynamic>> events,
  }) async {
    if (client != null) {
      final res = await client!.rpc(
        'sync_learner_device_activity',
        params: {
          'p_learner_id': learnerId,
          'p_session_token': sessionToken,
          'p_events': events,
        },
      );
      return res as Map<String, dynamic>;
    }

    return {
      'learner_id': learnerId,
      'processed_count': events.length,
      'duplicate_count': 0,
    };
  }
}
