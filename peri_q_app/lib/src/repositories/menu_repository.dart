import 'dart:typed_data';

import '../models/menu_category.dart';
import '../models/menu_item.dart';

abstract class MenuRepository {
  bool get lastFetchUsedCache => false;

  Future<List<MenuItemModel>> fetchMenuItems();
  Future<MenuItemModel> addMenuItem(MenuItemModel item);
  Future<MenuItemModel> updateMenuItem(MenuItemModel item);
  Future<void> deleteMenuItem(String menuItemId);

  Future<List<MenuCategoryModel>> fetchMenuCategories();
  Future<MenuCategoryModel> addMenuCategory(MenuCategoryModel category);
  Future<MenuCategoryModel> updateMenuCategory(MenuCategoryModel category);
  Future<void> deleteMenuCategory(String categoryId);

  Future<String> uploadMenuItemImage({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  });
}
