import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../shared/providers/global_loading_provider.dart';
import '../../domain/entities/lawyer_profile.dart';
import 'lawyers_provider.dart';

part 'lawyer_setup_provider.g.dart';

@riverpod
class LawyerSetupController extends _$LawyerSetupController {
  @override
  FutureOr<void> build() {}

  Future<void> completeProfile({
    required String profileId,
    required String licenseNumber,
    required String bio,
    required int yearsExperience,
    required double price,
    XFile? idDocument,
  }) async {
    ref.read(globalLoadingProvider.notifier).setLoading(true);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(lawyersRepositoryProvider);

      // 1. Upload document if exists
      if (idDocument != null) {
        try {
          final fileName =
              'id_${profileId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          await repository.uploadDocument(idDocument.path, fileName);
        } catch (e) {
          debugPrint('Storage upload failed: $e');
        }
      }

      // 2. Update profile
      final profile = LawyerProfile(
        id: '',
        profileId: profileId,
        licenseNumber: licenseNumber,
        bio: bio,
        yearsExperience: yearsExperience,
        consultationPrice: price,
      );

      await repository.updateLawyerProfile(profile);
    });
    ref.read(globalLoadingProvider.notifier).setLoading(false);
  }
}
