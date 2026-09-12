import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';

import 'package:mjn_liquid_ui_example/main.dart';

Future<void> _sendPlatformMethodCall(
  MethodChannel channel,
  String method, [
  Object? arguments,
]) async {
  final ByteData message = const StandardMethodCodec().encodeMethodCall(
    MethodCall(method, arguments),
  );

  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(channel.name, message, (_) {});
}

void main() {
  const MethodChannel sheetChannel = MethodChannel('mjn_liquid_ui/sheets');
  const MethodChannel toastChannel = MethodChannel('mjn_liquid_ui/toasts');

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
    expect(find.text('Toast stack'), findsOneWidget);
    expect(find.text('Add toast'), findsOneWidget);
  });

  testWidgets('shows the configurable concentric rectangle playground', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Switch'));
    await tester.pumpAndSettle();

    expect(find.text('Concentric Rectangle'), findsOneWidget);
    expect(find.byType(AppleConcentricRectangle), findsOneWidget);
    expect(find.text('Corner style'), findsOneWidget);
    expect(find.text('Corner grouping'), findsOneWidget);
    expect(find.text('Content padding'), findsOneWidget);
    expect(find.text('Custom container radius'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Geometry'), findsOneWidget);
    expect(find.text('Container'), findsOneWidget);
    expect(find.byType(AppleLiquidSlider), findsNWidgets(6));
  });

  testWidgets('preserves each demo tab scroll position', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = const Size(393, 500);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    try {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();

      final Finder tabbarList = find.byKey(
        const PageStorageKey<String>('demo-page-Tabbar'),
      );
      await tester.drag(tabbarList, const Offset(0, -260));
      await tester.pumpAndSettle();

      final ScrollableState tabbarScrollable = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(const PageStorageKey<String>('demo-page-Tabbar')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      final double tabbarOffset = tabbarScrollable.position.pixels;
      expect(tabbarOffset, greaterThan(0));

      await tester.tap(find.text('Switch'));
      await tester.pumpAndSettle();

      final Finder switchList = find.byKey(
        const PageStorageKey<String>('demo-page-Switch'),
      );
      await tester.drag(switchList, const Offset(0, -180));
      await tester.pumpAndSettle();

      final ScrollableState switchScrollable = tester.state<ScrollableState>(
        find
            .descendant(
              of: find.byKey(const PageStorageKey<String>('demo-page-Switch')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      final double switchOffset = switchScrollable.position.pixels;
      expect(switchOffset, greaterThan(0));

      await tester.tap(find.text('Tabs'));
      await tester.pumpAndSettle();
      expect(
        tester
            .state<ScrollableState>(
              find
                  .descendant(
                    of: find.byKey(
                      const PageStorageKey<String>('demo-page-Tabbar'),
                    ),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            )
            .position
            .pixels,
        closeTo(tabbarOffset, 0.1),
      );

      await tester.tap(find.text('Switch'));
      await tester.pumpAndSettle();
      expect(
        tester
            .state<ScrollableState>(
              find
                  .descendant(
                    of: find.byKey(
                      const PageStorageKey<String>('demo-page-Switch'),
                    ),
                    matching: find.byType(Scrollable),
                  )
                  .first,
            )
            .position
            .pixels,
        closeTo(switchOffset, 0.1),
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('opens Slider from one random whole-toast action', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final List<MethodCall> calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (MethodCall call) async {
          calls.add(call);
          return true;
        });

    try {
      await tester.pumpWidget(const MyApp());
      final Finder addButton = find.text('Add toast');
      await tester.ensureVisible(addButton);
      await tester.pumpAndSettle();
      for (int index = 0; index < 3; index += 1) {
        await tester.tap(addButton);
        await tester.pump();
      }

      final List<Map<Object?, Object?>> showArguments = calls
          .where((MethodCall call) => call.method == 'show')
          .map((MethodCall call) => call.arguments as Map<Object?, Object?>)
          .toList();

      expect(showArguments, hasLength(3));
      expect(
        showArguments.map((Map<Object?, Object?> arguments) {
          return arguments['title'];
        }),
        <Object?>['Toast 1', 'Toast 2', 'Toast 3'],
      );
      for (final Map<Object?, Object?> arguments in showArguments) {
        expect(arguments, containsPair('maxVisibleToasts', 2));
        expect(arguments, containsPair('overflowTitle', '{count} more toasts'));
      }

      final Map<Object?, Object?> actionableToast = showArguments.singleWhere(
        (Map<Object?, Object?> arguments) => arguments['actionId'] is String,
      );
      expect(actionableToast, containsPair('actionTitle', 'Open Slider'));
      expect(actionableToast, containsPair('isWholeToastTappable', true));

      await _sendPlatformMethodCall(
        toastChannel,
        'actionInvoked',
        <String, Object?>{'actionId': actionableToast['actionId']},
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Native SwiftUI sliders: continuous, stepped, and coarse.'),
        findsOneWidget,
      );
    } finally {
      await AppleLiquidToast.dismiss();
      AppleLiquidToast.stackOptions = const AppleLiquidToastStackOptions();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(toastChannel, null);
    }
  });

  testWidgets('opens and closes the custom sheet demo', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    final Finder openButton = find.text('Open');
    await tester.ensureVisible(openButton);
    await tester.pumpAndSettle();
    await tester.tap(openButton);
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

      final Finder openButton = find.text('Open');
      await tester.ensureVisible(openButton);
      await tester.pumpAndSettle();
      final double visibleOffsetBeforeSheet = scrollable.position.pixels;
      expect(visibleOffsetBeforeSheet, greaterThan(0));

      await tester.tap(openButton);
      await tester.pump();
      await tester.pump();

      final double lockedPixels = scrollable.position.pixels;
      expect(lockedPixels, closeTo(visibleOffsetBeforeSheet, 0.1));

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
