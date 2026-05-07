import Flutter
import SwiftUI
import UIKit

final class AppleLiquidTabbarHostingController<Content: View>: UIHostingController<Content> {
  private let model: AppleLiquidTabbarModel

  init(rootView: Content, model: AppleLiquidTabbarModel) {
    self.model = model
    super.init(rootView: rootView)
  }

  @MainActor dynamic required init?(coder aDecoder: NSCoder) {
    nil
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
    view.isOpaque = false
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    view.appleLiquidClearWrapperBackgrounds()
    view.appleLiquidApplyTabNotificationDots(from: model.allItems)
  }
}

private extension UIView {
  func appleLiquidClearWrapperBackgrounds() {
    // Keep Apple's tab bar and glass internals intact; only clear wrapper views.
    guard !(self is UITabBar), !(self is UIVisualEffectView) else {
      return
    }

    backgroundColor = .clear
    isOpaque = false

    subviews.forEach { subview in
      subview.appleLiquidClearWrapperBackgrounds()
    }
  }

  func appleLiquidApplyTabNotificationDots(from items: [AppleLiquidTabbarItem]) {
    if let tabBar = self as? UITabBar {
      tabBar.appleLiquidApplyNotificationDots(from: items)
      return
    }

    subviews.forEach { subview in
      subview.appleLiquidApplyTabNotificationDots(from: items)
    }
  }

}

private extension UITabBar {
  func appleLiquidApplyNotificationDots(from items: [AppleLiquidTabbarItem]) {
    let badgeColors = items.compactMap(\.notificationDotColor)
    if badgeColors.count == 1,
      let badgeColor = UIColor(appleLiquidARGB: badgeColors[0])
    {
      appleLiquidApplyBadgeAppearance(color: badgeColor)
    }

    for (index, tabBarItem) in (self.items ?? []).enumerated() {
      let item = items.indices.contains(index) ? items[index] : nil
      let color = UIColor(appleLiquidARGB: item?.notificationDotColor)
      let badgeValue = item?.notificationBadgeValue
      let badgeTextColor: UIColor = badgeValue == nil ? .clear : .white

      tabBarItem.badgeValue = color == nil ? nil : badgeValue ?? ""
      tabBarItem.badgeColor = color
      tabBarItem.setBadgeTextAttributes(
        [.foregroundColor: badgeTextColor],
        for: .normal
      )
    }
  }

  func appleLiquidApplyBadgeAppearance(color: UIColor) {
    let appearance = standardAppearance.copy()

    [
      appearance.stackedLayoutAppearance,
      appearance.inlineLayoutAppearance,
      appearance.compactInlineLayoutAppearance,
    ].forEach { itemAppearance in
      itemAppearance.normal.badgeBackgroundColor = color
      itemAppearance.selected.badgeBackgroundColor = color
    }

    standardAppearance = appearance
    if #available(iOS 15.0, *) {
      scrollEdgeAppearance = appearance
    }
  }
}

final class AppleLiquidTabbarPlatformView: NSObject, FlutterPlatformView {
  private let containerView: AppleLiquidPlatformViewContainer
  private let channel: FlutterMethodChannel
  private let model: AppleLiquidTabbarModel
  private var fallbackView: AppleLiquidTabbarUIKitFallbackView?
  private var hostingController: UIViewController?

  init(
    frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?,
    messenger: FlutterBinaryMessenger
  ) {
    containerView = AppleLiquidPlatformViewContainer(frame: frame)
    channel = FlutterMethodChannel(
      name: "\(AppleLiquidTabbarConstants.viewType)/\(viewId)",
      binaryMessenger: messenger
    )
    model = AppleLiquidTabbarModel(
      configuration: AppleLiquidTabbarConfiguration(arguments: args)
    )

    super.init()

    model.onSelectionChanged = { [weak self] index in
      self?.sendSelectionChanged(index)
    }

    installNativeView()
    channel.setMethodCallHandler(handle)
  }

  deinit {
    channel.setMethodCallHandler(nil)
    model.onSelectionChanged = nil
    fallbackView?.removeFromSuperview()
    containerView.disposeHostedViewController()
  }

  func view() -> UIView {
    containerView
  }

  private func installNativeView() {
    if #available(iOS 18.0, *) {
      let hostingController = AppleLiquidTabbarHostingController(
        rootView: AppleLiquidSwiftUITabView(model: model),
        model: model
      )
      hostingController.view.backgroundColor = .clear
      hostingController.view.isOpaque = false
      containerView.host(hostingController)
      self.hostingController = hostingController
    } else {
      let fallbackView = AppleLiquidTabbarUIKitFallbackView(model: model)
      addPinnedSubview(fallbackView)
      self.fallbackView = fallbackView
    }
  }

  private func addPinnedSubview(_ subview: UIView) {
    subview.translatesAutoresizingMaskIntoConstraints = false
    containerView.addSubview(subview)

    NSLayoutConstraint.activate([
      subview.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      subview.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      subview.topAnchor.constraint(equalTo: containerView.topAnchor),
      subview.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
    ])
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setCurrentIndex":
      let arguments = call.arguments as? [String: Any]
      let index = AppleLiquidTabbarConfiguration.intValue(
        arguments?["currentIndex"]
      ) ?? 0
      model.setSelectedIndex(index, notifyFlutter: false)
      fallbackView?.refresh()
      result(nil)

    case "updateConfiguration":
      let configuration = AppleLiquidTabbarConfiguration(arguments: call.arguments)
      model.update(configuration: configuration)
      containerView.appleLiquidApplyTabNotificationDots(from: model.allItems)
      fallbackView?.refresh()
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func sendSelectionChanged(_ index: Int) {
    channel.invokeMethod("tabSelected", arguments: ["index": index])
  }
}
