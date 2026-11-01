part of 'apple_liquid_sheet.dart';

/// Native form content for a popover. Sections are always supplied by the app.
class AppleLiquidPopoverContent extends AppleLiquidSheetContent {
  const AppleLiquidPopoverContent({
    super.title = '',
    super.doneSemanticLabel,
    super.leadingAction,
    super.trailingAction,
    super.showsSectionBackgrounds,
    super.sectionSpacing,
    required super.sections,
  });
}

/// Permitted directions for the native popover arrow.
enum AppleLiquidPopoverArrowDirection { up, down, left, right }

/// How iOS presents a popover in a compact size class.
enum AppleLiquidPopoverCompactBehavior { automatic, popover }

/// Native navigation title sizing inside a popover.
enum AppleLiquidPopoverTitleDisplayMode { automatic, inline, large }

/// Native popover dimensions, appearance and presentation behavior.
///
/// Dimensions and insets use logical points. The default preferred width is
/// 320 points; an omitted height uses the native content's layout estimate.
/// Available screen space takes precedence over preferred sizes and bounds.
/// Invalid dimensions or insets throw [ArgumentError] when shown in any build.
@immutable
class AppleLiquidPopoverOptions {
  const AppleLiquidPopoverOptions({
    this.width,
    this.height,
    this.minWidth = 1,
    this.maxWidth,
    this.minHeight = 1,
    this.maxHeight,
    this.arrowDirections = const <AppleLiquidPopoverArrowDirection>[
      AppleLiquidPopoverArrowDirection.up,
      AppleLiquidPopoverArrowDirection.down,
      AppleLiquidPopoverArrowDirection.left,
      AppleLiquidPopoverArrowDirection.right,
    ],
    this.layoutMargins = const EdgeInsets.all(10),
    this.contentPadding = EdgeInsets.zero,
    this.backgroundColor,
    this.tintColor,
    this.compactBehavior = AppleLiquidPopoverCompactBehavior.automatic,
    this.titleDisplayMode = AppleLiquidPopoverTitleDisplayMode.inline,
    this.dismissOnTapOutside = true,
    this.canOverlapSourceRect = false,
    this.showsToolbarActions = false,
    this.animated = true,
  });

  /// Preferred outer width. Null uses the native 320-point default.
  final double? width;

  /// Preferred outer height. Null sizes from the supplied native content.
  final double? height;

  /// Smallest preferred width, subject to available screen space.
  final double minWidth;

  /// Largest preferred width. Null permits all available space.
  final double? maxWidth;

  /// Smallest preferred height, subject to available screen space.
  final double minHeight;

  /// Largest preferred height. Overflowing forms remain scrollable.
  final double? maxHeight;

  /// Allowed arrow directions; an empty list hides the arrow.
  final List<AppleLiquidPopoverArrowDirection> arrowDirections;

  /// Insets limiting where iOS may position the popover.
  final EdgeInsets layoutMargins;

  /// Insets around the native navigation and form content.
  final EdgeInsets contentPadding;

  /// Optional native backdrop color. Null keeps the system appearance.
  final Color? backgroundColor;

  /// Optional tint inherited by native controls that have no explicit tint.
  final Color? tintColor;

  /// Whether UIKit may adapt the presentation in compact layouts.
  final AppleLiquidPopoverCompactBehavior compactBehavior;

  /// Navigation title sizing. Inline titles preserve space in narrow popovers.
  final AppleLiquidPopoverTitleDisplayMode titleDisplayMode;

  /// Allows outside taps and interactive adapted-presentation dismissal.
  final bool dismissOnTapOutside;

  /// Allows iOS to overlap the anchor rectangle when space is constrained.
  final bool canOverlapSourceRect;

  /// Shows the content's confirmation/cancellation toolbar actions.
  final bool showsToolbarActions;

  /// Animates native presentation and programmatic dismissal.
  final bool animated;

