import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'apple_liquid_platform_view.dart';
import 'apple_liquid_tab_bar_channel.dart';
import 'apple_liquid_tab_item.dart';

class AppleLiquidTabBar extends StatefulWidget {
  const AppleLiquidTabBar({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    required this.items,
    required this.searchItem,
    this.height,
    this.selectedTintColor,
  }) : assert(items.length > 0);

  final int currentIndex;
  final ValueChanged<int> onChanged;
  final List<AppleLiquidTabItem> items;
  final AppleLiquidTabItem searchItem;
  final double? height;
  final Color? selectedTintColor;

  @override
  State<AppleLiquidTabBar> createState() => _AppleLiquidTabBarState();
}

class _AppleLiquidTabBarState extends State<AppleLiquidTabBar> {
  static const double _defaultHeight = 86;

  AppleLiquidTabBarChannel? _channel;

  @override
  void didUpdateWidget(covariant AppleLiquidTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    final AppleLiquidTabBarChannel? channel = _channel;
    if (channel == null) {
      return;
    }

    if (oldWidget.currentIndex != widget.currentIndex) {
      channel.setCurrentIndex(widget.currentIndex);
    }

    if (!listEquals(oldWidget.items, widget.items) ||
        oldWidget.searchItem != widget.searchItem ||
        oldWidget.selectedTintColor != widget.selectedTintColor) {
      channel.updateConfiguration(
        currentIndex: widget.currentIndex,
        items: widget.items,
        searchItem: widget.searchItem,
        selectedTintColor: widget.selectedTintColor,
      );
    }
  }

  @override
  void dispose() {
    _channel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double height = widget.height ?? _defaultHeight;

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      return SizedBox(
        height: height,
        child: AppleLiquidUiKitView(
          viewType: AppleLiquidTabBarChannel.viewType,
          layoutDirection: Directionality.of(context),
          creationParamsCodec: const StandardMessageCodec(),
          creationParams: AppleLiquidTabBarChannel.configurationMap(
            currentIndex: widget.currentIndex,
            items: widget.items,
            searchItem: widget.searchItem,
            selectedTintColor: widget.selectedTintColor,
          ),
          hitTestBehavior: PlatformViewHitTestBehavior.opaque,
          onPlatformViewCreated: _onPlatformViewCreated,
        ),
      );
    }

    return _AppleLiquidTabBarFallback(
      currentIndex: widget.currentIndex,
      onChanged: widget.onChanged,
      items: _allItems,
      height: height,
      selectedTintColor: widget.selectedTintColor,
    );
  }

  List<AppleLiquidTabItem> get _allItems {
    return <AppleLiquidTabItem>[...widget.items, widget.searchItem];
  }

  void _onPlatformViewCreated(int viewId) {
    _channel?.dispose();
    _channel = AppleLiquidTabBarChannel.attach(
      viewId: viewId,
      onChanged: (int index) {
        if (mounted) {
          widget.onChanged(index);
        }
      },
    );
  }
}

class _AppleLiquidTabBarFallback extends StatelessWidget {
  const _AppleLiquidTabBarFallback({
    required this.currentIndex,
    required this.onChanged,
    required this.items,
    required this.height,
    required this.selectedTintColor,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;
  final List<AppleLiquidTabItem> items;
  final double height;
  final Color? selectedTintColor;

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = currentIndex.clamp(0, items.length - 1);

    return SizedBox(
      height: height,
      child: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: selectedIndex,
        onTap: onChanged,
        selectedItemColor: selectedTintColor,
        items: <BottomNavigationBarItem>[
          for (int index = 0; index < items.length; index += 1)
            BottomNavigationBarItem(
              icon: Icon(_fallbackIconFor(items[index], isSelected: false)),
              activeIcon: Icon(
                _fallbackIconFor(items[index], isSelected: true),
              ),
              label: items[index].title,
            ),
        ],
      ),
    );
  }

  IconData _fallbackIconFor(
    AppleLiquidTabItem item, {
    required bool isSelected,
  }) {
    final String symbol =
        (isSelected
                ? item.activeSystemImage ?? item.systemImage
                : item.systemImage)
            .toLowerCase();

    if (symbol.contains('plus')) {
      return Icons.add_rounded;
    }
    if (symbol.contains('magnifyingglass')) {
      return Icons.search_rounded;
    }
    if (symbol.contains('house')) {
      return Icons.home_rounded;
    }
    if (symbol.contains('briefcase')) {
      return Icons.work_rounded;
    }
    if (symbol.contains('message') || symbol.contains('bubble')) {
      return Icons.chat_bubble_rounded;
    }
    if (symbol.contains('person')) {
      return Icons.person_rounded;
    }
    if (symbol.contains('gear')) {
      return Icons.settings_rounded;
    }
    return Icons.circle_outlined;
  }
}
