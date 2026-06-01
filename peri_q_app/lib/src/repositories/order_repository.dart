import '../models/order.dart';

abstract class OrderRepository {
  Future<List<OrderModel>> fetchOrders({
    String? userId,
    bool includeAll = false,
  });

  Future<OrderModel> createOrder(
    OrderDraft order, {
    String? userId,
  });

  Future<OrderModel> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  });
}
