import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'apple_liquid_platform_view.dart';

class AppleLiquidSwitch extends StatefulWidget {
  const AppleLiquidSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 76,
    this.height = 60,
    this.tintColor,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final double width;
  final double height;
  final Color? tintColor;

  @override
  State<AppleLiquidSwitch> createState() => _AppleLiquidSwitchState();
}

class _AppleLiquidSwitchState extends State<AppleLiquidSwitch> {
  static const String _viewType = 'mjn_liquid_ui_switch';

  MethodChannel? _channel;
  bool _isInteractingNatively = false;
  bool _hasPendingValueSync = false;

  @override
  void didUpdateWidget(covariant AppleLiquidSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.tintColor != widget.tintColor) {
      if (_isInteractingNatively) {
        _hasPendingValueSync = true;
      } else {
        _updateNativeConfiguration();
      }
    } else if (oldWidget.value != widget.value) {
      if (_isInteractingNatively) {
        _hasPendingValueSync = true;
      } else {
        _setNativeValue(widget.value);
      }
    }
  }

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return SizedBox(
        width: widget.width,
        height: widget.height,
        child: AppleLiquidUiKitView(
          viewType: _viewType,
          layoutDirection: Directionality.of(context),
          creationParamsCodec: const StandardMessageCodec(),
          creationParams: _configuration,
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
            Factory<OneSequenceGestureRecognizer>(
              () => EagerGestureRecognizer(),
            ),
          },
          onPlatformViewCreated: _onPlatformViewCreated,
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Switch.adaptive(
        value: widget.value,
        activeThumbColor: widget.tintColor,
        activeTrackColor: widget.tintColor?.withValues(alpha: 0.42),
        onChanged: widget.onChanged,
      ),
    );
  }

  Map<String, Object?> get _configuration {
    return <String, Object?>{
      'value': widget.value,
      'tintColor': widget.tintColor?.toARGB32(),
    };
  }

  void _onPlatformViewCreated(int viewId) {
    _channel?.setMethodCallHandler(null);
    _channel = MethodChannel('$_viewType/$viewId')
      ..setMethodCallHandler(_handleMethodCall);
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'valueChanged':
        final Object? arguments = call.arguments;
        if (arguments is Map && arguments['value'] is bool) {
          if (mounted) {
            widget.onChanged(arguments['value'] as bool);
          }
          return;
        }
        throw MissingPluginException('Invalid switch valueChanged payload.');
      case 'interactionChanged':
        final Object? arguments = call.arguments;
        if (arguments is Map && arguments['isInteracting'] is bool) {
          if (mounted) {
            _setNativeInteraction(arguments['isInteracting'] as bool);
          }
          return;
        }
        throw MissingPluginException('Invalid switch interaction payload.');
      default:
        throw MissingPluginException('No handler for ${call.method}.');
    }
  }

  void _setNativeValue(bool value) {
    _invokeNative('setValue', <String, Object?>{'value': value});
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
      // The native side exposes only internal sync methods. During teardown
      // the channel can disappear before this state object is disposed.
    }
  }

  void _setNativeInteraction(bool isInteracting) {
    if (_isInteractingNatively == isInteracting) {
      return;
    }

    _isInteractingNatively = isInteracting;

    if (!isInteracting && _hasPendingValueSync) {
      _hasPendingValueSync = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isInteractingNatively) {
          _updateNativeConfiguration();
        }
      });
    }
  }
}
