import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/order.dart';

class OrderStatusChip extends StatelessWidget {
  const OrderStatusChip({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final appColors = context.appColors;
    Color background;
    Color foreground;

    switch (status) {
      case OrderStatus.pending:
        background = appColors.warningContainer;
        foreground = appColors.onWarningContainer;
        break;
      case OrderStatus.preparing:
        background = appColors.accentContainer;
        foreground = appColors.onAccentContainer;
        break;
      case OrderStatus.ready:
        background = appColors.successContainer;
        foreground = appColors.onSuccessContainer;
        break;
      case OrderStatus.completed:
        background = appColors.sunkenSurface;
        foreground = colors.onSurface;
        break;
      case OrderStatus.cancelled:
        background = appColors.dangerContainer;
        foreground = appColors.onDangerContainer;
        break;
    }

    return Semantics(
      label: 'Order status: ${status.label}',
      child: ExcludeSemantics(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppRadii.pill),
            border: Border.all(color: foreground.withValues(alpha: 0.28)),
          ),
          child: Text(
            status.label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
    );
  }
}
