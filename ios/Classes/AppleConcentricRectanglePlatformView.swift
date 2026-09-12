import Flutter
import SwiftUI
import UIKit

enum AppleConcentricRectangleGrouping: String {
  case individual
  case all
  case topAndBottom
  case leadingAndTrailing
  case top
  case bottom
  case leading
  case trailing
}

struct AppleConcentricCornerStyleConfiguration {
  enum Kind: String {
    case concentric
    case fixed
  }

  let kind: Kind
  let radius: CGFloat?
  let minimumRadius: CGFloat?

  init(value: Any?) {
    let dictionary = value as? [String: Any] ?? [:]
    kind = Kind(rawValue: dictionary["kind"] as? String ?? "") ?? .concentric

    switch kind {
    case .concentric:
      radius = nil
      minimumRadius = Self.nonNegativeCGFloat(dictionary["minimumRadius"])
    case .fixed:
      radius = Self.nonNegativeCGFloat(dictionary["radius"]) ?? 0
      minimumRadius = nil
    }
  }

  func fallbackRadius(containerCornerRadius: CGFloat?, inset: CGFloat) -> CGFloat {
    switch kind {
    case .fixed:
      return radius ?? 0
    case .concentric:
      let concentricRadius = max(0, (containerCornerRadius ?? inset) - inset)
      return max(concentricRadius, minimumRadius ?? 0)
    }
  }

  @available(iOS 26.0, *)
  var swiftUIStyle: Edge.Corner.Style {
    switch kind {
    case .fixed:
      return .fixed(radius ?? 0)
    case .concentric:
      if let minimumRadius {
        return .concentric(minimum: .fixed(minimumRadius))
      }
      return .concentric
    }
  }

  private static func nonNegativeCGFloat(_ value: Any?) -> CGFloat? {
    guard let doubleValue = AppleLiquidSliderConfiguration.doubleValue(value),
      doubleValue.isFinite,
      doubleValue >= 0
    else {
      return nil
    }

    return CGFloat(doubleValue)
  }
}

struct AppleConcentricRectangleRadii: Equatable {
  let topLeading: CGFloat
  let topTrailing: CGFloat
  let bottomLeading: CGFloat
  let bottomTrailing: CGFloat

  func resolved(for layoutDirection: LayoutDirection) -> Self {
    guard layoutDirection == .rightToLeft else {
      return self
    }

    return Self(
      topLeading: topTrailing,
      topTrailing: topLeading,
      bottomLeading: bottomTrailing,
      bottomTrailing: bottomLeading
    )
  }

  func grouped(_ grouping: AppleConcentricRectangleGrouping) -> Self {
    switch grouping {
    case .individual:
      return self
    case .all:
      let largest = max(topLeading, topTrailing, bottomLeading, bottomTrailing)
      return Self(
        topLeading: largest,
        topTrailing: largest,
        bottomLeading: largest,
        bottomTrailing: largest
      )
    case .topAndBottom:
      let top = max(topLeading, topTrailing)
      let bottom = max(bottomLeading, bottomTrailing)
      return Self(
        topLeading: top,
        topTrailing: top,
        bottomLeading: bottom,
        bottomTrailing: bottom
      )
    case .leadingAndTrailing:
      let leading = max(topLeading, bottomLeading)
      let trailing = max(topTrailing, bottomTrailing)
      return Self(
        topLeading: leading,
        topTrailing: trailing,
        bottomLeading: leading,
        bottomTrailing: trailing
      )
    case .top:
      let top = max(topLeading, topTrailing)
      return Self(
        topLeading: top,
        topTrailing: top,
        bottomLeading: bottomLeading,
        bottomTrailing: bottomTrailing
      )
    case .bottom:
      let bottom = max(bottomLeading, bottomTrailing)
      return Self(
        topLeading: topLeading,
        topTrailing: topTrailing,
        bottomLeading: bottom,
        bottomTrailing: bottom
      )
    case .leading:
      let leading = max(topLeading, bottomLeading)
      return Self(
        topLeading: leading,
        topTrailing: topTrailing,
        bottomLeading: leading,
        bottomTrailing: bottomTrailing
      )
    case .trailing:
      let trailing = max(topTrailing, bottomTrailing)
      return Self(
        topLeading: topLeading,
        topTrailing: trailing,
        bottomLeading: bottomLeading,
        bottomTrailing: trailing
      )
    }
  }

