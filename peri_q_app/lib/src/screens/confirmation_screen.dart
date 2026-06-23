import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../models/order.dart';
import '../widgets/order_status_chip.dart';
import 'customer_shell.dart';
import 'tracking_screen.dart';

class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({
    super.key,
    required this.controller,
    required this.order,
  });

  final AppController controller;
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.success.withValues(alpha: 0.12),
                    ),
                  ),
                  const CircleAvatar(
                    radius: 38,
                    backgroundColor: AppTheme.success,
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Order Placed! Thanks, ${order.customerName.split(' ').first}.',
                style: Theme.of(context).textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Order #${order.orderNumber} • Ready in ${order.estimatedMinutes} minutes',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Receipt',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        OrderStatusChip(status: order.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Order Type: ${order.orderType.label}'),
                    Text('Payment: ${order.paymentMethod.label}'),
                    if (order.deliveryAddress != null &&
                        order.deliveryAddress!.isNotEmpty)
                      Text('Address: ${order.deliveryAddress}'),
                    const SizedBox(height: 12),
                    ...order.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${item.quantity} x ${item.item.name}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Text(
                          'Total',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        Text(
                          'R${order.totalPrice.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: AppTheme.periRed),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status Timeline',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    const _TimelineStep(
                      title: 'Order Received',
                      subtitle:
                          'Your order was sent to the store successfully.',
                      active: true,
                    ),
                    const _TimelineStep(
                      title: 'Preparing',
                      subtitle:
                          'The kitchen will start once the owner accepts it.',
                    ),
                    const _TimelineStep(
                      title: 'Ready / Completed',
                      subtitle:
                          'We will notify you when it is ready for collection.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TrackingScreen(order: order),
                    ),
                  );
                },
                child: const Text('Track Order'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => CustomerShell(
                        controller: controller,
                        initialIndex: 2,
                      ),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('Go to My Orders'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.title,
    required this.subtitle,
    this.active = false,
  });

  final String title;
  final String subtitle;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: active
                  ? AppTheme.success
                  : AppTheme.mutedSurface,
              child: active
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    )
                  : const SizedBox.shrink(),
            ),
            Container(width: 2, height: 38, color: AppTheme.mutedSurface),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
