import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/theme.dart';
import '../../providers/home_provider.dart';
import '../../providers/auth_provider.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  final String riderId;

  const TrackingScreen({super.key, required this.riderId});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  GoogleMapController? _mapController;
  Marker? _riderMarker;
  bool _isLoading = true;
  String? _riderName;
  String? _riderPhone;
  String? _vehicleNumber;

  @override
  void initState() {
    super.initState();
    _startTracking();
  }

  Future<void> _startTracking() async {
    final success = await ref
        .read(trackingProvider.notifier)
        .startTracking(riderId: widget.riderId);

    setState(() => _isLoading = false);

    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to start tracking'),
          backgroundColor: AppColors.error,
        ),
      );
      context.pop();
    }
  }

  void _updateRiderMarker(double lat, double lng, double? heading) {
    setState(() {
      _riderMarker = Marker(
        markerId: const MarkerId('rider'),
        position: LatLng(lat, lng),
        rotation: heading ?? 0,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        infoWindow: InfoWindow(title: _riderName ?? 'Rider'),
      );
    });

    // Move camera to follow rider
    _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(lat, lng)));
  }

  Future<void> _callRider() async {
    if (_riderPhone == null) return;
    final uri = Uri.parse('tel:$_riderPhone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _shareRide() async {
    final trackingState = ref.read(trackingProvider);
    if (trackingState.rideId == null) return;

    try {
      final response = await ref
          .read(apiServiceProvider)
          .shareRide(trackingState.rideId!);
      if (response.data['success'] == true) {
        final shareText = response.data['data']['share_text'];
        await Share.share(shareText);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  void _showSosDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Emergency SOS'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Are you in an emergency? We will help you contact authorities.',
              style: AppTextStyles.body,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.local_police, color: AppColors.error),
              title: const Text('Police'),
              subtitle: const Text('100'),
              onTap: () => _callEmergency('100'),
            ),
            ListTile(
              leading: const Icon(Icons.emergency, color: AppColors.error),
              title: const Text('Emergency'),
              subtitle: const Text('112'),
              onTap: () => _callEmergency('112'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _callEmergency(String number) async {
    Navigator.pop(context);
    final uri = Uri.parse('tel:$number');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _endTracking() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Tracking?'),
        content: const Text(
          'Are you sure you want to stop tracking this ride?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('End'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(trackingProvider.notifier).endTracking();
      if (mounted) {
        context.go('/home');
      }
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trackingState = ref.watch(trackingProvider);
    final location = ref.watch(locationProvider).currentPosition;

    // Listen for location updates
    ref.listen(trackingProvider, (previous, next) {
      if (next.riderLocation != null) {
        _updateRiderMarker(
          next.riderLocation!.latitude,
          next.riderLocation!.longitude,
          next.riderLocation!.heading,
        );
      }
    });

    return Scaffold(
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(
                location?.latitude ?? 12.9716,
                location?.longitude ?? 77.5946,
              ),
              zoom: 16,
            ),
            markers: _riderMarker != null ? {_riderMarker!} : {},
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) => _mapController = controller,
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.surface),
              ),
            ),

          // Top bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppShadows.soft,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: AppShadows.soft,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: trackingState.isTracking
                                  ? AppColors.success
                                  : AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            trackingState.isTracking
                                ? 'Live Tracking'
                                : 'Connecting...',
                            style: AppTextStyles.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bottom panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: AppShadows.strong,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Rider info
                  Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.electric_rickshaw,
                          color: AppColors.secondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _riderName ?? 'Rider',
                              style: AppTextStyles.h4,
                            ),
                            Text(
                              _vehicleNumber ?? 'Loading...',
                              style: AppTextStyles.bodySm,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: _callRider,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.success.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.phone,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      // Share
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _shareRide,
                          icon: const Icon(Icons.share, size: 20),
                          label: const Text('Share'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // SOS
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showSosDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                          ),
                          icon: const Icon(
                            Icons.sos,
                            size: 20,
                            color: AppColors.surface,
                          ),
                          label: const Text('SOS'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // End
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _endTracking,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: const BorderSide(color: AppColors.error),
                          ),
                          icon: const Icon(Icons.close, size: 20),
                          label: const Text('End'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
