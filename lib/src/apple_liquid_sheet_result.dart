/// Outcome returned after `AppleLiquidSheet.showSheet` completes.
enum AppleLiquidSheetResultStatus {
  /// The sheet's confirmation action was pressed.
  saved,

  /// The sheet was dismissed without pressing its confirmation action.
  cancelled,

  /// Another native sheet was already being presented.
  alreadyShowing,

  /// The current platform or presentation context could not show the sheet.
  notPresented,
}

/// The final text from one `AppleLiquidSheetRow.textField`.
class AppleLiquidSheetTextFieldValue {
  const AppleLiquidSheetTextFieldValue({
    this.identifier,
    required this.title,
    required this.value,
  });

  /// Optional identifier supplied to `AppleLiquidSheetRow.textField`.
  final String? identifier;

  /// The text-field title.
  final String title;

  /// The final text when the sheet was dismissed.
  final String value;
}

/// Result of showing and dismissing a native sheet.
class AppleLiquidSheetResult {
  AppleLiquidSheetResult({
    required this.status,
    Iterable<AppleLiquidSheetTextFieldValue> textFields =
        const <AppleLiquidSheetTextFieldValue>[],
  }) : textFields = List<AppleLiquidSheetTextFieldValue>.unmodifiable(
         textFields,
       );

  /// Whether the sheet was saved, cancelled, already showing, or not presented.
  final AppleLiquidSheetResultStatus status;

  /// Final text-field values in the order their rows were declared.
  final List<AppleLiquidSheetTextFieldValue> textFields;

  /// Whether a native sheet is presented or was already showing.
  bool get didPresent => status != AppleLiquidSheetResultStatus.notPresented;

  /// Whether the sheet's confirmation action was pressed.
  bool get isSaved => status == AppleLiquidSheetResultStatus.saved;

  /// Whether the sheet was dismissed without saving.
  bool get isCancelled => status == AppleLiquidSheetResultStatus.cancelled;

  /// Looks up a text field by its explicit identifier.
  ///
  /// Identifiers must be unique within a sheet. Returns null when no field
  /// uses [identifier].
  AppleLiquidSheetTextFieldValue? textField(String identifier) {
    for (final AppleLiquidSheetTextFieldValue field in textFields) {
      if (field.identifier == identifier) {
        return field;
      }
    }
    return null;
  }
}
