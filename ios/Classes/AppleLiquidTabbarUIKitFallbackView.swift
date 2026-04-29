import Combine
import UIKit

final class AppleLiquidTabbarUIKitFallbackView: UIView {
  private let model: AppleLiquidTabbarModel
  private let stackView = UIStackView()
  private var cancellables = Set<AnyCancellable>()

  init(model: AppleLiquidTabbarModel) {
    self.model = model
    super.init(frame: .zero)

    isOpaque = false
    backgroundColor = .clear
    stackView.axis = .horizontal
    stackView.alignment = .fill
    stackView.distribution = .fillEqually
    stackView.spacing = 0

    addSubview(stackView)
    stackView.translatesAutoresizingMaskIntoConstraints = false

    NSLayoutConstraint.activate([
      stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
      stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
      stackView.topAnchor.constraint(equalTo: topAnchor),
      stackView.bottomAnchor.constraint(equalTo: bottomAnchor),
    ])

    bindModel()
    refresh()
  }

  required init?(coder: NSCoder) {
    nil
  }

  func refresh() {
    stackView.arrangedSubviews.forEach { view in
      stackView.removeArrangedSubview(view)
      view.removeFromSuperview()
    }

    for (index, item) in model.allItems.enumerated() {
      let button = UIButton(type: .system)
      button.setImage(
        UIImage(systemName: model.systemImage(for: item, index: index)),
        for: .normal
      )
      button.setTitle(item.title, for: .normal)
      button.titleLabel?.font = .preferredFont(forTextStyle: .caption2)
      button.tintColor = index == model.selectedIndex ? .systemBlue : .secondaryLabel
      button.tag = index
      button.addTarget(self, action: #selector(selectTab(_:)), for: .touchUpInside)
      stackView.addArrangedSubview(button)
    }
  }

  private func bindModel() {
    model.$selectedIndex
      .receive(on: RunLoop.main)
      .sink { [weak self] _ in
        self?.refresh()
      }
      .store(in: &cancellables)
  }

  @objc private func selectTab(_ sender: UIButton) {
    model.setSelectedIndex(sender.tag, notifyFlutter: true)
  }
}
