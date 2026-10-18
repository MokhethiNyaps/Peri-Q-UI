import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/app_auth_session.dart';
import '../models/app_preferences.dart';
import '../models/app_settings.dart';
import '../models/menu_category.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/todays_special_settings.dart';
import '../repositories/auth_repository.dart';
import '../repositories/menu_repository.dart';
import '../repositories/notification_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/preferences_repository.dart';
import '../repositories/store_repository.dart';
import 'upload_image_optimizer.dart';

class AppController extends ChangeNotifier {
  AppController({
    required this._authRepository,
    required this._menuRepository,
    required this._orderRepository,
    required this._preferencesRepository,
    required this._storeRepository,
    this._notificationRepository = const NoopNotificationRepository(),
  }) {
    bootstrapFuture = _bootstrap();
  }

  final AuthRepository _authRepository;
  final MenuRepository _menuRepository;
  final OrderRepository _orderRepository;
  final PreferencesRepository _preferencesRepository;
  final StoreRepository _storeRepository;
  final NotificationRepository _notificationRepository;

  late final Future<void> bootstrapFuture;

  AppSettings appSettings = const AppSettings();
  List<MenuCategoryModel> menuCategories = [];
  List<MenuItemModel> menuItems = [];
  List<OrderModel> orders = [];
  List<CartItemModel> cart = [];
  List<SavedAddress> savedAddresses = [];

  String customerName = '';
  String customerPhone = '';
  String? defaultAddressId;
  PaymentMethod preferredPaymentMethod = PaymentMethod.yoco;
  String? userId;
  String? userEmail;
  bool isGuest = true;
  bool isAdmin = false;
  bool storeOpen = true;
  TodaysSpecialSettings todaysSpecialSettings = const TodaysSpecialSettings();
  bool hasReturningSession = false;
  String selectedMenuCategory = 'All';
  ThemeMode themeMode = ThemeMode.system;

  bool isBootstrapping = true;
  String? bootstrapError;
  bool isMenuStale = false;
  StreamSubscription<void>? _orderChanges;
  StreamSubscription<AppSettings>? _appSettingsChanges;
  StreamSubscription<void>? _menuItemChanges;
  StreamSubscription<void>? _menuCategoryChanges;
  bool _isRefreshingMenuFromRealtime = false;
  bool _hasPendingMenuRealtimeRefresh = false;
  int _sessionRevision = 0;
  int _orderWatchRevision = 0;
  int _orderFetchRevision = 0;
  int _bootstrapRevision = 0;
  int _appSettingsMutationRevision = 0;
  Future<void>? _refreshInFlight;
  Future<void> _preferenceWriteQueue = Future<void>.value();
  final Set<String> _ordersBeingUpdated = <String>{};
  bool _isDisposed = false;
  String? _pendingOrderRequestId;

  bool get canAccessAdmin => isAdmin;

  static const List<String> priorityCategories = [
    'Combo Plates',
    'Wors Meals',
    'Pork Meals',
    'Chicken Meals',
    'Liver Meals',
    'Family Meals',
  ];

  AppPreferences get _currentPreferences {
    return AppPreferences(
      hasReturningSession: hasReturningSession,
      isGuest: isGuest,
      customerName: customerName,
      customerPhone: customerPhone,
      storeOpen: storeOpen,
      selectedMenuCategory: selectedMenuCategory,
      savedAddresses: List<SavedAddress>.from(savedAddresses),
      defaultAddressId: defaultAddressId,
      preferredPaymentMethod: preferredPaymentMethod,
      themeMode: themeMode,
    );
  }

  List<String> get categories =>
      _categoriesFor(includeInactiveCategories: true, items: menuItems);

  List<MenuItemModel> get availableMenuItems =>
      menuItems.where((item) => item.isAvailable).toList();

  List<String> get customerCategories => _categoriesFor(
    includeInactiveCategories: false,
    items: availableMenuItems,
  );

  List<String> _categoriesFor({
    required bool includeInactiveCategories,
    required List<MenuItemModel> items,
  }) {
    final categorySet = <String>{};
    final values = <String>['All'];

    for (final category in _orderedCategories(menuCategories)) {
      if (!includeInactiveCategories && !category.isActive) {
        continue;
      }
      if (categorySet.add(category.name)) {
        values.add(category.name);
      }
    }

    for (final item in _orderedMenuItems(items)) {
      if (categorySet.add(item.category)) {
        values.add(item.category);
      }
    }

    return values;
  }

