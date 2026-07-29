import '../models/app_auth_session.dart';

abstract class AuthRepository {
  Future<AppAuthSession> restoreSession();

  Future<AppAuthSession> signInAnonymously();

  Future<void> upsertProfile({required String name, required String phone});
}
