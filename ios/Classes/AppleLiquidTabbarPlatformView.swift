import Flutter
import SwiftUI
import UIKit

final class AppleLiquidTabbarHostingController<Content: View>: UIHostingController<Content> {
  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = .clear
    view.isOpaque = false
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    view.appleLiquidClearWrapperBackgrounds()
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
}

final class AppleLiquidTabbarPlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
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
    containerView = UIView(frame: frame)
    channel = FlutterMethodChannel(
      name: "\(AppleLiquidTabbarConstants.viewType)/\(viewId)",
      binaryMessenger: messenger
    )
    model = AppleLiquidTabbarModel(
      configuration: AppleLiquidTabbarConfiguration(arguments: args)
    )

    super.init()

    containerView.backgroundColor = .clear
    containerView.isOpaque = false
    model.onSelectionChanged = { [weak self] index in
      self?.sendSelectionChanged(index)
    }

    installNativeView()
    channel.setMethodCallHandler(handle)
  }

  deinit {
    channel.setMethodCallHandler(nil)
  }

  func view() -> UIView {
    containerView
  }

  private func installNativeView() {
    if #available(iOS 18.0, *) {
      let hostingController = AppleLiquidTabbarHostingController(
        rootView: AppleLiquidSwiftUITabView(model: model)
      )
      hostingController.view.backgroundColor = .clear
      hostingController.view.isOpaque = false
      addPinnedSubview(hostingController.view)
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
