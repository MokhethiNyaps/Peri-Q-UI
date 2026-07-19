import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/app_auth_session.dart';
import '../models/app_preferences.dart';
import '../models/app_settings.dart';
import '../models/menu_category.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../models/todays_special_settings.dart';
import '../repositories/auth_repository.dart';
import '../repositories/menu_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/preferences_repository.dart';
import '../repositories/store_repository.dart';

class AppController extends ChangeNotifier {
  AppController({
    required this._authRepository,
    required this._menuRepository,
    required this._orderRepository,
    required this._preferencesRepository,
    required this._storeRepository,
  }) {
    bootstrapFuture = _bootstrap();
  }

  final AuthRepository _authRepository;
  final MenuRepository _menuRepository;
  final OrderRepository _orderRepository;
  final PreferencesRepository _preferencesRepository;
  final StoreRepository _storeRepository;

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
  PaymentMethod preferredPaymentMethod = PaymentMethod.cashCollection;
  String? userId;
  String? userEmail;
  bool isGuest = true;
  bool isAdmin = false;
  bool storeOpen = true;
  TodaysSpecialSettings todaysSpecialSettings = const TodaysSpecialSettings();
  bool hasReturningSession = false;
  String selectedMenuCategory = 'All';

  bool isBootstrapping = true;
  String? bootstrapError;
  bool isMenuStale = false;
  StreamSubscription<void>? _orderChanges;
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

      selectedMenuCategory = preferences.selectedMenuCategory;
      savedAddresses = List<SavedAddress>.from(preferences.savedAddresses);
      defaultAddressId = _validDefaultAddressId(preferences.defaultAddressId);
      preferredPaymentMethod = preferences.preferredPaymentMethod;
      _applyAppSettings(fetchedAppSettings);
      menuCategories = _orderedCategories(fetchedMenuCategories);
      menuItems = _orderedMenuItems(fetchedMenuItems);
      isMenuStale = _menuRepository.lastFetchUsedCache;
      orders = fetchedOrders;
      _startWatchingOrders();

      if (!categories.contains(selectedMenuCategory)) {
        selectedMenuCategory = 'All';
      }
    } catch (error) {
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
      preferredPaymentMethod = PaymentMethod.cashCollection;
    } finally {
      isBootstrapping = false;
      notifyListeners();
    }
  }

  Future<void> retryBootstrap() => _bootstrap();

  Future<void> refreshData() async {
    final results = await Future.wait<dynamic>([
      _storeRepository.fetchAppSettings(),
      _menuRepository.fetchMenuCategories(),
      _menuRepository.fetchMenuItems(),
      _orderRepository.fetchOrders(userId: userId, includeAll: isAdmin),
    ]);
    _applyAppSettings(results[0] as AppSettings);
    menuCategories = _orderedCategories(results[1] as List<MenuCategoryModel>);
    menuItems = _orderedMenuItems(results[2] as List<MenuItemModel>);
    isMenuStale = _menuRepository.lastFetchUsedCache;
    orders = results[3] as List<OrderModel>;
    notifyListeners();
  }

  Future<void> _savePreferences() {
    return _preferencesRepository.savePreferences(_currentPreferences);
  }

  Future<void> startGuestSession() async {
    final session = await _authRepository.signInAnonymously();
    await _activateSession(session, guest: true);
  }

  Future<void> startPhoneSession({required String phone}) async {
    customerPhone = _normalizePhone(phone);
    final session = await _authRepository.signInAnonymously();
    await _activateSession(session, guest: false);
    await _authRepository.upsertProfile(
      name: customerName,
      phone: customerPhone,
    );
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

  Future<void> signOut() async {
    await _orderChanges?.cancel();
    _orderChanges = null;
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
    await _savePreferences();
    notifyListeners();
  }

  Future<void> deleteAccount() async {
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
    notifyListeners();
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

  Future<void> toggleStoreOpen(bool value) async {
    await updateAppSettings(appSettings.copyWith(storeOpen: value));
    await _savePreferences();
  }

  Future<void> updateAppSettings(AppSettings settings) async {
    final previousSettings = appSettings;
    _applyAppSettings(settings);
    notifyListeners();

    try {
      final savedSettings = await _storeRepository.updateAppSettings(settings);
      _applyAppSettings(savedSettings);
    } catch (_) {
      _applyAppSettings(previousSettings);
      notifyListeners();
      rethrow;
    }

    notifyListeners();
  }

  Future<void> updateTodaysSpecialSettings(
    TodaysSpecialSettings settings,
  ) async {
    await updateAppSettings(appSettings.copyWith(todaysSpecial: settings));
  }

  void setSelectedMenuCategory(String category) {
    selectedMenuCategory = category;
    _savePreferences();
    notifyListeners();
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
    preferredPaymentMethod = method;
    await _savePreferences();
    notifyListeners();
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
    notifyListeners();
  }

  void incrementCartItem(CartItemModel cartItem) {
    cartItem.quantity += 1;
    notifyListeners();
  }

  void decrementCartItem(CartItemModel cartItem) {
    if (cartItem.quantity == 1) {
      removeCartItem(cartItem);
      return;
    }
    cartItem.quantity -= 1;
    notifyListeners();
  }

  void removeCartItem(CartItemModel cartItem) {
    cart.removeWhere((item) => item.id == cartItem.id);
    notifyListeners();
  }

  Future<OrderModel> placeOrder({
    required OrderType orderType,
    required PaymentMethod paymentMethod,
    String? deliveryAddress,
  }) async {
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

    _pendingOrderRequestId = null;
    orders = [order, ...orders];
    cart = [];
    notifyListeners();
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
    final nextStatus = switch (order.status) {
      OrderStatus.pending => OrderStatus.preparing,
      OrderStatus.preparing => OrderStatus.ready,
      OrderStatus.ready => OrderStatus.completed,
      OrderStatus.completed => null,
      OrderStatus.cancelled => null,
    };

    if (nextStatus == null) {
      return;
    }

    final updatedOrder = await _orderRepository.updateOrderStatus(
      orderId: order.id,
      status: nextStatus,
    );
    _replaceOrder(updatedOrder);
  }

  Future<void> rejectOrder(OrderModel order) async {
    final updatedOrder = await _orderRepository.updateOrderStatus(
      orderId: order.id,
      status: OrderStatus.cancelled,
    );
    _replaceOrder(updatedOrder);
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
  }) {
    return _menuRepository.uploadMenuItemImage(
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
    );
  }

  Future<void> _activateSession(
    AppAuthSession session, {
    required bool guest,
  }) async {
    userId = session.userId;
    userEmail = session.email;
    isAdmin = session.isAdmin;
    hasReturningSession = session.hasSession;
    isGuest = guest;
    customerName = _resolveProfileValue(session.customerName, customerName);
    customerPhone = _resolveProfileValue(session.customerPhone, customerPhone);
    orders = await _orderRepository.fetchOrders(
      userId: userId,
      includeAll: isAdmin,
    );
    _startWatchingOrders();
    await _savePreferences();
    notifyListeners();
  }

  void _startWatchingOrders() {
    _orderChanges?.cancel();
    _orderChanges = _orderRepository
        .watchOrders(userId: userId, includeAll: isAdmin)
        .listen((_) async {
          try {
            orders = await _orderRepository.fetchOrders(
              userId: userId,
              includeAll: isAdmin,
            );
            notifyListeners();
          } catch (_) {
            // The current data stays visible; resume/refresh provides recovery.
          }
        });
  }

  @override
  void dispose() {
    _orderChanges?.cancel();
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