  func normalized(in size: CGSize) -> Self {
    let topLeading = max(0, self.topLeading)
    let topTrailing = max(0, self.topTrailing)
    let bottomLeading = max(0, self.bottomLeading)
    let bottomTrailing = max(0, self.bottomTrailing)
    let width = max(0, size.width)
    let height = max(0, size.height)
    var scale: CGFloat = 1

    for (sum, available) in [
      (topLeading + topTrailing, width),
      (bottomLeading + bottomTrailing, width),
      (topLeading + bottomLeading, height),
      (topTrailing + bottomTrailing, height),
    ] where sum > 0 {
      scale = min(scale, available / sum)
    }

    return Self(
      topLeading: topLeading * scale,
      topTrailing: topTrailing * scale,
      bottomLeading: bottomLeading * scale,
      bottomTrailing: bottomTrailing * scale
    )
  }
}

struct AppleConcentricRectangleConfiguration {
  let color: Int?
  let inset: CGFloat
  let containerCornerRadius: CGFloat?
  let grouping: AppleConcentricRectangleGrouping
  let topLeading: AppleConcentricCornerStyleConfiguration
  let topTrailing: AppleConcentricCornerStyleConfiguration
  let bottomLeading: AppleConcentricCornerStyleConfiguration
  let bottomTrailing: AppleConcentricCornerStyleConfiguration

  init(arguments: Any?) {
    let dictionary = arguments as? [String: Any] ?? [:]
    let corners = dictionary["corners"] as? [String: Any] ?? [:]

    color = AppleLiquidTabbarConfiguration.intValue(dictionary["color"])
    inset = Self.nonNegativeCGFloat(dictionary["inset"]) ?? 0
    containerCornerRadius = Self.nonNegativeCGFloat(
      dictionary["containerCornerRadius"]
    )
    grouping =
      AppleConcentricRectangleGrouping(
        rawValue: corners["grouping"] as? String ?? ""
      ) ?? .individual
    topLeading = AppleConcentricCornerStyleConfiguration(
      value: corners["topLeading"]
    )
    topTrailing = AppleConcentricCornerStyleConfiguration(
      value: corners["topTrailing"]
    )
    bottomLeading = AppleConcentricCornerStyleConfiguration(
      value: corners["bottomLeading"]
    )
    bottomTrailing = AppleConcentricCornerStyleConfiguration(
      value: corners["bottomTrailing"]
    )
  }

  var fallbackRadii: AppleConcentricRectangleRadii {
    AppleConcentricRectangleRadii(
      topLeading: topLeading.fallbackRadius(
        containerCornerRadius: containerCornerRadius,
        inset: inset
      ),
      topTrailing: topTrailing.fallbackRadius(
        containerCornerRadius: containerCornerRadius,
        inset: inset
      ),
      bottomLeading: bottomLeading.fallbackRadius(
        containerCornerRadius: containerCornerRadius,
        inset: inset
      ),
      bottomTrailing: bottomTrailing.fallbackRadius(
        containerCornerRadius: containerCornerRadius,
        inset: inset
      )
    ).grouped(grouping)
  }

  private static func nonNegativeCGFloat(_ value: Any?) -> CGFloat? {
    guard let doubleValue = AppleLiquidSliderConfiguration.doubleValue(value),
      doubleValue.isFinite,
      doubleValue >= 0
    else {
      return nil
    }

    return CGFloat(doubleValue)
  }
}

struct AppleConcentricRectangleView: View {
  let configuration: AppleConcentricRectangleConfiguration
  @Environment(\.layoutDirection) private var layoutDirection

