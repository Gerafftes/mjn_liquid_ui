import 'package:flutter_test/flutter_test.dart';

import 'package:mjn_liquid_ui_example/main.dart';

void main() {
  testWidgets('shows the demo shell', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('MJN Liquid UI'), findsOneWidget);
    expect(find.text('Tabbar'), findsOneWidget);
    expect(find.text('Switch'), findsOneWidget);
    expect(find.text('Slider'), findsOneWidget);
    expect(find.text('Surface'), findsOneWidget);
  });
}
