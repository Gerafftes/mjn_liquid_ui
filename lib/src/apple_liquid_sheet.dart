import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Declarative content rendered inside a native iOS Liquid Glass sheet.
///
/// The content is rendered by SwiftUI as a native `NavigationStack` and `Form`.
/// Interactive rows such as toggles, pickers, and text fields keep their state
/// locally inside the native sheet for the duration of the presentation.
class AppleLiquidSheetContent {
  /// Creates native sheet content from form sections.
  const AppleLiquidSheetContent({
    this.title = 'Settings',
    this.doneSemanticLabel = 'Done',
    required this.sections,
  });

  /// Default content used when no custom content is passed.
  static const AppleLiquidSheetContent settings = AppleLiquidSheetContent(
    sections: <AppleLiquidSheetSection>[
      AppleLiquidSheetSection(
        title: 'Overview',
        rows: <AppleLiquidSheetRow>[
          AppleLiquidSheetRow.value(title: 'Component', value: 'Liquid Sheet'),
          AppleLiquidSheetRow.value(title: 'Mode', value: 'Navigation Form'),
          AppleLiquidSheetRow.navigation(
            title: 'Preview details',
            content: AppleLiquidSheetContent(
              title: 'Preview',
              sections: <AppleLiquidSheetSection>[
                AppleLiquidSheetSection(
                  title: 'Preview',
                  rows: <AppleLiquidSheetRow>[
                    AppleLiquidSheetRow.textField(
                      title: 'Title',
                      value: 'Sheet Preview',
                    ),
                    AppleLiquidSheetRow.textField(
                      title: 'Owner',
                      value: 'Design Team',
                    ),
                  ],
                ),
                AppleLiquidSheetSection(
                  title: 'Context',
                  rows: <AppleLiquidSheetRow>[
                    AppleLiquidSheetRow.value(title: 'Surface', value: 'Form'),
                    AppleLiquidSheetRow.value(
                      title: 'Detents',
                      value: 'Content-sized',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      AppleLiquidSheetSection(
        title: 'Appearance',
        rows: <AppleLiquidSheetRow>[
          AppleLiquidSheetRow.toggle(title: 'Liquid Glass', value: true),
          AppleLiquidSheetRow.toggle(title: 'Reduce motion'),
          AppleLiquidSheetRow.picker(
            title: 'Accent',
            options: <String>['Blue', 'Teal', 'Graphite'],
            selectedOption: 'Blue',
          ),
        ],
      ),
      AppleLiquidSheetSection(
        title: 'Updates',
        rows: <AppleLiquidSheetRow>[
          AppleLiquidSheetRow.picker(
            title: 'Refresh',
            options: <String>['Manual', 'Daily', 'Weekly'],
            selectedOption: 'Daily',
          ),
          AppleLiquidSheetRow.navigation(
            title: 'Notification rules',
            content: AppleLiquidSheetContent(
              title: 'Rules',
              sections: <AppleLiquidSheetSection>[
                AppleLiquidSheetSection(
                  title: 'Rules',
                  rows: <AppleLiquidSheetRow>[
                    AppleLiquidSheetRow.toggle(
                      title: 'Critical updates',
                      value: true,
                    ),
                    AppleLiquidSheetRow.toggle(title: 'Weekly digest'),
                  ],
                ),
                AppleLiquidSheetSection(
                  title: 'Routing',
                  rows: <AppleLiquidSheetRow>[
                    AppleLiquidSheetRow.value(
                      title: 'Channel',
                      value: 'In-app',
                    ),
                    AppleLiquidSheetRow.value(
                      title: 'Priority',
                      value: 'Normal',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      AppleLiquidSheetSection(
        title: 'Metadata',
        rows: <AppleLiquidSheetRow>[
          AppleLiquidSheetRow.value(title: 'Platform', value: 'iOS'),
          AppleLiquidSheetRow.value(title: 'Status', value: 'Prototype'),
        ],
      ),
    ],
  );

  /// Native navigation title used by the sheet.
  final String title;

  /// Accessibility label for the checkmark dismiss button.
  final String doneSemanticLabel;

  /// Form sections rendered in order.
  final List<AppleLiquidSheetSection> sections;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'title': title,
      'doneSemanticLabel': doneSemanticLabel,
      'sections': sections
          .map((AppleLiquidSheetSection section) => section.toMap())
          .toList(),
    };
  }
}

/// A native SwiftUI `Form` section inside [AppleLiquidSheetContent].
class AppleLiquidSheetSection {
  /// Creates a section with optional title and rows.
  const AppleLiquidSheetSection({this.title, required this.rows});

  /// Optional section header.
  final String? title;

  /// Rows rendered in this section.
  final List<AppleLiquidSheetRow> rows;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (title != null) 'title': title,
      'rows': rows.map((AppleLiquidSheetRow row) => row.toMap()).toList(),
    };
  }
}

/// Native row types supported by [AppleLiquidSheetRow].
enum AppleLiquidSheetRowType {
  /// Plain title/subtitle row.
  text('text'),

  /// Label-value row rendered as native `LabeledContent`.
  value('value'),

  /// Native SwiftUI toggle with local state.
  toggle('toggle'),

  /// Native SwiftUI navigation-link picker with local state.
  picker('picker'),

  /// Navigation row that pushes nested [AppleLiquidSheetContent].
  navigation('navigation'),

  /// Native SwiftUI text field with local state.
  textField('textField');

  const AppleLiquidSheetRowType(this.platformValue);

  /// Value sent over the platform channel.
  final String platformValue;
}

/// A row rendered inside a native iOS Liquid Glass sheet form.
class AppleLiquidSheetRow {
  const AppleLiquidSheetRow._({
    required this.type,
    required this.title,
    this.subtitle,
    this.value,
    this.boolValue,
    this.options = const <String>[],
    this.selectedOption,
    this.content,
    this.systemImage,
  });

  /// Creates a plain text row.
  const AppleLiquidSheetRow.text({
    required String title,
    String? subtitle,
    String? systemImage,
  }) : this._(
         type: AppleLiquidSheetRowType.text,
         title: title,
         subtitle: subtitle,
         systemImage: systemImage,
       );

  /// Creates a label-value row.
  const AppleLiquidSheetRow.value({
    required String title,
    required String value,
    String? subtitle,
    String? systemImage,
  }) : this._(
         type: AppleLiquidSheetRowType.value,
         title: title,
         subtitle: subtitle,
         value: value,
         systemImage: systemImage,
       );

  /// Creates a native toggle row.
  const AppleLiquidSheetRow.toggle({
    required String title,
    bool value = false,
    String? subtitle,
    String? systemImage,
  }) : this._(
         type: AppleLiquidSheetRowType.toggle,
         title: title,
         subtitle: subtitle,
         boolValue: value,
         systemImage: systemImage,
       );

  /// Creates a native picker row.
  const AppleLiquidSheetRow.picker({
    required String title,
    required List<String> options,
    String? selectedOption,
    String? subtitle,
    String? systemImage,
  }) : this._(
         type: AppleLiquidSheetRowType.picker,
         title: title,
         subtitle: subtitle,
         options: options,
         selectedOption: selectedOption,
         systemImage: systemImage,
       );

  /// Creates a navigation row with nested sheet content.
  const AppleLiquidSheetRow.navigation({
    required String title,
    required AppleLiquidSheetContent content,
    String? subtitle,
    String? systemImage,
  }) : this._(
         type: AppleLiquidSheetRowType.navigation,
         title: title,
         subtitle: subtitle,
         content: content,
         systemImage: systemImage,
       );

  /// Creates a native text field row.
  const AppleLiquidSheetRow.textField({
    required String title,
    String value = '',
    String? subtitle,
    String? systemImage,
  }) : this._(
         type: AppleLiquidSheetRowType.textField,
         title: title,
         subtitle: subtitle,
         value: value,
         systemImage: systemImage,
       );

  /// Row type rendered on iOS.
  final AppleLiquidSheetRowType type;

  /// Main row title.
  final String title;

  /// Optional secondary text shown below the title where the native row supports
  /// it.
  final String? subtitle;

  /// Text value for [AppleLiquidSheetRow.value] and initial text-field value.
  final String? value;

  /// Initial toggle value for [AppleLiquidSheetRow.toggle].
  final bool? boolValue;

  /// Picker options for [AppleLiquidSheetRow.picker].
  final List<String> options;

  /// Initial picker selection. Defaults to the first option on iOS when null or
  /// not present in [options].
  final String? selectedOption;

  /// Nested content for [AppleLiquidSheetRow.navigation].
  final AppleLiquidSheetContent? content;

  /// Optional SF Symbol name used by native rows that can show a label icon.
  final String? systemImage;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'type': type.platformValue,
      'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (value != null) 'value': value,
      if (boolValue != null) 'boolValue': boolValue,
      if (options.isNotEmpty) 'options': options,
      if (selectedOption != null) 'selectedOption': selectedOption,
      if (content != null) 'content': content!.toMap(),
      if (systemImage != null) 'systemImage': systemImage,
    };
  }
}

/// Imperative controller for the native iOS sheet.
class AppleLiquidSheetController extends ChangeNotifier {
  /// Creates a controller with default presentation options.
  AppleLiquidSheetController({
    double heightFraction = 1,
    double backgroundZoomScale = 1,
    Color? sheetColor,
    AppleLiquidSheetContent? content,
  }) : assert(heightFraction >= 0.25 && heightFraction <= 1),
       assert(backgroundZoomScale >= 0.85 && backgroundZoomScale <= 1),
       _heightFraction = heightFraction,
       _backgroundZoomScale = backgroundZoomScale,
       _sheetColor = sheetColor,
       _content = content;

  double _heightFraction;
  double _backgroundZoomScale;
  Color? _sheetColor;
  AppleLiquidSheetContent? _content;
  Future<bool>? _activeShow;
  bool _isShown = false;
  bool _isDisposed = false;

  /// Legacy maximum detent height option used by [showSheet].
  double get heightFraction => _heightFraction;

  set heightFraction(double value) {
    assert(value >= 0.25 && value <= 1);

    if (_heightFraction == value) {
      return;
    }

    _heightFraction = value;
    _notifyStateChanged();
  }

  /// Default presenting-page zoom scale used by [showTemplateSheet].
  double get backgroundZoomScale => _backgroundZoomScale;

  set backgroundZoomScale(double value) {
    assert(value >= 0.85 && value <= 1);

    if (_backgroundZoomScale == value) {
      return;
    }

    _backgroundZoomScale = value;
    _notifyStateChanged();
  }

  /// Optional sheet background color.
  ///
  /// When null, iOS uses an automatic dynamic color that adapts to light and
  /// dark mode.
  Color? get sheetColor => _sheetColor;

  set sheetColor(Color? value) {
    if (_sheetColor == value) {
      return;
    }

    _sheetColor = value;
    _notifyStateChanged();
  }

  /// Default native form content used by [showSheet].
  AppleLiquidSheetContent? get content => _content;

  set content(AppleLiquidSheetContent? value) {
    if (_content == value) {
      return;
    }

    _content = value;
    _notifyStateChanged();
  }

  /// Whether this controller currently has a native sheet presentation pending.
  bool get isShowing => _activeShow != null;

  /// Whether this controller considers the native sheet visible.
  bool get isShown => _isShown;

  /// Shows the native sheet.
  ///
  /// Returns false on unsupported platforms, when the native side cannot present
  /// a sheet. Repeated calls while a native presentation is already active
  /// return true so callers do not open a fallback sheet on top.
  Future<bool> showSheet({
    double? heightFraction,
    double? backgroundZoomScale,
    Color? sheetColor,
    AppleLiquidSheetContent? content,
  }) async {
    if (_activeShow != null) {
      return true;
    }

    if (!AppleLiquidSheet._supportsNativeSheets) {
      return false;
    }

    final double effectiveHeightFraction = heightFraction ?? _heightFraction;
    final double effectiveBackgroundZoomScale =
        backgroundZoomScale ?? _backgroundZoomScale;
    final Color? effectiveSheetColor = sheetColor ?? _sheetColor;
    final AppleLiquidSheetContent? effectiveContent = content ?? _content;

    assert(effectiveHeightFraction >= 0.25 && effectiveHeightFraction <= 1);
    assert(
      effectiveBackgroundZoomScale >= 0.85 && effectiveBackgroundZoomScale <= 1,
    );

    final Future<bool> showFuture = AppleLiquidSheet.showSheet(
      heightFraction: effectiveHeightFraction,
      backgroundZoomScale: effectiveBackgroundZoomScale,
      sheetColor: effectiveSheetColor,
      content: effectiveContent,
    );

    _updateState(activeShow: showFuture, isShown: true);

    try {
      return await showFuture;
    } finally {
      if (identical(_activeShow, showFuture)) {
        _updateState(clearActiveShow: true, isShown: false);
      }
    }
  }

  /// Shows the native sheet.
  ///
  /// This legacy name is kept for source compatibility with earlier releases.
  Future<bool> showTemplateSheet({
    double? heightFraction,
    double? backgroundZoomScale,
    Color? sheetColor,
    AppleLiquidSheetContent? content,
  }) {
    return showSheet(
      heightFraction: heightFraction,
      backgroundZoomScale: backgroundZoomScale,
      sheetColor: sheetColor,
      content: content,
    );
  }

  /// Dismisses the active native sheet.
  ///
  /// Returns false when no native sheet is active or the platform is unsupported.
  Future<bool> dismiss() async {
    final bool didDismiss = await AppleLiquidSheet.dismissTemplateSheet();
    if (didDismiss) {
      _updateState(isShown: false);
    }
    return didDismiss;
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _updateState({
    Future<bool>? activeShow,
    bool clearActiveShow = false,
    bool? isShown,
  }) {
    final Future<bool>? previousActiveShow = _activeShow;
    final bool previousIsShown = _isShown;

    if (clearActiveShow) {
      _activeShow = null;
    } else if (activeShow != null) {
      _activeShow = activeShow;
    }

    if (isShown != null) {
      _isShown = isShown;
    }

    if (!identical(previousActiveShow, _activeShow) ||
        previousIsShown != _isShown) {
      _notifyStateChanged();
    }
  }

  void _notifyStateChanged() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }
}

/// Presents native iOS Liquid Glass sheets.
class AppleLiquidSheet {
  const AppleLiquidSheet._();

  static const MethodChannel _channel = MethodChannel('mjn_liquid_ui/sheets');
  static bool _debugLogHandlerAttached = false;
  static Future<bool>? _activeShow;

  /// Shows a native sheet on iOS.
  ///
  /// Pass [sheetColor] to force a specific sheet background color. When
  /// [sheetColor] is null, iOS uses an automatic dynamic color for light and
  /// dark mode.
  ///
  /// Pass [content] to customize the native SwiftUI `Form` rendered inside the
  /// sheet. When null, a built-in settings example is shown.
  ///
  /// [heightFraction] is retained for compatibility with earlier sheet demos.
  ///
  /// Returns false on unsupported platforms so callers can provide a fallback.
  /// Repeated calls while a native presentation is already active return true
  /// without opening another sheet.
  /// On iOS, the returned future completes after the sheet has closed.
  static Future<bool> showSheet({
    double heightFraction = 1,
    double backgroundZoomScale = 1,
    Color? sheetColor,
    AppleLiquidSheetContent? content,
  }) async {
    assert(heightFraction >= 0.25 && heightFraction <= 1);
    assert(backgroundZoomScale >= 0.85 && backgroundZoomScale <= 1);

    if (!_supportsNativeSheets) {
      return false;
    }

    if (_activeShow != null) {
      return true;
    }

    _attachDebugLogHandler();

    final Future<bool> showFuture = _channel
        .invokeMethod<bool>('showTemplateSheet', <String, Object?>{
          'heightFraction': heightFraction,
          'backgroundZoomScale': backgroundZoomScale,
          'sheetColor': sheetColor?.toARGB32(),
          if (content != null) 'content': content.toMap(),
        })
        .then((bool? didShow) => didShow ?? false);

    _activeShow = showFuture;

    try {
      return await showFuture;
    } finally {
      if (identical(_activeShow, showFuture)) {
        _activeShow = null;
      }
    }
  }

  /// Shows a native sheet on iOS.
  ///
  /// This legacy name is kept for source compatibility with earlier releases.
  static Future<bool> showTemplateSheet({
    double heightFraction = 1,
    double backgroundZoomScale = 1,
    Color? sheetColor,
    AppleLiquidSheetContent? content,
  }) {
    return showSheet(
      heightFraction: heightFraction,
      backgroundZoomScale: backgroundZoomScale,
      sheetColor: sheetColor,
      content: content,
    );
  }

  /// Dismisses the active native sheet on iOS.
  ///
  /// Returns false when no native sheet is active or the platform is unsupported.
  static Future<bool> dismissTemplateSheet() async {
    if (!_supportsNativeSheets) {
      return false;
    }

    _attachDebugLogHandler();

    return await _channel.invokeMethod<bool>('dismissTemplateSheet') ?? false;
  }

  static bool get _supportsNativeSheets {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  }

  static void _attachDebugLogHandler() {
    assert(() {
      if (_debugLogHandlerAttached) {
        return true;
      }

      _debugLogHandlerAttached = true;
      _channel.setMethodCallHandler((MethodCall call) async {
        if (call.method == 'debugLog') {
          debugPrint('${call.arguments}');
        }
      });
      return true;
    }());
  }
}
