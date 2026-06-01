import '../models/menu_item.dart';

abstract class MenuRepository {
  Future<List<MenuItemModel>> fetchMenuItems();
  Future<MenuItemModel> addMenuItem(MenuItemModel item);
  Future<MenuItemModel> updateMenuItem(MenuItemModel item);
}
