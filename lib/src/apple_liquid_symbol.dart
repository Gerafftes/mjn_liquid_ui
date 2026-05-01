import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'apple_liquid_platform_view.dart';

/// Renders an SF Symbol by name on iOS.
///
/// On unsupported platforms, [fallbackIcon] is rendered when provided. Without
/// a fallback, the widget keeps its square layout but paints no icon.
class AppleLiquidSymbol extends StatefulWidget {
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
  State<AppleLiquidSymbol> createState() => _AppleLiquidSymbolState();
}

class _AppleLiquidSymbolState extends State<AppleLiquidSymbol> {
  static const String _viewType = 'mjn_liquid_ui_symbol';

  MethodChannel? _channel;

  @override
  void didUpdateWidget(covariant AppleLiquidSymbol oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.name != widget.name ||
        oldWidget.size != widget.size ||
        oldWidget.color != widget.color) {
      _updateNativeConfiguration();
    }
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget symbol = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
        ? AppleLiquidUiKitView(
            viewType: _viewType,
            layoutDirection: Directionality.of(context),
            creationParamsCodec: const StandardMessageCodec(),
            creationParams: _configuration,
            hitTestBehavior: PlatformViewHitTestBehavior.transparent,
            onPlatformViewCreated: _onPlatformViewCreated,
          )
        : _fallbackSymbol();

    final Widget sizedSymbol = SizedBox.square(
      dimension: widget.size,
      child: symbol,
    );

    final String? semanticLabel = widget.semanticLabel;
    if (semanticLabel == null) {
      return sizedSymbol;
    }

    return Semantics(label: semanticLabel, image: true, child: sizedSymbol);
  }

  Widget _fallbackSymbol() {
    final IconData? fallbackIcon = widget.fallbackIcon;
    if (fallbackIcon == null) {
      return const SizedBox.expand();
    }

    return Icon(
      fallbackIcon,
      size: widget.size,
      color: widget.color,
      semanticLabel: widget.semanticLabel,
    );
  }

  Map<String, Object?> get _configuration {
    return <String, Object?>{
      'name': widget.name,
      'size': widget.size,
      'color': widget.color?.toARGB32(),
    };
  }

  void _onPlatformViewCreated(int viewId) {
    _channel?.setMethodCallHandler(null);
    _channel = MethodChannel('$_viewType/$viewId');
  }

  void _updateNativeConfiguration() {
    _invokeNative('updateConfiguration', _configuration);
  }

  Future<void> _invokeNative(String method, Object? arguments) async {
    final MethodChannel? channel = _channel;
    if (channel == null) {
      return;
    }

    try {
      await channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      // Ignore platform-view teardown races during debug hot restart.
    } on PlatformException {
      // The native view can disappear before Flutter disposes this state.
    }
  }
}
