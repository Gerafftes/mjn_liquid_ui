import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

enum AppleLiquidStretchGestureMode {
  /// Reacts to raw pointer events before child gestures are resolved.
  listener,

  /// Lets child gestures such as buttons win taps and only stretches on pans.
  gestureDetector,
}

/// Adds an interactive squash and stretch response to a glass widget.
///
/// The effect listens to raw pointer movement, applies resistance to the drag
/// distance, and paints the child with a small elastic transform. It is kept in
/// Flutter so it can deform native platform-view glass and Flutter content
/// together.
class AppleLiquidStretch extends StatefulWidget {
  const AppleLiquidStretch({
    super.key,
    required this.child,
    this.enabled = true,
    this.stretch = 0.22,
    this.interactionScale = 1.018,
    this.pressedScale = 0.995,
    this.resistance = 0.08,
    this.hitTestBehavior = HitTestBehavior.translucent,
    this.gestureMode = AppleLiquidStretchGestureMode.listener,
    this.releaseDuration = const Duration(milliseconds: 320),
    this.scaleDuration = const Duration(milliseconds: 140),
    this.releaseCurve = Curves.easeOutBack,
  });

  final Widget child;
  final bool enabled;

  /// Multiplies the resisted drag offset to produce stretch in pixels.
  final double stretch;

  /// A subtle growth applied while the pointer is active.
  final double interactionScale;

  /// A subtle press compression applied while the pointer is active.
  final double pressedScale;

  /// Higher values make drag movement feel stickier.
  final double resistance;

  final HitTestBehavior hitTestBehavior;
  final AppleLiquidStretchGestureMode gestureMode;
  final Duration releaseDuration;
  final Duration scaleDuration;
  final Curve releaseCurve;

  @override
  State<AppleLiquidStretch> createState() => _AppleLiquidStretchState();
}

class _AppleLiquidStretchState extends State<AppleLiquidStretch>
    with SingleTickerProviderStateMixin {
  late final AnimationController _releaseController;

  Animation<Offset>? _releaseAnimation;
  Offset _dragOffset = Offset.zero;
  Offset _stretchPixels = Offset.zero;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();

    _releaseController = AnimationController(
      vsync: this,
      duration: widget.releaseDuration,
    )..addListener(_handleReleaseTick);
  }

  @override
  void didUpdateWidget(covariant AppleLiquidStretch oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.releaseDuration != widget.releaseDuration) {
      _releaseController.duration = widget.releaseDuration;
    }

    if (_pressed &&
        (oldWidget.stretch != widget.stretch ||
            oldWidget.resistance != widget.resistance)) {
      _setStretchPixels(_stretchForDrag(_dragOffset));
    }
  }

  @override
  void dispose() {
    _releaseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled ||
        (widget.stretch == 0 &&
            widget.interactionScale == 1 &&
            widget.pressedScale == 1)) {
      return widget.child;
    }

    final double activeScale = _pressed
        ? widget.interactionScale * widget.pressedScale
        : 1;

    final Widget stretchedChild = AnimatedScale(
      duration: widget.scaleDuration,
      curve: Curves.easeOutCubic,
      scale: activeScale,
      child: _RawAppleLiquidStretch(
        stretchPixels: _stretchPixels,
        child: widget.child,
      ),
    );

    switch (widget.gestureMode) {
      case AppleLiquidStretchGestureMode.listener:
        return Listener(
          behavior: widget.hitTestBehavior,
          onPointerDown: (_) => _beginStretch(),
          onPointerMove: (PointerMoveEvent event) {
            _updateStretch(event.delta);
          },
          onPointerUp: (_) => _releaseStretch(),
          onPointerCancel: (_) => _releaseStretch(),
          child: stretchedChild,
        );
      case AppleLiquidStretchGestureMode.gestureDetector:
        return GestureDetector(
          behavior: widget.hitTestBehavior,
          onPanStart: (_) => _beginStretch(),
          onPanUpdate: (DragUpdateDetails details) {
            _updateStretch(details.delta);
          },
          onPanEnd: (_) => _releaseStretch(),
          onPanCancel: _releaseStretch,
          child: stretchedChild,
        );
    }
  }

  void _beginStretch() {
    _releaseController.stop();
    setState(() {
      _pressed = true;
      _dragOffset = Offset.zero;
      _stretchPixels = Offset.zero;
      _releaseAnimation = null;
    });
  }

  void _updateStretch(Offset delta) {
    _dragOffset += delta;
    _setStretchPixels(_stretchForDrag(_dragOffset));
  }

  void _releaseStretch() {
    if (!_pressed && _stretchPixels == Offset.zero) {
      return;
    }

    _pressed = false;
    _dragOffset = Offset.zero;
    _releaseAnimation = Tween<Offset>(begin: _stretchPixels, end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _releaseController,
            curve: widget.releaseCurve,
          ),
        );

    _releaseController.forward(from: 0);
    setState(() {});
  }

  void _handleReleaseTick() {
    final Animation<Offset>? animation = _releaseAnimation;
    if (animation == null) {
      return;
    }

    setState(() {
      _stretchPixels = animation.value;
      if (_releaseController.isCompleted) {
        _stretchPixels = Offset.zero;
        _releaseAnimation = null;
      }
    });
  }

  Offset _stretchForDrag(Offset offset) {
    return _withResistance(offset, widget.resistance) * widget.stretch;
  }

  void _setStretchPixels(Offset offset) {
    if (_stretchPixels == offset) {
      return;
    }

    setState(() {
      _stretchPixels = offset;
    });
  }
}

