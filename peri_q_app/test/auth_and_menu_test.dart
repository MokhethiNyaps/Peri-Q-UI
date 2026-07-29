import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:peri_q_app/src/core/app_controller.dart';
import 'package:peri_q_app/src/models/app_auth_session.dart';
import 'package:peri_q_app/src/models/app_preferences.dart';
import 'package:peri_q_app/src/models/app_settings.dart';
import 'package:peri_q_app/src/models/menu_category.dart';
import 'package:peri_q_app/src/models/menu_item.dart';
import 'package:peri_q_app/src/models/order.dart';
import 'package:peri_q_app/src/models/todays_special_settings.dart';
import 'package:peri_q_app/src/repositories/auth_repository.dart';
import 'package:peri_q_app/src/repositories/menu_repository.dart';
import 'package:peri_q_app/src/repositories/order_repository.dart';
import 'package:peri_q_app/src/repositories/preferences_repository.dart';
import 'package:peri_q_app/src/repositories/store_repository.dart';

void main() {
  group('AppController guest access', () {
    test('creates an anonymous ordering session during bootstrap', () async {
      final harness = _ControllerHarness();

      await harness.controller.bootstrapFuture;

      expect(harness.controller.hasReturningSession, isTrue);
      expect(harness.controller.isGuest, isTrue);
      expect(harness.controller.userId, 'anon-user');
      expect(harness.orders.lastUserId, 'anon-user');
    });
  });

  group('AppController menu management', () {
    test(
      'hides unavailable items from customers while keeping them editable',
      () async {
        final harness = _ControllerHarness(
          menuItems: [
            _menuItem(id: 'available', name: 'Chicken', category: 'Meals'),
            _menuItem(
              id: 'hidden',
              name: 'Secret Plate',
              category: 'Owner',
              isAvailable: false,
            ),
          ],
        );
        await harness.controller.bootstrapFuture;

        expect(harness.controller.menuItems, hasLength(2));
        expect(harness.controller.availableMenuItems.map((item) => item.id), [
          'available',
        ]);
        expect(harness.controller.customerCategories, ['All', 'Meals']);
        expect(harness.controller.categories, ['All', 'Meals', 'Owner']);
      },
    );

    test(
      'reloads menu items from the repository after add, update, and delete',
      () async {
        final harness = _ControllerHarness(
          menuItems: [_menuItem(id: 'kota', name: 'Kota')],
        );
        await harness.controller.bootstrapFuture;
        expect(harness.menu.fetchCount, 1);

        await harness.controller.addMenuItem(
          _menuItem(id: 'wings', name: 'Wings'),
        );
        expect(harness.menu.fetchCount, 2);
        expect(harness.controller.menuItems.map((item) => item.id), [
          'kota',
          'wings',
        ]);

        await harness.controller.updateMenuItem(
          _menuItem(id: 'wings', name: 'Hot Wings', isAvailable: false),
        );
        expect(harness.menu.fetchCount, 3);
        expect(harness.controller.availableMenuItems.map((item) => item.id), [
          'kota',
        ]);

        await harness.controller.deleteMenuItem('kota');
        expect(harness.menu.fetchCount, 4);
        expect(harness.controller.menuItems.map((item) => item.id), ['wings']);
      },
    );
  });

  group('AppController app settings management', () {
    test('loads and updates store hours and availability', () async {
      final harness = _ControllerHarness(
        appSettings: const AppSettings(
          openingTime: '00:00',
          closingTime: '23:59',
        ),
      );
      await harness.controller.bootstrapFuture;

      expect(harness.controller.appSettings.openingTime, '00:00');
      expect(harness.controller.appSettings.closingTime, '23:59');
      expect(harness.controller.isStoreOpenNow, isTrue);

      await harness.controller.updateAppSettings(
        const AppSettings(
          storeOpen: false,
          openingTime: '08:00',
          closingTime: '17:00',
        ),
      );

      expect(harness.store.appSettings.storeOpen, isFalse);
      expect(harness.controller.storeOpen, isFalse);
      expect(harness.controller.appSettings.openingTime, '08:00');
      expect(harness.controller.storeStatusLabel, 'Closed');
    });
  });

  group("AppController Today's Special management", () {
    test(
      'loads and updates promotional settings through the store repository',
      () async {
        final harness = _ControllerHarness(
          todaysSpecialSettings: const TodaysSpecialSettings(
            title: 'Lunch Deal',
            subtitle: 'Kota and chips',
            imagePath: 'assets/images/kota_alt.png',
            menuItemId: 'kota',
          ),
          menuItems: [_menuItem(id: 'kota', name: 'Kota')],
        );
        await harness.controller.bootstrapFuture;

        expect(harness.controller.todaysSpecialSettings.title, 'Lunch Deal');
        expect(harness.controller.todaysSpecialItem?.id, 'kota');

        await harness.controller.updateTodaysSpecialSettings(
          const TodaysSpecialSettings(
            enabled: false,
            title: 'Dinner Deal',
            subtitle: 'Wings and chips',
            imagePath: 'https://example.com/wings.png',
            menuItemId: 'wings',
          ),
        );

        expect(harness.store.todaysSpecialSettings.title, 'Dinner Deal');
        expect(harness.controller.todaysSpecialSettings.enabled, isFalse);
        expect(harness.controller.todaysSpecialItem, isNull);
      },
    );
  });

  group('AppController category management', () {
    test('creates categories and reflects them in customer filters', () async {
      final harness = _ControllerHarness(
        menuCategories: const [
          MenuCategoryModel(id: 'cat-meals', name: 'Meals', sortOrder: 10),
        ],
        menuItems: [_menuItem(id: 'kota', name: 'Kota', category: 'Meals')],
      );
      await harness.controller.bootstrapFuture;

      await harness.controller.addMenuCategory(
        const MenuCategoryModel(
          id: 'cat-drinks',
          name: 'Drinks',
          sortOrder: 20,
        ),
      );

      expect(harness.controller.categories, ['All', 'Meals', 'Drinks']);
      expect(harness.controller.customerCategories, ['All', 'Meals', 'Drinks']);
    });

    test('prioritizes main meal categories for customer filters', () async {
      final harness = _ControllerHarness(
        menuCategories: const [
          MenuCategoryModel(
            id: 'cat-drinks',
            name: 'Cold Drinks',
            sortOrder: 10,
          ),
          MenuCategoryModel(
            id: 'cat-chicken',
            name: 'Chicken Meals',
            sortOrder: 80,
          ),
          MenuCategoryModel(
            id: 'cat-combo',
            name: 'Combo Plates',
            sortOrder: 90,
          ),
          MenuCategoryModel(id: 'cat-wors', name: 'Wors Meals', sortOrder: 100),
        ],
        menuItems: [
          _menuItem(id: 'drink', name: 'Drink', category: 'Cold Drinks'),
          _menuItem(id: 'combo', name: 'Combo', category: 'Combo Plates'),
          _menuItem(id: 'wors', name: 'Wors', category: 'Wors Meals'),
          _menuItem(id: 'chicken', name: 'Chicken', category: 'Chicken Meals'),
        ],
      );
      await harness.controller.bootstrapFuture;

      expect(harness.controller.customerCategories, [
        'All',
        'Combo Plates',
        'Wors Meals',
        'Chicken Meals',
        'Cold Drinks',
      ]);
      expect(harness.controller.featuredItems.map((item) => item.category), [
        'Combo Plates',
        'Wors Meals',
        'Chicken Meals',
        'Cold Drinks',
      ]);
    });

    test(
      'renames categories and updates menu items using that category',
      () async {
        final harness = _ControllerHarness(
          menuCategories: const [
            MenuCategoryModel(id: 'cat-meals', name: 'Meals', sortOrder: 10),
          ],
          menuItems: [_menuItem(id: 'kota', name: 'Kota', category: 'Meals')],
        );
        await harness.controller.bootstrapFuture;

        await harness.controller.updateMenuCategory(
          const MenuCategoryModel(
            id: 'cat-meals',
            name: 'Lunch',
            sortOrder: 10,
          ),
        );

        expect(harness.controller.menuCategories.single.name, 'Lunch');
        expect(harness.controller.menuItems.single.category, 'Lunch');
        expect(harness.controller.customerCategories, ['All', 'Lunch']);
      },
    );

    test('prevents deleting categories still used by menu items', () async {
      final harness = _ControllerHarness(
        menuCategories: const [
          MenuCategoryModel(id: 'cat-meals', name: 'Meals', sortOrder: 10),
        ],
        menuItems: [_menuItem(id: 'kota', name: 'Kota', category: 'Meals')],
      );
      await harness.controller.bootstrapFuture;

      await expectLater(
        harness.controller.deleteMenuCategory(
          harness.controller.menuCategories.single,
        ),
        throwsStateError,
      );
    });

    test('uploads menu item images through the menu repository', () async {
      final harness = _ControllerHarness();
      await harness.controller.bootstrapFuture;

      final url = await harness.controller.uploadMenuItemImage(
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'Kota Photo.png',
        contentType: 'image/png',
      );

      expect(url, 'https://example.test/menu-images/Kota Photo.png');
      expect(harness.menu.lastUploadContentType, 'image/png');
    });
  });

  group('AppController customer preferences', () {
    test(
      'loads and persists saved addresses and payment preferences',
      () async {
        final harness = _ControllerHarness(
          seedPreferences: const AppPreferences(
            savedAddresses: [
              SavedAddress(id: 'home', label: 'Home', address: '1 Main Street'),
            ],
            defaultAddressId: 'home',
            preferredPaymentMethod: PaymentMethod.eft,
          ),
        );
        await harness.controller.bootstrapFuture;

        expect(harness.controller.defaultAddress?.label, 'Home');
        expect(harness.controller.preferredPaymentMethod, PaymentMethod.eft);

        await harness.controller.addSavedAddress(
          label: 'Work',
          address: '2 Office Park',
          notes: 'Reception',
        );
        final workAddress = harness.controller.savedAddresses.last;
        await harness.controller.setDefaultAddress(workAddress.id);
        await harness.controller.setPreferredPaymentMethod(
          PaymentMethod.cashDelivery,
        );

        expect(
          harness.preferences.preferences.defaultAddressId,
          workAddress.id,
        );
        expect(
          harness.preferences.preferences.preferredPaymentMethod,
          PaymentMethod.cashDelivery,
        );

        await harness.controller.deleteSavedAddress(workAddress.id);
        expect(harness.controller.defaultAddress?.id, 'home');
      },
    );
  });

  group('Production order rules', () {
    test('calculates quantities, add-ons, removal and delivery fee', () async {
      final harness = _ControllerHarness(
        appSettings: const AppSettings(
          openingTime: '00:00',
          closingTime: '00:00',
          deliveryFee: 35,
        ),
      );
      await harness.controller.bootstrapFuture;
      final item = MenuItemModel(
        id: 'plate',
        name: 'Grill Plate',
        description: 'A plate',
        price: 60,
        category: 'Meals',
        imagePath: 'assets/images/brand_mark.png',
        addOns: const [AddOnOption(name: 'Extra sauce', price: 5)],
      );

      harness.controller.addToCart(
        item,
        quantity: 2,
        selectedAddOns: item.addOns,
      );
      expect(harness.controller.cartCount, 2);
      expect(harness.controller.subtotal, 130);
      expect(harness.controller.totalFor(OrderType.delivery), 165);

      final cartItem = harness.controller.cart.single;
      harness.controller.incrementCartItem(cartItem);
      expect(harness.controller.subtotal, 195);
      harness.controller.decrementCartItem(cartItem);
      expect(harness.controller.cartCount, 2);
      harness.controller.removeCartItem(cartItem);
      expect(harness.controller.cart, isEmpty);
    });

    test('blocks unavailable items and unavailable fulfilment types', () async {
      final harness = _ControllerHarness(
        appSettings: const AppSettings(
          openingTime: '00:00',
          closingTime: '00:00',
          deliveryAvailable: false,
        ),
      );
      await harness.controller.bootstrapFuture;

      expect(
        () => harness.controller.addToCart(
          _menuItem(id: 'off', name: 'Unavailable', isAvailable: false),
        ),
        throwsStateError,
      );
      expect(harness.controller.canUseOrderType(OrderType.pickup), isTrue);
      expect(harness.controller.canUseOrderType(OrderType.delivery), isFalse);
    });

    test(
      'reuses the idempotency key after a recoverable submission failure',
      () async {
        final harness = _ControllerHarness(
          appSettings: const AppSettings(
            openingTime: '00:00',
            closingTime: '00:00',
          ),
        );
        await harness.controller.bootstrapFuture;
        await harness.controller.startGuestSession();
        await harness.controller.updateCustomer(
          name: 'Guest Customer',
          phone: '0712345678',
        );
        harness.controller.addToCart(_menuItem(id: 'plate', name: 'Plate'));
        harness.orders.failNextCreate = true;

        await expectLater(
          harness.controller.placeOrder(
            orderType: OrderType.pickup,
            paymentMethod: PaymentMethod.cashCollection,
          ),
          throwsA(isA<OrderSubmissionException>()),
        );
        await harness.controller.placeOrder(
          orderType: OrderType.pickup,
          paymentMethod: PaymentMethod.cashCollection,
        );

        expect(harness.orders.requestIds, hasLength(2));
        expect(harness.orders.requestIds.first, harness.orders.requestIds.last);
        expect(harness.controller.cart, isEmpty);
      },
    );

    test('advances only through the supported order status flow', () async {
      final harness = _ControllerHarness();
      await harness.controller.bootstrapFuture;
      final order = _FakeOrderRepository.order(status: OrderStatus.pending);

      await harness.controller.advanceOrderStatus(order);
      expect(harness.orders.updatedStatuses, [OrderStatus.preparing]);
    });
  });
}

