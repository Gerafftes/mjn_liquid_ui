import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';

const MethodChannel _symbolChannel = MethodChannel('mjn_liquid_ui/symbols');
final Uint8List _validPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGNgAAIAAAUAAXpeqz8AAAAASUVORK5CYII=',
);

Future<BuildContext> _mountContext(
  WidgetTester tester, {
  double dpr = 1,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(devicePixelRatio: dpr),
        child: Builder(
          key: const ValueKey<String>('precache-context'),
          builder: (BuildContext context) => const SizedBox.shrink(),
        ),
      ),
    ),
  );
  return tester.element(find.byKey(const ValueKey<String>('precache-context')));
}

void _resetImageCache() {
  PaintingBinding.instance.imageCache
    ..clear()
    ..clearLiveImages();
}

void _testAppleWidgets(
  String description,
  Future<void> Function(WidgetTester tester) body,
) {
  testWidgets(description, (WidgetTester tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    _resetImageCache();
    try {
      await body(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_symbolChannel, null);
      _resetImageCache();
    }
  });
}

Future<bool> _precache(
  WidgetTester tester,
  BuildContext context,
  String name, {
  double size = 24,
  Color? color,
  AppleLiquidSymbolWeight? weight,
}) async {
  return (await tester.runAsync(
    () => AppleLiquidSymbol.precache(
      context,
      name,
      size: size,
      color: color,
      weight: weight,
    ),
  ))!;
}

