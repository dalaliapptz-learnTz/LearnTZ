import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecureSupabaseStorage extends LocalStorage implements GotrueAsyncStorage {
  SecureSupabaseStorage({
    required String supabaseUrl,
    FlutterSecureStorage? storage,
  }) : _storage = storage ?? const FlutterSecureStorage(),
       _keyPrefix = 'learntz.supabase.${Uri.parse(supabaseUrl).host}.';

  final FlutterSecureStorage _storage;
  final String _keyPrefix;
  final Map<String, String> _webStorage = {};

  String get _sessionKey => '${_keyPrefix}session';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async => await accessToken() != null;

  @override
  Future<String?> accessToken() {
    if (kIsWeb) return Future.value(_webStorage[_sessionKey]);
    return _storage.read(key: _sessionKey);
  }

  @override
  Future<void> removePersistedSession() {
    if (kIsWeb) {
      _webStorage.remove(_sessionKey);
      return Future.value();
    }
    return _storage.delete(key: _sessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) {
    if (kIsWeb) {
      _webStorage[_sessionKey] = persistSessionString;
      return Future.value();
    }
    return _storage.write(key: _sessionKey, value: persistSessionString);
  }

  @override
  Future<String?> getItem({required String key}) {
    if (kIsWeb) return Future.value(_webStorage['${_keyPrefix}pkce.$key']);
    return _storage.read(key: '${_keyPrefix}pkce.$key');
  }

  @override
  Future<void> setItem({required String key, required String value}) {
    if (kIsWeb) {
      _webStorage['${_keyPrefix}pkce.$key'] = value;
      return Future.value();
    }
    return _storage.write(key: '${_keyPrefix}pkce.$key', value: value);
  }

  @override
  Future<void> removeItem({required String key}) {
    if (kIsWeb) {
      _webStorage.remove('${_keyPrefix}pkce.$key');
      return Future.value();
    }
    return _storage.delete(key: '${_keyPrefix}pkce.$key');
  }
}
