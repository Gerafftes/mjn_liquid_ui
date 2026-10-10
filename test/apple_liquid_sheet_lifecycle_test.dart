import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';

const MethodChannel _channel = MethodChannel('mjn_liquid_ui/sheets');

Future<void> _send(String method, Map<String, Object?> arguments) async {
  final ByteData message = const StandardMethodCodec().encodeMethodCall(
    MethodCall(method, arguments),
  );
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(_channel.name, message, (_) {});
}

List<Map<Object?, Object?>> _rows(MethodCall call) {
  final arguments = call.arguments as Map<Object?, Object?>;
  final content = arguments['content'] as Map<Object?, Object?>;
  final sections = content['sections'] as List<Object?>;
  final section = sections.single as Map<Object?, Object?>;
  return (section['rows'] as List<Object?>).cast<Map<Object?, Object?>>();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  for (final Object failure in <Object>[
    PlatformException(code: 'presentation_failed', message: 'Test failure'),
    MissingPluginException('Test plugin unavailable'),
  ]) {
    test('${failure.runtimeType} cleans callbacks and permits retry', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final List<List<Map<Object?, Object?>>> payloads = [];
      final List<String> oldText = [];
      final List<String> newText = [];
      int oldButtons = 0;
      int newButtons = 0;
      final Completer<Object?> nativeResult = Completer<Object?>();
      final Completer<void> retryReachedNative = Completer<void>();
      Future<AppleLiquidSheetResult>? retry;

      AppleLiquidSheetContent content(
        VoidCallback onButton,
        ValueChanged<String> onText,
      ) => AppleLiquidSheetContent(
        sections: <AppleLiquidSheetSection>[
          AppleLiquidSheetSection(
            rows: <AppleLiquidSheetRow>[
              AppleLiquidSheetRow.button(title: 'Action', onPressed: onButton),
              AppleLiquidSheetRow.textField(
                identifier: 'title',
                title: 'Title',
                value: 'Initial',
                onChanged: onText,
              ),
            ],
          ),
        ],
      );

      messenger.setMockMethodCallHandler(_channel, (MethodCall call) async {
        expect(call.method, 'showTemplateSheet');
        payloads.add(_rows(call));
        if (payloads.length == 1) throw failure;
        retryReachedNative.complete();
        return nativeResult.future;
      });

      try {
        await expectLater(
          AppleLiquidSheet.showSheet(
            content: content(() => oldButtons++, oldText.add),
          ),
          throwsA(
            failure is PlatformException
                ? isA<PlatformException>()
                      .having((error) => error.code, 'code', failure.code)
                      .having(
                        (error) => error.message,
                        'message',
                        failure.message,
                      )
                : isA<MissingPluginException>(),
          ),
        );
        final String oldButton = payloads.single[0]['buttonActionId'] as String;
        final String oldField =
            payloads.single[1]['textFieldActionId'] as String;

        Future<void> sendOldEvents() async {
          await _send('buttonPressed', {'actionId': oldButton});
          await _send('textFieldChanged', {
            'actionId': oldField,
            'value': 'Stale text',
          });
          expect(oldButtons, 0);
          expect(oldText, isEmpty);
        }

        await sendOldEvents();
        retry = AppleLiquidSheet.showSheet(
          content: content(() => newButtons++, newText.add),
        );
        await retryReachedNative.future.timeout(const Duration(seconds: 2));
        expect(payloads, hasLength(2));
        final String newButton = payloads.last[0]['buttonActionId'] as String;
        final String newField = payloads.last[1]['textFieldActionId'] as String;
        expect(newButton, isNot(oldButton));
        expect(newField, isNot(oldField));
        await sendOldEvents();
        expect(newButtons, 0);
        expect(newText, isEmpty);

        await _send('buttonPressed', {'actionId': newButton});
        await _send('textFieldChanged', {
          'actionId': newField,
          'value': 'Live retry',
        });
        expect(newButtons, 1);
        expect(newText, ['Live retry']);
        nativeResult.complete({
          'status': 'saved',
          'textFieldValues': {newField: 'Final retry', oldField: 'Stale final'},
        });
        final AppleLiquidSheetResult result = await retry;
        expect(result.status, AppleLiquidSheetResultStatus.saved);
        expect(result.textField('title')?.value, 'Final retry');
        expect(newText, ['Live retry', 'Final retry']);
        await sendOldEvents();
        await _send('buttonPressed', {'actionId': newButton});
        await _send('textFieldChanged', {
          'actionId': newField,
          'value': 'After completion',
        });
        expect(newButtons, 1);
        expect(newText, ['Live retry', 'Final retry']);
      } finally {
        if (!nativeResult.isCompleted) {
          nativeResult.complete({'status': 'cancelled'});
        }
        try {
          await retry;
        } finally {
          messenger.setMockMethodCallHandler(_channel, null);
          debugDefaultTargetPlatformOverride = null;
        }
      }
    });
  }
}