class _ControllerHarness {
  _ControllerHarness({
    List<MenuItemModel>? menuItems,
    List<MenuCategoryModel>? menuCategories,
    TodaysSpecialSettings? todaysSpecialSettings,
    AppSettings? appSettings,
    AppPreferences? seedPreferences,
  }) : auth = _FakeAuthRepository(),
       menu = _FakeMenuRepository(
         menuItems ?? const [],
         menuCategories ?? const [],
       ),
       orders = _FakeOrderRepository(),
       preferences = _FakePreferencesRepository(
         seedPreferences ?? const AppPreferences(),
       ),
       store = _FakeStoreRepository(
         appSettings ??
             AppSettings(
               todaysSpecial:
                   todaysSpecialSettings ?? const TodaysSpecialSettings(),
             ),
       ) {
    controller = AppController(
      authRepository: auth,
      menuRepository: menu,
      orderRepository: orders,
      preferencesRepository: preferences,
      storeRepository: store,
    );
  }

  final _FakeAuthRepository auth;
  final _FakeMenuRepository menu;
  final _FakeOrderRepository orders;
  final _FakePreferencesRepository preferences;
  final _FakeStoreRepository store;
  late final AppController controller;
}

class _FakeAuthRepository implements AuthRepository {
  String? upsertedName;
  String? upsertedPhone;

