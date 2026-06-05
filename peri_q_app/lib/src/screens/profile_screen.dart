import 'package:flutter/material.dart';

import '../core/app_controller.dart';
import '../core/app_theme.dart';
import 'admin_dashboard_screen.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: controller,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.smokeCharcoal,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white24,
                      child: Text(
                        controller.customerName.isNotEmpty
                            ? controller.customerName
                                  .substring(0, 1)
                                  .toUpperCase()
                            : 'U',
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            controller.customerName.isNotEmpty
                                ? controller.customerName
                                : 'Guest Customer',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(color: Colors.white),
                          ),
                          Text(
                            controller.customerPhone.isNotEmpty
                                ? controller.customerPhone
                                : 'No phone number yet',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            controller.isGuest
                                ? 'Guest checkout enabled'
                                : 'Signed in',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.chesaOrange,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ...[
                ('Saved Addresses', Icons.location_on_outlined),
                ('Payment Preferences', Icons.account_balance_wallet_outlined),
                ('Language', Icons.language_rounded),
                ('Push Notifications', Icons.notifications_outlined),
              ].map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ProfileTile(title: entry.$1, icon: entry.$2),
                ),
              ),
              const SizedBox(height: 8),
              if (controller.canAccessAdmin)
                InkWell(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            AdminDashboardScreen(controller: controller),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Ink(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.periRed.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: AppTheme.periRed.withValues(alpha: 0.18),
                      ),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.admin_panel_settings_outlined,
                            color: AppTheme.periRed,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Open Owner Dashboard',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(color: AppTheme.periRed),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.periRed,
                        ),
                      ],
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.mutedSurface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.lock_outline_rounded,
                        color: AppTheme.ashGrey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Admin tools unlock automatically for Supabase users with the admin role.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () async {
                    await controller.signOut();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => AuthScreen(controller: controller),
                      ),
                      (route) => false,
                    );
                  },
                  child: const Text('Sign Out'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({required this.title, required this.icon});

  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppTheme.mutedSurface,
            child: Icon(icon, color: AppTheme.ashGrey),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}
