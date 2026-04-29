import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('AppleLiquidTabItem serializes to platform arguments', () {
    const AppleLiquidTabItem item = AppleLiquidTabItem(
      title: 'Search',
      systemImage: 'plus',
      activeSystemImage: 'plus.circle.fill',
      isSearch: true,
    );

    expect(item.toMap(), <String, Object?>{
      'title': 'Search',
      'systemImage': 'plus',
      'activeSystemImage': 'plus.circle.fill',
      'isSearch': true,
    });
  });

  testWidgets('uses a tappable Flutter fallback outside iOS', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    int selectedIndex = 0;

    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppleLiquidTabBar(
              currentIndex: selectedIndex,
              onChanged: (int index) {
                selectedIndex = index;
              },
              items: const <AppleLiquidTabItem>[
                AppleLiquidTabItem(title: 'Home', systemImage: 'house.fill'),
                AppleLiquidTabItem(
                  title: 'Jobs',
                  systemImage: 'briefcase.fill',
                ),
                AppleLiquidTabItem(title: 'Chat', systemImage: 'message.fill'),
              ],
              searchItem: const AppleLiquidTabItem(
                title: 'Search',
                systemImage: 'plus',
                isSearch: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Jobs'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);

      await tester.tap(find.text('Jobs'));

      expect(selectedIndex, 1);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('uses Flutter fallbacks for switch, slider, and surface', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    bool switchValue = false;
    double sliderValue = 0.25;

    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: <Widget>[
                AppleLiquidSwitch(
                  value: switchValue,
                  onChanged: (bool value) {
                    switchValue = value;
                  },
                ),
                AppleLiquidSlider(
                  value: sliderValue,
                  step: 0.25,
                  onChanged: (double value) {
                    sliderValue = value;
                  },
                ),
                const AppleLiquidSurface(child: Text('Surface child')),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Switch), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('Surface child'), findsOneWidget);
      expect(tester.widget<Slider>(find.byType(Slider)).divisions, 4);

      await tester.tap(find.byType(Switch));

      expect(switchValue, isTrue);
      expect(sliderValue, 0.25);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('AppleLiquidStretch keeps wrapped content interactive', (
    WidgetTester tester,
  ) async {
    int taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppleLiquidStretch(
              child: GestureDetector(
                onTap: () {
                  taps += 1;
                },
                child: const SizedBox(
                  width: 160,
                  height: 80,
                  child: Center(child: Text('Stretch child')),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Stretch child'));
    await tester.drag(find.text('Stretch child'), const Offset(32, 6));
    await tester.pumpAndSettle();

    expect(taps, 1);
    expect(find.text('Stretch child'), findsOneWidget);
  });

  testWidgets(
    'AppleLiquidStretch gestureDetector mode lets taps pass through',
    (WidgetTester tester) async {
      int taps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppleLiquidStretch(
                gestureMode: AppleLiquidStretchGestureMode.gestureDetector,
                child: GestureDetector(
                  onTap: () {
                    taps += 1;
                  },
                  child: const SizedBox(
                    width: 160,
                    height: 80,
                    child: Center(child: Text('Button-like child')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final TestGesture tapGesture = await tester.startGesture(
        tester.getCenter(find.text('Button-like child')),
      );
      await tester.pump();

      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);

      await tapGesture.up();
      await tester.pumpAndSettle();

      expect(taps, 1);

      final TestGesture dragGesture = await tester.startGesture(
        tester.getCenter(find.text('Button-like child')),
      );
      await dragGesture.moveBy(const Offset(36, 0));
      await tester.pump();

      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        greaterThan(1),
      );

      await dragGesture.up();
      await tester.pumpAndSettle();
    },
  );
}
