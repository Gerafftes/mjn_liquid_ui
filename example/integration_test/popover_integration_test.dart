import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late AppleLiquidPopoverController controller;
  late Future<AppleLiquidSheetResult> presentation;

  Widget harness({required bool animated}) => MaterialApp(
    home: Scaffold(
      body: Center(
        child: AppleLiquidPopoverAnchor(
          builder: (context, value) {
            controller = value;
            return FilledButton(
              onPressed: () {
                presentation = value.show(
                  options: AppleLiquidPopoverOptions(
                    width: 280,
                    height: 240,
                    animated: animated,
                    compactBehavior: AppleLiquidPopoverCompactBehavior.popover,
                  ),
                  content: const AppleLiquidPopoverContent(
                    title: 'Integration content',
                    sections: [
                      AppleLiquidSheetSection(
                        rows: [
                          AppleLiquidSheetRow.textField(
                            identifier: 'consumer-field',
                            title: 'Consumer field',
                            value: 'Consumer initial value',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Open native popover'),
            );
          },
        ),
      ),
    ),
  );

  testWidgets(
    'registered plugin presents and dismisses native consumer content',
    (tester) async {
      expect(kIsWeb, isFalse);
      expect(defaultTargetPlatform, TargetPlatform.iOS);
      await tester.pumpWidget(harness(animated: false));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open native popover'));
      final result = await tester.runAsync(() async {
        // Give UIKit its presentation turn without depending on Flutter frames.
        await Future<void>.delayed(const Duration(milliseconds: 200));
        expect(controller.isShowing, isTrue);
        await binding.takeScreenshot('native-popover');
        expect(
          await controller.dismiss().timeout(const Duration(seconds: 5)),
          isTrue,
        );
        return presentation.timeout(const Duration(seconds: 5));
      });
      expect(result, isNotNull);
      expect(result!.status, AppleLiquidSheetResultStatus.cancelled);
      expect(
        result.textField('consumer-field')?.value,
        'Consumer initial value',
      );
      expect(controller.isShowing, isFalse);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'removing the anchor while native presentation animates completes dismissal',
    (tester) async {
      await tester.pumpWidget(harness(animated: true));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Open native popover'));
      // Removal sends the same session's dismissal immediately after showPopover,
      // before waiting for UIKit's presentation animation to finish.
      await tester.pumpWidget(const SizedBox());
      final result = await tester.runAsync(
        () => presentation.timeout(const Duration(seconds: 8)),
      );
      expect(result, isNotNull);
      expect(result!.status, AppleLiquidSheetResultStatus.cancelled);
      expect(
        result.textField('consumer-field')?.value,
        'Consumer initial value',
      );
      expect(controller.isShowing, isFalse);
      await tester.pump();
      expect(tester.takeException(), isNull);
    },
  );
}
