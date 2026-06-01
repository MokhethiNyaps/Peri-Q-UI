import '../../models/menu_item.dart';
import '../../models/order.dart';
import '../../repositories/order_repository.dart';
import '../mock_data.dart';

class MockOrderRepository implements OrderRepository {
  MockOrderRepository({
    required List<MenuItemModel> seedMenuItems,
  }) : _orders = List<OrderModel>.from(MockData.initialOrders(seedMenuItems));

  final List<OrderModel> _orders;

  @override
  Future<List<OrderModel>> fetchOrders({
    String? userId,
    bool includeAll = false,
  }) async {
    return _orders.map(_cloneOrder).toList();
  }

  @override
  Future<OrderModel> createOrder(
    OrderDraft order, {
    String? userId,
  }) async {
    final createdOrder = OrderModel(
      id: 'order-${DateTime.now().millisecondsSinceEpoch}',
      orderNumber: _nextOrderNumber(),
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      items: order.items.map(_cloneCartItem).toList(),
      orderType: order.orderType,
      paymentMethod: order.paymentMethod,
      totalPrice: order.totalPrice,
      status: OrderStatus.pending,
      createdAt: DateTime.now(),
      estimatedMinutes: order.estimatedMinutes,
      deliveryAddress: order.deliveryAddress,
    );

    _orders.insert(0, createdOrder);
    return _cloneOrder(createdOrder);
  }

  @override
  Future<OrderModel> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    final index = _orders.indexWhere((order) => order.id == orderId);
    if (index == -1) {
      throw StateError('Order $orderId was not found.');
    }

    _orders[index].status = status;
    return _cloneOrder(_orders[index]);
  }

  int _nextOrderNumber() {
    if (_orders.isEmpty) {
      return 1001;
    }

    return _orders
            .map((order) => order.orderNumber)
            .reduce((highest, value) => value > highest ? value : highest) +
        1;
  }

  OrderModel _cloneOrder(OrderModel order) {
    return OrderModel(
      id: order.id,
      orderNumber: order.orderNumber,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      items: order.items.map(_cloneCartItem).toList(),
      orderType: order.orderType,
      paymentMethod: order.paymentMethod,
      totalPrice: order.totalPrice,
      status: order.status,
      createdAt: order.createdAt,
      estimatedMinutes: order.estimatedMinutes,
      deliveryAddress: order.deliveryAddress,
    );
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
}
