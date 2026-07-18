import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import '../models/order.dart';
import '../widgets/order_status_chip.dart';
import 'customer_shell.dart';
import 'tracking_screen.dart';

class ConfirmationScreen extends StatelessWidget {
  const ConfirmationScreen({
    super.key,
    required this.controller,
    required this.order,
  });

  final AppController controller;
  final OrderModel order;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.success.withValues(alpha: 0.12),
                    ),
                  ),
                  const CircleAvatar(
                    radius: 38,
                    backgroundColor: AppTheme.success,
                    child: Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                'Order Placed! Thanks, ${order.customerName.split(' ').first}.',
                style: Theme.of(context).textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Order #${order.orderNumber} • Ready in ${order.estimatedMinutes} minutes',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              if (order.paymentMethod == PaymentMethod.eft) ...[
                const SizedBox(height: 16),
                _PaymentProofUploader(controller: controller, order: order),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Receipt',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        OrderStatusChip(status: order.status),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Order Type: ${order.orderType.label}'),
                    Text('Payment: ${order.paymentMethod.label}'),
                    if (order.deliveryAddress != null &&
                        order.deliveryAddress!.isNotEmpty)
                      Text('Address: ${order.deliveryAddress}'),
                    const SizedBox(height: 12),
                    ...order.items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${item.quantity} x ${item.item.name}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      );
                    }),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Text(
                          'Total',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const Spacer(),
                        Text(
                          'R${order.totalPrice.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(color: AppTheme.periRed),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status Timeline',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    const _TimelineStep(
                      title: 'Order Received',
                      subtitle:
                          'Your order was sent to the store successfully.',
                      active: true,
                    ),
                    const _TimelineStep(
                      title: 'Preparing',
                      subtitle:
                          'The kitchen will start once the owner accepts it.',
                    ),
                    const _TimelineStep(
                      title: 'Ready / Completed',
                      subtitle:
                          'We will notify you when it is ready for collection.',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TrackingScreen(order: order),
                    ),
                  );
                },
                child: const Text('Track Order'),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => CustomerShell(
                        controller: controller,
                        initialIndex: 2,
                      ),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('Go to My Orders'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaymentProofUploader extends StatefulWidget {
  const _PaymentProofUploader({required this.controller, required this.order});

  final AppController controller;
  final OrderModel order;

  @override
  State<_PaymentProofUploader> createState() => _PaymentProofUploaderState();
}

class _PaymentProofUploaderState extends State<_PaymentProofUploader> {
  bool isUploading = false;
  bool uploaded = false;

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty || bytes.length > 5 * 1024 * 1024) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose a JPG, PNG, WebP or PDF smaller than 5 MB.'),
        ),
      );
      return;
    }
    setState(() => isUploading = true);
    try {
      await widget.controller.uploadPaymentProof(
        order: widget.order,
        bytes: Uint8List.fromList(bytes),
        fileName: file.name,
        contentType: _contentType(file.extension ?? file.name),
      );
      if (!mounted) return;
      setState(() => uploaded = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment proof uploaded securely.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'The proof could not be uploaded. Your order is still placed; please try again.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  String _contentType(String extension) {
    final value = extension.toLowerCase().replaceAll('.', '');
    return switch (value) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'png' => 'image/png',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      _ => 'application/octet-stream',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: uploaded
            ? AppTheme.success.withValues(alpha: 0.08)
            : AppTheme.chesaOrange.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            uploaded ? 'Payment proof received' : 'EFT payment proof',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(
            uploaded
                ? 'The private proof is linked to this order for staff review.'
                : 'Upload a clear JPG, PNG, WebP or PDF (maximum 5 MB). Your order remains placed if the upload fails.',
          ),
          const SizedBox(height: 12),
          if (!uploaded)
            OutlinedButton.icon(
              onPressed: isUploading ? null : _pickAndUpload,
              icon: isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.upload_file_rounded),
              label: Text(isUploading ? 'Uploading...' : 'Choose proof file'),
            ),
        ],
      ),
    );
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({
    required this.title,
    required this.subtitle,
    this.active = false,
  });

  final String title;
  final String subtitle;
  final bool active;

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
                  ? AppTheme.success
                  : AppTheme.mutedSurface,
              child: active
                  ? const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 16,
                    )
                  : const SizedBox.shrink(),
            ),
            Container(width: 2, height: 38, color: AppTheme.mutedSurface),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
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
