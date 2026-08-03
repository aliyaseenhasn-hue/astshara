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
    String? licenseNumber,
    String? bio,
    int? yearsExperience,
    double? consultationPrice,
    Uint8List? profilePhotoBytes,
    Uint8List? idCardBytes,
  }) async {
    ref.read(globalLoadingProvider.notifier).setLoading(true);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final lawyersRepo = ref.read(lawyersRepositoryProvider);
      final authRepo = ref.read(authRepositoryProvider);

      debugPrint('--- بدء عملية إكمال الملف للمحامي ---');

      // 1. تحديث البروفايل الأساسي أولاً لضمان وجود السجل (تجنب مشاكل الـ FK)
      debugPrint('Step 1: Updating main profile (initial)...');
      await authRepo.updateProfile(
        fullName: fullName,
        email: email,
        role: 'lawyer',
        onboardingCompleted: false,
      );

      String? avatarUrl;
      String? idCardUrl;

      // 2. رفع الصورة الشخصية
      if (profilePhotoBytes != null) {
        debugPrint('Step 2: Uploading profile photo...');
        final fileName =
            'avatar_${profileId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        avatarUrl = await lawyersRepo.uploadFile(
            profilePhotoBytes, fileName, 'avatars');
      }

      // 3. رفع هوية النقابة
      if (idCardBytes != null) {
        debugPrint('Step 3: Uploading ID card...');
        final fileName =
            'id_${profileId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
        idCardUrl = await lawyersRepo.uploadFile(
            idCardBytes, fileName, 'lawyer_documents');
      }

      // 4. إنشاء سجل المحامي المهني
      debugPrint('Step 4: Updating lawyer professional profile...');
      final lawyerProfile = LawyerProfile(
        id: '', // Handled by DB
        profileId: profileId,
        fullName: fullName,
        whatsapp: whatsapp,
        idCardUrl: idCardUrl,
        verified: false,
        licenseNumber: licenseNumber ?? 'PENDING',
        bio: bio ?? 'طلب انضمام جديد',
        yearsExperience: yearsExperience ?? 0,
        consultationPrice: consultationPrice ?? 0,
      );

      await lawyersRepo.updateLawyerProfile(lawyerProfile);

      // 5. التحديث النهائي للبروفايل مع رابط الصورة وعلامة الإكمال
      debugPrint('Step 5: Finalizing main profile...');
      await authRepo.updateProfile(
        avatarUrl: avatarUrl,
        onboardingCompleted: true,
      );

      // 6. تحديث حالة المستخدم ليعيد التوجيه
      ref.invalidate(authStateChangesProvider);

      debugPrint('--- تمت العملية بنجاح ---');
    });
    ref.read(globalLoadingProvider.notifier).setLoading(false);
  }
}
