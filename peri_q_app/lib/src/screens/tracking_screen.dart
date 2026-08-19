import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_theme.dart';
import '../models/order.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key, required this.order});

  final OrderModel order;
  static const String storeAddress =
      '28 King Edward Rd, Bloemfontein, FS 9301, South Africa';
  static const String branchPhoneDisplay = '+27 73 642 3549';
  static const String branchPhoneDial = '+27736423549';
  static const String branchWhatsAppPhone = '27736423549';

  Future<void> _contactBranch() async {
    final message = Uri.encodeComponent(
      'Hello, I would like assistance with my order.',
    );
    final whatsappUri = Uri.parse(
      'whatsapp://send?phone=$branchWhatsAppPhone&text=$message',
    );
    final phoneUri = Uri.parse('tel:$branchPhoneDial');

    try {
      final openedWhatsApp = await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );
      if (openedWhatsApp) {
        return;
      }
    } catch (_) {
      // Fall through to the dialer when WhatsApp is unavailable.
    }

    try {
      await launchUrl(phoneUri, mode: LaunchMode.externalApplication);
    } catch (_) {
      // Keep the customer flow quiet if the OS cannot route either action.
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPreparingOrFurther =
        order.status == OrderStatus.preparing ||
        order.status == OrderStatus.ready ||
        order.status == OrderStatus.completed;
    final isReadyOrCompleted =
        order.status == OrderStatus.ready ||
        order.status == OrderStatus.completed;

    return Scaffold(
      appBar: AppBar(title: const Text('Live Tracking')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [AppTheme.periRed, AppTheme.chesaOrange],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${order.status.label.toUpperCase()} YOUR ORDER',
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(letterSpacing: 1.6),
                ),
                const SizedBox(height: 10),
                Text(
                  'Est. ${order.estimatedMinutes} mins remaining',
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  order.orderType.label,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Progress Timeline',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _TrackingStep(
            title: 'Order Received',
            subtitle: 'The store has received order #${order.orderNumber}.',
            active: true,
          ),
          _TrackingStep(
            title: 'Preparing',
            subtitle: 'The kitchen is working on your meal right now.',
            active: isPreparingOrFurther,
          ),
          _TrackingStep(
            title: 'Ready for Pickup',
            subtitle: 'Your order is packed and ready to go.',
            active: isReadyOrCompleted,
          ),
          _TrackingStep(
            title: 'Completed',
            subtitle: 'Order has been collected or delivered.',
            active: order.status == OrderStatus.completed,
            isLast: true,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Store Details',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'RastasperiQ Branch\n$storeAddress\n$branchPhoneDisplay',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  onPressed: _contactBranch,
                  icon: const Icon(Icons.call_rounded),
                  label: const Text('Call branch directly'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingStep extends StatelessWidget {
  const _TrackingStep({
    required this.title,
    required this.subtitle,
    required this.active,
    this.isLast = false,
  });

  final String title;
  final String subtitle;
  final bool active;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: active
                  ? AppTheme.periRed
                  : AppTheme.mutedSurface,
              child: active
                  ? const Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Colors.white,
                    )
                  : const SizedBox.shrink(),
            ),
            if (!isLast)
              Container(width: 2, height: 42, color: AppTheme.mutedSurface),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
