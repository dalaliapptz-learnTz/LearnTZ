import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/onboarding_session.dart';

/// Secure Local Persistence Service for LearnTZ Parent Onboarding Draft
class OnboardingStorageService {
  OnboardingStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;
  static const _storageKey = 'learntz_parent_onboarding_session';
  OnboardingSession? _memoryFallback;

  Future<void> saveSession(OnboardingSession session) async {
    _memoryFallback = session;
    try {
      final jsonString = jsonEncode(session.toJson());
      await _storage.write(key: _storageKey, value: jsonString);
    } catch (_) {
      // In web or restricted environments, memory fallback preserves session
    }
  }

  Future<OnboardingSession?> loadSession() async {
    try {
      final jsonString = await _storage.read(key: _storageKey);
      if (jsonString != null && jsonString.isNotEmpty) {
        final Map<String, dynamic> data = jsonDecode(jsonString);
        final session = OnboardingSession.fromJson(data);
        _memoryFallback = session;
        return session;
      }
    } catch (_) {
      // Return memory fallback if storage read fails
    }
    return _memoryFallback;
  }

  Future<void> clearSession() async {
    _memoryFallback = null;
    try {
      await _storage.delete(key: _storageKey);
    } catch (_) {}
  }
}
