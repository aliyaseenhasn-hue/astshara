import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../core/config/supabase_config.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabase;
  final _userStateController = StreamController<AppUser?>.broadcast();
  late final StreamSubscription<AuthState> _authSubscription;

  AuthRepositoryImpl([SupabaseClient? client]) : _supabase = client ?? SupabaseConfig.client {
    _authSubscription = _supabase.auth.onAuthStateChange.listen((data) async {
      try {
        final sessionUser = data.session?.user;
        if (sessionUser == null) {
          _userStateController.add(null);
          return;
        }
        final profile = await _supabase.from('profiles').select().eq('auth_id', sessionUser.id).maybeSingle();
        final lawyerProfile = profile?['role']?.toString() == 'lawyer'
            ? await _supabase.from('lawyer_profiles').select('verified').eq('profile_id', profile?['id']).maybeSingle()
            : null;
        _userStateController.add(_toAppUser(sessionUser, profile, lawyerProfile));
      } catch (e) {
        debugPrint('Auth state profile sync failed: $e');
      }
    });
    Future.microtask(refreshUser);
  }

  AppUser _toAppUser(User user, Map<String, dynamic>? profile, [Map<String, dynamic>? lawyerProfile]) {
    final lawyerVerified = profile?['role']?.toString() == 'lawyer' && lawyerProfile?['verified'] == true;
    return AppUser(
      id: user.id,
      email: profile?['email']?.toString() ?? user.email,
      fullName: profile?['full_name']?.toString() ?? user.userMetadata?['full_name']?.toString(),
      phone: profile?['phone']?.toString() ?? user.phone,
      avatarUrl: profile?['avatar_url']?.toString(),
      role: profile?['role']?.toString() ?? user.userMetadata?['role']?.toString() ?? 'user',
      isVerified: lawyerVerified || profile?['is_verified'] == true,
      hasProfessionalProfile: profile?['has_professional_profile'] == true,
      isOnboardingComplete: profile?['onboarding_completed'] == true,
      walletNumber: profile?['wallet_number']?.toString(),
    );
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    final profile = await _supabase.from('profiles').select().eq('auth_id', user.id).maybeSingle();
    final lawyerProfile = profile?['role']?.toString() == 'lawyer'
        ? await _supabase.from('lawyer_profiles').select('verified').eq('profile_id', profile?['id']).maybeSingle()
        : null;
    return _toAppUser(user, profile, lawyerProfile);
  }

  @override
  Future<void> signInWithEmail({required String email, required String password}) async => _supabase.auth.signInWithPassword(email: email, password: password);

  @override
  Future<void> signUpWithEmail({required String email, required String password, required String fullName, required String role}) async {
    final response = await _supabase.auth.signUp(email: email, password: password, data: {'full_name': fullName, 'role': role});
    if (response.user == null) throw Exception('تعذر إنشاء الحساب');
    await updateProfile(fullName: fullName, role: role);
  }

  @override Future<void> signOut() async => _supabase.auth.signOut();
  @override Future<void> signInWithPhone(String phone) async => _supabase.auth.signInWithOtp(phone: phone);

  @override
  Future<void> signInWithGoogle() async {
    final redirectUrl = kIsWeb
        ? Uri.parse('${Uri.base.origin}${Uri.base.path.startsWith('/istishara-platform') ? '/istishara-platform/' : '/'}')
        : Uri.parse('io.supabase.astshara://login-callback/');
    await _supabase.auth.signInWithOAuth(OAuthProvider.google, redirectTo: redirectUrl.toString(), queryParams: {'prompt': 'select_account'});
  }

  @override Future<void> signInWithTelegram() async => throw UnsupportedError('استخدم تسجيل Telegram عبر رمز التحقق داخل التطبيق');

  @override
  Future<Map<String, dynamic>> startTelegramLogin(String phone, {bool registration = false, String? fullName, String? role}) async {
    final body = <String, dynamic>{'action': 'start', 'phone': phone, 'mode': registration ? 'signup' : 'login'};
    if (fullName != null && fullName.trim().isNotEmpty) body['full_name'] = fullName.trim();
    if (role != null && role.trim().isNotEmpty) body['role'] = role.trim();
    final result = await _supabase.functions.invoke('telegram-auth-v2', body: body);
    if (result.data is! Map) throw Exception('تعذر بدء تسجيل Telegram');
    final data = Map<String, dynamic>.from(result.data as Map);
    if (data['ok'] != true) throw Exception(data['error'] ?? 'تعذر بدء تسجيل Telegram');
    return data;
  }

  @override
  Future<Map<String, dynamic>> verifyTelegramLogin({required String requestToken, required String code}) async {
    final result = await _supabase.functions.invoke('telegram-auth-v2', body: {'action': 'verify', 'request_token': requestToken, 'code': code});
    if (result.data is! Map) throw Exception('تعذر التحقق من الرمز');
    final data = Map<String, dynamic>.from(result.data as Map);
    if (data['ok'] != true) throw Exception(data['error'] ?? 'رمز التحقق غير صحيح');
    final accessToken = data['access_token'];
    final refreshToken = data['refresh_token'];
    if (accessToken is String && accessToken.isNotEmpty && refreshToken is String && refreshToken.isNotEmpty) {
      await _supabase.auth.setSession(refreshToken);
      final current = _supabase.auth.currentSession;
      if (current == null || current.accessToken != accessToken) await _supabase.auth.refreshSession();
      await refreshUser();
      return data;
    }
    final syntheticEmail = data['syntheticEmail'];
    final password = data['password'];
    if (syntheticEmail is String && syntheticEmail.isNotEmpty && password is String && password.isNotEmpty) {
      await signInWithEmail(email: syntheticEmail, password: password);
      return data;
    }
    throw Exception('تم التحقق من Telegram لكن تعذر إنشاء جلسة الدخول');
  }

  @override Future<void> verifyOTP({required String phone, required String token}) async => _supabase.auth.verifyOTP(phone: phone, token: token, type: OtpType.sms);

  @override
  Future<void> updateProfile({String? fullName, String? email, String? role, String? avatarUrl, bool? onboardingCompleted, String? walletNumber}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw Exception('لا يوجد مستخدم مسجل دخول');
    final data = <String, dynamic>{};
    if (fullName != null && fullName.trim().isNotEmpty) data['full_name'] = fullName.trim();
    if (email != null && email.trim().isNotEmpty) data['email'] = email.trim();
    if (role != null && (role == 'lawyer' || role == 'user')) data['role'] = role;
    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) data['avatar_url'] = avatarUrl.trim();
    if (onboardingCompleted != null) data['onboarding_completed'] = onboardingCompleted;
    if (walletNumber != null) data['wallet_number'] = walletNumber.trim();
    if (data.isEmpty) return;
    await _supabase.from('profiles').upsert({...data, 'auth_id': user.id, 'id': user.id, 'updated_at': DateTime.now().toIso8601String()}, onConflict: 'auth_id');
    await refreshUser();
  }

  @override
  Future<void> refreshUser() async {
    final current = await getCurrentUser();
    _userStateController.add(current);
  }

  @override
  Future<void> deleteAccount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    await _supabase.from('profiles').delete().eq('auth_id', user.id);
    try { await _supabase.rpc('delete_user_account'); } catch (e) { debugPrint('RPC delete failed: $e'); }
    await signOut();
  }

  @override Stream<AppUser?> authStateChanges() => _userStateController.stream;

  void dispose() {
    _authSubscription.cancel();
    _userStateController.close();
  }
}
