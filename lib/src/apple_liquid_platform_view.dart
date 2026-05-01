import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

typedef AppleLiquidPlatformViewCreatedCallback = void Function(int id);

int _nextAppleLiquidPlatformViewId = DateTime.now().microsecondsSinceEpoch;

int _allocateAppleLiquidPlatformViewId() {
  return _nextAppleLiquidPlatformViewId += 1;
}

class AppleLiquidUiKitView extends StatefulWidget {
  const AppleLiquidUiKitView({
    super.key,
    required this.viewType,
    this.onPlatformViewCreated,
    this.hitTestBehavior = PlatformViewHitTestBehavior.opaque,
    this.layoutDirection,
    this.creationParams,
    this.creationParamsCodec,
    this.gestureRecognizers,
  }) : assert(creationParams == null || creationParamsCodec != null);

  final String viewType;
  final AppleLiquidPlatformViewCreatedCallback? onPlatformViewCreated;
  final PlatformViewHitTestBehavior hitTestBehavior;
  final TextDirection? layoutDirection;
  final Object? creationParams;
  final MessageCodec<Object?>? creationParamsCodec;
  final Set<Factory<OneSequenceGestureRecognizer>>? gestureRecognizers;

  @override
  State<AppleLiquidUiKitView> createState() => _AppleLiquidUiKitViewState();
}

class _AppleLiquidUiKitViewState extends State<AppleLiquidUiKitView> {
  UiKitViewController? _controller;
  TextDirection? _layoutDirection;
  FocusNode? _focusNode;
  int _createGeneration = 0;
  bool _isCreatingController = false;

  static final Set<Factory<OneSequenceGestureRecognizer>> _emptyRecognizers =
      <Factory<OneSequenceGestureRecognizer>>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final TextDirection newLayoutDirection = _findLayoutDirection();
    final bool didChangeLayoutDirection =
        _layoutDirection != newLayoutDirection;
    _layoutDirection = newLayoutDirection;

    if (_controller == null && !_isCreatingController) {
      _createNewViewController();
    }

    if (didChangeLayoutDirection) {
      _controller?.setLayoutDirection(newLayoutDirection);
    }
  }

  @override
  void didUpdateWidget(covariant AppleLiquidUiKitView oldWidget) {
    super.didUpdateWidget(oldWidget);

    final TextDirection newLayoutDirection = _findLayoutDirection();
    final bool didChangeLayoutDirection =
        _layoutDirection != newLayoutDirection;
    _layoutDirection = newLayoutDirection;

    if (oldWidget.viewType != widget.viewType) {
      _disposeController();
      _createNewViewController();
      return;
    }

    if (didChangeLayoutDirection) {
      _controller?.setLayoutDirection(newLayoutDirection);
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final UiKitViewController? controller = _controller;
    if (controller == null) {
      return const SizedBox.expand();
    }

    return Focus(
      focusNode: _focusNode,
      onFocusChange: (bool isFocused) {
        if (isFocused) {
          SystemChannels.textInput.invokeMethod<void>(
            'TextInput.setPlatformViewClient',
            <String, Object?>{'platformViewId': controller.id},
          );
        }
      },
      child: _AppleLiquidUiKitPlatformView(
        controller: controller,
        hitTestBehavior: widget.hitTestBehavior,
        gestureRecognizers: widget.gestureRecognizers ?? _emptyRecognizers,
      ),
    );
  }

  TextDirection _findLayoutDirection() {
    assert(
      widget.layoutDirection != null || debugCheckHasDirectionality(context),
    );
    return widget.layoutDirection ?? Directionality.of(context);
  }

  void _createNewViewController() {
    final int generation = _createGeneration;
    final int id = _allocateAppleLiquidPlatformViewId();
    _isCreatingController = true;
    final Future<UiKitViewController> controller =
        PlatformViewsService.initUiKitView(
          id: id,
          viewType: widget.viewType,
          layoutDirection: _layoutDirection!,
          creationParams: widget.creationParams,
          creationParamsCodec: widget.creationParamsCodec,
          onFocus: () => _focusNode?.requestFocus(),
        );

    controller.then(
      (UiKitViewController controller) {
        if (!mounted || generation != _createGeneration) {
          controller.dispose();
          return;
        }

        setState(() {
          _controller = controller;
          _focusNode = FocusNode(debugLabel: 'AppleLiquidUiKitView(id: $id)');
          _isCreatingController = false;
        });
        widget.onPlatformViewCreated?.call(id);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!mounted || generation != _createGeneration) {
          return;
        }

        if (error is PlatformException && error.code == 'recreating_view') {
          _isCreatingController = false;
          _createNewViewController();
          return;
        }

        setState(() {
          _isCreatingController = false;
        });
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'mjn_liquid_ui',
            context: ErrorDescription('creating an iOS platform view'),
          ),
        );
      },
    );
  }

  void _disposeController() {
    _createGeneration += 1;
    _controller?.dispose();
    _controller = null;
    _isCreatingController = false;
    _focusNode?.dispose();
    _focusNode = null;
  }
}

class _AppleLiquidUiKitPlatformView extends LeafRenderObjectWidget {
  const _AppleLiquidUiKitPlatformView({
    required this.controller,
    required this.hitTestBehavior,
    required this.gestureRecognizers,
  });

  final UiKitViewController controller;
  final PlatformViewHitTestBehavior hitTestBehavior;
  final Set<Factory<OneSequenceGestureRecognizer>> gestureRecognizers;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderUiKitView(
      viewController: controller,
      hitTestBehavior: hitTestBehavior,
      gestureRecognizers: gestureRecognizers,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderUiKitView renderObject) {
    renderObject
      ..viewController = controller
      ..hitTestBehavior = hitTestBehavior
      ..updateGestureRecognizers(gestureRecognizers);
  }
}
