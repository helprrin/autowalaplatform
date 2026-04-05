import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/models.dart';

class AutoCard extends StatelessWidget {
  final NearbyRider rider;
  final VoidCallback onTap;
  final VoidCallback onCall;

  const AutoCard({
    super.key,
    required this.rider,
    required this.onTap,
    required this.onCall,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: rider.avatarUrl != null
                  ? ClipOval(
                      child: Image.network(rider.avatarUrl!, fit: BoxFit.cover),
                    )
                  : const Icon(
                      Icons.person,
                      size: 28,
                      color: AppColors.textTertiary,
                    ),
            ),

            const SizedBox(width: 16),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          rider.name,
                          style: AppTextStyles.bodyMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
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
                            rider.ratingAvg.toStringAsFixed(1),
                            style: AppTextStyles.bodySm.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          rider.vehicleNumber ?? 'Auto',
                          style: AppTextStyles.caption.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (rider.vehicleColor != null) ...[
                        const SizedBox(width: 8),
                        Text(rider.vehicleColor!, style: AppTextStyles.caption),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        rider.formattedDistance,
                        style: AppTextStyles.caption,
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(rider.formattedEta, style: AppTextStyles.caption),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Call button
            GestureDetector(
              onTap: onCall,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.phone,
                  color: AppColors.success,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
