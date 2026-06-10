import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/menu_category.dart';
import '../../models/menu_item.dart';
import '../../repositories/menu_repository.dart';

class SupabaseMenuRepository implements MenuRepository {
  SupabaseMenuRepository({required this._client});

  final SupabaseClient _client;
  static const _imageBucket = 'menu-images';

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
    final deletedRow = await _client
        .from('menu_items')
        .delete()
        .eq('id', menuItemId)
        .select('id')
        .maybeSingle();

    if (deletedRow == null) {
      throw StateError(
        'Menu item was not deleted. Check that the item exists and your account has admin access.',
      );
    }
  }

  @override
  Future<List<MenuCategoryModel>> fetchMenuCategories() async {
    try {
      final response = await _client
          .from('menu_categories')
          .select()
          .order('sort_order')
          .order('name');

      return (response as List<dynamic>)
          .map((row) => _categoryFromRow(row as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (error) {
      if (error.code == '42P01' ||
          error.message.contains('menu_categories')) {
        final items = await fetchMenuItems();
        final names = <String>{};
        return [
          for (final item in items)
            if (names.add(item.category))
              MenuCategoryModel(
                id: _categoryIdFromName(item.category),
                name: item.category,
                sortOrder: names.length * 10,
              ),
        ];
      }
      rethrow;
    }
  }

  @override
  Future<MenuCategoryModel> addMenuCategory(
    MenuCategoryModel category,
  ) async {
    final response = await _client
        .from('menu_categories')
        .insert(_categoryToRow(category))
        .select()
        .single();

    return _categoryFromRow(response);
  }

  @override
  Future<MenuCategoryModel> updateMenuCategory(
    MenuCategoryModel category,
  ) async {
    final response = await _client
        .from('menu_categories')
        .update(_categoryToRow(category))
        .eq('id', category.id)
        .select()
        .single();

    return _categoryFromRow(response);
  }

  @override
  Future<void> deleteMenuCategory(String categoryId) async {
    final deletedRow = await _client
        .from('menu_categories')
        .delete()
        .eq('id', categoryId)
        .select('id')
        .maybeSingle();

    if (deletedRow == null) {
      throw StateError(
        'Category was not deleted. Check that it exists and your account has admin access.',
      );
    }
  }

  @override
  Future<String> uploadMenuItemImage({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final cleanName = fileName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
    final storagePath =
        'menu/${DateTime.now().millisecondsSinceEpoch}-$cleanName';

    await _client.storage.from(_imageBucket).uploadBinary(
          storagePath,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );

    return _client.storage.from(_imageBucket).getPublicUrl(storagePath);
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

  MenuCategoryModel _categoryFromRow(Map<String, dynamic> row) {
    return MenuCategoryModel(
      id: row['id'] as String? ?? '',
      name: row['name'] as String? ?? '',
      sortOrder: (row['sort_order'] as num?)?.toInt() ?? 0,
      isActive: row['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> _categoryToRow(MenuCategoryModel category) {
    return {
      'id': category.id,
      'name': category.name,
      'sort_order': category.sortOrder,
      'is_active': category.isActive,
    };
  }

  String _categoryIdFromName(String value) {
    final slug = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    return slug.isEmpty ? 'category' : 'cat-$slug';
  }
}
