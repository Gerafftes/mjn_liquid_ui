import Combine
import Foundation

final class AppleLiquidTabbarModel: ObservableObject {
  @Published private(set) var items: [AppleLiquidTabbarItem]
  @Published private(set) var searchItem: AppleLiquidTabbarItem
  @Published var searchText = ""
  @Published var selectedIndex: Int {
    didSet {
      guard selectedIndex != oldValue, !isApplyingFlutterUpdate else {
        return
      }
      onSelectionChanged?(selectedIndex)
    }
  }

  var onSelectionChanged: ((Int) -> Void)?

  private var isApplyingFlutterUpdate = false

  init(configuration: AppleLiquidTabbarConfiguration) {
    items = configuration.items
    searchItem = configuration.searchItem
    selectedIndex = 0
    setSelectedIndex(configuration.currentIndex, notifyFlutter: false)
  }

  var allItems: [AppleLiquidTabbarItem] {
    items + [searchItem]
  }

  var searchIndex: Int {
    items.count
  }

  func systemImage(for item: AppleLiquidTabbarItem, index: Int) -> String {
    if selectedIndex == index, let activeSystemImage = item.activeSystemImage {
      return activeSystemImage
    }
    return item.systemImage
  }

  func setSelectedIndex(_ index: Int, notifyFlutter: Bool) {
    let nextIndex = clampedIndex(index)

    if notifyFlutter {
      selectedIndex = nextIndex
      return
    }

    isApplyingFlutterUpdate = true
    selectedIndex = nextIndex
    isApplyingFlutterUpdate = false
  }

  func update(configuration: AppleLiquidTabbarConfiguration) {
    isApplyingFlutterUpdate = true
    items = configuration.items
    searchItem = configuration.searchItem
    selectedIndex = clampedIndex(configuration.currentIndex)
    isApplyingFlutterUpdate = false
  }

  private func clampedIndex(_ index: Int) -> Int {
    let lastIndex = max(allItems.count - 1, 0)
    return min(max(index, 0), lastIndex)
  }
}
