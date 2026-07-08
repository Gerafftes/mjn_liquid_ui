import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mjn_liquid_ui_example/main.dart';

void main() {
  const MethodChannel sheetChannel = MethodChannel('mjn_liquid_ui/sheets');

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

  testWidgets('opens and closes the custom sheet demo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Open'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Sheet Demo'), findsOneWidget);
    expect(find.text('Name'), findsOneWidget);
    expect(find.text('mjn_liquid_ui'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
    expect(find.text('Apply'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Sheet Demo'), findsNothing);
  });

  testWidgets('locks background scrolling while native sheet is active', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final Completer<bool> showCompleter = Completer<bool>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sheetChannel, (MethodCall call) async {
          if (call.method == 'showTemplateSheet') {
            return showCompleter.future;
          }

          return null;
        });

    try {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      final Finder mainListView = find.byType(ListView).first;
      await tester.drag(mainListView, const Offset(0, -80));
      await tester.pumpAndSettle();

      final ScrollableState scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable).first,
      );
      final double offsetBeforeSheet = scrollable.position.pixels;
      expect(offsetBeforeSheet, greaterThan(0));

      await tester.tap(find.text('Open'));
      await tester.pump();
      await tester.pump();

      final double lockedPixels = scrollable.position.pixels;
      expect(lockedPixels, closeTo(offsetBeforeSheet, 0.1));

      await tester.drag(
        mainListView,
        const Offset(0, -300),
        warnIfMissed: false,
      );
      await tester.pump();

      expect(scrollable.position.pixels, lockedPixels);

      showCompleter.complete(true);
      await tester.pumpAndSettle();
    } finally {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(sheetChannel, null);
    }
  });
}
