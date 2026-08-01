import 'package:flutter/services.dart';

import 'apple_liquid_tab_item.dart';

typedef AppleLiquidNativeTabChanged = void Function(int index);
typedef AppleLiquidNativeTabExpanded = void Function();

class AppleLiquidTabBarChannel {
  AppleLiquidTabBarChannel._(this._channel, this._onChanged, this._onExpanded) {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static const String viewType = 'mjn_liquid_ui_tabbar';

  final MethodChannel _channel;
  final AppleLiquidNativeTabChanged _onChanged;
  final AppleLiquidNativeTabExpanded _onExpanded;
  bool _disposed = false;

  static AppleLiquidTabBarChannel attach({
    required int viewId,
    required AppleLiquidNativeTabChanged onChanged,
    required AppleLiquidNativeTabExpanded onExpanded,
  }) {
    return AppleLiquidTabBarChannel._(
      MethodChannel('$viewType/$viewId'),
      onChanged,
      onExpanded,
    );
  }

  Future<void> setCurrentIndex(int index) {
    return _invokeMethod('setCurrentIndex', <String, Object?>{
      'currentIndex': index,
    });
  }

  Future<void> setMinimized(bool isMinimized) {
    return _invokeMethod('setMinimized', <String, Object?>{
      'isMinimized': isMinimized,
    });
  }

  Future<void> updateConfiguration({
    required int currentIndex,
    required List<AppleLiquidTabItem> items,
    required AppleLiquidTabItem searchItem,
    required Color? selectedTintColor,
  }) {
    return _invokeMethod(
      'updateConfiguration',
      configurationMap(
        currentIndex: currentIndex,
        items: items,
        searchItem: searchItem,
        selectedTintColor: selectedTintColor,
      ),
    );
  }

  void dispose() {
    _disposed = true;
    _channel.setMethodCallHandler(null);
  }

  Future<void> _invokeMethod(String method, Object? arguments) async {
    if (_disposed) {
      return;
    }

    try {
      await _channel.invokeMethod<void>(method, arguments);
    } on MissingPluginException {
      // Platform views can be torn down while a debug hot restart is rebuilding
      // Dart state. Treat that as a lifecycle race, not an app-level failure.
    } on PlatformException {
      // The native side only exposes private control-update methods. During
      // engine/view teardown these can fail before Dart observes disposal.
    }
  }

  Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'tabSelected':
        final arguments = call.arguments;
        if (arguments is Map && arguments['index'] is int) {
          _onChanged(arguments['index'] as int);
          return;
        } else if (arguments is int) {
          _onChanged(arguments);
          return;
        }
        throw MissingPluginException(
          'Invalid tabSelected arguments on ${_channel.name}',
        );
      case 'tabExpanded':
        _onExpanded();
        return;
      default:
        throw MissingPluginException(
          'No handler for ${call.method} on ${_channel.name}',
        );
    }
  }

  static Map<String, Object?> configurationMap({
    required int currentIndex,
    required List<AppleLiquidTabItem> items,
    required AppleLiquidTabItem searchItem,
    required Color? selectedTintColor,
  }) {
    return <String, Object?>{
      'currentIndex': currentIndex,
      'items': items.map((AppleLiquidTabItem item) => item.toMap()).toList(),
      'searchItem': searchItem.toMap(),
      'selectedTintColor': selectedTintColor?.toARGB32(),
    };
  }
}
