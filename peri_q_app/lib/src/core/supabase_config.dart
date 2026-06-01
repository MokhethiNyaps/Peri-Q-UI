class SupabaseConfig {
  const SupabaseConfig._({
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

  static SupabaseConfig fromEnvironment() {
    const url = String.fromEnvironment('SUPABASE_URL');
    const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

    if (url.isEmpty || publishableKey.isEmpty) {
      return const SupabaseConfig.disabled();
    }

    return const SupabaseConfig._(
      url: url,
      publishableKey: publishableKey,
      isConfigured: true,
    );
  }
}
