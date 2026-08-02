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
      // 1. جلب بيانات البروفايل الأساسية
      final profileResponse = await _supabase
          .from('profiles')
          .select()
          .eq('auth_id', user.id)
          .maybeSingle();

      if (profileResponse == null) {
        debugPrint('Profile not found in database for auth_id: ${user.id}');
        return AppUser(
          id: user.id,
          email: user.email,
          fullName: null,
          phone: user.phone,
          role: 'user',
        );
      }

      // 2. التحقق من حالة التوثيق في جدول lawyer_profiles إذا كان المستخدم محامياً
      bool isVerified = false;
      bool hasProfessionalProfile = false;
      if (profileResponse['role'] == 'lawyer') {
        final lawyerResponse = await _supabase
            .from('lawyer_profiles')
            .select('verified')
            .eq('profile_id', user.id)
            .maybeSingle();

        if (lawyerResponse != null) {
          isVerified = lawyerResponse['verified'] ?? false;
          hasProfessionalProfile = true;
        }
      }

      final appUser = AppUserModel.fromJson(profileResponse).toEntity();
      return appUser.copyWith(
        isVerified: isVerified,
        hasProfessionalProfile: hasProfessionalProfile,
      );
    } catch (e) {
      debugPrint('Error fetching user profile from DB: $e');
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
      redirectTo: 'https://aliyaseenhasn-hue.github.io/astshara/',
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
  Future<void> deleteAccount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // حذف سجل البروفايل (سيقوم الـ CASCADE بحذف البيانات المرتبطة)
    await _supabase.from('profiles').delete().eq('auth_id', user.id);

    // استدعاء دالة RPC لحذف المستخدم من سجلات المصادقة نهائياً
    try {
      await _supabase.rpc('delete_user_account');
    } catch (e) {
      debugPrint('RPC delete failed: $e');
    }

    await signOut();
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
