import Flutter
import SwiftUI
import UIKit

struct AppleLiquidSurfaceView: View {
  let configuration: AppleLiquidSurfaceConfiguration

  var body: some View {
    Group {
      if #available(iOS 26.0, *) {
        AppleLiquidNativeGlassSurface(configuration: configuration)
      } else {
        RoundedRectangle(
          cornerRadius: configuration.borderRadius,
          style: .continuous
        )
        .fill(
          configuration.isClear
            ? Color.clear
            : Color(UIColor.secondarySystemBackground).opacity(0.72)
        )
        .overlay(
          RoundedRectangle(
            cornerRadius: configuration.borderRadius,
            style: .continuous
          )
          .stroke(Color(UIColor.separator).opacity(0.28), lineWidth: 1)
        )
      }
    }
  }
}

@available(iOS 26.0, *)
private struct AppleLiquidNativeGlassSurface: View {
  let configuration: AppleLiquidSurfaceConfiguration

  var body: some View {
    let tint = Color(appleLiquidARGB: configuration.tintColor)
    let glass = (configuration.isClear ? Glass.clear : Glass.regular)
      .tint(tint)
      .interactive(configuration.interactive)

    RoundedRectangle(
      cornerRadius: configuration.borderRadius,
      style: .continuous
    )
    .fill(Color.clear)
    .glassEffect(
      glass,
      in: RoundedRectangle(
        cornerRadius: configuration.borderRadius,
        style: .continuous
      )
    )
  }
}

final class AppleLiquidSurfacePlatformViewFactory: NSObject, FlutterPlatformViewFactory {
  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    return AppleLiquidSurfacePlatformView(frame: frame, arguments: args)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}

final class AppleLiquidSurfacePlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private var hostingController: UIViewController?

  init(frame: CGRect, arguments args: Any?) {
    containerView = UIView(frame: frame)

    super.init()

    containerView.backgroundColor = .clear

    let hostingController = UIHostingController(
      rootView: AppleLiquidSurfaceView(
        configuration: AppleLiquidSurfaceConfiguration(arguments: args)
      )
    )
    hostingController.view.backgroundColor = .clear
    addPinnedSubview(hostingController.view)
    self.hostingController = hostingController
  }

  func view() -> UIView {
    containerView
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
}
