import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

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
    final Widget content = _AppleLiquidSurfaceContent(
      borderRadius: borderRadius,
      padding: padding,
      tintColor: tintColor,
      clear: clear,
      interactive: interactive,
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
  });

  final Widget? child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final Color? tintColor;
  final bool clear;
  final bool interactive;

  @override
  Widget build(BuildContext context) {
    final Widget surface =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
        ? AppleLiquidUiKitView(
            viewType: 'mjn_liquid_ui_surface',
            layoutDirection: Directionality.of(context),
            creationParamsCodec: const StandardMessageCodec(),
            creationParams: <String, Object?>{
              'borderRadius': borderRadius,
              'tintColor': tintColor?.toARGB32(),
              'clear': clear,
              'interactive': interactive,
            },
            hitTestBehavior: PlatformViewHitTestBehavior.transparent,
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
