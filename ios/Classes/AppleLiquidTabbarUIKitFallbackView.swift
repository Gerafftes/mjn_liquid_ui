import Combine
import UIKit

final class AppleLiquidTabbarUIKitFallbackView: UIView {
  private let model: AppleLiquidTabbarModel
  private let stackView = UIStackView()
  private var cancellables = Set<AnyCancellable>()
  private let notificationDotSize: CGFloat = 5.5
  private let notificationBadgeSize: CGFloat = 18

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
        image(for: item, index: index),
        for: .normal
      )
      button.setTitle(item.title, for: .normal)
      button.titleLabel?.font = .preferredFont(forTextStyle: .caption2)
      if index == model.selectedIndex {
        button.tintColor = model.selectedTintUIColor ?? .systemBlue
      } else {
        button.tintColor = .secondaryLabel
      }
      button.tag = index
      button.addTarget(self, action: #selector(selectTab(_:)), for: .touchUpInside)
      addNotificationDotIfNeeded(to: button, item: item)
      stackView.addArrangedSubview(button)
    }
  }

  private func image(for item: AppleLiquidTabbarItem, index: Int) -> UIImage? {
    let systemImage = model.systemImage(for: item, index: index)
    guard let weight = AppleLiquidSymbolWeight.imageWeight(
      model.symbolWeight(for: item, index: index)
    ) else {
      return UIImage(systemName: systemImage)
    }

    let configuration = UIImage.SymbolConfiguration(pointSize: 24, weight: weight)
    return UIImage(systemName: systemImage, withConfiguration: configuration)
  }

  private func addNotificationDotIfNeeded(
    to button: UIButton,
    item: AppleLiquidTabbarItem
  ) {
    guard let color = UIColor(appleLiquidARGB: item.notificationDotColor) else {
      return
    }

    let badgeSize: CGFloat
    if item.notificationBadgeValue == nil {
      badgeSize = notificationDotSize
    } else {
      badgeSize = notificationBadgeSize
    }
    let dotView = UIView()
    dotView.backgroundColor = color
    dotView.isUserInteractionEnabled = false
    dotView.layer.cornerRadius = badgeSize / 2
    dotView.translatesAutoresizingMaskIntoConstraints = false

    button.addSubview(dotView)

    if let badgeValue = item.notificationBadgeValue {
      let label = UILabel()
      label.text = badgeValue
      label.textAlignment = .center
      label.textColor = .white
      label.font = .systemFont(ofSize: 11, weight: .semibold)
      label.translatesAutoresizingMaskIntoConstraints = false
      dotView.addSubview(label)

      NSLayoutConstraint.activate([
        label.leadingAnchor.constraint(equalTo: dotView.leadingAnchor),
        label.trailingAnchor.constraint(equalTo: dotView.trailingAnchor),
        label.topAnchor.constraint(equalTo: dotView.topAnchor),
        label.bottomAnchor.constraint(equalTo: dotView.bottomAnchor),
      ])
    }

    NSLayoutConstraint.activate([
      dotView.widthAnchor.constraint(equalToConstant: badgeSize),
      dotView.heightAnchor.constraint(equalToConstant: badgeSize),
      dotView.centerXAnchor.constraint(equalTo: button.centerXAnchor, constant: 10),
      dotView.topAnchor.constraint(equalTo: button.topAnchor, constant: 12),
    ])
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
