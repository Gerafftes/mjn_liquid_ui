import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'apple_liquid_platform_view.dart';
import 'apple_liquid_tab_bar_channel.dart';
import 'apple_liquid_tab_item.dart';

/// Controls whether an [AppleLiquidTabBar] compacts while content scrolls.
enum AppleLiquidTabBarMinimizeBehavior {
  /// Keeps the full tab bar visible, matching the original behavior.
  never,

  /// Compacts to the selected regular tab when content scrolls down.
  ///
  /// Scrolling back up expands the tab bar again. On iOS this behavior uses
  /// the native Liquid Glass tab presentation and requires iOS 26 or newer.
  onScrollDown,
}

/// Controls when downward scrolling minimizes an [AppleLiquidTabBar].
@immutable
class AppleLiquidTabBarMinimizeTrigger {
  /// Minimizes as soon as scrollable content starts moving down.
  const AppleLiquidTabBarMinimizeTrigger.contentScroll() : pixelDistance = null;

  /// Minimizes after [pixelDistance] logical pixels have been scrolled down.
  const AppleLiquidTabBarMinimizeTrigger.pixels(double pixels)
    : assert(pixels >= 0),
      pixelDistance = pixels;

  /// Downward scroll distance required before minimizing.
  ///
  /// A `null` value represents the immediate content-scroll trigger.
  final double? pixelDistance;

  /// Whether minimization starts with the first downward content movement.
  bool get followsContentScroll => pixelDistance == null;

  @override
  bool operator ==(Object other) {
    return other is AppleLiquidTabBarMinimizeTrigger &&
        other.pixelDistance == pixelDistance;
  }

  @override
  int get hashCode => pixelDistance.hashCode;
}

/// A bottom tab bar that uses Apple's Liquid Glass tab styling on iOS.
class AppleLiquidTabBar extends StatefulWidget {
  /// Creates a Liquid Glass tab bar with regular tabs and a search item.
  const AppleLiquidTabBar({
    super.key,
    required this.currentIndex,
    required this.onChanged,
    required this.items,
    required this.searchItem,
    this.height,
    this.selectedTintColor,
    this.minimizeBehavior = AppleLiquidTabBarMinimizeBehavior.never,
    this.minimizeTrigger =
        const AppleLiquidTabBarMinimizeTrigger.contentScroll(),
    this.scrollNotificationPredicate = defaultScrollNotificationPredicate,
  }) : assert(items.length > 0);

  /// Index of the currently selected item.
  final int currentIndex;

  /// Called when the selected tab changes.
  final ValueChanged<int> onChanged;

  /// Regular tab items shown before [searchItem].
  final List<AppleLiquidTabItem> items;

  /// Search tab item shown with the native iOS search role when available.
  final AppleLiquidTabItem searchItem;

  /// Optional fixed height for the tab bar.
  final double? height;

  /// Optional tint color for the selected item.
  final Color? selectedTintColor;

  /// Controls whether scrolling compacts the native tab bar.
  ///
  /// The default keeps the original full-width presentation. When using
  /// [AppleLiquidTabBarMinimizeBehavior.onScrollDown], place the tab bar in a
  /// [Scaffold] or below a [ScrollNotificationObserver] so it can observe the
  /// page's scroll notifications.
  final AppleLiquidTabBarMinimizeBehavior minimizeBehavior;

  /// Controls whether minimization follows the first content movement or a
  /// configurable downward pixel distance.
  final AppleLiquidTabBarMinimizeTrigger minimizeTrigger;

  /// Selects which scroll notifications may minimize the tab bar.
  ///
  /// The default reacts only to the nearest vertical scrollable. Supply a
  /// custom predicate for nested scroll views.
  final ScrollNotificationPredicate scrollNotificationPredicate;

  @override
  State<AppleLiquidTabBar> createState() => _AppleLiquidTabBarState();
}

class _AppleLiquidTabBarState extends State<AppleLiquidTabBar> {
  static const double _defaultHeight = 86;

