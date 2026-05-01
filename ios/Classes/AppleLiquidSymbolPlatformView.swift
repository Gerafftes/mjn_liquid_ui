import Flutter
import UIKit

final class AppleLiquidSymbolPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
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
    return AppleLiquidSymbolPlatformView(
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

final class AppleLiquidSymbolPlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private let imageView: UIImageView
  private let channel: FlutterMethodChannel

  init(
    frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?,
    messenger: FlutterBinaryMessenger
  ) {
    containerView = UIView(frame: frame)
    imageView = UIImageView(frame: .zero)
    channel = FlutterMethodChannel(
      name: "\(AppleLiquidTabbarConstants.symbolViewType)/\(viewId)",
      binaryMessenger: messenger
    )

    super.init()

    containerView.backgroundColor = .clear
    containerView.isOpaque = false

    imageView.translatesAutoresizingMaskIntoConstraints = false
    imageView.backgroundColor = .clear
    imageView.isOpaque = false
    imageView.contentMode = .scaleAspectFit

    containerView.addSubview(imageView)
    NSLayoutConstraint.activate([
      imageView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
      imageView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
      imageView.topAnchor.constraint(equalTo: containerView.topAnchor),
      imageView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor),
    ])

    apply(configuration: AppleLiquidSymbolConfiguration(arguments: args))
    channel.setMethodCallHandler(handle)
  }

  deinit {
    channel.setMethodCallHandler(nil)
  }

  func view() -> UIView {
    containerView
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "updateConfiguration":
      apply(configuration: AppleLiquidSymbolConfiguration(arguments: call.arguments))
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func apply(configuration: AppleLiquidSymbolConfiguration) {
    let symbolConfiguration = UIImage.SymbolConfiguration(
      pointSize: configuration.pointSize
    )
    imageView.preferredSymbolConfiguration = symbolConfiguration
    imageView.image = UIImage(
      systemName: configuration.name,
      withConfiguration: symbolConfiguration
    )?.withRenderingMode(.alwaysTemplate)
    imageView.tintColor = UIColor(appleLiquidARGB: configuration.tintColor) ?? .label
  }
}
