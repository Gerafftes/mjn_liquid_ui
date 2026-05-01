import 'package:flutter/foundation.dart';

/// Configuration for one item in an [AppleLiquidTabBar].
@immutable
class AppleLiquidTabItem {
  /// Creates a tab item backed by SF Symbol image names on iOS.
  const AppleLiquidTabItem({
    required this.title,
    required this.systemImage,
    this.activeSystemImage,
    this.isSearch = false,
  });

  /// Text label shown for the tab.
  final String title;

  /// SF Symbol name used for the inactive tab icon on iOS.
  final String systemImage;

  /// Optional SF Symbol name used for the active tab icon on iOS.
  final String? activeSystemImage;

  /// Whether this item should be treated as the search tab.
  final bool isSearch;

  /// Converts this item to the platform channel payload used by iOS.
  Map<String, Object?> toMap() {
    return <String, Object?>{
      'title': title,
      'systemImage': systemImage,
      'activeSystemImage': activeSystemImage,
      'isSearch': isSearch,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is AppleLiquidTabItem &&
        other.title == title &&
        other.systemImage == systemImage &&
        other.activeSystemImage == activeSystemImage &&
        other.isSearch == isSearch;
  }

  @override
  int get hashCode =>
      Object.hash(title, systemImage, activeSystemImage, isSearch);
}
