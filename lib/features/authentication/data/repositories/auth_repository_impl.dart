import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/app_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabase;
  final _userStateController = StreamController<AppUser?>.broadcast();
  bool _isListening = false;

  AuthRepositoryImpl(this._supabase) {
    _setupAuthListener();
  }

  void _setupAuthListener() {
    if (_isListening) return;
    _isListening = true;

    _supabase.auth.onAuthStateChange.listen((data) async {
      final user = data.session?.user;
      if (user == null) {
        _userStateController.add(null);
      } else {
        _userStateController.add(await getCurrentUser());
      }
    });
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final profileResponse = await _supabase
          .from('profiles')
          .select()
          .eq('auth_id', user.id)
          .maybeSingle();

      if (profileResponse == null) {
        debugPrint('Profile not found in database for user_id: ${user.id}');
        return AppUser(
          id: user.id,
          email: user.email,
          fullName: user.userMetadata?['full_name'] as String?,
          phone: user.phone,
          role: 'user',
          isOnboardingComplete: false,
        );
      }

      bool isVerified = false;
      bool hasProfessionalProfile = false;

      final dynamic roleValue = profileResponse['role'];
      final String roleStr =
          (roleValue is String) ? roleValue : (roleValue?.toString() ?? 'user');

      if (roleStr == 'lawyer') {
        final profileId = profileResponse['id'] as String;
        final lawyerResponse = await _supabase
            .from('lawyer_profiles')
            .select('verified')
            .eq('profile_id', profileId)
            .maybeSingle();

        if (lawyerResponse != null) {
          isVerified = (lawyerResponse['verified'] == true);
          hasProfessionalProfile = true;
        }
      }

      final appUser = AppUserModel.fromJson(profileResponse).toEntity();
      final bool isOnboarded = profileResponse['onboarding_completed'] == true;

      return appUser.copyWith(
        isVerified: isVerified,
        hasProfessionalProfile: hasProfessionalProfile,
        isOnboardingComplete: isOnboarded,
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
    String formattedPhone = phone.trim().replaceAll(' ', '');
    if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+$formattedPhone';
    }
    await _supabase.auth.signInWithOtp(phone: formattedPhone);
  }

  @override
  Future<void> signInWithGoogle() async {
    try {
      const String redirectUrl = kIsWeb
          ? 'https://aliyaseenhasn-hue.github.io/astshara/'
          : 'io.supabase.astshara://login-callback';

      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: redirectUrl,
        queryParams: {
          'prompt': 'select_account',
        },
      );
    } on AuthException catch (e) {
      debugPrint('Google OAuth AuthException: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Unexpected Google OAuth error: $e');
      rethrow;
    }
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
  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? role,
    String? avatarUrl,
    bool? onboardingCompleted,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('❌ لا يوجد مستخدم مسجل دخول');
    }

    final data = <String, dynamic>{};
    if (fullName != null && fullName.trim().isNotEmpty) {
      data['full_name'] = fullName.trim();
    }
    if (email != null && email.trim().isNotEmpty) {
      data['email'] = email.trim();
    }
    if (role != null && role.trim().isNotEmpty) {
      data['role'] = role.trim();
    }
    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      data['avatar_url'] = avatarUrl.trim();
    }
    if (onboardingCompleted != null) {
      data['onboarding_completed'] = onboardingCompleted;
    }

    if (data.isEmpty) return;

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
      debugPrint('RPC delete failed: $e');
    }
    await signOut();
  }

  @override
  Stream<AppUser?> authStateChanges() {
    return _userStateController.stream;
  }
}
