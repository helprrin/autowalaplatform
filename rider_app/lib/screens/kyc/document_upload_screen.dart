import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme.dart';
import '../../core/constants.dart';
import '../../providers/kyc_provider.dart';

class DocumentUploadScreen extends ConsumerStatefulWidget {
  final String documentType;

  const DocumentUploadScreen({super.key, required this.documentType});

  @override
  ConsumerState<DocumentUploadScreen> createState() =>
      _DocumentUploadScreenState();
}

class _DocumentUploadScreenState extends ConsumerState<DocumentUploadScreen> {
  File? _selectedFile;
  final _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(
      source: source,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );

    if (image != null) {
      setState(() {
        _selectedFile = File(image.path);
      });
    }
  }

  Future<void> _upload() async {
    if (_selectedFile == null) return;

    final success = await ref
        .read(kycProvider.notifier)
        .uploadDocument(widget.documentType, _selectedFile!.path);

    if (success && mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final kycState = ref.watch(kycProvider);
    final label =
        AppConstants.documentLabels[widget.documentType] ?? widget.documentType;

    return Scaffold(
      appBar: AppBar(title: Text('Upload $label')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Upload your $label', style: AppTextStyles.h3),
            const SizedBox(height: 8),
            Text(
              _getInstructions(widget.documentType),
              style: AppTextStyles.bodySm,
            ),

            const SizedBox(height: 24),

            // Preview or placeholder
            Expanded(
              child: GestureDetector(
                onTap: () => _showPicker(),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.border,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: _selectedFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.file(
                            _selectedFile!,
                            fit: BoxFit.contain,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.cloud_upload_outlined,
                              size: 64,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Tap to select image',
                              style: AppTextStyles.bodyMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'JPG, PNG up to 5MB',
                              style: AppTextStyles.caption,
                            ),
                          ],
                        ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (_selectedFile != null) ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showPicker(),
                      child: const Text('Change'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: kycState.isLoading ? null : _upload,
                      child: kycState.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.surface,
                              ),
                            )
                          : const Text('Upload'),
                    ),
                  ),
                ],
              ),
            ] else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showPicker(),
                  child: const Text('Select Image'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take Photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _getInstructions(String type) {
    switch (type) {
      case 'driving_license':
        return 'Take a clear photo of your driving license. Both front and back should be visible.';
      case 'vehicle_registration':
        return 'Upload a clear photo of your vehicle registration certificate (RC).';
      case 'permit':
        return 'Upload your auto-rickshaw permit document.';
      case 'photo':
        return 'Take a clear selfie or upload a recent passport-size photo.';
      default:
        return 'Upload a clear photo of the document.';
    }
  }
}
