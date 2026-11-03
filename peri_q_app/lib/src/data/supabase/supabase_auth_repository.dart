import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/auth_deep_links.dart';
import '../../core/policy_version.dart';
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
      // The database records the policy acceptance from this metadata,
      // because an email sign-up has no session until it is confirmed.
      data: {
        'full_name': name.trim(),
        'phone': phone.trim(),
        'policy_version': policyVersion,
        'policy_client': 'android',
      },
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
    return _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: AuthDeepLinks.resetPasswordUrl,
    );
  }

  @override
  Future<void> updatePassword({required String newPassword}) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('No signed-in account is available.');
    }
    final bucket = _client.storage.from('payment-proofs');
    final orderFolders = await bucket.list(path: user.id);
    final proofPaths = <String>[];
    for (final folder in orderFolders) {
      final files = await bucket.list(path: '${user.id}/${folder.name}');
      proofPaths.addAll(
        files.map((file) => '${user.id}/${folder.name}/${file.name}'),
      );
    }
    if (proofPaths.isNotEmpty) {
      await bucket.remove(proofPaths);
    }
    await _client.rpc('delete_own_account');
    await _client.auth.signOut(scope: SignOutScope.local);
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
