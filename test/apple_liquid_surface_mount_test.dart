import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';
import 'package:mjn_liquid_ui/src/apple_liquid_platform_view.dart';

void main() {
  final List<MethodCall> creates = <MethodCall>[];
  Completer<void>? pendingCreation;

  setUp(() {
    creates.clear();
    pendingCreation = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform_views, (call) async {
          if (call.method == 'create') {
            creates.add(call);
            await pendingCreation?.future;
          }
          return null;
        });
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform_views, null);
  });

  void surfaceTest(String name, WidgetTesterCallback callback) {
    testWidgets(name, (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        await callback(tester);
      } finally {
        await tester.pumpWidget(const SizedBox());
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  Widget surface({bool deferred = true, Widget? child, Color? tint}) {
    return AppleLiquidSurface(
      deferMountUntilRouteTransitionCompletes: deferred,
      tintColor: tint,
      child: child,
    );
  }

  surfaceTest('default still creates immediately; deferred waits one frame', (
    tester,
  ) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: surface(deferred: false),
      ),
    );
    expect(creates, hasLength(1));
    await tester.pumpWidget(const SizedBox());
    creates.clear();
    await tester.pumpWidget(
      Directionality(textDirection: TextDirection.ltr, child: surface()),
    );
    expect(creates, isEmpty);
    await tester.pump();
    expect(creates, hasLength(1));
    await tester.pumpWidget(const SizedBox());
  });

  surfaceTest('waits for entrance and preserves child state and layout', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    final probe = GlobalKey<_ProbeState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigator, home: const SizedBox()),
    );
    unawaited(
      navigator.currentState!.push<void>(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, animation, secondary) => Scaffold(
            body: surface(child: _Probe(key: probe)),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    final state = probe.currentState!;
    final Size size = tester.getSize(find.byType(AppleLiquidSurface));
    expect(creates, isEmpty);
    expect(find.byType(BackdropFilter), findsNothing);
    await tester.pump(const Duration(milliseconds: 200));
    expect(creates, isEmpty);
    await tester.pump(const Duration(milliseconds: 200));
    expect(creates, isEmpty);
    await tester.pumpAndSettle();
    expect(creates, hasLength(1));
    expect(probe.currentState, same(state));
    expect(tester.getSize(find.byType(AppleLiquidSurface)), size);
    // Once mounted it stays mounted during later navigation.
    unawaited(
      navigator.currentState!.push<void>(
        MaterialPageRoute<void>(builder: (_) => const SizedBox()),
      ),
    );
    await tester.pumpAndSettle();
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(creates, hasLength(1));
    await tester.pumpWidget(const SizedBox());
  });

  surfaceTest('pop during entrance never creates a native surface', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigator, home: const SizedBox()),
    );
    unawaited(
      navigator.currentState!.push<void>(
        PageRouteBuilder<void>(
          transitionDuration: const Duration(milliseconds: 400),
          reverseTransitionDuration: const Duration(milliseconds: 400),
          pageBuilder: (_, animation, secondary) => Scaffold(body: surface()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    navigator.currentState!.pop();
    await tester.pumpAndSettle();
    expect(creates, isEmpty);
    expect(tester.takeException(), isNull);
  });

  surfaceTest(
    'pop after completion but before the native build cancels mounting',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(navigatorKey: navigator, home: const SizedBox()),
      );
      unawaited(
        navigator.currentState!.push<void>(
          PageRouteBuilder<void>(
            transitionDuration: const Duration(milliseconds: 400),
            pageBuilder: (_, animation, secondary) => Scaffold(body: surface()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(creates, isEmpty);
      navigator.currentState!.pop();
      await tester.pumpAndSettle();
      expect(creates, isEmpty);
      expect(tester.takeException(), isNull);
    },
  );

  surfaceTest(
    'cancelled reverse transition can resume a postponed native mount',
    (tester) async {
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(navigatorKey: navigator, home: const SizedBox()),
      );
      final route = _ControlledRoute(Scaffold(body: surface()));
      unawaited(navigator.currentState!.push<void>(route));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(creates, isEmpty);
      unawaited(route.testController.reverse());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(creates, isEmpty);
      unawaited(route.testController.forward());
      await tester.pumpAndSettle();
      expect(creates, hasLength(1));
    },
  );

  surfaceTest('TickerMode gates creation and latest config reaches native', (
    tester,
  ) async {
    Widget host(bool enabled, Color tint) => MaterialApp(
      home: TickerMode(
        enabled: enabled,
        child: surface(tint: tint),
      ),
    );
    await tester.pumpWidget(host(false, Colors.red));
    await tester.pump();
    expect(creates, isEmpty);
    await tester.pumpWidget(host(true, Colors.blue));
    expect(creates, isEmpty);
    await tester.pumpAndSettle();
    expect(creates, hasLength(1));
    final arguments = creates.single.arguments as Map;
    final params =
        const StandardMessageCodec().decodeMessage(
              ByteData.sublistView(arguments['params'] as Uint8List),
            )
            as Map;
    expect(params['tintColor'], Colors.blue.toARGB32());
    await tester.pumpWidget(const SizedBox());
  });

  surfaceTest('placeholder remains until async native creation finishes', (
    tester,
  ) async {
    pendingCreation = Completer<void>();
    await tester.pumpWidget(MaterialApp(home: surface()));
    await tester.pump();
    final background = find
        .ancestor(
          of: find.byType(AppleLiquidUiKitView),
          matching: find.byType(Stack),
        )
        .first;
    expect(tester.widget<Stack>(background).children, hasLength(2));
    pendingCreation!.complete();
    await tester.pumpAndSettle();
    expect(tester.widget<Stack>(background).children, hasLength(1));
    await tester.pumpWidget(const SizedBox());
  });

  surfaceTest('unmount invalidates scheduled mount and pending creation', (
    tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: surface()));
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
    expect(creates, isEmpty);

    pendingCreation = Completer<void>();
    await tester.pumpWidget(MaterialApp(home: surface()));
    await tester.pump();
    expect(creates, hasLength(1));
    await tester.pumpWidget(const SizedBox());
    pendingCreation!.complete();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  surfaceTest('changing defer option starts mount without remounting child', (
    tester,
  ) async {
    final probe = GlobalKey<_ProbeState>();
    Widget host(bool defer) => MaterialApp(
      home: TickerMode(
        enabled: false,
        child: surface(
          deferred: defer,
          child: _Probe(key: probe),
        ),
      ),
    );
    await tester.pumpWidget(host(true));
    final state = probe.currentState;
    expect(creates, isEmpty);
    await tester.pumpWidget(host(false));
    await tester.pump();
    expect(creates, hasLength(1));
    expect(probe.currentState, same(state));
    await tester.pumpWidget(const SizedBox());
  });

  surfaceTest('Android keeps its existing background without native creation', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    await tester.pumpWidget(
      MaterialApp(home: surface(child: const Text('child'))),
    );
    await tester.pumpAndSettle();
    expect(find.text('child'), findsOneWidget);
    expect(find.byType(BackdropFilter), findsOneWidget);
    expect(creates, isEmpty);
  });
}

class _Probe extends StatefulWidget {
  const _Probe({super.key});

  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  Widget build(BuildContext context) => const Text('Stateful content');
}

class _ControlledRoute extends PageRouteBuilder<void> {
  _ControlledRoute(Widget child)
    : super(
        transitionDuration: const Duration(milliseconds: 400),
        reverseTransitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (_, animation, secondary) => child,
      );

  AnimationController get testController => controller!;
}
