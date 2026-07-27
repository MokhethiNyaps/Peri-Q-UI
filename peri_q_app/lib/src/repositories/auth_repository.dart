import '../models/app_auth_session.dart';

abstract class AuthRepository {
  bool get usesAuthoritativeSessions;

  Future<AppAuthSession> restoreSession();

  Future<AppAuthSession> signInAnonymously();

  Future<AppAuthSession> signInWithEmail({
    required String email,
    required String password,
  });

  Future<AppAuthSession> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
  });

  Future<void> resetPasswordForEmail({required String email});

  Future<void> updatePassword({required String newPassword});

  Future<void> signOut();

  Future<void> deleteAccount() =>
      throw UnsupportedError('Account deletion is not configured.');

  Future<void> upsertProfile({required String name, required String phone});
}
