import '../models/order.dart';

class OrderSubmissionException implements Exception {
  const OrderSubmissionException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class OrderRepository {
  Future<List<OrderModel>> fetchOrders({
    String? userId,
    bool includeAll = false,
  });

  Future<OrderModel> createOrder(OrderDraft order, {String? userId});

  Future<OrderModel> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  });

  Stream<void> watchOrders({String? userId, bool includeAll = false}) =>
      const Stream<void>.empty();

  Future<String> uploadPaymentProof({
    required String orderId,
    required List<int> bytes,
    required String fileName,
    required String contentType,
  }) => throw UnsupportedError('Payment proof uploads are not configured.');
}
