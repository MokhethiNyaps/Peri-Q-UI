import 'package:flutter_test/flutter_test.dart';

import 'package:peri_q_app/src/app.dart';

void main() {
  testWidgets('app renders splash screen', (tester) async {
    await tester.pumpWidget(const PeriQApp());
    expect(find.text('PERI Q'), findsOneWidget);
  });
}
