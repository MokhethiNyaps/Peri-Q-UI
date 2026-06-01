import '../../models/app_auth_session.dart';
import '../../repositories/auth_repository.dart';

class MockAuthRepository implements AuthRepository {
  AppAuthSession _session = const AppAuthSession.signedOut();

  @override
  bool get usesAuthoritativeSessions => false;

  @override
  Future<AppAuthSession> restoreSession() async {
    return _session;
  }

  @override
  Future<AppAuthSession> signInAnonymously() async {
    _session = const AppAuthSession(
      hasSession: true,
      userId: 'local-anonymous-user',
      isAnonymous: true,
      isAdmin: false,
    );
    return _session;
  }

  @override
  Future<AppAuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    _session = AppAuthSession(
      hasSession: true,
      userId: normalizedEmail.isEmpty ? 'local-user' : normalizedEmail,
      email: normalizedEmail,
      isAnonymous: false,
      isAdmin:
          normalizedEmail.contains('admin') ||
          normalizedEmail.endsWith('@periq.co.za'),
    );
    return _session;
  }

  @override
  Future<void> signOut() async {
    _session = const AppAuthSession.signedOut();
  }

  @override
  Future<void> upsertProfile({
    required String name,
    required String phone,
  }) async {
    if (!_session.hasSession) {
      return;
    }

    _session = _session.copyWith(
      customerName: name,
      customerPhone: phone,
    );
  }
}
