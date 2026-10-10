import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();
  const MethodChannel toastChannel = MethodChannel('mjn_liquid_ui/toasts');

  test('AppleLiquidToast returns false outside iOS', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    final List<MethodCall> calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (MethodCall call) async {
          calls.add(call);
          return true;
        });

    try {
      expect(await AppleLiquidToast.show(title: 'Saved'), isFalse);
      expect(await AppleLiquidToast.dismiss(), isFalse);
      expect(await AppleLiquidToast.setVisible(false), isFalse);
      expect(await AppleLiquidToast.setVisible(true), isFalse);
      expect(calls, isEmpty);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(toastChannel, null);
    }
  });

  test('AppleLiquidToast hides and restores the active stack', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final List<MethodCall> calls = <MethodCall>[];
    String? actionId;
    int actionTapCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (MethodCall call) async {
          calls.add(call);
          if (call.method == 'show') {
            final Map<Object?, Object?> arguments =
                call.arguments as Map<Object?, Object?>;
            actionId = arguments['actionId'] as String?;
          }
          return true;
        });

    try {
      expect(
        await AppleLiquidToast.show(
          title: 'Saved',
          duration: null,
          action: AppleLiquidToastAction(
            title: 'Undo',
            dismissesToast: false,
            onPressed: () {
              actionTapCount += 1;
            },
          ),
        ),
        isTrue,
      );

      expect(await AppleLiquidToast.setVisible(false), isTrue);
      expect(await AppleLiquidToast.setVisible(true), isTrue);

      expect(calls.map((MethodCall call) => call.method).toList(), <String>[
        'show',
        'setVisibility',
        'setVisibility',
      ]);
      expect(calls[1].arguments, isFalse);
      expect(calls[2].arguments, isTrue);

      await _sendPlatformMethodCall(
        toastChannel,
        'actionInvoked',
        <String, Object?>{'actionId': actionId},
      );
      expect(actionTapCount, 1);
    } finally {
      await AppleLiquidToast.setVisible(true);
      await AppleLiquidToast.dismiss();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(toastChannel, null);
    }
  });

  test('AppleLiquidToast sends native show payload on iOS', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final List<MethodCall> calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (MethodCall call) async {
          calls.add(call);
          return true;
        });

    try {
      expect(
        await AppleLiquidToast.show(
          title: 'Added to Cart',
          duration: const Duration(milliseconds: 1500),
          placementOffset: -44,
          transitionOffset: 120,
          systemImage: 'cart.fill',
          action: AppleLiquidToastAction(
            title: 'Undo',
            tintColor: const Color(0xFFFF9500),
            dismissesToast: false,
            isWholeToastTappable: true,
            onPressed: () {},
          ),
        ),
        isTrue,
      );

      expect(calls, hasLength(1));
      expect(calls.single.method, 'show');

      final Map<Object?, Object?> arguments =
          calls.single.arguments as Map<Object?, Object?>;
      expect(arguments, containsPair('title', 'Added to Cart'));
      expect(arguments, containsPair('duration', 1.5));
      expect(arguments, containsPair('placementOffset', -44.0));
      expect(arguments, containsPair('transitionOffset', 120.0));
      expect(arguments['maxVisibleToasts'], isNull);
      expect(arguments, containsPair('overflowTitle', 'More notifications'));
      expect(arguments, containsPair('isVisible', true));
      expect(arguments, containsPair('systemImage', 'cart.fill'));
      expect(arguments, containsPair('actionTitle', 'Undo'));
      expect(arguments, containsPair('actionTintColor', 0xFFFF9500));
      expect(arguments, containsPair('dismissesOnAction', false));
      expect(arguments, containsPair('isWholeToastTappable', true));
      expect(arguments['actionId'], isA<String>());
    } finally {
      await AppleLiquidToast.dismiss();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(toastChannel, null);
    }
  });

  test('AppleLiquidToast keeps stacked actions independent', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final List<String> actionIds = <String>[];
    final List<String> toastIds = <String>[];
    int firstTapCount = 0;
    int secondTapCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (MethodCall call) async {
          if (call.method == 'show') {
            final Map<Object?, Object?> arguments =
                call.arguments as Map<Object?, Object?>;
            actionIds.add(arguments['actionId'] as String);
            toastIds.add(arguments['id'] as String);
          }

          return true;
        });

    try {
      expect(
        await AppleLiquidToast.show(
          title: 'First',
          duration: null,
          action: AppleLiquidToastAction(
            title: 'Undo first',
            dismissesToast: false,
            onPressed: () {
              firstTapCount += 1;
            },
          ),
        ),
        isTrue,
      );
      expect(
        await AppleLiquidToast.show(
          title: 'Second',
          duration: null,
          action: AppleLiquidToastAction(
            title: 'Undo second',
            dismissesToast: false,
            onPressed: () {
              secondTapCount += 1;
            },
          ),
        ),
        isTrue,
      );

      expect(actionIds, hasLength(2));
      expect(actionIds[0], isNot(equals(actionIds[1])));
      expect(toastIds, hasLength(2));
      expect(toastIds[0], isNot(equals(toastIds[1])));

      await _sendPlatformMethodCall(
        toastChannel,
        'actionInvoked',
        <String, Object?>{'actionId': actionIds[0]},
      );
      await _sendPlatformMethodCall(
        toastChannel,
        'actionInvoked',
        <String, Object?>{'actionId': actionIds[1]},
      );

      expect(firstTapCount, 1);
      expect(secondTapCount, 1);

      await _sendPlatformMethodCall(
        toastChannel,
        'toastDismissed',
        <String, Object?>{'toastId': toastIds[0]},
      );
      await _sendPlatformMethodCall(
        toastChannel,
        'actionInvoked',
        <String, Object?>{'actionId': actionIds[0]},
      );
      await _sendPlatformMethodCall(
        toastChannel,
        'actionInvoked',
        <String, Object?>{'actionId': actionIds[1]},
      );

      expect(firstTapCount, 1);
      expect(secondTapCount, 2);
    } finally {
      await AppleLiquidToast.dismiss();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(toastChannel, null);
    }
  });

  test('AppleLiquidToast keeps actions trailing-only by default', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final List<MethodCall> calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (MethodCall call) async {
          calls.add(call);
          return true;
        });

    try {
      expect(
        await AppleLiquidToast.show(
          title: 'Added to Cart',
          action: AppleLiquidToastAction(title: 'Undo', onPressed: () {}),
        ),
        isTrue,
      );

      final Map<Object?, Object?> arguments =
          calls.single.arguments as Map<Object?, Object?>;
      expect(arguments, containsPair('isWholeToastTappable', false));
    } finally {
      await AppleLiquidToast.dismiss();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(toastChannel, null);
    }
  });

  test('AppleLiquidToast serializes configurable stack options', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final List<MethodCall> calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (MethodCall call) async {
          calls.add(call);
          return true;
        });

    final AppleLiquidToastStackOptions previousStackOptions =
        AppleLiquidToast.stackOptions;
    AppleLiquidToast.stackOptions = const AppleLiquidToastStackOptions(
      maxVisibleToasts: 2,
      overflowTitle: '{count} weitere Toasts',
    );

    try {
      expect(
        await AppleLiquidToast.show(title: 'First', duration: null),
        isTrue,
      );
      expect(
        await AppleLiquidToast.show(title: 'Second', duration: null),
        isTrue,
      );

      final List<Map<Object?, Object?>> showArguments = calls
          .where((MethodCall call) => call.method == 'show')
          .map((MethodCall call) => call.arguments as Map<Object?, Object?>)
          .toList();

      expect(showArguments, hasLength(2));
      for (final Map<Object?, Object?> arguments in showArguments) {
        expect(arguments, containsPair('maxVisibleToasts', 2));
        expect(
          arguments,
          containsPair('overflowTitle', '{count} weitere Toasts'),
        );
      }
    } finally {
      AppleLiquidToast.stackOptions = previousStackOptions;
      await AppleLiquidToast.dismiss();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(toastChannel, null);
    }
  });

  for (final bool dismissesToast in <bool>[true, false]) {
    test(
      'AppleLiquidToast retains the summary callback ($dismissesToast)',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        final List<Map<Object?, Object?>> shown = <Map<Object?, Object?>>[];
        int individualTaps = 0;
        int summaryTaps = 0;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(toastChannel, (MethodCall call) async {
              if (call.method == 'show') {
                shown.add(call.arguments as Map<Object?, Object?>);
              }
              return true;
            });
        AppleLiquidToast.stackOptions = AppleLiquidToastStackOptions(
          maxVisibleToasts: 2,
          overflowTitle: '{count} notifications',
          overflowAction: AppleLiquidToastAction(
            title: 'Open',
            tintColor: const Color(0xFFFF9500),
            dismissesToast: dismissesToast,
            onPressed: () => summaryTaps += 1,
          ),
        );

        Future<void> invoke(Object? actionId) => _sendPlatformMethodCall(
          toastChannel,
          'actionInvoked',
          <String, Object?>{'actionId': actionId},
        );
        Future<void> dismiss(Object? toastId) => _sendPlatformMethodCall(
          toastChannel,
          'toastDismissed',
          <String, Object?>{'toastId': toastId},
        );

        try {
          for (int index = 0; index < 3; index += 1) {
            expect(
              await AppleLiquidToast.show(
                title: 'Toast $index',
                duration: null,
                action: AppleLiquidToastAction(
                  title: 'Individual',
                  onPressed: () => individualTaps += 1,
                ),
              ),
              isTrue,
            );
          }
          final List<Map<Object?, Object?>> overflowActions = shown
              .map(
                (Map<Object?, Object?> arguments) =>
                    arguments['overflowAction'] as Map<Object?, Object?>,
              )
              .toList();
          expect(overflowActions.last, containsPair('title', 'Open'));
          expect(overflowActions.last, containsPair('tintColor', 0xFFFF9500));
          expect(
            overflowActions.last,
            containsPair('dismissesToast', dismissesToast),
          );

          // Native collapse discards every individual action and the unused
          // overflow actions, retaining only the newest summary's registration.
          for (int index = 0; index < shown.length; index += 1) {
            await dismiss(shown[index]['id']);
            if (index < shown.length - 1) {
              await dismiss(overflowActions[index]['toastId']);
            }
          }
          for (final Map<Object?, Object?> toast in shown) {
            await invoke(toast['actionId']);
          }
          await invoke(overflowActions.first['actionId']);
          expect(individualTaps, 0);
          expect(summaryTaps, 0);

          await AppleLiquidToast.setVisible(false);
          await AppleLiquidToast.setVisible(true);
          await invoke(overflowActions.last['actionId']);
          await invoke(overflowActions.last['actionId']);
          expect(summaryTaps, dismissesToast ? 1 : 2);

          await dismiss(overflowActions.last['toastId']);
          await invoke(overflowActions.last['actionId']);
          expect(summaryTaps, dismissesToast ? 1 : 2);
        } finally {
          await AppleLiquidToast.dismiss();
          AppleLiquidToast.stackOptions = const AppleLiquidToastStackOptions();
          debugDefaultTargetPlatformOverride = null;
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(toastChannel, null);
        }
      },
    );
  }

  test(
    'AppleLiquidToast clears overflow callbacks when showing fails',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      Map<Object?, Object?>? overflowAction;
      int taps = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(toastChannel, (MethodCall call) async {
            if (call.method == 'show') {
              overflowAction =
                  (call.arguments as Map<Object?, Object?>)['overflowAction']
                      as Map<Object?, Object?>;
            }
            return false;
          });
      AppleLiquidToast.stackOptions = AppleLiquidToastStackOptions(
        maxVisibleToasts: 1,
        overflowAction: AppleLiquidToastAction(
          title: 'Open',
          onPressed: () => taps += 1,
        ),
      );
      try {
        expect(
          await AppleLiquidToast.show(title: 'Failed', duration: null),
          isFalse,
        );
        await _sendPlatformMethodCall(
          toastChannel,
          'actionInvoked',
          <String, Object?>{'actionId': overflowAction!['actionId']},
        );
        expect(taps, 0);
      } finally {
        await AppleLiquidToast.dismiss();
        AppleLiquidToast.stackOptions = const AppleLiquidToastStackOptions();
        debugDefaultTargetPlatformOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(toastChannel, null);
      }
    },
  );

  test('AppleLiquidToast keeps the three-second default duration', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final List<MethodCall> calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (MethodCall call) async {
          calls.add(call);
          return true;
        });

    try {
      expect(await AppleLiquidToast.show(title: 'Saved'), isTrue);

      final Map<Object?, Object?> arguments =
          calls.single.arguments as Map<Object?, Object?>;
      expect(arguments, containsPair('duration', 3.0));
    } finally {
      await AppleLiquidToast.dismiss();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(toastChannel, null);
    }
  });

  test('AppleLiquidToast supports an indefinite native duration', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    String? actionId;
    String? toastId;
    int actionTapCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (MethodCall call) async {
          if (call.method == 'show') {
            final Map<Object?, Object?> arguments =
                call.arguments as Map<Object?, Object?>;
            actionId = arguments['actionId'] as String?;
            toastId = arguments['id'] as String?;
            expect(arguments['duration'], isNull);
          }

          return true;
        });

    try {
      expect(
        await AppleLiquidToast.show(
          title: 'Needs attention',
          duration: null,
          action: AppleLiquidToastAction(
            title: 'Undo',
            dismissesToast: false,
            onPressed: () {
              actionTapCount += 1;
            },
          ),
        ),
        isTrue,
      );

      expect(actionId, isNotNull);
      expect(toastId, isNotNull);

      await _sendPlatformMethodCall(
        toastChannel,
        'toastDismissed',
        <String, Object?>{'toastId': toastId},
      );
      await _sendPlatformMethodCall(
        toastChannel,
        'actionInvoked',
        <String, Object?>{'actionId': actionId},
      );

      expect(actionTapCount, 0);
    } finally {
      await AppleLiquidToast.dismiss();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(toastChannel, null);
    }
  });

  test('AppleLiquidToast.dismiss clears persistent action callbacks', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    String? actionId;
    int actionTapCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (MethodCall call) async {
          if (call.method == 'show') {
            final Map<Object?, Object?> arguments =
                call.arguments as Map<Object?, Object?>;
            actionId = arguments['actionId'] as String?;
          }

          return true;
        });

    try {
      await AppleLiquidToast.show(
        title: 'Needs attention',
        duration: null,
        action: AppleLiquidToastAction(
          title: 'Undo',
          dismissesToast: false,
          onPressed: () {
            actionTapCount += 1;
          },
        ),
      );

      await AppleLiquidToast.dismiss();
      await _sendPlatformMethodCall(
        toastChannel,
        'actionInvoked',
        <String, Object?>{'actionId': actionId},
      );

      expect(actionTapCount, 0);
    } finally {
      await AppleLiquidToast.dismiss();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(toastChannel, null);
    }
  });

  test('AppleLiquidToast action dismissal clears its callback', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    String? actionId;
    int actionTapCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (MethodCall call) async {
          if (call.method == 'show') {
            final Map<Object?, Object?> arguments =
                call.arguments as Map<Object?, Object?>;
            actionId = arguments['actionId'] as String?;
          }

          return true;
        });

    try {
      await AppleLiquidToast.show(
        title: 'Saved',
        action: AppleLiquidToastAction(
          title: 'Undo',
          onPressed: () {
            actionTapCount += 1;
          },
        ),
      );

      await _sendPlatformMethodCall(
        toastChannel,
        'actionInvoked',
        <String, Object?>{'actionId': actionId},
      );
      await _sendPlatformMethodCall(
        toastChannel,
        'actionInvoked',
        <String, Object?>{'actionId': actionId},
      );

      expect(actionTapCount, 1);
    } finally {
      await AppleLiquidToast.dismiss();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(toastChannel, null);
    }
  });

  test('AppleLiquidToast routes native action callbacks', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    String? actionId;
    int actionTapCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (MethodCall call) async {
          if (call.method == 'show') {
            final Map<Object?, Object?> arguments =
                call.arguments as Map<Object?, Object?>;
            actionId = arguments['actionId'] as String?;
          }

          return true;
        });

    try {
      expect(
        await AppleLiquidToast.show(
          title: 'Added to Cart',
          action: AppleLiquidToastAction(
            title: 'Undo',
            dismissesToast: false,
            onPressed: () {
              actionTapCount += 1;
            },
          ),
        ),
        isTrue,
      );

      expect(actionId, isNotNull);

      await _sendPlatformMethodCall(
        toastChannel,
        'actionInvoked',
        <String, Object?>{'actionId': actionId},
      );

      expect(actionTapCount, 1);
    } finally {
      await AppleLiquidToast.dismiss();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(toastChannel, null);
    }
  });

  test(
    'toast visibility events supersede an in-flight native snapshot',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final Completer<bool> snapshot = Completer<bool>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(toastChannel, (MethodCall call) async {
            return call.method == 'getStackVisibility' ? snapshot.future : true;
          });
      try {
        final ValueListenable<bool> visibility =
            AppleLiquidToast.isStackVisible;
        expect(visibility.value, isFalse);
        await _sendPlatformMethodCall(
          toastChannel,
          'stackVisibilityChanged',
          true,
        );
        expect(visibility.value, isTrue);
        snapshot.complete(false);
        await Future<void>.delayed(Duration.zero);
        expect(visibility.value, isTrue);
      } finally {
        await _sendPlatformMethodCall(
          toastChannel,
          'stackVisibilityChanged',
          false,
        );
        debugDefaultTargetPlatformOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(toastChannel, null);
      }
    },
  );

  test('AppleLiquidToastAction requires visible content', () {
    expect(() => AppleLiquidToastAction(title: ''), throwsAssertionError);
  });
}
