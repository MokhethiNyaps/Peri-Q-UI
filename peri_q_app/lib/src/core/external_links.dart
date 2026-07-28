abstract final class AppExternalLinks {
  static const String supportEmailAddress = 'contact@rastasperiq.co.za';
  static const String primaryPhoneNumber = '+27736423549';
  static const String whatsAppNumber = '27736423549';

  static final Uri website = Uri.parse('https://rastasperiq.co.za/');
  static final Uri privacyPolicy = Uri.parse(
    'https://rastasperiq.co.za/privacy-policy/',
  );
  static final Uri accountDeletion = Uri.parse(
    'https://rastasperiq.co.za/delete-account/',
  );
  static final Uri termsAndConditions = Uri.parse(
    'https://rastasperiq.co.za/terms-and-conditions/',
  );
  static final Uri supportPage = Uri.parse(
    'https://rastasperiq.co.za/#contact',
  );
  static final Uri phone = Uri(scheme: 'tel', path: primaryPhoneNumber);
  static final Uri supportEmail = Uri(
    scheme: 'mailto',
    path: supportEmailAddress,
    queryParameters: {'subject': "Rasta's Peri Q app support"},
  );
  static final Uri whatsApp = Uri.parse(
    'https://wa.me/$whatsAppNumber?text=Hello%20Rasta%27s%20Peri%20Q%2C%20I%20need%20help%20with%20the%20app.',
  );
}
