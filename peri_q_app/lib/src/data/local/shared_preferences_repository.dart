import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_preferences.dart';
import '../../models/order.dart';
import '../../repositories/preferences_repository.dart';

abstract interface class SecurePreferencesStorage {
  Future<String?> read(String key);

  Future<void> write(String key, String value);
}

class FlutterSecurePreferencesStorage implements SecurePreferencesStorage {
  const FlutterSecurePreferencesStorage();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) {
    return _storage.write(key: key, value: value);
  }
}

class SharedPreferencesRepository implements PreferencesRepository {
  static const _sessionKey = 'has_active_session';
  static const _guestKey = 'session_is_guest';
  // These legacy keys contained personal data in SharedPreferences. Keep the
  // names only so existing installs can migrate them once into secure storage.
  static const _customerNameKey = 'customer_name';
  static const _customerPhoneKey = 'customer_phone';
  static const _storeOpenKey = 'store_open';
  static const _menuCategoryKey = 'selected_menu_category';
  static const _savedAddressesKey = 'saved_addresses';
  static const _defaultAddressKey = 'default_address_id';
  static const _preferredPaymentKey = 'preferred_payment_method';
  static const _secureCustomerNameKey = 'peri_q_customer_name_v1';
  static const _secureCustomerPhoneKey = 'peri_q_customer_phone_v1';
  static const _secureSavedAddressesKey = 'peri_q_saved_addresses_v1';
  static const _secureDefaultAddressKey = 'peri_q_default_address_id_v1';

  SharedPreferencesRepository({SecurePreferencesStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecurePreferencesStorage();

  final SecurePreferencesStorage _secureStorage;
  SharedPreferences? _preferences;

  Future<SharedPreferences> _instance() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  @override
  Future<AppPreferences> loadPreferences() async {
    final preferences = await _instance();
    final customerName = await _readSecureValue(
      preferences: preferences,
      secureKey: _secureCustomerNameKey,
      legacyKey: _customerNameKey,
      fallback: '',
    );
    final customerPhone = await _readSecureValue(
      preferences: preferences,
      secureKey: _secureCustomerPhoneKey,
      legacyKey: _customerPhoneKey,
      fallback: '',
    );
    final savedAddressesValue = await _readSecureValue(
      preferences: preferences,
      secureKey: _secureSavedAddressesKey,
      legacyKey: _savedAddressesKey,
      fallback: '[]',
    );
    final defaultAddressIdValue = await _readSecureValue(
      preferences: preferences,
      secureKey: _secureDefaultAddressKey,
      legacyKey: _defaultAddressKey,
      fallback: '',
    );
    final savedAddresses = _decodeSavedAddresses(savedAddressesValue);
    final defaultAddressId = defaultAddressIdValue.trim().isEmpty
        ? null
        : defaultAddressIdValue;
    return AppPreferences(
      hasReturningSession: preferences.getBool(_sessionKey) ?? false,
      isGuest: preferences.getBool(_guestKey) ?? true,
      customerName: _withoutLegacySample(customerName, 'Thabo Mokhethi'),
      customerPhone: _withoutLegacySample(customerPhone, '+27 71 234 5678'),
      storeOpen: preferences.getBool(_storeOpenKey) ?? true,
      selectedMenuCategory: preferences.getString(_menuCategoryKey) ?? 'All',
      savedAddresses: savedAddresses,
      defaultAddressId:
          savedAddresses.any((address) => address.id == defaultAddressId)
          ? defaultAddressId
          : (savedAddresses.isEmpty ? null : savedAddresses.first.id),
      preferredPaymentMethod: paymentMethodFromCode(
        preferences.getString(_preferredPaymentKey) ?? 'cash_collection',
      ),
    );
  }

  String _withoutLegacySample(String value, String legacySample) {
    final text = value.trim();
    return text == legacySample ? '' : text;
  }

  @override
  Future<void> savePreferences(AppPreferences preferences) async {
    final instance = await _instance();

    // Persist personal data before removing the legacy plaintext values. If
    // secure storage is unavailable, the operation fails without losing the
    // previous data or silently falling back to plaintext storage.
    await Future.wait<void>([
      _secureStorage.write(_secureCustomerNameKey, preferences.customerName),
      _secureStorage.write(_secureCustomerPhoneKey, preferences.customerPhone),
      _secureStorage.write(
        _secureSavedAddressesKey,
        jsonEncode(
          preferences.savedAddresses
              .map((address) => address.toJson())
              .toList(),
        ),
      ),
      _secureStorage.write(
        _secureDefaultAddressKey,
        preferences.defaultAddressId ?? '',
      ),
    ]);
    await Future.wait<bool>([
      instance.remove(_customerNameKey),
      instance.remove(_customerPhoneKey),
      instance.remove(_savedAddressesKey),
      instance.remove(_defaultAddressKey),
    ]);

    await instance.setBool(_sessionKey, preferences.hasReturningSession);
    await instance.setBool(_guestKey, preferences.isGuest);
    await instance.setBool(_storeOpenKey, preferences.storeOpen);
    await instance.setString(
      _menuCategoryKey,
      preferences.selectedMenuCategory,
    );
    await instance.setString(
      _preferredPaymentKey,
      preferences.preferredPaymentMethod.code,
    );
  }

  Future<String> _readSecureValue({
    required SharedPreferences preferences,
    required String secureKey,
    required String legacyKey,
    required String fallback,
  }) async {
    final secureValue = await _secureStorage.read(secureKey);
    if (secureValue != null) {
      // Remove a leftover legacy copy even if a previous migration was
      // interrupted after the secure write completed.
      await preferences.remove(legacyKey);
      return secureValue;
    }

    final value = preferences.getString(legacyKey) ?? fallback;
    await _secureStorage.write(secureKey, value);
    await preferences.remove(legacyKey);
    return value;
  }

  List<SavedAddress> _decodeSavedAddresses(String? value) {
    if (value == null || value.trim().isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(value);
      if (decoded is! List<dynamic>) {
        return const [];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(SavedAddress.fromJson)
          .where((address) => address.id.isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
