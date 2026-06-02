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
    const dartDefinePublishableKey =
        String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    const dartDefineAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    final url = _firstNonEmpty([
      environment?['SUPABASE_URL'],
      dartDefineUrl,
    ]);
    final publishableKey = _firstNonEmpty([
      environment?['SUPABASE_PUBLISHABLE_KEY'],
      environment?['SUPABASE_ANON_KEY'],
      dartDefinePublishableKey,
      dartDefineAnonKey,
    ]);

    if (url.isEmpty || publishableKey.isEmpty) {
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
}
