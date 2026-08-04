import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/lawyer_profile.dart';
import '../../domain/repositories/lawyers_repository.dart';
import '../models/lawyer_profile_model.dart';

class LawyersRepositoryImpl implements LawyersRepository {
  final SupabaseClient _supabase;

  LawyersRepositoryImpl(this._supabase);

  @override
  Future<List<LawyerProfile>> getLawyers() async {
    final response = await _supabase
        .from('lawyer_profiles')
        .select('*, profiles(full_name, avatar_url)')
        .eq('verified', true);

    return (response as List).map((json) {
      final model = LawyerProfileModel.fromJson(json);
      final profileData = json['profiles'];

      // معالجة مرنة للـ Join (سواء كان كائن أو قائمة)
      Map<String, dynamic>? profile;
      if (profileData is List && profileData.isNotEmpty) {
        profile = profileData.first as Map<String, dynamic>;
      } else if (profileData is Map) {
        profile = profileData as Map<String, dynamic>;
      }

      return model.toEntity().copyWith(
            fullName: profile?['full_name'],
            avatarUrl: profile?['avatar_url'],
          );
    }).toList();
  }

  @override
  Future<LawyerProfile?> getLawyerProfile(String profileId) async {
    final response = await _supabase
        .from('lawyer_profiles')
        .select('*, profiles(full_name, avatar_url)')
        .eq('profile_id', profileId)
        .maybeSingle();

    if (response == null) return null;

    final model = LawyerProfileModel.fromJson(response);
    final profileData = response['profiles'];

    Map<String, dynamic>? profile;
    if (profileData is List && profileData.isNotEmpty) {
      profile = profileData.first as Map<String, dynamic>;
    } else if (profileData is Map) {
      profile = profileData as Map<String, dynamic>;
    }

    return model.toEntity().copyWith(
          fullName: profile?['full_name'],
          avatarUrl: profile?['avatar_url'],
        );
  }

  @override
  Future<void> updateLawyerProfile(LawyerProfile profile) async {
    try {
      debugPrint('⚖️ Updating lawyer profile for: ${profile.profileId}');
      await _supabase.from('lawyer_profiles').upsert({
        'profile_id': profile.profileId,
        // 'full_name': profile.fullName, // Removed redundant field causing 400 error
        'license_number': profile.licenseNumber,
        'bio': profile.bio,
        'specialization': profile.specializations
            .join(','), // Joined as string to match TEXT column
        'years_experience': profile.yearsExperience,
        'consultation_price': profile.consultationPrice,
        'whatsapp': profile.whatsapp,
        'id_card_url': profile.idCardUrl,
        'availability': profile.availability,
      }, onConflict: 'profile_id');
      debugPrint('✅ Lawyer profile updated successfully');
    } on PostgrestException catch (e) {
      debugPrint('❌ Supabase error (400) updating lawyer profile:');
      debugPrint('Message: ${e.message}');
      debugPrint('Details: ${e.details}');
      debugPrint('Hint: ${e.hint}');
      rethrow;
    } catch (e) {
      debugPrint('❌ Unexpected error updating lawyer profile: $e');
      rethrow;
    }
  }

  @override
  Future<String> uploadFile(
      Uint8List bytes, String fileName, String bucket) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('المستخدم غير مسجل دخول');

    final filePath = '${user.id}/$fileName';

    try {
      debugPrint('جاري رفع الملف: $filePath في الوعاء: $bucket');
      await _supabase.storage.from(bucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      debugPrint('تم رفع الملف بنجاح');
      return await _supabase.storage
          .from(bucket)
          .createSignedUrl(filePath, 31536000);
    } catch (e) {
      debugPrint('خطأ في رفع الملف إلى Supabase: $e');
      rethrow;
    }
  }
}
