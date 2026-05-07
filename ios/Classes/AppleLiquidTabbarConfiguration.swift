import Foundation

struct AppleLiquidTabbarItem: Equatable {
  let title: String
  let systemImage: String
  let activeSystemImage: String?
  let isSearch: Bool
  let notificationDotColor: Int?
  let notificationBadgeValue: String?

  init(
    title: String,
    systemImage: String,
    activeSystemImage: String? = nil,
    isSearch: Bool = false,
    notificationDotColor: Int? = nil,
    notificationBadgeValue: String? = nil
  ) {
    self.title = title
    self.systemImage = systemImage
    self.activeSystemImage = activeSystemImage
    self.isSearch = isSearch
    self.notificationDotColor = notificationDotColor
    self.notificationBadgeValue = notificationBadgeValue
  }

  init(dictionary: [String: Any]) {
    title = dictionary["title"] as? String ?? ""
    systemImage = dictionary["systemImage"] as? String ?? "circle"
    activeSystemImage = dictionary["activeSystemImage"] as? String
    notificationDotColor = AppleLiquidTabbarConfiguration.intValue(
      dictionary["notificationDotColor"]
    )
    notificationBadgeValue = dictionary["notificationBadgeValue"] as? String
    isSearch = AppleLiquidTabbarConfiguration.boolValue(
      dictionary["isSearch"]
    ) ?? false
  }
}

struct AppleLiquidTabbarConfiguration {
  let currentIndex: Int
  let items: [AppleLiquidTabbarItem]
  let searchItem: AppleLiquidTabbarItem
  let selectedTintColor: Int?

  init(arguments: Any?) {
    let dictionary = arguments as? [String: Any] ?? [:]

    currentIndex = Self.intValue(dictionary["currentIndex"]) ?? 0
    items = Self.itemArray(dictionary["items"])
    searchItem = Self.searchItem(dictionary["searchItem"])
    selectedTintColor = Self.intValue(dictionary["selectedTintColor"])
  }

  static func intValue(_ value: Any?) -> Int? {
    if let intValue = value as? Int {
      return intValue
    }
    if let number = value as? NSNumber {
      return number.intValue
    }
    return nil
  }

  static func boolValue(_ value: Any?) -> Bool? {
    if let boolValue = value as? Bool {
      return boolValue
    }
    if let number = value as? NSNumber {
      return number.boolValue
    }
    return nil
  }

  private static func itemArray(_ value: Any?) -> [AppleLiquidTabbarItem] {
    guard let rawItems = value as? [[String: Any]] else {
      return []
    }

    return rawItems.map(AppleLiquidTabbarItem.init(dictionary:))
  }

  private static func searchItem(_ value: Any?) -> AppleLiquidTabbarItem {
    guard let dictionary = value as? [String: Any] else {
      return AppleLiquidTabbarItem(
        title: "Search",
        systemImage: "plus",
        isSearch: true
      )
    }

    let item = AppleLiquidTabbarItem(dictionary: dictionary)
    return AppleLiquidTabbarItem(
      title: item.title.isEmpty ? "Search" : item.title,
      systemImage: item.systemImage,
      activeSystemImage: item.activeSystemImage,
      isSearch: true,
      notificationDotColor: item.notificationDotColor,
      notificationBadgeValue: item.notificationBadgeValue
    )
  }
}
