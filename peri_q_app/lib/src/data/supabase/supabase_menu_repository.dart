import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/menu_item.dart';
import '../../repositories/menu_repository.dart';

class SupabaseMenuRepository implements MenuRepository {
  SupabaseMenuRepository({required this._client});

  final SupabaseClient _client;

  @override
  Future<List<MenuItemModel>> fetchMenuItems() async {
    final response = await _client
        .from('menu_items')
        .select()
        .order('category')
        .order('name');

    return (response as List<dynamic>)
        .map((row) => _fromRow(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<MenuItemModel> addMenuItem(MenuItemModel item) async {
    final response = await _client
        .from('menu_items')
        .insert(_toRow(item))
        .select()
        .single();

    return _fromRow(response);
  }

  @override
  Future<MenuItemModel> updateMenuItem(MenuItemModel item) async {
    final response = await _client
        .from('menu_items')
        .update(_toRow(item))
        .eq('id', item.id)
        .select()
        .single();

    return _fromRow(response);
  }

  @override
  Future<void> deleteMenuItem(String menuItemId) async {
    await _client.from('menu_items').delete().eq('id', menuItemId);
  }

  MenuItemModel _fromRow(Map<String, dynamic> row) {
    return MenuItemModel(
      id: row['id'] as String? ?? '',
      name: row['name'] as String? ?? '',
      description: row['description'] as String? ?? '',
      price: (row['price'] as num?)?.toDouble() ?? 0,
      category: row['category'] as String? ?? '',
      imagePath: row['image_path'] as String? ?? '',
      isAvailable: row['is_available'] as bool? ?? true,
      prepMinutes: (row['prep_minutes'] as num?)?.toInt() ?? 25,
      spiceLevels:
          (row['spice_levels'] as List<dynamic>?)
              ?.map((level) => level.toString())
              .toList() ??
          const ['Mild', 'Medium', 'Hot', 'Extra Hot'],
      addOns:
          (row['add_ons'] as List<dynamic>?)
              ?.map(
                (entry) => AddOnOption.fromJson(entry as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> _toRow(MenuItemModel item) {
    return {
      'id': item.id,
      'name': item.name,
      'description': item.description,
      'price': item.price,
      'category': item.category,
      'image_path': item.imagePath,
      'is_available': item.isAvailable,
      'prep_minutes': item.prepMinutes,
      'spice_levels': item.spiceLevels,
      'add_ons': item.addOns.map((addOn) => addOn.toJson()).toList(),
    };
  }
}
