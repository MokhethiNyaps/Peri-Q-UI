import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peri_q_app/src/core/app_controller.dart';
import 'package:peri_q_app/src/core/app_theme.dart';
import 'package:peri_q_app/src/screens/customer_shell.dart';
import 'package:peri_q_app/src/core/auth_deep_links.dart';
import 'package:peri_q_app/src/core/payment_session.dart';
import 'package:peri_q_app/src/models/app_auth_session.dart';
import 'package:peri_q_app/src/models/app_preferences.dart';
import 'package:peri_q_app/src/models/app_settings.dart';
import 'package:peri_q_app/src/models/menu_category.dart';
import 'package:peri_q_app/src/models/menu_item.dart';
import 'package:peri_q_app/src/models/order.dart';
import 'package:peri_q_app/src/models/todays_special_settings.dart';
import 'package:peri_q_app/src/repositories/auth_repository.dart';
import 'package:peri_q_app/src/repositories/menu_repository.dart';
import 'package:peri_q_app/src/repositories/notification_repository.dart';
import 'package:peri_q_app/src/repositories/order_repository.dart';
import 'package:peri_q_app/src/repositories/preferences_repository.dart';
import 'package:peri_q_app/src/repositories/store_repository.dart';
import 'package:peri_q_app/src/screens/auth_screen.dart';
import 'package:peri_q_app/src/screens/checkout_screen.dart';
import 'package:peri_q_app/src/screens/reset_password_screen.dart';
import 'package:peri_q_app/src/screens/splash_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    const fontDir = String.fromEnvironment('SCREENSHOT_FONT_DIR');
    if (fontDir.isNotEmpty) {
      for (final font in {
        'Roboto': 'roboto-regular.ttf',
        'MaterialIcons': 'materialicons-regular.otf',
      }.entries) {
        final loader = FontLoader(font.key)
          ..addFont(
            File(
              '$fontDir/${font.value}',
            ).readAsBytes().then(ByteData.sublistView),
          );
        await loader.load();
      }
    }
  });
  for (final size in [const Size(360, 800), const Size(800, 360)]) {
    for (final dark in [false, true]) {
      testWidgets('customer screens ${size.width}x${size.height} dark=$dark', (
        tester,
      ) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final harness = _ControllerHarness(
          menuItems: [
            const MenuItemModel(
              id: 'meal',
              name: 'Flame-grilled chicken',
              description: 'Served with pap and chakalaka',
              price: 70,
              category: 'Meals',
              imagePath: 'assets/images/white-app-icon.png',
            ),
          ],
        );
        await harness.controller.bootstrapFuture;
        harness.controller.addToCart(harness.controller.menuItems.first);
        for (final screen in [
          CustomerShell(controller: harness.controller),
          CheckoutScreen(controller: harness.controller),
        ]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: dark ? AppTheme.darkTheme : AppTheme.lightTheme,
              home: RepaintBoundary(
                key: const ValueKey('preview'),
                child: screen,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          const screenshots = String.fromEnvironment('SCREENSHOT_DIR');
          if (screenshots.isNotEmpty) {
            await tester.runAsync(() async {
              final boundary = tester.renderObject<RenderRepaintBoundary>(
                find.byKey(const ValueKey('preview')),
              );
              final frame = await boundary.toImage(pixelRatio: 1);
              final bytes = await frame.toByteData(
                format: ui.ImageByteFormat.png,
              );
              await File(
                '$screenshots/${screen is CustomerShell ? 'menu' : 'checkout'}-${size.width.toInt()}-${dark ? 'dark' : 'light'}.png',
              ).writeAsBytes(bytes!.buffer.asUint8List());
              frame.dispose();
            });
          }
        }
        expect(find.text('Pay by card'), findsOneWidget);
        expect(find.text('Cash on Collection'), findsNothing);
        await tester.pumpWidget(const SizedBox());
        harness.controller.dispose();
      });
    }
  }

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
        await Future<void>.delayed(Duration.zero);
        expect(harness.notifications.registeredUserIds, ['new-user']);
        expect(harness.notifications.registeredAdminRoles, [isFalse]);
      },
    );

    test('sends password reset requests through the auth repository', () async {
      final harness = _ControllerHarness();
      await harness.controller.bootstrapFuture;

      await harness.controller.requestPasswordReset(email: 'reset@example.com');

      expect(harness.auth.resetEmail, 'reset@example.com');
    });

    test(
      'updates recovered user passwords through the auth repository',
      () async {
        final harness = _ControllerHarness();
        await harness.controller.bootstrapFuture;

        await harness.controller.updatePassword(newPassword: 'new-secret1');

        expect(harness.auth.updatedPassword, 'new-secret1');
      },
    );

    test('deletes the account and clears local personal data', () async {
      final harness = _ControllerHarness();
      await harness.controller.bootstrapFuture;
      await harness.controller.signInWithEmail(
        email: 'customer@example.com',
        password: 'secret1',
      );
      await harness.controller.addSavedAddress(
        label: 'Home',
        address: '1 Main Street',
      );

      await harness.controller.deleteAccount();

      expect(harness.controller.hasReturningSession, isFalse);
      expect(harness.controller.savedAddresses, isEmpty);
      expect(harness.controller.userId, isNull);
      expect(harness.auth.signedOut, isTrue);
      expect(harness.notifications.unregisterCount, 1);
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
      expect(find.byKey(const ValueKey('auth-phone-button')), findsNothing);
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
        find.byKey(const ValueKey('auth-sign-up-phone-field')),
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

    testWidgets('accepts formatted phone numbers and rejects short ones', (
      tester,
    ) async {
      final harness = _ControllerHarness();
      await harness.controller.bootstrapFuture;
      await tester.pumpWidget(
        MaterialApp(home: AuthScreen(controller: harness.controller)),
      );

      await tester.tap(find.byKey(const ValueKey('auth-create-account-tab')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('auth-sign-up-phone-field')),
        '07123',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('auth-sign-up-button')),
      );
      await tester.tap(find.byKey(const ValueKey('auth-sign-up-button')));
      await tester.pump();
      expect(
        find.text('Enter a valid phone number (min 9 digits).'),
        findsOneWidget,
      );

      await tester.enterText(
        find.byKey(const ValueKey('auth-sign-up-phone-field')),
        '+27 73 642 3549',
      );
      await tester.pump();
      expect(
        find.text('Enter a valid phone number (min 9 digits).'),
        findsNothing,
      );
    });
  });

  group('SplashScreen', () {
    testWidgets('waits for the minimum display time before routing', (
      tester,
    ) async {
      final harness = _ControllerHarness();
      await harness.controller.bootstrapFuture;
      await tester.pumpWidget(
        MaterialApp(home: SplashScreen(controller: harness.controller)),
      );

      await tester.pump(const Duration(milliseconds: 1399));
      expect(find.byType(SplashScreen), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 1));
      await tester.pumpAndSettle();
      expect(find.byType(AuthScreen), findsOneWidget);
    });
  });

  group('CheckoutScreen', () {
    testWidgets('reviews items, options, fulfilment and total before payment', (
      tester,
    ) async {
      final harness = _ControllerHarness(
        appSettings: const AppSettings(
          openingTime: '00:00',
          closingTime: '00:00',
        ),
      );
      await harness.controller.bootstrapFuture;
      await harness.controller.startGuestSession();
      await harness.controller.updateCustomer(
        name: 'Test Customer',
        phone: '0712345678',
      );
      harness.controller.addToCart(
        _menuItem(id: 'plate', name: 'Plate'),
        quantity: 2,
        notes: 'No onions',
        selectedAddOns: const [AddOnOption(name: 'Cheese', price: 5)],
      );

      await tester.pumpWidget(
        MaterialApp(home: CheckoutScreen(controller: harness.controller)),
      );
      final review = find.byKey(const ValueKey('checkout-order-review'));
      await tester.ensureVisible(review);

      expect(
        find.descendant(of: review, matching: find.text('2 × Plate')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: review, matching: find.text('+ Cheese (R5)')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: review, matching: find.text('Note: No onions')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: review, matching: find.text('R110')),
        findsWidgets,
      );
      expect(
        find.descendant(
          of: review,
          matching: find.textContaining('Collect from RastasperiQ'),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: review,
          matching: find.textContaining('Contact: Test Customer, '),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('checkout-edit-cart')), findsOneWidget);
      expect(find.text('Cancellations and refunds'), findsOneWidget);
    });

    testWidgets('does not start payment until the policy box is ticked', (
      tester,
    ) async {
      final delayedOrders = _DelayedOrderRepository();
      final harness = _ControllerHarness(
        orderRepository: delayedOrders,
        appSettings: const AppSettings(
          openingTime: '00:00',
          closingTime: '00:00',
        ),
      );
      await harness.controller.bootstrapFuture;
      await harness.controller.startGuestSession();
      await harness.controller.updateCustomer(
        name: 'Test Customer',
        phone: '0712345678',
      );
      harness.controller.addToCart(_menuItem(id: 'plate', name: 'Plate'));

      await tester.pumpWidget(
        MaterialApp(home: CheckoutScreen(controller: harness.controller)),
      );
      await tester.tap(
        find.byKey(const ValueKey('checkout-place-order-button')),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('checkout-placing')), findsNothing);
      expect(
        find.text('Accept the terms and conditions to continue.'),
        findsOneWidget,
      );
    });

    testWidgets('shows a spinner while an order is being submitted', (
      tester,
    ) async {
      final delayedOrders = _DelayedOrderRepository();
      final harness = _ControllerHarness(
        orderRepository: delayedOrders,
        appSettings: const AppSettings(
          openingTime: '00:00',
          closingTime: '00:00',
        ),
      );
      await harness.controller.bootstrapFuture;
      await harness.controller.startGuestSession();
      await harness.controller.updateCustomer(
        name: 'Test Customer',
        phone: '0712345678',
      );
      harness.controller.addToCart(_menuItem(id: 'plate', name: 'Plate'));

      await tester.pumpWidget(
        MaterialApp(home: CheckoutScreen(controller: harness.controller)),
      );
      await _acceptPolicies(tester);
      await tester.tap(
        find.byKey(const ValueKey('checkout-place-order-button')),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('checkout-placing')), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      delayedOrders.completeSubmission();
      await tester.pumpAndSettle();
      expect(find.textContaining('Order Placed!'), findsOneWidget);
    });

    testWidgets('offers reopen and cancel while the payment sheet is open', (
      tester,
    ) async {
      final delayedOrders = _DelayedOrderRepository();
      final harness = _ControllerHarness(
        orderRepository: delayedOrders,
        appSettings: const AppSettings(
          openingTime: '00:00',
          closingTime: '00:00',
        ),
      );
      await harness.controller.bootstrapFuture;
      await harness.controller.startGuestSession();
      await harness.controller.updateCustomer(
        name: 'Test Customer',
        phone: '0712345678',
      );
      harness.controller.addToCart(_menuItem(id: 'plate', name: 'Plate'));
      addTearDown(CardPaymentSession.instance.finish);

      await tester.pumpWidget(
        MaterialApp(home: CheckoutScreen(controller: harness.controller)),
      );
      await _acceptPolicies(tester);
      await tester.tap(
        find.byKey(const ValueKey('checkout-place-order-button')),
      );
      await tester.pump();
      expect(find.text('Preparing secure payment…'), findsOneWidget);

      final returns = <PaymentReturn>[];
      final subscription = CardPaymentSession.instance.returns.listen(
        returns.add,
      );
      addTearDown(subscription.cancel);
      CardPaymentSession.instance.opened(
        orderId: 'order-1',
        checkoutUrl: Uri.parse('https://pay.example/checkout/1'),
      );
      await tester.pumpAndSettle();
      expect(find.text('Finish paying in the secure window'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('checkout-reopen-payment')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('checkout-cancel-payment')));
      await tester.pump();
      expect(returns.single.result, PaymentReturnResult.abandoned);

      CardPaymentSession.instance.confirming();
      await tester.pump();
      expect(find.text('Confirming your payment…'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('checkout-reopen-payment')),
        findsNothing,
      );

      delayedOrders.completeSubmission();
      await tester.pumpAndSettle();
    });
  });

  group('Password recovery', () {
    test('recognizes only the configured password recovery deep link', () {
      expect(
        AuthDeepLinks.isPasswordReset(
          Uri.parse('rastasperiq://reset-password?code=abc'),
        ),
        isTrue,
      );
      expect(
        AuthDeepLinks.isPasswordReset(
          Uri.parse('rastasperiq://another-screen?code=abc'),
        ),
        isFalse,
      );
      expect(
        AuthDeepLinks.isPasswordReset(
          Uri.parse('https://example.com/reset-password?code=abc'),
        ),
        isFalse,
      );
    });

    testWidgets('updates the password and returns the user to sign in', (
      tester,
    ) async {
      final harness = _ControllerHarness();
      await harness.controller.bootstrapFuture;

      await tester.pumpWidget(
        MaterialApp(home: ResetPasswordScreen(controller: harness.controller)),
      );

      await tester.enterText(
        find.byKey(const ValueKey('reset-password-field')),
        'new-secret1',
      );
      await tester.enterText(
        find.byKey(const ValueKey('reset-password-confirm-field')),
        'new-secret1',
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('reset-password-submit-button')),
      );
      await tester.tap(
        find.byKey(const ValueKey('reset-password-submit-button')),
      );
      await tester.pump();
      await tester.runAsync(() async {
        for (var attempt = 0; attempt < 100; attempt += 1) {
          if (harness.auth.signedOut) {
            return;
          }
          await Future<void>.delayed(const Duration(milliseconds: 5));
        }
      });
      await tester.pumpAndSettle();

      expect(harness.auth.updatedPassword, 'new-secret1');
      expect(harness.auth.signedOut, isTrue);
      expect(find.byType(AuthScreen), findsOneWidget);
    });
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
        expect(harness.controller.preferredPaymentMethod, PaymentMethod.yoco);

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
          PaymentMethod.yoco,
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
        imagePath: 'assets/images/white-app-icon.png',
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
      'requires and submits contact and address details for delivery orders',
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
          name: 'Delivery Customer',
          phone: '0712345678',
        );
        harness.controller.addToCart(_menuItem(id: 'plate', name: 'Plate'));

        await expectLater(
          harness.controller.placeOrder(
            orderType: OrderType.delivery,
            paymentMethod: PaymentMethod.yoco,
          ),
          throwsA(isA<OrderSubmissionException>()),
        );
        expect(harness.orders.lastDraft, isNull);

        await harness.controller.placeOrder(
          orderType: OrderType.delivery,
          paymentMethod: PaymentMethod.yoco,
          deliveryAddress:
              '12 Main Street, Bloemfontein\nRing the side gate bell.',
        );

        expect(harness.orders.lastDraft?.customerName, 'Delivery Customer');
        expect(harness.orders.lastDraft?.customerPhone, '+27 712345678');
        expect(harness.orders.lastDraft?.orderType, OrderType.delivery);
        expect(
          harness.orders.lastDraft?.deliveryAddress,
          '12 Main Street, Bloemfontein\nRing the side gate bell.',
        );
      },
    );

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
            paymentMethod: PaymentMethod.yoco,
          ),
          throwsA(isA<OrderSubmissionException>()),
        );
        await harness.controller.placeOrder(
          orderType: OrderType.pickup,
          paymentMethod: PaymentMethod.yoco,
        );

        expect(harness.orders.requestIds, hasLength(2));
        expect(harness.orders.requestIds.first, harness.orders.requestIds.last);
        expect(harness.orders.lastDraft?.orderType, OrderType.pickup);
        expect(harness.orders.lastDraft?.deliveryAddress, isNull);
        expect(harness.controller.cart, isEmpty);
        await Future<void>.delayed(Duration.zero);
        expect(harness.notifications.newOrderIds, ['order-2']);
      },
    );

    test('advances only through the supported order status flow', () async {
      final harness = _ControllerHarness();
      await harness.controller.bootstrapFuture;
      final order = _FakeOrderRepository.order(status: OrderStatus.pending);

      await harness.controller.advanceOrderStatus(order);
      expect(harness.orders.updatedStatuses, [OrderStatus.preparing]);
      await Future<void>.delayed(Duration.zero);
      expect(harness.notifications.statusOrderIds, ['order-1']);
    });

    test(
      'notification failures never roll back committed order work',
      () async {
        final harness = _ControllerHarness(
          appSettings: const AppSettings(
            openingTime: '00:00',
            closingTime: '00:00',
          ),
        );
        harness.notifications.failRequests = true;
        await harness.controller.bootstrapFuture;
        await harness.controller.startGuestSession();
        await harness.controller.updateCustomer(
          name: 'Guest Customer',
          phone: '0712345678',
        );
        harness.controller.addToCart(_menuItem(id: 'plate', name: 'Plate'));

        final order = await harness.controller.placeOrder(
          orderType: OrderType.pickup,
          paymentMethod: PaymentMethod.yoco,
        );
        await harness.controller.advanceOrderStatus(order);
        await Future<void>.delayed(Duration.zero);

        expect(harness.controller.cart, isEmpty);
        expect(harness.orders.updatedStatuses, [OrderStatus.preparing]);
      },
    );
  });
}

