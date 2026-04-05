import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';

class RideHistoryScreen extends ConsumerStatefulWidget {
  const RideHistoryScreen({super.key});

  @override
  ConsumerState<RideHistoryScreen> createState() => _RideHistoryScreenState();
}

class _RideHistoryScreenState extends ConsumerState<RideHistoryScreen> {
  List<RideLog> _rides = [];
  bool _isLoading = true;
  int _currentPage = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadRides();
  }

  Future<void> _loadRides({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _currentPage = 1;
        _hasMore = true;
      });
    }

    if (!_hasMore && !refresh) return;

    setState(() => _isLoading = true);

    try {
      final response = await ref
          .read(apiServiceProvider)
          .getRideHistory(page: _currentPage);

      if (response.data['success'] == true) {
        final ridesData = response.data['data']['rides'] as List;
        final rides = ridesData.map((r) => RideLog.fromJson(r)).toList();

        final pagination = response.data['data']['pagination'];
        _hasMore = pagination['current_page'] < pagination['last_page'];

        setState(() {
          if (refresh) {
            _rides = rides;
          } else {
            _rides.addAll(rides);
          }
          _currentPage++;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Ride History')),
      body: RefreshIndicator(
        onRefresh: () => _loadRides(refresh: true),
        child: _isLoading && _rides.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : _rides.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.history,
                      size: 64,
                      color: AppColors.textTertiary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No rides yet',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _rides.length + (_hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _rides.length) {
                    _loadRides();
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final ride = _rides[index];
                  return _RideCard(ride: ride);
                },
              ),
      ),
    );
  }
}

class _RideCard extends StatelessWidget {
  final RideLog ride;

  const _RideCard({required this.ride});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.electric_rickshaw,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ride.rider.name, style: AppTextStyles.bodyMedium),
                    Text(
                      ride.rider.vehicleNumber ?? 'Auto',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (ride.fareShown != null)
                    Text(
                      '₹${ride.fareShown!.toStringAsFixed(0)}',
                      style: AppTextStyles.bodyMedium,
                    ),
                  Row(
                    children: [
                      const Icon(
                        Icons.star,
                        size: 14,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        ride.rider.ratingAvg.toStringAsFixed(1),
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Route info
          if (ride.routeName != null || ride.pickupAddress != null) ...[
            Row(
              children: [
                const Icon(Icons.circle, size: 10, color: AppColors.success),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ride.pickupAddress ?? 'Pickup',
                    style: AppTextStyles.bodySm,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (ride.dropoffAddress != null) ...[
              Container(
                margin: const EdgeInsets.only(left: 4),
                height: 20,
                width: 2,
                color: AppColors.border,
              ),
              Row(
                children: [
                  const Icon(
                    Icons.location_on,
                    size: 10,
                    color: AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ride.dropoffAddress!,
                      style: AppTextStyles.bodySm,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
          ],

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDate(ride.startedAt), style: AppTextStyles.caption),
              if (!ride.hasRated && ride.isCompleted)
                TextButton(
                  onPressed: () => _showRatingDialog(context),
                  child: const Text('Rate Ride'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  void _showRatingDialog(BuildContext context) {
    // Show rating dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rate Your Ride'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('How was your ride with ${ride.rider.name}?'),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  icon: Icon(Icons.star, size: 32, color: AppColors.warning),
                  onPressed: () {
                    Navigator.pop(context);
                    // Submit rating
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