class _RawAppleLiquidStretch extends SingleChildRenderObjectWidget {
  const _RawAppleLiquidStretch({
    required this.stretchPixels,
    required super.child,
  });

  final Offset stretchPixels;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderAppleLiquidStretch(stretchPixels);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderAppleLiquidStretch renderObject,
  ) {
    renderObject.stretchPixels = stretchPixels;
  }
}

class _RenderAppleLiquidStretch extends RenderProxyBox {
  _RenderAppleLiquidStretch(this._stretchPixels);

  Offset _stretchPixels;

  set stretchPixels(Offset value) {
    if (_stretchPixels == value) {
      return;
    }

    _stretchPixels = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      return;
    }

    final Matrix4? transform = _effectiveTransform();
    if (transform == null) {
      super.paint(context, offset);
      return;
    }

    final double determinant = transform.determinant();
    if (determinant == 0 || !determinant.isFinite) {
      layer = null;
      return;
    }

    layer = context.pushTransform(
      needsCompositing,
      offset,
      transform,
      super.paint,
      oldLayer: layer is TransformLayer ? layer as TransformLayer? : null,
    );
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final Matrix4? stretchTransform = _effectiveTransform();
    if (stretchTransform != null) {
      transform.multiply(stretchTransform);
    }
  }

  Matrix4? _effectiveTransform() {
    if (_stretchPixels == Offset.zero || size.isEmpty) {
      return null;
    }

    final Offset scale = _scaleForStretch(_stretchPixels, size);
    final Offset center = Offset(size.width / 2, size.height / 2);

    return Matrix4.identity()
      ..translateByDouble(
        center.dx + _stretchPixels.dx,
        center.dy + _stretchPixels.dy,
        0,
        1,
      )
      ..scaleByDouble(scale.dx, scale.dy, 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1);
  }
}

Offset _scaleForStretch(Offset stretchPixels, Size size) {
  final double relativeX = size.width > 0
      ? (stretchPixels.dx.abs() / size.width).clamp(0.0, 1.0)
      : 0;
  final double relativeY = size.height > 0
      ? (stretchPixels.dy.abs() / size.height).clamp(0.0, 1.0)
      : 0;

  final double baseScaleX = 1 + relativeX;
  final double baseScaleY = 1 + relativeY;
  final double magnitude = math.sqrt(
    relativeX * relativeX + relativeY * relativeY,
  );
  final double targetVolume = 1 + magnitude * 0.5;
  final double currentVolume = baseScaleX * baseScaleY;

  if (currentVolume == 0) {
    return const Offset(1, 1);
  }

  final double volumeCorrection = math.sqrt(targetVolume / currentVolume);

  return Offset(baseScaleX * volumeCorrection, baseScaleY * volumeCorrection);
}

Offset _withResistance(Offset offset, double resistance) {
  if (resistance <= 0) {
    return offset;
  }

  final double magnitude = math.sqrt(
    offset.dx * offset.dx + offset.dy * offset.dy,
  );

  if (magnitude == 0) {
    return Offset.zero;
  }

  final double resistedMagnitude = magnitude / (1 + magnitude * resistance);
  final double scale = resistedMagnitude / magnitude;

  return Offset(offset.dx * scale, offset.dy * scale);
}
