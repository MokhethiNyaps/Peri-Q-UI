import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../widgets/order_status_chip.dart';
import 'admin_menu_item_editor_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key, required this.controller});

  final AppController controller;

  Future<void> _openMenuEditor(
    BuildContext context, {
    MenuItemModel? item,
  }) async {
    final didSave = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) =>
            AdminMenuItemEditorScreen(controller: controller, item: item),
      ),
    );

    if (didSave != true || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(item == null ? 'Menu item added.' : 'Menu item updated.'),
      ),
    );
  }

  Future<void> _rejectOrder(BuildContext context, OrderModel order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Reject this order?'),
          content: Text(
            'Order #${order.orderNumber} will move out of the active queue.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Keep Order'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Reject Order'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await controller.rejectOrder(order);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Order #${order.orderNumber} marked as cancelled.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (!controller.canAccessAdmin) {
          return Scaffold(
            appBar: AppBar(title: const Text('Owner Dashboard')),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Sign in with a Supabase account that has the admin role to manage orders and menu items.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Owner Dashboard')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openMenuEditor(context),
            backgroundColor: AppTheme.periRed,
            icon: const Icon(Icons.add),
            label: const Text('Menu Item'),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppTheme.smokeCharcoal,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.storeOpen
                                ? 'Store Open'
                                : 'Store Closed',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(color: Colors.white),
                          ),
                          Text(
                            'Switch store availability for customers instantly.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: controller.storeOpen,
                      activeThumbColor: AppTheme.chesaOrange,
                      onChanged: (value) async {
                        try {
                          await controller.toggleStoreOpen(value);
                        } catch (error) {
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: [
                  _MetricCard(
                    title: 'Active Orders',
                    value: '${controller.activeOrders.length}',
                  ),
                  _MetricCard(
                    title: "Today's Sales",
                    value:
                        'R${controller.orders.fold<double>(0, (sum, order) => sum + order.totalPrice).toStringAsFixed(0)}',
                  ),
                  _MetricCard(
                    title: 'Completed',
                    value: '${controller.completedOrders.length}',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Incoming Orders',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 14),
              if (controller.activeOrders.isEmpty)
                const _EmptyAdminState(
                  message: 'No active orders in the queue right now.',
                )
              else
                ...controller.activeOrders.map(
                  (order) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _IncomingOrderCard(
                      order: order,
                      onReject: () => _rejectOrder(context, order),
                      onAdvance: () async {
                        await controller.advanceOrderStatus(order);
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              Text(
                'Menu Management',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Add new dishes or update availability and pricing from one place.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 14),
              ...controller.menuItems.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: _MenuItemCard(
                    item: item,
                    onEdit: () => _openMenuEditor(context, item: item),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 150,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
          ],
        ),
      ),
    );
  }
}

class _IncomingOrderCard extends StatelessWidget {
  const _IncomingOrderCard({
    required this.order,
    required this.onReject,
    required this.onAdvance,
  });

  final OrderModel order;
  final VoidCallback onReject;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                '#${order.orderNumber}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              OrderStatusChip(status: order.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            order.customerName,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            order.orderType.label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          ...order.items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '${item.quantity} x ${item.item.name}${item.notes.isNotEmpty ? ' • ${item.notes}' : ''}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onReject,
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAdvance,
                  child: Text(switch (order.status) {
                    OrderStatus.pending => 'Accept & Start Cooking',
                    OrderStatus.preparing => 'Mark Ready',
                    OrderStatus.ready => 'Mark Completed',
                    OrderStatus.completed => 'Completed',
                    OrderStatus.cancelled => 'Cancelled',
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({required this.item, required this.onEdit});

  final MenuItemModel item;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              item.imagePath,
              width: 72,
              height: 72,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  item.category,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'R${item.price.toStringAsFixed(0)}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: AppTheme.periRed),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: item.isAvailable
                        ? AppTheme.success.withValues(alpha: 0.12)
                        : AppTheme.periRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    item.isAvailable ? 'Available' : 'Hidden',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: item.isAvailable
                          ? AppTheme.success
                          : AppTheme.periRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          OutlinedButton(onPressed: onEdit, child: const Text('Edit')),
        ],
      ),
    );
  }
}

class _EmptyAdminState extends StatelessWidget {
  const _EmptyAdminState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
