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
      final response = await _supabase
          .from('public_lawyer_profiles')
          .select()
          .eq('verified', true);

      return (response as List)
          .map((json) => LawyerProfileModel.fromJson(
                Map<String, dynamic>.from(json as Map),
              ).toEntity())
          .toList();
    } catch (e) {
      debugPrint('❌ LawyersRepo: Fetch error: $e');
      return [];
    }
  }

  @override
  Future<LawyerProfile?> getLawyerProfile(String profileId) async {
    try {
      final response = await _supabase
          .from('public_lawyer_profiles')
          .select()
          .eq('profile_id', profileId)
          .maybeSingle();

      if (response == null) return null;
      return LawyerProfileModel.fromJson(
        Map<String, dynamic>.from(response),
      ).toEntity();
    } catch (e) {
      debugPrint('❌ LawyersRepo: Profile fetch error: $e');
      return null;
    }
  }

  @override
  Future<void> updateLawyerProfile(LawyerProfile profile) async {
    try {
      final Map<String, dynamic> data = {
        'profile_id': profile.profileId,
        'license_number': profile.licenseNumber,
        'bio': profile.bio,
        'years_experience': profile.yearsExperience,
        'consultation_price': profile.consultationPrice,
        'whatsapp': profile.whatsapp,
        'id_card_url': profile.idCardUrl,
        'availability': profile.availability,
        'services': profile.services.map((s) => s.toJson()).toList(),
      };

      if (profile.specializations.isNotEmpty) {
        data['specialization'] = profile.specializations.join(',');
      }

      await _supabase
          .from('lawyer_profiles')
          .upsert(data, onConflict: 'profile_id');
    } on PostgrestException catch (e) {
      debugPrint('❌ Supabase: ${e.message}');
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

  Future<void> requestSpecializationChange(List<String> newSpecs) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('المستخدم غير مسجل دخول');

    await _supabase.from('specialization_change_requests').insert({
      'lawyer_id': user.id,
      'requested_specializations': newSpecs,
      'status': 'pending',
    });
  }
}
