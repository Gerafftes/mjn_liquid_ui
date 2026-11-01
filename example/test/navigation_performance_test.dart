import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';
import 'package:mjn_liquid_ui_example/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final creates = <Map>[];
  final disposals = <Object?>[];
  final symbols = <String>[];
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR4nGNgAAIAAAUAAXpeqz8AAAAASUVORK5CYII=',
  );
  setUp(() {
    creates.clear();
    disposals.clear();
    symbols.clear();
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, (
      call,
    ) async {
      if (call.method == 'create') creates.add(call.arguments as Map);
      if (call.method == 'dispose') disposals.add(call.arguments);
      return null;
    });
    messenger.setMockMethodCallHandler(
      const MethodChannel('mjn_liquid_ui/symbols'),
      (call) async {
        symbols.add((call.arguments as Map)['name'] as String);
        return png;
      },
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('mjn_liquid_ui/toasts'),
      (call) async => false,
    );
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, null);
    messenger.setMockMethodCallHandler(
      const MethodChannel('mjn_liquid_ui/symbols'),
      null,
    );
    messenger.setMockMethodCallHandler(
      const MethodChannel('mjn_liquid_ui/toasts'),
      null,
    );
  });
  void nativeTest(String name, WidgetTesterCallback body) {
    testWidgets(name, (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      try {
        await body(tester);
      } finally {
        await tester.pumpWidget(const SizedBox());
        await tester.pump();
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }

  Future<void> select(WidgetTester tester, int index) async {
    tester
        .widget<AppleLiquidTabBar>(find.byType(AppleLiquidTabBar))
        .onChanged(index);
    await tester.pumpAndSettle();
  }

  nativeTest(
    'returning to a visited tab preserves its native views and local state',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      final initialCreates = creates.length;
      await select(tester, 1);
      final switchCreates = creates.length;
      await select(tester, 0);
      final backCreates = creates.length;
      await select(tester, 1);
      final repeatCreates = creates.length;
      // ignore: avoid_print
      print(
        'MJN_NATIVE_CHURN initial=$initialCreates firstSwitch=$switchCreates back=$backCreates repeated=$repeatCreates disposed=${disposals.length}',
      );
      expect(
        backCreates,
        switchCreates,
        reason: 'Returning must not rebuild native controls',
      );
      expect(repeatCreates, switchCreates);
      expect(disposals, isEmpty);
    },
  );
  nativeTest(
    'first viewport leaves offscreen native cards and symbols unmounted',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      // ignore: avoid_print
      print(
        'MJN_INITIAL_TYPES ${creates.map((c) => c['viewType']).toList()} symbols=$symbols',
      );
      expect(
        creates.where((c) => c['viewType'] == 'mjn_liquid_ui_surface'),
        hasLength(3),
        reason: 'The fourth glass card is beyond the viewport and cache',
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is AppleLiquidSymbol && widget.name == 'headphones',
        ),
        findsNothing,
        reason: 'Offscreen symbol grid should not rasterize on entry',
      );
      await select(tester, 1);
      expect(
        creates.where((c) => c['viewType'] == 'mjn_liquid_ui_switch_group'),
        hasLength(1),
      );
      expect(
        creates.where((c) => c['viewType'] == 'mjn_liquid_ui_switch'),
        hasLength(2),
        reason:
            'Only the prefetched sheet toggles are individual native switches',
      );
      expect(
        creates.where((c) => c['viewType'] == 'mjn_liquid_ui_slider').length,
        lessThan(6),
        reason:
            'The inner playground must not eagerly mount all slider controls',
      );
    },
  );
  nativeTest(
    'unvisited tabs stay unmounted and hidden animation tickers stop',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      expect(
        find.byType(AppleLiquidSwitchGroup, skipOffstage: false),
        findsNothing,
      );
      tester
          .widget<AppleLiquidTabBar>(find.byType(AppleLiquidTabBar))
          .onChanged(3);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.transientCallbackCount, greaterThan(0));
      tester
          .widget<AppleLiquidTabBar>(find.byType(AppleLiquidTabBar))
          .onChanged(1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.binding.transientCallbackCount, 0);
      expect(find.byType(AppleLiquidSwitchGroup), findsOneWidget);
      await tester.pumpAndSettle();
    },
  );
  nativeTest(
    'scrolling back to a visited card does not recreate its native view',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      final list = find.byKey(const PageStorageKey<String>('demo-page-Tabbar'));
      final scrollable = tester.state<ScrollableState>(
        find.descendant(of: list, matching: find.byType(Scrollable)).first,
      );
      for (int i = 0; i < 3; i++) {
        scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
        await tester.pumpAndSettle();
      }
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is AppleLiquidSymbol && widget.name == 'headphones',
        ),
        findsOneWidget,
      );
      final loadedCreates = creates.length;
      scrollable.position.jumpTo(0);
      await tester.pumpAndSettle();
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pumpAndSettle();
      expect(creates.length, loadedCreates);
      expect(disposals, isEmpty);
    },
  );
  nativeTest('inner playground retains visited native controls when scrolling', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    await select(tester, 1);
    final list = find.byKey(
      const PageStorageKey<String>('concentric-controls'),
    );
    final scrollable = tester.state<ScrollableState>(
      find.descendant(of: list, matching: find.byType(Scrollable)).first,
    );
    for (int i = 0; i < 3; i++) {
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pumpAndSettle();
    }
    final loaded = creates.length;
    final disposed = disposals.length;
    scrollable.position.jumpTo(0);
    await tester.pumpAndSettle();
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pumpAndSettle();
    // ignore: avoid_print
    print(
      'INNER_CHURN loaded=$loaded after=${creates.length} disposedBefore=$disposed disposedAfter=${disposals.length}',
    );
    expect(creates.length, loaded);
  });
  ScrollPosition outerPosition(WidgetTester tester, String title) {
    return tester
        .state<ScrollableState>(
          find
              .descendant(
                of: find.byKey(
                  PageStorageKey<String>('demo-page-$title'),
                  skipOffstage: false,
                ),
                matching: find.byType(Scrollable, skipOffstage: false),
                skipOffstage: false,
              )
              .first,
        )
        .position;
  }

  nativeTest(
    'primary keyboard scrolling targets only the active retained tab',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      BuildContext barContext() =>
          tester.element(find.byType(AppleLiquidTabBar));
      final firstController = PrimaryScrollController.of(barContext());
      final firstPosition = outerPosition(tester, 'Tabbar');
      firstPosition.jumpTo(120);
      await tester.pumpAndSettle();
      await select(tester, 1);
      final switchPosition = outerPosition(tester, 'Switch');
      expect(
        () => ScrollAction().invoke(
          const ScrollIntent(direction: AxisDirection.down),
          barContext(),
        ),
        returnsNormally,
      );
      await tester.pumpAndSettle();
      final switchController = PrimaryScrollController.of(barContext());
      expect(switchController.positions, hasLength(1));
      expect(switchController.position, same(switchPosition));
      expect(switchController, isNot(same(firstController)));
      expect(switchPosition.pixels, greaterThan(0));
      expect(firstPosition.pixels, closeTo(120, .1));
      await select(tester, 0);
      expect(PrimaryScrollController.of(barContext()), same(firstController));
      expect(firstController.positions, hasLength(1));
      expect(firstPosition.pixels, closeTo(120, .1));

      tester
          .widget<AppleLiquidTabBar>(find.byType(AppleLiquidTabBar))
          .onChanged(3);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(PrimaryScrollController.of(barContext()).hasClients, isFalse);
      expect(
        ScrollAction().isEnabled(
          const ScrollIntent(direction: AxisDirection.down),
          barContext(),
        ),
        isFalse,
      );
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(firstController.hasClients, isFalse);
      expect(switchController.hasClients, isFalse);
      expect(() => firstController.addListener(() {}), throwsFlutterError);
      expect(() => switchController.addListener(() {}), throwsFlutterError);
    },
  );

  nativeTest('status bar tap preserves the hidden tabs scroll position', (
    tester,
  ) async {
    tester.view.padding = FakeViewPadding(top: 24);
    addTearDown(tester.view.resetPadding);
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    final firstPosition = outerPosition(tester, 'Tabbar');
    firstPosition.jumpTo(120);
    await tester.pumpAndSettle();
    await select(tester, 1);
    final switchPosition = outerPosition(tester, 'Switch');
    switchPosition.jumpTo(200);
    await tester.pumpAndSettle();
    final topPadding = tester.view.padding.top / tester.view.devicePixelRatio;
    expect(topPadding, greaterThan(0));
    await tester.tapAt(Offset(16, topPadding / 2));
    await tester.pumpAndSettle();
    expect(switchPosition.pixels, closeTo(0, .1));
    await select(tester, 0);
    expect(
      firstPosition.pixels,
      closeTo(120, .1),
      reason: 'Status-bar scrolling must not touch a hidden tab',
    );
  });
  nativeTest('page down works from the initial route focus', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();
    final position = outerPosition(tester, 'Tabbar');
    expect(position.pixels, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pumpAndSettle();
    expect(position.pixels, greaterThan(0));
  });
  nativeTest(
    'keyboard routing survives hidden focused controls and route return',
    (tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pumpAndSettle();
      Focus.of(tester.element(find.text('Add toast'))).requestFocus();
      await tester.pumpAndSettle();
      final hiddenPosition = outerPosition(tester, 'Tabbar');
      final hiddenOffset = hiddenPosition.pixels;
      await select(tester, 1);
      final activePosition = outerPosition(tester, 'Switch');
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
      expect(activePosition.pixels, greaterThan(0));
      expect(hiddenPosition.pixels, closeTo(hiddenOffset, .1));
      final activeOffset = activePosition.pixels;
      await tester.tap(find.byTooltip('Performance examples'));
      await tester.pumpAndSettle();
      await tester.pageBack();
      await tester.pumpAndSettle();
      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
      expect(activePosition.pixels, greaterThan(activeOffset));
      expect(hiddenPosition.pixels, closeTo(hiddenOffset, .1));
    },
  );
}
