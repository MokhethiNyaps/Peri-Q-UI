import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/menu_item.dart';
import '../../models/order.dart';
import '../../repositories/order_repository.dart';

class SupabaseOrderRepository implements OrderRepository {
  SupabaseOrderRepository({required this._client});

  final SupabaseClient _client;

  static const _orderSelect = '''
id,
order_number,
customer_name,
customer_phone,
order_type,
payment_method,
total_price,
status,
created_at,
estimated_minutes,
delivery_address,
order_items (
  id,
  menu_item_id,
  item_name,
  item_description,
  item_image_path,
  item_category,
  unit_price,
  quantity,
  spice_level,
  notes,
  selected_add_ons
)
''';

  @override
  Future<List<OrderModel>> fetchOrders({
    String? userId,
    bool includeAll = false,
  }) async {
    if (!includeAll && (userId == null || userId.isEmpty)) {
      return const [];
    }

    final builder = _client.from('orders').select(_orderSelect);
    final response = includeAll
        ? await builder.order('created_at', ascending: false)
        : await builder
              .eq('user_id', userId!)
              .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((row) => _fromOrderRow(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<OrderModel> createOrder(OrderDraft order, {String? userId}) async {
    if (userId == null || userId.isEmpty) {
      throw StateError(
        'A signed-in Supabase user is required to place orders.',
      );
    }

    final createdOrder = await _client
        .from('orders')
        .insert({
          'user_id': userId,
          'customer_name': order.customerName,
          'customer_phone': order.customerPhone,
          'order_type': order.orderType.code,
          'payment_method': order.paymentMethod.code,
          'total_price': order.totalPrice,
          'status': OrderStatus.pending.code,
          'estimated_minutes': order.estimatedMinutes,
          'delivery_address': order.deliveryAddress,
        })
        .select('id, order_number, created_at')
        .single();

    final orderId = createdOrder['id'] as String;
    await _client
        .from('order_items')
        .insert(
          order.items.map((item) => _toOrderItemRow(orderId, item)).toList(),
        );

    return OrderModel(
      id: orderId,
      orderNumber: (createdOrder['order_number'] as num?)?.toInt() ?? 0,
      customerName: order.customerName,
      customerPhone: order.customerPhone,
      items: order.items.map(_cloneCartItem).toList(),
      orderType: order.orderType,
      paymentMethod: order.paymentMethod,
      totalPrice: order.totalPrice,
      status: OrderStatus.pending,
      createdAt:
          DateTime.tryParse(createdOrder['created_at'] as String? ?? '') ??
          DateTime.now(),
      estimatedMinutes: order.estimatedMinutes,
      deliveryAddress: order.deliveryAddress,
    );
  }

  @override
  Future<OrderModel> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    final response = await _client
        .from('orders')
        .update({'status': status.code})
        .eq('id', orderId)
        .select(_orderSelect)
        .single();

    return _fromOrderRow(response);
  }

  OrderModel _fromOrderRow(Map<String, dynamic> row) {
    final orderItems = row['order_items'] as List<dynamic>? ?? const [];

    return OrderModel(
      id: row['id'] as String? ?? '',
      orderNumber: (row['order_number'] as num?)?.toInt() ?? 0,
      customerName: row['customer_name'] as String? ?? '',
      customerPhone: row['customer_phone'] as String? ?? '',
      items: orderItems
          .map((item) => _fromOrderItemRow(item as Map<String, dynamic>))
          .toList(),
      orderType: orderTypeFromCode(row['order_type'] as String? ?? 'pickup'),
      paymentMethod: paymentMethodFromCode(
        row['payment_method'] as String? ?? 'cash_collection',
      ),
      totalPrice: (row['total_price'] as num?)?.toDouble() ?? 0,
      status: orderStatusFromCode(row['status'] as String? ?? 'pending'),
      createdAt:
          DateTime.tryParse(row['created_at'] as String? ?? '') ??
          DateTime.now(),
      estimatedMinutes: (row['estimated_minutes'] as num?)?.toInt() ?? 0,
      deliveryAddress: row['delivery_address'] as String?,
    );
  }

  CartItemModel _fromOrderItemRow(Map<String, dynamic> row) {
    return CartItemModel(
      id: row['id'] as String? ?? '',
      item: MenuItemModel(
        id: row['menu_item_id'] as String? ?? '',
        name: row['item_name'] as String? ?? '',
        description: row['item_description'] as String? ?? '',
        price: (row['unit_price'] as num?)?.toDouble() ?? 0,
        category: row['item_category'] as String? ?? '',
        imagePath: row['item_image_path'] as String? ?? '',
      ),
      quantity: (row['quantity'] as num?)?.toInt() ?? 1,
      spiceLevel: row['spice_level'] as String?,
      notes: row['notes'] as String? ?? '',
      selectedAddOns:
          (row['selected_add_ons'] as List<dynamic>?)
              ?.map(
                (entry) => AddOnOption.fromJson(entry as Map<String, dynamic>),
              )
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> _toOrderItemRow(String orderId, CartItemModel item) {
    return {
      'order_id': orderId,
      'menu_item_id': item.item.id,
      'item_name': item.item.name,
      'item_description': item.item.description,
      'item_image_path': item.item.imagePath,
      'item_category': item.item.category,
      'unit_price': item.item.price,
      'quantity': item.quantity,
      'spice_level': item.spiceLevel,
      'notes': item.notes,
      'selected_add_ons': item.selectedAddOns
          .map((addOn) => addOn.toJson())
          .toList(),
    };
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
