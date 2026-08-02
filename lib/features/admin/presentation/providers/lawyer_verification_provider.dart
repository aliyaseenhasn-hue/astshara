import 'package:astshara/features/lawyers/data/models/lawyer_profile_model.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../lawyers/domain/entities/lawyer_profile.dart';
import '../../../lawyers/presentation/providers/lawyers_provider.dart';
import '../../../../core/config/supabase_config.dart';

part 'lawyer_verification_provider.g.dart';

@riverpod
class LawyerVerification extends _$LawyerVerification {
  @override
  FutureOr<List<LawyerProfile>> build() async {
    try {
      // محاولة جلب البيانات مع ربط الجداول
      // سنستخدم ربطاً مرناً لضمان عدم استثناء السجلات إذا كان هناك مشكلة في الربط الإلزامي
      final response = await SupabaseConfig.client
          .from('lawyer_profiles')
          .select('*, profiles(full_name)')
          .eq('verified', false);

      debugPrint('Admin Lawyer Requests Response: $response');

      if (response == null) return [];

      return (response as List).map((json) {
        final profileData = json['profiles'];
        final lawyer = LawyerProfileModel.fromJson(json).toEntity();

        // دمج الاسم إذا وجد، وإلا وضع اسم افتراضي
        final fullName =
            profileData != null ? profileData['full_name'] : 'محامي مجهول';
        return lawyer.copyWith(fullName: fullName);
      }).toList();
    } catch (e, stack) {
      debugPrint('Error fetching lawyer verification requests: $e');
      debugPrint('Stack trace: $stack');
      return [];
    }
  }

  Future<void> approveLawyer(String profileId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await SupabaseConfig.client
          .from('lawyer_profiles')
          .update({'verified': true}).eq('profile_id', profileId);

      // تحديث قائمة المحامين الموثقين
      ref.invalidate(lawyersListProvider);
      return build();
    });
  }

  Future<void> rejectLawyer(String profileId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await SupabaseConfig.client
          .from('lawyer_profiles')
          .delete()
          .eq('profile_id', profileId);

      return build();
    });
  }
}
