import '../models/todays_special_settings.dart';

abstract class StoreRepository {
  Future<bool> fetchStoreOpenStatus();

  Future<bool> updateStoreOpenStatus(bool isOpen);

  Future<TodaysSpecialSettings> fetchTodaysSpecialSettings();

  Future<TodaysSpecialSettings> updateTodaysSpecialSettings(
    TodaysSpecialSettings settings,
  );
}
