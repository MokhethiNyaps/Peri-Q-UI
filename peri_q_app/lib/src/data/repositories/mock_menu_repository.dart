import '../../models/menu_item.dart';
import '../../repositories/menu_repository.dart';

class MockMenuRepository implements MenuRepository {
  MockMenuRepository({
    required List<MenuItemModel> seedItems,
  }) : _items = List<MenuItemModel>.from(seedItems);

  final List<MenuItemModel> _items;

  @override
  Future<List<MenuItemModel>> fetchMenuItems() async {
    return List<MenuItemModel>.from(_items);
  }

  @override
  Future<MenuItemModel> addMenuItem(MenuItemModel item) async {
    _items.insert(0, item);
    return item;
  }

  @override
  Future<MenuItemModel> updateMenuItem(MenuItemModel item) async {
    final index = _items.indexWhere((existingItem) => existingItem.id == item.id);
    if (index == -1) {
      throw StateError('Menu item ${item.id} was not found.');
    }

    _items[index] = item;
    return item;
  }
}
