import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'apple_liquid_symbol_weight.dart';

/// Configuration for one item in an [AppleLiquidTabBar].
@immutable
class AppleLiquidTabItem {
  /// Creates a tab item backed by SF Symbol image names on iOS.
  const AppleLiquidTabItem({
    required this.title,
    required this.systemImage,
    this.activeSystemImage,
    this.symbolWeight,
    this.activeSymbolWeight,
    this.isSearch = false,
    this.notificationDotColor,
    this.notificationBadgeValue,
  });

  /// Text label shown for the tab.
  final String title;

  /// SF Symbol name used for the inactive tab icon on iOS.
  final String systemImage;

  /// Optional SF Symbol name used for the active tab icon on iOS.
  final String? activeSystemImage;

  /// Optional SF Symbol stroke weight for the inactive tab icon.
  final AppleLiquidSymbolWeight? symbolWeight;

  /// Optional SF Symbol stroke weight for the active tab icon.
  ///
  /// When null, the active icon uses [symbolWeight].
  final AppleLiquidSymbolWeight? activeSymbolWeight;

  /// Whether this item should be treated as the search tab.
  final bool isSearch;

  /// Optional color for a small notification dot on the tab icon.
  ///
  /// When null, no dot is shown.
  final Color? notificationDotColor;

  /// Optional text shown inside the notification badge.
  ///
  /// When null, the badge is shown as a numberless dot.
  final String? notificationBadgeValue;

  /// Converts this item to the platform channel payload used by iOS.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'title': title,
      'systemImage': systemImage,
      'activeSystemImage': activeSystemImage,
      'symbolWeight': symbolWeight?.platformValue,
      'activeSymbolWeight': activeSymbolWeight?.platformValue,
      'isSearch': isSearch,
      'notificationDotColor': notificationDotColor?.toARGB32(),
      'notificationBadgeValue': notificationBadgeValue,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is AppleLiquidTabItem &&
        other.title == title &&
        other.systemImage == systemImage &&
        other.activeSystemImage == activeSystemImage &&
        other.symbolWeight == symbolWeight &&
        other.activeSymbolWeight == activeSymbolWeight &&
        other.isSearch == isSearch &&
        other.notificationDotColor == notificationDotColor &&
        other.notificationBadgeValue == notificationBadgeValue;
  }

  @override
  int get hashCode => Object.hash(
    title,
    systemImage,
    activeSystemImage,
    symbolWeight,
    activeSymbolWeight,
    isSearch,
    notificationDotColor,
    notificationBadgeValue,
  );
}
