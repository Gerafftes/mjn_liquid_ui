import Flutter
import UIKit

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
  private let containerView: UIView
  private let switchControl: UISwitch
  private let channel: FlutterMethodChannel
  private var isInteracting = false

  init(
    frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?,
    messenger: FlutterBinaryMessenger
  ) {
    let creationStart = Date()
    containerView = UIView(frame: frame)
    switchControl = UISwitch(frame: .zero)
    channel = FlutterMethodChannel(
      name: "\(AppleLiquidTabbarConstants.switchViewType)/\(viewId)",
      binaryMessenger: messenger
    )

    super.init()

    containerView.backgroundColor = .clear
    containerView.isOpaque = false
    containerView.isUserInteractionEnabled = true

    switchControl.translatesAutoresizingMaskIntoConstraints = false
    switchControl.backgroundColor = .clear
    switchControl.isOpaque = false
    switchControl.addTarget(
      self,
      action: #selector(handleValueChanged),
      for: .valueChanged
    )
    switchControl.addTarget(
      self,
      action: #selector(handleInteractionStarted),
      for: [.touchDown, .touchDragEnter]
    )
    switchControl.addTarget(
      self,
      action: #selector(handleInteractionEnded),
      for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit]
    )

    containerView.addSubview(switchControl)
    NSLayoutConstraint.activate([
      switchControl.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
      switchControl.centerYAnchor.constraint(equalTo: containerView.centerYAnchor),
    ])

    apply(configuration: AppleLiquidSwitchConfiguration(arguments: args))
    channel.setMethodCallHandler(handle)

    #if DEBUG
      let elapsedMilliseconds = Date().timeIntervalSince(creationStart) * 1000
      print(
        "[mjn_liquid_ui] UISwitch platform view \(viewId) created in "
          + "\(String(format: "%.2f", elapsedMilliseconds))ms"
      )
    #endif
  }

  deinit {
    channel.setMethodCallHandler(nil)
    switchControl.removeTarget(nil, action: nil, for: .allEvents)
  }

  func view() -> UIView {
    containerView
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "setValue":
      let configuration = AppleLiquidSwitchConfiguration(arguments: call.arguments)
      setValue(configuration.value, animated: false)
      result(nil)
    case "updateConfiguration":
      let configuration = AppleLiquidSwitchConfiguration(arguments: call.arguments)
      apply(configuration: configuration)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func apply(configuration: AppleLiquidSwitchConfiguration) {
    setValue(configuration.value, animated: false)
    switchControl.onTintColor = UIColor(appleLiquidARGB: configuration.tintColor)
  }

  private func setValue(_ value: Bool, animated: Bool) {
    guard switchControl.isOn != value else {
      return
    }

    switchControl.setOn(value, animated: animated)
  }

  @objc private func handleValueChanged() {
    channel.invokeMethod(
      "valueChanged",
      arguments: ["value": switchControl.isOn]
    )
  }

  @objc private func handleInteractionStarted() {
    setInteracting(true)
  }

  @objc private func handleInteractionEnded() {
    setInteracting(false)
  }

  private func setInteracting(_ isInteracting: Bool) {
    guard self.isInteracting != isInteracting else {
      return
    }

    self.isInteracting = isInteracting
    channel.invokeMethod(
      "interactionChanged",
      arguments: ["isInteracting": isInteracting]
    )
  }
}
