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
      final response = await _supabase.rpc('get_public_lawyers');

      final lawyers = <LawyerProfile>[];
      for (final item in (response as List)) {
        try {
          final json = Map<String, dynamic>.from(item as Map);
          final model = LawyerProfileModel.fromJson(json);
          lawyers.add(model.toEntity().copyWith(
                fullName: model.fullName ?? 'محامي استشارة',
                avatarUrl: json['avatar_url'] as String?,
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
      final response = await _supabase.rpc(
        'get_public_lawyer',
        params: {'p_profile_id': profileId},
      );
      final rows = response as List;
      if (rows.isEmpty) return null;

      final json = Map<String, dynamic>.from(rows.first as Map);
      final model = LawyerProfileModel.fromJson(json);
      return model.toEntity().copyWith(
            fullName: model.fullName ?? 'محامي',
            avatarUrl: json['avatar_url'] as String?,
          );
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
        data['specialization'] = profile.specializations;
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

    // لا نعيد استخدام الاسم نفسه حتى لا يتحول الرفع إلى UPDATE غير ضروري.
    final safeFileName = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final filePath = '${user.id}/${DateTime.now().microsecondsSinceEpoch}_$safeFileName';
    try {
      await _supabase.storage.from(bucket).uploadBinary(
            filePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
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
