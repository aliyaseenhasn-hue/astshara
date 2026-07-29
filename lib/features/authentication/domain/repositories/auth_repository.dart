import '../entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser?> getCurrentUser();
  Future<void> signInWithEmail(
      {required String email, required String password});
  Future<void> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required String role,
  });
  Future<void> signOut();
  Future<void> signInWithPhone(String phone);
  Future<void> verifyOTP({required String phone, required String token});
  Future<void> updateProfile({String? fullName, String? email, String? role});
  Stream<AppUser?> authStateChanges();
}
