import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final rider = authState.rider;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 3),
              ),
              child: user?.avatarUrl != null
                  ? ClipOval(
                      child: Image.network(user!.avatarUrl!, fit: BoxFit.cover),
                    )
                  : const Icon(
                      Icons.person,
                      size: 48,
                      color: AppColors.textTertiary,
                    ),
            ),
            const SizedBox(height: 16),
            Text(user?.name ?? 'Rider', style: AppTextStyles.h3),
            Text('+91 ${user?.phone ?? ''}', style: AppTextStyles.bodySm),

            const SizedBox(height: 32),

            // Stats
            Row(
              children: [
                _StatCard(
                  icon: Icons.star,
                  value: rider?.ratingAvg.toStringAsFixed(1) ?? '-',
                  label: 'Rating',
                ),
                const SizedBox(width: 16),
                _StatCard(
                  icon: Icons.electric_rickshaw,
                  value: '${rider?.totalRides ?? 0}',
                  label: 'Rides',
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Menu items
            _MenuItem(
              icon: Icons.person_outline,
              title: 'Edit Profile',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.badge_outlined,
              title: 'KYC Documents',
              onTap: () => context.push('/kyc'),
            ),
            _MenuItem(
              icon: Icons.directions_car_outlined,
              title: 'Vehicle Details',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.route_outlined,
              title: 'My Routes',
              onTap: () => context.push('/routes'),
            ),
            _MenuItem(
              icon: Icons.star_outline,
              title: 'My Ratings',
              onTap: () {},
            ),
            _MenuItem(
              icon: Icons.help_outline,
              title: 'Help & Support',
              onTap: () {},
            ),
            _MenuItem(icon: Icons.info_outline, title: 'About', onTap: () {}),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/auth/login');
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                ),
                child: const Text('Logout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.accent),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.h2),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.textSecondary),
        title: Text(title, style: AppTextStyles.bodyMedium),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.textTertiary,
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
