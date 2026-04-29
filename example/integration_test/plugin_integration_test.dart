import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mjn_liquid_ui_example/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('demo app shows all tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Tabs'), findsOneWidget);
    expect(find.text('Switch'), findsOneWidget);
    expect(find.text('Slider'), findsOneWidget);
    expect(find.text('Surface'), findsOneWidget);
  });
}
