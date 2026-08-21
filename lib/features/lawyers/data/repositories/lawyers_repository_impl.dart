import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/lawyer_profile.dart';
import '../../domain/repositories/lawyers_repository.dart';
import '../models/lawyer_profile_model.dart';

class LawyersRepositoryImpl implements LawyersRepository {
  final SupabaseClient _supabase;
  LawyersRepositoryImpl(this._supabase);
  static const _cacheKey = 'public_lawyers';
  static const _cacheTimeKey = 'public_lawyers_time';
  static const _cacheTtl = Duration(minutes: 10);

  Future<List<LawyerProfile>?> _readCachedLawyers() async {
    try {
      final box = Hive.box('app_cache');
      final timestamp = box.get(_cacheTimeKey) as int?;
      final raw = box.get(_cacheKey);
      if (timestamp == null || raw is! List) return null;
      if (DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(timestamp)) > _cacheTtl) return null;
      return _parseRows(raw);
    } catch (e) {
      debugPrint('⚠️ LawyersRepo: Cache read error: $e');
      return null;
    }
  }

  List<LawyerProfile> _parseRows(Iterable<dynamic> rows) {
    final result = <LawyerProfile>[];
    for (final item in rows) {
      try {
        final json = Map<String, dynamic>.from(item as Map);
        final model = LawyerProfileModel.fromJson(json);
        result.add(model.toEntity().copyWith(fullName: model.fullName ?? 'محامي استشارة', avatarUrl: json['avatar_url'] as String?));
      } catch (e) { debugPrint('❌ LawyersRepo: Record error: $e'); }
    }
    return result;
  }

  Future<void> _writeLawyersCache(List<dynamic> response) async {
    try {
      final box = Hive.box('app_cache');
      await box.put(_cacheKey, response.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      await box.put(_cacheTimeKey, DateTime.now().millisecondsSinceEpoch);
    } catch (e) { debugPrint('⚠️ LawyersRepo: Cache write error: $e'); }
  }

  @override
  Future<List<LawyerProfile>> getLawyers({int limit = 20, int offset = 0}) async {
    final cached = await _readCachedLawyers();
    if (cached != null && cached.isNotEmpty) {
      final end = (offset + limit).clamp(0, cached.length);
      if (offset < end) return cached.sublist(offset, end);
      return [];
    }
    try {
      // The current RPC is kept intact for compatibility. Pagination is applied
      // after the fetch until the RPC itself exposes limit/offset parameters.
      final response = await _supabase.rpc('get_public_lawyers');
      final rows = List<dynamic>.from(response as List);
      await _writeLawyersCache(rows);
      final end = (offset + limit).clamp(0, rows.length);
      return offset < end ? _parseRows(rows.sublist(offset, end)) : [];
    } catch (e) {
      debugPrint('❌ LawyersRepo: Fetch error: $e');
      if (cached == null) return [];
      final end = (offset + limit).clamp(0, cached.length);
      return offset < end ? cached.sublist(offset, end) : [];
    }
  }

  @override
  Future<LawyerProfile?> getLawyerProfile(String profileId) async {
    try {
      final response = await _supabase.rpc('get_public_lawyer', params: {'p_profile_id': profileId});
      final rows = response as List;
      if (rows.isEmpty) return null;
      final json = Map<String, dynamic>.from(rows.first as Map);
      final model = LawyerProfileModel.fromJson(json);
      return model.toEntity().copyWith(fullName: model.fullName ?? 'محامي', avatarUrl: json['avatar_url'] as String?);
    } catch (e) { debugPrint('❌ LawyersRepo: Profile fetch error: $e'); return null; }
  }

  @override
  Future<void> updateLawyerProfile(LawyerProfile profile) async {
    final data = <String, dynamic>{'profile_id': profile.profileId, 'license_number': profile.licenseNumber, 'bio': profile.bio, 'years_experience': profile.yearsExperience, 'consultation_price': profile.consultationPrice, 'whatsapp': profile.whatsapp, 'id_card_url': profile.idCardUrl, 'availability': profile.availability, 'services': profile.services.map((s) => s.toJson()).toList()};
    if (profile.specializations.isNotEmpty) data['specialization'] = profile.specializations;
    await _supabase.from('lawyer_profiles').upsert(data, onConflict: 'profile_id');
    try { await Hive.box('app_cache').delete(_cacheTimeKey); } catch (_) {}
  }

  @override
  Future<String> uploadFile(Uint8List bytes, String fileName, String bucket) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('المستخدم غير مسجل دخول');
    final safe = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path = '${user.id}/${DateTime.now().microsecondsSinceEpoch}_$safe';
    final ext = fileName.split('.').last.toLowerCase();
    final contentType = switch (ext) {'png' => 'image/png', 'webp' => 'image/webp', 'pdf' => 'application/pdf', 'jpg' || 'jpeg' => 'image/jpeg', _ => 'application/octet-stream'};
    await _supabase.storage.from(bucket).uploadBinary(path, bytes, fileOptions: FileOptions(upsert: false, contentType: contentType));
    return _supabase.storage.from(bucket).createSignedUrl(path, 31536000);
  }

  @override
  Future<void> requestSpecializationChange(List<String> newSpecs, {String? unionIdCardUrl}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('المستخدم غير مسجل دخول');
    final profile = await _supabase.from('profiles').select('id').eq('auth_id', user.id).maybeSingle();
    final profileId = profile?['id'] as String?;
    if (profileId == null) throw Exception('ملف المحامي غير مكتمل');
    if (newSpecs.isEmpty) throw Exception('يجب اختيار تخصص واحد على الأقل');
    if (unionIdCardUrl == null || unionIdCardUrl.trim().isEmpty) throw Exception('صورة هوية النقابة مطلوبة');
    await _supabase.from('specialization_change_requests').insert({'lawyer_id': profileId, 'requested_specializations': newSpecs, 'union_id_card_url': unionIdCardUrl, 'status': 'pending'});
    final admins = await _supabase.from('profiles').select('id').eq('role', 'admin');
    for (final row in (admins as List)) { await _supabase.from('notifications').insert({'user_id': row['id'], 'title': 'طلب تغيير تخصص جديد', 'body': 'وصل طلب جديد من محامٍ لتغيير التخصص ويحتاج إلى مراجعة صورة هوية النقابة.', 'type': 'specialization_change'}); }
  }
}
