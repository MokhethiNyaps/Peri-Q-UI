import 'package:flutter_test/flutter_test.dart';
import 'package:peri_q_app/src/core/payment_session.dart';

void main() {
  final session = CardPaymentSession.instance;

  tearDown(session.finish);

  group('Payment return links', () {
    test('reads success, cancel and failure returns for an order', () {
      final success = CardPaymentSession.parseReturnLink(
        Uri.parse('rastasperiq://payment-return?order=abc&result=success'),
      );
      expect(success?.orderId, 'abc');
      expect(success?.result, PaymentReturnResult.success);
      expect(
        CardPaymentSession.parseReturnLink(
          Uri.parse('rastasperiq://payment-return?order=abc&result=cancel'),
        )?.result,
        PaymentReturnResult.cancelled,
      );
      expect(
        CardPaymentSession.parseReturnLink(
          Uri.parse('rastasperiq://payment-return?order=abc&result=failure'),
        )?.result,
        PaymentReturnResult.failed,
      );
    });

    test('ignores other links and incomplete returns', () {
      for (final link in [
        'rastasperiq://reset-password?code=abc',
        'https://rastasperiq.co.za/payment-return?order=abc&result=success',
        'rastasperiq://payment-return?result=success',
        'rastasperiq://payment-return?order=abc&result=paid',
      ]) {
        expect(
          CardPaymentSession.parseReturnLink(Uri.parse(link)),
          isNull,
          reason: link,
        );
      }
    });
  });

  group('Payment session', () {
    test('passes returns only for the payment that is running', () async {
      final received = <PaymentReturn>[];
      final subscription = session.returns.listen(received.add);
      session.opened(
        orderId: 'current',
        checkoutUrl: Uri.parse('https://pay.example/checkout/1'),
      );
      expect(session.stage.value, CardPaymentStage.awaitingCustomer);

      session.report(
        const PaymentReturn(
          orderId: 'old-order',
          result: PaymentReturnResult.success,
        ),
      );
      session.abandon();
      await Future<void>.delayed(Duration.zero);

      expect(received, hasLength(1));
      expect(received.single.orderId, 'current');
      expect(received.single.result, PaymentReturnResult.abandoned);
      await subscription.cancel();
    });

    test('finishing clears the running payment', () {
      session.opened(
        orderId: 'current',
        checkoutUrl: Uri.parse('https://pay.example/checkout/1'),
      );
      session.finish();
      expect(session.activeOrderId, isNull);
      expect(session.checkoutUrl, isNull);
      expect(session.stage.value, CardPaymentStage.idle);
    });
  });
}
