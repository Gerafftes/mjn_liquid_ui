import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Imperative controller for the native iOS template sheet.
class AppleLiquidSheetController extends ChangeNotifier {
  /// Creates a controller with default presentation options.
  AppleLiquidSheetController({
    double heightFraction = 1,
    double backgroundZoomScale = 1,
  }) : assert(heightFraction >= 0.25 && heightFraction <= 1),
       assert(backgroundZoomScale >= 0.85 && backgroundZoomScale <= 1),
       _heightFraction = heightFraction,
       _backgroundZoomScale = backgroundZoomScale;

  double _heightFraction;
  double _backgroundZoomScale;
  Future<bool>? _activeShow;
  bool _isShown = false;
  bool _isDisposed = false;

  /// Default detent height used by [showTemplateSheet].
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

  /// Whether this controller currently has a native sheet presentation pending.
  bool get isShowing => _activeShow != null;

  /// Whether this controller considers the native sheet visible.
  bool get isShown => _isShown;

  /// Shows the native template sheet.
  ///
  /// Returns false on unsupported platforms, when the native side cannot present
  /// a sheet, or when this controller already has a pending presentation.
  Future<bool> showTemplateSheet({
    double? heightFraction,
    double? backgroundZoomScale,
  }) async {
    if (_activeShow != null || !AppleLiquidSheet._supportsNativeSheets) {
      return false;
    }

    final double effectiveHeightFraction = heightFraction ?? _heightFraction;
    final double effectiveBackgroundZoomScale =
        backgroundZoomScale ?? _backgroundZoomScale;

    assert(effectiveHeightFraction >= 0.25 && effectiveHeightFraction <= 1);
    assert(
      effectiveBackgroundZoomScale >= 0.85 && effectiveBackgroundZoomScale <= 1,
    );

    final Future<bool> showFuture = AppleLiquidSheet.showTemplateSheet(
      heightFraction: effectiveHeightFraction,
      backgroundZoomScale: effectiveBackgroundZoomScale,
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

  /// Dismisses the active native template sheet.
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

  /// Shows a native template picker sheet on iOS.
  ///
  /// Returns false on unsupported platforms so callers can provide a fallback.
  /// On iOS, the returned future completes after the sheet has closed.
  static Future<bool> showTemplateSheet({
    double heightFraction = 1,
    double backgroundZoomScale = 1,
  }) async {
    assert(heightFraction >= 0.25 && heightFraction <= 1);
    assert(backgroundZoomScale >= 0.85 && backgroundZoomScale <= 1);

    if (!_supportsNativeSheets) {
      return false;
    }

    _attachDebugLogHandler();

    return await _channel.invokeMethod<bool>(
          'showTemplateSheet',
          <String, Object?>{
            'heightFraction': heightFraction,
            'backgroundZoomScale': backgroundZoomScale,
          },
        ) ??
        false;
  }

  /// Dismisses the active native template sheet on iOS.
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
