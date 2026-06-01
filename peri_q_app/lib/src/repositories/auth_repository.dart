import '../models/app_auth_session.dart';

abstract class AuthRepository {
  bool get usesAuthoritativeSessions;

  Future<AppAuthSession> restoreSession();

  Future<AppAuthSession> signInAnonymously();

  Future<AppAuthSession> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> upsertProfile({
    required String name,
    required String phone,
  });
}