  Map<String, Object?> _toMap() {
    for (final entry in <String, double?>{
      'width': width,
      'height': height,
      'minWidth': minWidth,
      'maxWidth': maxWidth,
      'minHeight': minHeight,
      'maxHeight': maxHeight,
    }.entries) {
      final value = entry.value;
      if (value != null && (!value.isFinite || value <= 0)) {
        throw ArgumentError.value(
          value,
          entry.key,
          'Must be finite and positive',
        );
      }
    }
    if ((maxWidth != null && minWidth > maxWidth!) ||
        (maxHeight != null && minHeight > maxHeight!)) {
      throw ArgumentError(
        'Minimum dimensions must not exceed maximum dimensions',
      );
    }
    Map<String, double> insets(EdgeInsets value) {
      final map = <String, double>{
        'top': value.top,
        'left': value.left,
        'bottom': value.bottom,
        'right': value.right,
      };
      if (map.values.any((value) => !value.isFinite || value < 0)) {
        throw ArgumentError.value(
          value,
          'insets',
          'Must be finite and nonnegative',
        );
      }
      return map;
    }

    return <String, Object?>{
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      'minWidth': minWidth,
      if (maxWidth != null) 'maxWidth': maxWidth,
      'minHeight': minHeight,
      if (maxHeight != null) 'maxHeight': maxHeight,
      'arrowDirections': arrowDirections.map((value) => value.name).toList(),
      'layoutMargins': insets(layoutMargins),
      'contentPadding': insets(contentPadding),
      if (backgroundColor != null)
        'backgroundColor': backgroundColor!.toARGB32(),
      if (tintColor != null) 'tintColor': tintColor!.toARGB32(),
      'compactBehavior': compactBehavior.name,
      'titleDisplayMode': titleDisplayMode.name,
      'dismissOnTapOutside': dismissOnTapOutside,
      'canOverlapSourceRect': canOverlapSourceRect,
      'showsToolbarActions': showsToolbarActions,
      'animated': animated,
    };
  }
}

/// Builds an anchor and owns its [AppleLiquidPopoverController].
///
/// The native presentation follows this widget as it moves, and dismisses when
/// the anchor is removed, hidden by [TickerMode], or its route stops being current.
class AppleLiquidPopoverAnchor extends StatefulWidget {
  const AppleLiquidPopoverAnchor({super.key, required this.builder});

  final Widget Function(
    BuildContext context,
    AppleLiquidPopoverController controller,
  )
  builder;

  @override
  State<AppleLiquidPopoverAnchor> createState() =>
      _AppleLiquidPopoverAnchorState();
}

