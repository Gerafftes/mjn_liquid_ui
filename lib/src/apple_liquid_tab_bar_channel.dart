import 'package:flutter/services.dart';

import 'apple_liquid_tab_item.dart';

typedef AppleLiquidNativeTabChanged = void Function(int index);

class AppleLiquidTabBarChannel {
  AppleLiquidTabBarChannel._(this._channel, this._onChanged) {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  static const String viewType = 'mjn_liquid_ui_tabbar';

  final MethodChannel _channel;
  final AppleLiquidNativeTabChanged _onChanged;

  static AppleLiquidTabBarChannel attach({
    required int viewId,
    required AppleLiquidNativeTabChanged onChanged,
  }) {
    return AppleLiquidTabBarChannel._(
      MethodChannel('$viewType/$viewId'),
      onChanged,
    );
  }

  Future<void> setCurrentIndex(int index) {
    return _channel.invokeMethod<void>('setCurrentIndex', <String, Object?>{
      'currentIndex': index,
    });
  }

  Future<void> updateConfiguration({
    required int currentIndex,
    required List<AppleLiquidTabItem> items,
    required AppleLiquidTabItem searchItem,
  }) {
    return _channel.invokeMethod<void>(
      'updateConfiguration',
      configurationMap(
        currentIndex: currentIndex,
        items: items,
        searchItem: searchItem,
      ),
    );
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
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
  }) {
    return <String, Object?>{
      'currentIndex': currentIndex,
      'items': items.map((AppleLiquidTabItem item) => item.toMap()).toList(),
      'searchItem': searchItem.toMap(),
    };
  }
}
