/// SF Symbol stroke weights supported by Apple's symbol configuration APIs.
enum AppleLiquidSymbolWeight {
  /// The thinnest available SF Symbol stroke.
  ultraLight('ultraLight', 100),

  /// A very thin SF Symbol stroke.
  thin('thin', 100),

  /// A light SF Symbol stroke.
  light('light', 300),

  /// The regular SF Symbol stroke.
  regular('regular', 400),

  /// A medium SF Symbol stroke.
  medium('medium', 500),

  /// A semibold SF Symbol stroke.
  semibold('semibold', 600),

  /// A bold SF Symbol stroke.
  bold('bold', 700),

  /// A heavy SF Symbol stroke.
  heavy('heavy', 800),

  /// The heaviest available SF Symbol stroke.
  black('black', 900);

  const AppleLiquidSymbolWeight(this.platformValue, this.fallbackIconWeight);

  /// String value understood by the native iOS implementation.
  final String platformValue;

  /// Approximate Flutter `Icon.weight` value for non-iOS fallbacks.
  final double fallbackIconWeight;
}