  @override
  Future<AppAuthSession> restoreSession() async {
    return const AppAuthSession.signedOut();
  }

  @override
  Future<AppAuthSession> signInAnonymously() async {
    return const AppAuthSession(
      hasSession: true,
      userId: 'anon-user',
      isAnonymous: true,
    );
  }

  @override
  Future<void> upsertProfile({
    required String name,
    required String phone,
  }) async {
    upsertedName = name;
    upsertedPhone = phone;
  }
}

class _FakeMenuRepository implements MenuRepository {
  _FakeMenuRepository(
    List<MenuItemModel> seedItems,
    List<MenuCategoryModel> seedCategories,
  ) : items = List<MenuItemModel>.from(seedItems),
      categories = List<MenuCategoryModel>.from(seedCategories);

  final List<MenuItemModel> items;
  final List<MenuCategoryModel> categories;
  int fetchCount = 0;
  String? lastUploadContentType;

  @override
  bool get lastFetchUsedCache => false;

  @override
  Future<List<MenuItemModel>> fetchMenuItems() async {
    fetchCount += 1;
    return List<MenuItemModel>.from(items);
  }

  @override
  Stream<void> watchMenuItems() => const Stream<void>.empty();

  @override
  Future<MenuItemModel> addMenuItem(MenuItemModel item) async {
    items.add(item);
    return item;
  }

