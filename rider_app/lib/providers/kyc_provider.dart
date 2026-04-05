import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

final kycProvider = StateNotifierProvider<KycNotifier, KycState>((ref) {
  return KycNotifier(ref);
});

class KycState {
  final bool isLoading;
  final List<Document> documents;
  final String? error;

  KycState({this.isLoading = false, this.documents = const [], this.error});

  KycState copyWith({
    bool? isLoading,
    List<Document>? documents,
    String? error,
  }) {
    return KycState(
      isLoading: isLoading ?? this.isLoading,
      documents: documents ?? this.documents,
      error: error,
    );
  }

  bool hasDocument(String type) {
    return documents.any((d) => d.type == type);
  }

  Document? getDocument(String type) {
    try {
      return documents.firstWhere((d) => d.type == type);
    } catch (e) {
      return null;
    }
  }

  bool get allDocumentsUploaded {
    const required = [
      'driving_license',
      'vehicle_registration',
      'permit',
      'photo',
    ];
    return required.every((type) => hasDocument(type));
  }

  bool get allDocumentsApproved {
    const required = [
      'driving_license',
      'vehicle_registration',
      'permit',
      'photo',
    ];
    return required.every((type) {
      final doc = getDocument(type);
      return doc?.isApproved ?? false;
    });
  }
}

class KycNotifier extends StateNotifier<KycState> {
  KycNotifier(this._ref) : super(KycState());

  final Ref _ref;
  final _api = ApiService();

  Future<void> loadDocuments() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final docs = await _api.getDocuments();
      state = state.copyWith(
        isLoading: false,
        documents: docs.map((d) => Document.fromJson(d)).toList(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load documents.',
      );
    }
  }

  Future<bool> uploadDocument(String type, String filePath) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _api.uploadDocument(type, filePath);
      await loadDocuments();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to upload document.',
      );
      return false;
    }
  }

  Future<bool> submitKyc() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      await _api.submitKyc();

      // Refresh auth to get updated KYC status
      await _ref.read(authProvider.notifier).refreshProfile();

      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Failed to submit KYC.');
      return false;
    }
  }
}
