import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'apple_liquid_platform.dart';
import 'apple_liquid_platform_view.dart';
import 'apple_liquid_stretch.dart';

const double _defaultSurfaceStretch = 0.22;

/// A Liquid Glass surface for grouping content.
class AppleLiquidSurface extends StatelessWidget {
  /// Creates a glass surface with optional content and interactive deformation.
  const AppleLiquidSurface({
    super.key,
    this.child,
    this.height = 160,
    this.borderRadius = 28,
    this.padding = const EdgeInsets.all(20),
    this.tintColor,
    this.clear = false,
    this.interactive = false,
    this.deferMountUntilRouteTransitionCompletes = false,
    this.deformable = false,
    this.stretch = _defaultSurfaceStretch,
    this.pressedStretch = _defaultSurfaceStretch,
    this.interactionScale = 1.018,
    this.pressedScale = 0.995,
    this.resistance = 0.08,
    this.stretchGestureMode = AppleLiquidStretchGestureMode.listener,
    @Deprecated('Use deformable instead. This no longer moves the surface.')
    this.draggable = false,
    @Deprecated('Use stretch/resistance instead.') this.dragLimit = 36,
  });

  /// Optional content painted above the glass surface.
  final Widget? child;

  /// The height reserved for the surface.
  final double height;

  /// Corner radius applied to the glass shape.
  final double borderRadius;

  /// Padding applied around [child].
  final EdgeInsetsGeometry padding;

  /// Optional color used to tint the glass material.
  final Color? tintColor;

  /// Whether the surface should use a clearer, less filled appearance.
  final bool clear;

  /// Whether the native iOS surface should react to touch interaction.
  final bool interactive;

  /// Shows a lightweight Flutter background until the enclosing route has
  /// finished entering, then creates the native surface. Defaults to false.
  ///
  /// Flutter content keeps its state throughout. This shifts native setup work
  /// out of the entrance transition; it does not reduce the final native count.
  final bool deferMountUntilRouteTransitionCompletes;

  /// Whether the surface should deform while pressed or dragged.
  final bool deformable;

  /// Multiplier for drag-driven stretch when [deformable] is enabled.
  final double stretch;

  /// Stretch multiplier used while the surface is pressed.
  final double pressedStretch;

  /// Scale applied while pointer interaction is active.
  final double interactionScale;

  /// Additional compression applied during press interaction.
  final double pressedScale;

  /// Resistance applied to drag movement before stretching.
  final double resistance;

  /// Gesture strategy used by the deformation wrapper.
  final AppleLiquidStretchGestureMode stretchGestureMode;

  /// Deprecated compatibility flag for enabling deformation.
  @Deprecated('Use deformable instead. This no longer moves the surface.')
  final bool draggable;

  /// Deprecated compatibility value retained for older callers.
  @Deprecated('Use stretch/resistance instead.')
  final double dragLimit;

  @override
  Widget build(BuildContext context) {
    checkAppleLiquidPlatform();
    final Widget content = _AppleLiquidSurfaceContent(
      borderRadius: borderRadius,
      padding: padding,
      tintColor: tintColor,
      clear: clear,
      interactive: interactive,
      deferMountUntilRouteTransitionCompletes:
          deferMountUntilRouteTransitionCompletes,
      child: child,
    );

    // Keep `draggable` as a compatibility alias for older example code.
    // ignore: deprecated_member_use_from_same_package
    final bool usesDeformation = deformable || draggable;

    if (usesDeformation) {
      final double effectiveStretch = pressedStretch == _defaultSurfaceStretch
          ? stretch
          : pressedStretch;

      return _DeformableAppleLiquidSurface(
        height: height,
        pressedStretch: effectiveStretch,
        interactionScale: interactionScale,
        pressedScale: pressedScale,
        resistance: resistance,
        gestureMode: stretchGestureMode,
        child: content,
      );
    }

    return SizedBox(height: height, child: content);
  }
}

class _AppleLiquidSurfaceContent extends StatelessWidget {
  const _AppleLiquidSurfaceContent({
    required this.child,
    required this.borderRadius,
    required this.padding,
    required this.tintColor,
    required this.clear,
    required this.interactive,
    required this.deferMountUntilRouteTransitionCompletes,
  });

  final Widget? child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? tintColor;
  final bool clear;
  final bool interactive;
  final bool deferMountUntilRouteTransitionCompletes;

  @override
  Widget build(BuildContext context) {
    final Widget surface = defaultTargetPlatform == TargetPlatform.iOS
        ? _AppleLiquidSurfaceBackground(
            borderRadius: borderRadius,
            tintColor: tintColor,
            clear: clear,
            interactive: interactive,
            deferMountUntilRouteTransitionCompletes:
                deferMountUntilRouteTransitionCompletes,
          )
        : _AppleLiquidSurfaceFallback(
            borderRadius: borderRadius,
            tintColor: tintColor,
            clear: clear,
          );

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        surface,
        if (child != null) Padding(padding: padding, child: child),
      ],
    );
  }
}

class _AppleLiquidSurfaceBackground extends StatefulWidget {
  const _AppleLiquidSurfaceBackground({
    required this.borderRadius,
    required this.tintColor,
    required this.clear,
    required this.interactive,
    required this.deferMountUntilRouteTransitionCompletes,
  });

