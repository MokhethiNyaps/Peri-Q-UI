import '../models/order.dart';

abstract interface class NotificationRepository {
  Future<void> registerForSession({
    required String userId,
    required bool isAdmin,
  });

  Future<void> unregisterCurrentSession();

  Future<void> notifyNewOrder(OrderModel order);

  Future<void> notifyOrderStatusChanged(OrderModel order);

  void dispose();
}

class NoopNotificationRepository implements NotificationRepository {
  const NoopNotificationRepository();

  @override
  Future<void> registerForSession({
    required String userId,
    required bool isAdmin,
  }) async {}

  @override
  Future<void> unregisterCurrentSession() async {}

  @override
  Future<void> notifyNewOrder(OrderModel order) async {}

  @override
  Future<void> notifyOrderStatusChanged(OrderModel order) async {}

  @override
  void dispose() {}
}
