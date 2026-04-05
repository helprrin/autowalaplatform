import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../widgets/auto_card.dart';
import '../../widgets/drawer_menu.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};
  bool _isMapReady = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _startAutoRefresh();
  }

  void _loadInitialData() async {
    // Get current location
    await ref.read(locationProvider.notifier).getCurrentLocation();

    // Fetch nearby riders
    final location = ref.read(locationProvider).currentPosition;
    if (location != null) {
      await ref
          .read(nearbyRidersProvider.notifier)
          .fetchNearbyRiders(location.latitude, location.longitude);
    }
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _refreshNearbyRiders();
    });
  }

  Future<void> _refreshNearbyRiders() async {
    final location = ref.read(locationProvider).currentPosition;
    if (location != null) {
      await ref
          .read(nearbyRidersProvider.notifier)
          .fetchNearbyRiders(location.latitude, location.longitude);
    }
  }

  void _updateMarkers(List<NearbyRider> riders) {
    _markers.clear();

    for (final rider in riders) {
      _markers.add(
        Marker(
          markerId: MarkerId(rider.id),
          position: LatLng(rider.latitude, rider.longitude),
          rotation: rider.heading ?? 0,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(
            title: rider.name,
            snippet: '${rider.vehicleNumber ?? 'Auto'} • ${rider.formattedEta}',
          ),
          onTap: () => _showRiderDetails(rider),
        ),
      );
    }

    setState(() {});
  }

  void _showRiderDetails(NearbyRider rider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RiderDetailSheet(
        rider: rider,
        onTrack: () => _startTracking(rider),
        onCall: () => _callRider(rider.phone),
      ),
    );
  }

  Future<void> _startTracking(NearbyRider rider) async {
    Navigator.pop(context);
    context.push('/tracking/${rider.id}');
  }

  Future<void> _callRider(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  void _centerOnLocation() async {
    final location = ref.read(locationProvider).currentPosition;
    if (location != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(location.latitude, location.longitude)),
      );
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final ridersState = ref.watch(nearbyRidersProvider);
    final authState = ref.watch(authStateProvider);

    // Update markers when riders change
    ref.listen(nearbyRidersProvider, (previous, next) {
      if (next.riders.isNotEmpty) {
        _updateMarkers(next.riders);
      }
    });

    return Scaffold(
      drawer: DrawerMenu(user: authState.user),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                locationState.currentPosition?.latitude ??
                    AppConstants.defaultLat,
                locationState.currentPosition?.longitude ??
                    AppConstants.defaultLng,
              ),
              zoom: AppConstants.defaultZoom,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
              setState(() => _isMapReady = true);
            },
          ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Menu button
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Search bar
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.search,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Where to?',
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center on location button
          Positioned(
            right: 16,
            bottom: 280,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.soft,
              ),
              child: IconButton(
                icon: const Icon(Icons.my_location),
                onPressed: _centerOnLocation,
              ),
            ),
          ),

          // Refresh button
          Positioned(
            right: 16,
            bottom: 340,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: AppShadows.soft,
              ),
              child: IconButton(
                icon: ridersState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh),
                onPressed: ridersState.isLoading ? null : _refreshNearbyRiders,
              ),
            ),
          ),

          // Bottom sheet with nearby autos
          DraggableScrollableSheet(
            initialChildSize: 0.35,
            minChildSize: 0.15,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: AppShadows.strong,
                ),
                child: Column(
                  children: [
                    // Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Text('Nearby Autos', style: AppTextStyles.h4),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${ridersState.riders.length} online',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // List
                    Expanded(
                      child: ridersState.isLoading && ridersState.riders.isEmpty
                          ? const Center(child: CircularProgressIndicator())
                          : ridersState.riders.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.electric_rickshaw,
                                    size: 64,
                                    color: AppColors.textTertiary,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'No autos nearby',
                                    style: AppTextStyles.body.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  TextButton(
                                    onPressed: _refreshNearbyRiders,
                                    child: const Text('Refresh'),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              itemCount: ridersState.riders.length,
                              itemBuilder: (context, index) {
                                final rider = ridersState.riders[index];
                                return AutoCard(
                                  rider: rider,
                                  onTap: () => _showRiderDetails(rider),
                                  onCall: () => _callRider(rider.phone),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RiderDetailSheet extends StatelessWidget {
  final NearbyRider rider;
  final VoidCallback onTrack;
  final VoidCallback onCall;

  const _RiderDetailSheet({
    required this.rider,
    required this.onTrack,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 24),

          // Avatar and info
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person,
                  size: 32,
                  color: AppColors.textTertiary,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(rider.name, style: AppTextStyles.h4),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.star,
                          size: 16,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${rider.ratingAvg.toStringAsFixed(1)} (${rider.ratingCount})',
                          style: AppTextStyles.bodySm,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          rider.vehicleNumber ?? 'Auto',
                          style: AppTextStyles.bodySm.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Distance and ETA
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      const Icon(Icons.place_outlined, color: AppColors.accent),
                      const SizedBox(height: 8),
                      Text(
                        rider.formattedDistance,
                        style: AppTextStyles.bodyMedium,
                      ),
                      Text('Away', style: AppTextStyles.caption),
                    ],
                  ),
                ),
                Container(width: 1, height: 48, color: AppColors.border),
                Expanded(
                  child: Column(
                    children: [
                      const Icon(Icons.access_time, color: AppColors.accent),
                      const SizedBox(height: 8),
                      Text(rider.formattedEta, style: AppTextStyles.bodyMedium),
                      Text('ETA', style: AppTextStyles.caption),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Routes if available
          if (rider.activeRoutes != null && rider.activeRoutes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Active Route',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    rider.activeRoutes!.first.name,
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '₹${rider.activeRoutes!.first.baseFare.toStringAsFixed(0)}',
                    style: AppTextStyles.h4.copyWith(color: AppColors.accent),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onCall,
                  icon: const Icon(Icons.phone),
                  label: const Text('Call'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: onTrack,
                  icon: const Icon(Icons.location_on, color: AppColors.surface),
                  label: const Text('Track'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
