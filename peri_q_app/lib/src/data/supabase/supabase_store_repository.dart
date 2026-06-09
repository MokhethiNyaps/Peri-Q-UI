import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/todays_special_settings.dart';
import '../../repositories/store_repository.dart';

class SupabaseStoreRepository implements StoreRepository {
  SupabaseStoreRepository({required this._client});

  final SupabaseClient _client;

  static const _settingsId = 'default';

  static const _todaysSpecialSelect = '''
todays_special_enabled,
todays_special_label,
todays_special_title,
todays_special_subtitle,
todays_special_image_path,
todays_special_menu_item_id
''';

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
    try {
      final response = await _client
          .from('app_settings')
          .select(_todaysSpecialSelect)
          .eq('id', _settingsId)
          .maybeSingle();

      return TodaysSpecialSettings.fromJson(response);
    } on PostgrestException catch (error) {
      if (_isMissingTodaysSpecialColumns(error)) {
        return const TodaysSpecialSettings();
      }
      rethrow;
    }
  }

  @override
  Future<TodaysSpecialSettings> updateTodaysSpecialSettings(
    TodaysSpecialSettings settings,
  ) async {
    try {
      final response = await _client
          .from('app_settings')
          .upsert({'id': _settingsId, ...settings.toJson()})
          .select(_todaysSpecialSelect)
          .single();

      return TodaysSpecialSettings.fromJson(response);
    } on PostgrestException catch (error) {
      if (_isMissingTodaysSpecialColumns(error)) {
        throw StateError(
          'Apply the latest supabase/schema.sql before updating Today\'s Special.',
        );
      }
      rethrow;
    }
  }

  bool _isMissingTodaysSpecialColumns(PostgrestException error) {
    return error.code == '42703' || error.message.contains('todays_special_');
  }
}
