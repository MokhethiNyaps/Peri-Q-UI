import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_theme.dart';
import '../core/external_links.dart';

class PrivacyAndSupportScreen extends StatelessWidget {
  const PrivacyAndSupportScreen({super.key});

  Future<void> _open(BuildContext context, Uri uri) async {
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (opened || !context.mounted) return;
    } catch (_) {
      if (!context.mounted) return;
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'This link could not be opened. Check your connection and try again.',
          ),
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
            'Contact RastasperiQ about an order, account, payment proof or data request.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _open(context, AppExternalLinks.whatsApp),
            icon: const Icon(Icons.chat_bubble_outline_rounded),
            label: const Text('Message support on WhatsApp'),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => _open(context, AppExternalLinks.supportEmail),
            icon: const Icon(Icons.mail_outline_rounded),
            label: const Text('Email contact@rastasperiq.co.za'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _open(context, AppExternalLinks.phone),
            icon: const Icon(Icons.call_outlined),
            label: const Text('Call the store'),
          ),
          const SizedBox(height: 28),
          const Divider(),
          const SizedBox(height: 20),
          Text(
            'Website & legal',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 12),
          _ExternalLinkTile(
            title: 'RastasperiQ website',
            subtitle: 'rastasperiq.co.za',
            icon: Icons.language_rounded,
            onTap: () => _open(context, AppExternalLinks.website),
          ),
          _ExternalLinkTile(
            title: 'Privacy Policy',
            subtitle: 'How app and order information is handled',
            icon: Icons.privacy_tip_outlined,
            onTap: () => _open(context, AppExternalLinks.privacyPolicy),
          ),
          _ExternalLinkTile(
            title: 'Terms and Conditions',
            subtitle: 'Terms for using the ordering service',
            icon: Icons.description_outlined,
            onTap: () => _open(context, AppExternalLinks.termsAndConditions),
          ),
          _ExternalLinkTile(
            title: 'Delete account or data',
            subtitle: 'Public instructions and request options',
            icon: Icons.delete_outline_rounded,
            onTap: () => _open(context, AppExternalLinks.accountDeletion),
          ),
          const SizedBox(height: 18),
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
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.mutedSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.verified_user_outlined, color: AppTheme.success),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Privacy and data requests can be sent to contact@rastasperiq.co.za or submitted through the public account-deletion page.',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExternalLinkTile extends StatelessWidget {
  const _ExternalLinkTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.lightSurface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.periRed.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppTheme.periRed, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.open_in_new_rounded,
                size: 18,
                color: AppTheme.ashGrey,
              ),
            ],
          ),
        ),
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
