import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peri_q_app/src/core/app_controller.dart';
import 'package:peri_q_app/src/models/app_auth_session.dart';
import 'package:peri_q_app/src/models/app_preferences.dart';
import 'package:peri_q_app/src/models/menu_item.dart';
import 'package:peri_q_app/src/models/order.dart';
import 'package:peri_q_app/src/models/todays_special_settings.dart';
import 'package:peri_q_app/src/repositories/auth_repository.dart';
import 'package:peri_q_app/src/repositories/menu_repository.dart';
import 'package:peri_q_app/src/repositories/order_repository.dart';
import 'package:peri_q_app/src/repositories/preferences_repository.dart';
import 'package:peri_q_app/src/repositories/store_repository.dart';
import 'package:peri_q_app/src/screens/auth_screen.dart';

void main() {
  group('AppController authentication', () {
    test(
      'registers email users, activates the session, and stores profile data',
      () async {
        final harness = _ControllerHarness();
        await harness.controller.bootstrapFuture;

        await harness.controller.registerWithEmail(
          name: 'New Customer',
          phone: '071 234 5678',
          email: 'new@example.com',
          password: 'secret1',
        );

        expect(harness.controller.isGuest, isFalse);
        expect(harness.controller.userId, 'new-user');
        expect(harness.controller.userEmail, 'new@example.com');
        expect(harness.controller.customerName, 'New Customer');
        expect(harness.controller.customerPhone, '+27 71 234 5678');
        expect(harness.auth.upsertedName, 'New Customer');
        expect(harness.auth.upsertedPhone, '+27 71 234 5678');
        expect(harness.orders.lastUserId, 'new-user');
      },
    );

    test('sends password reset requests through the auth repository', () async {
      final harness = _ControllerHarness();
      await harness.controller.bootstrapFuture;

      await harness.controller.requestPasswordReset(email: 'reset@example.com');

      expect(harness.auth.resetEmail, 'reset@example.com');
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

  group('AuthScreen', () {
    testWidgets('exposes sign up and password reset flows with validation', (
      tester,
    ) async {
      final harness = _ControllerHarness();
      await harness.controller.bootstrapFuture;

      await tester.pumpWidget(
        MaterialApp(home: AuthScreen(controller: harness.controller)),
      );

      expect(
        find.byKey(const ValueKey('auth-create-account-tab')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('auth-forgot-password-button')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('auth-phone-button')), findsOneWidget);
      expect(find.byKey(const ValueKey('auth-guest-button')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('auth-create-account-tab')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('auth-sign-up-name-field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('auth-sign-up-email-field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('auth-sign-up-password-field')),
        findsOneWidget,
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('auth-sign-up-button')),
      );
      await tester.tap(find.byKey(const ValueKey('auth-sign-up-button')));
      await tester.pump();

      expect(find.text('Enter your full name.'), findsOneWidget);
      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(find.text('Use at least 6 characters.'), findsOneWidget);
    });
  });
}

class _ControllerHarness {
  _ControllerHarness({
    List<MenuItemModel>? menuItems,
    TodaysSpecialSettings? todaysSpecialSettings,
  }) : auth = _FakeAuthRepository(),
       menu = _FakeMenuRepository(menuItems ?? const []),
       orders = _FakeOrderRepository(),
       preferences = _FakePreferencesRepository(),
       store = _FakeStoreRepository(todaysSpecialSettings) {
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
  String? resetEmail;
  bool signedOut = false;

  @override
  bool get usesAuthoritativeSessions => true;

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
  Future<AppAuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return AppAuthSession(
      hasSession: true,
      userId: 'email-user',
      email: email,
      customerName: 'Existing Customer',
      customerPhone: '+27 70 000 0000',
    );
  }

  @override
  Future<AppAuthSession> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    return AppAuthSession(
      hasSession: true,
      userId: 'new-user',
      email: email,
      customerName: name,
      customerPhone: phone,
    );
  }

  @override
  Future<void> resetPasswordForEmail({required String email}) async {
    resetEmail = email;
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
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
  _FakeMenuRepository(List<MenuItemModel> seedItems)
    : items = List<MenuItemModel>.from(seedItems);

  final List<MenuItemModel> items;
  int fetchCount = 0;

  @override
  Future<List<MenuItemModel>> fetchMenuItems() async {
    fetchCount += 1;
    return List<MenuItemModel>.from(items);
  }

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
}

class _FakeOrderRepository implements OrderRepository {
  String? lastUserId;

  @override
  Future<List<OrderModel>> fetchOrders({
    String? userId,
    bool includeAll = false,
  }) async {
    lastUserId = userId;
    return const [];
  }

  @override
  Future<OrderModel> createOrder(OrderDraft order, {String? userId}) {
    throw UnimplementedError();
  }

  @override
  Future<OrderModel> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) {
    throw UnimplementedError();
  }
}

class _FakePreferencesRepository implements PreferencesRepository {
  AppPreferences preferences = const AppPreferences();

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
  _FakeStoreRepository(TodaysSpecialSettings? todaysSpecialSettings)
    : todaysSpecialSettings =
          todaysSpecialSettings ?? const TodaysSpecialSettings();

  bool storeOpen = true;
  TodaysSpecialSettings todaysSpecialSettings;

  @override
  Future<bool> fetchStoreOpenStatus() async {
    return storeOpen;
  }

  @override
  Future<bool> updateStoreOpenStatus(bool isOpen) async {
    storeOpen = isOpen;
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
    todaysSpecialSettings = settings;
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
