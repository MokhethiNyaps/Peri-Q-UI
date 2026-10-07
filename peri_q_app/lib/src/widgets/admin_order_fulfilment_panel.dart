import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/order.dart';

/// Displays private fulfilment details inside the admin-only order dashboard.
class AdminOrderFulfilmentPanel extends StatelessWidget {
  const AdminOrderFulfilmentPanel({super.key, required this.order});

  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    final isDelivery = order.orderType == OrderType.delivery;
    final deliveryAddress = order.deliveryAddress?.trim() ?? '';
    final panelColor = isDelivery
        ? context.appColors.accentContainer
        : context.appColors.sunkenSurface;
    final panelForeground = isDelivery
        ? context.appColors.onAccentContainer
        : Theme.of(context).colorScheme.onSurface;

    return Container(
      key: ValueKey('admin-order-fulfilment-${order.id}'),
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(color: panelForeground.withValues(alpha: 0.32)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isDelivery
                    ? Icons.delivery_dining_rounded
                    : Icons.storefront_rounded,
                color: panelForeground,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  order.orderType.label,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: panelForeground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _AdminOrderDetailRow(
            icon: Icons.person_outline_rounded,
            label: 'Customer',
            value: order.customerName.trim().isEmpty
                ? 'Not recorded on this order'
                : order.customerName.trim(),
            valueKey: ValueKey('admin-order-customer-${order.id}'),
          ),
          const SizedBox(height: 10),
          _AdminOrderDetailRow(
            icon: Icons.phone_outlined,
            label: 'Phone number',
            value: order.customerPhone.trim().isEmpty
                ? 'Not recorded on this order'
                : order.customerPhone.trim(),
            valueKey: ValueKey('admin-order-phone-${order.id}'),
          ),
          const SizedBox(height: 10),
          if (isDelivery)
            _AdminOrderDetailRow(
              icon: Icons.location_on_outlined,
              label: 'Delivery address & instructions',
              value: deliveryAddress.isEmpty
                  ? 'Not recorded on this order'
                  : deliveryAddress,
              valueKey: ValueKey('admin-order-address-${order.id}'),
              isWarning: deliveryAddress.isEmpty,
            )
          else
            const _AdminOrderDetailRow(
              icon: Icons.check_circle_outline_rounded,
              label: 'Collection',
              value: 'Customer collects at the store; no address required.',
            ),
          const SizedBox(height: 10),
          _AdminOrderDetailRow(
            icon: Icons.payments_outlined,
            label: 'Payment',
            value: order.paymentMethod.label,
          ),
        ],
      ),
    );
  }
}

class _AdminOrderDetailRow extends StatelessWidget {
  const _AdminOrderDetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueKey,
    this.isWarning = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Key? valueKey;
  final bool isWarning;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 19,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              SelectableText(
                value,
                key: valueKey,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isWarning
                      ? Theme.of(context).colorScheme.error
                      : Theme.of(context).colorScheme.onSurface,
                  fontWeight: isWarning ? FontWeight.w800 : FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
