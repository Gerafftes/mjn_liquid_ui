import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Callback invoked when a native toast action is pressed.
typedef AppleLiquidToastActionCallback = void Function();

class _AppleLiquidToastActionRegistration {
  const _AppleLiquidToastActionRegistration({
    required this.callback,
    required this.dismissesToast,
  });

  final AppleLiquidToastActionCallback callback;
  final bool dismissesToast;
}

/// Action button configuration for [AppleLiquidToast.show].
class AppleLiquidToastAction {
  const AppleLiquidToastAction({
    required this.title,
    this.tintColor,
    this.dismissesToast = true,
    this.onPressed,
  }) : assert(title != '');

  /// Button text displayed at the trailing edge of the toast.
  final String title;

  /// Optional native tint color for the action title.
  final Color? tintColor;

  /// Whether the native toast should dismiss immediately after tapping.
  final bool dismissesToast;

  /// Optional Dart callback invoked after the native action button is tapped.
  final AppleLiquidToastActionCallback? onPressed;
}

/// Static API for showing native iOS Liquid Glass toasts.
class AppleLiquidToast {
  AppleLiquidToast._();

  static const MethodChannel _channel = MethodChannel('mjn_liquid_ui/toasts');
  static final Map<String, _AppleLiquidToastActionRegistration> _actions =
      <String, _AppleLiquidToastActionRegistration>{};

  static bool _handlerAttached = false;
  static int _nextActionId = 0;
  static String? _activeActionId;
  static Timer? _activeActionCleanupTimer;

  /// Shows a native iOS Liquid Glass toast.
  ///
  /// Returns `false` on unsupported platforms or when the native overlay cannot
  /// be attached to the active iOS window.
  static Future<bool> show({
    required String title,
    Duration duration = const Duration(seconds: 3),
    double placementOffset = -60,
    double transitionOffset = 100,
    String? systemImage,
    AppleLiquidToastAction? action,
  }) async {
    assert(title.isNotEmpty);
    assert(duration > Duration.zero);
    assert(placementOffset.isFinite);
    assert(transitionOffset.isFinite);

    if (!_isNativeToastSupported) {
      return false;
    }

    _ensureHandlerAttached();

    final String? actionId = _registerAction(action, duration);
    final Map<String, Object?> arguments = <String, Object?>{
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'title': title,
      'duration': duration.inMicroseconds / Duration.microsecondsPerSecond,
      'placementOffset': placementOffset,
      'transitionOffset': transitionOffset,
      if (systemImage != null) 'systemImage': systemImage,
      if (action != null) ...<String, Object?>{
        'actionTitle': action.title,
        'actionTintColor': action.tintColor?.toARGB32(),
        'dismissesOnAction': action.dismissesToast,
        if (actionId != null) 'actionId': actionId,
      },
    };

    try {
      return await _channel.invokeMethod<bool>('show', arguments) ?? false;
    } on MissingPluginException {
      _removeAction(actionId);
      return false;
    } on PlatformException {
      _removeAction(actionId);
      return false;
    }
  }

  /// Dismisses the currently visible native toast.
  static Future<bool> dismiss() async {
    _clearActiveAction();

    if (!_isNativeToastSupported) {
      return false;
    }

    try {
      return await _channel.invokeMethod<bool>('dismiss') ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static bool get _isNativeToastSupported {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  }

  static void _ensureHandlerAttached() {
    if (_handlerAttached) {
      return;
    }

    _channel.setMethodCallHandler(_handleMethodCall);
    _handlerAttached = true;
  }

  static Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'actionInvoked':
        final Object? arguments = call.arguments;
        if (arguments is Map && arguments['actionId'] is String) {
          _invokeAction(arguments['actionId'] as String);
          return;
        }
        throw MissingPluginException('Invalid toast actionInvoked payload.');
      default:
        throw MissingPluginException('No handler for ${call.method}.');
    }
  }

  static String? _registerAction(
    AppleLiquidToastAction? action,
    Duration duration,
  ) {
    _clearActiveAction();

    if (action == null) {
      return null;
    }

    final AppleLiquidToastActionCallback? callback = action.onPressed;
    if (callback == null) {
      return null;
    }

    final String actionId = 'toast_action_${_nextActionId++}';
    _actions[actionId] = _AppleLiquidToastActionRegistration(
      callback: callback,
      dismissesToast: action.dismissesToast,
    );
    _activeActionId = actionId;

    _activeActionCleanupTimer = Timer(
      duration + const Duration(seconds: 2),
      () => _removeAction(actionId),
    );

    return actionId;
  }

  static void _invokeAction(String actionId) {
    final _AppleLiquidToastActionRegistration? registration =
        _actions[actionId];
    if (registration == null) {
      return;
    }

    registration.callback();

    if (registration.dismissesToast) {
      _removeAction(actionId);
    }
  }

  static void _clearActiveAction() {
    _removeAction(_activeActionId);
  }

  static void _removeAction(String? actionId) {
    if (actionId == null) {
      return;
    }

    _actions.remove(actionId);

    if (_activeActionId == actionId) {
      _activeActionId = null;
      _activeActionCleanupTimer?.cancel();
      _activeActionCleanupTimer = null;
    }
  }
}