  @override
  Future<MenuItemModel> updateMenuItem(MenuItemModel item) async {
    final index = items.indexWhere((entry) => entry.id == item.id);
    if (index == -1) {
      throw StateError('Menu item not found.');
    }
    items[index] = item;
    return item;
  }

  @override
  Future<void> deleteMenuItem(String menuItemId) async {
    items.removeWhere((entry) => entry.id == menuItemId);
  }

  @override
  Future<List<MenuCategoryModel>> fetchMenuCategories() async {
    return List<MenuCategoryModel>.from(categories);
  }

  @override
  Stream<void> watchMenuCategories() => const Stream<void>.empty();

  @override
  Future<MenuCategoryModel> addMenuCategory(MenuCategoryModel category) async {
    categories.add(category);
    return category;
  }

  @override
  Future<MenuCategoryModel> updateMenuCategory(
    MenuCategoryModel category,
  ) async {
    final index = categories.indexWhere((entry) => entry.id == category.id);
    if (index == -1) {
      throw StateError('Category not found.');
    }
    categories[index] = category;
    return category;
  }

  @override
  Future<void> deleteMenuCategory(String categoryId) async {
    categories.removeWhere((entry) => entry.id == categoryId);
  }

  @override
  Future<String> uploadMenuItemImage({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    lastUploadContentType = contentType;
    return 'https://example.test/menu-images/$fileName';
  }
}

class _FakeOrderRepository implements OrderRepository {
  String? lastUserId;
  bool failNextCreate = false;
  final List<String> requestIds = [];
  final List<OrderStatus> updatedStatuses = [];

