abstract final class AuthDeepLinks {
  static const String scheme = 'rastasperiq';
  static const String resetPasswordHost = 'reset-password';
  static const String resetPasswordUrl = '$scheme://$resetPasswordHost';

  static bool isPasswordReset(Uri uri) {
    return uri.scheme == scheme && uri.host == resetPasswordHost;
  }
}
