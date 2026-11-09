import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/app_theme.dart';
import '../core/payment_session.dart';

/// The payment provider's secure card page, shown inside the app.
///
/// When the provider finishes and tries to send the customer to the website,
/// this screen stops that page from loading, tells checkout how the payment
/// ended and closes, so the customer goes straight back to the app. That
/// result is only a hint: checkout still waits for the database to confirm
/// the payment.
class SecurePaymentScreen extends StatefulWidget {
  const SecurePaymentScreen({
    super.key,
    required this.checkoutUrl,
    required this.orderId,
  });

  final Uri checkoutUrl;
  final String orderId;

  static Route<void> route({
    required Uri checkoutUrl,
    required String orderId,
  }) {
    return MaterialPageRoute<void>(
      settings: const RouteSettings(name: '/secure-payment'),
      fullscreenDialog: true,
      builder: (_) =>
          SecurePaymentScreen(checkoutUrl: checkoutUrl, orderId: orderId),
    );
  }

  @override
  State<SecurePaymentScreen> createState() => _SecurePaymentScreenState();
}

class _SecurePaymentScreenState extends State<SecurePaymentScreen> {
  final _session = CardPaymentSession.instance;
  late final WebViewController _web;
  int _progress = 0;
  bool _loadFailed = false;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _web = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _onNavigationRequest,
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            if (mounted && _loadFailed) setState(() => _loadFailed = false);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              if (mounted) setState(() => _loadFailed = true);
            }
          },
        ),
      )
      ..loadRequest(widget.checkoutUrl);
    // Checkout stops waiting when the payment is confirmed, fails or is
    // abandoned; this screen must not stay on top of it.
    _session.stage.addListener(_onStageChanged);
  }

  @override
  void dispose() {
    _session.stage.removeListener(_onStageChanged);
    super.dispose();
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;
    final paymentReturn =
        CardPaymentSession.parseHostedReturn(uri, orderId: widget.orderId) ??
        CardPaymentSession.parseReturnLink(uri);
    if (paymentReturn != null) {
      _session.report(paymentReturn);
      _close();
      return NavigationDecision.prevent;
    }
    // App links and intents cannot open inside this page.
    if (uri.scheme != 'https' && uri.scheme != 'http') {
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  void _onStageChanged() {
    if (_session.stage.value != CardPaymentStage.awaitingCustomer ||
        _session.activeOrderId != widget.orderId) {
      _close();
    }
  }

  void _close() {
    if (_closing || !mounted) return;
    _closing = true;
    final route = ModalRoute.of(context);
    if (route == null || !route.isActive) return;
    final navigator = Navigator.of(context);
    if (route.isCurrent) {
      navigator.pop();
    } else {
      navigator.removeRoute(route);
    }
  }

  Future<void> _onBack() async {
    if (await _web.canGoBack()) {
      await _web.goBack();
      return;
    }
    await _confirmLeave();
  }

  Future<void> _confirmLeave() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave secure payment?'),
        content: const Text(
          "If you haven't paid yet, nothing is charged and your cart stays "
          'saved.',
        ),
        actions: [
          TextButton(
            key: const ValueKey('secure-payment-keep-paying'),
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep paying'),
          ),
          TextButton(
            key: const ValueKey('secure-payment-leave'),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (leave != true || !mounted) return;
    _session.abandon();
    _close();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final loading = _progress < 100 && !_loadFailed;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(_onBack());
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            key: const ValueKey('secure-payment-close'),
            tooltip: 'Leave payment',
            icon: const Icon(Icons.close_rounded),
            onPressed: _confirmLeave,
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_rounded, size: 18, color: colors.primary),
              const SizedBox(width: 8),
              const Text('Secure payment'),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(3),
            child: loading
                ? LinearProgressIndicator(
                    minHeight: 3,
                    value: _progress == 0 ? null : _progress / 100,
                  )
                : const SizedBox(height: 3),
          ),
        ),
        body: _loadFailed
            ? _LoadFailed(onRetry: () => _web.reload())
            : WebViewWidget(controller: _web),
      ),
    );
  }
}

class _LoadFailed extends StatelessWidget {
  const _LoadFailed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 40,
              color: context.appColors.warning,
            ),
            const SizedBox(height: 16),
            Text(
              'Could not load the payment page',
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again. Nothing has been charged '
              'and your cart is saved.',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              key: const ValueKey('secure-payment-retry'),
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
