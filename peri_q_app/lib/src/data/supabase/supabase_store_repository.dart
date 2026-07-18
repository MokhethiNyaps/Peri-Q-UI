import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/app_settings.dart';
import '../../models/todays_special_settings.dart';
import '../../repositories/store_repository.dart';

class SupabaseStoreRepository implements StoreRepository {
  SupabaseStoreRepository({required this._client});

  final SupabaseClient _client;

  static const _settingsId = 'default';

  static const _settingsSelect = '''
store_open,
pickup_available,
delivery_available,
delivery_fee,
opening_time,
closing_time,
todays_special_enabled,
todays_special_label,
todays_special_title,
todays_special_subtitle,
todays_special_image_path,
todays_special_menu_item_id
''';

  @override
  Future<AppSettings> fetchAppSettings() async {
    try {
      final response = await _client
          .from('app_settings')
          .select(_settingsSelect)
          .eq('id', _settingsId)
          .maybeSingle();

      return AppSettings.fromJson(response);
    } on PostgrestException catch (error) {
      if (_isMissingSettingsColumns(error)) {
        return const AppSettings();
      }
      rethrow;
    }
  }

  @override
  Future<AppSettings> updateAppSettings(AppSettings settings) async {
    try {
      final response = await _client
          .from('app_settings')
          .upsert({'id': _settingsId, ...settings.toJson()})
          .select(_settingsSelect)
          .single();

      return AppSettings.fromJson(response);
    } on PostgrestException catch (error) {
      if (_isMissingSettingsColumns(error)) {
        throw StateError(
          'Apply the latest supabase/schema.sql before updating app settings.',
        );
      }
      rethrow;
    }
  }

  @override
  Future<bool> fetchStoreOpenStatus() async {
    final response = await _client
        .from('app_settings')
        .select('store_open')
        .eq('id', _settingsId)
        .maybeSingle();

    return response?['store_open'] as bool? ?? true;
  }

  @override
  Future<bool> updateStoreOpenStatus(bool isOpen) async {
    final response = await _client
        .from('app_settings')
        .upsert({'id': _settingsId, 'store_open': isOpen})
        .select('store_open')
        .single();

    return response['store_open'] as bool? ?? isOpen;
  }

  @override
  Future<TodaysSpecialSettings> fetchTodaysSpecialSettings() async {
    return (await fetchAppSettings()).todaysSpecial;
  }

  @override
  Future<TodaysSpecialSettings> updateTodaysSpecialSettings(
    TodaysSpecialSettings settings,
  ) async {
    final currentSettings = await fetchAppSettings();
    final updatedSettings = await updateAppSettings(
      currentSettings.copyWith(todaysSpecial: settings),
    );
    return updatedSettings.todaysSpecial;
  }

  bool _isMissingSettingsColumns(PostgrestException error) {
    return error.code == '42703' ||
        error.message.contains('opening_time') ||
        error.message.contains('closing_time') ||
        error.message.contains('todays_special_');
  }
}
