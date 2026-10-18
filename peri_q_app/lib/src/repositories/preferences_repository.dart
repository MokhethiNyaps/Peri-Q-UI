import '../models/app_preferences.dart';

abstract class PreferencesRepository {
  Future<AppPreferences> loadPreferences();
  Future<void> savePreferences(AppPreferences preferences);
}

abstract interface class CheckoutCartStore {
  Future<Map<String, dynamic>?> loadCheckoutCart(String userId);
  Future<void> saveCheckoutCart(String userId, Map<String, dynamic> value);
}
