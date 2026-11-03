import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/external_links.dart';

/// Required tick box: the customer accepts the terms and confirms they read
/// the privacy policy. Part of the surrounding [Form], so the form does not
/// validate until it is ticked.
class PolicyConsentField extends FormField<bool> {
  PolicyConsentField({super.key})
    : super(
        initialValue: false,
        validator: (value) => value == true
            ? null
            : 'Accept the terms and conditions to continue.',
        builder: (field) => _PolicyConsentView(field: field),
      );
}

class _PolicyConsentView extends StatelessWidget {
  const _PolicyConsentView({required this.field});

  final FormFieldState<bool> field;

  Future<void> _open(BuildContext context, Uri link) async {
    if (!await launchUrl(link, mode: LaunchMode.inAppBrowserView)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open the page.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final linkStyle = TextButton.styleFrom(
      padding: EdgeInsets.zero,
      minimumSize: const Size(0, 32),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              key: const ValueKey('policy-consent-checkbox'),
              value: field.value ?? false,
              onChanged: (value) => field.didChange(value ?? false),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Text('I accept the '),
                    TextButton(
                      style: linkStyle,
                      onPressed: () =>
                          _open(context, AppExternalLinks.termsAndConditions),
                      child: const Text('terms and conditions'),
                    ),
                    const Text(' and have read the '),
                    TextButton(
                      style: linkStyle,
                      onPressed: () =>
                          _open(context, AppExternalLinks.privacyPolicy),
                      child: const Text('privacy policy'),
                    ),
                    const Text('.'),
                  ],
                ),
              ),
            ),
          ],
        ),
        if (field.hasError)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 4),
            child: Text(
              field.errorText!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
      ],
    );
  }
}
