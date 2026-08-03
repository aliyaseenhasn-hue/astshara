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
      // 1. جلب بيانات البروفايل الأساسية
      // نستخدم id لأن سياسة RLS "Self Manage" تتحقق من auth.uid() = id
      final profileResponse = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profileResponse == null) {
        debugPrint('Profile not found in database for user_id: ${user.id}');
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

      final dynamic roleValue = profileResponse['role'];
      final String roleStr =
          (roleValue is String) ? roleValue : (roleValue?.toString() ?? 'user');

      if (roleStr == 'lawyer') {
        final lawyerResponse = await _supabase
            .from('lawyer_profiles')
            .select('verified')
            .eq('profile_id', user.id)
            .maybeSingle();

        if (lawyerResponse != null) {
          isVerified = (lawyerResponse['verified'] == true);
          hasProfessionalProfile = true;
        }
      }

      final appUser = AppUserModel.fromJson(profileResponse).toEntity();
      debugPrint(
          'DB Profile: ${profileResponse['full_name']}, Onboarding: ${profileResponse['onboarding_completed']}');

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
    // التأكد من تنسيق الرقم العراقي
    String formattedPhone = phone.trim().replaceAll(' ', '');
    if (!formattedPhone.startsWith('+')) {
      formattedPhone = '+$formattedPhone';
    }
    await _supabase.auth.signInWithOtp(phone: formattedPhone);
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

    // إضافة البيانات فقط إذا كانت غير فارغة
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

    // ملاحظة: لا نرسل phone هنا لأن Supabase Auth يديره تلقائياً
    // وإرساله قد يسبب تعارضاً مع قيد UNIQUE في جدول profiles

    // تأكد أن هناك بيانات للتحديث
    if (data.isEmpty) {
      debugPrint('⚠️ لا توجد بيانات للتحديث');
      return;
    }

    debugPrint('📝 بيانات التحديث: $data');
    debugPrint('🔑 المعرف: ${user.id}');

    try {
      // السجل موجود بفضل الـ Trigger handle_new_user - نستخدم update مباشرة
      // نستخدم id لأن سياسة RLS "Self Manage" تتحقق من auth.uid() = id
      await _supabase
          .from('profiles')
          .update({
            ...data,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', user.id)
          .then((value) {
            debugPrint('✅ تم تحديث الملف الشخصي بنجاح');
          });

      // بثّ الحالة المحدثة للمستخدم
      await refreshUser();
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الملف: $e');
      rethrow;
    }
  }

  // بثّ حالة المستخدم المحدثة بعد تعديل البروفايل
  Future<void> refreshUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    _userStateController.add(await getCurrentUser());
  }

  @override
  Future<void> deleteAccount() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    // حذف سجل البروفايل (سيقوم الـ CASCADE بحذف البيانات المرتبطة)
    // نستخدم id لأن سياسة RLS "Self Manage" تتحقق من auth.uid() = id
    await _supabase.from('profiles').delete().eq('id', user.id);

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
    return _userStateController.stream;
  }
}
