import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';

const MethodChannel _channel = MethodChannel('mjn_liquid_ui/toasts');

Future<void> _send(String method, Object? arguments) async {
  final ByteData message = const StandardMethodCodec().encodeMethodCall(
    MethodCall(method, arguments),
  );
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(_channel.name, message, (_) {});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    messenger.setMockMethodCallHandler(_channel, (_) async => true);
  });

  tearDown(() async {
    await AppleLiquidToast.dismiss();
    await _send('stackVisibilityChanged', false);
    messenger.setMockMethodCallHandler(_channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test(
    'starts false and synchronizes native state once on first access',
    () async {
      final Completer<bool> snapshot = Completer<bool>();
      int queries = 0;
      messenger.setMockMethodCallHandler(_channel, (MethodCall call) async {
        if (call.method == 'getStackVisibility') {
          queries += 1;
          if (queries == 1) throw MissingPluginException();
          if (queries == 2) throw PlatformException(code: 'unavailable');
          return snapshot.future;
        }
        return true;
      });

      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      expect(AppleLiquidToast.isStackVisible.value, isFalse);
      expect(queries, 0);
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final ValueListenable<bool> visibility = AppleLiquidToast.isStackVisible;
      expect(visibility.value, isFalse);
      expect(visibility, isNot(isA<ValueNotifier<bool>>()));
      await Future<void>.delayed(Duration.zero);
      expect(AppleLiquidToast.isStackVisible.value, isFalse);
      await Future<void>.delayed(Duration.zero);
      expect(AppleLiquidToast.isStackVisible.value, isFalse);
      final List<bool> changes = <bool>[];
      void listener() => changes.add(visibility.value);
      visibility.addListener(listener);
      addTearDown(() => visibility.removeListener(listener));

      snapshot.complete(true);
      await Future<void>.delayed(Duration.zero);
      expect(visibility.value, isTrue);
      expect(changes, <bool>[true]);
      expect(identical(visibility, AppleLiquidToast.isStackVisible), isTrue);
      expect(queries, 3);
    },
  );

  test('show and dismiss wait for authoritative native visibility', () async {
    final ValueListenable<bool> visibility = AppleLiquidToast.isStackVisible;
    expect(await AppleLiquidToast.show(title: 'Saved', duration: null), isTrue);
    expect(visibility.value, isFalse);
    await _send('stackVisibilityChanged', true);
    expect(visibility.value, isTrue);

    expect(await AppleLiquidToast.dismiss(), isTrue);
    expect(visibility.value, isTrue);
    await _send('stackVisibilityChanged', false);
    expect(visibility.value, isFalse);
  });

  test(
    'individual dismissal and collapsed originals do not hide the stack',
    () async {
      final ValueListenable<bool> visibility = AppleLiquidToast.isStackVisible;
      final List<bool> changes = <bool>[];
      void listener() => changes.add(visibility.value);
      visibility.addListener(listener);
      addTearDown(() => visibility.removeListener(listener));

      await _send('stackVisibilityChanged', true);
      for (final String id in <String>['first', 'second', 'third']) {
        await _send('toastDismissed', <String, Object?>{'toastId': id});
        expect(visibility.value, isTrue);
      }
      await _send('stackVisibilityChanged', true);
      expect(changes, <bool>[true]);

      await _send('stackVisibilityChanged', false);
      expect(changes, <bool>[true, false]);
    },
  );

  for (final String reason in <String>['swipe', 'expiry', 'action']) {
    test(
      'native last-toast $reason updates immediately and keeps callbacks',
      () async {
        String? actionId;
        String? toastId;
        int actions = 0;
        messenger.setMockMethodCallHandler(_channel, (MethodCall call) async {
          if (call.method == 'show') {
            final Map<Object?, Object?> arguments =
                call.arguments as Map<Object?, Object?>;
            actionId = arguments['actionId'] as String;
            toastId = arguments['id'] as String;
          }
          return true;
        });
        await AppleLiquidToast.show(
          title: reason,
          duration: null,
          action: AppleLiquidToastAction(
            title: 'Open',
            onPressed: () => actions += 1,
          ),
        );
        final ValueListenable<bool> visibility =
            AppleLiquidToast.isStackVisible;
        await _send('stackVisibilityChanged', true);
        await _send('stackVisibilityChanged', false);
        expect(visibility.value, isFalse);
        if (reason == 'action') {
          await _send('actionInvoked', <String, Object?>{'actionId': actionId});
          expect(actions, 1);
        }
        await _send('toastDismissed', <String, Object?>{'toastId': toastId});
        await _send('actionInvoked', <String, Object?>{'actionId': actionId});
        expect(actions, reason == 'action' ? 1 : 0);
      },
    );
  }

  test(
    'hide and restore commands use native events, including sheets',
    () async {
      final ValueListenable<bool> visibility = AppleLiquidToast.isStackVisible;
      await _send('stackVisibilityChanged', true);
      await AppleLiquidToast.setVisible(false);
      expect(visibility.value, isTrue);
      await _send('stackVisibilityChanged', false);
      expect(visibility.value, isFalse);
      await AppleLiquidToast.setVisible(true);
      expect(visibility.value, isFalse);
      await _send('stackVisibilityChanged', true);
      expect(visibility.value, isTrue);

      // Native sheet suspension uses the same event without a Dart command.
      await _send('stackVisibilityChanged', false);
      expect(visibility.value, isFalse);
      await _send('stackVisibilityChanged', true);
      expect(visibility.value, isTrue);
    },
  );

  test('unsupported platforms stay false without channel calls', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    final List<MethodCall> calls = <MethodCall>[];
    messenger.setMockMethodCallHandler(_channel, (MethodCall call) async {
      calls.add(call);
      return true;
    });
    expect(AppleLiquidToast.isStackVisible.value, isFalse);
    expect(await AppleLiquidToast.show(title: 'Unsupported'), isFalse);
    expect(await AppleLiquidToast.setVisible(true), isFalse);
    expect(await AppleLiquidToast.dismiss(), isFalse);
    expect(calls, isEmpty);
  });
}
