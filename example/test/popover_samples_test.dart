import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mjn_liquid_ui_example/widgets/popover_samples.dart';

void main() {
  const channel = MethodChannel('mjn_liquid_ui/popovers');

  testWidgets('consumer text, dimensions and behavior reach native popover', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final calls = <MethodCall>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      final content = (call.arguments as Map)['content'] as Map;
      final rows =
          ((content['sections'] as List).single as Map)['rows'] as List;
      final fieldId = (rows[1] as Map)['textFieldActionId'] as String;
      return {
        'status': 'saved',
        'textFieldValues': {fieldId: 'Returned native value'},
      };
    });
    try {
      await tester.pumpWidget(const MaterialApp(home: PopoverSamplesPage()));
      await tester.enterText(
        find.widgetWithText(TextField, 'Popover title'),
        'App-owned title',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Popover message'),
        'App-owned message',
      );
      tester.widget<Slider>(find.byType(Slider).first).onChanged!(410);
      await tester.tap(find.text('Use a preferred height'));
      await tester.pump();
      tester.widget<Slider>(find.byType(Slider).last).onChanged!(450);
      await tester.tap(find.text('Keep popover in compact layouts'));
      await tester.tap(find.text('Dismiss when tapping outside'));
      await tester.tap(find.text('Use a custom background color'));
      await tester.pump();
      await tester.tap(find.text('Show native popover'));
      await tester.pumpAndSettle();

      expect(calls, hasLength(1));
      expect(calls.single.method, 'showPopover');
      final arguments = calls.single.arguments as Map;
      final content = arguments['content'] as Map;
      expect(content['title'], 'App-owned title');
      expect((content['trailingAction'] as Map)['title'], 'Apply');
      final rows =
          ((content['sections'] as List).single as Map)['rows'] as List;
      expect((rows.first as Map)['title'], 'App-owned message');
      final options = arguments['options'] as Map;
      expect(options['width'], 410.0);
      expect(options['height'], 450.0);
      expect(options['maxHeight'], 700.0);
      expect(options['compactBehavior'], 'automatic');
      expect(options['dismissOnTapOutside'], isFalse);
      expect(options['backgroundColor'], 0xfff2f7ff);
      expect(options['tintColor'], 0xff007aff);
      expect(options['showsToolbarActions'], isTrue);
      expect(find.text('saved: Returned native value'), findsOneWidget);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      messenger.setMockMethodCallHandler(channel, null);
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('unsupported platform shows a useful fallback message', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    try {
      await tester.pumpWidget(const MaterialApp(home: PopoverSamplesPage()));
      await tester.tap(find.text('Show native popover'));
      await tester.pumpAndSettle();
      expect(
        find.text('Native popovers require iOS 16+ and a visible anchor.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox());
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
