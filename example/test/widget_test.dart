import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mjn_liquid_ui_example/main.dart';

void main() {
  testWidgets('lays out the tabbar demo on compact iPhone width', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the demo shell', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('MJN Liquid UI'), findsOneWidget);
    expect(find.text('Tabbar'), findsOneWidget);
    expect(find.text('Switch'), findsOneWidget);
    expect(find.text('Slider'), findsOneWidget);
    expect(find.text('Surface'), findsOneWidget);
  });

  testWidgets('opens and closes the settings sheet demo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Component'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsNothing);
  });
}
