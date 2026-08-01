import SwiftUI

@available(iOS 18.0, *)
struct AppleLiquidSwiftUITabView: View {
  private enum Layout {
    static let compactButtonSize: CGFloat = 48
    static let compactHorizontalInset: CGFloat = 28
  }

  @ObservedObject var model: AppleLiquidTabbarModel
  @Environment(\.accessibilityReduceMotion) private var reduceMotion

  var body: some View {
    ZStack(alignment: .bottom) {
      if #available(iOS 26.0, *), model.isMinimized {
        compactTabBar
          .transition(
            reduceMotion
              ? .identity
              : .scale(scale: 0.82, anchor: .bottomLeading)
                .combined(with: .opacity)
          )
      } else {
        expandedTabBar
          .scaleEffect(
            x: model.isCompressing && !reduceMotion ? 0.97 : 1,
            y: model.isCompressing && !reduceMotion ? 0.94 : 1,
            anchor: .bottomLeading
          )
          .transition(.opacity)
          .animation(
            reduceMotion ? nil : .easeOut(duration: 0.1),
            value: model.isCompressing
          )
      }
    }
    .animation(
      reduceMotion
        ? nil
        : .spring(response: 0.36, dampingFraction: 0.78),
      value: model.isMinimized
    )
  }

  private var expandedTabBar: some View {
    TabView(selection: $model.selectedIndex) {
      ForEach(model.displayedRegularIndices, id: \.self) { index in
        let item = model.items[index]

        if item.symbolWeight == nil, item.activeSymbolWeight == nil {
          Tab(
            LocalizedStringKey(item.title),
            systemImage: model.systemImage(for: item, index: index),
            value: index
          ) {
            Color.clear
          }
        } else {
          Tab(value: index) {
            Color.clear
          } label: {
            Label {
              Text(LocalizedStringKey(item.title))
            } icon: {
              tabImage(for: item, index: index)
            }
          }
        }
      }

      Tab(value: model.searchIndex, role: .search) {
        Color.clear
      } label: {
        tabImage(for: model.searchItem, index: model.searchIndex)
        .accessibilityLabel(Text(model.searchItem.title))
      }
    }
    .background(Color.clear)
    .appleLiquidControlTint(model.selectedTintColor)
  }

  @available(iOS 26.0, *)
  private var compactTabBar: some View {
    GlassEffectContainer(spacing: 24) {
      HStack {
        if let index = model.displayedRegularIndices.first {
          compactButton(for: model.items[index], index: index)
        }

        Spacer(minLength: 24)

        compactButton(for: model.searchItem, index: model.searchIndex)
      }
    }
    .padding(.horizontal, Layout.compactHorizontalInset)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
  }

  @available(iOS 26.0, *)
  private func compactButton(
    for item: AppleLiquidTabbarItem,
    index: Int
  ) -> some View {
    Button {
      model.selectCompactItem(at: index)
    } label: {
      tabImage(for: item, index: index)
        .frame(
          width: Layout.compactButtonSize,
          height: Layout.compactButtonSize
        )
        .contentShape(Circle())
    }
    .buttonStyle(.plain)
    .foregroundStyle(
      index == model.selectedIndex
        ? model.selectedTintColor ?? Color.primary
        : Color.primary
    )
    .accessibilityLabel(Text(item.title))
    .overlay(alignment: .topTrailing) {
      compactBadge(for: item)
        .padding(8)
    }
    .glassEffect(Glass.regular.interactive(true), in: Circle())
  }

  @ViewBuilder
  private func compactBadge(for item: AppleLiquidTabbarItem) -> some View {
    if let color = Color(appleLiquidARGB: item.notificationDotColor) {
      if let value = item.notificationBadgeValue, !value.isEmpty {
        Text(value)
          .font(.caption2.bold())
          .foregroundStyle(Color.white)
          .padding(.horizontal, 5)
          .frame(minWidth: 18, minHeight: 18)
          .background(color, in: Capsule())
      } else {
        Circle()
          .fill(color)
          .frame(width: 5.5, height: 5.5)
      }
    }
  }

  @ViewBuilder
  private func tabImage(
    for item: AppleLiquidTabbarItem,
    index: Int
  ) -> some View {
    let image = Image(systemName: model.systemImage(for: item, index: index))

    if let weight = AppleLiquidSymbolWeight.fontWeight(
      model.symbolWeight(for: item, index: index)
    ) {
      image.font(.system(size: 22, weight: weight))
    } else {
      image
    }
  }
}