  List<MenuItemModel> get featuredItems =>
      _orderedMenuItems(availableMenuItems).take(4).toList();

  List<MenuItemModel> get todaysSpecials {
    final configuredItem = todaysSpecialItem;
    final specials = _orderedMenuItems(
      availableMenuItems,
    ).where(_isPriorityMenuItem).take(3).toList();

    final ordered = <MenuItemModel>[
      ?configuredItem,
      ...specials.where((item) => item.id != configuredItem?.id),
    ];

    return ordered.isNotEmpty
        ? ordered
        : _orderedMenuItems(availableMenuItems).take(3).toList();
  }

  MenuItemModel? get todaysSpecialItem {
    if (!todaysSpecialSettings.enabled) {
      return null;
    }

    final configuredId = todaysSpecialSettings.menuItemId;
    if (configuredId != null && configuredId.isNotEmpty) {
      for (final item in availableMenuItems) {
        if (item.id == configuredId) {
          return item;
        }
      }
    }

    final priorityItems = _orderedMenuItems(
      availableMenuItems,
    ).where(_isPriorityMenuItem).toList();
    if (priorityItems.isNotEmpty) {
      return priorityItems.first;
    }

    return availableMenuItems.isEmpty ? null : availableMenuItems.first;
  }

  SavedAddress? get defaultAddress {
    for (final address in savedAddresses) {
      if (address.id == defaultAddressId) {
        return address;
      }
    }
    return savedAddresses.isEmpty ? null : savedAddresses.first;
  }

  List<OrderModel> get activeOrders =>
      orders.where((order) => order.isActive).toList();

  List<OrderModel> get completedOrders =>
      orders.where((order) => !order.isActive).toList();

  int get cartCount => cart.fold<int>(0, (sum, item) => sum + item.quantity);

  double get subtotal => cart.fold<double>(0, (sum, item) => sum + item.total);

  double deliveryFeeFor(OrderType type) =>
      type == OrderType.delivery ? appSettings.deliveryFee : 0;

  double totalFor(OrderType type) => subtotal + deliveryFeeFor(type);

  bool get isStoreOpenNow => appSettings.isOpenAt(DateTime.now());

  bool canUseOrderType(OrderType type) => type == OrderType.pickup
      ? appSettings.pickupAvailable
      : appSettings.deliveryAvailable;

  bool get canPlaceOrders =>
      isStoreOpenNow &&
      (appSettings.pickupAvailable || appSettings.deliveryAvailable);

  String get storeStatusLabel {
    if (!appSettings.storeOpen) {
      return 'Closed';
    }
    if (!isStoreOpenNow) {
      return 'Closed - Opens ${appSettings.openingTime}';
    }
    return 'Open Now - Closes ${appSettings.closingTime}';
  }

  Future<void> _bootstrap() async {
    final bootstrapRevision = ++_bootstrapRevision;
    try {
      isBootstrapping = true;
      bootstrapError = null;

      final preferences = await _preferencesRepository.loadPreferences();
      final authSession = await _authRepository.restoreSession();
      AppSettings fetchedAppSettings;
      try {
        fetchedAppSettings = await _storeRepository.fetchAppSettings();
      } catch (_) {
        fetchedAppSettings = const AppSettings(storeOpen: false);
      }
      final fetchedMenuCategories = await _menuRepository.fetchMenuCategories();
      final fetchedMenuItems = await _menuRepository.fetchMenuItems();

      if (_isDisposed || bootstrapRevision != _bootstrapRevision) return;

      _applySessionState(authSession, fallbackPreferences: preferences);

      List<OrderModel> fetchedOrders;
      try {
        fetchedOrders = await _orderRepository.fetchOrders(
          userId: userId,
          includeAll: isAdmin,
        );
      } catch (_) {
        fetchedOrders = const [];
      }

      if (_isDisposed || bootstrapRevision != _bootstrapRevision) return;

      selectedMenuCategory = preferences.selectedMenuCategory;
      savedAddresses = List<SavedAddress>.from(preferences.savedAddresses);
      defaultAddressId = _validDefaultAddressId(preferences.defaultAddressId);
      preferredPaymentMethod = PaymentMethod.yoco;
      themeMode = preferences.themeMode;
      _applyAppSettings(fetchedAppSettings);
      menuCategories = _orderedCategories(fetchedMenuCategories);
      menuItems = _orderedMenuItems(fetchedMenuItems);
      isMenuStale = _menuRepository.lastFetchUsedCache;
      orders = fetchedOrders;
      final storage = _preferencesRepository;
      if (storage is CheckoutCartStore && userId != null) {
        final saved = await (storage as CheckoutCartStore).loadCheckoutCart(
          userId!,
        );
        if (saved != null) {
          cart = (saved['items'] as List<dynamic>? ?? [])
              .map((e) => CartItemModel.fromJson(e as Map<String, dynamic>))
              .toList();
          _pendingOrderRequestId = saved['requestId'] as String?;
        }
      }
      _startWatchingOrders();
      _startWatchingAppSettings();
      _startWatchingMenu();
      unawaited(_registerNotificationsForCurrentSession());

      if (!categories.contains(selectedMenuCategory)) {
        selectedMenuCategory = 'All';
      }
    } catch (error) {
      if (_isDisposed || bootstrapRevision != _bootstrapRevision) return;
      bootstrapError = error.toString();
      hasReturningSession = false;
      userId = null;
      userEmail = null;
      isAdmin = false;
      _applyAppSettings(const AppSettings());
      menuCategories = [];
      menuItems = [];
      orders = [];
      cart = [];
      savedAddresses = [];
      defaultAddressId = null;
      preferredPaymentMethod = PaymentMethod.yoco;
    } finally {
      if (!_isDisposed && bootstrapRevision == _bootstrapRevision) {
        isBootstrapping = false;
        notifyListeners();
      }
    }
  }

