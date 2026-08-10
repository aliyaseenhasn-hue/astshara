import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabase;
  final StreamController<User?> _userStateController = StreamController<User?>.broadcast();

  AuthRepositoryImpl(this._supabase);

  @override
  Stream<User?> get authStateChanges => _userStateController.stream;

  @override
  Future<User?> getCurrentUser() async {
    final authUser = _supabase.auth.currentUser;
    if (authUser == null) return null;
    try {
      final profile = await _supabase.from('profiles').select().eq('auth_id', authUser.id).maybeSingle();
      if (profile == null) return null;
      return User.fromJson(profile);
    } catch (e) {
      debugPrint('❌ خطأ في جلب المستخدم: $e');
      return null;
    }
  }

  @override
  Future<void> updateProfile(Map<String, dynamic> data) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('يجب تسجيل الدخول أولاً');
    try {
      await _supabase.from('profiles').upsert({
        ...data,
        'auth_id': user.id,
        'id': user.id,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'auth_id');
      await refreshUser();
    } on PostgrestException catch (e) {
      debugPrint('❌ خطأ Supabase: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('❌ خطأ غير متوقع: $e');
      rethrow;
    }
  }

  @override
  Future<void> refreshUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    _userStateController.add(await getCurrentUser());
  }

  @override
  Future<void> deleteAccount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    await _supabase.from('profiles').delete().eq('auth_id', user.id);
    try {
      await _supabase.rpc('delete_user_account');
    } catch (e) {
      debugPrint('❌ خطأ حذف حساب المستخدم: $e');
      rethrow;
    }
    await _supabase.auth.signOut();
  }

  void dispose() {
    _userStateController.close();
  }
}
