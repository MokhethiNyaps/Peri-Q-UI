import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peri_q_app/src/models/order.dart';
import 'package:peri_q_app/src/widgets/admin_order_fulfilment_panel.dart';

void main() {
  testWidgets('delivery order exposes contact and delivery details to admin', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testApp(
        _order(
          orderType: OrderType.delivery,
          paymentMethod: PaymentMethod.cashDelivery,
          deliveryAddress:
              '12 Main Street, Bloemfontein\nRing the side gate bell.',
        ),
      ),
    );

    expect(find.text('Home Delivery'), findsOneWidget);
    expect(find.text('Test Customer'), findsOneWidget);
    expect(find.text('+27 71 234 5678'), findsOneWidget);
    expect(find.text('Delivery address & instructions'), findsOneWidget);
    expect(
      find.text('12 Main Street, Bloemfontein\nRing the side gate bell.'),
      findsOneWidget,
    );
    expect(find.text('Cash on Delivery'), findsOneWidget);
  });

  testWidgets('pickup order clearly requires no delivery address', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(_order(orderType: OrderType.pickup)));

    expect(find.text('Pickup in Store'), findsOneWidget);
    expect(
      find.text('Customer collects at the store; no address required.'),
      findsOneWidget,
    );
    expect(find.text('Delivery address & instructions'), findsNothing);
  });

  testWidgets('legacy delivery order warns when its address was not recorded', (
    tester,
  ) async {
    await tester.pumpWidget(_testApp(_order(orderType: OrderType.delivery)));

    expect(find.text('Delivery address & instructions'), findsOneWidget);
    expect(find.text('Not recorded on this order'), findsOneWidget);
  });
}

Widget _testApp(OrderModel order) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: AdminOrderFulfilmentPanel(order: order),
      ),
    ),
  );
}

OrderModel _order({
  required OrderType orderType,
  PaymentMethod paymentMethod = PaymentMethod.cashCollection,
  String? deliveryAddress,
}) {
  return OrderModel(
    id: 'order-1',
    orderNumber: 101,
    customerName: 'Test Customer',
    customerPhone: '+27 71 234 5678',
    items: const [],
    orderType: orderType,
    paymentMethod: paymentMethod,
    totalPrice: 125,
    status: OrderStatus.pending,
    createdAt: DateTime(2026, 8, 1),
    estimatedMinutes: 45,
    deliveryAddress: deliveryAddress,
  );
}
