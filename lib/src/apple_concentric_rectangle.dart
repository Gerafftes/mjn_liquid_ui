import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'apple_liquid_platform_view.dart';

/// The way a corner of an [AppleConcentricRectangle] is resolved.
enum AppleConcentricCornerStyleKind { concentric, fixed }

/// A fixed or container-relative corner style.
@immutable
class AppleConcentricCornerStyle {
  /// Creates a corner that shares its center with the container's corner.
  ///
  /// [minimumRadius] keeps the corner rounded when the calculated concentric
  /// radius would otherwise be smaller.
  const AppleConcentricCornerStyle.concentric({this.minimumRadius})
    : kind = AppleConcentricCornerStyleKind.concentric,
      _radius = 0,
      assert(minimumRadius == null || minimumRadius >= 0);

  /// Creates a corner with a fixed [radius].
  ///
  /// Use a radius of zero for a square corner.
  const AppleConcentricCornerStyle.fixed(double radius)
    : kind = AppleConcentricCornerStyleKind.fixed,
      minimumRadius = null,
      _radius = radius,
      assert(radius >= 0);

  /// Whether this corner is concentric or fixed.
  final AppleConcentricCornerStyleKind kind;

  /// The minimum radius for a concentric corner.
  final double? minimumRadius;

  /// The radius for a fixed corner.
  final double _radius;

  /// The radius for a fixed corner, or null for a concentric corner.
  double? get radius =>
      kind == AppleConcentricCornerStyleKind.fixed ? _radius : null;

  void _validate() {
    switch (kind) {
      case AppleConcentricCornerStyleKind.concentric:
        _requireValidRadius(minimumRadius, 'minimumRadius');
        break;
      case AppleConcentricCornerStyleKind.fixed:
        _requireValidRadius(radius, 'radius', required: true);
        break;
    }
  }

  Map<String, Object?> _toMap() {
    return <String, Object?>{
      'kind': kind.name,
      if (minimumRadius != null) 'minimumRadius': minimumRadius,
      if (radius != null) 'radius': radius,
    };
  }

  double _fallbackRadius(double? containerCornerRadius, double inset) {
    switch (kind) {
      case AppleConcentricCornerStyleKind.fixed:
        return radius!;
      case AppleConcentricCornerStyleKind.concentric:
        final double concentricRadius = containerCornerRadius == null
            ? 0
            : _maxDouble(containerCornerRadius - inset, 0);
        return _maxDouble(concentricRadius, minimumRadius ?? 0);
    }
  }

  @override
  bool operator ==(Object other) {
    return other is AppleConcentricCornerStyle &&
        other.kind == kind &&
        other.minimumRadius == minimumRadius &&
        other.radius == radius;
  }

  @override
  int get hashCode => Object.hash(kind, minimumRadius, radius);
}

/// Which corners use SwiftUI's uniform-radius calculation.
enum AppleConcentricRectangleCornerGrouping {
  individual,
  all,
  topAndBottom,
  leadingAndTrailing,
  top,
  bottom,
  leading,
  trailing,
}

/// Corner configuration for an [AppleConcentricRectangle].
@immutable
class AppleConcentricRectangleCorners {
  /// Creates a rectangle with four independently resolved corners.
  const AppleConcentricRectangleCorners({
    this.topLeadingCorner = const AppleConcentricCornerStyle.concentric(),
    this.topTrailingCorner = const AppleConcentricCornerStyle.concentric(),
    this.bottomLeadingCorner = const AppleConcentricCornerStyle.concentric(),
    this.bottomTrailingCorner = const AppleConcentricCornerStyle.concentric(),
  }) : grouping = AppleConcentricRectangleCornerGrouping.individual;

  /// Applies [corners] to all four corners.
  ///
  /// When [isUniform] is true, SwiftUI first resolves every corner and then
  /// uses the largest calculated radius for all four corners.
  const AppleConcentricRectangleCorners.all(
    AppleConcentricCornerStyle corners, {
    bool isUniform = false,
  }) : topLeadingCorner = corners,
       topTrailingCorner = corners,
       bottomLeadingCorner = corners,
       bottomTrailingCorner = corners,
       grouping = isUniform
           ? AppleConcentricRectangleCornerGrouping.all
           : AppleConcentricRectangleCornerGrouping.individual;

