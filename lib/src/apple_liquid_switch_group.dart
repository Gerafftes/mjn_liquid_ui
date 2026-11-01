import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'apple_liquid_platform.dart';
import 'apple_liquid_platform_view.dart';

/// One controlled switch and its Flutter label in an [AppleLiquidSwitchGroup].
@immutable
class AppleLiquidSwitchGroupItem {
  const AppleLiquidSwitchGroupItem({
    required this.id,
    required this.label,
    required this.semanticLabel,
    required this.value,
    required this.onChanged,
    this.tintColor,
  });

  /// Stable, nonempty identity, unique within the group.
  final String id;
  final Widget label;

  /// Accessible name of the native switch.
  final String semanticLabel;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Color? tintColor;
}

/// Flutter labels beside a single native iOS view containing several switches.
class AppleLiquidSwitchGroup extends StatefulWidget {
  AppleLiquidSwitchGroup({
    super.key,
    required List<AppleLiquidSwitchGroupItem> items,
    this.rowHeight = 60,
  }) : items = List<AppleLiquidSwitchGroupItem>.unmodifiable(items) {
    if (!rowHeight.isFinite ||
        rowHeight < 44 ||
        !(rowHeight * items.length).isFinite) {
      throw ArgumentError.value(
        rowHeight,
        'rowHeight',
        'Must be finite and >= 44.',
      );
    }
    final Set<String> ids = <String>{};
    for (final AppleLiquidSwitchGroupItem item in items) {
      if (item.id.isEmpty || !ids.add(item.id)) {
        throw ArgumentError('Switch group IDs must be nonempty and unique.');
      }
    }
  }

  final List<AppleLiquidSwitchGroupItem> items;

  /// Height of each aligned label/control row, at least 44 logical pixels.
  final double rowHeight;

  @override
  State<AppleLiquidSwitchGroup> createState() => _AppleLiquidSwitchGroupState();
}

class _AppleLiquidSwitchGroupState extends State<AppleLiquidSwitchGroup> {
  static const String _viewType = 'mjn_liquid_ui_switch_group';
  MethodChannel? _channel;
  final Set<String> _interacting = <String>{};

  @override
  void didUpdateWidget(covariant AppleLiquidSwitchGroup oldWidget) {
    super.didUpdateWidget(oldWidget);
    _interacting.removeWhere((String id) => !_contains(id));
    if (widget.items.isEmpty) {
      _channel?.setMethodCallHandler(null);
      _channel = null;
    } else {
      _sync();
    }
  }

  bool _contains(String id) => widget.items.any((item) => item.id == id);

  Map<String, Object?> get _configuration => <String, Object?>{
    'rowHeight': widget.rowHeight,
    'items': widget.items
        .map(
          (item) => <String, Object?>{
            'id': item.id,
            'value': item.value,
            'tintColor': item.tintColor?.toARGB32(),
            'semanticLabel': item.semanticLabel,
          },
        )
        .toList(),
  };

  @override
  void dispose() {
    _channel?.setMethodCallHandler(null);
    _channel = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    checkAppleLiquidPlatform();
    if (widget.items.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: widget.rowHeight * widget.items.length,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              children: <Widget>[
                for (final item in widget.items)
                  SizedBox(
                    key: ValueKey<String>(item.id),
                    height: widget.rowHeight,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: item.label,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 76,
            child: defaultTargetPlatform == TargetPlatform.iOS
                ? AppleLiquidUiKitView(
                    viewType: _viewType,
                    layoutDirection: Directionality.of(context),
                    creationParamsCodec: const StandardMessageCodec(),
                    creationParams: _configuration,
                    hitTestBehavior: PlatformViewHitTestBehavior.opaque,
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                      ),
                    },
                    onPlatformViewCreated: _onCreated,
                  )
                : Column(
                    children: <Widget>[
                      for (final item in widget.items)
                        SizedBox(
                          key: ValueKey<String>(item.id),
                          height: widget.rowHeight,
                          child: Semantics(
                            label: item.semanticLabel,
                            child: Switch.adaptive(
                              value: item.value,
                              onChanged: item.onChanged,
                              activeThumbColor: item.tintColor,
                              activeTrackColor: item.tintColor?.withValues(
                                alpha: .42,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _onCreated(int id) {
    if (!mounted || widget.items.isEmpty) return;
    _channel?.setMethodCallHandler(null);
    _interacting.clear();
    final MethodChannel channel = MethodChannel('$_viewType/$id');
    _channel = channel;
    channel.setMethodCallHandler((MethodCall call) async {
      if (!mounted || _channel != channel) return;
      final Object? args = call.arguments;
      if (args is! Map || args['id'] is! String) {
        throw MissingPluginException('Invalid switch group event payload.');
      }
      final String id = args['id'] as String;
      if (!_contains(id)) return;
      switch (call.method) {
        case 'valueChanged':
          if (args['value'] is! bool) {
            throw MissingPluginException('Invalid switch group value.');
          }
          widget.items
              .firstWhere((item) => item.id == id)
              .onChanged(args['value'] as bool);
        case 'interactionChanged':
          if (args['isInteracting'] is! bool) {
            throw MissingPluginException('Invalid switch group interaction.');
          }
          if (args['isInteracting'] as bool) {
            _interacting.add(id);
          } else if (_interacting.remove(id)) {
            // Let the controlled-value callback rebuild before reconciling.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted &&
                  _channel == channel &&
                  !_interacting.contains(id)) {
                _sync();
              }
            });
            WidgetsBinding.instance.ensureVisualUpdate();
          }
        default:
          throw MissingPluginException('No handler for ${call.method}.');
      }
    });
    // Creation can finish after several widget updates.
    _sync();
  }

  Future<void> _sync() async {
    final MethodChannel? channel = _channel;
    if (channel == null) return;
    try {
      await channel.invokeMethod<void>('updateConfiguration', _configuration);
    } on MissingPluginException {
      // A native platform view can disappear during teardown or hot restart.
    } on PlatformException {
      // Same teardown race as the other native controls.
    }
  }
}
