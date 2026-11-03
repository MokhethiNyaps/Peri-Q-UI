import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:url_launcher/url_launcher.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/payment_config.dart';
import '../../core/payment_session.dart';
import '../../core/policy_version.dart';
import '../../models/menu_item.dart';
import '../../models/order.dart';
import '../../repositories/order_repository.dart';

class SupabaseOrderRepository implements OrderRepository {
  SupabaseOrderRepository({required this._client});

  final SupabaseClient _client;

  static const _orderSelect = '''
*,
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
        ? await builder.order('created_at', ascending: false).limit(100)
        : await builder
              .eq('user_id', userId!)
              .order('created_at', ascending: false)
              .limit(100);

    return (response as List<dynamic>)
        .map((row) => _fromOrderRow(row as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<OrderModel> createOrder(OrderDraft order, {String? userId}) async {
    if (order.paymentMethod != PaymentMethod.yoco) {
      throw const OrderSubmissionException('Only card payment is accepted.');
    }
    if (userId == null || userId.isEmpty) {
      throw StateError(
        'A signed-in Supabase user is required to place orders.',
      );
    }

    final session = CardPaymentSession.instance;
    session.preparing();
    try {
      final response = await _client.rpc(
        'prepare_card_checkout',
        params: {
          'p_customer_name': order.customerName,
          'p_customer_phone': order.customerPhone,
          'p_order_type': order.orderType.code,
          'p_payment_method': order.paymentMethod.code,
          'p_delivery_address': order.deliveryAddress,
          'p_expected_total': order.totalPrice,
          'p_client_request_id': order.clientRequestId,
          'p_items': order.items
              .map(
                (item) => {
                  'menu_item_id': item.item.id,
                  'quantity': item.quantity,
                  'spice_level': item.spiceLevel,
                  'notes': item.notes,
                  'selected_add_ons': item.selectedAddOns
                      .map((addOn) => {'name': addOn.name})
                      .toList(),
                },
              )
              .toList(),
        },
      );
      final result = response as Map<String, dynamic>;
      final orderId = result['id'] as String?;
      if (orderId == null || orderId.isEmpty) {
        throw const OrderSubmissionException(
          'The store did not return an order confirmation. Please try again.',
        );
      }
      final existingPaid = await _client
          .from('orders')
          .select(_orderSelect)
          .eq('id', orderId)
          .maybeSingle();
      if (existingPaid != null && existingPaid['payment_status'] == 'paid') {
        return _fromOrderRow(existingPaid);
      }
      // The customer ticked the policy box on the checkout screen. Saved
      // before payment opens, against the draft that becomes the order.
      try {
        await _client.rpc(
          'record_policy_acceptance',
          params: {
            'p_version': policyVersion,
            'p_context': 'checkout',
            'p_client': 'android',
            'p_checkout_id': orderId,
          },
        );
      } on PostgrestException {
        throw const OrderSubmissionException(
          'Could not record your acceptance of our terms. Please try again; '
          'your cart is saved.',
        );
      }
      final checkoutUrl = await _requestCheckoutUrl(orderId);
      if (!await _openSecurePaymentPage(checkoutUrl)) {
        throw const OrderSubmissionException(
          'Could not open secure card checkout. Your cart is saved.',
        );
      }
      session.opened(orderId: orderId, checkoutUrl: checkoutUrl);
      return await _awaitConfirmedPayment(orderId, session);
    } on PostgrestException catch (error) {
      throw OrderSubmissionException(_friendlyOrderError(error));
    } finally {
      session.finish();
    }
  }

  /// Asks the website's server to create the hosted card checkout for this
  /// order. The server checks ownership, amount and payment state; the app
  /// never holds payment-provider credentials.
  Future<Uri> _requestCheckoutUrl(String orderId) async {
    final checkoutEndpoint = cardCheckoutUri();
    if (checkoutEndpoint == null) {
      throw const OrderSubmissionException(
        'Card payments are temporarily unavailable. Your cart is saved.',
      );
    }
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 20);
    try {
      final request = await client.postUrl(checkoutEndpoint);
      request.headers.contentType = ContentType.json;
      request.headers.set(
        'Authorization',
        'Bearer ${_client.auth.currentSession?.accessToken ?? ''}',
      );
      request.write(jsonEncode({'orderId': orderId, 'source': 'mobile'}));
      final response = await request.close();
      final body =
          jsonDecode(await utf8.decoder.bind(response).join())
              as Map<String, dynamic>;
      final redirect = body['redirectUrl'];
      final uri = redirect is String ? Uri.tryParse(redirect) : null;
      if (response.statusCode != 200 || uri == null || uri.scheme != 'https') {
        throw OrderSubmissionException(
          body['error'] as String? ??
              'Card checkout is unavailable. Your cart is saved.',
        );
      }
      return uri;
    } finally {
      client.close();
    }
  }

  /// Opens the secure payment page in a browser sheet on top of the app
  /// (Chrome Custom Tab on Android, Safari view on iOS) so the customer never
  /// leaves RastasperiQ. Falls back to the full browser if no in-app browser
  /// is available on the device.
  Future<bool> _openSecurePaymentPage(Uri checkoutUrl) async {
    try {
      if (await launchUrl(checkoutUrl, mode: LaunchMode.inAppBrowserView)) {
        return true;
      }
    } catch (_) {
      // Fall through to the device browser.
    }
    return launchUrl(checkoutUrl, mode: LaunchMode.externalApplication);
  }

  /// Waits until the database shows the order as paid. The return link from
  /// the payment page only decides how long to wait and what to tell the
  /// customer; it never marks anything as paid.
  Future<OrderModel> _awaitConfirmedPayment(
    String orderId,
    CardPaymentSession session,
  ) async {
    PaymentReturn? latestReturn;
    Completer<void>? wake;
    final subscription = session.returns.listen((paymentReturn) {
      latestReturn = paymentReturn;
      final pending = wake;
      if (pending != null && !pending.isCompleted) pending.complete();
    });
    final waitingSince = DateTime.now();
    DateTime? confirmingSince;
    try {
      while (DateTime.now().difference(waitingSince) < _paymentWaitLimit) {
        final paid = await _client
            .from('orders')
            .select(_orderSelect)
            .eq('id', orderId)
            .maybeSingle();
        if (paid != null && paid['payment_status'] == 'paid') {
          return _fromOrderRow(paid);
        }
        final draft = await _client
            .from('checkout_intents')
            .select('payment_status')
            .eq('id', orderId)
            .single();
        if (draft['payment_status'] == 'failed') {
          throw const OrderSubmissionException(
            'The payment did not go through and no order was placed. '
            'Your cart is saved, so you can try again.',
          );
        }

        final returned = latestReturn?.result;
        if (returned == PaymentReturnResult.cancelled) {
          throw const OrderSubmissionException(
            'Payment cancelled. Your cart is saved.',
          );
        }
        if (returned == PaymentReturnResult.failed) {
          throw const OrderSubmissionException(
            'The payment did not go through and no order was placed. '
            'Your cart is saved, so you can try again.',
          );
        }
        if (returned == PaymentReturnResult.abandoned) {
          throw const OrderSubmissionException(
            'Payment not completed. Your cart is saved. If you did pay, '
            'your order will appear in Orders within a few minutes.',
          );
        }
        if (returned == PaymentReturnResult.success) {
          final since = confirmingSince ??= DateTime.now();
          session.confirming();
          if (DateTime.now().difference(since) > _confirmationWaitLimit) {
            throw _notConfirmedYet;
          }
        }

        // Check again soon; wake straight away if the customer comes back.
        final pending = Completer<void>();
        wake = pending;
        final interval = confirmingSince == null
            ? const Duration(seconds: 3)
            : const Duration(seconds: 1);
        await Future.any([pending.future, Future<void>.delayed(interval)]);
        wake = null;
      }
      throw _notConfirmedYet;
    } finally {
      await subscription.cancel();
    }
  }

  static const _paymentWaitLimit = Duration(minutes: 10);
  static const _confirmationWaitLimit = Duration(seconds: 90);
  static const _notConfirmedYet = OrderSubmissionException(
    'Payment is not confirmed yet. Your cart is saved. A successful payment '
    'will appear in Orders, even if you close the app.',
  );

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
      paymentProofPath: row['payment_proof_path'] as String?,
      paymentStatus: paymentStatusFromCode(
        row['payment_status'] as String? ?? 'unpaid',
      ),
      yocoCheckoutId: row['yoco_checkout_id'] as String?,
      paidAt: row['paid_at'] != null
          ? DateTime.tryParse(row['paid_at'] as String)
          : null,
      yocoPaymentId: row['yoco_payment_id'] as String?,
      yocoMode: row['yoco_mode'] as String?,
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

  @override
  Stream<void> watchOrders({String? userId, bool includeAll = false}) {
    if (!includeAll && (userId == null || userId.isEmpty)) {
      return const Stream<void>.empty();
    }
    if (includeAll) {
      return _client.from('orders').stream(primaryKey: ['id']).map((_) {});
    }
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId!)
        .map((_) {});
  }

  @override
  Future<String> uploadPaymentProof({
    required String orderId,
    required List<int> bytes,
    required String fileName,
    required String contentType,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw const OrderSubmissionException('Sign in again before uploading.');
    }
    if (bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      throw const OrderSubmissionException(
        'Choose a JPG, PNG, WebP or PDF file smaller than 5 MB.',
      );
    }
    const allowedTypes = {
      'image/jpeg',
      'image/png',
      'image/webp',
      'application/pdf',
    };
    if (!allowedTypes.contains(contentType)) {
      throw const OrderSubmissionException(
        'Only JPG, PNG, WebP and PDF proof files are accepted.',
      );
    }
    final safeName = fileName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9._-]+'), '-')
        .replaceAll(RegExp(r'-+'), '-');
    final path =
        '${user.id}/$orderId/${DateTime.now().millisecondsSinceEpoch}-$safeName';
    try {
      await _client.storage
          .from('payment-proofs')
          .uploadBinary(
            path,
            Uint8List.fromList(bytes),
            fileOptions: FileOptions(contentType: contentType, upsert: false),
          );
      await _client.rpc(
        'attach_payment_proof',
        params: {'p_order_id': orderId, 'p_storage_path': path},
      );
      return path;
    } on StorageException catch (error) {
      throw OrderSubmissionException(
        error.statusCode == '413'
            ? 'The selected proof file is too large.'
            : 'The proof could not be uploaded. Check your connection and try again.',
      );
    } on PostgrestException {
      try {
        await _client.storage.from('payment-proofs').remove([path]);
      } catch (_) {
        // The private orphan cannot be read publicly and can be removed by staff.
      }
      throw const OrderSubmissionException(
        'The proof uploaded but could not be linked to this order. Please try again.',
      );
    }
  }

  String _friendlyOrderError(PostgrestException error) {
    final message = error.message.toLowerCase();
    if (message.contains('store is closed') ||
        message.contains('ordering is paused')) {
      return 'Ordering is currently paused. Please try again during store hours.';
    }
    if (message.contains('pickup is unavailable')) {
      return 'Pickup is not available right now. Choose delivery instead.';
    }
    if (message.contains('delivery is unavailable')) {
      return 'Delivery is not available right now. Choose pickup instead.';
    }
    if (message.contains('price changed')) {
      return 'A price changed while you were checking out. Review the updated cart total and submit again.';
    }
    if (message.contains('unavailable') || message.contains('not found')) {
      return 'An item in your cart is no longer available. Return to the menu and update your cart.';
    }
    if (message.contains('invalid payment')) {
      return 'That payment method is not available for this order type.';
    }
    return 'We could not place the order. Check your connection and try again; your cart is still saved.';
  }
}
