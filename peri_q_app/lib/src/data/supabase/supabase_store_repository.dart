import 'package:supabase_flutter/supabase_flutter.dart';

import '../../repositories/store_repository.dart';

class SupabaseStoreRepository implements StoreRepository {
  SupabaseStoreRepository({required this._client});

  final SupabaseClient _client;

  @override
  Future<bool> fetchStoreOpenStatus() async {
    final response = await _client
        .from('app_settings')
        .select('store_open')
        .eq('id', 'default')
        .maybeSingle();

    return response?['store_open'] as bool? ?? true;
  }

  @override
  Future<bool> updateStoreOpenStatus(bool isOpen) async {
    final response = await _client
        .from('app_settings')
        .upsert({'id': 'default', 'store_open': isOpen})
        .select('store_open')
        .single();

    return response['store_open'] as bool? ?? isOpen;
  }
}