  AppleLiquidTabBarChannel? _channel;
  ScrollNotificationObserverState? _scrollNotificationObserver;
  bool _isMinimized = false;
  ScrollDirection _userScrollDirection = ScrollDirection.idle;
  double _downwardScrollDistance = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scrollNotificationObserver?.removeListener(_handleScrollNotification);
    _scrollNotificationObserver = ScrollNotificationObserver.maybeOf(context);
    _scrollNotificationObserver?.addListener(_handleScrollNotification);
  }

  @override
  void didUpdateWidget(covariant AppleLiquidTabBar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.minimizeBehavior != widget.minimizeBehavior) {
      _resetMinimizeTriggerProgress();
      if (widget.minimizeBehavior == AppleLiquidTabBarMinimizeBehavior.never) {
        _setMinimized(false);
      }
    }

    if (oldWidget.minimizeTrigger != widget.minimizeTrigger) {
      _resetMinimizeTriggerProgress();
      _setMinimized(false);
    }

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
    _scrollNotificationObserver?.removeListener(_handleScrollNotification);
    _scrollNotificationObserver = null;
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
      onExpanded: () {
        if (mounted) {
          _isMinimized = false;
          _resetMinimizeTriggerProgress();
        }
      },
    );
    _channel?.setMinimized(_isMinimized);
  }

  void _handleScrollNotification(ScrollNotification notification) {
    if (widget.minimizeBehavior !=
            AppleLiquidTabBarMinimizeBehavior.onScrollDown ||
        !widget.scrollNotificationPredicate(notification) ||
        notification.metrics.axis != Axis.vertical) {
      return;
    }

    if (notification is UserScrollNotification) {
      final ScrollDirection direction = notification.direction;
      _userScrollDirection = direction;

      switch (direction) {
        case ScrollDirection.reverse:
          if (notification.metrics.extentBefore > 0 &&
              (widget.minimizeTrigger.followsContentScroll ||
                  widget.minimizeTrigger.pixelDistance == 0)) {
            _setMinimized(true);
          }
        case ScrollDirection.forward:
          _resetMinimizeTriggerProgress();
          _setMinimized(false);
        case ScrollDirection.idle:
          break;
      }
      return;
    }

    final double? pixelDistance = widget.minimizeTrigger.pixelDistance;
    if (pixelDistance != null &&
        notification is ScrollUpdateNotification &&
        _userScrollDirection == ScrollDirection.reverse) {
      final double scrollDelta = notification.scrollDelta ?? 0;
      if (scrollDelta > 0) {
        _downwardScrollDistance += scrollDelta;
        if (_downwardScrollDistance >= pixelDistance) {
          _setMinimized(true);
        }
      }
    }
  }

  void _resetMinimizeTriggerProgress() {
    _userScrollDirection = ScrollDirection.idle;
    _downwardScrollDistance = 0;
  }

  void _setMinimized(bool isMinimized) {
    if (_isMinimized == isMinimized) {
      return;
    }

    _isMinimized = isMinimized;
    _channel?.setMinimized(isMinimized);
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

  static const double _iconSlotSize = 28;
  static const double _notificationDotSize = 5.5;
  static const double _notificationBadgeSize = 18;
  static const double _notificationDotInset = 4;

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
              icon: _fallbackIconFor(items[index], isSelected: false),
              activeIcon: _fallbackIconFor(items[index], isSelected: true),
              label: items[index].title,
            ),
        ],
      ),
    );
  }

  Widget _fallbackIconFor(AppleLiquidTabItem item, {required bool isSelected}) {
    final Icon icon = Icon(
      _fallbackIconDataFor(item, isSelected: isSelected),
      weight: _fallbackIconWeightFor(item, isSelected: isSelected),
    );
    final Color? dotColor = item.notificationDotColor;

    if (dotColor == null) {
      return icon;
    }

    return SizedBox.square(
      dimension: _iconSlotSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: <Widget>[
          icon,
          Positioned(
            top: _notificationDotInset,
            right: _notificationDotInset,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
              child: item.notificationBadgeValue == null
                  ? const SizedBox.square(dimension: _notificationDotSize)
                  : SizedBox.square(
                      dimension: _notificationBadgeSize,
                      child: Center(
                        child: Text(
                          item.notificationBadgeValue!,
                          style: const TextStyle(
                            color: Color(0xFFFFFFFF),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _fallbackIconDataFor(
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

  double? _fallbackIconWeightFor(
    AppleLiquidTabItem item, {
    required bool isSelected,
  }) {
    if (isSelected) {
      return (item.activeSymbolWeight ?? item.symbolWeight)?.fallbackIconWeight;
    }

    return item.symbolWeight?.fallbackIconWeight;
  }
}
