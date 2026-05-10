import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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

    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
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
