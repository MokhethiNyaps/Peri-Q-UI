import 'menu_item.dart';

enum OrderStatus { pending, preparing, ready, completed, cancelled }

enum OrderType { pickup, delivery }

enum PaymentMethod { cashCollection, cashDelivery, eft, card, yoco }

enum PaymentStatus {
  unpaid,
  pending,
  paid,
  failed,
  cancelled,
  expired,
  refunded,
}

extension OrderStatusX on OrderStatus {
  String get code {
    switch (this) {
      case OrderStatus.pending:
        return 'pending';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.ready:
        return 'ready';
      case OrderStatus.completed:
        return 'completed';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

extension OrderTypeX on OrderType {
  String get code => this == OrderType.pickup ? 'pickup' : 'delivery';

  String get label =>
      this == OrderType.pickup ? 'Pickup in Store' : 'Home Delivery';
}

extension PaymentMethodX on PaymentMethod {
  String get code {
    switch (this) {
      case PaymentMethod.cashCollection:
        return 'cash_collection';
      case PaymentMethod.cashDelivery:
        return 'cash_delivery';
      case PaymentMethod.eft:
        return 'eft';
      case PaymentMethod.card:
        return 'card';
      case PaymentMethod.yoco:
        return 'yoco';
    }
  }

  String get label {
    switch (this) {
      case PaymentMethod.cashCollection:
        return 'Cash on Collection';
      case PaymentMethod.cashDelivery:
        return 'Cash on Delivery';
      case PaymentMethod.eft:
        return 'EFT';
      case PaymentMethod.card:
        return 'Card';
      case PaymentMethod.yoco:
        return 'Yoco';
    }
  }
}

extension PaymentStatusX on PaymentStatus {
  String get code {
    switch (this) {
      case PaymentStatus.unpaid:
        return 'unpaid';
      case PaymentStatus.pending:
        return 'pending';
      case PaymentStatus.paid:
        return 'paid';
      case PaymentStatus.failed:
        return 'failed';
      case PaymentStatus.cancelled:
        return 'cancelled';
      case PaymentStatus.expired:
        return 'expired';
      case PaymentStatus.refunded:
        return 'refunded';
    }
  }
}

OrderStatus orderStatusFromCode(String code) {
  return OrderStatus.values.firstWhere(
    (status) => status.code == code,
    orElse: () => OrderStatus.pending,
  );
}

OrderType orderTypeFromCode(String code) {
  return OrderType.values.firstWhere(
    (type) => type.code == code,
    orElse: () => OrderType.pickup,
  );
}

PaymentMethod paymentMethodFromCode(String code) {
  return PaymentMethod.values.firstWhere(
    (method) => method.code == code,
    orElse: () => PaymentMethod.cashCollection,
  );
}

PaymentStatus paymentStatusFromCode(String code) {
  return PaymentStatus.values.firstWhere(
    (status) => status.code == code,
    orElse: () => PaymentStatus.unpaid,
  );
}

class OrderDraft {
  const OrderDraft({
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.orderType,
    required this.paymentMethod,
    required this.totalPrice,
    required this.estimatedMinutes,
    required this.clientRequestId,
    this.deliveryAddress,
  });

  final String customerName;
  final String customerPhone;
  final List<CartItemModel> items;
  final OrderType orderType;
  final PaymentMethod paymentMethod;
  final double totalPrice;
  final int estimatedMinutes;
  final String clientRequestId;
  final String? deliveryAddress;

  Map<String, dynamic> toJson() {
    return {
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items.map((item) => item.toJson()).toList(),
      'orderType': orderType.code,
      'paymentMethod': paymentMethod.code,
      'totalPrice': totalPrice,
      'estimatedMinutes': estimatedMinutes,
      'clientRequestId': clientRequestId,
      'deliveryAddress': deliveryAddress,
    };
  }
}

class OrderModel {
  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.customerName,
    required this.customerPhone,
    required this.items,
    required this.orderType,
    required this.paymentMethod,
    required this.totalPrice,
    required this.status,
    required this.createdAt,
    required this.estimatedMinutes,
    this.paymentProofPath,
    this.deliveryAddress,
    this.paymentStatus = PaymentStatus.unpaid,
    this.yocoCheckoutId,
    this.paidAt,
    this.yocoPaymentId,
    this.yocoMode,
  });

  final String id;
  final int orderNumber;
  final String customerName;
  final String customerPhone;
  final List<CartItemModel> items;
  final OrderType orderType;
  final PaymentMethod paymentMethod;
  final double totalPrice;
  OrderStatus status;
  final DateTime createdAt;
  final int estimatedMinutes;
  final String? paymentProofPath;
  final String? deliveryAddress;
  final PaymentStatus paymentStatus;
  final String? yocoCheckoutId;
  final DateTime? paidAt;
  final String? yocoPaymentId;
  final String? yocoMode;

  bool get isActive =>
      status == OrderStatus.pending ||
      status == OrderStatus.preparing ||
      status == OrderStatus.ready;

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'] as String? ?? '',
      orderNumber: json['orderNumber'] as int? ?? 0,
      customerName: json['customerName'] as String? ?? '',
      customerPhone: json['customerPhone'] as String? ?? '',
      items:
          (json['items'] as List<dynamic>?)
              ?.map(
                (item) => CartItemModel.fromJson(item as Map<String, dynamic>),
              )
              .toList() ??
          const [],
      orderType: orderTypeFromCode(json['orderType'] as String? ?? 'pickup'),
      paymentMethod: paymentMethodFromCode(
        json['paymentMethod'] as String? ?? 'cash_collection',
      ),
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      status: orderStatusFromCode(json['status'] as String? ?? 'pending'),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      estimatedMinutes: json['estimatedMinutes'] as int? ?? 0,
      paymentProofPath: json['paymentProofPath'] as String?,
      deliveryAddress: json['deliveryAddress'] as String?,
      paymentStatus: paymentStatusFromCode(
        json['paymentStatus'] as String? ??
            json['payment_status'] as String? ??
            'unpaid',
      ),
      yocoCheckoutId:
          json['yocoCheckoutId'] as String? ??
          json['yoco_checkout_id'] as String?,
      paidAt: json['paidAt'] != null
          ? DateTime.tryParse(json['paidAt'] as String)
          : json['paid_at'] != null
          ? DateTime.tryParse(json['paid_at'] as String)
          : null,
      yocoPaymentId:
          json['yocoPaymentId'] as String? ??
          json['yoco_payment_id'] as String?,
      yocoMode: json['yocoMode'] as String? ?? json['yoco_mode'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderNumber': orderNumber,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'items': items.map((item) => item.toJson()).toList(),
      'orderType': orderType.code,
      'paymentMethod': paymentMethod.code,
      'totalPrice': totalPrice,
      'status': status.code,
      'createdAt': createdAt.toIso8601String(),
      'estimatedMinutes': estimatedMinutes,
      'paymentProofPath': paymentProofPath,
      'deliveryAddress': deliveryAddress,
      'paymentStatus': paymentStatus.code,
      'yocoCheckoutId': yocoCheckoutId,
      'paidAt': paidAt?.toIso8601String(),
      'yocoPaymentId': yocoPaymentId,
      'yocoMode': yocoMode,
    };
  }
}