  Future<void> retryBootstrap() => _bootstrap();

  Future<void> refreshData() {
    final inFlight = _refreshInFlight;
    if (inFlight != null) return inFlight;

    final operation = _refreshDataOnce();
    _refreshInFlight = operation;
    return operation.whenComplete(() {
      if (identical(_refreshInFlight, operation)) {
        _refreshInFlight = null;
      }
    });
  }

  Future<void> _refreshDataOnce() async {
    final sessionRevision = _sessionRevision;
    final results = await Future.wait<dynamic>([
      _storeRepository.fetchAppSettings(),
      _menuRepository.fetchMenuCategories(),
      _menuRepository.fetchMenuItems(),
      _orderRepository.fetchOrders(userId: userId, includeAll: isAdmin),
    ]);
    if (_isDisposed || sessionRevision != _sessionRevision) return;
    _applyAppSettings(results[0] as AppSettings);
    menuCategories = _orderedCategories(results[1] as List<MenuCategoryModel>);
    menuItems = _orderedMenuItems(results[2] as List<MenuItemModel>);
    isMenuStale = _menuRepository.lastFetchUsedCache;
    orders = results[3] as List<OrderModel>;
    if (!_isDisposed) notifyListeners();
  }

  Future<void> _savePreferences() {
    final snapshot = _currentPreferences;
    final operation = _preferenceWriteQueue.then(
      (_) => _preferencesRepository.savePreferences(snapshot),
    );
    _preferenceWriteQueue = operation.catchError((_) {});
    return operation;
  }

