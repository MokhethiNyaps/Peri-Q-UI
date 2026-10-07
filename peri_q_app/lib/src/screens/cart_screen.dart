import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../models/order.dart';
import '../widgets/app_image.dart';
import 'checkout_screen.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key, required this.controller, this.bannerMessage});

  final AppController controller;
  final String? bannerMessage;

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.bannerMessage == null) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(widget.bannerMessage!)));
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final colors = theme.colorScheme;
        final appColors = context.appColors;
        return Scaffold(
          appBar: AppBar(title: const Text('Your Cart')),
          body: widget.controller.cart.isEmpty
              ? LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: (constraints.maxHeight - 48)
                            .clamp(0, double.infinity)
                            .toDouble(),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 72,
                            color: colors.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Your cart is empty.',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Add a few meals and come back to checkout.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
                  children: [
                    ...widget.controller.cart.map((cartItem) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: appColors.elevatedSurface,
                            borderRadius: BorderRadius.circular(AppRadii.card),
                            border: Border.all(color: appColors.softOutline),
                            boxShadow: [
                              BoxShadow(
                                color: appColors.shadow,
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  AppImage(
                                    imagePath: cartItem.item.imagePath,
                                    semanticLabel:
                                        '${cartItem.item.name} photo',
                                    width: 72,
                                    height: 72,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          cartItem.item.name,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleLarge,
                                        ),
                                        if (cartItem.spiceLevel != null)
                                          Text(
                                            'Spice: ${cartItem.spiceLevel}',
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        if (cartItem.selectedAddOns.isNotEmpty)
                                          Text(
                                            cartItem.selectedAddOns
                                                .map((addOn) => addOn.name)
                                                .join(', '),
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        if (cartItem.notes.isNotEmpty)
                                          Text(
                                            cartItem.notes,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Remove ${cartItem.item.name}',
                                    onPressed: () => widget.controller
                                        .removeCartItem(cartItem),
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color: appColors.sunkenSurface,
                                      borderRadius: BorderRadius.circular(
                                        AppRadii.input,
                                      ),
                                      border: Border.all(
                                        color: appColors.softOutline,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        IconButton(
                                          tooltip: 'Decrease quantity',
                                          onPressed: () => widget.controller
                                              .decrementCartItem(cartItem),
                                          icon: const Icon(
                                            Icons.remove_rounded,
                                          ),
                                        ),
                                        Text(
                                          '${cartItem.quantity}',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleLarge,
                                        ),
                                        IconButton(
                                          tooltip: 'Increase quantity',
                                          onPressed: () => widget.controller
                                              .incrementCartItem(cartItem),
                                          icon: const Icon(Icons.add_rounded),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'R${cartItem.total.toStringAsFixed(0)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(color: colors.primary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 6),
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Add More Items'),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: appColors.elevatedSurface,
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        border: Border.all(color: appColors.softOutline),
                      ),
                      child: Column(
                        children: [
                          _SummaryRow(
                            label: 'Subtotal',
                            value: widget.controller.subtotal,
                          ),
                          _SummaryRow(
                            label: 'Delivery fee',
                            value: widget.controller.deliveryFeeFor(
                              OrderType.pickup,
                            ),
                          ),
                          const Divider(height: 24),
                          _SummaryRow(
                            label: 'Total',
                            value: widget.controller.totalFor(OrderType.pickup),
                            strong: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
          bottomNavigationBar: widget.controller.cart.isEmpty
              ? null
              : Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: SafeArea(
                    child: ElevatedButton(
                      onPressed: widget.controller.canPlaceOrders
                          ? () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => CheckoutScreen(
                                    controller: widget.controller,
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: Text(
                        widget.controller.canPlaceOrders
                            ? 'Proceed to Checkout • R${widget.controller.totalFor(OrderType.pickup).toStringAsFixed(0)}'
                            : 'Ordering unavailable • ${widget.controller.storeStatusLabel}',
                      ),
                    ),
                  ),
                ),
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final double value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final style = strong
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.bodyLarge;
    return Row(
      children: [
        Text(label, style: style),
        const Spacer(),
        Text(
          'R${value.toStringAsFixed(0)}',
          style: style?.copyWith(
            color: strong ? colors.primary : colors.onSurface,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
