import 'package:flutter_test/flutter_test.dart';
import 'package:peri_q_app/src/core/payment_config.dart';

void main() {
  test('retains the existing production checkout endpoint by default', () {
    expect(
      cardCheckoutUri()?.toString(),
      'https://rastasperiq.co.za/api/yoco/checkout/',
    );
  });
  test('accepts a public HTTPS staging checkout endpoint', () {
    expect(
      cardCheckoutUri(
        override: 'https://staging.example.com/api/yoco/checkout/',
      )?.host,
      'staging.example.com',
    );
  });
  for (final invalid in [
    'http://staging.example.com/api/yoco/checkout/',
    'https://user:password@example.com/checkout',
    'https://example.com/checkout?secret=value',
    'https://example.com/checkout#fragment',
    'not a URL',
  ]) {
    test('rejects unsafe checkout configuration: $invalid', () {
      expect(cardCheckoutUri(override: invalid), isNull);
    });
  }
}
