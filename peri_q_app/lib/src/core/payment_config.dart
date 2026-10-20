/// Public checkout endpoint; server credentials must never be Dart defines.
Uri? cardCheckoutUri({String? override}) {
  const configured = String.fromEnvironment(
    'CARD_CHECKOUT_URL',
    defaultValue: 'https://rastasperiq.co.za/api/yoco/checkout/',
  );
  final uri = Uri.tryParse((override ?? configured).trim());
  if (uri == null ||
      uri.scheme != 'https' ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty ||
      uri.hasQuery ||
      uri.hasFragment) {
    return null;
  }
  return uri;
}
