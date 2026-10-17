import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';

void main() {
  for (final TargetPlatform platform in <TargetPlatform>[
    TargetPlatform.macOS,
    TargetPlatform.windows,
    TargetPlatform.linux,
    TargetPlatform.fuchsia,
    TargetPlatform.android,
  ]) {
    testWidgets('UI platform boundary on ${platform.name}', (
      WidgetTester tester,
    ) async {
      debugDefaultTargetPlatformOverride = platform;
      final AppleLiquidSheetController controller =
          AppleLiquidSheetController();

      try {
        final Map<String, Widget> widgets = <String, Widget>{
          'tab bar': AppleLiquidTabBar(
            currentIndex: 0,
            onChanged: (_) {},
            items: const <AppleLiquidTabItem>[
              AppleLiquidTabItem(title: 'Home', systemImage: 'house'),
            ],
            searchItem: const AppleLiquidTabItem(
              title: 'Search',
              systemImage: 'magnifyingglass',
              isSearch: true,
            ),
          ),
          'switch': AppleLiquidSwitch(value: false, onChanged: (_) {}),
          'slider': AppleLiquidSlider(value: 0.5, onChanged: (_) {}),
          'symbol': const AppleLiquidSymbol('star', fallbackIcon: Icons.star),
          'surface': const AppleLiquidSurface(child: Text('Surface')),
          'concentric rectangle': const AppleConcentricRectangle(
            color: Colors.blue,
          ),
          'stretch': const AppleLiquidStretch(child: Text('Stretch')),
          'sheet guard': AppleLiquidSheetBackgroundInteractionGuard(
            controller: controller,
            child: const Text('Guarded'),
          ),
        };

        for (final MapEntry<String, Widget> entry in widgets.entries) {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(body: Center(child: entry.value)),
            ),
          );
          final Object? exception = tester.takeException();

          if (!kIsWeb && platform == TargetPlatform.android) {
            expect(exception, isNull, reason: entry.key);
            expect(find.byWidget(entry.value), findsOneWidget);
          } else {
            expect(exception, isA<UnsupportedError>(), reason: entry.key);
            expect(exception.toString(), contains('Desktop and web'));
          }

          await tester.pumpWidget(const SizedBox.shrink());
        }

        expect(
          (await AppleLiquidSheet.showSheet()).status,
          AppleLiquidSheetResultStatus.notPresented,
        );
        expect(await AppleLiquidToast.show(title: 'Unavailable'), isFalse);
      } finally {
        controller.dispose();
        debugDefaultTargetPlatformOverride = null;
      }
    });
  }
}
