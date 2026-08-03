import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:astshara/core/config/supabase_config.dart';
import '../../../../shared/providers/global_loading_provider.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  return AuthRepositoryImpl(SupabaseConfig.client);
}

@riverpod
Stream<AppUser?> authStateChanges(AuthStateChangesRef ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
}

@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {}

  Future<void> signIn(String email, String password) async {
    ref.read(globalLoadingProvider.notifier).setLoading(true);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signInWithEmail(email: email, password: password),
    );
    ref.read(globalLoadingProvider.notifier).setLoading(false);
  }

  Future<void> signUp(
      String email, String password, String fullName, String role) async {
    ref.read(globalLoadingProvider.notifier).setLoading(true);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signUpWithEmail(
            email: email,
            password: password,
            fullName: fullName,
            role: role,
          ),
    );
    ref.read(globalLoadingProvider.notifier).setLoading(false);
  }

  Future<void> logout() async {
    ref.read(globalLoadingProvider.notifier).setLoading(true);
    await ref.read(authRepositoryProvider).signOut();
    ref.read(globalLoadingProvider.notifier).setLoading(false);
  }

  Future<void> deleteAccount() async {
    ref.read(globalLoadingProvider.notifier).setLoading(true);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).deleteAccount(),
    );
    ref.read(globalLoadingProvider.notifier).setLoading(false);
  }

  Future<void> signInWithPhone(String phone) async {
    ref.read(globalLoadingProvider.notifier).setLoading(true);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithPhone(phone),
    );
    ref.read(globalLoadingProvider.notifier).setLoading(false);
  }

  Future<void> signInWithGoogle() async {
    ref.read(globalLoadingProvider.notifier).setLoading(true);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithGoogle(),
    );
    ref.read(globalLoadingProvider.notifier).setLoading(false);
  }

  Future<void> verifyOTP(String phone, String token) async {
    ref.read(globalLoadingProvider.notifier).setLoading(true);
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .verifyOTP(phone: phone, token: token),
    );
    ref.read(globalLoadingProvider.notifier).setLoading(false);
  }

  Future<void> updateInitialProfile({
    required String fullName,
    String? email,
    required String role,
    bool onboardingCompleted = true,
  }) async {
    ref.read(globalLoadingProvider.notifier).setLoading(true);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).updateProfile(
            fullName: fullName,
            email: email,
            role: role,
            onboardingCompleted: onboardingCompleted,
          );
      // إعادة تحميل حالة المستخدم بعد التحديث
      ref.invalidate(authStateChangesProvider);
    });
    ref.read(globalLoadingProvider.notifier).setLoading(false);
  }
}
