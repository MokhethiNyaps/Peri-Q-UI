import '../models/app_settings.dart';
import '../models/todays_special_settings.dart';

abstract class StoreRepository {
  Future<AppSettings> fetchAppSettings();

  Future<AppSettings> updateAppSettings(AppSettings settings);

  Future<bool> fetchStoreOpenStatus();

  Future<bool> updateStoreOpenStatus(bool isOpen);

  Future<TodaysSpecialSettings> fetchTodaysSpecialSettings();

  Future<TodaysSpecialSettings> updateTodaysSpecialSettings(
    TodaysSpecialSettings settings,
  );
}
