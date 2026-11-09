import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shows the secure payment page for [orderId] inside the app. Returns false
/// when it cannot, so the caller can fall back to a browser.
typedef PaymentPagePresenter =
    Future<bool> Function(Uri checkoutUrl, String orderId);

/// Where the customer is in a card payment, for the checkout screen.
enum CardPaymentStage {
  /// No payment is running.
  idle,

  /// The order is being prepared and the secure payment page requested.
  preparing,

  /// The secure payment page is open; waiting for the customer to finish.
  awaitingCustomer,

  /// The customer came back from a completed payment; waiting for the
  /// server to confirm it.
  confirming,
}

/// How the customer left the secure payment page.
///
/// This is only a hint about where the customer is. It is never proof of
/// payment: an order is paid only when the database says so, after the
/// payment provider's signed webhook has been verified on the server.
enum PaymentReturnResult { success, cancelled, failed, abandoned }

@immutable
class PaymentReturn {
  const PaymentReturn({required this.orderId, required this.result});

  final String orderId;
  final PaymentReturnResult result;
}

/// Shared state for the one card payment that can run at a time.
///
/// The order repository drives [stage] and listens to [returns]. The app's
/// deep-link handler and the checkout screen report how the customer left
/// the payment page.
class CardPaymentSession {
  CardPaymentSession._();

  static final CardPaymentSession instance = CardPaymentSession._();

  /// `rastasperiq://payment-return?order=<id>&result=<success|cancel|failure>`
  static const String returnHost = 'payment-return';

  final ValueNotifier<CardPaymentStage> stage = ValueNotifier(
    CardPaymentStage.idle,
  );
  final StreamController<PaymentReturn> _returns =
      StreamController<PaymentReturn>.broadcast();

  String? _activeOrderId;
  Uri? _checkoutUrl;

  /// Set by the app so the payment page opens in its own screen instead of
  /// a browser.
  PaymentPagePresenter? presenter;

  Stream<PaymentReturn> get returns => _returns.stream;
  String? get activeOrderId => _activeOrderId;

  /// The secure payment page for the running payment, so it can be reopened.
  Uri? get checkoutUrl => _checkoutUrl;

  void preparing() {
    stage.value = CardPaymentStage.preparing;
  }

  void opened({required String orderId, required Uri checkoutUrl}) {
    _activeOrderId = orderId;
    _checkoutUrl = checkoutUrl;
    stage.value = CardPaymentStage.awaitingCustomer;
  }

  void confirming() {
    stage.value = CardPaymentStage.confirming;
  }

  /// Reports how the customer left the payment page. Ignored unless it is
  /// for the payment that is currently running.
  void report(PaymentReturn paymentReturn) {
    if (paymentReturn.orderId != _activeOrderId) return;
    _returns.add(paymentReturn);
  }

  /// The customer chose to stop waiting in the app.
  void abandon() {
    final orderId = _activeOrderId;
    if (orderId == null) return;
    report(
      PaymentReturn(orderId: orderId, result: PaymentReturnResult.abandoned),
    );
  }

  void finish() {
    _activeOrderId = null;
    _checkoutUrl = null;
    stage.value = CardPaymentStage.idle;
  }

  /// Opens the payment page for the running payment: in the app's own
  /// payment screen when one is set, otherwise in a browser sheet on top of
  /// the app, and as a last resort in the device browser.
  Future<bool> openPaymentPage() async {
    final url = _checkoutUrl;
    final orderId = _activeOrderId;
    if (url == null || orderId == null) return false;
    final present = presenter;
    if (present != null) {
      try {
        if (await present(url, orderId)) return true;
      } catch (_) {
        // Fall through to the browser.
      }
    }
    try {
      if (await launchUrl(url, mode: LaunchMode.inAppBrowserView)) {
        return true;
      }
    } catch (_) {
      // Fall through to the device browser.
    }
    return launchUrl(url, mode: LaunchMode.externalApplication);
  }

  /// Reads where the payment provider sends the customer when they finish:
  /// `https://<site>/payment/<orderId>/?checkout=<success|cancel|failure>`.
  /// Returns null for any other page, including returns for other orders.
  static PaymentReturn? parseHostedReturn(Uri uri, {required String orderId}) {
    if (uri.scheme != 'https') return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.length != 2 ||
        segments[0] != 'payment' ||
        segments[1] != orderId) {
      return null;
    }
    final result = switch (uri.queryParameters['checkout']) {
      'success' => PaymentReturnResult.success,
      'cancel' => PaymentReturnResult.cancelled,
      'failure' => PaymentReturnResult.failed,
      _ => null,
    };
    if (result == null) return null;
    return PaymentReturn(orderId: orderId, result: result);
  }

  /// Reads a payment return link, or returns null for any other link.
  static PaymentReturn? parseReturnLink(Uri uri) {
    if (uri.scheme != 'rastasperiq' || uri.host != returnHost) return null;
    final orderId = uri.queryParameters['order']?.trim() ?? '';
    if (orderId.isEmpty) return null;
    final result = switch (uri.queryParameters['result']) {
      'success' => PaymentReturnResult.success,
      'cancel' => PaymentReturnResult.cancelled,
      'failure' => PaymentReturnResult.failed,
      _ => null,
    };
    if (result == null) return null;
    return PaymentReturn(orderId: orderId, result: result);
  }
}
