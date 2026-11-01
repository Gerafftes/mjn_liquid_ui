import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';

const _channel = MethodChannel('mjn_liquid_ui/popovers');
const _content = AppleLiquidPopoverContent(sections: []);

Future<void> _send(String method, Map<String, Object?> arguments) async {
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        _channel.name,
        const StandardMethodCodec().encodeMethodCall(
          MethodCall(method, arguments),
        ),
        (_) {},
      );
}

List<Map<Object?, Object?>> _rows(Map<Object?, Object?> arguments) {
  final content = arguments['content'] as Map;
  final sections = content['sections'] as List;
  return ((sections.first as Map)['rows'] as List)
      .cast<Map<Object?, Object?>>();
}

class _BrokenSections extends ListBase<AppleLiquidSheetSection> {
  _BrokenSections(this.firstSection);
  final AppleLiquidSheetSection firstSection;
  @override
  int get length => 2;
  @override
  set length(int value) => throw UnsupportedError('immutable');
  @override
  AppleLiquidSheetSection operator [](int index) {
    if (index == 0) return firstSection;
    throw StateError('Serialization failed after registering callbacks');
  }

  @override
  void operator []=(int index, AppleLiquidSheetSection value) =>
      throw UnsupportedError('immutable');
}

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  final messenger = binding.defaultBinaryMessenger;
  late AppleLiquidPopoverController controller;
  late List<MethodCall> calls;
  late Completer<Object?> result;

  Widget anchor({double left = 20, bool enabled = true}) => Directionality(
    textDirection: TextDirection.ltr,
    child: TickerMode(
      enabled: enabled,
      child: Stack(
        children: [
          Positioned(
            left: left,
            top: 40,
            child: AppleLiquidPopoverAnchor(
              builder: (context, value) {
                controller = value;
                return const SizedBox(width: 100, height: 30);
              },
            ),
          ),
        ],
      ),
    ),
  );

  void popoverTest(String name, WidgetTesterCallback callback) {
    testWidgets(name, (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      calls = [];
      result = Completer<Object?>();
      messenger.setMockMethodCallHandler(_channel, (call) async {
        calls.add(call);
        if (call.method == 'showPopover') return await result.future;
        return true;
      });

      try {
        await callback(tester);
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  tearDown(() {
    messenger.setMockMethodCallHandler(_channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  popoverTest(
    'passes native configuration and logical anchor without demo content',
    (tester) async {
      tester.view.devicePixelRatio = 2;
      tester.view.physicalSize = const Size(1600, 1200);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(anchor());
      final future = controller.show(
        content: _content,
        options: const AppleLiquidPopoverOptions(
          width: 280,
          height: 320,
          minWidth: 100,
          maxWidth: 400,
          minHeight: 80,
          maxHeight: 500,
          arrowDirections: [AppleLiquidPopoverArrowDirection.down],
          layoutMargins: EdgeInsets.fromLTRB(1, 2, 3, 4),
          contentPadding: EdgeInsets.all(8),
          backgroundColor: Color(0xff123456),
          tintColor: Color(0xff654321),
          compactBehavior: AppleLiquidPopoverCompactBehavior.popover,
          titleDisplayMode: AppleLiquidPopoverTitleDisplayMode.large,
          dismissOnTapOutside: false,
          canOverlapSourceRect: true,
          showsToolbarActions: true,
          animated: false,
        ),
      );
      await tester.pump();
      final args = calls.single.arguments as Map;
      expect(args['anchor'], {
        'x': 20.0,
        'y': 40.0,
        'width': 100.0,
        'height': 30.0,
      });
      expect(args['viewSize'], {'width': 800.0, 'height': 600.0});
      expect((args['content'] as Map)['sections'], isEmpty);
      expect((args['content'] as Map)['title'], '');
      expect(args['options'], {
        'width': 280.0,
        'height': 320.0,
        'minWidth': 100.0,
        'maxWidth': 400.0,
        'minHeight': 80.0,
        'maxHeight': 500.0,
        'arrowDirections': ['down'],
        'layoutMargins': {'top': 2.0, 'left': 1.0, 'bottom': 4.0, 'right': 3.0},
        'contentPadding': {
          'top': 8.0,
          'left': 8.0,
          'bottom': 8.0,
          'right': 8.0,
        },
        'backgroundColor': 0xff123456,
        'tintColor': 0xff654321,
        'compactBehavior': 'popover',
        'titleDisplayMode': 'large',
        'dismissOnTapOutside': false,
        'canOverlapSourceRect': true,
        'showsToolbarActions': true,
        'animated': false,
      });
      expect(controller.isShowing, isTrue);
      expect(
        (await controller.show(content: _content)).status,
        AppleLiquidSheetResultStatus.alreadyShowing,
      );
      result.complete({'status': 'saved'});
      await tester.pump();
      expect((await future).status, AppleLiquidSheetResultStatus.saved);
      expect(controller.isShowing, isFalse);
      final dismiss = controller.dismiss();
      await tester.pump();
      expect(await dismiss, isFalse);
    },
  );

  popoverTest(
    'title display mode defaults inline and permits automatic sizing',
    (tester) async {
      await tester.pumpWidget(anchor());
      for (final mode in <AppleLiquidPopoverTitleDisplayMode?>[
        null,
        AppleLiquidPopoverTitleDisplayMode.automatic,
      ]) {
        result = Completer<Object?>();
        final future = controller.show(
          content: _content,
          options: mode == null
              ? const AppleLiquidPopoverOptions()
              : AppleLiquidPopoverOptions(titleDisplayMode: mode),
        );
        await tester.pump();
        expect(
          ((calls.last.arguments as Map)['options'] as Map)['titleDisplayMode'],
          mode?.name ?? 'inline',
        );
        result.complete({'status': 'cancelled'});
        await tester.pump();
        await future;
      }
    },
  );

  popoverTest(
    'native callbacks and final text values are scoped to presentation',
    (tester) async {
      await tester.pumpWidget(anchor());
      int presses = 0;
      final changes = <String>[];
      final future = controller.show(
        content: AppleLiquidPopoverContent(
          sections: [
            AppleLiquidSheetSection(
              rows: [
                AppleLiquidSheetRow.button(
                  title: 'Run',
                  onPressed: () => presses++,
                ),
                AppleLiquidSheetRow.textField(
                  identifier: 'name',
                  title: 'Name',
                  value: 'Before',
                  onChanged: changes.add,
                ),
              ],
            ),
          ],
        ),
      );
      await tester.pump();
      final rows = _rows(calls.single.arguments as Map<Object?, Object?>);
      final button = rows[0]['buttonActionId'] as String;
      final field = rows[1]['textFieldActionId'] as String;
      await _send('buttonPressed', {'actionId': button});
      await _send('textFieldChanged', {'actionId': field, 'value': 'Live'});
      result.complete({
        'status': 'cancelled',
        'textFieldValues': {field: 'Final'},
      });
      await tester.pump();
      final value = await future;
      expect(value.status, AppleLiquidSheetResultStatus.cancelled);
      expect(value.textField('name')?.value, 'Final');
      expect(changes, ['Live', 'Final']);
      await _send('buttonPressed', {'actionId': button});
      await _send('textFieldChanged', {'actionId': field, 'value': 'Stale'});
      expect(presses, 1);
      expect(changes, ['Live', 'Final']);
    },
  );

  popoverTest('channel failures remove callbacks and allow retry', (
    tester,
  ) async {
    await tester.pumpWidget(anchor());
    int presses = 0;
    messenger.setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      throw PlatformException(code: 'failed');
    });
    final content = AppleLiquidPopoverContent(
      sections: [
        AppleLiquidSheetSection(
          rows: [
            AppleLiquidSheetRow.button(
              title: 'Run',
              onPressed: () => presses++,
            ),
          ],
        ),
      ],
    );
    await expectLater(
      controller.show(content: content),
      throwsA(isA<PlatformException>()),
    );
    final id =
        _rows(
              calls.single.arguments as Map<Object?, Object?>,
            ).single['buttonActionId']
            as String;
    await _send('buttonPressed', {'actionId': id});
    expect(presses, 0);
    expect(controller.isShowing, isFalse);
    messenger.setMockMethodCallHandler(
      _channel,
      (call) async => {'status': 'alreadyShowing'},
    );
    expect(
      (await controller.show(content: content)).status,
      AppleLiquidSheetResultStatus.alreadyShowing,
    );
    expect(controller.isShowing, isFalse);
  });

  popoverTest('serialization failure clears local presentation state', (
    tester,
  ) async {
    await tester.pumpWidget(anchor());
    await expectLater(
      controller.show(
        content: AppleLiquidPopoverContent(
          sections: _BrokenSections(
            AppleLiquidSheetSection(
              rows: [
                AppleLiquidSheetRow.button(title: 'Run', onPressed: () {}),
              ],
            ),
          ),
        ),
      ),
      throwsStateError,
    );
    expect(controller.isShowing, isFalse);
    expect(calls, isEmpty);
    messenger.setMockMethodCallHandler(
      _channel,
      (call) async => {'status': 'notPresented'},
    );
    expect(
      (await controller.show(content: _content)).status,
      AppleLiquidSheetResultStatus.notPresented,
    );
  });

  popoverTest(
    'updates moving anchors only on real frames and dismisses by session on removal',
    (tester) async {
      await tester.pumpWidget(anchor());
      final future = controller.show(content: _content);
      await tester.pump();
      final id = (calls.single.arguments as Map)['sessionId'];
      expect(binding.hasScheduledFrame, isFalse);
      await tester.pump();
      expect(calls, hasLength(1));
      await tester.pumpWidget(anchor(left: 70));
      expect(calls.last.method, 'updateAnchor');
      expect((calls.last.arguments as Map)['sessionId'], id);
      expect(((calls.last.arguments as Map)['anchor'] as Map)['x'], 70.0);
      await tester.pumpWidget(const SizedBox());
      expect(calls.last.method, 'dismissPopover');
      expect(calls.last.arguments, {'sessionId': id});
      result.complete({'status': 'cancelled'});
      await tester.pump();
      await future;
      expect(
        (await controller.show(content: _content)).status,
        AppleLiquidSheetResultStatus.notPresented,
      );
    },
  );

  popoverTest('hidden anchors dismiss their presentation', (tester) async {
    await tester.pumpWidget(anchor());
    final future = controller.show(content: _content);
    await tester.pump();
    await tester.pumpWidget(anchor(enabled: false));
    expect(calls.last.method, 'dismissPopover');
    result.complete({'status': 'cancelled'});
    await tester.pump();
    await future;
  });

  popoverTest('route changes dismiss the current presentation', (tester) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Navigator(
          key: navigator,
          onGenerateRoute: (_) =>
              PageRouteBuilder<void>(pageBuilder: (_, __, ___) => anchor()),
        ),
      ),
    );
    final future = controller.show(content: _content);
    await tester.pump();
    unawaited(
      navigator.currentState!.push(
        PageRouteBuilder<void>(pageBuilder: (_, __, ___) => const SizedBox()),
      ),
    );
    await tester.pumpAndSettle();
    expect(calls.last.method, 'dismissPopover');
    result.complete({'status': 'cancelled'});
    await tester.pump();
    await future;
  });

  popoverTest('asynchronous dismiss errors are reported and permit retry', (
    tester,
  ) async {
    await tester.pumpWidget(anchor());
    final future = controller.show(content: _content);
    await tester.pump();
    int attempts = 0;
    messenger.setMockMethodCallHandler(_channel, (call) async {
      calls.add(call);
      if (call.method == 'dismissPopover' && attempts++ == 0) {
        throw PlatformException(code: 'dismiss_failed');
      }
      return true;
    });
    await tester.pumpWidget(anchor(enabled: false));
    expect(tester.takeException(), isA<PlatformException>());
    final retry = controller.dismiss();
    await tester.pump();
    expect(await retry, isTrue);
    expect(attempts, 2);
    expect(tester.takeException(), isNull);
    result.complete({'status': 'cancelled'});
    await tester.pump();
    await future;
    expect(controller.isShowing, isFalse);
  });

  popoverTest('unsupported and offscreen anchors never invoke native channel', (
    tester,
  ) async {
    await tester.pumpWidget(anchor());
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    expect(
      (await controller.show(content: _content)).status,
      AppleLiquidSheetResultStatus.notPresented,
    );
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    await tester.pumpWidget(anchor(left: 10000));
    expect(
      (await controller.show(content: _content)).status,
      AppleLiquidSheetResultStatus.notPresented,
    );
    expect(calls, isEmpty);
  });

  popoverTest('invalid options are rejected with runtime validation', (
    tester,
  ) async {
    await tester.pumpWidget(anchor());
    for (final options in [
      const AppleLiquidPopoverOptions(width: 0),
      const AppleLiquidPopoverOptions(height: double.infinity),
      const AppleLiquidPopoverOptions(minWidth: double.nan),
      const AppleLiquidPopoverOptions(minWidth: 40, maxWidth: 20),
      const AppleLiquidPopoverOptions(minHeight: 40, maxHeight: 20),
      const AppleLiquidPopoverOptions(layoutMargins: EdgeInsets.all(-1)),
      const AppleLiquidPopoverOptions(
        contentPadding: EdgeInsets.all(double.nan),
      ),
    ]) {
      await expectLater(
        controller.show(content: _content, options: options),
        throwsArgumentError,
      );
      expect(controller.isShowing, isFalse);
    }
    expect(calls, isEmpty);
  });
}
