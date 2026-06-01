import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_preferences.dart';
import '../../repositories/preferences_repository.dart';

class SharedPreferencesRepository implements PreferencesRepository {
  static const _sessionKey = 'has_active_session';
  static const _guestKey = 'session_is_guest';
  static const _customerNameKey = 'customer_name';
  static const _customerPhoneKey = 'customer_phone';
  static const _storeOpenKey = 'store_open';
  static const _menuCategoryKey = 'selected_menu_category';

  SharedPreferences? _preferences;

  Future<SharedPreferences> _instance() async {
    return _preferences ??= await SharedPreferences.getInstance();
  }

  @override
  Future<AppPreferences> loadPreferences() async {
    final preferences = await _instance();
    return AppPreferences(
      hasReturningSession: preferences.getBool(_sessionKey) ?? false,
      isGuest: preferences.getBool(_guestKey) ?? true,
      customerName: preferences.getString(_customerNameKey) ?? 'Thabo Mokhethi',
      customerPhone:
          preferences.getString(_customerPhoneKey) ?? '+27 71 234 5678',
      storeOpen: preferences.getBool(_storeOpenKey) ?? true,
      selectedMenuCategory: preferences.getString(_menuCategoryKey) ?? 'All',
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
  }
}