class _ControllerHarness {
  _ControllerHarness({
    List<MenuItemModel>? menuItems,
    List<MenuCategoryModel>? menuCategories,
    TodaysSpecialSettings? todaysSpecialSettings,
    AppSettings? appSettings,
    AppPreferences? seedPreferences,
    _FakeNotificationRepository? notificationRepository,
    _FakeOrderRepository? orderRepository,
  }) : auth = _FakeAuthRepository(),
       menu = _FakeMenuRepository(
         menuItems ?? const [],
         menuCategories ?? const [],
       ),
       orders = orderRepository ?? _FakeOrderRepository(),
       preferences = _FakePreferencesRepository(
         seedPreferences ?? const AppPreferences(),
       ),
       notifications = notificationRepository ?? _FakeNotificationRepository(),
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
      notificationRepository: notifications,
    );
  }

  final _FakeAuthRepository auth;
  final _FakeMenuRepository menu;
  final _FakeOrderRepository orders;
  final _FakeNotificationRepository notifications;
  final _FakePreferencesRepository preferences;
  final _FakeStoreRepository store;
  late final AppController controller;
}

class _FakeAuthRepository implements AuthRepository {
  String? upsertedName;
  String? upsertedPhone;
  String? resetEmail;
  String? updatedPassword;
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
  Future<void> updatePassword({required String newPassword}) async {
    updatedPassword = newPassword;
  }

