import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';

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
}
