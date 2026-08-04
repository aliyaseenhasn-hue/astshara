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
    required String authUid, // تم تغيير الاسم ليكون واضحاً أنه معرف المصادقة
    required String fullName,
    String? email,
    required String whatsapp,
    String? licenseNumber,
    String? bio,
    List<String>? specializations,
    int? yearsExperience,
    double? consultationPrice,
    Uint8List? profilePhotoBytes,
    Uint8List? idCardBytes,
  }) async {
    // التحقق من البيانات المطلوبة
    if (fullName.isEmpty || whatsapp.isEmpty) {
      throw Exception('البيانات المطلوبة غير كاملة');
    }

    ref.read(globalLoadingProvider.notifier).setLoading(true);
    state = const AsyncLoading();

    try {
      state = await AsyncValue.guard(() async {
        final lawyersRepo = ref.read(lawyersRepositoryProvider);
        final authRepo = ref.read(authRepositoryProvider);

        debugPrint('--- 🔄 بدء عملية إكمال الملف للمحامي ---');

        // 1. جلب الـ profile_id الفعلي من جدول profiles باستخدام auth_id
        // لأن profiles.id لا يساوي auth.uid()
        final userProfile = await authRepo.getCurrentUser();
        if (userProfile == null) throw Exception('فشل جلب بيانات المستخدم');
        final String realProfileId = userProfile.id;

        // 2. تحديث البروفايل الأساسي أولاً
        debugPrint('📝 الخطوة 2: تحديث ملف المحامي الأساسي...');
        await authRepo.updateProfile(
          fullName: fullName,
          email: email,
          role: 'lawyer',
          onboardingCompleted: false,
        );
        debugPrint('✅ تم تحديث الملف الأساسي');

        String? avatarUrl;
        String? idCardUrl;

        // 3. رفع الصورة الشخصية
        if (profilePhotoBytes != null && profilePhotoBytes.isNotEmpty) {
          try {
            debugPrint('📸 الخطوة 3: رفع الصورة الشخصية...');
            final fileName =
                'avatar_${realProfileId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
            avatarUrl = await lawyersRepo.uploadFile(
                profilePhotoBytes, fileName, 'avatars');
            debugPrint('✅ تم رفع الصورة الشخصية: $avatarUrl');
          } catch (e) {
            debugPrint('⚠️ تحذير: فشل رفع الصورة الشخصية: $e');
          }
        }

        // 4. رفع هوية النقابة
        if (idCardBytes != null && idCardBytes.isNotEmpty) {
          try {
            debugPrint('📄 الخطوة 4: رفع صورة الهوية...');
            final fileName =
                'id_${realProfileId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
            idCardUrl = await lawyersRepo.uploadFile(
                idCardBytes, fileName, 'lawyer_documents');
            debugPrint('✅ تم رفع صورة الهوية: $idCardUrl');
          } catch (e) {
            debugPrint('⚠️ تحذير: فشل رفع صورة الهوية: $e');
          }
        }

        // 5. إنشاء سجل المحامي المهني باستخدام realProfileId
        debugPrint('⚖️ الخطوة 5: تحديث ملف المحامي المهني...');
        final lawyerProfile = LawyerProfile(
          id: '', // Handled by DB
          profileId: realProfileId,
          fullName: fullName,
          whatsapp: whatsapp,
          idCardUrl: idCardUrl,
          verified: false,
          licenseNumber: licenseNumber ?? 'PENDING',
          specializations: specializations ?? [],
          bio: bio ?? 'طلب انضمام جديد',
          yearsExperience: yearsExperience ?? 0,
          consultationPrice: consultationPrice ?? 0,
        );

        await lawyersRepo.updateLawyerProfile(lawyerProfile);
        debugPrint('✅ تم تحديث ملف المحامي المهني');

        // 6. التحديث النهائي للبروفايل
        debugPrint('🔚 الخطوة 6: إنهاء الملف الشخصي...');
        await authRepo.updateProfile(
          avatarUrl: avatarUrl,
          onboardingCompleted: true,
        );
        debugPrint('✅ تم إنهاء الملف الشخصي');

        // 7. تحديث الحالة
        ref.invalidate(authStateChangesProvider);
        await ref.read(authStateChangesProvider.future);

        debugPrint('--- ✅ تمت العملية بنجاح ---');
      });
    } catch (e, st) {
      debugPrint('❌ خطأ حرج: $e');
      state = AsyncValue.error(e, st);
    } finally {
      ref.read(globalLoadingProvider.notifier).setLoading(false);
    }
  }
}
