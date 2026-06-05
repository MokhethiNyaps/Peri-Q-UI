import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/app_auth_session.dart';
import '../../repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository({required this._client});

  final SupabaseClient _client;

  @override
  bool get usesAuthoritativeSessions => true;

  @override
  Future<AppAuthSession> restoreSession() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      return const AppAuthSession.signedOut();
    }

    return _buildSession(user);
  }

  @override
  Future<AppAuthSession> signInAnonymously() async {
    final response = await _client.auth.signInAnonymously();
    final user = response.user ?? _client.auth.currentUser;
    if (user == null) {
      throw StateError('Supabase did not return a user session.');
    }

    return _buildSession(user);
  }

  @override
  Future<AppAuthSession> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = response.user ?? _client.auth.currentUser;
    if (user == null) {
      throw StateError('Supabase did not return a user session.');
    }

    return _buildSession(user);
  }

  @override
  Future<AppAuthSession> signUpWithEmail({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    final normalizedEmail = email.trim();
    final response = await _client.auth.signUp(
      email: normalizedEmail,
      password: password,
      data: {'full_name': name.trim(), 'phone': phone.trim()},
    );
    final user = response.user ?? _client.auth.currentUser;
    final session = response.session ?? _client.auth.currentSession;

    if (user == null) {
      throw StateError('Supabase did not return a user account.');
    }

    if (session == null) {
      throw StateError(
        'Account created. Check your email to confirm it, then sign in.',
      );
    }

    await upsertProfile(name: name, phone: phone);
    return _buildSession(user);
  }

  @override
  Future<void> resetPasswordForEmail({required String email}) {
    return _client.auth.resetPasswordForEmail(email.trim());
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> upsertProfile({
    required String name,
    required String phone,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in Supabase user is available.');
    }

    await _client.from('profiles').upsert({
      'id': user.id,
      'email': user.email,
      'full_name': name,
      'phone': phone,
    });
  }

  Future<AppAuthSession> _buildSession(User user) async {
    final profile = await _fetchProfile(user.id);
    final role = profile?['role'] as String? ?? 'customer';

    return AppAuthSession(
      hasSession: true,
      userId: user.id,
      email: user.email,
      isAnonymous: user.isAnonymous,
      isAdmin: role == 'admin',
      customerName: profile?['full_name'] as String?,
      customerPhone: profile?['phone'] as String?,
    );
  }

  Future<Map<String, dynamic>?> _fetchProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select('full_name, phone, role')
        .eq('id', userId)
        .maybeSingle();

    return response;
  }
}
