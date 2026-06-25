import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../models/order.dart';

class PaymentPreferencesScreen extends StatelessWidget {
  const PaymentPreferencesScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Payment Preferences')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.smokeCharcoal,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preferred Method',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            controller.preferredPaymentMethod.label,
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              ...PaymentMethod.values.map((method) {
                final isCard = method == PaymentMethod.card;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PaymentPreferenceCard(
                    method: method,
                    selected: controller.preferredPaymentMethod == method,
                    enabled: !isCard,
                    onTap: isCard
                        ? null
                        : () async {
                            await controller.setPreferredPaymentMethod(method);
                            if (!context.mounted) {
                              return;
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('${method.label} saved.')),
                            );
                          },
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

class _PaymentPreferenceCard extends StatelessWidget {
  const _PaymentPreferenceCard({
    required this.method,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final PaymentMethod method;
  final bool selected;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (method) {
      PaymentMethod.cashCollection => Icons.storefront_rounded,
      PaymentMethod.cashDelivery => Icons.two_wheeler_rounded,
      PaymentMethod.eft => Icons.account_balance_rounded,
      PaymentMethod.card => Icons.credit_card_rounded,
    };

    return Opacity(
      opacity: enabled ? 1 : 0.52,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? AppTheme.periRed : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
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
                    Text(
                      method.label,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    if (!enabled)
                      Text(
                        'Coming soon',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppTheme.periRed : AppTheme.ashGrey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
