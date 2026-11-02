import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../models/order.dart';
import '../widgets/flame_progress.dart';

class TrackingScreen extends StatelessWidget {
  const TrackingScreen({super.key, required this.order, this.controller});

  final OrderModel order;
  final AppController? controller;
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
    final appController = controller;
    if (appController == null) {
      return _buildContent(context, order);
    }

    return AnimatedBuilder(
      animation: appController,
      builder: (context, _) {
        var latestOrder = order;
        for (final candidate in appController.orders) {
          if (candidate.id == order.id) {
            latestOrder = candidate;
            break;
          }
        }
        return _buildContent(context, latestOrder);
      },
    );
  }

  Widget _buildContent(BuildContext context, OrderModel order) {
    final isPreparingOrFurther =
        order.status == OrderStatus.preparing ||
        order.status == OrderStatus.ready ||
        order.status == OrderStatus.completed;
    final isReadyOrCompleted =
        order.status == OrderStatus.ready ||
        order.status == OrderStatus.completed;
    final statusHeadline = switch (order.status) {
      OrderStatus.pending => 'ORDER RECEIVED',
      OrderStatus.preparing => 'IN THE KITCHEN',
      OrderStatus.ready =>
        order.orderType == OrderType.delivery
            ? 'READY FOR DELIVERY'
            : 'READY FOR PICKUP',
      OrderStatus.completed => 'ORDER COMPLETED',
      OrderStatus.cancelled => 'ORDER CANCELLED',
    };
    final progress = switch (order.status) {
      OrderStatus.pending => 0.25,
      OrderStatus.preparing => 0.5,
      OrderStatus.ready => 0.75,
      OrderStatus.completed => 1.0,
      OrderStatus.cancelled => 0.0,
    };
    final statusDetail = switch (order.status) {
      OrderStatus.completed => 'Thanks for ordering with RastasperiQ',
      OrderStatus.cancelled => 'Contact the branch if you need help',
      _ => 'Est. ${order.estimatedMinutes} mins remaining',
    };

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
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1715), Color(0xFF5A1406)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusHeadline,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    letterSpacing: 1.6,
                    color: const Color(0xFFFFD1A8),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  statusDetail,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 34,
                  ),
                ),
                if (order.status != OrderStatus.cancelled) ...[
                  const SizedBox(height: 16),
                  FlameProgress(progress: progress, label: statusHeadline),
                ],
                const SizedBox(height: 10),
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
            title: order.orderType == OrderType.delivery
                ? 'Ready for Delivery'
                : 'Ready for Pickup',
            subtitle: order.orderType == OrderType.delivery
                ? 'Your order is packed and ready for handoff.'
                : 'Your order is packed and ready to collect.',
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
                  label: const Text('Contact branch'),
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
    final connectorHeight = (42 * MediaQuery.textScalerOf(context).scale(1))
        .clamp(42, 88)
        .toDouble();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            CircleAvatar(
              radius: 12,
              backgroundColor: active
                  ? Theme.of(context).colorScheme.primary
                  : context.appColors.sunkenSurface,
              child: active
                  ? Icon(
                      Icons.check_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimary,
                    )
                  : const SizedBox.shrink(),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: connectorHeight,
                color: context.appColors.softOutline,
              ),
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