  var body: some View {
    Group {
      if #available(iOS 26.0, *) {
        AppleNativeConcentricRectangle(configuration: configuration)
      } else {
        AppleConcentricRectangleFallbackShape(
          radii: configuration.fallbackRadii.resolved(for: layoutDirection)
        )
        .fill(Color(appleLiquidARGB: configuration.color) ?? .clear)
        .padding(configuration.inset)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

@available(iOS 26.0, *)
private struct AppleNativeConcentricRectangle: View {
  let configuration: AppleConcentricRectangleConfiguration

  var body: some View {
    Group {
      if let containerCornerRadius = configuration.containerCornerRadius {
        ZStack {
          filledShape
        }
        .containerShape(
          RoundedRectangle(
            cornerRadius: containerCornerRadius,
            style: .continuous
          )
        )
      } else {
        filledShape
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }

  private var filledShape: some View {
    shape
      .fill(Color(appleLiquidARGB: configuration.color) ?? .clear)
      .padding(configuration.inset)
  }

  private var shape: ConcentricRectangle {
    switch configuration.grouping {
    case .individual:
      return ConcentricRectangle(
        topLeadingCorner: configuration.topLeading.swiftUIStyle,
        topTrailingCorner: configuration.topTrailing.swiftUIStyle,
        bottomLeadingCorner: configuration.bottomLeading.swiftUIStyle,
        bottomTrailingCorner: configuration.bottomTrailing.swiftUIStyle
      )
    case .all:
      return ConcentricRectangle(
        corners: configuration.topLeading.swiftUIStyle,
        isUniform: true
      )
    case .topAndBottom:
      return ConcentricRectangle(
        uniformTopCorners: configuration.topLeading.swiftUIStyle,
        uniformBottomCorners: configuration.bottomLeading.swiftUIStyle
      )
    case .leadingAndTrailing:
      return ConcentricRectangle(
        uniformLeadingCorners: configuration.topLeading.swiftUIStyle,
        uniformTrailingCorners: configuration.topTrailing.swiftUIStyle
      )
    case .top:
      return ConcentricRectangle(
        uniformTopCorners: configuration.topLeading.swiftUIStyle,
        bottomLeadingCorner: configuration.bottomLeading.swiftUIStyle,
        bottomTrailingCorner: configuration.bottomTrailing.swiftUIStyle
      )
    case .bottom:
      return ConcentricRectangle(
        uniformBottomCorners: configuration.bottomLeading.swiftUIStyle,
        topLeadingCorner: configuration.topLeading.swiftUIStyle,
        topTrailingCorner: configuration.topTrailing.swiftUIStyle
      )
    case .leading:
      return ConcentricRectangle(
        uniformLeadingCorners: configuration.topLeading.swiftUIStyle,
        topTrailingCorner: configuration.topTrailing.swiftUIStyle,
        bottomTrailingCorner: configuration.bottomTrailing.swiftUIStyle
      )
    case .trailing:
      return ConcentricRectangle(
        uniformTrailingCorners: configuration.topTrailing.swiftUIStyle,
        topLeadingCorner: configuration.topLeading.swiftUIStyle,
        bottomLeadingCorner: configuration.bottomLeading.swiftUIStyle
      )
    }
  }
}

private struct AppleConcentricRectangleFallbackShape: Shape {
  let radii: AppleConcentricRectangleRadii

  func path(in rect: CGRect) -> Path {
    guard rect.width > 0, rect.height > 0 else {
      return Path()
    }

    let radii = radii.normalized(in: rect.size)
    var path = Path()
    path.move(to: CGPoint(x: rect.minX + radii.topLeading, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX - radii.topTrailing, y: rect.minY))
    path.addArc(
      center: CGPoint(
        x: rect.maxX - radii.topTrailing,
        y: rect.minY + radii.topTrailing
      ),
      radius: radii.topTrailing,
      startAngle: .degrees(-90),
      endAngle: .degrees(0),
      clockwise: false
    )
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - radii.bottomTrailing))
    path.addArc(
      center: CGPoint(
        x: rect.maxX - radii.bottomTrailing,
        y: rect.maxY - radii.bottomTrailing
      ),
      radius: radii.bottomTrailing,
      startAngle: .degrees(0),
      endAngle: .degrees(90),
      clockwise: false
    )
    path.addLine(to: CGPoint(x: rect.minX + radii.bottomLeading, y: rect.maxY))
    path.addArc(
      center: CGPoint(
        x: rect.minX + radii.bottomLeading,
        y: rect.maxY - radii.bottomLeading
      ),
      radius: radii.bottomLeading,
      startAngle: .degrees(90),
      endAngle: .degrees(180),
      clockwise: false
    )
    path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + radii.topLeading))
    path.addArc(
      center: CGPoint(
        x: rect.minX + radii.topLeading,
        y: rect.minY + radii.topLeading
      ),
      radius: radii.topLeading,
      startAngle: .degrees(180),
      endAngle: .degrees(270),
      clockwise: false
    )
    path.closeSubpath()
    return path
  }
}

final class AppleConcentricRectanglePlatformViewFactory: NSObject,
  FlutterPlatformViewFactory
{
  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    AppleConcentricRectanglePlatformView(frame: frame, arguments: args)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}

final class AppleConcentricRectanglePlatformView: NSObject, FlutterPlatformView {
  private let containerView: AppleLiquidPlatformViewContainer
  private var hostingController: UIViewController?

  init(frame: CGRect, arguments args: Any?) {
    containerView = AppleLiquidPlatformViewContainer(frame: frame)

    super.init()

    let hostingController = UIHostingController(
      rootView: AppleConcentricRectangleView(
        configuration: AppleConcentricRectangleConfiguration(arguments: args)
      )
    )
    hostingController.view.backgroundColor = .clear
    hostingController.view.isOpaque = false
    containerView.host(hostingController)
    self.hostingController = hostingController
  }

  deinit {
    containerView.disposeHostedViewController()
  }

  func view() -> UIView {
    containerView
  }
}
