import 'package:astshara/features/lawyers/data/models/lawyer_profile_model.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../lawyers/domain/entities/lawyer_profile.dart';
import '../../../lawyers/presentation/providers/lawyers_provider.dart';
import '../../../../core/config/supabase_config.dart';

part 'lawyer_verification_provider.g.dart';

@riverpod
class LawyerVerification extends _$LawyerVerification {
  @override
  FutureOr<List<LawyerProfile>> build() async {
    final response = await SupabaseConfig.client
        .from('lawyer_profiles')
        .select('*, profiles(full_name)')
        .eq('verified', false);

    return (response as List).map((json) {
      final profile = json['profiles'];
      return LawyerProfileModel.fromJson(json)
          .toEntity()
          .copyWith(fullName: profile['full_name']);
    }).toList();
  }

  Future<void> approveLawyer(String profileId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await SupabaseConfig.client
          .from('lawyer_profiles')
          .update({'verified': true}).eq('profile_id', profileId);

      // تحديث قائمة المحامين الموثقين أيضاً
      ref.invalidate(lawyersListProvider);
      return build();
    });
  }

  Future<void> rejectLawyer(String profileId) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      // يمكنك إضافة منطق لحذف السجل أو تحديث حالته كمرفوض
      await SupabaseConfig.client
          .from('lawyer_profiles')
          .delete()
          .eq('profile_id', profileId);

      return build();
    });
  }
}
