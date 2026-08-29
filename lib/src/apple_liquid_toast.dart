import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Callback invoked when a native toast action is pressed.
typedef AppleLiquidToastActionCallback = void Function();

class _AppleLiquidToastActionRegistration {
  const _AppleLiquidToastActionRegistration({
    required this.callback,
    required this.dismissesToast,
    required this.toastId,
  });

  final AppleLiquidToastActionCallback callback;
  final bool dismissesToast;
  final String toastId;
}

/// Action button configuration for [AppleLiquidToast.show].
class AppleLiquidToastAction {
  const AppleLiquidToastAction({
    required this.title,
    this.tintColor,
    this.dismissesToast = true,
    this.isWholeToastTappable = false,
    this.onPressed,
  }) : assert(title != '');

  /// Button text displayed at the trailing edge of the toast.
  final String title;

  /// Optional native tint color for the action title.
  final Color? tintColor;

  /// Whether the native toast should dismiss immediately after tapping.
  final bool dismissesToast;

  /// Whether the complete toast capsule invokes this action.
  ///
  /// When enabled, the action title is rendered as a label inside one native
  /// button that covers the complete toast. The default keeps only the action
  /// title tappable for backwards compatibility.
  final bool isWholeToastTappable;

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
  static String? _activeToastId;
  static Timer? _activeActionCleanupTimer;

  /// Shows a native iOS Liquid Glass toast.
  ///
  /// The default duration is three seconds. Pass `null` to keep the toast
  /// visible until its action, a downward swipe, or [dismiss] closes it.
  ///
  /// Returns `false` on unsupported platforms or when the native overlay cannot
  /// be attached to the active iOS window.
  static Future<bool> show({
    required String title,
    Duration? duration = const Duration(seconds: 3),
    double placementOffset = -60,
    double transitionOffset = 100,
    String? systemImage,
    AppleLiquidToastAction? action,
  }) async {
    assert(title.isNotEmpty);
    assert(duration == null || duration > Duration.zero);
    assert(placementOffset.isFinite);
    assert(transitionOffset.isFinite);

    if (!_isNativeToastSupported) {
      return false;
    }

    _ensureHandlerAttached();

    final String toastId = DateTime.now().microsecondsSinceEpoch.toString();
    final String? actionId = _registerAction(action, duration, toastId);
    _activeToastId = toastId;
    final Map<String, Object?> arguments = <String, Object?>{
      'id': toastId,
      'title': title,
      'duration': duration == null
          ? null
          : duration.inMicroseconds / Duration.microsecondsPerSecond,
      'placementOffset': placementOffset,
      'transitionOffset': transitionOffset,
      if (systemImage != null) 'systemImage': systemImage,
      if (action != null) ...<String, Object?>{
        'actionTitle': action.title,
        'actionTintColor': action.tintColor?.toARGB32(),
        'dismissesOnAction': action.dismissesToast,
        'isWholeToastTappable': action.isWholeToastTappable,
        if (actionId != null) 'actionId': actionId,
      },
    };

    try {
      final bool shown =
          await _channel.invokeMethod<bool>('show', arguments) ?? false;
      if (!shown) {
        _clearActiveToast(toastId, actionId);
      }
      return shown;
    } on MissingPluginException {
      _clearActiveToast(toastId, actionId);
      return false;
    } on PlatformException {
      _clearActiveToast(toastId, actionId);
      return false;
    }
  }

  /// Dismisses the currently visible native toast.
  static Future<bool> dismiss() async {
    _clearActiveToast();

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
      case 'toastDismissed':
        final Object? arguments = call.arguments;
        if (arguments is Map && arguments['toastId'] is String) {
          _clearActiveToast(arguments['toastId'] as String);
          return;
        }
        throw MissingPluginException('Invalid toastDismissed payload.');
      default:
        throw MissingPluginException('No handler for ${call.method}.');
    }
  }

  static String? _registerAction(
    AppleLiquidToastAction? action,
    Duration? duration,
    String toastId,
  ) {
    _clearActiveToast();

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
      toastId: toastId,
    );
    _activeActionId = actionId;

    if (duration != null) {
      _activeActionCleanupTimer = Timer(
        duration + const Duration(seconds: 2),
        () => _removeAction(actionId),
      );
    }

    return actionId;
  }

  static void _invokeAction(String actionId) {
    final _AppleLiquidToastActionRegistration? registration =
        _actions[actionId];
    if (registration == null) {
      return;
    }

    try {
      registration.callback();
    } finally {
      if (registration.dismissesToast) {
        _clearActiveToast(registration.toastId, actionId);
      }
    }
  }

  static void _clearActiveToast([String? toastId, String? actionId]) {
    if (toastId != null && toastId != _activeToastId) {
      return;
    }

    _removeAction(actionId ?? _activeActionId);
    _activeToastId = null;
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
