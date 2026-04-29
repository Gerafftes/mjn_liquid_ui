import 'package:flutter/foundation.dart';

@immutable
class AppleLiquidTabItem {
  const AppleLiquidTabItem({
    required this.title,
    required this.systemImage,
    this.activeSystemImage,
    this.isSearch = false,
  });

  final String title;
  final String systemImage;
  final String? activeSystemImage;
  final bool isSearch;

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
