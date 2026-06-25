import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_preferences.dart';
import '../../models/order.dart';
import '../../repositories/preferences_repository.dart';

class SharedPreferencesRepository implements PreferencesRepository {
  static const _sessionKey = 'has_active_session';
  static const _guestKey = 'session_is_guest';
  static const _customerNameKey = 'customer_name';
  static const _customerPhoneKey = 'customer_phone';
  static const _storeOpenKey = 'store_open';
  static const _menuCategoryKey = 'selected_menu_category';
  static const _savedAddressesKey = 'saved_addresses';
  static const _defaultAddressKey = 'default_address_id';
  static const _preferredPaymentKey = 'preferred_payment_method';

  SharedPreferences? _preferences;

  Future<SharedPreferences> _instance() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  @override
  Future<AppPreferences> loadPreferences() async {
    final preferences = await _instance();
    final savedAddresses = _decodeSavedAddresses(
      preferences.getString(_savedAddressesKey),
    );
    final defaultAddressId = preferences.getString(_defaultAddressKey);
    return AppPreferences(
      hasReturningSession: preferences.getBool(_sessionKey) ?? false,
      isGuest: preferences.getBool(_guestKey) ?? true,
      customerName: preferences.getString(_customerNameKey) ?? 'Thabo Mokhethi',
      customerPhone:
          preferences.getString(_customerPhoneKey) ?? '+27 71 234 5678',
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

  @override
  Future<void> savePreferences(AppPreferences preferences) async {
    final instance = await _instance();
    await instance.setBool(_sessionKey, preferences.hasReturningSession);
    await instance.setBool(_guestKey, preferences.isGuest);
    await instance.setString(_customerNameKey, preferences.customerName);
    await instance.setString(_customerPhoneKey, preferences.customerPhone);
    await instance.setBool(_storeOpenKey, preferences.storeOpen);
    await instance.setString(
      _menuCategoryKey,
      preferences.selectedMenuCategory,
    );
    await instance.setString(
      _savedAddressesKey,
      jsonEncode(
        preferences.savedAddresses.map((address) => address.toJson()).toList(),
      ),
    );
    final defaultAddressId = preferences.defaultAddressId;
    if (defaultAddressId == null) {
      await instance.remove(_defaultAddressKey);
    } else {
      await instance.setString(_defaultAddressKey, defaultAddressId);
    }
    await instance.setString(
      _preferredPaymentKey,
      preferences.preferredPaymentMethod.code,
    );
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
