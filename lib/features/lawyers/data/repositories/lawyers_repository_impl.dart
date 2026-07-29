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
    final response =
        await _supabase.from('lawyer_profiles').select().eq('verified', true);

    return (response as List)
        .map((json) => LawyerProfileModel.fromJson(json).toEntity())
        .toList();
  }

  @override
  Future<LawyerProfile?> getLawyerProfile(String profileId) async {
    final response = await _supabase
        .from('lawyer_profiles')
        .select()
        .eq('profile_id', profileId)
        .maybeSingle();

    if (response == null) return null;
    return LawyerProfileModel.fromJson(response).toEntity();
  }

  @override
  Future<void> updateLawyerProfile(LawyerProfile profile) async {
    await _supabase.from('lawyer_profiles').upsert({
      'profile_id': profile.profileId,
      'license_number': profile.licenseNumber,
      'bio': profile.bio,
      'years_experience': profile.yearsExperience,
      'consultation_price': profile.consultationPrice,
      'availability': profile.availability,
    });
  }

  @override
  Future<String> uploadDocument(String path, String fileName) async {
    final user = _supabase.auth.currentUser;
    // تنظيم الملفات داخل مجلدات باسم المعرف الخاص بالمستخدم لسهولة تطبيق RLS
    final filePath = '${user?.id}/$fileName';

    await _supabase.storage
        .from('lawyer_documents')
        .uploadBinary(filePath, Uint8List(0));

    // توليد رابط موقع (Signed URL) صالح لمدة ساعة واحدة
    return _supabase.storage
        .from('lawyer_documents')
        .createSignedUrl(filePath, 3600);
  }
}