  /// Resolves the top pair and bottom pair uniformly.
  const AppleConcentricRectangleCorners.uniformTopAndBottom({
    AppleConcentricCornerStyle uniformTopCorners =
        const AppleConcentricCornerStyle.concentric(),
    AppleConcentricCornerStyle uniformBottomCorners =
        const AppleConcentricCornerStyle.concentric(),
  }) : topLeadingCorner = uniformTopCorners,
       topTrailingCorner = uniformTopCorners,
       bottomLeadingCorner = uniformBottomCorners,
       bottomTrailingCorner = uniformBottomCorners,
       grouping = AppleConcentricRectangleCornerGrouping.topAndBottom;

  /// Resolves the leading pair and trailing pair uniformly.
  const AppleConcentricRectangleCorners.uniformLeadingAndTrailing({
    AppleConcentricCornerStyle uniformLeadingCorners =
        const AppleConcentricCornerStyle.concentric(),
    AppleConcentricCornerStyle uniformTrailingCorners =
        const AppleConcentricCornerStyle.concentric(),
  }) : topLeadingCorner = uniformLeadingCorners,
       bottomLeadingCorner = uniformLeadingCorners,
       topTrailingCorner = uniformTrailingCorners,
       bottomTrailingCorner = uniformTrailingCorners,
       grouping = AppleConcentricRectangleCornerGrouping.leadingAndTrailing;

  /// Resolves the top pair uniformly and keeps both bottom corners separate.
  const AppleConcentricRectangleCorners.uniformTop({
    AppleConcentricCornerStyle uniformTopCorners =
        const AppleConcentricCornerStyle.concentric(),
    this.bottomLeadingCorner = const AppleConcentricCornerStyle.concentric(),
    this.bottomTrailingCorner = const AppleConcentricCornerStyle.concentric(),
  }) : topLeadingCorner = uniformTopCorners,
       topTrailingCorner = uniformTopCorners,
       grouping = AppleConcentricRectangleCornerGrouping.top;

  /// Resolves the bottom pair uniformly and keeps both top corners separate.
  const AppleConcentricRectangleCorners.uniformBottom({
    AppleConcentricCornerStyle uniformBottomCorners =
        const AppleConcentricCornerStyle.concentric(),
    this.topLeadingCorner = const AppleConcentricCornerStyle.concentric(),
    this.topTrailingCorner = const AppleConcentricCornerStyle.concentric(),
  }) : bottomLeadingCorner = uniformBottomCorners,
       bottomTrailingCorner = uniformBottomCorners,
       grouping = AppleConcentricRectangleCornerGrouping.bottom;

  /// Resolves the leading pair uniformly and keeps trailing corners separate.
  const AppleConcentricRectangleCorners.uniformLeading({
    AppleConcentricCornerStyle uniformLeadingCorners =
        const AppleConcentricCornerStyle.concentric(),
    this.topTrailingCorner = const AppleConcentricCornerStyle.concentric(),
    this.bottomTrailingCorner = const AppleConcentricCornerStyle.concentric(),
  }) : topLeadingCorner = uniformLeadingCorners,
       bottomLeadingCorner = uniformLeadingCorners,
       grouping = AppleConcentricRectangleCornerGrouping.leading;

  /// Resolves the trailing pair uniformly and keeps leading corners separate.
  const AppleConcentricRectangleCorners.uniformTrailing({
    AppleConcentricCornerStyle uniformTrailingCorners =
        const AppleConcentricCornerStyle.concentric(),
    this.topLeadingCorner = const AppleConcentricCornerStyle.concentric(),
    this.bottomLeadingCorner = const AppleConcentricCornerStyle.concentric(),
  }) : topTrailingCorner = uniformTrailingCorners,
       bottomTrailingCorner = uniformTrailingCorners,
       grouping = AppleConcentricRectangleCornerGrouping.trailing;

  /// The top-leading corner style.
  final AppleConcentricCornerStyle topLeadingCorner;

  /// The top-trailing corner style.
  final AppleConcentricCornerStyle topTrailingCorner;

  /// The bottom-leading corner style.
  final AppleConcentricCornerStyle bottomLeadingCorner;

  /// The bottom-trailing corner style.
  final AppleConcentricCornerStyle bottomTrailingCorner;

  /// The corners that share a uniform resolved radius.
  final AppleConcentricRectangleCornerGrouping grouping;

  void _validate() {
    topLeadingCorner._validate();
    topTrailingCorner._validate();
    bottomLeadingCorner._validate();
    bottomTrailingCorner._validate();
  }