class _AppleLiquidPopoverAnchorState extends State<AppleLiquidPopoverAnchor>
    with WidgetsBindingObserver {
  late final AppleLiquidPopoverController _controller =
      AppleLiquidPopoverController._(this);
  final GlobalKey _anchorKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  bool get _isVisible =>
      mounted &&
      TickerMode.of(context) &&
      (ModalRoute.of(context)?.isCurrent ?? true);

  ({Rect anchor, Size viewSize})? _geometry() {
    if (!_isVisible) return null;
    final renderObject = _anchorKey.currentContext?.findRenderObject();
    if (renderObject is! RenderBox ||
        !renderObject.attached ||
        !renderObject.hasSize) {
      return null;
    }
    final view = View.of(context);
    final Size viewSize = view.physicalSize / view.devicePixelRatio;
    final Rect anchor = MatrixUtils.transformRect(
      renderObject.getTransformTo(null),
      Offset.zero & renderObject.size,
    );
    if (!anchor.isFinite ||
        anchor.isEmpty ||
        !viewSize.isFinite ||
        viewSize.isEmpty ||
        !anchor.overlaps(Offset.zero & viewSize)) {
      return null;
    }
    return (anchor: anchor, viewSize: viewSize);
  }

  @override
  void didChangeMetrics() {
    if (_controller.isShowing) WidgetsBinding.instance.ensureVisualUpdate();
  }

  @override
  Widget build(BuildContext context) {
    // Establish dependencies so route and TickerMode changes produce a frame.
    TickerMode.of(context);
    ModalRoute.of(context);
    return SizedBox(
      key: _anchorKey,
      child: widget.builder(context, _controller),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller._detach();
    super.dispose();
  }
}

/// Controller owned by [AppleLiquidPopoverAnchor]; do not dispose it yourself.
class AppleLiquidPopoverController {
  AppleLiquidPopoverController._(this._owner);

  static const MethodChannel _channel = MethodChannel('mjn_liquid_ui/popovers');
  static int _nextSessionId = 0;
  _AppleLiquidPopoverAnchorState? _owner;
  int? _sessionId;
  _AppleLiquidSheetActionRegistry? _registry;
  bool _dismissInFlight = false;
  ({Rect anchor, Size viewSize})? _lastGeometry;

  bool get isShowing => _sessionId != null;

  /// Shows caller-supplied native content, returning final text field values.
  ///
  /// Content and options are captured for this presentation. Updates apply to
  /// the next [show] call. Unsupported platforms and unavailable anchors return
  /// [AppleLiquidSheetResultStatus.notPresented]. Confirmation returns `saved`;
  /// other dismissal returns `cancelled`, preserving final text-field values.
  Future<AppleLiquidSheetResult> show({
    required AppleLiquidSheetContent content,
    AppleLiquidPopoverOptions options = const AppleLiquidPopoverOptions(),
  }) async {
    final optionsMap = options._toMap();
    if (isShowing) {
      return AppleLiquidSheetResult(
        status: AppleLiquidSheetResultStatus.alreadyShowing,
      );
    }
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      return AppleLiquidSheetResult(
        status: AppleLiquidSheetResultStatus.notPresented,
      );
    }
    final geometry = _owner?._geometry();
    if (geometry == null) {
      return AppleLiquidSheetResult(
        status: AppleLiquidSheetResultStatus.notPresented,
      );
    }
    final int sessionId = _nextSessionId++;
    final registry = _AppleLiquidSheetActionRegistry();
    _sessionId = sessionId;
    _registry = registry;
    _lastGeometry = geometry;
    _channel.setMethodCallHandler(AppleLiquidSheet._handleMethodCall);
    try {
      final contentMap = content._toMap(registry);
      _watchGeometry(sessionId);
      final result = await _channel
          .invokeMethod<Object?>('showPopover', <String, Object?>{
            'sessionId': sessionId,
            ..._geometryMap(geometry),
            'content': contentMap,
            'options': optionsMap,
          });
      return registry.resultFrom(result);
    } finally {
      registry.dispose();
      if (_sessionId == sessionId) {
        _sessionId = null;
        _registry = null;
        _lastGeometry = null;
      }
    }
  }

  /// Dismisses only this anchor's active presentation.
  Future<bool> dismiss() async {
    final sessionId = _sessionId;
    if (sessionId == null) return false;
    return await _channel.invokeMethod<bool>(
          'dismissPopover',
          <String, Object?>{'sessionId': sessionId},
        ) ??
        false;
  }

  Map<String, Object?> _geometryMap(({Rect anchor, Size viewSize}) geometry) =>
      {
        'anchor': <String, double>{
          'x': geometry.anchor.left,
          'y': geometry.anchor.top,
          'width': geometry.anchor.width,
          'height': geometry.anchor.height,
        },
        'viewSize': <String, double>{
          'width': geometry.viewSize.width,
          'height': geometry.viewSize.height,
        },
      };

  void _watchGeometry(int sessionId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_sessionId != sessionId) return;
      final geometry = _owner?._geometry();
      if (geometry == null) {
        _dismissSafely();
      } else if (geometry != _lastGeometry) {
        _lastGeometry = geometry;
        unawaited(_updateAnchor(sessionId, geometry));
      }
      if (_sessionId == sessionId && _owner != null) _watchGeometry(sessionId);
    });
  }

  Future<void> _updateAnchor(
    int sessionId,
    ({Rect anchor, Size viewSize}) geometry,
  ) async {
    try {
      await _channel.invokeMethod<bool>('updateAnchor', <String, Object?>{
        'sessionId': sessionId,
        ..._geometryMap(geometry),
      });
    } catch (error, stack) {
      _reportError(error, stack, 'updating a popover anchor');
      if (_sessionId == sessionId && _lastGeometry == geometry) {
        _lastGeometry = null;
      }
    }
  }

  void _detach() {
    _owner = null;
    _registry?.dispose();
    _dismissSafely();
  }

  void _dismissSafely() {
    if (!isShowing || _dismissInFlight) return;
    _dismissInFlight = true;
    unawaited(
      dismiss()
          .catchError((Object error, StackTrace stack) {
            _reportError(error, stack, 'dismissing a popover');
            return false;
          })
          .whenComplete(() => _dismissInFlight = false),
    );
  }

  void _reportError(Object error, StackTrace stack, String operation) {
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stack,
        library: 'mjn_liquid_ui',
        context: ErrorDescription('while $operation'),
      ),
    );
  }
}
