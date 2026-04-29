import SwiftUI

@available(iOS 18.0, *)
struct AppleLiquidSwiftUITabView: View {
  @ObservedObject var model: AppleLiquidTabbarModel

  var body: some View {
    TabView(selection: $model.selectedIndex) {
      ForEach(model.items.indices, id: \.self) { index in
        let item = model.items[index]

        Tab(
          LocalizedStringKey(item.title),
          systemImage: model.systemImage(for: item, index: index),
          value: index
        ) {
          Color.clear
        }
      }

      Tab(value: model.searchIndex, role: .search) {
        NavigationStack {
          Color.clear
        }
      } label: {
        Image(
          systemName: model.systemImage(
            for: model.searchItem,
            index: model.searchIndex
          )
        )
        .accessibilityLabel(Text(model.searchItem.title))
      }
    }
    .background(Color.clear)
  }
}