  Map<String, Object?> _toMap() {
    return <String, Object?>{
      'grouping': grouping.name,
      'topLeading': topLeadingCorner._toMap(),
      'topTrailing': topTrailingCorner._toMap(),
      'bottomLeading': bottomLeadingCorner._toMap(),
      'bottomTrailing': bottomTrailingCorner._toMap(),
    };
  }

  _AppleConcentricRectangleRadii _fallbackRadii({
    required double? containerCornerRadius,
    required double inset,
  }) {
    double topLeading = topLeadingCorner._fallbackRadius(
      containerCornerRadius,
      inset,
    );
    double topTrailing = topTrailingCorner._fallbackRadius(
      containerCornerRadius,
      inset,
    );
    double bottomLeading = bottomLeadingCorner._fallbackRadius(
      containerCornerRadius,
      inset,
    );
    double bottomTrailing = bottomTrailingCorner._fallbackRadius(
      containerCornerRadius,
      inset,
    );

    switch (grouping) {
      case AppleConcentricRectangleCornerGrouping.individual:
        break;
      case AppleConcentricRectangleCornerGrouping.all:
        final double largest = <double>[
          topLeading,
          topTrailing,
          bottomLeading,
          bottomTrailing,
        ].reduce(_maxDouble);
        topLeading = largest;
        topTrailing = largest;
        bottomLeading = largest;
        bottomTrailing = largest;
        break;
      case AppleConcentricRectangleCornerGrouping.topAndBottom:
        final double top = _maxDouble(topLeading, topTrailing);
        final double bottom = _maxDouble(bottomLeading, bottomTrailing);
        topLeading = top;
        topTrailing = top;
        bottomLeading = bottom;
        bottomTrailing = bottom;
        break;
      case AppleConcentricRectangleCornerGrouping.leadingAndTrailing:
        final double leading = _maxDouble(topLeading, bottomLeading);
        final double trailing = _maxDouble(topTrailing, bottomTrailing);
        topLeading = leading;
        bottomLeading = leading;
        topTrailing = trailing;
        bottomTrailing = trailing;
        break;
      case AppleConcentricRectangleCornerGrouping.top:
        final double top = _maxDouble(topLeading, topTrailing);
        topLeading = top;
        topTrailing = top;
        break;
      case AppleConcentricRectangleCornerGrouping.bottom:
        final double bottom = _maxDouble(bottomLeading, bottomTrailing);
        bottomLeading = bottom;
        bottomTrailing = bottom;
        break;
      case AppleConcentricRectangleCornerGrouping.leading:
        final double leading = _maxDouble(topLeading, bottomLeading);
        topLeading = leading;
        bottomLeading = leading;
        break;
      case AppleConcentricRectangleCornerGrouping.trailing:
        final double trailing = _maxDouble(topTrailing, bottomTrailing);
        topTrailing = trailing;
        bottomTrailing = trailing;
        break;
    }

    return _AppleConcentricRectangleRadii(
      topLeading: topLeading,
      topTrailing: topTrailing,
      bottomLeading: bottomLeading,
      bottomTrailing: bottomTrailing,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is AppleConcentricRectangleCorners &&
        other.topLeadingCorner == topLeadingCorner &&
        other.topTrailingCorner == topTrailingCorner &&
        other.bottomLeadingCorner == bottomLeadingCorner &&
        other.bottomTrailingCorner == bottomTrailingCorner &&
        other.grouping == grouping;
  }

  @override
  int get hashCode => Object.hash(
    topLeadingCorner,
    topTrailingCorner,
    bottomLeadingCorner,
    bottomTrailingCorner,
    grouping,
  );
}

/// A rectangle whose corners can follow the curvature of a container.
///
/// On iOS 26 and newer this uses SwiftUI's native `ConcentricRectangle`.
/// Earlier iOS versions and other platforms use fixed-radius fallbacks.
class AppleConcentricRectangle extends StatelessWidget {
  static const String _viewType = 'mjn_liquid_ui_concentric_rectangle';

  /// Creates a filled concentric rectangle with optional Flutter content.
  const AppleConcentricRectangle({
    super.key,
    required this.color,
    this.child,
    this.width,
    this.height,
    this.inset = 0,
    this.containerCornerRadius,
    this.corners = const AppleConcentricRectangleCorners(),
    this.padding = EdgeInsets.zero,
  }) : assert(width == null || width >= 0),
       assert(height == null || height >= 0),
       assert(inset >= 0),
       assert(containerCornerRadius == null || containerCornerRadius >= 0);

  /// The fill color of the rectangle.
  final Color color;

  /// Optional Flutter content painted above the native shape.
  final Widget? child;

