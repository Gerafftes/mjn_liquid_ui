import Combine
import Flutter
import SwiftUI
import UIKit

final class AppleLiquidSwitchModel: ObservableObject {
  @Published private(set) var value: Bool
  @Published private(set) var tintColor: Color?

  var onValueChanged: ((Bool) -> Void)?
  var onInteractionChanged: ((Bool) -> Void)?

  private var isInteracting = false

  init(configuration: AppleLiquidSwitchConfiguration) {
    value = configuration.value
    tintColor = Color(appleLiquidARGB: configuration.tintColor)
  }

  func update(configuration: AppleLiquidSwitchConfiguration) {
    value = configuration.value
    tintColor = Color(appleLiquidARGB: configuration.tintColor)
  }

  func setValue(_ value: Bool, notifyFlutter: Bool) {
    guard self.value != value else {
      return
    }

    self.value = value

    if notifyFlutter {
      onValueChanged?(value)
    }
  }

  func setInteracting(_ isInteracting: Bool) {
    guard self.isInteracting != isInteracting else {
      return
    }

    self.isInteracting = isInteracting
    onInteractionChanged?(isInteracting)
  }
}

struct AppleLiquidSwitchView: View {
  @ObservedObject var model: AppleLiquidSwitchModel

  var body: some View {
    HStack {
      Spacer(minLength: 0)
      Toggle(
        "",
        isOn: Binding(
          get: { model.value },
          set: { model.setValue($0, notifyFlutter: true) }
        )
      )
      .labelsHidden()
      .appleLiquidControlTint(model.tintColor)
      .simultaneousGesture(
        DragGesture(minimumDistance: 0)
          .onChanged { _ in
            model.setInteracting(true)
          }
          .onEnded { _ in
            model.setInteracting(false)
          }
      )
      Spacer(minLength: 0)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

final class AppleLiquidSwitchPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    return AppleLiquidSwitchPlatformView(
      frame: frame,
      viewIdentifier: viewId,
      arguments: args,
      messenger: messenger
    )
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}

final class AppleLiquidSwitchPlatformView: NSObject, FlutterPlatformView {
  private let containerView: AppleLiquidPlatformViewContainer
  private let channel: FlutterMethodChannel
  private let model: AppleLiquidSwitchModel
  private var hostingController: UIViewController?

  init(
    frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?,
    messenger: FlutterBinaryMessenger
  ) {
    containerView = AppleLiquidPlatformViewContainer(frame: frame)
    channel = FlutterMethodChannel(
      name: "\(AppleLiquidTabbarConstants.switchViewType)/\(viewId)",
      binaryMessenger: messenger
    )
    model = AppleLiquidSwitchModel(
      configuration: AppleLiquidSwitchConfiguration(arguments: args)
    )

    super.init()

    model.onValueChanged = { [weak self] value in
      self?.channel.invokeMethod("valueChanged", arguments: ["value": value])
    }
    model.onInteractionChanged = { [weak self] isInteracting in
      self?.channel.invokeMethod(
        "interactionChanged",
        arguments: ["isInteracting": isInteracting]
      )
    }

    let hostingController = UIHostingController(
      rootView: AppleLiquidSwitchView(model: model)
    )
    hostingController.view.backgroundColor = .clear
    hostingController.view.isOpaque = false
    containerView.host(hostingController)
    self.hostingController = hostingController

    channel.setMethodCallHandler(handle)
  }

  deinit {
    channel.setMethodCallHandler(nil)
    model.onValueChanged = nil
    model.onInteractionChanged = nil
    containerView.disposeHostedViewController()
  }

  func view() -> UIView {
    containerView
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setValue":
      let configuration = AppleLiquidSwitchConfiguration(arguments: call.arguments)
      model.setValue(configuration.value, notifyFlutter: false)
      result(nil)
    case "updateConfiguration":
      let configuration = AppleLiquidSwitchConfiguration(arguments: call.arguments)
      model.update(configuration: configuration)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
