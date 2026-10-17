import 'package:flutter/foundation.dart';

/// Limits UI widgets to iOS and the retained experimental Android fallbacks.
void checkAppleLiquidPlatform() {
  if (kIsWeb ||
      (defaultTargetPlatform != TargetPlatform.iOS &&
          defaultTargetPlatform != TargetPlatform.android)) {
    throw UnsupportedError(
      'mjn_liquid_ui supports iOS. Android fallbacks are experimental and '
      'untested. Desktop and web are not supported.',
    );
  }
}
