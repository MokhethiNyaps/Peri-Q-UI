import 'package:flutter/foundation.dart';

import '../models/app_auth_session.dart';
import '../models/app_preferences.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../repositories/auth_repository.dart';
import '../repositories/menu_repository.dart';
import '../repositories/order_repository.dart';
import '../repositories/preferences_repository.dart';
import '../repositories/store_repository.dart';

class AppController extends ChangeNotifier {
  AppController({
    required AuthRepository authRepository,
    required this._menuRepository,
    required this._orderRepository,
    required this._preferencesRepository,
    required this._storeRepository,
  }) : _authRepository = authRepository {
    bootstrapFuture = _bootstrap();
  }

  final AuthRepository _authRepository;
  final MenuRepository _menuRepository;
  final OrderRepository _orderRepository;
  final PreferencesRepository _preferencesRepository;
  final StoreRepository _storeRepository;

  late final Future<void> bootstrapFuture;

  List<MenuItemModel> menuItems = [];
  List<OrderModel> orders = [];
  List<CartItemModel> cart = [];

  String customerName = 'Thabo Mokhethi';
  String customerPhone = '+27 71 234 5678';
  String? userId;
  String? userEmail;
  bool isGuest = true;
  bool isAdmin = false;
  bool storeOpen = true;
  bool hasReturningSession = false;
  String selectedMenuCategory = 'All';

  bool isBootstrapping = true;
  String? bootstrapError;

  bool get canAccessAdmin => isAdmin;

  AppPreferences get _currentPreferences {
    return AppPreferences(
      hasReturningSession: hasReturningSession,
      isGuest: isGuest,
      customerName: customerName,
      customerPhone: customerPhone,
      storeOpen: storeOpen,
      selectedMenuCategory: selectedMenuCategory,
    );
  }

  List<String> get categories {
    final categorySet = <String>{};
    final values = <String>['All'];

    for (final item in menuItems) {
      if (categorySet.add(item.category)) {
        values.add(item.category);
      }
    }

    return values;
  }

  List<MenuItemModel> get featuredItems => menuItems.take(4).toList();

  List<MenuItemModel> get todaysSpecials {
    final specials = menuItems.where((item) {
      return item.id == 'wings-1' ||
          item.id == 'kota-1' ||
          item.id == 'burger-1';
    }).toList();

    return specials.isNotEmpty ? specials : menuItems.take(3).toList();
  }

  List<OrderModel> get activeOrders =>
      orders.where((order) => order.isActive).toList();

  List<OrderModel> get completedOrders =>
      orders.where((order) => !order.isActive).toList();

  int get cartCount => cart.fold<int>(0, (sum, item) => sum + item.quantity);

  double get subtotal => cart.fold<double>(0, (sum, item) => sum + item.total);

  double deliveryFeeFor(OrderType type) => type == OrderType.delivery ? 30 : 0;

  double totalFor(OrderType type) => subtotal + deliveryFeeFor(type);

  Future<void> _bootstrap() async {
    try {
      isBootstrapping = true;
      bootstrapError = null;

      final preferences = await _preferencesRepository.loadPreferences();
      final authSession = await _authRepository.restoreSession();
      final fetchedMenuItems = await _menuRepository.fetchMenuItems();
      final fetchedStoreOpen = await _storeRepository.fetchStoreOpenStatus();

      _applySessionState(authSession, fallbackPreferences: preferences);

      final fetchedOrders = await _orderRepository.fetchOrders(
        userId: userId,
        includeAll: isAdmin,
      );

      selectedMenuCategory = preferences.selectedMenuCategory;
      menuItems = fetchedMenuItems;
      storeOpen = fetchedStoreOpen;
      orders = fetchedOrders;

      if (!categories.contains(selectedMenuCategory)) {
        selectedMenuCategory = 'All';
      }
    } catch (error) {
      bootstrapError = error.toString();
      hasReturningSession = false;
      userId = null;
      userEmail = null;
      isAdmin = false;
      menuItems = [];
      orders = [];
      cart = [];
    } finally {
      isBootstrapping = false;
      notifyListeners();
    }
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

  Future<void> signOut() async {
    await _authRepository.signOut();
    userId = null;
    userEmail = null;
    isAdmin = false;
    hasReturningSession = false;
    isGuest = true;
    orders = await _orderRepository.fetchOrders(
      userId: null,
      includeAll: false,
    );
    selectedMenuCategory = 'All';
    cart = [];
    await _savePreferences();
    notifyListeners();
  }

  Future<void> updateCustomer({
    required String name,
    required String phone,
  }) async {
    customerName = name;
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
    final previousValue = storeOpen;
    storeOpen = value;
    notifyListeners();

    try {
      storeOpen = await _storeRepository.updateStoreOpenStatus(value);
      await _savePreferences();
    } catch (error) {
      storeOpen = previousValue;
      notifyListeners();
      rethrow;
    }

    notifyListeners();
  }

  void setSelectedMenuCategory(String category) {
    selectedMenuCategory = category;
    _savePreferences();
    notifyListeners();
  }

  void addToCart(
    MenuItemModel item, {
    int quantity = 1,
    String? spiceLevel,
    String notes = '',
    List<AddOnOption> selectedAddOns = const [],
  }) {
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
    final order = await _orderRepository.createOrder(
      OrderDraft(
        customerName: customerName,
        customerPhone: customerPhone,
        items: cart.map(_cloneCartItem).toList(),
        orderType: orderType,
        paymentMethod: paymentMethod,
        totalPrice: totalFor(orderType),
        estimatedMinutes: orderType == OrderType.delivery ? 45 : 25,
        deliveryAddress: deliveryAddress,
      ),
      userId: userId,
    );

    orders = [order, ...orders];
    cart = [];
    notifyListeners();
    return order;
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
    final savedItem = await _menuRepository.addMenuItem(item);
    menuItems = [savedItem, ...menuItems];
    notifyListeners();
  }

  Future<void> updateMenuItem(MenuItemModel updatedItem) async {
    final savedItem = await _menuRepository.updateMenuItem(updatedItem);
    menuItems = [
      for (final item in menuItems)
        if (item.id == savedItem.id) savedItem else item,
    ];
    notifyListeners();
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
    await _savePreferences();
    notifyListeners();
  }

  void _applySessionState(
    AppAuthSession session, {
    required AppPreferences fallbackPreferences,
  }) {
    userId = session.userId;
    userEmail = session.email;
    isAdmin = session.isAdmin;
    hasReturningSession =
        session.hasSession ||
        (!_authRepository.usesAuthoritativeSessions &&
            fallbackPreferences.hasReturningSession);
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
}
