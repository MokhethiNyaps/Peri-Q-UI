import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../models/app_preferences.dart';
import '../models/order.dart';
import '../repositories/order_repository.dart';
import 'confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController nameController;
  late final TextEditingController phoneController;
  final addressController = TextEditingController();
  OrderType orderType = OrderType.pickup;
  PaymentMethod paymentMethod = PaymentMethod.cashCollection;
  String? selectedAddressId;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: widget.controller.customerName,
    );
    phoneController = TextEditingController(
      text: widget.controller.customerPhone,
    );
    selectedAddressId = widget.controller.defaultAddress?.id;
    addressController.text =
        widget.controller.defaultAddress?.displayAddress ?? '';
    paymentMethod = _availablePaymentFor(
      widget.controller.preferredPaymentMethod,
      orderType,
    );
    if (!widget.controller.canUseOrderType(orderType) &&
        widget.controller.canUseOrderType(OrderType.delivery)) {
      orderType = OrderType.delivery;
      paymentMethod = _availablePaymentFor(paymentMethod, orderType);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  void _selectOrderType(OrderType type) {
    setState(() {
      orderType = type;
      if (orderType == OrderType.pickup &&
          paymentMethod == PaymentMethod.cashDelivery) {
        paymentMethod = PaymentMethod.cashCollection;
      }
      if (orderType == OrderType.delivery &&
          paymentMethod == PaymentMethod.cashCollection) {
        paymentMethod = PaymentMethod.cashDelivery;
      }
    });
  }

  PaymentMethod _availablePaymentFor(PaymentMethod method, OrderType type) {
    if (method == PaymentMethod.card) {
      return PaymentMethod.cashCollection;
    }
    if (type == OrderType.pickup && method == PaymentMethod.cashDelivery) {
      return PaymentMethod.cashCollection;
    }
    return method;
  }

  Future<void> _selectPayment(PaymentMethod method) async {
    setState(() => paymentMethod = method);
    await widget.controller.setPreferredPaymentMethod(method);
  }

  void _selectSavedAddress(String addressId) {
    SavedAddress? address;
    for (final entry in widget.controller.savedAddresses) {
      if (entry.id == addressId) {
        address = entry;
        break;
      }
    }
    if (address == null) {
      return;
    }
    final selectedAddress = address;
    setState(() {
      selectedAddressId = selectedAddress.id;
      addressController.text = selectedAddress.displayAddress;
    });
  }

  Future<void> _submitOrder() async {
    if (isSubmitting) return;
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => isSubmitting = true);
    try {
      await widget.controller.updateCustomer(
        name: nameController.text.trim(),
        phone: phoneController.text.trim(),
      );
      final order = await widget.controller.placeOrder(
        orderType: orderType,
        paymentMethod: paymentMethod,
        deliveryAddress: orderType == OrderType.delivery
            ? addressController.text.trim()
            : null,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) =>
              ConfirmationScreen(controller: widget.controller, order: order),
        ),
        (route) => route.isFirst,
      );
    } catch (error) {
      if (!mounted) return;
      final message = error is OrderSubmissionException
          ? error.message
          : 'We could not place your order. Check your connection and try again.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.controller.totalFor(orderType);
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  _StepBadge(number: 1, label: 'Details', active: true),
                  _StepBadge(number: 2, label: 'Fulfilment', active: true),
                  _StepBadge(number: 3, label: 'Payment', active: true),
                ],
              ),
              const SizedBox(height: 26),
              Text(
                'Your Details',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter your full name.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter your phone number.';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Order Type', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              _ChoiceCard(
                selected: orderType == OrderType.pickup,
                icon: Icons.storefront_rounded,
                title: 'Pickup in Store',
                subtitle: 'Ready in around 25 minutes • No delivery fee',
                onTap: () => _selectOrderType(OrderType.pickup),
                enabled: widget.controller.canUseOrderType(OrderType.pickup),
              ),
              const SizedBox(height: 12),
              _ChoiceCard(
                selected: orderType == OrderType.delivery,
                icon: Icons.two_wheeler_rounded,
                title: 'Home Delivery',
                subtitle:
                    '+R${widget.controller.appSettings.deliveryFee.toStringAsFixed(0)} delivery fee • 45 to 60 minutes',
                onTap: () => _selectOrderType(OrderType.delivery),
                enabled: widget.controller.canUseOrderType(OrderType.delivery),
              ),
              if (orderType == OrderType.delivery) ...[
                const SizedBox(height: 12),
                if (widget.controller.savedAddresses.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Saved Address',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: widget.controller.savedAddresses.map((
                            address,
                          ) {
                            final selected = address.id == selectedAddressId;
                            return ChoiceChip(
                              selected: selected,
                              selectedColor: AppTheme.periRed,
                              backgroundColor: AppTheme.mutedSurface,
                              label: Text(
                                address.label,
                                style: TextStyle(
                                  color: selected
                                      ? Colors.white
                                      : AppTheme.smokeCharcoal,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              onSelected: (_) =>
                                  _selectSavedAddress(address.id),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: addressController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Delivery Address',
                    hintText: 'House number, street, area and landmarks',
                  ),
                  validator: (value) {
                    if (orderType == OrderType.delivery &&
                        (value == null || value.trim().isEmpty)) {
                      return 'Enter the delivery address.';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              Text(
                'Payment Method',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(
                'Selected: ${paymentMethod.label}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              _PaymentTile(
                title: 'Cash on Collection',
                icon: Icons.storefront_rounded,
                selected: paymentMethod == PaymentMethod.cashCollection,
                enabled: true,
                onTap: () => _selectPayment(PaymentMethod.cashCollection),
              ),
              _PaymentTile(
                title: 'Cash on Delivery',
                icon: Icons.two_wheeler_rounded,
                selected: paymentMethod == PaymentMethod.cashDelivery,
                enabled: orderType == OrderType.delivery,
                onTap: () => _selectPayment(PaymentMethod.cashDelivery),
              ),
              _PaymentTile(
                title: 'EFT / Bank Transfer',
                icon: Icons.account_balance_rounded,
                subtitle: 'Upload proof after ordering',
                selected: paymentMethod == PaymentMethod.eft,
                enabled: true,
                onTap: () => _selectPayment(PaymentMethod.eft),
              ),
              _PaymentTile(
                title: 'Card Payment',
                icon: Icons.credit_card_rounded,
                subtitle: 'Coming soon',
                selected: paymentMethod == PaymentMethod.card,
                enabled: false,
                onTap: null,
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Summary',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${widget.controller.cartCount} items • R${total.toStringAsFixed(0)} total',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.expand_more_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SafeArea(
          child: ElevatedButton(
            key: const ValueKey('checkout-place-order-button'),
            onPressed: isSubmitting ? null : _submitOrder,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 160),
              child: isSubmitting
                  ? const Row(
                      key: ValueKey('checkout-placing'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 10),
                        Text('Placing order…'),
                      ],
                    )
                  : Text(
                      key: const ValueKey('checkout-ready'),
                      'Place Order • R${total.toStringAsFixed(0)}',
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({
    required this.number,
    required this.label,
    this.active = false,
  });

  final int number;
  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: active ? AppTheme.periRed : Colors.white,
          child: Text(
            '$number',
            style: TextStyle(
              color: active ? Colors.white : AppTheme.ashGrey,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: active ? AppTheme.periRed : AppTheme.ashGrey,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppTheme.periRed : Colors.transparent,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: selected
                    ? AppTheme.periRed.withValues(alpha: 0.1)
                    : AppTheme.mutedSurface,
                child: Icon(
                  icon,
                  color: selected ? AppTheme.periRed : AppTheme.ashGrey,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              IgnorePointer(
                child: RadioGroup<bool>(
                  groupValue: selected,
                  onChanged: (_) {},
                  child: Radio<bool>(
                    value: true,
                    activeColor: AppTheme.periRed,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentTile extends StatelessWidget {
  const _PaymentTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final IconData icon;
  final String? subtitle;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? AppTheme.periRed.withValues(alpha: 0.1)
                      : AppTheme.mutedSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: selected ? AppTheme.periRed : AppTheme.ashGrey,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              IgnorePointer(
                child: RadioGroup<bool>(
                  groupValue: selected,
                  onChanged: (_) {},
                  child: Radio<bool>(
                    value: true,
                    activeColor: AppTheme.periRed,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
