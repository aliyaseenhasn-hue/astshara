import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:astshara/core/config/supabase_config.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/app_user.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_provider.g.dart';

@riverpod
AuthRepository authRepository(AuthRepositoryRef ref) {
  // للاتصال بـ Supabase الحقيقي، اجعل هذه القيمة false
  const bool useMock = false;
  if (useMock) {
    return MockAuthRepository.instance;
  }
  return AuthRepositoryImpl(SupabaseConfig.client);
}

class MockAuthRepository implements AuthRepository {
  static final MockAuthRepository instance = MockAuthRepository._();
  final _authStateController = StreamController<AppUser?>.broadcast();
  AppUser? _currentUser;

  MockAuthRepository._() {
    _authStateController.add(null);
  }

  @override
  Future<AppUser?> getCurrentUser() async => _currentUser;

  @override
  Future<void> signInWithEmail(
      {required String email, required String password}) async {}

  @override
  Future<void> signUpWithEmail(
      {required String email,
      required String password,
      required String fullName,
      required String role}) async {}

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _authStateController.add(null);
  }

  @override
  Future<void> signInWithPhone(String phone) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> signInWithGoogle() async {
    await Future.delayed(const Duration(seconds: 1));
  }

  @override
  Future<void> verifyOTP({required String phone, required String token}) async {
    await Future.delayed(const Duration(seconds: 1));

    // للتجربة المحلية:
    // إذا كان رقم الهاتف ينتهي بـ 000، سيعتبره النظام أدمن
    final bool isAdmin = phone.endsWith('000');

    _currentUser = AppUser(
      id: isAdmin ? 'admin_id' : 'user_id',
      email: isAdmin ? 'admin@astshara.com' : 'user@test.com',
      fullName: isAdmin ? 'مدير النظام' : 'مستخدم تجريبي',
      role: isAdmin ? 'admin' : 'user',
    );
    _authStateController.add(_currentUser);
  }

  @override
  Future<void> updateProfile(
      {String? fullName, String? email, String? role}) async {}

  @override
  Stream<AppUser?> authStateChanges() => _authStateController.stream;
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
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .signInWithEmail(email: email, password: password),
    );
  }

  Future<void> signUp(
      String email, String password, String fullName, String role) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signUpWithEmail(
            email: email,
            password: password,
            fullName: fullName,
            role: role,
          ),
    );
  }

  Future<void> logout() async {
    await ref.read(authRepositoryProvider).signOut();
  }

  Future<void> signInWithPhone(String phone) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithPhone(phone),
    );
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(authRepositoryProvider).signInWithGoogle(),
    );
  }

  Future<void> verifyOTP(String phone, String token) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref
          .read(authRepositoryProvider)
          .verifyOTP(phone: phone, token: token),
    );
  }

  Future<void> updateInitialProfile({
    required String fullName,
    String? email,
    required String role,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(authRepositoryProvider).updateProfile(
            fullName: fullName,
            email: email,
            role: role,
          );
    });
  }
}
