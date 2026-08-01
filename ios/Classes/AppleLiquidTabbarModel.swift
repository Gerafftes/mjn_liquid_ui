import Combine
import Foundation
import SwiftUI
import UIKit

final class AppleLiquidTabbarModel: ObservableObject {
  @Published private(set) var items: [AppleLiquidTabbarItem]
  @Published private(set) var searchItem: AppleLiquidTabbarItem
  @Published private(set) var selectedTintColor: Color?
  @Published private(set) var isMinimized = false
  @Published private(set) var isCompressing = false
  @Published var searchText = ""
  @Published var selectedIndex: Int {
    didSet {
      if items.indices.contains(selectedIndex) {
        lastSelectedRegularIndex = selectedIndex
      }
      guard selectedIndex != oldValue, !isApplyingFlutterUpdate else {
        return
      }
      onSelectionChanged?(selectedIndex)
    }
  }

  var onSelectionChanged: ((Int) -> Void)?
  var onExpansionRequested: (() -> Void)?
  private(set) var selectedTintUIColor: UIColor?

  private var isApplyingFlutterUpdate = false
  private var lastSelectedRegularIndex = 0
  private var minimizationRequestID = 0

  static let minimizationLeadInDuration: TimeInterval = 0.1

  init(configuration: AppleLiquidTabbarConfiguration) {
    items = configuration.items
    searchItem = configuration.searchItem
    selectedTintColor = Color(appleLiquidARGB: configuration.selectedTintColor)
    selectedTintUIColor = UIColor(
      appleLiquidARGB: configuration.selectedTintColor
    )
    selectedIndex = 0
    setSelectedIndex(configuration.currentIndex, notifyFlutter: false)
  }

  var allItems: [AppleLiquidTabbarItem] {
    items + [searchItem]
  }

  var displayedRegularIndices: [Int] {
    guard isMinimized, items.indices.contains(lastSelectedRegularIndex) else {
      return Array(items.indices)
    }

    return [lastSelectedRegularIndex]
  }

  var displayedItems: [AppleLiquidTabbarItem] {
    displayedRegularIndices.map { items[$0] } + [searchItem]
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

  func symbolWeight(for item: AppleLiquidTabbarItem, index: Int) -> String? {
    if selectedIndex == index {
      return item.activeSymbolWeight ?? item.symbolWeight
    }

    return item.symbolWeight
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

  func selectCompactItem(at index: Int) {
    setMinimized(false)
    onExpansionRequested?()
    setSelectedIndex(index, notifyFlutter: true)
  }

  func setMinimized(_ shouldMinimize: Bool, animated: Bool = true) {
    if shouldMinimize {
      if !animated {
        minimizationRequestID += 1
        isCompressing = false
        isMinimized = true
        return
      }

      guard !isMinimized, !isCompressing else {
        return
      }

      minimizationRequestID += 1
      isCompressing = true
      let requestID = minimizationRequestID

      DispatchQueue.main.asyncAfter(
        deadline: .now() + Self.minimizationLeadInDuration
      ) { [weak self] in
        guard let self, minimizationRequestID == requestID else {
          return
        }

        isCompressing = false
        isMinimized = true
      }
      return
    }

    minimizationRequestID += 1
    isCompressing = false
    isMinimized = false
  }

  func update(configuration: AppleLiquidTabbarConfiguration) {
    isApplyingFlutterUpdate = true
    items = configuration.items
    searchItem = configuration.searchItem
    selectedTintColor = Color(appleLiquidARGB: configuration.selectedTintColor)
    selectedTintUIColor = UIColor(
      appleLiquidARGB: configuration.selectedTintColor
    )
    selectedIndex = clampedIndex(configuration.currentIndex)
    if items.indices.contains(selectedIndex) {
      lastSelectedRegularIndex = selectedIndex
    } else if !items.indices.contains(lastSelectedRegularIndex) {
      lastSelectedRegularIndex = max(items.count - 1, 0)
    }
    isApplyingFlutterUpdate = false
  }

  private func clampedIndex(_ index: Int) -> Int {
    let lastIndex = max(allItems.count - 1, 0)
    return min(max(index, 0), lastIndex)
  }
}
