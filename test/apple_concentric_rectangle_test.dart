import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';

void main() {
  test('mirrors SwiftUI corner grouping constructors', () {
    const AppleConcentricCornerStyle fixed24 = AppleConcentricCornerStyle.fixed(
      24,
    );
    const AppleConcentricCornerStyle minimum12 =
        AppleConcentricCornerStyle.concentric(minimumRadius: 12);

    const AppleConcentricRectangleCorners corners =
        AppleConcentricRectangleCorners.uniformTopAndBottom(
          uniformTopCorners: fixed24,
          uniformBottomCorners: minimum12,
        );

    expect(
      corners.grouping,
      AppleConcentricRectangleCornerGrouping.topAndBottom,
    );
    expect(corners.topLeadingCorner, fixed24);
    expect(corners.topTrailingCorner, fixed24);
    expect(corners.bottomLeadingCorner, minimum12);
    expect(corners.bottomTrailingCorner, minimum12);
  });

  testWidgets('renders Flutter content over the non-iOS fallback', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    try {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: AppleConcentricRectangle(
              width: 180,
              height: 100,
              color: Color(0xFF34C759),
              inset: 8,
              containerCornerRadius: 32,
              padding: EdgeInsets.all(12),
              child: Text('Concentric'),
            ),
          ),
        ),
      );

      expect(find.text('Concentric'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(AppleConcentricRectangle),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byType(AppleConcentricRectangle)),
        const Size(180, 100),
      );
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('rejects non-finite dimensions outside debug assertions', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            return AppleConcentricRectangle(
              width: double.infinity,
              height: 100,
              color: Colors.green,
            );
          },
        ),
      ),
    );

    expect(tester.takeException(), isA<ArgumentError>());
  });
}
