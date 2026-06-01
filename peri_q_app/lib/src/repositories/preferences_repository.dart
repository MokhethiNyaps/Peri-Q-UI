import '../models/app_preferences.dart';

abstract class PreferencesRepository {
  Future<AppPreferences> loadPreferences();
  Future<void> savePreferences(AppPreferences preferences);
}
