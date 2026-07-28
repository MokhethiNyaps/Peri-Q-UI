import 'package:flutter_test/flutter_test.dart';
import 'package:peri_q_app/src/core/supabase_config.dart';

void main() {
  group('SupabaseConfig', () {
    test('accepts an HTTPS project URL and publishable key', () {
      final config = SupabaseConfig.fromSources({
        'SUPABASE_URL': 'https://project.supabase.co',
        'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_example',
      });

      expect(config.isConfigured, isTrue);
    });

    test('rejects cleartext project URLs', () {
      final config = SupabaseConfig.fromSources({
        'SUPABASE_URL': 'http://project.supabase.co',
        'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_example',
      });

      expect(config.isConfigured, isFalse);
    });

    test('rejects new-format secret keys', () {
      final config = SupabaseConfig.fromSources({
        'SUPABASE_URL': 'https://project.supabase.co',
        'SUPABASE_PUBLISHABLE_KEY': 'sb_secret_example',
      });

      expect(config.isConfigured, isFalse);
    });

    test('rejects legacy service-role JWTs', () {
      final config = SupabaseConfig.fromSources({
        'SUPABASE_URL': 'https://project.supabase.co',
        'SUPABASE_ANON_KEY': 'e30.eyJyb2xlIjoic2VydmljZV9yb2xlIn0.signature',
      });

      expect(config.isConfigured, isFalse);
    });

    test('accepts legacy anonymous JWTs', () {
      final config = SupabaseConfig.fromSources({
        'SUPABASE_URL': 'https://project.supabase.co',
        'SUPABASE_ANON_KEY': 'e30.eyJyb2xlIjoiYW5vbiJ9.signature',
      });

      expect(config.isConfigured, isTrue);
    });
  });
}
