import Flutter
import UIKit

enum AppleLiquidSymbolRenderer {
  static func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "render":
      let configuration = AppleLiquidSymbolConfiguration(arguments: call.arguments)
      result(render(configuration: configuration))
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func render(
    configuration: AppleLiquidSymbolConfiguration
  ) -> FlutterStandardTypedData? {
    let symbolConfiguration = UIImage.SymbolConfiguration(
      pointSize: configuration.pointSize
    )
    guard let symbol = UIImage(
      systemName: configuration.name,
      withConfiguration: symbolConfiguration
    ) else {
      return nil
    }

    let tintColor = UIColor(appleLiquidARGB: configuration.tintColor) ?? .label
    let image = symbol.withTintColor(tintColor, renderingMode: .alwaysOriginal)
    let size = CGSize(
      width: configuration.pointSize,
      height: configuration.pointSize
    )
    let bounds = CGRect(origin: .zero, size: size)
    let format = UIGraphicsImageRendererFormat()
    format.scale = configuration.scale
    format.opaque = false

    let renderer = UIGraphicsImageRenderer(size: size, format: format)
    let pngData = renderer.pngData { _ in
      image.draw(in: aspectFitRect(for: image.size, in: bounds))
    }

    return FlutterStandardTypedData(bytes: pngData)
  }

  private static func aspectFitRect(for imageSize: CGSize, in bounds: CGRect) -> CGRect {
    guard imageSize.width > 0, imageSize.height > 0 else {
      return bounds
    }

    let scale = min(
      bounds.width / imageSize.width,
      bounds.height / imageSize.height
    )
    let fittedSize = CGSize(
      width: imageSize.width * scale,
      height: imageSize.height * scale
    )

    return CGRect(
      x: bounds.midX - fittedSize.width / 2,
      y: bounds.midY - fittedSize.height / 2,
      width: fittedSize.width,
      height: fittedSize.height
    )
  }
}
