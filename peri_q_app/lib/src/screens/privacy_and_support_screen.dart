import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_theme.dart';

class PrivacyAndSupportScreen extends StatelessWidget {
  const PrivacyAndSupportScreen({super.key});

  static final Uri _phone = Uri(scheme: 'tel', path: '+27736423549');
  static final Uri _whatsApp = Uri.parse(
    'https://wa.me/27736423549?text=Hello%20Rasta%27s%20Peri%20Q%2C%20I%20need%20help%20with%20the%20app.',
  );

  Future<void> _open(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No supported phone or browser app was found.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Help')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          Text('Need help?', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Contact Rasta’s Peri Q Chesanyama about an order, account, payment proof or data request.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _open(context, _whatsApp),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('Message support on WhatsApp'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _open(context, _phone),
            icon: const Icon(Icons.call_outlined),
            label: const Text('Call the store'),
          ),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 20),
          Text(
            'Privacy summary',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          const _PrivacySection(
            title: 'Information used',
            body:
                'The app uses your name, phone number, optional email, delivery address, order history and any EFT proof you choose to upload to process and support orders. Guest checkout creates an anonymous Supabase session so your orders remain private.',
          ),
          const _PrivacySection(
            title: 'Storage and sharing',
            body:
                'Order and account data is sent securely to the business Supabase project. Payment proofs are stored in a private bucket. The app has no advertising or analytics SDK and does not sell personal information.',
          ),
          const _PrivacySection(
            title: 'Your choices',
            body:
                'Delivery addresses are optional unless you select delivery. EFT proof is only needed when you choose EFT. Signed-in customers can delete their account from Profile; they can also contact support for privacy help.',
          ),
          const _PrivacySection(
            title: 'Policy publication',
            body:
                'This in-app summary is provided for convenience. The owner must publish the final policy at the public URL shown on the Google Play store listing before release.',
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.mutedSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Text(
              'Privacy contact: use the WhatsApp or phone options above until the owner publishes the final support email and privacy-policy URL.',
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 5),
          Text(body, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
