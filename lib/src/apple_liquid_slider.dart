import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'apple_liquid_platform_view.dart';

/// A Liquid Glass styled slider that uses a native iOS control when available.
class AppleLiquidSlider extends StatefulWidget {
  /// Creates a slider for selecting a numeric value between [min] and [max].
  const AppleLiquidSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0,
    this.max = 1,
    this.step,
    this.height = 64,
    this.tintColor,
  }) : assert(min < max),
       assert(step == null || step > 0),
       assert(step == null || step <= max - min);

  /// The current slider value.
  final double value;

  /// Called whenever the user selects a new value.
  final ValueChanged<double> onChanged;

  /// The smallest selectable value.
  final double min;

  /// The largest selectable value.
  final double max;

  /// Optional fixed increment between selectable values.
  final double? step;

  /// The height reserved for the control.
  final double height;

  /// Optional accent color for the selected track and thumb.
  final Color? tintColor;

  @override
  State<AppleLiquidSlider> createState() => _AppleLiquidSliderState();
}

class _AppleLiquidSliderState extends State<AppleLiquidSlider> {
  static const String _viewType = 'mjn_liquid_ui_slider';

  MethodChannel? _channel;
  bool _isInteractingNatively = false;
  bool _hasPendingConfigurationSync = false;

  @override
  void didUpdateWidget(covariant AppleLiquidSlider oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.value != widget.value ||
        oldWidget.min != widget.min ||
        oldWidget.max != widget.max ||
        oldWidget.step != widget.step ||
        oldWidget.tintColor != widget.tintColor) {
      if (_isInteractingNatively) {
        _hasPendingConfigurationSync = true;
      } else {
        _updateNativeConfiguration();
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
    final double value = widget.value.clamp(widget.min, widget.max);
    final int? divisions = _divisionsForStep();

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return SizedBox(
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
      child: Slider.adaptive(
        value: value,
        min: widget.min,
        max: widget.max,
        divisions: divisions,
        activeColor: widget.tintColor,
        thumbColor: widget.tintColor,
        onChanged: widget.onChanged,
      ),
    );
  }

  Map<String, Object?> get _configuration {
    return <String, Object?>{
      'value': widget.value,
      'min': widget.min,
      'max': widget.max,
      'step': widget.step,
      'tintColor': widget.tintColor?.toARGB32(),
    };
  }

  int? _divisionsForStep() {
    final double? step = widget.step;
    if (step == null) {
      return null;
    }

    final int divisions = ((widget.max - widget.min) / step).round();
    return divisions < 1 ? 1 : divisions;
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
        if (arguments is Map && arguments['value'] is num) {
          if (mounted) {
            widget.onChanged((arguments['value'] as num).toDouble());
          }
          return;
        }
        throw MissingPluginException('Invalid slider valueChanged payload.');
      case 'interactionChanged':
        final Object? arguments = call.arguments;
        if (arguments is Map && arguments['isInteracting'] is bool) {
          if (mounted) {
            _setNativeInteraction(arguments['isInteracting'] as bool);
          }
          return;
        }
        throw MissingPluginException('Invalid slider interaction payload.');
      default:
        throw MissingPluginException('No handler for ${call.method}.');
    }
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

    if (!isInteracting && _hasPendingConfigurationSync) {
      _hasPendingConfigurationSync = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isInteractingNatively) {
          _updateNativeConfiguration();
        }
      });
    }
  }
}
