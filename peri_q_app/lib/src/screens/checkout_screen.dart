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
  PaymentMethod paymentMethod = PaymentMethod.yoco;
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
    if (!widget.controller.canUseOrderType(orderType) &&
        widget.controller.canUseOrderType(OrderType.delivery)) {
      orderType = OrderType.delivery;
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    super.dispose();
  }

  void _selectOrderType(OrderType type) => setState(() => orderType = type);

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
              const Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 16,
                runSpacing: 12,
                children: [
                  _StepBadge(number: 1, label: 'Details'),
                  _StepBadge(number: 2, label: 'Fulfilment'),
                  _StepBadge(number: 3, label: 'Payment'),
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
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(color: context.appColors.softOutline),
                ),
                child: Column(
                  children: [
                    TextFormField(
                      controller: nameController,
                      autofillHints: const [AutofillHints.name],
                      textCapitalization: TextCapitalization.words,
                      maxLength: 100,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        counterText: '',
                      ),
                      textInputAction: TextInputAction.next,
                      validator: (value) {
                        if (value == null || value.trim().length < 2) {
                          return 'Enter your full name (at least 2 characters).';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      autofillHints: const [AutofillHints.telephoneNumber],
                      maxLength: 30,
                      decoration: const InputDecoration(
                        labelText: 'Phone number',
                        counterText: '',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 7) {
                          return 'Enter a valid phone number.';
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
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      border: Border.all(color: context.appColors.softOutline),
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
                              selectedColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              backgroundColor: context.appColors.sunkenSurface,
                              label: Text(
                                address.label,
                                style: TextStyle(
                                  color: selected
                                      ? Theme.of(context).colorScheme.onPrimary
                                      : Theme.of(context).colorScheme.onSurface,
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
                  autofillHints: const [AutofillHints.fullStreetAddress],
                  decoration: const InputDecoration(
                    labelText: 'Delivery Address',
                    hintText: 'House number, street, area and landmarks',
                  ),
                  validator: (value) {
                    if (orderType == OrderType.delivery &&
                        (value == null || value.trim().length < 8)) {
                      return 'Enter a full delivery address.';
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
              const _PaymentTile(
                title: 'Pay by card',
                subtitle:
                    'Pay securely before we send your order to the grill.',
                icon: Icons.credit_card_rounded,
                selected: true,
                enabled: true,
                onTap: null,
              ),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(AppRadii.card),
                  border: Border.all(color: context.appColors.softOutline),
                ),
                child: ExpansionTile(
                  shape: const Border(),
                  collapsedShape: const Border(),
                  tilePadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  leading: Icon(
                    Icons.receipt_long_rounded,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    'Order Summary',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  subtitle: Text(
                    '${widget.controller.cartCount} items • R${total.toStringAsFixed(0)} total',
                  ),
                  children: [
                    _SummaryRow(
                      label: 'Subtotal',
                      amount: widget.controller.subtotal,
                    ),
                    if (orderType == OrderType.delivery)
                      _SummaryRow(
                        label: 'Delivery',
                        amount: widget.controller.deliveryFeeFor(orderType),
                      ),
                    const Divider(height: 20),
                    _SummaryRow(label: 'Total', amount: total, strong: true),
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
              duration: MediaQuery.disableAnimationsOf(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 160),
              child: isSubmitting
                  ? Row(
                      key: ValueKey('checkout-placing'),
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Flexible(
                          child: Text(
                            'Opening payment and waiting for confirmation…',
                          ),
                        ),
                      ],
                    )
                  : Text(
                      key: const ValueKey('checkout-ready'),
                      'Pay by card • R${total.toStringAsFixed(0)}',
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  const _StepBadge({required this.number, required this.label});

  final int number;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Checkout section $number of 3: $label',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                '$number',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 7),
            Text(label, style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
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
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(AppRadii.card),
            border: Border.all(
              color: selected
                  ? Theme.of(context).colorScheme.primary
                  : context.appColors.softOutline,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: selected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : context.appColors.sunkenSurface,
                child: Icon(
                  icon,
                  color: selected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
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
                  child: Radio<bool>(value: true),
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
            color: Theme.of(context).cardColor,
            border: Border(
              bottom: BorderSide(color: context.appColors.softOutline),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context).colorScheme.primaryContainer
                      : context.appColors.sunkenSurface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: selected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurfaceVariant,
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
                  child: Radio<bool>(value: true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.amount,
    this.strong = false,
  });

  final String label;
  final double amount;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    final style = strong
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('R${amount.toStringAsFixed(0)}', style: style),
        ],
      ),
    );
  }
}