  final double borderRadius;
  final Color? tintColor;
  final bool clear;
  final bool interactive;
  final bool deferMountUntilRouteTransitionCompletes;

  @override
  State<_AppleLiquidSurfaceBackground> createState() =>
      _AppleLiquidSurfaceBackgroundState();
}

class _AppleLiquidSurfaceBackgroundState
    extends State<_AppleLiquidSurfaceBackground> {
  ModalRoute<dynamic>? _route;
  Animation<double>? _animation;
  bool _tickerEnabled = true;
  bool _mountRequested = false;
  bool _nativeMounted = false;
  bool _viewCreated = false;
  bool _mountScheduled = false;
  int _generation = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<dynamic>? route = ModalRoute.of(context);
    final Animation<double>? animation = route?.animation;
    if (_route != route || _animation != animation) {
      _animation?.removeStatusListener(_handleAnimationStatus);
      _route = route;
      _animation = animation;
      _animation?.addStatusListener(_handleAnimationStatus);
      _generation += 1;
      _mountScheduled = false;
      if (!_nativeMounted) {
        _mountRequested = false;
      }
    }
    _tickerEnabled = TickerMode.of(context);
    _requestMountIfReady();
  }

  @override
  void didUpdateWidget(covariant _AppleLiquidSurfaceBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    _requestMountIfReady();
  }

  void _handleAnimationStatus(AnimationStatus status) {
    _requestMountIfReady();
  }

  bool get _canMount =>
      _tickerEnabled &&
      (_route == null || _route!.isCurrent) &&
      (_animation == null || _animation!.status == AnimationStatus.completed);

  void _requestMountIfReady() {
    if (_mountRequested) {
      return;
    }
    if (!widget.deferMountUntilRouteTransitionCompletes) {
      _mountRequested = true;
      return;
    }
    if (!_canMount || _mountScheduled) {
      return;
    }
    _mountScheduled = true;
    final int generation = _generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || generation != _generation) {
        return;
      }
      _mountScheduled = false;
      if (!_mountRequested && _canMount) {
        setState(() => _mountRequested = true);
      }
    });
    // Status notifications can arrive outside an active frame. A post-frame
    // callback alone does not request a frame.
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  void dispose() {
    _generation += 1;
    _animation?.removeStatusListener(_handleAnimationStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    // A pop can begin between the granting post-frame callback and this build.
    // Only latch once the native widget is actually inserted into the tree.
    if (!_nativeMounted &&
        _mountRequested &&
        widget.deferMountUntilRouteTransitionCompletes &&
        !_canMount) {
      _mountRequested = false;
    }
    if (_mountRequested &&
        (!widget.deferMountUntilRouteTransitionCompletes || _canMount)) {
      _nativeMounted = true;
    }
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        if (widget.deferMountUntilRouteTransitionCompletes && !_viewCreated)
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: (widget.tintColor ?? colors.surface).withValues(
                  alpha: widget.clear ? 0.03 : 0.18,
                ),
                borderRadius: BorderRadius.circular(widget.borderRadius),
                border: Border.all(
                  color: colors.outlineVariant.withValues(alpha: 0.45),
                ),
              ),
            ),
          ),
        if (_nativeMounted)
          AppleLiquidUiKitView(
            key: const ValueKey<String>('native-surface'),
            viewType: 'mjn_liquid_ui_surface',
            layoutDirection: Directionality.of(context),
            creationParamsCodec: const StandardMessageCodec(),
            creationParams: <String, Object?>{
              'borderRadius': widget.borderRadius,
              'tintColor': widget.tintColor?.toARGB32(),
              'clear': widget.clear,
              'interactive': widget.interactive,
            },
            hitTestBehavior: PlatformViewHitTestBehavior.transparent,
            onPlatformViewCreated: (_) {
              if (mounted) {
                setState(() => _viewCreated = true);
              }
            },
          ),
      ],
    );
  }
}

class _DeformableAppleLiquidSurface extends StatelessWidget {
  const _DeformableAppleLiquidSurface({
    required this.height,
    required this.pressedStretch,
    required this.interactionScale,
    required this.pressedScale,
    required this.resistance,
    required this.gestureMode,
    required this.child,
  });

  final double height;
  final double pressedStretch;
  final double interactionScale;
  final double pressedScale;
  final double resistance;
  final AppleLiquidStretchGestureMode gestureMode;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: AppleLiquidStretch(
        stretch: pressedStretch,
        interactionScale: interactionScale,
        pressedScale: pressedScale,
        resistance: resistance,
        gestureMode: gestureMode,
        child: child,
      ),
    );
  }
}

class _AppleLiquidSurfaceFallback extends StatelessWidget {
  const _AppleLiquidSurfaceFallback({
    required this.borderRadius,
    required this.tintColor,
    required this.clear,
  });

  final double borderRadius;
  final Color? tintColor;
  final bool clear;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color baseColor = tintColor ?? colorScheme.surface;
    final double fillAlpha = clear ? 0.03 : 0.18;

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: baseColor.withValues(alpha: fillAlpha),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }
}
