import SwiftUI

@available(iOS 18.0, *)
struct AppleLiquidSwiftUITabView: View {
  @ObservedObject var model: AppleLiquidTabbarModel

  var body: some View {
    TabView(selection: $model.selectedIndex) {
      ForEach(model.items.indices, id: \.self) { index in
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
