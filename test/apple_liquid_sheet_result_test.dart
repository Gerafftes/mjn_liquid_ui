import 'package:flutter_test/flutter_test.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart' as api;
import 'package:mjn_liquid_ui/src/apple_liquid_sheet.dart' as sheet;

void main() {
  test('sheet result status getters preserve every outcome', () {
    expect(
      api.AppleLiquidSheetResultStatus.values,
      <api.AppleLiquidSheetResultStatus>[
        api.AppleLiquidSheetResultStatus.saved,
        api.AppleLiquidSheetResultStatus.cancelled,
        api.AppleLiquidSheetResultStatus.alreadyShowing,
        api.AppleLiquidSheetResultStatus.notPresented,
      ],
    );
    const Map<api.AppleLiquidSheetResultStatus, List<bool>> expectations = {
      api.AppleLiquidSheetResultStatus.saved: [true, true, false],
      api.AppleLiquidSheetResultStatus.cancelled: [true, false, true],
      api.AppleLiquidSheetResultStatus.alreadyShowing: [true, false, false],
      api.AppleLiquidSheetResultStatus.notPresented: [false, false, false],
    };
    for (final entry in expectations.entries) {
      final api.AppleLiquidSheetResult result = api.AppleLiquidSheetResult(
        status: entry.key,
      );
      expect([
        result.didPresent,
        result.isSaved,
        result.isCancelled,
      ], entry.value);
    }
  });

  test('sheet result constructors preserve empty and optional defaults', () {
    final api.AppleLiquidSheetResult result = api.AppleLiquidSheetResult(
      status: api.AppleLiquidSheetResultStatus.notPresented,
    );
    const api.AppleLiquidSheetTextFieldValue field =
        api.AppleLiquidSheetTextFieldValue(title: 'Name', value: 'Johann');
    expect(result.textFields, isEmpty);
    expect(result.textField('missing'), isNull);
    expect(field.identifier, isNull);
    expect(field.title, 'Name');
    expect(field.value, 'Johann');
  });

  test('sheet result owns an unmodifiable snapshot in declaration order', () {
    const api.AppleLiquidSheetTextFieldValue first =
        api.AppleLiquidSheetTextFieldValue(
          identifier: 'first',
          title: 'First',
          value: 'one',
        );
    const api.AppleLiquidSheetTextFieldValue second =
        api.AppleLiquidSheetTextFieldValue(
          identifier: 'second',
          title: 'Second',
          value: 'two',
        );
    final List<api.AppleLiquidSheetTextFieldValue> input =
        <api.AppleLiquidSheetTextFieldValue>[first, second];
    final api.AppleLiquidSheetResult result = api.AppleLiquidSheetResult(
      status: api.AppleLiquidSheetResultStatus.saved,
      textFields: input,
    );
    input.clear();
    expect(result.textFields, <api.AppleLiquidSheetTextFieldValue>[
      first,
      second,
    ]);
    expect(() => result.textFields.add(first), throwsUnsupportedError);
    expect(() => result.textFields[0] = second, throwsUnsupportedError);
    expect(result.textField('first'), same(first));
    expect(result.textField('second'), same(second));
    expect(result.textField('missing'), isNull);
  });

  test('sheet result accepts a non-list iterable', () {
    const api.AppleLiquidSheetTextFieldValue field =
        api.AppleLiquidSheetTextFieldValue(
          identifier: 'name',
          title: 'Name',
          value: 'Johann',
        );
    final api.AppleLiquidSheetResult result = api.AppleLiquidSheetResult(
      status: api.AppleLiquidSheetResultStatus.saved,
      textFields: <api.AppleLiquidSheetTextFieldValue>{
        field,
      }.map((value) => value),
    );
    expect(result.textFields, <api.AppleLiquidSheetTextFieldValue>[field]);
  });

  test('barrel and existing sheet import expose identical result types', () {
    const sheet.AppleLiquidSheetTextFieldValue field =
        api.AppleLiquidSheetTextFieldValue(title: 'Name', value: 'Johann');
    const api.AppleLiquidSheetResultStatus status =
        sheet.AppleLiquidSheetResultStatus.saved;
    final api.AppleLiquidSheetResult publicResult =
        sheet.AppleLiquidSheetResult(
          status: status,
          textFields: <sheet.AppleLiquidSheetTextFieldValue>[field],
        );
    final sheet.AppleLiquidSheetResult sheetResult = publicResult;
    expect(sheetResult, same(publicResult));
    expect(sheetResult.textFields.single, same(field));
    expect(api.AppleLiquidSheetResult, sheet.AppleLiquidSheetResult);
    expect(
      api.AppleLiquidSheetResultStatus,
      sheet.AppleLiquidSheetResultStatus,
    );
    expect(
      api.AppleLiquidSheetTextFieldValue,
      sheet.AppleLiquidSheetTextFieldValue,
    );
  });
}
