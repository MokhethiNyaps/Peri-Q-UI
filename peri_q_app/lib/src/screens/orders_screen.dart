import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../models/order.dart';
import '../widgets/order_status_chip.dart';
import '../widgets/section_header.dart';
import 'cart_screen.dart';
import 'tracking_screen.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
            children: [
              Text(
                'My Orders',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 20),
              const SectionHeader(title: 'Active Orders'),
              const SizedBox(height: 12),
              if (controller.activeOrders.isEmpty)
                const _EmptyState(message: 'No active orders right now.')
              else
                ...controller.activeOrders.map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _OrderCard(
                      order: order,
                      actionLabel: 'Track',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TrackingScreen(
                              order: order,
                              controller: controller,
                            ),
                          ),
                        );
                      },
                      onAction: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TrackingScreen(
                              order: order,
                              controller: controller,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 18),
              const SectionHeader(title: 'Order History'),
              const SizedBox(height: 12),
              if (controller.completedOrders.isEmpty)
                const _EmptyState(message: 'Past orders will appear here.')
              else
                ...controller.completedOrders.map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _OrderCard(
                      order: order,
                      actionLabel: 'Reorder',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TrackingScreen(
                              order: order,
                              controller: controller,
                            ),
                          ),
                        );
                      },
                      onAction: () {
                        controller.reorder(order);
                        final quantity = order.items.fold<int>(
                          0,
                          (sum, item) => sum + item.quantity,
                        );
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => CartScreen(
                              controller: controller,
                              bannerMessage:
                                  '$quantity item${quantity == 1 ? '' : 's'} added back to your cart.',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.actionLabel,
    required this.onAction,
    required this.onTap,
  });

  final OrderModel order;
  final String actionLabel;
  final VoidCallback onAction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appColors = context.appColors;
    final isTerminal =
        order.status == OrderStatus.completed ||
        order.status == OrderStatus.cancelled;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: appColors.elevatedSurface,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: appColors.softOutline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '#${order.orderNumber}',
                  style: theme.textTheme.titleLarge,
                ),
                const Spacer(),
                OrderStatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              order.items
                  .map((item) => '${item.quantity} x ${item.item.name}')
                  .join(', '),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            if (!isTerminal)
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: switch (order.status) {
                    OrderStatus.pending => 0.25,
                    OrderStatus.preparing => 0.55,
                    OrderStatus.ready => 0.85,
                    _ => 0.0,
                  },
                ),
              )
            else
              Row(
                children: [
                  Icon(
                    order.status == OrderStatus.completed
                        ? Icons.check_circle_outline_rounded
                        : Icons.cancel_outlined,
                    color: order.status == OrderStatus.completed
                        ? appColors.success
                        : theme.colorScheme.onSurfaceVariant,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    order.status.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: order.status == OrderStatus.completed
                          ? appColors.success
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'R${order.totalPrice.toStringAsFixed(0)}',
                  style: theme.textTheme.titleLarge,
                ),
                const Spacer(),
                TextButton(onPressed: onAction, child: Text(actionLabel)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final appColors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: appColors.elevatedSurface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: appColors.softOutline),
      ),
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
