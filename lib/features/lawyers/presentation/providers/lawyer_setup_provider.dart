import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../shared/providers/global_loading_provider.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../domain/entities/lawyer_profile.dart';
import 'lawyers_provider.dart';

part 'lawyer_setup_provider.g.dart';

@riverpod
class LawyerSetupController extends _$LawyerSetupController {
  @override
  FutureOr<void> build() {}

  Future<void> completeProfile({
    required String profileId,
    required String fullName,
    String? email,
    required String whatsapp,
    Uint8List? profilePhotoBytes,
    Uint8List? idCardBytes,
  }) async {
    ref.read(globalLoadingProvider.notifier).setLoading(true);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final lawyersRepo = ref.read(lawyersRepositoryProvider);

      String? avatarUrl;
      String? idCardUrl;

      // 1. Upload Profile Photo if exists (avatars bucket)
      if (profilePhotoBytes != null) {
        final fileName =
            'avatar_${profileId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        avatarUrl = await lawyersRepo.uploadFile(
            profilePhotoBytes, fileName, 'avatars');
      }

      // 2. Upload ID Card if exists (lawyer_documents bucket)
      if (idCardBytes != null) {
        final fileName =
            'id_${profileId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        idCardUrl = await lawyersRepo.uploadFile(
            idCardBytes, fileName, 'lawyer_documents');
      }

      // 3. Update Lawyer Specific Profile (with whatsapp and id_card_url)
      final lawyerProfile = LawyerProfile(
        id: '', // Handled by DB
        profileId: profileId,
        fullName: fullName,
        whatsapp: whatsapp,
        idCardUrl: idCardUrl,
        verified: false,
        licenseNumber: 'PENDING',
        bio: 'طلب انضمام جديد',
        yearsExperience: 0,
        consultationPrice: 0,
      );

      await lawyersRepo.updateLawyerProfile(lawyerProfile);

      // 4. Update the main profile with name, email, role, and avatar_url
      await ref.read(authRepositoryProvider).updateProfile(
            fullName: fullName,
            email: email,
            role: 'lawyer',
            avatarUrl: avatarUrl,
            onboardingCompleted: true,
          );
    });
    ref.read(globalLoadingProvider.notifier).setLoading(false);
  }
}