  @override
  Future<void> signOut() async {
    signedOut = true;
  }

  @override
  Future<void> deleteAccount() async {
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
  OrderDraft? lastDraft;
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
    lastDraft = draft;
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

class _DelayedOrderRepository extends _FakeOrderRepository {
  final _submissionCompleter = Completer<OrderModel>();
  OrderModel? _pendingOrder;

  @override
  Future<OrderModel> createOrder(OrderDraft draft, {String? userId}) async {
    _pendingOrder = await super.createOrder(draft, userId: userId);
    return _submissionCompleter.future;
  }

  void completeSubmission() {
    _submissionCompleter.complete(_pendingOrder);
  }
}

class _FakeNotificationRepository implements NotificationRepository {
  final List<String> registeredUserIds = [];
  final List<bool> registeredAdminRoles = [];
  final List<String> newOrderIds = [];
  final List<String> statusOrderIds = [];
  int unregisterCount = 0;
  bool isDisposed = false;
  bool failRequests = false;

  @override
  Future<void> registerForSession({
    required String userId,
    required bool isAdmin,
  }) async {
    if (failRequests) {
      throw StateError('Notifications unavailable');
    }
    registeredUserIds.add(userId);
    registeredAdminRoles.add(isAdmin);
  }

  @override
  Future<void> unregisterCurrentSession() async {
    if (failRequests) {
      throw StateError('Notifications unavailable');
    }
    unregisterCount += 1;
  }

  @override
  Future<void> notifyNewOrder(OrderModel order) async {
    if (failRequests) {
      throw StateError('Notifications unavailable');
    }
    newOrderIds.add(order.id);
  }

  @override
  Future<void> notifyOrderStatusChanged(OrderModel order) async {
    if (failRequests) {
      throw StateError('Notifications unavailable');
    }
    statusOrderIds.add(order.id);
  }

  @override
  void dispose() {
    isDisposed = true;
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
    imagePath: 'assets/images/white-app-icon.png',
    isAvailable: isAvailable,
  );
}

/// Ticks the required terms and privacy box on the checkout screen.
Future<void> _acceptPolicies(WidgetTester tester) async {
  final checkbox = find.byKey(const ValueKey('policy-consent-checkbox'));
  await tester.ensureVisible(checkbox);
  await tester.tap(checkbox);
  await tester.pump();
}
