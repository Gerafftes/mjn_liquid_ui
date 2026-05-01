import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Renders an SF Symbol by name on iOS.
///
/// The symbol shape is still produced by native `UIImage(systemName:)`, but the
/// result is painted as a normal Flutter image. This keeps small symbols stable
/// inside lists, rows, and transitions because no native platform view is
/// inserted for each icon.
class AppleLiquidSymbol extends StatelessWidget {
  /// Creates a square SF Symbol view.
  const AppleLiquidSymbol(
    this.name, {
    super.key,
    this.size = 24,
    this.color,
    this.fallbackIcon,
    this.semanticLabel,
  }) : assert(name.length > 0),
       assert(size > 0);

  static const MethodChannel _channel = MethodChannel('mjn_liquid_ui/symbols');
  static final Map<_AppleLiquidSymbolCacheKey, Uint8List> _bytesCache =
      <_AppleLiquidSymbolCacheKey, Uint8List>{};
  static final Map<_AppleLiquidSymbolCacheKey, Future<Uint8List?>>
  _pendingLoads = <_AppleLiquidSymbolCacheKey, Future<Uint8List?>>{};
  static final Set<_AppleLiquidSymbolCacheKey> _missingSymbols =
      <_AppleLiquidSymbolCacheKey>{};

  /// SF Symbol name passed to `UIImage(systemName:)` on iOS.
  final String name;

  /// Width, height, and preferred point size for the symbol.
  final double size;

  /// Optional tint color for the rendered symbol.
  final Color? color;

  /// Optional Flutter icon used when the platform cannot render SF Symbols.
  final IconData? fallbackIcon;

  /// Optional accessibility label for the symbol.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final Color? effectiveColor = color ?? IconTheme.of(context).color;
    final Widget symbol = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
        ? _nativeSymbol(context, effectiveColor)
        : _fallbackSymbol(effectiveColor);

    final Widget sizedSymbol = SizedBox.square(dimension: size, child: symbol);

    final String? semanticLabel = this.semanticLabel;
    if (semanticLabel == null) {
      return sizedSymbol;
    }

    return Semantics(label: semanticLabel, image: true, child: sizedSymbol);
  }

  Widget _nativeSymbol(BuildContext context, Color? effectiveColor) {
    final double devicePixelRatio =
        MediaQuery.maybeOf(context)?.devicePixelRatio ?? 1;
    final _AppleLiquidSymbolCacheKey cacheKey = _AppleLiquidSymbolCacheKey(
      name: name,
      size: size,
      color: effectiveColor?.toARGB32(),
      devicePixelRatio: devicePixelRatio,
    );

    final Uint8List? cachedBytes = _bytesCache[cacheKey];
    if (cachedBytes != null) {
      return _image(cachedBytes, effectiveColor);
    }

    if (_missingSymbols.contains(cacheKey)) {
      return _fallbackSymbol(effectiveColor);
    }

    return FutureBuilder<Uint8List?>(
      future: _loadNativeSymbol(cacheKey),
      builder: (BuildContext context, AsyncSnapshot<Uint8List?> snapshot) {
        final Uint8List? bytes = snapshot.data;
        if (bytes != null) {
          return _image(bytes, effectiveColor);
        }

        return _fallbackSymbol(effectiveColor);
      },
    );
  }

  Widget _image(Uint8List bytes, Color? effectiveColor) {
    return Image.memory(
      bytes,
      width: size,
      height: size,
      fit: BoxFit.contain,
      gaplessPlayback: true,
      excludeFromSemantics: true,
      errorBuilder:
          (BuildContext context, Object error, StackTrace? stackTrace) {
            return _fallbackSymbol(effectiveColor);
          },
    );
  }

  Widget _fallbackSymbol(Color? effectiveColor) {
    final IconData? fallbackIcon = this.fallbackIcon;
    if (fallbackIcon == null) {
      return const SizedBox.expand();
    }

    return Icon(
      fallbackIcon,
      size: size,
      color: effectiveColor,
      semanticLabel: semanticLabel,
    );
  }

  static Future<Uint8List?> _loadNativeSymbol(
    _AppleLiquidSymbolCacheKey cacheKey,
  ) {
    final Uint8List? cachedBytes = _bytesCache[cacheKey];
    if (cachedBytes != null) {
      return SynchronousFuture<Uint8List?>(cachedBytes);
    }

    if (_missingSymbols.contains(cacheKey)) {
      return SynchronousFuture<Uint8List?>(null);
    }

    return _pendingLoads.putIfAbsent(cacheKey, () async {
      try {
        final Uint8List? bytes = await _channel
            .invokeMethod<Uint8List>('render', <String, Object?>{
              'name': cacheKey.name,
              'size': cacheKey.size,
              'scale': cacheKey.devicePixelRatio,
              'color': cacheKey.color,
            });

        if (bytes == null || bytes.isEmpty) {
          _missingSymbols.add(cacheKey);
          return null;
        }

        _bytesCache[cacheKey] = bytes;
        return bytes;
      } on MissingPluginException {
        return null;
      } on PlatformException {
        return null;
      } finally {
        _pendingLoads.remove(cacheKey);
      }
    });
  }
}

@immutable
class _AppleLiquidSymbolCacheKey {
  const _AppleLiquidSymbolCacheKey({
    required this.name,
    required this.size,
    required this.color,
    required this.devicePixelRatio,
  });

  final String name;
  final double size;
  final int? color;
  final double devicePixelRatio;

  @override
  bool operator ==(Object other) {
    return other is _AppleLiquidSymbolCacheKey &&
        other.name == name &&
        other.size == size &&
        other.color == color &&
        other.devicePixelRatio == devicePixelRatio;
  }

  @override
  int get hashCode => Object.hash(name, size, color, devicePixelRatio);
}
