import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:peri_q_app/src/core/policy_version.dart';
import 'package:peri_q_app/src/widgets/policy_consent_field.dart';

void main() {
  testWidgets('a form with the policy box is invalid until it is ticked', (
    tester,
  ) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Form(key: formKey, child: PolicyConsentField()),
        ),
      ),
    );

    expect(find.text('terms and conditions'), findsOneWidget);
    expect(find.text('privacy policy'), findsOneWidget);

    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(
      find.text('Accept the terms and conditions to continue.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('policy-consent-checkbox')));
    await tester.pump();
    expect(formKey.currentState!.validate(), isTrue);
    await tester.pump();
    expect(
      find.text('Accept the terms and conditions to continue.'),
      findsNothing,
    );
  });

  test('the app and website accept the same policy version', () {
    expect(policyVersion, '2026-11-03-draft');
  });
}
