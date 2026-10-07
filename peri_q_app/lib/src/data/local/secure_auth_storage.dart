import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SecureAuthLocalStorage extends LocalStorage {
  SecureAuthLocalStorage({
    required this.sessionKey,
    this.legacySessionKeys = const [],
  });

  final String sessionKey;
  final List<String> legacySessionKeys;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  @override
  Future<void> initialize() async {
    final existing = await _secureStorage.read(key: sessionKey);
    if (existing != null) return;

    final preferences = await SharedPreferences.getInstance();
    final migrationKeys = <String>{sessionKey, ...legacySessionKeys};
    for (final legacyKey in migrationKeys) {
      final secureLegacy = await _secureStorage.read(key: legacyKey);
      final plaintextLegacy = preferences.getString(legacyKey);
      final legacySession = secureLegacy ?? plaintextLegacy;
      if (legacySession == null) continue;

      await _secureStorage.write(key: sessionKey, value: legacySession);
      await preferences.remove(legacyKey);
      if (legacyKey != sessionKey) {
        await _secureStorage.delete(key: legacyKey);
      }
      return;
    }
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
  Future<void> removePersistedSession() async {
    final preferences = await SharedPreferences.getInstance();
    final keys = <String>{sessionKey, ...legacySessionKeys};
    await Future.wait<void>([
      for (final key in keys) _secureStorage.delete(key: key),
    ]);
    await Future.wait<bool>([
      for (final key in keys) preferences.remove(key),
    ]);
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
