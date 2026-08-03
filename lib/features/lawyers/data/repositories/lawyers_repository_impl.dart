import 'dart:typed_data';
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
        .select('*, profiles(full_name)')
        .eq('verified', true);

    return (response as List).map((json) {
      final model = LawyerProfileModel.fromJson(json);
      final profile = json['profiles'] as Map<String, dynamic>?;
      return model.toEntity().copyWith(
            fullName: profile?['full_name'],
          );
    }).toList();
  }

  @override
  Future<LawyerProfile?> getLawyerProfile(String profileId) async {
    final response = await _supabase
        .from('lawyer_profiles')
        .select('*, profiles(full_name)')
        .eq('profile_id', profileId)
        .maybeSingle();

    if (response == null) return null;
    final model = LawyerProfileModel.fromJson(response);
    final profile = response['profiles'] as Map<String, dynamic>?;
    return model.toEntity().copyWith(
          fullName: profile?['full_name'],
        );
  }

  @override
  Future<void> updateLawyerProfile(LawyerProfile profile) async {
    await _supabase.from('lawyer_profiles').upsert({
      'profile_id': profile.profileId,
      'license_number': profile.licenseNumber,
      'bio': profile.bio,
      'years_experience': profile.yearsExperience,
      'consultation_price': profile.consultationPrice,
      'whatsapp': profile.whatsapp,
      'id_card_url': profile.idCardUrl,
      'availability': profile.availability,
    });
  }

  @override
  Future<String> uploadFile(
      Uint8List bytes, String fileName, String bucket) async {
    final user = _supabase.auth.currentUser;
    final filePath = '${user?.id}/$fileName';

    await _supabase.storage.from(bucket).uploadBinary(filePath, bytes);

    return _supabase.storage.from(bucket).createSignedUrl(filePath, 3600);
  }
}
