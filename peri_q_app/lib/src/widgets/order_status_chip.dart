import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/order.dart';

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({
    super.key,
    required this.status,
  });

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    Color background;
    Color foreground;

    switch (status) {
      case OrderStatus.pending:
        background = AppTheme.warning.withValues(alpha: 0.18);
        foreground = AppTheme.warning;
      case OrderStatus.preparing:
        background = AppTheme.chesaOrange.withValues(alpha: 0.18);
        foreground = AppTheme.chesaOrange;
      case OrderStatus.ready:
        background = AppTheme.success.withValues(alpha: 0.18);
        foreground = AppTheme.success;
      case OrderStatus.completed:
        background = Colors.grey.shade200;
        foreground = AppTheme.ashGrey;
      case OrderStatus.cancelled:
        background = AppTheme.periRed.withValues(alpha: 0.12);
        foreground = AppTheme.periRed;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
