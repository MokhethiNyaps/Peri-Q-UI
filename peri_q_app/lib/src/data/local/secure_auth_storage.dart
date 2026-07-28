import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecureAuthLocalStorage extends LocalStorage {
  SecureAuthLocalStorage({required this.sessionKey});

  final String sessionKey;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  Future<void> initialize() async {
    final existing = await _secureStorage.read(key: sessionKey);
    if (existing != null) return;

    final preferences = await SharedPreferences.getInstance();
    final legacySession = preferences.getString(sessionKey);
    if (legacySession == null) return;

    await _secureStorage.write(key: sessionKey, value: legacySession);
    await preferences.remove(sessionKey);
  }

  @override
  Future<String?> accessToken() => _secureStorage.read(key: sessionKey);

  @override
  Future<bool> hasAccessToken() => _secureStorage.containsKey(key: sessionKey);

  @override
  Future<void> persistSession(String persistSessionString) {
    return _secureStorage.write(key: sessionKey, value: persistSessionString);
  }

  @override
  Future<void> removePersistedSession() {
    return _secureStorage.delete(key: sessionKey);
  }
}

class SecurePkceStorage extends GotrueAsyncStorage {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  Future<String?> getItem({required String key}) async {
    final secureValue = await _secureStorage.read(key: key);
    if (secureValue != null) return secureValue;

    final preferences = await SharedPreferences.getInstance();
    final legacyValue = preferences.getString(key);
    if (legacyValue == null) return null;

    await _secureStorage.write(key: key, value: legacyValue);
    await preferences.remove(key);
    return legacyValue;
  }

  @override
  Future<void> removeItem({required String key}) async {
    await _secureStorage.delete(key: key);
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(key);
  }

  @override
  Future<void> setItem({required String key, required String value}) {
    return _secureStorage.write(key: key, value: value);
  }
}
