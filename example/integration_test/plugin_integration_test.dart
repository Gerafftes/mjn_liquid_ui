import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';
import 'package:mjn_liquid_ui/src/apple_liquid_platform_view.dart';

import 'package:mjn_liquid_ui_example/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('iOS demo creates its native tab bar and channel', (
    WidgetTester tester,
  ) async {
    expect(kIsWeb, isFalse);
    expect(defaultTargetPlatform, TargetPlatform.iOS);
    await tester.pumpWidget(const MyApp());

    // Native tab labels are not Flutter Text widgets.
    final Finder tabBarFinder = find.byType(AppleLiquidTabBar);
    final AppleLiquidTabBar tabBar = tester.widget<AppleLiquidTabBar>(
      tabBarFinder,
    );
    expect(tabBar.items.map((item) => item.title), <String>[
      'Tabs',
      'Switch',
      'Slider',
    ]);
    expect(tabBar.searchItem.title, 'Surface');
    expect(tabBar.searchItem.isSearch, isTrue);
    expect(find.text('MJN Liquid UI'), findsOneWidget);

    final Finder nativeTabBar = find.descendant(
      of: tabBarFinder,
      matching: find.byElementPredicate(
        (Element element) =>
            element is RenderObjectElement &&
            element.renderObject is RenderUiKitView,
      ),
    );
    final Stopwatch deadline = Stopwatch()..start();
    while (nativeTabBar.evaluate().isEmpty &&
        deadline.elapsed < const Duration(seconds: 5)) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(tester.takeException(), isNull);
    expect(nativeTabBar, findsOneWidget);

    final RenderUiKitView view = tester.renderObject<RenderUiKitView>(
      nativeTabBar,
    );
    await MethodChannel('mjn_liquid_ui_tabbar/${view.viewController.id}')
        .invokeMethod<void>('setCurrentIndex', <String, Object?>{
          'currentIndex': 0,
        })
        .timeout(const Duration(seconds: 5));
  });

  testWidgets(
    'switch group uses one real native channel and validates updates',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppleLiquidSwitchGroup(
              items: <AppleLiquidSwitchGroupItem>[
                AppleLiquidSwitchGroupItem(
                  id: 'one',
                  label: const Text('One'),
                  semanticLabel: 'One',
                  value: false,
                  onChanged: (_) {},
                ),
                AppleLiquidSwitchGroupItem(
                  id: 'two',
                  label: const Text('Two'),
                  semanticLabel: 'Two',
                  value: true,
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        ),
      );
      final native = find.byElementPredicate(
        (element) =>
            element is RenderObjectElement &&
            element.renderObject is RenderUiKitView,
      );
      final deadline = Stopwatch()..start();
      while (native.evaluate().isEmpty &&
          deadline.elapsed < const Duration(seconds: 5)) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      expect(native, findsOneWidget);
      final view = tester.renderObject<RenderUiKitView>(native);
      final channel = MethodChannel(
        'mjn_liquid_ui_switch_group/${view.viewController.id}',
      );
      await channel.invokeMethod<void>('updateConfiguration', <String, Object?>{
        'rowHeight': 60.0,
        'items': <Object>[
          <String, Object?>{
            'id': 'two',
            'semanticLabel': 'Two',
            'value': false,
          },
          <String, Object?>{'id': 'one', 'semanticLabel': 'One', 'value': true},
        ],
      });
      await expectLater(
        channel.invokeMethod<void>('updateConfiguration', <String, Object?>{
          'rowHeight': 0,
          'items': <Object>[],
        }),
        throwsA(
          isA<PlatformException>().having(
            (error) => error.code,
            'code',
            'invalid_arguments',
          ),
        ),
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );

  testWidgets(
    'symbol precache completes real rasterization and image decoding',
    (tester) async {
      late BuildContext context;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (value) {
              context = value;
              return const SizedBox();
            },
          ),
        ),
      );
      if (!context.mounted) throw StateError('Precache context was removed');
      expect(
        await AppleLiquidSymbol.precache(
          context,
          'star.fill',
          size: 32,
          color: Colors.amber,
        ),
        isTrue,
      );
      if (!context.mounted) throw StateError('Precache context was removed');
      expect(
        await AppleLiquidSymbol.precache(
          context,
          'mjn.symbol.that.does.not.exist',
        ),
        isFalse,
      );
      await tester.pumpWidget(
        const MaterialApp(
          home: AppleLiquidSymbol('star.fill', size: 32, color: Colors.amber),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Image), findsOneWidget);
      expect(tester.widget<RawImage>(find.byType(RawImage)).image, isNotNull);
    },
  );

  testWidgets('deferred surface waits for a real route entrance', (
    tester,
  ) async {
    final navigator = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(navigatorKey: navigator, home: const SizedBox()),
    );
    await tester.pumpAndSettle();
    navigator.currentState!.push<void>(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, animation, secondary) => const Scaffold(
          body: AppleLiquidSurface(
            deferMountUntilRouteTransitionCompletes: true,
            child: Text('Deferred content'),
          ),
        ),
      ),
    );
    await tester.pump();
    final native = find.byElementPredicate(
      (element) =>
          element is RenderObjectElement &&
          element.renderObject is RenderUiKitView,
    );
    await tester.pump(const Duration(milliseconds: 100));
    expect(native, findsNothing);
    await tester.pumpAndSettle();
    final deadline = Stopwatch()..start();
    while (native.evaluate().isEmpty &&
        deadline.elapsed < const Duration(seconds: 5)) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(native, findsOneWidget);
    expect(find.text('Deferred content'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('example reuses real native views when revisiting tabs', (
    tester,
  ) async {
    final native = find.byElementPredicate(
      (element) =>
          element is RenderObjectElement &&
          element.renderObject is RenderUiKitView,
    );
    Future<Set<int>> readyIDs() async {
      final deadline = Stopwatch()..start();
      while (deadline.elapsed < const Duration(seconds: 8)) {
        await tester.pump(const Duration(milliseconds: 50));
        if (native.evaluate().length ==
            find.byType(AppleLiquidUiKitView).evaluate().length) {
          return native
              .evaluate()
              .map(
                (element) =>
                    (element as RenderObjectElement).renderObject
                        as RenderUiKitView,
              )
              .map((view) => view.viewController.id)
              .toSet();
        }
      }
      throw StateError('Native demo views did not become ready');
    }

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    final firstIDs = await readyIDs();
    expect(firstIDs, isNotEmpty);
    tester
        .widget<AppleLiquidTabBar>(find.byType(AppleLiquidTabBar))
        .onChanged(1);
    await tester.pumpAndSettle();
    final switchIDs = await readyIDs();
    tester
        .widget<AppleLiquidTabBar>(find.byType(AppleLiquidTabBar))
        .onChanged(0);
    await tester.pumpAndSettle();
    expect(await readyIDs(), firstIDs);
    tester
        .widget<AppleLiquidTabBar>(find.byType(AppleLiquidTabBar))
        .onChanged(1);
    await tester.pumpAndSettle();
    expect(await readyIDs(), switchIDs);
    await tester.pumpWidget(const SizedBox());
  });
}
