import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/config/supabase_config.dart';
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
    required String authUid,
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
      final lawyersRepo = ref.read(lawyersRepositoryProvider);
      final authRepo = ref.read(authRepositoryProvider);

      debugPrint('--- 🔄 بدء عملية إكمال الملف للمحامي ---');

      // 1. تحديث البروفايل الأساسي أولاً (role + fullName)
      debugPrint('📝 الخطوة 1: تحديث ملف المحامي الأساسي...');
      await authRepo.updateProfile(
        fullName: fullName,
        email: email,
        role: 'lawyer',
        onboardingCompleted: false,
      );
      debugPrint('✅ تم تحديث الملف الأساسي');

      // 1b. جلب profiles.id الحقيقي (UUID مختلف عن auth.uid)
      final profileRow = await SupabaseConfig.client
          .from('profiles')
          .select('id')
          .eq('auth_id', authUid)
          .maybeSingle();

      if (profileRow == null) {
        throw Exception('❌ لم يتم العثور على سجل Profile للمستخدم');
      }
      final profileId = profileRow['id'] as String;
      debugPrint('✅ profiles.id = $profileId');

      String? avatarUrl;
      String? idCardUrl;

      // 2. رفع الصورة الشخصية
      if (profilePhotoBytes != null && profilePhotoBytes.isNotEmpty) {
        try {
          debugPrint('📸 الخطوة 2: رفع الصورة الشخصية...');
          final fileName =
              'avatar_${profileId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          avatarUrl = await lawyersRepo.uploadFile(
              profilePhotoBytes, fileName, 'avatars');
          debugPrint('✅ تم رفع الصورة الشخصية: $avatarUrl');
        } catch (e) {
          debugPrint('⚠️ تحذير: فشل رفع الصورة الشخصية: $e');
        }
      }

      // 3. رفع هوية النقابة
      if (idCardBytes != null && idCardBytes.isNotEmpty) {
        try {
          debugPrint('📄 الخطوة 3: رفع صورة الهوية...');
          final fileName =
              'id_${profileId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
          idCardUrl = await lawyersRepo.uploadFile(
              idCardBytes, fileName, 'lawyer_documents');
          debugPrint('✅ تم رفع صورة الهوية: $idCardUrl');
        } catch (e) {
          debugPrint('⚠️ تحذير: فشل رفع صورة الهوية: $e');
        }
      }

      // 4. إنشاء سجل المحامي — profileId هنا = profiles.id الصحيح
      debugPrint('⚖️ الخطوة 4: تحديث ملف المحامي المهني...');
      final lawyerProfile = LawyerProfile(
        id: '',
        profileId: profileId,
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

      // 5. التحديث النهائي للبروفايل مع رابط الصورة وعلامة الإكمال
      debugPrint('🔚 الخطوة 5: إنهاء الملف الشخصي...');
      await authRepo.updateProfile(
        avatarUrl: avatarUrl,
        onboardingCompleted: true,
      );
      debugPrint('✅ تم إنهاء الملف الشخصي');

      debugPrint('--- ✅ تمت العملية بنجاح ---');
      state = const AsyncData(null);
    } catch (e, st) {
      debugPrint('❌ خطأ حرج: $e');
      debugPrint('📍 Stack trace: $st');
      state = AsyncValue.error(e, st);
    } finally {
      ref.read(globalLoadingProvider.notifier).setLoading(false);
    }
  }
}
