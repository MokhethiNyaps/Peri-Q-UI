import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../widgets/app_image.dart';
import '../widgets/admin_order_fulfilment_panel.dart';
import '../widgets/order_status_chip.dart';
import 'admin_app_settings_screen.dart';
import 'admin_category_manager_screen.dart';
import 'admin_menu_item_editor_screen.dart';
import 'admin_todays_special_editor_screen.dart';

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

  Future<void> _deleteMenuItem(BuildContext context, MenuItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete this item?'),
          content: Text('${item.name} will be removed from the menu.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    await controller.deleteMenuItem(item.id);
    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${item.name} deleted.')));
  }

  Future<void> _openTodaysSpecialEditor(BuildContext context) async {
    final didSave = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminTodaysSpecialEditorScreen(controller: controller),
      ),
    );

    if (didSave != true || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Today's Special updated.")));
  }

  Future<void> _openAppSettings(BuildContext context) async {
    final didSave = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AdminAppSettingsScreen(controller: controller),
      ),
    );

    if (didSave != true || !context.mounted) {
      return;
    }

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('App settings updated.')));
  }

  Future<void> _openCategoryManager(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminCategoryManagerScreen(controller: controller),
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
            icon: const Icon(Icons.add),
            label: const Text('Menu Item'),
          ),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: context.appColors.heroSurface,
                    borderRadius: BorderRadius.circular(AppRadii.panel),
                    border: Border.all(color: context.appColors.softOutline),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              controller.isStoreOpenNow
                                  ? 'Store Open'
                                  : 'Store Closed',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(
                                    color: context.appColors.heroOnSurface,
                                  ),
                            ),
                            Text(
                              controller.storeStatusLabel,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: context.appColors.heroOnSurface,
                                  ),
                            ),
                            Text(
                              '${controller.appSettings.openingTime} - ${controller.appSettings.closingTime}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: context.appColors.heroOnSurface,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: controller.storeOpen,
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
                Text(
                  'App Controls',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 14),
                _AdminActionCard(
                  icon: Icons.tune_rounded,
                  title: 'App Settings',
                  subtitle:
                      'Store hours, availability, and Today\'s Special content.',
                  onTap: () => _openAppSettings(context),
                ),
                const SizedBox(height: 12),
                _AdminActionCard(
                  icon: Icons.category_outlined,
                  title: 'Food Categories',
                  subtitle:
                      '${controller.menuCategories.length} categories available for menu items.',
                  onTap: () => _openCategoryManager(context),
                ),
                const SizedBox(height: 20),
                _TodaysSpecialAdminCard(
                  title: controller.todaysSpecialSettings.title,
                  subtitle: controller.todaysSpecialSettings.subtitle,
                  enabled: controller.todaysSpecialSettings.enabled,
                  onEdit: () => _openTodaysSpecialEditor(context),
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
                Row(
                  children: [
                    Text(
                      'Menu Items',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => _openMenuEditor(context),
                      child: const Text('Add New'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (controller.menuItems.isEmpty)
                  const _EmptyAdminState(message: 'No menu items found.')
                else
                  ...controller.menuItems.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _MenuItemCard(
                        item: item,
                        onEdit: () => _openMenuEditor(context, item: item),
                        onDelete: () => _deleteMenuItem(context, item),
                        onToggleAvailability: () async {
                          await controller.updateMenuItem(
                            item.copyWith(isAvailable: !item.isAvailable),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TodaysSpecialAdminCard extends StatelessWidget {
  const _TodaysSpecialAdminCard({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onEdit,
  });

  final String title;
  final String subtitle;
  final bool enabled;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: context.appColors.softOutline),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.local_fire_department_rounded,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Special",
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  enabled ? title : 'Hidden from customers',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (enabled)
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit'),
          ),
        ],
      ),
    );
  }
}

class _AdminActionCard extends StatelessWidget {
  const _AdminActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: context.appColors.softOutline),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
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
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(AppRadii.card),
          border: Border.all(color: context.appColors.softOutline),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: context.appColors.softOutline),
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
          AdminOrderFulfilmentPanel(order: order),
          const SizedBox(height: 14),
          Text(
            'Order items',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
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
          LayoutBuilder(
            builder: (context, constraints) {
              final rejectButton = OutlinedButton(
                onPressed: onReject,
                child: const Text('Reject'),
              );
              final advanceButton = ElevatedButton(
                onPressed: onAdvance,
                child: Text(switch (order.status) {
                  OrderStatus.pending => 'Accept & Start Cooking',
                  OrderStatus.preparing => 'Mark Ready',
                  OrderStatus.ready => 'Mark Completed',
                  OrderStatus.completed => 'Completed',
                  OrderStatus.cancelled => 'Cancelled',
                }),
              );
              final stackButtons =
                  constraints.maxWidth < 410 ||
                  MediaQuery.textScalerOf(context).scale(1) > 1.2;
              if (stackButtons) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    advanceButton,
                    const SizedBox(height: 10),
                    rejectButton,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(child: rejectButton),
                  const SizedBox(width: 12),
                  Expanded(child: advanceButton),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MenuItemCard extends StatelessWidget {
  const _MenuItemCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAvailability,
  });

  final MenuItemModel item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleAvailability;

  @override
  Widget build(BuildContext context) {
    final priceLabel = 'R${item.price.toStringAsFixed(0)}';

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
        side: BorderSide(color: context.appColors.softOutline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppImage(
                  imagePath: item.imagePath,
                  semanticLabel: '${item.name} photo',
                  width: 64,
                  height: 64,
                  borderRadius: BorderRadius.circular(12),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      _CategoryChip(label: item.category),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Menu item actions',
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        onEdit();
                        break;
                      case 'delete':
                        onDelete();
                        break;
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit item')),
                    PopupMenuItem(value: 'delete', child: Text('Delete item')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  priceLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Semantics(
                  button: true,
                  toggled: item.isAvailable,
                  label: item.isAvailable
                      ? 'Mark ${item.name} unavailable'
                      : 'Mark ${item.name} available',
                  child: InkWell(
                    onTap: onToggleAvailability,
                    borderRadius: BorderRadius.circular(AppRadii.pill),
                    child: _AvailabilityPill(isAvailable: item.isAvailable),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: context.appColors.sunkenSurface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _AvailabilityPill extends StatelessWidget {
  const _AvailabilityPill({required this.isAvailable});

  final bool isAvailable;

  @override
  Widget build(BuildContext context) {
    final background = isAvailable
        ? context.appColors.successContainer
        : context.appColors.dangerContainer;
    final foreground = isAvailable
        ? context.appColors.onSuccessContainer
        : context.appColors.onDangerContainer;
    return Container(
      constraints: const BoxConstraints(minHeight: 48),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Text(
        isAvailable ? 'Available' : 'Unavailable',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w800,
        ),
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
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: context.appColors.softOutline),
      ),
      child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
    );
  }
}
