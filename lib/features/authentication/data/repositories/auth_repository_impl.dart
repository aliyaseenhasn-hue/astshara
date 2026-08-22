import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:web/web.dart' as web;
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../models/app_user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final SupabaseClient _supabase;
  final _userStateController = StreamController<AppUser?>.broadcast();
  bool _isListening = false;
  Future<AppUser?>? _currentUserFuture;

  AuthRepositoryImpl(this._supabase) { _setupAuthListener(); }

  void _setupAuthListener() {
    if (_isListening) return;
    _isListening = true;
    _supabase.auth.onAuthStateChange.listen((data) async {
      final user = data.session?.user;
      if (user == null) {
        _userStateController.add(null);
      } else {
        _clearWebOAuthCallbackUrl();
        _userStateController.add(await getCurrentUser());
      }
    });
  }

  void _clearWebOAuthCallbackUrl() {
    if (!kIsWeb) return;
    final uri = Uri.base;
    final hasOAuthParams = uri.queryParameters.containsKey('code') ||
        uri.queryParameters.containsKey('error') ||
        uri.queryParameters.containsKey('error_code') ||
        uri.fragment.contains('access_token=') ||
        uri.fragment.contains('error=');
    if (!hasOAuthParams) return;
    final cleanUri = uri.replace(query: '', fragment: '');
    web.window.history.replaceState(null, '', cleanUri.toString());
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    if (_currentUserFuture != null) return _currentUserFuture;
    _currentUserFuture = _getCurrentUserInternal();
    try { return await _currentUserFuture; } finally { _currentUserFuture = null; }
  }

  Future<AppUser?> _getCurrentUserInternal() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    try {
      final profileResponse = await _supabase.from('profiles').select().eq('auth_id', user.id).maybeSingle();
      if (profileResponse == null) return AppUser(id: user.id, email: user.email, fullName: user.userMetadata?['full_name'] as String?, phone: user.phone, role: 'user', isOnboardingComplete: false);
      bool isVerified = false;
      bool hasProfessionalProfile = false;
      final roleValue = profileResponse['role'];
      final roleStr = roleValue is String ? roleValue : (roleValue?.toString() ?? 'user');
      if (roleStr == 'lawyer') {
        final profileId = profileResponse['id'] as String;
        final lawyerResponse = await _supabase.from('lawyer_profiles').select('verified').eq('profile_id', profileId).maybeSingle();
        if (lawyerResponse != null) { isVerified = lawyerResponse['verified'] == true; hasProfessionalProfile = true; }
      }
      final appUser = AppUserModel.fromJson(profileResponse).toEntity();
      return appUser.copyWith(isVerified: isVerified, hasProfessionalProfile: hasProfessionalProfile, isOnboardingComplete: profileResponse['onboarding_completed'] == true);
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      return AppUser(id: user.id, email: user.email, phone: user.phone, fullName: user.userMetadata?['full_name'] as String?, role: (user.userMetadata?['role'] as String?) ?? 'user');
    }
  }

  @override
  Future<void> signInWithEmail({required String email, required String password}) async => _supabase.auth.signInWithPassword(email: email, password: password);
  @override
  Future<void> signUpWithEmail({required String email, required String password, required String fullName, required String role}) async { final safeRole = role == 'lawyer' ? 'lawyer' : 'user'; await _supabase.auth.signUp(email: email, password: password, data: {'full_name': fullName, 'role': safeRole}); }
  @override
  Future<void> signOut() async => _supabase.auth.signOut();
  @override
  Future<void> signInWithPhone(String phone) async { var formattedPhone = phone.trim().replaceAll(' ', ''); if (!formattedPhone.startsWith('+')) formattedPhone = '+$formattedPhone'; await _supabase.auth.signInWithOtp(phone: formattedPhone); }
  @override
  Future<void> signInWithGoogle() async {
    const redirectUrl = 'https://aliyaseenhasn-hue.github.io/istishara-platform/';
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: redirectUrl,
      queryParams: {'prompt': 'select_account'},
    );
  }
  @override
  Future<void> signInWithTelegram() async => throw UnsupportedError('استخدم تسجيل Telegram عبر رمز التحقق داخل التطبيق');

  @override
  Future<Map<String, dynamic>> startTelegramLogin(String phone, {bool registration = false}) async {
    final result = await _supabase.functions.invoke('telegram-auth-v2', body: {'action': 'start', 'phone': phone, 'mode': registration ? 'signup' : 'login'});
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
    if (syntheticEmail is String && syntheticEmail.isNotEmpty && password is String && password.isNotEmpty) { await signInWithEmail(email: syntheticEmail, password: password); return data; }
    throw Exception('تم التحقق من Telegram لكن تعذر إنشاء جلسة الدخول');
  }

  @override
  Future<void> verifyOTP({required String phone, required String token}) async => _supabase.auth.verifyOTP(phone: phone, token: token, type: OtpType.sms);
  @override
  Future<void> updateProfile({String? fullName, String? email, String? role, String? avatarUrl, bool? onboardingCompleted, String? walletNumber}) async { final user = _supabase.auth.currentUser; if (user == null) throw Exception('❌ لا يوجد مستخدم مسجل دخول'); final data = <String, dynamic>{}; if (fullName != null && fullName.trim().isNotEmpty) data['full_name'] = fullName.trim(); if (email != null && email.trim().isNotEmpty) data['email'] = email.trim(); if (role != null && (role == 'lawyer' || role == 'user')) data['role'] = role; if (avatarUrl != null && avatarUrl.trim().isNotEmpty) data['avatar_url'] = avatarUrl.trim(); if (onboardingCompleted != null) data['onboarding_completed'] = onboardingCompleted; if (walletNumber != null) data['wallet_number'] = walletNumber.trim(); if (data.isEmpty) return; await _supabase.from('profiles').upsert({...data, 'auth_id': user.id, 'id': user.id, 'updated_at': DateTime.now().toIso8601String()}, onConflict: 'auth_id'); await refreshUser(); }
  @override
  Future<void> refreshUser() async { if (_supabase.auth.currentUser != null) _userStateController.add(await getCurrentUser()); }
  @override
  Future<void> deleteAccount() async { final user = _supabase.auth.currentUser; if (user == null) return; await _supabase.from('profiles').delete().eq('auth_id', user.id); try { await _supabase.rpc('delete_user_account'); } catch (e) { debugPrint('RPC delete failed: $e'); } await signOut(); }
  @override
  Stream<AppUser?> authStateChanges() => _userStateController.stream;
}