  static OrderModel order({OrderStatus status = OrderStatus.pending}) {
    return OrderModel(
      id: 'order-1',
      orderNumber: 101,
      customerName: 'Customer',
      customerPhone: '+27710000000',
      items: [],
      orderType: OrderType.pickup,
      paymentMethod: PaymentMethod.cashCollection,
      totalPrice: 50,
      status: status,
      createdAt: DateTime(2026),
      estimatedMinutes: 25,
    );
  }

  @override
  Future<List<OrderModel>> fetchOrders({
    String? userId,
    bool includeAll = false,
  }) async {
    lastUserId = userId;
    return const [];
  }

  @override
  Future<OrderModel> createOrder(OrderDraft draft, {String? userId}) async {
    requestIds.add(draft.clientRequestId);
    if (failNextCreate) {
      failNextCreate = false;
      throw const OrderSubmissionException('Temporary failure');
    }
    return OrderModel(
      id: 'order-${requestIds.length}',
      orderNumber: 100 + requestIds.length,
      customerName: draft.customerName,
      customerPhone: draft.customerPhone,
      items: draft.items,
      orderType: draft.orderType,
      paymentMethod: draft.paymentMethod,
      totalPrice: draft.totalPrice,
      status: OrderStatus.pending,
      createdAt: DateTime(2026),
      estimatedMinutes: draft.estimatedMinutes,
      deliveryAddress: draft.deliveryAddress,
    );
  }

  @override
  Future<OrderModel> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    updatedStatuses.add(status);
    return order(status: status);
  }

  @override
  Stream<void> watchOrders({String? userId, bool includeAll = false}) {
    return const Stream<void>.empty();
  }

  @override
  Future<String> uploadPaymentProof({
    required String orderId,
    required List<int> bytes,
    required String fileName,
    required String contentType,
  }) async {
    return 'proof/$orderId/$fileName';
  }
}

class _FakePreferencesRepository implements PreferencesRepository {
  _FakePreferencesRepository(this.preferences);

  AppPreferences preferences;

  @override
  Future<AppPreferences> loadPreferences() async {
    return preferences;
  }

  @override
  Future<void> savePreferences(AppPreferences preferences) async {
    this.preferences = preferences;
  }
}

class _FakeStoreRepository implements StoreRepository {
  _FakeStoreRepository(this.appSettings);

  AppSettings appSettings;

  bool get storeOpen => appSettings.storeOpen;
  TodaysSpecialSettings get todaysSpecialSettings => appSettings.todaysSpecial;

  @override
  Future<AppSettings> fetchAppSettings() async {
    return appSettings;
  }

  @override
  Stream<AppSettings> watchAppSettings() => const Stream<AppSettings>.empty();

  @override
  Future<AppSettings> updateAppSettings(AppSettings settings) async {
    appSettings = settings;
    return appSettings;
  }

  @override
  Future<bool> fetchStoreOpenStatus() async {
    return storeOpen;
  }

  @override
  Future<bool> updateStoreOpenStatus(bool isOpen) async {
    appSettings = appSettings.copyWith(storeOpen: isOpen);
    return storeOpen;
  }

  @override
  Future<TodaysSpecialSettings> fetchTodaysSpecialSettings() async {
    return todaysSpecialSettings;
  }

  @override
  Future<TodaysSpecialSettings> updateTodaysSpecialSettings(
    TodaysSpecialSettings settings,
  ) async {
    appSettings = appSettings.copyWith(todaysSpecial: settings);
    return todaysSpecialSettings;
  }
}

MenuItemModel _menuItem({
  required String id,
  required String name,
  String category = 'Meals',
  bool isAvailable = true,
}) {
  return MenuItemModel(
    id: id,
    name: name,
    description: '$name description',
    price: 50,
    category: category,
    imagePath: 'assets/images/brand_mark.png',
    isAvailable: isAvailable,
  );
}
