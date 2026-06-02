import 'package:flutter_test/flutter_test.dart';

import 'package:peri_q_app/src/app.dart';
import 'package:peri_q_app/src/core/supabase_config.dart';

void main() {
  testWidgets('shows config screen when Supabase is not configured', (
    tester,
  ) async {
    await tester.pumpWidget(
      const PeriQApp(supabaseConfig: SupabaseConfig.disabled()),
    );

    expect(find.text('Supabase is not configured'), findsOneWidget);
  });
}
