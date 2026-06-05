import 'dart:async';
import 'dart:convert';

import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const MethodChannel symbolChannel = MethodChannel('mjn_liquid_ui/symbols');
  const MethodChannel sheetChannel = MethodChannel('mjn_liquid_ui/sheets');
  final Uint8List transparentPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAFgwJ/lv5Q9wAAAABJRU5ErkJggg==',
  );

  test('AppleLiquidTabItem serializes to platform arguments', () {
    const AppleLiquidTabItem item = AppleLiquidTabItem(
      title: 'Search',
      systemImage: 'plus',
      activeSystemImage: 'plus.circle.fill',
      symbolWeight: AppleLiquidSymbolWeight.regular,
      activeSymbolWeight: AppleLiquidSymbolWeight.bold,
      isSearch: true,
      notificationDotColor: Color(0xFFEF4444),
      notificationBadgeValue: '3',
    );

    expect(item.toMap(), <String, Object?>{
      'title': 'Search',
      'systemImage': 'plus',
      'activeSystemImage': 'plus.circle.fill',
      'symbolWeight': 'regular',
      'activeSymbolWeight': 'bold',
      'isSearch': true,
      'notificationDotColor': 0xFFEF4444,
      'notificationBadgeValue': '3',
    });
  });

  test('AppleLiquidSheetContent serializes to platform arguments', () {
    const AppleLiquidSheetContent content = AppleLiquidSheetContent(
      title: 'Project',
      doneSemanticLabel: 'Close sheet',
      sections: <AppleLiquidSheetSection>[
        AppleLiquidSheetSection(
          title: 'Overview',
          rows: <AppleLiquidSheetRow>[
            AppleLiquidSheetRow.value(
              title: 'Name',
              value: 'mjn_liquid_ui',
              systemImage: 'shippingbox.fill',
            ),
            AppleLiquidSheetRow.toggle(title: 'Enabled', value: true),
            AppleLiquidSheetRow.picker(
              title: 'Theme',
              options: <String>['Auto', 'Light', 'Dark'],
              selectedOption: 'Auto',
            ),
            AppleLiquidSheetRow.navigation(
              title: 'Details',
              content: AppleLiquidSheetContent(
                title: 'Details',
                sections: <AppleLiquidSheetSection>[
                  AppleLiquidSheetSection(
                    rows: <AppleLiquidSheetRow>[
                      AppleLiquidSheetRow.textField(
                        title: 'Label',
                        value: 'Liquid',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );

    expect(content.toMap(), <String, Object?>{
      'title': 'Project',
      'doneSemanticLabel': 'Close sheet',
      'sections': <Object?>[
        <String, Object?>{
          'title': 'Overview',
          'rows': <Object?>[
            <String, Object?>{
              'type': 'value',
              'title': 'Name',
              'value': 'mjn_liquid_ui',
              'systemImage': 'shippingbox.fill',
            },
            <String, Object?>{
              'type': 'toggle',
              'title': 'Enabled',
              'boolValue': true,
            },
            <String, Object?>{
              'type': 'picker',
              'title': 'Theme',
              'options': <String>['Auto', 'Light', 'Dark'],
              'selectedOption': 'Auto',
            },
            <String, Object?>{
              'type': 'navigation',
              'title': 'Details',
              'content': <String, Object?>{
                'title': 'Details',
                'doneSemanticLabel': 'Done',
                'sections': <Object?>[
                  <String, Object?>{
                    'rows': <Object?>[
                      <String, Object?>{
                        'type': 'textField',
                        'title': 'Label',
                        'value': 'Liquid',
                      },
                    ],
                  },
                ],
              },
            },
          ],
        },
      ],
    });
  });

  test('AppleLiquidSheet returns false outside iOS', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    try {
      expect(
        await AppleLiquidSheet.showTemplateSheet(
          heightFraction: 0.72,
          backgroundZoomScale: 0.94,
        ),
        isFalse,
      );
      expect(await AppleLiquidSheet.dismissTemplateSheet(), isFalse);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('AppleLiquidSheetController returns false outside iOS', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    final AppleLiquidSheetController controller = AppleLiquidSheetController(
      heightFraction: 0.72,
      backgroundZoomScale: 0.94,
      sheetColor: const Color(0xFFEAF3FF),
    );

    try {
      expect(await controller.showTemplateSheet(), isFalse);
      expect(await controller.dismiss(), isFalse);
      expect(controller.isShowing, isFalse);
      expect(controller.isShown, isFalse);
    } finally {
      controller.dispose();
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('AppleLiquidSheetController tracks native presentation state', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final Completer<bool> showCompleter = Completer<bool>();
    final List<MethodCall> calls = <MethodCall>[];
    const AppleLiquidSheetContent content = AppleLiquidSheetContent(
      title: 'Project',
      sections: <AppleLiquidSheetSection>[
        AppleLiquidSheetSection(
          rows: <AppleLiquidSheetRow>[
            AppleLiquidSheetRow.value(title: 'Name', value: 'mjn_liquid_ui'),
          ],
        ),
      ],
    );
    final AppleLiquidSheetController controller = AppleLiquidSheetController(
      heightFraction: 0.72,
      backgroundZoomScale: 0.94,
      sheetColor: const Color(0xFFEAF3FF),
      content: content,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sheetChannel, (MethodCall call) async {
          calls.add(call);

          switch (call.method) {
            case 'showTemplateSheet':
              return showCompleter.future;
            case 'dismissTemplateSheet':
              if (!showCompleter.isCompleted) {
                showCompleter.complete(true);
              }
              return true;
            default:
              return null;
          }
        });

    try {
      final Future<bool> showFuture = controller.showSheet();
      await Future<void>.delayed(Duration.zero);

      expect(controller.isShowing, isTrue);
      expect(controller.isShown, isTrue);
      expect(calls, hasLength(1));
      expect(calls.single.method, 'showTemplateSheet');
      expect(calls.single.arguments, containsPair('heightFraction', 0.72));
      expect(calls.single.arguments, containsPair('backgroundZoomScale', 0.94));
      expect(calls.single.arguments, containsPair('sheetColor', 0xFFEAF3FF));
      expect(calls.single.arguments, containsPair('content', content.toMap()));

      expect(await controller.showSheet(), isTrue);
      expect(calls, hasLength(1));

      expect(await controller.dismiss(), isTrue);
      expect(await showFuture, isTrue);
      expect(controller.isShowing, isFalse);
      expect(controller.isShown, isFalse);
      expect(calls.map((MethodCall call) => call.method), <String>[
        'showTemplateSheet',
        'dismissTemplateSheet',
      ]);
    } finally {
      controller.dispose();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(sheetChannel, null);
    }
  });

  test('AppleLiquidSheet ignores duplicate native show requests', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final Completer<bool> showCompleter = Completer<bool>();
    final List<MethodCall> calls = <MethodCall>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sheetChannel, (MethodCall call) async {
          calls.add(call);

          switch (call.method) {
            case 'showTemplateSheet':
              return showCompleter.future;
            default:
              return null;
          }
        });

    try {
      final Future<bool> showFuture = AppleLiquidSheet.showSheet();
      await Future<void>.delayed(Duration.zero);

      expect(calls, hasLength(1));
      expect(await AppleLiquidSheet.showSheet(), isTrue);
      expect(calls, hasLength(1));

      showCompleter.complete(true);
      expect(await showFuture, isTrue);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(sheetChannel, null);
    }
  });

  testWidgets('AppleLiquidSymbol uses an Icon fallback outside iOS', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    try {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: AppleLiquidSymbol(
              'sparkles',
              size: 32,
              color: Color(0xFF0EA5E9),
              weight: AppleLiquidSymbolWeight.semibold,
              fallbackIcon: Icons.auto_awesome_rounded,
              semanticLabel: 'Highlights',
            ),
          ),
        ),
      );

      final Icon icon = tester.widget<Icon>(
        find.byIcon(Icons.auto_awesome_rounded),
      );

      expect(icon.size, 32);
      expect(icon.color, const Color(0xFF0EA5E9));
      expect(icon.weight, AppleLiquidSymbolWeight.semibold.fallbackIconWeight);
      expect(icon.semanticLabel, 'Highlights');
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
    'AppleLiquidSymbol paints native bytes as a Flutter image on iOS',
    (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final List<MethodCall> calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(symbolChannel, (MethodCall call) async {
            calls.add(call);
            return transparentPng;
          });

      try {
        await tester.pumpWidget(
          const MaterialApp(
            home: Center(
              child: AppleLiquidSymbol(
                'sparkles',
                size: 32,
                color: Color(0xFF0EA5E9),
                weight: AppleLiquidSymbolWeight.heavy,
                fallbackIcon: Icons.auto_awesome_rounded,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(Image), findsOneWidget);
        expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing);
        expect(calls, hasLength(1));
        expect(calls.single.method, 'render');
        expect(calls.single.arguments, containsPair('name', 'sparkles'));
        expect(calls.single.arguments, containsPair('size', 32.0));
        expect(calls.single.arguments, containsPair('color', 0xFF0EA5E9));
        expect(calls.single.arguments, containsPair('weight', 'heavy'));
      } finally {
        debugDefaultTargetPlatformOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(symbolChannel, null);
      }
    },
  );

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
              selectedTintColor: const Color(0xFF0EA5E9),
              onChanged: (int index) {
                selectedIndex = index;
              },
              items: const <AppleLiquidTabItem>[
                AppleLiquidTabItem(title: 'Home', systemImage: 'house.fill'),
                AppleLiquidTabItem(
                  title: 'Jobs',
                  systemImage: 'briefcase.fill',
                ),
                AppleLiquidTabItem(
                  title: 'Chat',
                  systemImage: 'message.fill',
                  notificationDotColor: Color(0xFFEF4444),
                  notificationBadgeValue: '3',
                ),
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
      expect(
        tester
            .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
            .selectedItemColor,
        const Color(0xFF0EA5E9),
      );
      expect(
        find.byWidgetPredicate((Widget widget) {
          final Decoration? decoration = widget is DecoratedBox
              ? widget.decoration
              : null;

          return decoration is BoxDecoration &&
              decoration.shape == BoxShape.circle &&
              decoration.color == const Color(0xFFEF4444);
        }),
        findsAtLeastNWidgets(1),
      );
      expect(find.text('3'), findsOneWidget);

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
