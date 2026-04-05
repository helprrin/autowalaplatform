import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(homeProvider.notifier).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final homeState = ref.watch(homeProvider);
    final rider = authState.rider;

    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: homeState.currentPosition != null
                  ? LatLng(
                      homeState.currentPosition!.latitude,
                      homeState.currentPosition!.longitude,
                    )
                  : const LatLng(19.0760, 72.8777), // Mumbai default
              zoom: 15,
            ),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
          ),

          // Top Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Menu button
                  GestureDetector(
                    onTap: () => context.push('/profile'),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppShadows.soft,
                      ),
                      child: const Icon(Icons.person_outline),
                    ),
                  ),

                  const Spacer(),

                  // Online status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: homeState.isOnline
                          ? AppColors.online
                          : AppColors.offline,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.surface,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          homeState.isOnline ? 'Online' : 'Offline',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.surface,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // My location button
                  GestureDetector(
                    onTap: () {
                      if (homeState.currentPosition != null) {
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLng(
                            LatLng(
                              homeState.currentPosition!.latitude,
                              homeState.currentPosition!.longitude,
                            ),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppShadows.soft,
                      ),
                      child: const Icon(Icons.my_location),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: AppShadows.strong,
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // KYC warning if not verified
                      if (rider != null && !rider.canGoOnline) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Complete KYC to go online',
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                    Text(
                                      'Your documents are being verified',
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.push('/kyc'),
                                child: const Text('View'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Stats
                      Row(
                        children: [
                          _StatCard(
                            icon: Icons.electric_rickshaw,
                            label: 'Rides',
                            value: '${homeState.stats?.totalRides ?? 0}',
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            icon: Icons.star,
                            label: 'Rating',
                            value:
                                homeState.stats?.ratingAvg.toStringAsFixed(1) ??
                                '-',
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            icon: Icons.route,
                            label: 'Routes',
                            value: '${homeState.routes.length}',
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Active route (if any)
                      if (homeState.activeRoute != null) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.accent),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.route,
                                  color: AppColors.accent,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      homeState.activeRoute!.name,
                                      style: AppTextStyles.bodyMedium,
                                    ),
                                    Text(
                                      '₹${homeState.activeRoute!.fare.toStringAsFixed(0)}',
                                      style: AppTextStyles.caption,
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                onPressed: () => ref
                                    .read(homeProvider.notifier)
                                    .setActiveRoute(null),
                                child: const Text('Change'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Go Online/Offline button
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: rider != null && rider.canGoOnline
                              ? () {
                                  if (homeState.isOnline) {
                                    ref.read(homeProvider.notifier).goOffline();
                                  } else {
                                    _showRouteSelector(context);
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: homeState.isOnline
                                ? AppColors.offline
                                : AppColors.online,
                          ),
                          child: homeState.isLoading
                              ? const CircularProgressIndicator(
                                  color: AppColors.surface,
                                )
                              : Text(
                                  homeState.isOnline
                                      ? 'Go Offline'
                                      : 'Go Online',
                                  style: AppTextStyles.button.copyWith(
                                    color: AppColors.surface,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Route management button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => context.push('/routes'),
                          child: const Text('Manage Routes'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRouteSelector(BuildContext context) {
    final homeState = ref.read(homeProvider);

    if (homeState.routes.isEmpty) {
      // No routes, go online without route
      ref.read(homeProvider.notifier).goOnline();
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Route', style: AppTextStyles.h3),
            const SizedBox(height: 16),
            ...homeState.routes.map(
              (route) => ListTile(
                leading: const Icon(Icons.route),
                title: Text(route.name),
                subtitle: Text('₹${route.fare.toStringAsFixed(0)}'),
                onTap: () {
                  Navigator.pop(context);
                  ref.read(homeProvider.notifier).goOnline(route: route);
                },
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.location_on),
              title: const Text('No specific route'),
              subtitle: const Text('Accept rides from anywhere'),
              onTap: () {
                Navigator.pop(context);
                ref.read(homeProvider.notifier).goOnline();
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 24),
            const SizedBox(height: 8),
            Text(value, style: AppTextStyles.h3),
            Text(label, style: AppTextStyles.caption),
          ],
        ),
      ),
    );
  }
}