void main() {
  _testAppleWidgets(
    'precache warms the scale-1 image cache and widget reuses render',
    (WidgetTester tester) async {
      final Uint8List bytes = Uint8List.fromList(_validPng);
      final List<MethodCall> calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(_symbolChannel, (MethodCall call) async {
            calls.add(call);
            return bytes;
          });
      final BuildContext context = await _mountContext(tester, dpr: 2);

      final bool precached = await _precache(
        tester,
        context,
        'precache-success-unique',
        size: 20,
        color: const Color(0xFF123456),
        weight: AppleLiquidSymbolWeight.bold,
      );
      expect(precached, isTrue);
      expect(calls, hasLength(1));
      expect(calls.single.arguments, <String, Object?>{
        'name': 'precache-success-unique',
        'size': 20.0,
        'scale': 2.0,
        'color': 0xFF123456,
        'weight': 'bold',
      });
      expect(
        PaintingBinding.instance.imageCache.statusForKey(MemoryImage(bytes)),
        isNotNull,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(devicePixelRatio: 2),
            child: const AppleLiquidSymbol(
              'precache-success-unique',
              size: 20,
              color: Color(0xFF123456),
              weight: AppleLiquidSymbolWeight.bold,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.byType(Image), findsOneWidget);
      expect(calls, hasLength(1));
    },
  );

  _testAppleWidgets('concurrent precaches share one native render', (
    WidgetTester tester,
  ) async {
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_symbolChannel, (MethodCall call) async {
          calls++;
          await Future<void>.delayed(const Duration(milliseconds: 20));
          return _validPng;
        });
    final BuildContext context = await _mountContext(tester);

    final List<bool> results = (await tester.runAsync(() async {
      return Future.wait(<Future<bool>>[
        AppleLiquidSymbol.precache(context, 'precache-concurrent-unique'),
        AppleLiquidSymbol.precache(context, 'precache-concurrent-unique'),
      ]);
    }))!;

    expect(results, <bool>[true, true]);
    expect(calls, 1);
  });

  _testAppleWidgets('render cache key includes color, weight, size, and DPR', (
    WidgetTester tester,
  ) async {
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_symbolChannel, (MethodCall call) async {
          calls++;
          return _validPng;
        });
    final BuildContext context = await _mountContext(tester);

    Future<void> load({
      double size = 24,
      Color? color,
      AppleLiquidSymbolWeight? weight,
      double dpr = 1,
    }) async {
      final BuildContext currentContext = dpr == 1
          ? context
          : await _mountContext(tester, dpr: dpr);
      expect(
        await _precache(
          tester,
          currentContext,
          'precache-key-unique',
          size: size,
          color: color,
          weight: weight,
        ),
        isTrue,
      );
    }

    await load();
    await load(color: const Color(0xFF010203));
    await load(weight: AppleLiquidSymbolWeight.medium);
    await load(size: 25);
    await load(dpr: 2);
    expect(calls, 5);
  });

  _testAppleWidgets('evicts the oldest render after 128 cached entries', (
    WidgetTester tester,
  ) async {
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_symbolChannel, (MethodCall call) async {
          calls++;
          return _validPng;
        });
    final BuildContext context = await _mountContext(tester);

    for (var index = 0; index < 129; index++) {
      expect(
        await _precache(tester, context, 'precache-eviction-$index'),
        isTrue,
      );
    }
    expect(calls, 129);
    expect(await _precache(tester, context, 'precache-eviction-0'), isTrue);
    expect(calls, 130);
  });

  _testAppleWidgets('missing symbols are negative cached', (
    WidgetTester tester,
  ) async {
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_symbolChannel, (MethodCall call) async {
          calls++;
          return null;
        });
    final BuildContext context = await _mountContext(tester);

    expect(
      await _precache(tester, context, 'precache-missing-unique'),
      isFalse,
    );
    expect(
      await _precache(tester, context, 'precache-missing-unique'),
      isFalse,
    );
    expect(calls, 1);
  });

  _testAppleWidgets('transient channel errors can be retried', (
    WidgetTester tester,
  ) async {
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_symbolChannel, (MethodCall call) async {
          calls++;
          if (calls == 1) {
            throw PlatformException(code: 'temporary');
          }
          return _validPng;
        });
    final BuildContext context = await _mountContext(tester);

    expect(await _precache(tester, context, 'precache-retry-unique'), isFalse);
    expect(await _precache(tester, context, 'precache-retry-unique'), isTrue);
    expect(calls, 2);
  });

  _testAppleWidgets(
    'invalid PNG returns false without surfacing a decode error',
    (WidgetTester tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            _symbolChannel,
            (MethodCall call) async => Uint8List.fromList(<int>[1, 2, 3]),
          );
      final BuildContext context = await _mountContext(tester);

      expect(
        await _precache(tester, context, 'precache-bad-png-unique'),
        isFalse,
      );
    },
  );

  _testAppleWidgets(
    'returns false when its context unmounts during native render',
    (WidgetTester tester) async {
      final Completer<Uint8List> response = Completer<Uint8List>();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            _symbolChannel,
            (MethodCall call) => response.future,
          );
      final BuildContext context = await _mountContext(tester);
      final Future<bool> result = AppleLiquidSymbol.precache(
        context,
        'precache-unmount-unique',
      );
      await tester.pumpWidget(const SizedBox.shrink());
      response.complete(_validPng);

      expect(await tester.runAsync(() => result), isFalse);
    },
  );

  _testAppleWidgets('Android returns false without making a native call', (
    WidgetTester tester,
  ) async {
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_symbolChannel, (MethodCall call) async {
          calls++;
          return _validPng;
        });
    final BuildContext context = await _mountContext(tester);
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    expect(
      await AppleLiquidSymbol.precache(context, 'precache-android-unique'),
      isFalse,
    );
    expect(calls, 0);
  });

  _testAppleWidgets('validates name and finite supported size', (
    WidgetTester tester,
  ) async {
    final BuildContext context = await _mountContext(tester);
    await expectLater(
      AppleLiquidSymbol.precache(context, ''),
      throwsArgumentError,
    );
    for (final double size in <double>[
      0,
      -1,
      double.infinity,
      double.nan,
      513,
    ]) {
      await expectLater(
        AppleLiquidSymbol.precache(
          context,
          'precache-validation-unique',
          size: size,
        ),
        throwsArgumentError,
      );
    }
  });

  _testAppleWidgets('unsupported DPR returns false without a native call', (
    WidgetTester tester,
  ) async {
    var calls = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_symbolChannel, (MethodCall call) async {
          calls++;
          return _validPng;
        });
    final BuildContext context = await _mountContext(tester, dpr: 5);

    expect(
      await AppleLiquidSymbol.precache(context, 'precache-dpr-unique'),
      isFalse,
    );
    expect(calls, 0);
  });
}
