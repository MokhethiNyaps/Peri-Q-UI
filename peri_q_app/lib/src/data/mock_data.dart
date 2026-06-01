import '../models/menu_item.dart';
import '../models/order.dart';

class MockData {
  static const categories = [
    'All',
    'Kota',
    'Pap & Meat',
    'Burgers',
    'Drinks',
    'Desserts',
  ];

  static List<MenuItemModel> menuItems() {
    return const [
      MenuItemModel(
        id: 'kota-1',
        name: 'Chicken Kota',
        description: 'Spicy chicken, chips, russian and signature sauce.',
        price: 65,
        category: 'Kota',
        imagePath: 'assets/images/chicken_kota.png',
        addOns: [
          AddOnOption(name: 'Extra Sauce', price: 5),
          AddOnOption(name: 'Extra Chips', price: 10),
        ],
      ),
      MenuItemModel(
        id: 'grill-1',
        name: 'Mixed Grill Plate',
        description: 'Boerewors, steak, lamb chops and pap.',
        price: 120,
        category: 'Pap & Meat',
        imagePath: 'assets/images/mixed_grill.png',
        addOns: [
          AddOnOption(name: 'Extra Pap', price: 12),
          AddOnOption(name: 'Side Salad', price: 18),
        ],
      ),
      MenuItemModel(
        id: 'wings-1',
        name: 'Peri Peri Wings',
        description: 'Sticky charred wings with peri glaze.',
        price: 85,
        category: 'Pap & Meat',
        imagePath: 'assets/images/wings.png',
      ),
      MenuItemModel(
        id: 'burger-1',
        name: 'Beef Burger',
        description: '150g grilled patty with cheese and peri mayo.',
        price: 75,
        category: 'Burgers',
        imagePath: 'assets/images/kota_alt.png',
      ),
      MenuItemModel(
        id: 'pap-1',
        name: 'Pap & Wors',
        description: 'Traditional boerewors with onion and tomato relish.',
        price: 55,
        category: 'Pap & Meat',
        imagePath: 'assets/images/mixed_grill.png',
      ),
      MenuItemModel(
        id: 'drink-1',
        name: 'Cream Soda',
        description: 'Cold 500ml bottle.',
        price: 18,
        category: 'Drinks',
        imagePath: 'assets/images/brand_mark.png',
      ),
      MenuItemModel(
        id: 'dessert-1',
        name: 'Malva Pudding',
        description: 'Warm pudding with creamy vanilla drizzle.',
        price: 35,
        category: 'Desserts',
        imagePath: 'assets/images/kota_alt.png',
      ),
    ];
  }

  static List<OrderModel> initialOrders(List<MenuItemModel> items) {
    final activeItem = CartItemModel(
      id: 'seed-1',
      item: items.first,
      quantity: 2,
      spiceLevel: 'Hot',
      selectedAddOns: const [AddOnOption(name: 'Extra Sauce', price: 5)],
      notes: 'No onions, extra sauce',
    );

    final completedItem = CartItemModel(
      id: 'seed-2',
      item: items[1],
      quantity: 1,
    );

    return [
      OrderModel(
        id: 'order-1047',
        orderNumber: 1047,
        customerName: 'Thabo Mokhethi',
        customerPhone: '+27 71 234 5678',
        items: [activeItem],
        orderType: OrderType.pickup,
        paymentMethod: PaymentMethod.cashCollection,
        totalPrice: activeItem.total,
        status: OrderStatus.preparing,
        createdAt: DateTime.now().subtract(const Duration(minutes: 7)),
        estimatedMinutes: 18,
      ),
      OrderModel(
        id: 'order-1046',
        orderNumber: 1046,
        customerName: 'Nandi Dlamini',
        customerPhone: '+27 82 000 1122',
        items: [completedItem],
        orderType: OrderType.delivery,
        paymentMethod: PaymentMethod.eft,
        totalPrice: completedItem.total + 30,
        status: OrderStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        estimatedMinutes: 0,
        deliveryAddress: '8127 Vilakazi St, Orlando West',
      ),
    ];
  }
}
