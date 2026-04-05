import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../services/api_service.dart';
import '../../services/location_service.dart';
import '../../providers/home_provider.dart';

class CreateRouteScreen extends ConsumerStatefulWidget {
  const CreateRouteScreen({super.key});

  @override
  ConsumerState<CreateRouteScreen> createState() => _CreateRouteScreenState();
}

class _CreateRouteScreenState extends ConsumerState<CreateRouteScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _fareController = TextEditingController();

  GoogleMapController? _mapController;
  LatLng? _startPoint;
  LatLng? _endPoint;
  String? _startAddress;
  String? _endAddress;
  bool _isLoading = false;
  bool _isSelectingStart = true;

  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fareController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    final position = await LocationService().getCurrentPosition();
    if (position != null && _mapController != null) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );
    }
  }

  Future<void> _onMapTap(LatLng position) async {
    if (_isSelectingStart) {
      setState(() {
        _startPoint = position;
      });
      await _getAddressFromLatLng(position, true);
    } else {
      setState(() {
        _endPoint = position;
      });
      await _getAddressFromLatLng(position, false);
    }
    _updateMarkers();
  }

  Future<void> _getAddressFromLatLng(LatLng position, bool isStart) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final address =
            '${place.street ?? ''}, ${place.subLocality ?? ''}, ${place.locality ?? ''}';
        setState(() {
          if (isStart) {
            _startAddress = address;
          } else {
            _endAddress = address;
          }
        });
      }
    } catch (e) {
      // Ignore
    }
  }

  void _updateMarkers() {
    _markers.clear();
    _polylines.clear();

    if (_startPoint != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('start'),
          position: _startPoint!,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
          infoWindow: InfoWindow(title: 'Start', snippet: _startAddress),
        ),
      );
    }

    if (_endPoint != null) {
      _markers.add(
        Marker(
          markerId: const MarkerId('end'),
          position: _endPoint!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: 'End', snippet: _endAddress),
        ),
      );
    }

    if (_startPoint != null && _endPoint != null) {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [_startPoint!, _endPoint!],
          color: AppColors.accent,
          width: 3,
        ),
      );
    }

    setState(() {});
  }

  Future<void> _createRoute() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startPoint == null || _endPoint == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select start and end points')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService().createRoute({
        'name': _nameController.text.trim(),
        'start_address': _startAddress ?? 'Start Point',
        'end_address': _endAddress ?? 'End Point',
        'start_latitude': _startPoint!.latitude,
        'start_longitude': _startPoint!.longitude,
        'end_latitude': _endPoint!.latitude,
        'end_longitude': _endPoint!.longitude,
        'fare': double.parse(_fareController.text),
        'is_active': true,
      });

      ref.read(homeProvider.notifier).refreshRoutes();

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to create route')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Route')),
      body: Column(
        children: [
          // Map
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(19.0760, 72.8777),
                    zoom: 12,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                    _getCurrentLocation();
                  },
                  onTap: _onMapTap,
                  markers: _markers,
                  polylines: _polylines,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                ),

                // Point selector
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: AppShadows.soft,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _isSelectingStart = true),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isSelectingStart
                                    ? AppColors.success.withOpacity(0.1)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _isSelectingStart
                                      ? AppColors.success
                                      : AppColors.border,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.trip_origin,
                                    color: _isSelectingStart
                                        ? AppColors.success
                                        : AppColors.textTertiary,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _startAddress ?? 'Tap to set start',
                                    style: AppTextStyles.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward),
                        const SizedBox(width: 8),
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _isSelectingStart = false),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: !_isSelectingStart
                                    ? AppColors.error.withOpacity(0.1)
                                    : AppColors.background,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: !_isSelectingStart
                                      ? AppColors.error
                                      : AppColors.border,
                                ),
                              ),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.place,
                                    color: !_isSelectingStart
                                        ? AppColors.error
                                        : AppColors.textTertiary,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _endAddress ?? 'Tap to set end',
                                    style: AppTextStyles.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
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

          // Form
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: AppShadows.strong,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Route Name',
                      hintText: 'e.g. Andheri to Bandra',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter route name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _fareController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Fare (₹)',
                      hintText: 'e.g. 50',
                      prefixText: '₹ ',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter fare';
                      }
                      if (double.tryParse(value) == null) {
                        return 'Please enter valid amount';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _createRoute,
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.surface,
                              ),
                            )
                          : const Text('Create Route'),
                    ),
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
