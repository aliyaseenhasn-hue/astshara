import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/app_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabase;

  AuthRepositoryImpl(this._supabase);

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('auth_id', user.id)
          .maybeSingle();

      if (response == null) {
        debugPrint('Profile not found in database for auth_id: ${user.id}');
        // نرجع fullName كـ null لكي يكتشف الـ Router أنه مستخدم جديد ويحتاج لإكمال بياناته واختيار دوره
        return AppUser(
          id: user.id,
          email: user.email,
          fullName: null, // تعمدنا جعله null هنا
          phone: user.phone,
          role: 'user',
        );
      }

      return AppUserModel.fromJson(response).toEntity();
    } catch (e) {
      debugPrint('Error fetching user profile from DB: $e');
      // في حالة حدوث خطأ تقني، نستخدم بيانات الجلسة كخيار احتياطي
      return AppUser(
        id: user.id,
        email: user.email,
        phone: user.phone,
        fullName: user.userMetadata?['full_name'] as String?,
        role: (user.userMetadata?['role'] as String?) ?? 'user',
      );
    }
  }

  @override
  Future<void> signInWithEmail(
      {required String email, required String password}) async {
    await _supabase.auth.signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String role,
  }) async {
    await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'full_name': fullName,
        'role': role,
      },
    );
  }

  @override
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  @override
  Future<void> signInWithPhone(String phone) async {
    await _supabase.auth.signInWithOtp(phone: phone);
  }

  @override
  Future<void> signInWithGoogle() async {
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      queryParams: {
        'prompt': 'select_account',
      },
    );
  }

  @override
  Future<void> verifyOTP({required String phone, required String token}) async {
    await _supabase.auth.verifyOTP(
      phone: phone,
      token: token,
      type: OtpType.sms,
    );
  }

  @override
  Future<void> updateProfile(
      {String? fullName, String? email, String? role}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final data = <String, dynamic>{};
    if (fullName != null) data['full_name'] = fullName;
    if (email != null) data['email'] = email;
    if (role != null) data['role'] = role;

    await _supabase.from('profiles').upsert({
      'auth_id': user.id,
      'phone': user.phone,
      ...data,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'auth_id');
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _supabase.auth.onAuthStateChange.asyncMap((data) async {
      final user = data.session?.user;
      if (user == null) return null;
      return await getCurrentUser();
    });
  }
}