  /// Optional width of the rectangle.
  final double? width;

  /// Optional height of the rectangle.
  final double? height;

  /// The uniform distance between the container and the rectangle.
  ///
  /// Keep the platform view at the container's full size and use this inset,
  /// rather than padding the widget externally, so SwiftUI can calculate the
  /// correct concentric radii.
  final double inset;

  /// An optional fixed radius for a custom rounded container.
  ///
  /// Leave this null to use the system-provided container shape on iOS 26.
  final double? containerCornerRadius;

  /// The style and uniform calculation mode for each corner.
  final AppleConcentricRectangleCorners corners;

  /// Padding applied around [child].
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    _validateConfiguration();

    final TextDirection textDirection = Directionality.of(context);
    final Widget shape = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
        ? AppleLiquidUiKitView(
            key: ValueKey<Object>((
              color: color.toARGB32(),
              inset: inset,
              containerCornerRadius: containerCornerRadius,
              corners: corners,
            )),
            viewType: _viewType,
            layoutDirection: textDirection,
            creationParamsCodec: const StandardMessageCodec(),
            creationParams: <String, Object?>{
              'color': color.toARGB32(),
              'inset': inset,
              'containerCornerRadius': containerCornerRadius,
              'corners': corners._toMap(),
            },
            hitTestBehavior: PlatformViewHitTestBehavior.transparent,
          )
        : CustomPaint(
            painter: _AppleConcentricRectanglePainter(
              color: color,
              inset: inset,
              containerCornerRadius: containerCornerRadius,
              corners: corners,
              textDirection: textDirection,
            ),
          );

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        fit: StackFit.passthrough,
        children: <Widget>[
          Positioned.fill(child: shape),
          Padding(padding: padding, child: child ?? const SizedBox.shrink()),
        ],
      ),
    );
  }

  void _validateConfiguration() {
    _requireValidRadius(width, 'width');
    _requireValidRadius(height, 'height');
    _requireValidRadius(inset, 'inset', required: true);
    _requireValidRadius(containerCornerRadius, 'containerCornerRadius');
    corners._validate();
  }
}

class _AppleConcentricRectanglePainter extends CustomPainter {
  const _AppleConcentricRectanglePainter({
    required this.color,
    required this.inset,
    required this.containerCornerRadius,
    required this.corners,
    required this.textDirection,
  });

  final Color color;
  final double inset;
  final double? containerCornerRadius;
  final AppleConcentricRectangleCorners corners;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    final double resolvedInset = inset
        .clamp(0, size.shortestSide / 2)
        .toDouble();
    final Rect rect = Offset.zero & size;
    final Rect insetRect = rect.deflate(resolvedInset);
    final _AppleConcentricRectangleRadii radii = corners._fallbackRadii(
      containerCornerRadius: containerCornerRadius,
      inset: resolvedInset,
    );

    final bool isLeftToRight = textDirection == TextDirection.ltr;
    final RRect roundedRectangle = RRect.fromRectAndCorners(
      insetRect,
      topLeft: Radius.circular(
        isLeftToRight ? radii.topLeading : radii.topTrailing,
      ),
      topRight: Radius.circular(
        isLeftToRight ? radii.topTrailing : radii.topLeading,
      ),
      bottomLeft: Radius.circular(
        isLeftToRight ? radii.bottomLeading : radii.bottomTrailing,
      ),
      bottomRight: Radius.circular(
        isLeftToRight ? radii.bottomTrailing : radii.bottomLeading,
      ),
    );

    canvas.drawRRect(roundedRectangle, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _AppleConcentricRectanglePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.inset != inset ||
        oldDelegate.containerCornerRadius != containerCornerRadius ||
        oldDelegate.corners != corners ||
        oldDelegate.textDirection != textDirection;
  }
}

class _AppleConcentricRectangleRadii {
  const _AppleConcentricRectangleRadii({
    required this.topLeading,
    required this.topTrailing,
    required this.bottomLeading,
    required this.bottomTrailing,
  });

  final double topLeading;
  final double topTrailing;
  final double bottomLeading;
  final double bottomTrailing;
}

double _maxDouble(double first, double second) {
  return first > second ? first : second;
}

void _requireValidRadius(double? value, String name, {bool required = false}) {
  if (value == null) {
    if (required) {
      throw ArgumentError.notNull(name);
    }
    return;
  }

  if (!value.isFinite || value < 0) {
    throw ArgumentError.value(value, name, 'must be finite and non-negative');
  }
}
