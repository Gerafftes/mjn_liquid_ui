import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'apple_liquid_symbol_weight.dart';

const double _maxNativeSymbolSize = 512;
const double _maxNativeSymbolScale = 4;
const double _maxNativeSymbolPixelDimension = 2048;
const int _maxSymbolCacheEntries = 128;
const int _maxSymbolCacheBytes = 4 * 1024 * 1024;

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
    this.weight,
    this.fallbackIcon,
    this.semanticLabel,
  }) : assert(name.length > 0),
       assert(size > 0),
       assert(size <= _maxNativeSymbolSize);

  static const MethodChannel _channel = MethodChannel('mjn_liquid_ui/symbols');
  static final LinkedHashMap<_AppleLiquidSymbolCacheKey, Uint8List>
  _bytesCache = LinkedHashMap<_AppleLiquidSymbolCacheKey, Uint8List>();
  static final Map<_AppleLiquidSymbolCacheKey, Future<Uint8List?>>
  _pendingLoads = <_AppleLiquidSymbolCacheKey, Future<Uint8List?>>{};
  static final LinkedHashSet<_AppleLiquidSymbolCacheKey> _missingSymbols =
      LinkedHashSet<_AppleLiquidSymbolCacheKey>();
  static int _cachedByteCount = 0;

  /// SF Symbol name passed to `UIImage(systemName:)` on iOS.
  final String name;

  /// Width, height, and preferred point size for the symbol.
  final double size;

  /// Optional tint color for the rendered symbol.
  final Color? color;

  /// Optional SF Symbol stroke weight used by native iOS rendering.
  ///
  /// When null, iOS uses the symbol's default weight for the requested point
  /// size. Unsupported-platform icon fallbacks map this to Flutter's variable
  /// icon weight when the fallback icon font supports it.
  final AppleLiquidSymbolWeight? weight;

  /// Optional Flutter icon used when the platform cannot render SF Symbols.
  final IconData? fallbackIcon;

  /// Optional accessibility label for the symbol.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    _validateSize();
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
    if (!_supportsNativeScale(devicePixelRatio)) {
      return _fallbackSymbol(effectiveColor);
    }

    final _AppleLiquidSymbolCacheKey cacheKey = _AppleLiquidSymbolCacheKey(
      name: name,
      size: size,
      color: effectiveColor?.toARGB32(),
      weight: weight?.platformValue,
      devicePixelRatio: devicePixelRatio,
    );

    final Uint8List? cachedBytes = _cachedBytesFor(cacheKey);
    if (cachedBytes != null) {
      return _image(cachedBytes, effectiveColor);
    }

    if (_isMissing(cacheKey)) {
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
      weight: weight?.fallbackIconWeight,
      semanticLabel: semanticLabel,
    );
  }

  static Future<Uint8List?> _loadNativeSymbol(
    _AppleLiquidSymbolCacheKey cacheKey,
  ) {
    final Uint8List? cachedBytes = _cachedBytesFor(cacheKey);
    if (cachedBytes != null) {
      return SynchronousFuture<Uint8List?>(cachedBytes);
    }

    if (_isMissing(cacheKey)) {
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
              'weight': cacheKey.weight,
            });

        if (bytes == null || bytes.isEmpty) {
          _rememberMissing(cacheKey);
          return null;
        }

        _cacheBytes(cacheKey, bytes);
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

  static Uint8List? _cachedBytesFor(_AppleLiquidSymbolCacheKey cacheKey) {
    final Uint8List? bytes = _bytesCache.remove(cacheKey);
    if (bytes != null) {
      _bytesCache[cacheKey] = bytes;
    }
    return bytes;
  }

  static bool _isMissing(_AppleLiquidSymbolCacheKey cacheKey) {
    if (!_missingSymbols.remove(cacheKey)) {
      return false;
    }

    _missingSymbols.add(cacheKey);
    return true;
  }

  static void _rememberMissing(_AppleLiquidSymbolCacheKey cacheKey) {
    _missingSymbols.remove(cacheKey);
    _missingSymbols.add(cacheKey);
    while (_missingSymbols.length > _maxSymbolCacheEntries) {
      _missingSymbols.remove(_missingSymbols.first);
    }
  }

  static void _cacheBytes(
    _AppleLiquidSymbolCacheKey cacheKey,
    Uint8List bytes,
  ) {
    final Uint8List? previousBytes = _bytesCache.remove(cacheKey);
    if (previousBytes != null) {
      _cachedByteCount -= previousBytes.length;
    }
    _missingSymbols.remove(cacheKey);

    if (bytes.length > _maxSymbolCacheBytes) {
      return;
    }

    _bytesCache[cacheKey] = bytes;
    _cachedByteCount += bytes.length;

    while (_bytesCache.length > _maxSymbolCacheEntries ||
        _cachedByteCount > _maxSymbolCacheBytes) {
      final _AppleLiquidSymbolCacheKey oldestKey = _bytesCache.keys.first;
      final Uint8List? oldestBytes = _bytesCache.remove(oldestKey);
      if (oldestBytes == null) {
        break;
      }
      _cachedByteCount -= oldestBytes.length;
    }
  }

  bool _supportsNativeScale(double devicePixelRatio) {
    return devicePixelRatio.isFinite &&
        devicePixelRatio > 0 &&
        devicePixelRatio <= _maxNativeSymbolScale &&
        size * devicePixelRatio <= _maxNativeSymbolPixelDimension;
  }

  void _validateSize() {
    if (!size.isFinite || size <= 0 || size > _maxNativeSymbolSize) {
      throw ArgumentError.value(
        size,
        'size',
        'must be finite, greater than zero, and at most $_maxNativeSymbolSize',
      );
    }
  }
}

@immutable
class _AppleLiquidSymbolCacheKey {
  const _AppleLiquidSymbolCacheKey({
    required this.name,
    required this.size,
    required this.color,
    required this.weight,
    required this.devicePixelRatio,
  });

  final String name;
  final double size;
  final int? color;
  final String? weight;
  final double devicePixelRatio;

  @override
  bool operator ==(Object other) {
    return other is _AppleLiquidSymbolCacheKey &&
        other.name == name &&
        other.size == size &&
        other.color == color &&
        other.weight == weight &&
        other.devicePixelRatio == devicePixelRatio;
  }

  @override
  int get hashCode => Object.hash(name, size, color, weight, devicePixelRatio);
}