  Future<void> startGuestSession() async {
    final session = await _authRepository.signInAnonymously();
    await _activateSession(session, guest: true);
  }

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final session = await _authRepository.signInWithEmail(
      email: email,
      password: password,
    );
    await _activateSession(session, guest: false);
  }

  Future<void> registerWithEmail({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    final normalizedPhone = _normalizePhone(phone);
    final trimmedName = name.trim();
    final session = await _authRepository.signUpWithEmail(
      email: email,
      password: password,
      name: trimmedName,
      phone: normalizedPhone,
    );
    customerName = trimmedName;
    customerPhone = normalizedPhone;
    await _activateSession(session, guest: false);
    await _authRepository.upsertProfile(
      name: customerName,
      phone: customerPhone,
    );
  }

  Future<void> requestPasswordReset({required String email}) {
    return _authRepository.resetPasswordForEmail(email: email);
  }

  Future<void> updatePassword({required String newPassword}) {
    return _authRepository.updatePassword(newPassword: newPassword);
  }

  Future<void> signOut() async {
    _sessionRevision += 1;
    _orderWatchRevision += 1;
    _refreshInFlight = null;
    _pendingOrderRequestId = null;
    await _orderChanges?.cancel();
    _orderChanges = null;
    await _unregisterNotificationsBestEffort();
    await _authRepository.signOut();
    userId = null;
    userEmail = null;
    isAdmin = false;
    hasReturningSession = false;
    isGuest = true;
    customerName = '';
    customerPhone = '';
    orders = [];
    selectedMenuCategory = 'All';
    cart = [];
    savedAddresses = [];
    defaultAddressId = null;
    preferredPaymentMethod = PaymentMethod.yoco;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> deleteAccount() async {
    _sessionRevision += 1;
    _orderWatchRevision += 1;
    _refreshInFlight = null;
    _pendingOrderRequestId = null;
    await _unregisterNotificationsBestEffort();
    await _authRepository.deleteAccount();
    await _orderChanges?.cancel();
    _orderChanges = null;
    userId = null;
    userEmail = null;
    isAdmin = false;
    hasReturningSession = false;
    isGuest = true;
    customerName = '';
    customerPhone = '';
    orders = [];
    cart = [];
    savedAddresses = [];
    defaultAddressId = null;
    await _savePreferences();
    if (!_isDisposed) notifyListeners();
  }

  Future<void> updateCustomer({
    required String name,
    required String phone,
  }) async {
    customerName = name.trim();
    customerPhone = _normalizePhone(phone);
    if (hasReturningSession) {
      await _savePreferences();
    }
    if (userId != null) {
      await _authRepository.upsertProfile(
        name: customerName,
        phone: customerPhone,
      );
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode = mode;
    notifyListeners();
    await _savePreferences();
  }

  Future<void> toggleStoreOpen(bool value) async {
    await updateAppSettings(appSettings.copyWith(storeOpen: value));
    await _savePreferences();
  }

  Future<void> updateAppSettings(AppSettings settings) async {
    final mutationRevision = ++_appSettingsMutationRevision;
    final previousSettings = appSettings;
    _applyAppSettings(settings);
    notifyListeners();

    try {
      final savedSettings = await _storeRepository.updateAppSettings(settings);
      if (_isDisposed || mutationRevision != _appSettingsMutationRevision) {
        return;
      }
      _applyAppSettings(savedSettings);
    } catch (_) {
      if (!_isDisposed && mutationRevision == _appSettingsMutationRevision) {
        _applyAppSettings(previousSettings);
        notifyListeners();
      }
      rethrow;
    }

    if (!_isDisposed) notifyListeners();
  }

  Future<void> updateTodaysSpecialSettings(
    TodaysSpecialSettings settings,
  ) async {
    await updateAppSettings(appSettings.copyWith(todaysSpecial: settings));
  }

  void setSelectedMenuCategory(String category) {
    selectedMenuCategory = category;
    notifyListeners();
    unawaited(_savePreferences().catchError((_) {}));
  }

  Future<void> addSavedAddress({
    required String label,
    required String address,
    String notes = '',
  }) async {
    final savedAddress = SavedAddress(
      id: 'address-${DateTime.now().microsecondsSinceEpoch}',
      label: label.trim(),
      address: address.trim(),
      notes: notes.trim(),
    );
    savedAddresses = [...savedAddresses, savedAddress];
    defaultAddressId ??= savedAddress.id;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> updateSavedAddress(SavedAddress updatedAddress) async {
    savedAddresses = [
      for (final address in savedAddresses)
        if (address.id == updatedAddress.id) updatedAddress else address,
    ];
    defaultAddressId = _validDefaultAddressId(defaultAddressId);
    await _savePreferences();
    notifyListeners();
  }

  Future<void> deleteSavedAddress(String addressId) async {
    savedAddresses = [
      for (final address in savedAddresses)
        if (address.id != addressId) address,
    ];
    defaultAddressId = defaultAddressId == addressId
        ? (savedAddresses.isEmpty ? null : savedAddresses.first.id)
        : _validDefaultAddressId(defaultAddressId);
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setDefaultAddress(String addressId) async {
    if (!savedAddresses.any((address) => address.id == addressId)) {
      return;
    }
    defaultAddressId = addressId;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> setPreferredPaymentMethod(PaymentMethod method) async {
    preferredPaymentMethod = PaymentMethod.yoco;
    await _savePreferences();
    notifyListeners();
  }

  Future<void> _persistCheckoutCart() async {
    final storage = _preferencesRepository;
    if (storage is CheckoutCartStore && userId != null) {
      await (storage as CheckoutCartStore).saveCheckoutCart(userId!, {
        'items': cart.map((e) => e.toJson()).toList(),
        'requestId': _pendingOrderRequestId,
      });
    }
  }

  void addToCart(
    MenuItemModel item, {
    int quantity = 1,
    String? spiceLevel,
    String notes = '',
    List<AddOnOption> selectedAddOns = const [],
  }) {
    if (!item.isAvailable) {
      throw StateError('This item is currently unavailable.');
    }
    if (quantity < 1 || quantity > 50) {
      throw ArgumentError.value(quantity, 'quantity', 'Use 1 to 50.');
    }
    final newItem = CartItemModel(
      id: '${item.id}-${DateTime.now().microsecondsSinceEpoch}',
      item: item,
      quantity: quantity,
      spiceLevel: spiceLevel,
      notes: notes,
      selectedAddOns: List<AddOnOption>.from(selectedAddOns),
    );
    cart = [...cart, newItem];
    _pendingOrderRequestId = null;
    unawaited(_persistCheckoutCart());
    notifyListeners();
  }

  void incrementCartItem(CartItemModel cartItem) {
    cartItem.quantity += 1;
    _pendingOrderRequestId = null;
    unawaited(_persistCheckoutCart());
    notifyListeners();
  }

  void decrementCartItem(CartItemModel cartItem) {
    if (cartItem.quantity == 1) {
      removeCartItem(cartItem);
      return;
    }
    cartItem.quantity -= 1;
    _pendingOrderRequestId = null;
    unawaited(_persistCheckoutCart());
    notifyListeners();
  }

  void removeCartItem(CartItemModel cartItem) {
    cart.removeWhere((item) => item.id == cartItem.id);
    _pendingOrderRequestId = null;
    unawaited(_persistCheckoutCart());
    notifyListeners();
  }

  Future<OrderModel> placeOrder({
    required OrderType orderType,
    required PaymentMethod paymentMethod,
    String? deliveryAddress,
  }) async {
    if (paymentMethod != PaymentMethod.yoco) {
      throw const OrderSubmissionException('Pay by card through Yoco.');
    }
    final sessionRevision = _sessionRevision;
    if (cart.isEmpty) {
      throw const OrderSubmissionException('Your cart is empty.');
    }
    if (!canPlaceOrders) {
      throw const OrderSubmissionException(
        'Ordering is currently paused or the store is closed.',
      );
    }
    if (!canUseOrderType(orderType)) {
      throw OrderSubmissionException(
        '${orderType.label} is not available right now.',
      );
    }
    if (orderType == OrderType.delivery &&
        (deliveryAddress == null || deliveryAddress.trim().isEmpty)) {
      throw const OrderSubmissionException('Enter a delivery address.');
    }
    _pendingOrderRequestId ??=
        '${userId ?? 'user'}-${DateTime.now().microsecondsSinceEpoch}';
    await _persistCheckoutCart();
    final order = await _orderRepository.createOrder(
      OrderDraft(
        customerName: customerName,
        customerPhone: customerPhone,
        items: cart.map(_cloneCartItem).toList(),
        orderType: orderType,
        paymentMethod: paymentMethod,
        totalPrice: totalFor(orderType),
        estimatedMinutes: orderType == OrderType.delivery ? 45 : 25,
        clientRequestId: _pendingOrderRequestId!,
        deliveryAddress: deliveryAddress,
      ),
      userId: userId,
    );

    if (_isDisposed || sessionRevision != _sessionRevision) {
      return order;
    }
    _pendingOrderRequestId = null;
    orders = [order, ...orders];
    cart = [];
    unawaited(_persistCheckoutCart());
    notifyListeners();
    unawaited(_notifyNewOrderBestEffort(order));
    return order;
  }

  Future<String> uploadPaymentProof({
    required OrderModel order,
    required List<int> bytes,
    required String fileName,
    required String contentType,
  }) {
    if (order.paymentMethod != PaymentMethod.eft) {
      throw const OrderSubmissionException(
        'Payment proof is only used for EFT orders.',
      );
    }
    return _orderRepository.uploadPaymentProof(
      orderId: order.id,
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );
  }

  Future<void> advanceOrderStatus(OrderModel order) async {
    if (!_ordersBeingUpdated.add(order.id)) return;
    final nextStatus = switch (order.status) {
      OrderStatus.pending => OrderStatus.preparing,
      OrderStatus.preparing => OrderStatus.ready,
      OrderStatus.ready => OrderStatus.completed,
      OrderStatus.completed => null,
      OrderStatus.cancelled => null,
    };

    if (nextStatus == null) {
      _ordersBeingUpdated.remove(order.id);
      return;
    }

    try {
      final updatedOrder = await _orderRepository.updateOrderStatus(
        orderId: order.id,
        status: nextStatus,
      );
      _replaceOrder(updatedOrder);
      unawaited(_notifyOrderStatusBestEffort(updatedOrder));
    } finally {
      _ordersBeingUpdated.remove(order.id);
    }
  }

  Future<void> rejectOrder(OrderModel order) async {
    if (!_ordersBeingUpdated.add(order.id)) return;
    try {
      final updatedOrder = await _orderRepository.updateOrderStatus(
        orderId: order.id,
        status: OrderStatus.cancelled,
      );
      _replaceOrder(updatedOrder);
      unawaited(_notifyOrderStatusBestEffort(updatedOrder));
    } finally {
      _ordersBeingUpdated.remove(order.id);
    }
  }

  void reorder(OrderModel order) {
    cart = [
      ...cart,
      ...order.items.map(
        (entry) => CartItemModel(
          id: '${entry.id}-${DateTime.now().microsecondsSinceEpoch}',
          item: entry.item,
          quantity: entry.quantity,
          spiceLevel: entry.spiceLevel,
          notes: entry.notes,
          selectedAddOns: List<AddOnOption>.from(entry.selectedAddOns),
        ),
      ),
    ];
    notifyListeners();
  }

  Future<void> addMenuItem(MenuItemModel item) async {
    await _menuRepository.addMenuItem(item);
    await _reloadMenuItems();
    notifyListeners();
  }

  Future<void> updateMenuItem(MenuItemModel updatedItem) async {
    await _menuRepository.updateMenuItem(updatedItem);
    await _reloadMenuItems();
    notifyListeners();
  }

  Future<void> deleteMenuItem(String menuItemId) async {
    await _menuRepository.deleteMenuItem(menuItemId);
    await _reloadMenuItems();
    notifyListeners();
  }

  Future<void> addMenuCategory(MenuCategoryModel category) async {
    await _menuRepository.addMenuCategory(category);
    await _reloadMenuCategories();
    notifyListeners();
  }

  Future<void> updateMenuCategory(MenuCategoryModel updatedCategory) async {
    MenuCategoryModel? previousCategory;
    for (final category in menuCategories) {
      if (category.id == updatedCategory.id) {
        previousCategory = category;
        break;
      }
    }

    final savedCategory = await _menuRepository.updateMenuCategory(
      updatedCategory,
    );

    if (previousCategory != null &&
        previousCategory.name != savedCategory.name) {
      final previousName = previousCategory.name;
      final affectedItems = menuItems.where(
        (item) => item.category == previousName,
      );
      for (final item in affectedItems) {
        await _menuRepository.updateMenuItem(
          item.copyWith(category: savedCategory.name),
        );
      }
    }

    await _reloadMenuCategories();
    await _reloadMenuItems();
    notifyListeners();
  }

  Future<void> deleteMenuCategory(MenuCategoryModel category) async {
    final hasMenuItems = menuItems.any(
      (item) => item.category == category.name,
    );
    if (hasMenuItems) {
      throw StateError(
        'Move or edit menu items in this category before deleting it.',
      );
    }

    await _menuRepository.deleteMenuCategory(category.id);
    await _reloadMenuCategories();
    notifyListeners();
  }

  Future<String> uploadMenuItemImage({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final optimized = await UploadImageOptimizer.optimize(
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );
    return _menuRepository.uploadMenuItemImage(
      bytes: optimized.bytes,
      fileName: optimized.fileName,
      contentType: optimized.contentType,
    );
  }

  Future<void> _activateSession(
    AppAuthSession session, {
    required bool guest,
  }) async {
    final sessionRevision = ++_sessionRevision;
    _refreshInFlight = null;
    _pendingOrderRequestId = null;
    userId = session.userId;
    userEmail = session.email;
    isAdmin = session.isAdmin;
    hasReturningSession = session.hasSession;
    isGuest = guest;
    customerName = _resolveProfileValue(session.customerName, customerName);
    customerPhone = _resolveProfileValue(session.customerPhone, customerPhone);
    final fetchedOrders = await _orderRepository.fetchOrders(
      userId: userId,
      includeAll: isAdmin,
    );
    if (_isDisposed || sessionRevision != _sessionRevision) return;
    orders = fetchedOrders;
    _startWatchingOrders();
    await _savePreferences();
    if (_isDisposed || sessionRevision != _sessionRevision) return;
    notifyListeners();
    unawaited(_registerNotificationsForCurrentSession());
  }

  Future<void> _registerNotificationsForCurrentSession() async {
    final sessionUserId = userId;
    if (sessionUserId == null || sessionUserId.isEmpty) {
      return;
    }
    try {
      await _notificationRepository.registerForSession(
        userId: sessionUserId,
        isAdmin: isAdmin,
      );
    } catch (_) {
      // Push registration is best effort and must not block authentication.
    }
  }

  Future<void> _unregisterNotificationsBestEffort() async {
    try {
      await _notificationRepository.unregisterCurrentSession();
    } catch (_) {
      // Signing out/deleting an account must remain available if FCM is down.
    }
  }

  Future<void> _notifyNewOrderBestEffort(OrderModel order) async {
    try {
      await _notificationRepository.notifyNewOrder(order);
    } catch (_) {
      // The order is already committed; notification delivery is independent.
    }
  }

  Future<void> _notifyOrderStatusBestEffort(OrderModel order) async {
    try {
      await _notificationRepository.notifyOrderStatusChanged(order);
    } catch (_) {
      // The status change remains authoritative even if push delivery fails.
    }
  }

  void _startWatchingOrders() {
    _orderChanges?.cancel();
    final watchRevision = ++_orderWatchRevision;
    final watchedUserId = userId;
    final watchedIsAdmin = isAdmin;
    _orderChanges = _orderRepository
        .watchOrders(userId: watchedUserId, includeAll: watchedIsAdmin)
        .listen((_) {
          final fetchRevision = ++_orderFetchRevision;
          unawaited(
            _orderRepository
                .fetchOrders(userId: watchedUserId, includeAll: watchedIsAdmin)
                .then((fetchedOrders) {
                  if (_isDisposed ||
                      watchRevision != _orderWatchRevision ||
                      fetchRevision != _orderFetchRevision) {
                    return;
                  }
                  orders = fetchedOrders;
                  notifyListeners();
                })
                .catchError((_) {
                  // Keep the last successful orders. A later event or manual
                  // refresh will recover without regressing newer state.
                }),
          );
        });
  }

  void _startWatchingAppSettings() {
    _appSettingsChanges?.cancel();
    _appSettingsChanges = _storeRepository.watchAppSettings().listen(
      (settings) {
        if (_isDisposed) return;
        _applyAppSettings(settings);
        notifyListeners();
      },
      onError: (_) {
        // Keep the last successful settings; pull-to-refresh provides recovery.
      },
    );
  }

  void _startWatchingMenu() {
    _menuItemChanges?.cancel();
    _menuCategoryChanges?.cancel();
    _menuItemChanges = _menuRepository.watchMenuItems().listen(
      (_) => unawaited(_refreshMenuFromRealtime()),
      onError: (_) {
        // Keep the last successful menu; pull-to-refresh provides recovery.
      },
    );
    _menuCategoryChanges = _menuRepository.watchMenuCategories().listen(
      (_) => unawaited(_refreshMenuFromRealtime()),
      onError: (_) {
        // Keep the last successful categories; pull-to-refresh provides recovery.
      },
    );
  }

  Future<void> _refreshMenuFromRealtime() async {
    if (_isDisposed) return;
    if (_isRefreshingMenuFromRealtime) {
      _hasPendingMenuRealtimeRefresh = true;
      return;
    }
    _isRefreshingMenuFromRealtime = true;
    try {
      do {
        _hasPendingMenuRealtimeRefresh = false;
        try {
          final results = await Future.wait<dynamic>([
            _menuRepository.fetchMenuCategories(),
            _menuRepository.fetchMenuItems(),
          ]);
          if (_isDisposed) return;
          menuCategories = _orderedCategories(
            results[0] as List<MenuCategoryModel>,
          );
          menuItems = _orderedMenuItems(results[1] as List<MenuItemModel>);
          isMenuStale = _menuRepository.lastFetchUsedCache;
          if (!categories.contains(selectedMenuCategory)) {
            selectedMenuCategory = 'All';
          }
          notifyListeners();
        } catch (_) {
          // Keep the last successful menu; pull-to-refresh provides recovery.
        }
      } while (_hasPendingMenuRealtimeRefresh);
    } finally {
      _isRefreshingMenuFromRealtime = false;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _bootstrapRevision += 1;
    _sessionRevision += 1;
    _orderWatchRevision += 1;
    _orderFetchRevision += 1;
    _orderChanges?.cancel();
    _appSettingsChanges?.cancel();
    _menuItemChanges?.cancel();
    _menuCategoryChanges?.cancel();
    _notificationRepository.dispose();
    super.dispose();
  }

  void _applySessionState(
    AppAuthSession session, {
    required AppPreferences fallbackPreferences,
  }) {
    userId = session.userId;
    userEmail = session.email;
    isAdmin = session.isAdmin;
    hasReturningSession = session.hasSession;
    isGuest = session.hasSession
        ? (session.isAnonymous ? fallbackPreferences.isGuest : false)
        : fallbackPreferences.isGuest;
    customerName = _resolveProfileValue(
      session.customerName,
      fallbackPreferences.customerName,
    );
    customerPhone = _resolveProfileValue(
      session.customerPhone,
      fallbackPreferences.customerPhone,
    );
    storeOpen = fallbackPreferences.storeOpen;
  }

  void _replaceOrder(OrderModel updatedOrder) {
    if (_isDisposed) return;
    orders = [
      for (final order in orders)
        if (order.id == updatedOrder.id) updatedOrder else order,
    ];
    notifyListeners();
  }

  void _applyAppSettings(AppSettings settings) {
    appSettings = settings;
    storeOpen = settings.storeOpen;
    todaysSpecialSettings = settings.todaysSpecial;
  }

  Future<void> _reloadMenuCategories() async {
    menuCategories = _orderedCategories(
      await _menuRepository.fetchMenuCategories(),
    );
  }

  Future<void> _reloadMenuItems() async {
    menuItems = _orderedMenuItems(await _menuRepository.fetchMenuItems());
    isMenuStale = _menuRepository.lastFetchUsedCache;
    if (!categories.contains(selectedMenuCategory)) {
      selectedMenuCategory = 'All';
    }
  }

  CartItemModel _cloneCartItem(CartItemModel item) {
    return CartItemModel(
      id: item.id,
      item: item.item,
      quantity: item.quantity,
      spiceLevel: item.spiceLevel,
      notes: item.notes,
      selectedAddOns: List<AddOnOption>.from(item.selectedAddOns),
    );
  }

  String _resolveProfileValue(String? remoteValue, String fallbackValue) {
    if (remoteValue == null || remoteValue.trim().isEmpty) {
      return fallbackValue;
    }

    return remoteValue.trim();
  }

  String _normalizePhone(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return customerPhone;
    }

    if (trimmed.startsWith('+')) {
      return trimmed;
    }

    return '+27 ${trimmed.replaceFirst(RegExp(r'^0+'), '')}';
  }

  String? _validDefaultAddressId(String? addressId) {
    if (addressId == null) {
      return savedAddresses.isEmpty ? null : savedAddresses.first.id;
    }
    return savedAddresses.any((address) => address.id == addressId)
        ? addressId
        : (savedAddresses.isEmpty ? null : savedAddresses.first.id);
  }

  List<MenuCategoryModel> _orderedCategories(
    List<MenuCategoryModel> categories,
  ) {
    final ordered = List<MenuCategoryModel>.from(categories);
    ordered.sort((a, b) {
      final priorityCompare = _categoryPriority(
        a.name,
      ).compareTo(_categoryPriority(b.name));
      if (priorityCompare != 0) {
        return priorityCompare;
      }

      final sortCompare = a.sortOrder.compareTo(b.sortOrder);
      if (sortCompare != 0) {
        return sortCompare;
      }

      return a.name.compareTo(b.name);
    });
    return ordered;
  }

  List<MenuItemModel> _orderedMenuItems(List<MenuItemModel> items) {
    final ordered = List<MenuItemModel>.from(items);
    ordered.sort((a, b) {
      final priorityCompare = _categoryPriority(
        a.category,
      ).compareTo(_categoryPriority(b.category));
      if (priorityCompare != 0) {
        return priorityCompare;
      }
      return a.name.compareTo(b.name);
    });
    return ordered;
  }

  int _categoryPriority(String category) {
    final index = priorityCategories.indexWhere(
      (value) => value.toLowerCase() == category.toLowerCase(),
    );
    return index == -1 ? 1000 : index;
  }

  bool _isPriorityMenuItem(MenuItemModel item) {
    return _categoryPriority(item.category) < 1000;
  }
}
