import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/auth_provider.dart';
import '../../providers/kyc_provider.dart';

class KycScreen extends ConsumerStatefulWidget {
  const KycScreen({super.key});

  @override
  ConsumerState<KycScreen> createState() => _KycScreenState();
}

class _KycScreenState extends ConsumerState<KycScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(kycProvider.notifier).loadDocuments();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final kycState = ref.watch(kycProvider);
    final rider = authState.rider;

    return Scaffold(
      appBar: AppBar(title: const Text('KYC Verification')),
      body: kycState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _getStatusColor(
                        rider?.kycStatus ?? 'pending',
                      ).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getStatusColor(rider?.kycStatus ?? 'pending'),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _getStatusIcon(rider?.kycStatus ?? 'pending'),
                          size: 48,
                          color: _getStatusColor(rider?.kycStatus ?? 'pending'),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          AppConstants.kycStatusLabels[rider?.kycStatus] ??
                              'Pending',
                          style: AppTextStyles.h3,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getStatusMessage(rider?.kycStatus ?? 'pending'),
                          style: AppTextStyles.bodySm,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  Text('Required Documents', style: AppTextStyles.h3),
                  const SizedBox(height: 16),

                  // Document list
                  ...AppConstants.requiredDocuments.map((type) {
                    final doc = kycState.getDocument(type);
                    final label = AppConstants.documentLabels[type] ?? type;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: doc == null
                                  ? AppColors.background
                                  : doc.isApproved
                                  ? AppColors.success.withOpacity(0.1)
                                  : doc.isRejected
                                  ? AppColors.error.withOpacity(0.1)
                                  : AppColors.warning.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _getDocumentIcon(type),
                              color: doc == null
                                  ? AppColors.textTertiary
                                  : doc.isApproved
                                  ? AppColors.success
                                  : doc.isRejected
                                  ? AppColors.error
                                  : AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(label, style: AppTextStyles.bodyMedium),
                                if (doc != null)
                                  Text(
                                    doc.isApproved
                                        ? 'Verified'
                                        : doc.isRejected
                                        ? 'Rejected: ${doc.rejectionReason ?? ''}'
                                        : 'Under review',
                                    style: AppTextStyles.caption.copyWith(
                                      color: doc.isApproved
                                          ? AppColors.success
                                          : doc.isRejected
                                          ? AppColors.error
                                          : AppColors.warning,
                                    ),
                                  )
                                else
                                  Text(
                                    'Not uploaded',
                                    style: AppTextStyles.caption,
                                  ),
                              ],
                            ),
                          ),
                          if (doc == null || doc.isRejected)
                            TextButton(
                              onPressed: () =>
                                  context.push('/kyc/upload/$type'),
                              child: const Text('Upload'),
                            )
                          else if (doc.isPending)
                            const Icon(
                              Icons.hourglass_empty,
                              color: AppColors.warning,
                            )
                          else
                            const Icon(
                              Icons.check_circle,
                              color: AppColors.success,
                            ),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 24),

                  // Submit button
                  if (rider?.kycStatus == 'pending' &&
                      kycState.allDocumentsUploaded)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: kycState.isLoading
                            ? null
                            : () async {
                                final success = await ref
                                    .read(kycProvider.notifier)
                                    .submitKyc();
                                if (success && mounted) {
                                  context.go('/home');
                                }
                              },
                        child: const Text('Submit for Verification'),
                      ),
                    ),

                  if (rider?.kycStatus == 'verified')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => context.go('/home'),
                        child: const Text('Continue to Home'),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'verified':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'submitted':
        return AppColors.warning;
      default:
        return AppColors.textTertiary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'verified':
        return Icons.verified;
      case 'rejected':
        return Icons.cancel;
      case 'submitted':
        return Icons.hourglass_empty;
      default:
        return Icons.upload_file;
    }
  }

  String _getStatusMessage(String status) {
    switch (status) {
      case 'verified':
        return 'Your documents have been verified. You can now go online!';
      case 'rejected':
        return 'Some documents were rejected. Please re-upload them.';
      case 'submitted':
        return 'Your documents are being reviewed. This usually takes 24-48 hours.';
      default:
        return 'Please upload all required documents to start earning.';
    }
  }

  IconData _getDocumentIcon(String type) {
    switch (type) {
      case 'driving_license':
        return Icons.badge;
      case 'vehicle_registration':
        return Icons.directions_car;
      case 'permit':
        return Icons.description;
      case 'photo':
        return Icons.person;
      default:
        return Icons.insert_drive_file;
    }
  }
}
