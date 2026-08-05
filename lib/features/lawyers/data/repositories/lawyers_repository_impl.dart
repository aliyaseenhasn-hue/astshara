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
    try {
      debugPrint('🔍 LawyersRepo: Fetching verified lawyers...');

      final response = await _supabase
          .from('lawyer_profiles')
          .select('*, profiles(full_name, avatar_url)')
          .eq('verified', true);

      if (response == null) return [];

      final List<LawyerProfile> lawyers = [];
      for (var json in (response as List)) {
        try {
          final model = LawyerProfileModel.fromJson(json);
          final profileData = json['profiles'];

          Map<String, dynamic>? profile;
          if (profileData is List && profileData.isNotEmpty) {
            profile = profileData.first as Map<String, dynamic>;
          } else if (profileData is Map) {
            profile = profileData as Map<String, dynamic>;
          }

          lawyers.add(model.toEntity().copyWith(
                fullName:
                    profile?['full_name'] ?? model.fullName ?? 'محامي استشارة',
                avatarUrl: profile?['avatar_url'],
              ));
        } catch (e) {
          debugPrint('❌ LawyersRepo: Error parsing record: $e');
        }
      }
      return lawyers;
    } catch (e) {
      debugPrint('❌ LawyersRepo: Fetch error: $e');
      return [];
    }
  }

  @override
  Future<LawyerProfile?> getLawyerProfile(String profileId) async {
    try {
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
            fullName: profile?['full_name'] ?? model.fullName ?? 'محامي',
            avatarUrl: profile?['avatar_url'],
          );
    } catch (e) {
      debugPrint('❌ LawyersRepo: Profile fetch error: $e');
      return null;
    }
  }

  @override
  Future<void> updateLawyerProfile(LawyerProfile profile) async {
    try {
      debugPrint('⚖️ LawyersRepo: Attempting upsert for: ${profile.profileId}');

      // نقوم بتجهيز البيانات بعناية لتجنب خطأ 400
      final Map<String, dynamic> data = {
        'profile_id': profile.profileId,
        'license_number': profile.licenseNumber,
        'bio': profile.bio,
        'years_experience': profile.yearsExperience,
        'consultation_price': profile.consultationPrice,
        'whatsapp': profile.whatsapp,
        'id_card_url': profile.idCardUrl,
        'availability': profile.availability,
      };

      // معالجة التخصص: إرساله كنص (String) ليتوافق مع النوع TEXT في DB
      if (profile.specializations.isNotEmpty) {
        data['specialization'] = profile.specializations.join(',');
      }

      await _supabase
          .from('lawyer_profiles')
          .upsert(data, onConflict: 'profile_id');
      debugPrint('✅ LawyersRepo: Upsert successful');
    } on PostgrestException catch (e) {
      debugPrint('❌ Supabase 400 Fix: Error Details:');
      debugPrint('Message: ${e.message}');
      debugPrint('Hint: ${e.hint}');
      debugPrint('Details: ${e.details}');
      rethrow;
    } catch (e) {
      debugPrint('❌ LawyersRepo: Unexpected error: $e');
      rethrow;
    }
  }

  @override
  Future<String> uploadFile(
      Uint8List bytes, String fileName, String bucket) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    final filePath = '${user.id}/$fileName';
    try {
      await _supabase.storage.from(bucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );
      return await _supabase.storage
          .from(bucket)
          .createSignedUrl(filePath, 31536000);
    } catch (e) {
      debugPrint('❌ Storage Error: $e');
      rethrow;
    }
  }
}
