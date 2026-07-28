import 'dart:convert';

class SupabaseConfig {
  SupabaseConfig._({
    required this.url,
    required this.publishableKey,
    required this.isConfigured,
  });

  const SupabaseConfig.disabled()
    : url = '',
      publishableKey = '',
      isConfigured = false;

  final String url;
  final String publishableKey;
  final bool isConfigured;

  static SupabaseConfig fromSources([Map<String, String>? environment]) {
    const dartDefineUrl = String.fromEnvironment('SUPABASE_URL');
    const dartDefinePublishableKey = String.fromEnvironment(
      'SUPABASE_PUBLISHABLE_KEY',
    );
    const dartDefineAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    final url = _firstNonEmpty([environment?['SUPABASE_URL'], dartDefineUrl]);
    final publishableKey = _firstNonEmpty([
      environment?['SUPABASE_PUBLISHABLE_KEY'],
      environment?['SUPABASE_ANON_KEY'],
      dartDefinePublishableKey,
      dartDefineAnonKey,
    ]);

    if (!_isSecureUrl(url) || !_isSafePublishableKey(publishableKey)) {
      return const SupabaseConfig.disabled();
    }

    return SupabaseConfig._(
      url: url,
      publishableKey: publishableKey,
      isConfigured: true,
    );
  }

  static String _firstNonEmpty(List<String?> values) {
    for (final value in values) {
      final trimmed = value?.trim() ?? '';
      if (trimmed.isNotEmpty) {
        return trimmed;
      }
    }

    return '';
  }

  static bool _isSecureUrl(String value) {
    final uri = Uri.tryParse(value);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty;
  }

  static bool _isSafePublishableKey(String value) {
    final key = value.trim();
    if (key.isEmpty || key.startsWith('sb_secret_')) {
      return false;
    }
    if (key.startsWith('sb_publishable_')) {
      return true;
    }

    final segments = key.split('.');
    if (segments.length != 3) {
      return true;
    }

    try {
      final payload = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(segments[1]))),
      );
      return payload is! Map<String, dynamic> ||
          payload['role']?.toString() != 'service_role';
    } catch (_) {
      return false;
    }
  }
}
