import Combine
import Flutter
import SwiftUI
import UIKit

enum AppleLiquidSheetPresenter {
  @available(iOS 16.0, *)
  private static var activeSession: AppleLiquidSheetSession?
  #if DEBUG
  private static var debugChannel: FlutterMethodChannel?
  #endif

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: AppleLiquidTabbarConstants.sheetChannelName,
      binaryMessenger: messenger
    )
    #if DEBUG
    debugChannel = channel
    #endif

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "showTemplateSheet":
        showTemplateSheet(arguments: call.arguments, result: result)

      case "dismissTemplateSheet":
        dismissTemplateSheet(result: result)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  #if DEBUG
  static func debugLog(_ message: String) {
    NSLog(message)
    debugChannel?.invokeMethod("debugLog", arguments: message)
  }
  #endif

  private static func showTemplateSheet(
    arguments: Any?,
    result: @escaping FlutterResult
  ) {
    guard #available(iOS 16.0, *) else {
      result(false)
      return
    }

    guard activeSession == nil else {
      result(true)
      return
    }

    guard let presenter = topViewController(from: activeRootViewController()),
      presenter.viewIfLoaded?.window != nil
    else {
      result(false)
      return
    }

    let configuration = AppleLiquidSheetConfiguration(arguments: arguments)
    let session = AppleLiquidSheetSession(
      configuration: configuration,
      presentingView: presenter.view,
      result: result,
      onFinish: {
        activeSession = nil
      }
    )

    guard session.present(from: presenter) else {
      result(false)
      return
    }

    activeSession = session
  }

  private static func dismissTemplateSheet(result: @escaping FlutterResult) {
    guard #available(iOS 16.0, *) else {
      result(false)
      return
    }

    guard let activeSession else {
      result(false)
      return
    }

    activeSession.dismissFromControl {
      result(true)
    }
  }

  private static func activeRootViewController() -> UIViewController? {
    let foregroundScenes = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .filter { scene in
        scene.activationState == .foregroundActive ||
          scene.activationState == .foregroundInactive
      }

    let windows = foregroundScenes.flatMap(\.windows)
    return windows.first(where: \.isKeyWindow)?.rootViewController ??
      windows.first?.rootViewController
  }

  private static func topViewController(
    from viewController: UIViewController?
  ) -> UIViewController? {
    if let navigationController = viewController as? UINavigationController {
      return topViewController(from: navigationController.visibleViewController)
    }

    if let tabBarController = viewController as? UITabBarController {
      return topViewController(from: tabBarController.selectedViewController)
    }

    if let presentedViewController = viewController?.presentedViewController {
      return topViewController(from: presentedViewController)
    }

    return viewController
  }
}

private struct AppleLiquidSheetConfiguration {
  let backgroundZoomScale: CGFloat
  let sheetColor: Int?
  let content: AppleLiquidSheetContentConfiguration

  init(arguments: Any?) {
    let arguments = arguments as? [String: Any]
    self.backgroundZoomScale = Self.clampedCGFloat(
      arguments?["backgroundZoomScale"],
      defaultValue: 1,
      minValue: 0.85,
      maxValue: 1
    )
    self.sheetColor = AppleLiquidTabbarConfiguration.intValue(
      arguments?["sheetColor"]
    )
    self.content = AppleLiquidSheetContentConfiguration(
      value: arguments?["content"]
    )
  }

  private static func clampedCGFloat(
    _ value: Any?,
    defaultValue: Double,
    minValue: Double,
    maxValue: Double
  ) -> CGFloat {
    let doubleValue: Double
    if let value = value as? Double {
      doubleValue = value
    } else if let value = value as? NSNumber {
      doubleValue = value.doubleValue
    } else {
      doubleValue = defaultValue
    }

    return CGFloat(min(max(doubleValue, minValue), maxValue))
  }

  var resolvedSheetColor: UIColor {
    if let customColor = UIColor(appleLiquidARGB: sheetColor) {
      return customColor
    }

    return UIColor { traits in
      if traits.userInterfaceStyle == .dark {
        return .secondarySystemBackground
      }

      return .systemBackground
    }
  }

  @available(iOS 15.0, *)
  var resolvedSheetSwiftUIColor: Color {
    Color(uiColor: resolvedSheetColor)
  }

  @available(iOS 15.0, *)
  var resolvedSheetColorScheme: ColorScheme? {
    guard sheetColor != nil else {
      return nil
    }

    return resolvedSheetColor.appleLiquidPrefersDarkColorScheme ? .dark : .light
  }
}

private struct AppleLiquidSheetContentConfiguration {
  let title: String
  let doneAccessibilityLabel: String
  let detents: AppleLiquidSheetDetentConfiguration
  let sections: [AppleLiquidSheetSectionConfiguration]

  init(value: Any?, fallbackTitle: String = "Settings") {
    guard let dictionary = value as? [String: Any] else {
      self = Self.defaultContent
      return
    }

    let title = Self.nonEmptyString(
      dictionary["title"],
      defaultValue: fallbackTitle
    )
    let doneAccessibilityLabel = Self.nonEmptyString(
      dictionary["doneSemanticLabel"],
      defaultValue: "Done"
    )
    let detents = AppleLiquidSheetDetentConfiguration(
      value: dictionary["detents"]
    )
    let sections = (dictionary["sections"] as? [Any] ?? [])
      .enumerated()
      .compactMap { index, value in
        AppleLiquidSheetSectionConfiguration(
          value: value,
          index: index
        )
      }

    self.init(
      title: title,
      doneAccessibilityLabel: doneAccessibilityLabel,
      detents: detents,
      sections: sections.isEmpty ? Self.defaultContent.sections : sections
    )
  }

  private init(
    title: String,
    doneAccessibilityLabel: String,
    detents: AppleLiquidSheetDetentConfiguration = .automatic,
    sections: [AppleLiquidSheetSectionConfiguration]
  ) {
    self.title = title
    self.doneAccessibilityLabel = doneAccessibilityLabel
    self.detents = detents
    self.sections = sections
  }

  private static func nonEmptyString(
    _ value: Any?,
    defaultValue: String
  ) -> String {
    guard let string = value as? String,
      !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      return defaultValue
    }

    return string
  }

  var estimatedDetentHeight: CGFloat {
    let navigationChromeHeight: CGFloat = 92
    let sectionHeaderHeight = sections.reduce(CGFloat.zero) { partial, section in
      partial + (section.title == nil ? 12 : 34)
    }
    let sectionSpacing = CGFloat(max(sections.count - 1, 0)) * 12
    let rowHeight = sections.reduce(CGFloat.zero) { partial, section in
      partial + section.estimatedHeight
    }

    return navigationChromeHeight + sectionHeaderHeight + sectionSpacing + rowHeight
  }

  var preferredDetentHeights: AppleLiquidSheetDetentHeights {
    Self.detentHeights(for: estimatedDetentHeight, configuration: detents)
  }

  var preferredDetentHeight: CGFloat {
    preferredDetentHeights.primary
  }

  static func normalizedDetentHeight(_ height: CGFloat) -> CGFloat {
    detentHeights(for: height).primary
  }

  static func detentHeights(
    for estimatedHeight: CGFloat,
    configuration: AppleLiquidSheetDetentConfiguration = .automatic
  ) -> AppleLiquidSheetDetentHeights {
    let screenHeight = UIScreen.main.bounds.height
    let roundedHeight = estimatedHeight.rounded(.up)
    let minimumHeight: CGFloat = 240
    let primaryMaximumHeight = min(560, max(320, screenHeight * 0.64))
    let expandedMaximumHeight = min(700, max(360, screenHeight * 0.88))
    let primaryHeight = configuration.initialHeight.map { height in
      Self.clampedDetentHeight(
        height,
        min: minimumHeight,
        max: expandedMaximumHeight
      )
    } ?? min(
      max(roundedHeight, minimumHeight),
      primaryMaximumHeight
    )

    if let configuredExpandedHeight = configuration.expandedHeight {
      let expandedHeight = Self.clampedDetentHeight(
        configuredExpandedHeight,
        min: minimumHeight,
        max: expandedMaximumHeight
      )

      if expandedHeight > primaryHeight + 24 {
        return AppleLiquidSheetDetentHeights(
          primary: primaryHeight,
          expanded: expandedHeight
        )
      }
    }

    let automaticExpandedHeight = min(
      max(roundedHeight, primaryHeight + 96),
      expandedMaximumHeight
    )
    guard roundedHeight > primaryHeight + 24,
      automaticExpandedHeight > primaryHeight + 24
    else {
      return AppleLiquidSheetDetentHeights(
        primary: primaryHeight,
        expanded: nil
      )
    }

    return AppleLiquidSheetDetentHeights(
      primary: primaryHeight,
      expanded: automaticExpandedHeight
    )
  }

  private static func clampedDetentHeight(
    _ height: CGFloat,
    min minimumHeight: CGFloat,
    max maximumHeight: CGFloat
  ) -> CGFloat {
    Swift.min(Swift.max(height.rounded(.up), minimumHeight), maximumHeight)
  }

  static let defaultContent = AppleLiquidSheetContentConfiguration(
    title: "Settings",
    doneAccessibilityLabel: "Done",
    sections: [
      AppleLiquidSheetSectionConfiguration(
        id: "default-overview",
        title: "Overview",
        rows: [
          AppleLiquidSheetRowConfiguration.value(
            id: "default-component",
            title: "Component",
            value: "Liquid Sheet"
          ),
          AppleLiquidSheetRowConfiguration.value(
            id: "default-mode",
            title: "Mode",
            value: "Navigation Form"
          ),
          AppleLiquidSheetRowConfiguration.navigation(
            id: "default-preview-link",
            title: "Preview details",
            content: AppleLiquidSheetContentConfiguration(
              title: "Preview",
              doneAccessibilityLabel: "Done",
              sections: [
                AppleLiquidSheetSectionConfiguration(
                  id: "default-preview",
                  title: "Preview",
                  rows: [
                    AppleLiquidSheetRowConfiguration.textField(
                      id: "default-preview-title",
                      title: "Title",
                      value: "Sheet Preview"
                    ),
                    AppleLiquidSheetRowConfiguration.textField(
                      id: "default-preview-owner",
                      title: "Owner",
                      value: "Design Team"
                    ),
                  ]
                ),
                AppleLiquidSheetSectionConfiguration(
                  id: "default-preview-context",
                  title: "Context",
                  rows: [
                    AppleLiquidSheetRowConfiguration.value(
                      id: "default-preview-surface",
                      title: "Surface",
                      value: "Form"
                    ),
                    AppleLiquidSheetRowConfiguration.value(
                      id: "default-preview-detents",
                      title: "Detents",
                      value: "Content-sized"
                    ),
                  ]
                ),
              ]
            )
          ),
        ]
      ),
      AppleLiquidSheetSectionConfiguration(
        id: "default-appearance",
        title: "Appearance",
        rows: [
          AppleLiquidSheetRowConfiguration.toggle(
            id: "default-liquid-glass",
            title: "Liquid Glass",
            value: true
          ),
          AppleLiquidSheetRowConfiguration.toggle(
            id: "default-reduce-motion",
            title: "Reduce motion",
            value: false
          ),
          AppleLiquidSheetRowConfiguration.picker(
            id: "default-accent",
            title: "Accent",
            options: ["Blue", "Teal", "Graphite"],
            selectedOption: "Blue"
          ),
          AppleLiquidSheetRowConfiguration.segmented(
            id: "default-layout",
            title: "Layout",
            options: ["List", "Grid"],
            selectedOption: "List"
          ),
          AppleLiquidSheetRowConfiguration.slider(
            id: "default-intensity",
            title: "Intensity",
            value: 0.72,
            tintColor: 0xFF0A84FF
          ),
        ]
      ),
      AppleLiquidSheetSectionConfiguration(
        id: "default-updates",
        title: "Updates",
        rows: [
          AppleLiquidSheetRowConfiguration.picker(
            id: "default-refresh",
            title: "Refresh",
            options: ["Manual", "Daily", "Weekly"],
            selectedOption: "Daily"
          ),
          AppleLiquidSheetRowConfiguration.navigation(
            id: "default-rules-link",
            title: "Notification rules",
            content: AppleLiquidSheetContentConfiguration(
              title: "Rules",
              doneAccessibilityLabel: "Done",
              sections: [
                AppleLiquidSheetSectionConfiguration(
                  id: "default-rules",
                  title: "Rules",
                  rows: [
                    AppleLiquidSheetRowConfiguration.toggle(
                      id: "default-critical-updates",
                      title: "Critical updates",
                      value: true
                    ),
                    AppleLiquidSheetRowConfiguration.toggle(
                      id: "default-weekly-digest",
                      title: "Weekly digest",
                      value: false
                    ),
                  ]
                ),
                AppleLiquidSheetSectionConfiguration(
                  id: "default-routing",
                  title: "Routing",
                  rows: [
                    AppleLiquidSheetRowConfiguration.value(
                      id: "default-channel",
                      title: "Channel",
                      value: "In-app"
                    ),
                    AppleLiquidSheetRowConfiguration.value(
                      id: "default-priority",
                      title: "Priority",
                      value: "Normal"
                    ),
                  ]
                ),
              ]
            )
          ),
        ]
      ),
      AppleLiquidSheetSectionConfiguration(
        id: "default-metadata",
        title: "Metadata",
        rows: [
          AppleLiquidSheetRowConfiguration.value(
            id: "default-platform",
            title: "Platform",
            value: "iOS"
          ),
          AppleLiquidSheetRowConfiguration.value(
            id: "default-status",
            title: "Status",
            value: "Prototype"
          ),
        ]
      ),
    ]
  )
}

private struct AppleLiquidSheetDetentHeights {
  let primary: CGFloat
  let expanded: CGFloat?
}

private struct AppleLiquidSheetDetentConfiguration {
  static let automatic = AppleLiquidSheetDetentConfiguration(
    initialHeight: nil,
    expandedHeight: nil
  )

  let initialHeight: CGFloat?
  let expandedHeight: CGFloat?

  init(value: Any?) {
    let dictionary = value as? [String: Any] ?? [:]
    self.init(
      initialHeight: Self.height(dictionary["initialHeight"]),
      expandedHeight: Self.height(dictionary["expandedHeight"])
    )
  }

  private init(initialHeight: CGFloat?, expandedHeight: CGFloat?) {
    self.initialHeight = initialHeight
    self.expandedHeight = expandedHeight
  }

  private static func height(_ value: Any?) -> CGFloat? {
    let doubleValue: Double?
    if let value = value as? Double {
      doubleValue = value
    } else if let value = value as? NSNumber {
      doubleValue = value.doubleValue
    } else {
      doubleValue = nil
    }

    guard let doubleValue, doubleValue > 0 else {
      return nil
    }

    return CGFloat(doubleValue)
  }
}

private struct AppleLiquidSheetSectionConfiguration: Identifiable {
  let id: String
  let title: String?
  let rows: [AppleLiquidSheetRowConfiguration]

  init?(value: Any?, index: Int) {
    guard let dictionary = value as? [String: Any] else {
      return nil
    }

    let rows = (dictionary["rows"] as? [Any] ?? [])
      .enumerated()
      .compactMap { rowIndex, value in
        AppleLiquidSheetRowConfiguration(
          value: value,
          id: "section-\(index)-row-\(rowIndex)"
        )
      }

    guard !rows.isEmpty else {
      return nil
    }

    self.init(
      id: "section-\(index)",
      title: Self.optionalNonEmptyString(dictionary["title"]),
      rows: rows
    )
  }

  init(id: String, title: String?, rows: [AppleLiquidSheetRowConfiguration]) {
    self.id = id
    self.title = title
    self.rows = rows
  }

  private static func optionalNonEmptyString(_ value: Any?) -> String? {
    guard let string = value as? String,
      !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      return nil
    }

    return string
  }

  var estimatedHeight: CGFloat {
    rows.reduce(CGFloat.zero) { partial, row in
      partial + row.estimatedHeight
    }
  }
}

private enum AppleLiquidSheetRowKind: String {
  case text
  case value
  case toggle
  case picker
  case segmented
  case slider
  case navigation
  case textField
}

private enum AppleLiquidSheetSegmentedAnimationCurve: String {
  case linear
  case easeIn
  case easeOut
  case easeInOut
  case spring
}

private struct AppleLiquidSheetSegmentedStyleConfiguration {
  let selectedBackgroundARGB: Int?
  let unselectedBackgroundARGB: Int?
  let selectedTextARGB: Int?
  let unselectedTextARGB: Int?
  let selectedBorderARGB: Int?
  let unselectedBorderARGB: Int?
  let selectedShadowARGB: Int?
  let titleARGB: Int?
  let subtitleARGB: Int?
  let buttonHeight: CGFloat
  let cornerRadius: CGFloat
  let buttonSpacing: CGFloat
  let contentSpacing: CGFloat
  let verticalPadding: CGFloat
  let borderWidth: CGFloat
  let selectedShadowRadius: CGFloat
  let selectedShadowOffsetX: CGFloat
  let selectedShadowOffsetY: CGFloat
  let titleFontSize: CGFloat?
  let subtitleFontSize: CGFloat?
  let buttonFontSize: CGFloat?
  let titleFontWeight: Font.Weight
  let subtitleFontWeight: Font.Weight
  let buttonFontWeight: Font.Weight
  let minimumTextScaleFactor: CGFloat
  let pressedScale: CGFloat
  let pressedOpacity: Double
  let pressAnimationDuration: Double
  let selectionAnimationEnabled: Bool
  let selectionAnimationCurve: AppleLiquidSheetSegmentedAnimationCurve
  let selectionAnimationDuration: Double
  let selectionSpringDamping: Double

  init(value: Any?) {
    let dictionary = value as? [String: Any] ?? [:]
    self.selectedBackgroundARGB = AppleLiquidTabbarConfiguration.intValue(
      dictionary["selectedBackgroundColor"]
    )
    self.unselectedBackgroundARGB = AppleLiquidTabbarConfiguration.intValue(
      dictionary["unselectedBackgroundColor"]
    )
    self.selectedTextARGB = AppleLiquidTabbarConfiguration.intValue(
      dictionary["selectedTextColor"]
    )
    self.unselectedTextARGB = AppleLiquidTabbarConfiguration.intValue(
      dictionary["unselectedTextColor"]
    )
    self.selectedBorderARGB = AppleLiquidTabbarConfiguration.intValue(
      dictionary["selectedBorderColor"]
    )
    self.unselectedBorderARGB = AppleLiquidTabbarConfiguration.intValue(
      dictionary["unselectedBorderColor"]
    )
    self.selectedShadowARGB = AppleLiquidTabbarConfiguration.intValue(
      dictionary["selectedShadowColor"]
    )
    self.titleARGB = AppleLiquidTabbarConfiguration.intValue(
      dictionary["titleColor"]
    )
    self.subtitleARGB = AppleLiquidTabbarConfiguration.intValue(
      dictionary["subtitleColor"]
    )
    self.buttonHeight = Self.clampedCGFloat(
      dictionary["buttonHeight"],
      defaultValue: 46,
      minValue: 28,
      maxValue: 120
    )
    self.cornerRadius = Self.clampedCGFloat(
      dictionary["cornerRadius"],
      defaultValue: 14,
      minValue: 0,
      maxValue: 60
    )
    self.buttonSpacing = Self.clampedCGFloat(
      dictionary["buttonSpacing"],
      defaultValue: 12,
      minValue: 0,
      maxValue: 64
    )
    self.contentSpacing = Self.clampedCGFloat(
      dictionary["contentSpacing"],
      defaultValue: 12,
      minValue: 0,
      maxValue: 64
    )
    self.verticalPadding = Self.clampedCGFloat(
      dictionary["verticalPadding"],
      defaultValue: 6,
      minValue: 0,
      maxValue: 48
    )
    self.borderWidth = Self.clampedCGFloat(
      dictionary["borderWidth"],
      defaultValue: 1,
      minValue: 0,
      maxValue: 12
    )
    self.selectedShadowRadius = Self.clampedCGFloat(
      dictionary["selectedShadowRadius"],
      defaultValue: 8,
      minValue: 0,
      maxValue: 48
    )
    self.selectedShadowOffsetX = Self.clampedCGFloat(
      dictionary["selectedShadowOffsetX"],
      defaultValue: 0,
      minValue: -48,
      maxValue: 48
    )
    self.selectedShadowOffsetY = Self.clampedCGFloat(
      dictionary["selectedShadowOffsetY"],
      defaultValue: 2,
      minValue: -48,
      maxValue: 48
    )
    self.titleFontSize = Self.optionalClampedCGFloat(
      dictionary["titleFontSize"],
      minValue: 8,
      maxValue: 72
    )
    self.subtitleFontSize = Self.optionalClampedCGFloat(
      dictionary["subtitleFontSize"],
      minValue: 8,
      maxValue: 72
    )
    self.buttonFontSize = Self.optionalClampedCGFloat(
      dictionary["buttonFontSize"],
      minValue: 8,
      maxValue: 72
    )
    self.titleFontWeight = Self.fontWeight(
      dictionary["titleFontWeight"],
      defaultValue: .semibold
    )
    self.subtitleFontWeight = Self.fontWeight(
      dictionary["subtitleFontWeight"],
      defaultValue: .regular
    )
    self.buttonFontWeight = Self.fontWeight(
      dictionary["buttonFontWeight"],
      defaultValue: .semibold
    )
    self.minimumTextScaleFactor = Self.clampedCGFloat(
      dictionary["minimumTextScaleFactor"],
      defaultValue: 0.75,
      minValue: 0.1,
      maxValue: 1
    )
    self.pressedScale = Self.clampedCGFloat(
      dictionary["pressedScale"],
      defaultValue: 0.98,
      minValue: 0.8,
      maxValue: 1
    )
    self.pressedOpacity = Self.clampedDouble(
      dictionary["pressedOpacity"],
      defaultValue: 0.86,
      minValue: 0.1,
      maxValue: 1
    )
    self.pressAnimationDuration = Self.clampedDouble(
      dictionary["pressAnimationDuration"],
      defaultValue: 0.12,
      minValue: 0,
      maxValue: 1
    )
    self.selectionAnimationEnabled = Self.bool(
      dictionary["selectionAnimationEnabled"],
      defaultValue: true
    )
    self.selectionAnimationCurve =
      AppleLiquidSheetSegmentedAnimationCurve(
        rawValue: dictionary["selectionAnimationCurve"] as? String ?? ""
      ) ?? .easeInOut
    self.selectionAnimationDuration = Self.clampedDouble(
      dictionary["selectionAnimationDuration"],
      defaultValue: 0.15,
      minValue: 0,
      maxValue: 2
    )
    self.selectionSpringDamping = Self.clampedDouble(
      dictionary["selectionSpringDamping"],
      defaultValue: 0.82,
      minValue: 0.1,
      maxValue: 1
    )
  }

  var titleFont: Font {
    resolvedFont(
      size: titleFontSize,
      defaultFont: .headline,
      weight: titleFontWeight
    )
  }

  var subtitleFont: Font {
    resolvedFont(
      size: subtitleFontSize,
      defaultFont: .footnote,
      weight: subtitleFontWeight
    )
  }

  var buttonFont: Font {
    resolvedFont(
      size: buttonFontSize,
      defaultFont: .body,
      weight: buttonFontWeight
    )
  }

  var titleColor: Color? {
    Color(appleLiquidARGB: titleARGB)
  }

  var subtitleColor: Color? {
    Color(appleLiquidARGB: subtitleARGB)
  }

  var selectionAnimation: Animation? {
    guard selectionAnimationEnabled, selectionAnimationDuration > 0 else {
      return nil
    }

    switch selectionAnimationCurve {
    case .linear:
      return .linear(duration: selectionAnimationDuration)
    case .easeIn:
      return .easeIn(duration: selectionAnimationDuration)
    case .easeOut:
      return .easeOut(duration: selectionAnimationDuration)
    case .easeInOut:
      return .easeInOut(duration: selectionAnimationDuration)
    case .spring:
      return .spring(
        response: selectionAnimationDuration,
        dampingFraction: selectionSpringDamping,
        blendDuration: selectionAnimationDuration * 0.15
      )
    }
  }

  func estimatedHeight(hasSubtitle: Bool) -> CGFloat {
    let titleLineHeight = (titleFontSize ?? 17) * 1.2
    let subtitleLineHeight = hasSubtitle
      ? (subtitleFontSize ?? 13) * 1.2 + 3
      : 0

    return titleLineHeight + subtitleLineHeight + contentSpacing +
      buttonHeight + verticalPadding * 2
  }

  private func resolvedFont(
    size: CGFloat?,
    defaultFont: Font,
    weight: Font.Weight
  ) -> Font {
    if let size {
      return .system(size: size, weight: weight)
    }

    return defaultFont.weight(weight)
  }

  private static func fontWeight(
    _ value: Any?,
    defaultValue: Font.Weight
  ) -> Font.Weight {
    AppleLiquidSymbolWeight.fontWeight(value as? String) ?? defaultValue
  }

  private static func optionalClampedCGFloat(
    _ value: Any?,
    minValue: Double,
    maxValue: Double
  ) -> CGFloat? {
    guard let value = double(value) else {
      return nil
    }

    return CGFloat(min(max(value, minValue), maxValue))
  }

  private static func clampedCGFloat(
    _ value: Any?,
    defaultValue: Double,
    minValue: Double,
    maxValue: Double
  ) -> CGFloat {
    CGFloat(
      clampedDouble(
        value,
        defaultValue: defaultValue,
        minValue: minValue,
        maxValue: maxValue
      )
    )
  }

  private static func clampedDouble(
    _ value: Any?,
    defaultValue: Double,
    minValue: Double,
    maxValue: Double
  ) -> Double {
    min(max(double(value) ?? defaultValue, minValue), maxValue)
  }

  private static func double(_ value: Any?) -> Double? {
    if let value = value as? Double {
      return value
    }

    if let value = value as? NSNumber {
      return value.doubleValue
    }

    return nil
  }

  private static func bool(_ value: Any?, defaultValue: Bool) -> Bool {
    if let value = value as? Bool {
      return value
    }

    if let value = value as? NSNumber {
      return value.boolValue
    }

    return defaultValue
  }
}

private struct AppleLiquidSheetRowConfiguration: Identifiable {
  let id: String
  let kind: AppleLiquidSheetRowKind
  let title: String
  let subtitle: String?
  let value: String?
  let boolValue: Bool
  let options: [String]
  let selectedOption: String?
  let sliderValue: Double
  let sliderMin: Double
  let sliderMax: Double
  let sliderStep: Double?
  let tintColor: Int?
  let content: AppleLiquidSheetContentConfiguration?
  let systemImage: String?
  let segmentedStyle: AppleLiquidSheetSegmentedStyleConfiguration

  init?(value: Any?, id: String) {
    guard let dictionary = value as? [String: Any] else {
      return nil
    }

    let kind = AppleLiquidSheetRowKind(
      rawValue: Self.string(dictionary["type"], defaultValue: "text")
    ) ?? .text
    let title = Self.string(dictionary["title"], defaultValue: "Item")
    let options = Self.stringArray(dictionary["options"])
    let sliderMin = Self.double(dictionary["min"], defaultValue: 0)
    let rawSliderMax = Self.double(dictionary["max"], defaultValue: 1)
    let sliderMax = rawSliderMax > sliderMin ? rawSliderMax : sliderMin + 1
    let sliderStep = Self.validStep(
      Self.optionalDouble(dictionary["step"]),
      min: sliderMin,
      max: sliderMax
    )

    if kind == .picker && options.isEmpty {
      return nil
    }

    if kind == .segmented &&
      (options.count != 2 || options.first == options.last)
    {
      return nil
    }

    let content: AppleLiquidSheetContentConfiguration?
    if kind == .navigation {
      guard dictionary["content"] != nil else {
        return nil
      }

      content = AppleLiquidSheetContentConfiguration(
        value: dictionary["content"],
        fallbackTitle: title
      )
    } else {
      content = nil
    }

    self.id = id
    self.kind = kind
    self.title = title
    self.subtitle = Self.optionalString(dictionary["subtitle"])
    self.value = Self.optionalString(dictionary["value"])
    self.boolValue = Self.bool(dictionary["boolValue"], defaultValue: false)
    self.options = options
    self.selectedOption = Self.optionalString(dictionary["selectedOption"])
    self.sliderMin = sliderMin
    self.sliderMax = sliderMax
    self.sliderStep = sliderStep
    self.sliderValue = Self.normalizedSliderValue(
      Self.optionalDouble(dictionary["sliderValue"]) ??
        Self.optionalDouble(dictionary["value"]) ??
        sliderMin,
      min: sliderMin,
      max: sliderMax,
      step: sliderStep
    )
    self.tintColor = AppleLiquidTabbarConfiguration.intValue(
      dictionary["tintColor"]
    )
    self.content = content
    self.systemImage = Self.optionalString(dictionary["systemImage"])
    self.segmentedStyle = AppleLiquidSheetSegmentedStyleConfiguration(
      value: dictionary["segmentedStyle"]
    )
  }

  private init(
    id: String,
    kind: AppleLiquidSheetRowKind,
    title: String,
    subtitle: String? = nil,
    value: String? = nil,
    boolValue: Bool = false,
    options: [String] = [],
    selectedOption: String? = nil,
    sliderValue: Double = 0,
    sliderMin: Double = 0,
    sliderMax: Double = 1,
    sliderStep: Double? = nil,
    tintColor: Int? = nil,
    content: AppleLiquidSheetContentConfiguration? = nil,
    systemImage: String? = nil,
    segmentedStyle: AppleLiquidSheetSegmentedStyleConfiguration =
      AppleLiquidSheetSegmentedStyleConfiguration(value: nil)
  ) {
    self.id = id
    self.kind = kind
    self.title = title
    self.subtitle = subtitle
    self.value = value
    self.boolValue = boolValue
    self.options = options
    self.selectedOption = selectedOption
    self.sliderMin = sliderMin
    self.sliderMax = sliderMax
    self.sliderStep = sliderStep
    self.sliderValue = Self.normalizedSliderValue(
      sliderValue,
      min: sliderMin,
      max: sliderMax,
      step: sliderStep
    )
    self.tintColor = tintColor
    self.content = content
    self.systemImage = systemImage
    self.segmentedStyle = segmentedStyle
  }

  static func text(
    id: String,
    title: String,
    subtitle: String? = nil,
    systemImage: String? = nil
  ) -> AppleLiquidSheetRowConfiguration {
    AppleLiquidSheetRowConfiguration(
      id: id,
      kind: .text,
      title: title,
      subtitle: subtitle,
      systemImage: systemImage
    )
  }

  static func value(
    id: String,
    title: String,
    value: String,
    subtitle: String? = nil,
    systemImage: String? = nil
  ) -> AppleLiquidSheetRowConfiguration {
    AppleLiquidSheetRowConfiguration(
      id: id,
      kind: .value,
      title: title,
      subtitle: subtitle,
      value: value,
      systemImage: systemImage
    )
  }

  static func toggle(
    id: String,
    title: String,
    value: Bool,
    subtitle: String? = nil,
    systemImage: String? = nil
  ) -> AppleLiquidSheetRowConfiguration {
    AppleLiquidSheetRowConfiguration(
      id: id,
      kind: .toggle,
      title: title,
      subtitle: subtitle,
      boolValue: value,
      systemImage: systemImage
    )
  }

  static func picker(
    id: String,
    title: String,
    options: [String],
    selectedOption: String? = nil,
    subtitle: String? = nil,
    systemImage: String? = nil,
    style: AppleLiquidSheetSegmentedStyleConfiguration =
      AppleLiquidSheetSegmentedStyleConfiguration(value: nil)
  ) -> AppleLiquidSheetRowConfiguration {
    AppleLiquidSheetRowConfiguration(
      id: id,
      kind: .picker,
      title: title,
      subtitle: subtitle,
      options: options,
      selectedOption: selectedOption,
      systemImage: systemImage,
      segmentedStyle: style
    )
  }

  static func segmented(
    id: String,
    title: String,
    options: [String],
    selectedOption: String? = nil,
    subtitle: String? = nil,
    systemImage: String? = nil
  ) -> AppleLiquidSheetRowConfiguration {
    AppleLiquidSheetRowConfiguration(
      id: id,
      kind: .segmented,
      title: title,
      subtitle: subtitle,
      options: options,
      selectedOption: selectedOption,
      systemImage: systemImage
    )
  }

  static func slider(
    id: String,
    title: String,
    value: Double,
    min: Double = 0,
    max: Double = 1,
    step: Double? = nil,
    tintColor: Int? = nil,
    subtitle: String? = nil,
    systemImage: String? = nil
  ) -> AppleLiquidSheetRowConfiguration {
    let resolvedMax = max > min ? max : min + 1
    let resolvedStep = validStep(step, min: min, max: resolvedMax)

    return AppleLiquidSheetRowConfiguration(
      id: id,
      kind: .slider,
      title: title,
      subtitle: subtitle,
      sliderValue: value,
      sliderMin: min,
      sliderMax: resolvedMax,
      sliderStep: resolvedStep,
      tintColor: tintColor,
      systemImage: systemImage
    )
  }

  static func navigation(
    id: String,
    title: String,
    content: AppleLiquidSheetContentConfiguration,
    subtitle: String? = nil,
    systemImage: String? = nil
  ) -> AppleLiquidSheetRowConfiguration {
    AppleLiquidSheetRowConfiguration(
      id: id,
      kind: .navigation,
      title: title,
      subtitle: subtitle,
      content: content,
      systemImage: systemImage
    )
  }

  static func textField(
    id: String,
    title: String,
    value: String,
    subtitle: String? = nil,
    systemImage: String? = nil
  ) -> AppleLiquidSheetRowConfiguration {
    AppleLiquidSheetRowConfiguration(
      id: id,
      kind: .textField,
      title: title,
      subtitle: subtitle,
      value: value,
      systemImage: systemImage
    )
  }

  var resolvedSelectedOption: String {
    if let selectedOption, options.contains(selectedOption) {
      return selectedOption
    }

    return options.first ?? ""
  }

  var estimatedHeight: CGFloat {
    let baseHeight: CGFloat

    switch kind {
    case .text:
      baseHeight = subtitle == nil ? 48 : 68
    case .value:
      baseHeight = subtitle == nil ? 48 : 66
    case .toggle:
      baseHeight = subtitle == nil ? 50 : 68
    case .picker:
      baseHeight = subtitle == nil ? 50 : 68
    case .segmented:
      baseHeight = segmentedStyle.estimatedHeight(hasSubtitle: subtitle != nil)
    case .slider:
      baseHeight = subtitle == nil ? 76 : 94
    case .navigation:
      baseHeight = subtitle == nil ? 50 : 68
    case .textField:
      baseHeight = 54
    }

    return systemImage == nil ? baseHeight : max(baseHeight, 54)
  }

  private static func string(_ value: Any?, defaultValue: String) -> String {
    guard let string = value as? String,
      !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      return defaultValue
    }

    return string
  }

  private static func optionalString(_ value: Any?) -> String? {
    guard let string = value as? String,
      !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      return nil
    }

    return string
  }

  private static func stringArray(_ value: Any?) -> [String] {
    guard let values = value as? [Any] else {
      return []
    }

    return values.compactMap { value in
      guard let string = value as? String,
        !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      else {
        return nil
      }

      return string
    }
  }

  private static func bool(_ value: Any?, defaultValue: Bool) -> Bool {
    if let value = value as? Bool {
      return value
    }

    if let value = value as? NSNumber {
      return value.boolValue
    }

    return defaultValue
  }

  private static func double(_ value: Any?, defaultValue: Double) -> Double {
    optionalDouble(value) ?? defaultValue
  }

  private static func optionalDouble(_ value: Any?) -> Double? {
    if let value = value as? Double {
      return value
    }

    if let value = value as? NSNumber {
      return value.doubleValue
    }

    return nil
  }

  private static func validStep(
    _ step: Double?,
    min: Double,
    max: Double
  ) -> Double? {
    guard let step, step > 0, step <= max - min else {
      return nil
    }

    return step
  }

  private static func normalizedSliderValue(
    _ value: Double,
    min: Double,
    max: Double,
    step: Double?
  ) -> Double {
    let clampedValue = Swift.min(Swift.max(value, min), max)
    guard let step else {
      return clampedValue
    }

    let steppedValue = min + ((clampedValue - min) / step).rounded() * step
    return Swift.min(Swift.max(steppedValue, min), max)
  }

  func normalizedSliderValue(_ value: Double) -> Double {
    Self.normalizedSliderValue(
      value,
      min: sliderMin,
      max: sliderMax,
      step: sliderStep
    )
  }

  func formattedSliderValue(_ value: Double) -> String {
    let normalizedValue = normalizedSliderValue(value)

    if sliderMin == 0 && sliderMax == 1 {
      return "\(Int((normalizedValue * 100).rounded()))%"
    }

    return String(format: "%.2f", normalizedValue)
      .replacingOccurrences(of: ".00", with: "")
  }
}

private extension UIColor {
  var appleLiquidPrefersDarkColorScheme: Bool {
    guard let components = appleLiquidRGBAComponents(
      in: UIScreen.main.traitCollection
    ) else {
      return false
    }

    let luminance = 0.2126 * components.red +
      0.7152 * components.green +
      0.0722 * components.blue
    return luminance < 0.5
  }

  private func appleLiquidRGBAComponents(
    in traits: UITraitCollection? = nil
  ) -> (
    red: CGFloat,
    green: CGFloat,
    blue: CGFloat,
    alpha: CGFloat
  )? {
    let color = traits.map { resolvedColor(with: $0) } ?? self
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0

    guard color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
      return nil
    }

    return (red, green, blue, alpha)
  }
}

private final class AppleLiquidBackgroundInteractionBlockerView: UIView {
  override init(frame: CGRect) {
    super.init(frame: frame)

    backgroundColor = .clear
    isUserInteractionEnabled = true
    isAccessibilityElement = false
  }

  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
    bounds.contains(point) ? self : nil
  }
}

@available(iOS 16.0, *)
private final class AppleLiquidSheetSession {
  private let zoomedCornerRadius: CGFloat = 44
  private let configuration: AppleLiquidSheetConfiguration
  private let presentationState = AppleLiquidSheetPresentationState()
  private weak var presentingView: UIView?
  private var hostController: UIViewController?
  private var backgroundInteractionBlocker: UIView?
  private let result: FlutterResult
  private let onFinish: () -> Void
  private let originalTransform: CGAffineTransform
  private let originalCornerRadius: CGFloat
  private let originalMasksToBounds: Bool
  private var didApplyZoom = false
  private var didRestoreZoom = false
  private var didFinish = false
  private var restingSheetMinY: CGFloat?
  private var dismissProgress: CGFloat = 0
  private var isKeyboardVisible = false
  private var isKeyboardTransitioning = false
  private var isControlInteractionActive = false
  private var keyboardTransitionWorkItem: DispatchWorkItem?
  private var dismissalCallbacks: [() -> Void] = []
  private var isDismissing = false

  init(
    configuration: AppleLiquidSheetConfiguration,
    presentingView: UIView?,
    result: @escaping FlutterResult,
    onFinish: @escaping () -> Void
  ) {
    self.configuration = configuration
    self.presentingView = presentingView
    self.result = result
    self.onFinish = onFinish
    self.originalTransform = presentingView?.transform ?? .identity
    self.originalCornerRadius = presentingView?.layer.cornerRadius ?? 0
    self.originalMasksToBounds = presentingView?.layer.masksToBounds ?? false
    registerKeyboardNotifications()
  }

  deinit {
    keyboardTransitionWorkItem?.cancel()
    NotificationCenter.default.removeObserver(self)
    removeBackgroundInteractionBlocker()
  }

  func present(from presenter: UIViewController) -> Bool {
    guard let window = presenter.viewIfLoaded?.window else {
      return false
    }

    installBackgroundInteractionBlocker(in: window)

    let hostView = AppleLiquidSheetPresentationHost(
      configuration: configuration,
      presentationState: presentationState,
      onFrameChange: { [weak self] sheetFrame, windowBounds in
        self?.updateBackgroundZoom(
          sheetFrame: sheetFrame,
          windowBounds: windowBounds
        )
      },
      onControlInteractionChanged: { [weak self] isInteracting in
        self?.setControlInteractionActive(isInteracting)
      },
      onDismiss: { [weak self] in
        self?.completeDismissal()
      }
    )

    let hostController = UIHostingController(rootView: hostView)
    hostController.view.backgroundColor = .clear
    hostController.modalPresentationStyle = .overFullScreen
    hostController.modalTransitionStyle = .crossDissolve
    self.hostController = hostController

    presenter.present(hostController, animated: false) { [weak self] in
      guard let self, !self.didFinish else {
        return
      }

      self.applyBackgroundZoom()
      self.presentationState.present()
    }

    return true
  }

  private func installBackgroundInteractionBlocker(in window: UIWindow) {
    removeBackgroundInteractionBlocker()

    let blocker = AppleLiquidBackgroundInteractionBlockerView()
    blocker.translatesAutoresizingMaskIntoConstraints = false
    window.addSubview(blocker)

    NSLayoutConstraint.activate([
      blocker.leadingAnchor.constraint(equalTo: window.leadingAnchor),
      blocker.trailingAnchor.constraint(equalTo: window.trailingAnchor),
      blocker.topAnchor.constraint(equalTo: window.topAnchor),
      blocker.bottomAnchor.constraint(equalTo: window.bottomAnchor),
    ])

    backgroundInteractionBlocker = blocker
  }

  private func removeBackgroundInteractionBlocker() {
    backgroundInteractionBlocker?.removeFromSuperview()
    backgroundInteractionBlocker = nil
  }

  func dismissFromControl(onDismissed: (() -> Void)? = nil) {
    guard !didFinish else {
      onDismissed?()
      return
    }

    if let onDismissed {
      dismissalCallbacks.append(onDismissed)
    }

    guard !isDismissing else {
      return
    }

    isDismissing = true
    beginStationaryDismissAnimation()

    if presentationState.isPresented {
      presentationState.dismiss()
    } else {
      completeDismissal()
    }
  }

  private func applyBackgroundZoom() {
    guard configuration.backgroundZoomScale < 0.999, let presentingView else {
      return
    }

    didApplyZoom = true
    UIView.animate(
      withDuration: 0.28,
      delay: 0,
      options: [.curveEaseOut, .allowUserInteraction],
      animations: {
        presentingView.transform = CGAffineTransform(
          scaleX: self.configuration.backgroundZoomScale,
          y: self.configuration.backgroundZoomScale
        )
        presentingView.layer.cornerRadius = self.zoomedCornerRadius
        presentingView.layer.cornerCurve = .continuous
        presentingView.layer.masksToBounds = true
      }
    )
  }

  private func updateBackgroundZoom(sheetFrame: CGRect, windowBounds: CGRect) {
    guard didApplyZoom,
      !didRestoreZoom,
      !didFinish,
      configuration.backgroundZoomScale < 0.999,
      let presentingView
    else {
      return
    }

    if isControlInteractionActive {
      dismissProgress = 0
      applyPresentedBackgroundZoomWithoutAnimation()
      return
    }

    if isKeyboardAffectingLayout {
      dismissProgress = 0
      applyPresentedBackgroundZoomWithoutAnimation()
      return
    }

    let currentMinY = max(0, sheetFrame.minY)
    if restingSheetMinY == nil || currentMinY < restingSheetMinY! {
      restingSheetMinY = currentMinY
    }

    guard let restingSheetMinY else {
      return
    }

    let travelDistance = max(1, windowBounds.maxY - restingSheetMinY)
    let dragProgress = min(
      max((currentMinY - restingSheetMinY) / travelDistance, 0),
      1
    )
    dismissProgress = dragProgress

    let scale = configuration.backgroundZoomScale +
      (1 - configuration.backgroundZoomScale) * dragProgress

    CATransaction.begin()
    CATransaction.setDisableActions(true)
    presentingView.transform = CGAffineTransform(scaleX: scale, y: scale)
    presentingView.layer.cornerRadius = zoomedCornerRadius
    presentingView.layer.cornerCurve = .continuous
    presentingView.layer.masksToBounds = true
    CATransaction.commit()
  }

  private func setControlInteractionActive(_ isActive: Bool) {
    guard isControlInteractionActive != isActive else {
      return
    }

    isControlInteractionActive = isActive

    if isActive {
      dismissProgress = 0
      applyPresentedBackgroundZoomWithoutAnimation()
    }
  }

  private func beginStationaryDismissAnimation() {
    guard dismissProgress <= 0.02 else {
      return
    }

    restoreBackgroundZoom()
  }

  private func restoreBackgroundZoom() {
    guard didApplyZoom, !didRestoreZoom, let presentingView else {
      return
    }

    didRestoreZoom = true
    UIView.animate(
      withDuration: 0.24,
      delay: 0,
      options: [.curveEaseOut, .allowUserInteraction],
      animations: {
        presentingView.transform = self.originalTransform
        presentingView.layer.cornerRadius = self.originalCornerRadius
        presentingView.layer.masksToBounds = self.originalMasksToBounds
      }
    )
  }

  private var isKeyboardAffectingLayout: Bool {
    isKeyboardVisible || isKeyboardTransitioning
  }

  private func applyPresentedBackgroundZoomWithoutAnimation() {
    guard didApplyZoom, !didRestoreZoom, let presentingView else {
      return
    }

    CATransaction.begin()
    CATransaction.setDisableActions(true)
    presentingView.transform = CGAffineTransform(
      scaleX: configuration.backgroundZoomScale,
      y: configuration.backgroundZoomScale
    )
    presentingView.layer.cornerRadius = zoomedCornerRadius
    presentingView.layer.cornerCurve = .continuous
    presentingView.layer.masksToBounds = true
    CATransaction.commit()
  }

  private func resetKeyboardAffectedZoomState() {
    restingSheetMinY = nil
    dismissProgress = 0
    applyPresentedBackgroundZoomWithoutAnimation()
  }

  private func registerKeyboardNotifications() {
    let notificationCenter = NotificationCenter.default
    notificationCenter.addObserver(
      self,
      selector: #selector(keyboardWillShow),
      name: UIResponder.keyboardWillShowNotification,
      object: nil
    )
    notificationCenter.addObserver(
      self,
      selector: #selector(keyboardWillHide),
      name: UIResponder.keyboardWillHideNotification,
      object: nil
    )
    notificationCenter.addObserver(
      self,
      selector: #selector(keyboardDidHide),
      name: UIResponder.keyboardDidHideNotification,
      object: nil
    )
  }

  @objc private func keyboardWillShow(_ notification: Notification) {
    isKeyboardVisible = true
    lockKeyboardLayoutUpdates(using: notification)
    resetKeyboardAffectedZoomState()
    logZoomState(event: "keyboardWillShow")
  }

  @objc private func keyboardWillHide(_ notification: Notification) {
    isKeyboardVisible = false
    lockKeyboardLayoutUpdates(using: notification)
    logZoomState(event: "keyboardWillHide")
  }

  @objc private func keyboardDidHide(_ notification: Notification) {
    isKeyboardVisible = false
    keyboardTransitionWorkItem?.cancel()
    keyboardTransitionWorkItem = nil
    isKeyboardTransitioning = false
    resetKeyboardAffectedZoomState()
    logZoomState(event: "keyboardDidHide")
  }

  private func lockKeyboardLayoutUpdates(using notification: Notification) {
    isKeyboardTransitioning = true
    keyboardTransitionWorkItem?.cancel()

    let duration =
      notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey]
      as? Double ?? 0.25
    let workItem = DispatchWorkItem { [weak self] in
      guard let self else {
        return
      }

      self.isKeyboardTransitioning = false
      if !self.isKeyboardVisible {
        self.resetKeyboardAffectedZoomState()
      }
    }

    keyboardTransitionWorkItem = workItem
    DispatchQueue.main.asyncAfter(
      deadline: .now() + duration + 0.12,
      execute: workItem
    )
  }

  private func completeDismissal() {
    guard !didFinish else {
      return
    }

    didFinish = true
    keyboardTransitionWorkItem?.cancel()
    keyboardTransitionWorkItem = nil
    restoreBackgroundZoom()

    let callbacks = dismissalCallbacks
    dismissalCallbacks.removeAll()
    let finished = { [weak self] in
      guard let self else {
        return
      }

      self.result(true)
      self.onFinish()
      callbacks.forEach { $0() }
      self.removeBackgroundInteractionBlocker()
      self.hostController = nil
    }

    if let hostController, hostController.presentingViewController != nil {
      hostController.dismiss(animated: false, completion: finished)
    } else {
      finished()
    }
  }

  #if DEBUG
  private func logZoomState(event: String) {
    AppleLiquidSheetPresenter.debugLog(
      "[mjn_liquid_ui][sheet-zoom] " +
        "event=\(event) " +
        "keyboardVisible=\(isKeyboardVisible) " +
        "keyboardTransitioning=\(isKeyboardTransitioning) " +
        "progress=\(format(dismissProgress))"
    )
  }

  private func format(_ value: CGFloat) -> String {
    String(format: "%.2f", value)
  }
  #else
  private func logZoomState(event: String) {}
  #endif
}

@available(iOS 16.0, *)
private final class AppleLiquidSheetPresentationState: ObservableObject {
  @Published var isPresented = false

  func present() {
    guard !isPresented else {
      return
    }

    isPresented = true
  }

  func dismiss() {
    guard isPresented else {
      return
    }

    isPresented = false
  }
}

@available(iOS 16.0, *)
private struct AppleLiquidSheetPresentationHost: View {
  let configuration: AppleLiquidSheetConfiguration
  @ObservedObject var presentationState: AppleLiquidSheetPresentationState
  let onFrameChange: (CGRect, CGRect) -> Void
  let onControlInteractionChanged: (Bool) -> Void
  let onDismiss: () -> Void

  var body: some View {
    AppleLiquidSheetTouchBlocker()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .ignoresSafeArea()
      .sheet(
        isPresented: $presentationState.isPresented,
        onDismiss: onDismiss
      ) {
        AppleLiquidSettingsSheetView(
          configuration: configuration,
          onFrameChange: onFrameChange,
          onControlInteractionChanged: onControlInteractionChanged
        )
      }
  }
}

@available(iOS 16.0, *)
private struct AppleLiquidSheetTouchBlocker: UIViewRepresentable {
  func makeUIView(context: Context) -> UIView {
    let view = UIView()
    view.backgroundColor = .clear
    view.isUserInteractionEnabled = true
    return view
  }

  func updateUIView(_ uiView: UIView, context: Context) {
    uiView.isUserInteractionEnabled = true
  }
}

@available(iOS 16.0, *)
private struct AppleLiquidSettingsSheetView: View {
  let configuration: AppleLiquidSheetConfiguration
  let onFrameChange: (CGRect, CGRect) -> Void
  let onControlInteractionChanged: (Bool) -> Void
  @Environment(\.dismiss) private var dismiss
  @State private var selectedDetent: PresentationDetent
  @State private var contentDetentHeight: CGFloat
  @State private var expandedDetentHeight: CGFloat?

  init(
    configuration: AppleLiquidSheetConfiguration,
    onFrameChange: @escaping (CGRect, CGRect) -> Void,
    onControlInteractionChanged: @escaping (Bool) -> Void
  ) {
    self.configuration = configuration
    self.onFrameChange = onFrameChange
    self.onControlInteractionChanged = onControlInteractionChanged

    let detentHeights = configuration.content.preferredDetentHeights
    self._selectedDetent = State(initialValue: .height(detentHeights.primary))
    self._contentDetentHeight = State(initialValue: detentHeights.primary)
    self._expandedDetentHeight = State(initialValue: detentHeights.expanded)
  }

  var body: some View {
    NavigationStack {
      AppleLiquidSheetFormScreen(
        content: configuration.content,
        showsDoneButton: true,
        onPreferredDetentHeightsChange: setPreferredDetentHeights,
        onControlInteractionChanged: onControlInteractionChanged,
        onDone: {
          dismiss()
        }
      )
    }
    .appleLiquidSheetBackground(
      configuration.resolvedSheetSwiftUIColor,
      isEnabled: configuration.sheetColor != nil
    )
    .appleLiquidColorScheme(configuration.resolvedSheetColorScheme)
    .presentationDetents(presentationDetents, selection: $selectedDetent)
    .presentationDragIndicator(.visible)
    .background(
      AppleLiquidSheetFrameObserver(onFrameChange: onFrameChange)
    )
  }

  private var contentDetent: PresentationDetent {
    .height(contentDetentHeight)
  }

  private var presentationDetents: Set<PresentationDetent> {
    var detents: Set<PresentationDetent> = [contentDetent]

    if let expandedDetentHeight {
      detents.insert(.height(expandedDetentHeight))
    }

    return detents
  }

  private func setPreferredDetentHeights(
    _ detentHeights: AppleLiquidSheetDetentHeights
  ) {
    let shouldUpdatePrimary = abs(
      contentDetentHeight - detentHeights.primary
    ) > 0.5
    let shouldUpdateExpanded = !Self.optionalCGFloat(
      expandedDetentHeight,
      equals: detentHeights.expanded
    )

    guard shouldUpdatePrimary || shouldUpdateExpanded else {
      return
    }

    contentDetentHeight = detentHeights.primary
    expandedDetentHeight = detentHeights.expanded
    selectedDetent = .height(detentHeights.primary)
  }

  private static func optionalCGFloat(
    _ lhs: CGFloat?,
    equals rhs: CGFloat?
  ) -> Bool {
    switch (lhs, rhs) {
    case (.none, .none):
      return true
    case let (.some(lhs), .some(rhs)):
      return abs(lhs - rhs) <= 0.5
    default:
      return false
    }
  }
}

@available(iOS 16.0, *)
private struct AppleLiquidSheetFormScreen: View {
  let content: AppleLiquidSheetContentConfiguration
  let showsDoneButton: Bool
  let onPreferredDetentHeightsChange: (AppleLiquidSheetDetentHeights) -> Void
  let onControlInteractionChanged: (Bool) -> Void
  let onDone: (() -> Void)?

  var body: some View {
    Form {
      ForEach(content.sections) { section in
        Section {
          ForEach(section.rows) { row in
            AppleLiquidSheetRowView(
              row: row,
              onPreferredDetentHeightsChange: onPreferredDetentHeightsChange,
              onControlInteractionChanged: onControlInteractionChanged
            )
          }
        } header: {
          if let title = section.title {
            Text(title)
          }
        }
      }
    }
    .navigationTitle(content.title)
    .toolbar {
      if showsDoneButton {
        ToolbarItem(placement: .confirmationAction) {
          Button {
            onDone?()
          } label: {
            Image(systemName: "checkmark")
          }
          .accessibilityLabel(content.doneAccessibilityLabel)
        }
      }
    }
    .scrollContentBackground(formBackgroundVisibility)
    .appleLiquidNavigationContainerBackground()
    .onAppear {
      onPreferredDetentHeightsChange(content.preferredDetentHeights)
    }
  }

  private var formBackgroundVisibility: Visibility {
    .hidden
  }
}

@available(iOS 16.0, *)
private struct AppleLiquidSheetRowView: View {
  let row: AppleLiquidSheetRowConfiguration
  let onPreferredDetentHeightsChange: (AppleLiquidSheetDetentHeights) -> Void
  let onControlInteractionChanged: (Bool) -> Void
  @State private var toggleValue: Bool
  @State private var pickerSelection: String
  @State private var sliderValue: Double
  @State private var textValue: String

  init(
    row: AppleLiquidSheetRowConfiguration,
    onPreferredDetentHeightsChange: @escaping (
      AppleLiquidSheetDetentHeights
    ) -> Void,
    onControlInteractionChanged: @escaping (Bool) -> Void
  ) {
    self.row = row
    self.onPreferredDetentHeightsChange = onPreferredDetentHeightsChange
    self.onControlInteractionChanged = onControlInteractionChanged
    self._toggleValue = State(initialValue: row.boolValue)
    self._pickerSelection = State(initialValue: row.resolvedSelectedOption)
    self._sliderValue = State(initialValue: row.sliderValue)
    self._textValue = State(initialValue: row.value ?? "")
  }

  @ViewBuilder
  var body: some View {
    switch row.kind {
    case .text:
      AppleLiquidSheetRowLabel(row: row)

    case .value:
      LabeledContent {
        Text(row.value ?? "")
      } label: {
        AppleLiquidSheetRowLabel(row: row)
      }

    case .toggle:
      Toggle(isOn: $toggleValue) {
        AppleLiquidSheetRowLabel(row: row)
      }

    case .picker:
      Picker(selection: $pickerSelection) {
        ForEach(row.options, id: \.self) { option in
          Text(option)
        }
      } label: {
        AppleLiquidSheetRowLabel(row: row)
      }
      .pickerStyle(.navigationLink)
      .scrollContentBackground(formBackgroundVisibility)
      .appleLiquidNavigationContainerBackground()

    case .segmented:
      VStack(alignment: .leading, spacing: row.segmentedStyle.contentSpacing) {
        AppleLiquidSheetRowLabel(
          row: row,
          titleFont: row.segmentedStyle.titleFont,
          subtitleFont: row.segmentedStyle.subtitleFont,
          titleColor: row.segmentedStyle.titleColor,
          subtitleColor: row.segmentedStyle.subtitleColor
        )

        HStack(spacing: row.segmentedStyle.buttonSpacing) {
          ForEach(row.options, id: \.self) { option in
            AppleLiquidSheetSegmentOptionButton(
              title: option,
              isSelected: pickerSelection == option,
              style: row.segmentedStyle,
              onSelect: {
                selectSegmentedOption(option)
              }
            )
          }
        }
      }
      .padding(.vertical, row.segmentedStyle.verticalPadding)

    case .slider:
      VStack(alignment: .leading, spacing: 8) {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
          AppleLiquidSheetRowLabel(row: row)

          Spacer(minLength: 12)

          Text(row.formattedSliderValue(sliderValue))
            .font(.footnote)
            .foregroundStyle(.secondary)
            .monospacedDigit()
        }

        AppleLiquidSheetSliderControl(
          row: row,
          value: $sliderValue,
          onInteractionChanged: onControlInteractionChanged
        )
      }
      .padding(.vertical, 4)

    case .navigation:
      if let content = row.content {
        NavigationLink {
          AppleLiquidSheetFormScreen(
            content: content,
            showsDoneButton: false,
            onPreferredDetentHeightsChange: onPreferredDetentHeightsChange,
            onControlInteractionChanged: onControlInteractionChanged,
            onDone: nil
          )
        } label: {
          AppleLiquidSheetRowLabel(row: row)
        }
      }

    case .textField:
      TextField(row.title, text: $textValue)
    }
  }

  private var formBackgroundVisibility: Visibility {
    .hidden
  }

  private func selectSegmentedOption(_ option: String) {
    guard pickerSelection != option else {
      return
    }

    if let animation = row.segmentedStyle.selectionAnimation {
      withAnimation(animation) {
        pickerSelection = option
      }
    } else {
      pickerSelection = option
    }
  }
}

@available(iOS 16.0, *)
private struct AppleLiquidSheetSegmentOptionButton: View {
  let title: String
  let isSelected: Bool
  let style: AppleLiquidSheetSegmentedStyleConfiguration
  let onSelect: () -> Void

  var body: some View {
    Button(action: onSelect) {
      ZStack {
        RoundedRectangle(
          cornerRadius: style.cornerRadius,
          style: .continuous
        )
        .fill(buttonBackground)
        .shadow(
          color: buttonShadowColor,
          radius: buttonShadowRadius,
          x: buttonShadowOffsetX,
          y: buttonShadowOffsetY
        )

        if style.borderWidth > 0 {
          RoundedRectangle(
            cornerRadius: style.cornerRadius,
            style: .continuous
          )
          .stroke(buttonBorder, lineWidth: style.borderWidth)
        }

        Text(title)
          .font(style.buttonFont)
          .foregroundStyle(buttonTextColor)
          .lineLimit(1)
          .minimumScaleFactor(style.minimumTextScaleFactor)
      }
      .frame(maxWidth: .infinity, minHeight: style.buttonHeight)
      .contentShape(
        RoundedRectangle(
          cornerRadius: style.cornerRadius,
          style: .continuous
        )
      )
      .animation(style.selectionAnimation, value: isSelected)
    }
    .buttonStyle(AppleLiquidSheetSegmentOptionButtonStyle(style: style))
    .accessibilityAddTraits(isSelected ? .isSelected : [])
  }

  private var buttonBackground: Color {
    if isSelected {
      return Color(appleLiquidARGB: style.selectedBackgroundARGB) ??
        Color.accentColor.opacity(0.16)
    }

    return Color(appleLiquidARGB: style.unselectedBackgroundARGB) ??
      Color.primary.opacity(0.07)
  }

  private var buttonTextColor: Color {
    if isSelected {
      return Color(appleLiquidARGB: style.selectedTextARGB) ?? .accentColor
    }

    return Color(appleLiquidARGB: style.unselectedTextARGB) ?? .primary
  }

  private var buttonBorder: Color {
    if isSelected {
      return Color(appleLiquidARGB: style.selectedBorderARGB) ??
        Color.accentColor.opacity(0.42)
    }

    return Color(appleLiquidARGB: style.unselectedBorderARGB) ??
      Color.primary.opacity(0.04)
  }

  private var buttonShadowColor: Color {
    guard isSelected, style.selectedShadowRadius > 0 else {
      return .clear
    }

    return Color(appleLiquidARGB: style.selectedShadowARGB) ??
      Color.white.opacity(0.04)
  }

  private var buttonShadowRadius: CGFloat {
    isSelected ? style.selectedShadowRadius : 0
  }

  private var buttonShadowOffsetX: CGFloat {
    isSelected ? style.selectedShadowOffsetX : 0
  }

  private var buttonShadowOffsetY: CGFloat {
    isSelected ? style.selectedShadowOffsetY : 0
  }
}

@available(iOS 16.0, *)
private struct AppleLiquidSheetSegmentOptionButtonStyle: ButtonStyle {
  let style: AppleLiquidSheetSegmentedStyleConfiguration

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .scaleEffect(configuration.isPressed ? style.pressedScale : 1)
      .opacity(configuration.isPressed ? style.pressedOpacity : 1)
      .animation(
        .easeOut(duration: style.pressAnimationDuration),
        value: configuration.isPressed
      )
  }
}

@available(iOS 16.0, *)
private struct AppleLiquidSheetSliderControl: UIViewRepresentable {
  let row: AppleLiquidSheetRowConfiguration
  @Binding var value: Double
  let onInteractionChanged: (Bool) -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(parent: self)
  }

  func makeUIView(context: Context) -> AppleLiquidSheetSliderUIKitView {
    let slider = AppleLiquidSheetSliderUIKitView()
    slider.isContinuous = true
    slider.addTarget(
      context.coordinator,
      action: #selector(Coordinator.valueChanged(_:)),
      for: .valueChanged
    )
    slider.addTarget(
      context.coordinator,
      action: #selector(Coordinator.touchDown(_:)),
      for: .touchDown
    )
    slider.addTarget(
      context.coordinator,
      action: #selector(Coordinator.touchEnded(_:)),
      for: [.touchUpInside, .touchUpOutside, .touchCancel]
    )
    configure(slider)
    return slider
  }

  func updateUIView(
    _ uiView: AppleLiquidSheetSliderUIKitView,
    context: Context
  ) {
    context.coordinator.parent = self
    configure(uiView)
  }

  private func configure(_ slider: UISlider) {
    slider.minimumValue = Float(row.sliderMin)
    slider.maximumValue = Float(row.sliderMax)

    let normalizedValue = row.normalizedSliderValue(value)
    if abs(Double(slider.value) - normalizedValue) > 0.0001 {
      slider.setValue(Float(normalizedValue), animated: false)
    }

    let tintColor = UIColor(appleLiquidARGB: row.tintColor)
    slider.tintColor = tintColor
    slider.minimumTrackTintColor = tintColor
    slider.thumbTintColor = tintColor
  }

  final class Coordinator: NSObject {
    var parent: AppleLiquidSheetSliderControl
    private var isInteracting = false

    init(parent: AppleLiquidSheetSliderControl) {
      self.parent = parent
    }

    @objc func valueChanged(_ sender: UISlider) {
      let normalizedValue = parent.row.normalizedSliderValue(
        Double(sender.value)
      )
      parent.value = normalizedValue
      sender.setValue(Float(normalizedValue), animated: false)
    }

    @objc func touchDown(_ sender: AppleLiquidSheetSliderUIKitView) {
      sender.lockAncestorPanGestures()
      setInteracting(true)
    }

    @objc func touchEnded(_ sender: AppleLiquidSheetSliderUIKitView) {
      valueChanged(sender)
      sender.unlockAncestorPanGestures()
      setInteracting(false)
    }

    private func setInteracting(_ isInteracting: Bool) {
      guard self.isInteracting != isInteracting else {
        return
      }

      self.isInteracting = isInteracting
      parent.onInteractionChanged(isInteracting)
    }
  }
}

private final class AppleLiquidSheetSliderUIKitView: UISlider {
  private var lockedPanGestureRecognizers: [UIPanGestureRecognizer] = []

  override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
    lockAncestorPanGestures()
    return super.beginTracking(touch, with: event)
  }

  override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
    super.endTracking(touch, with: event)
    unlockAncestorPanGestures()
  }

  override func cancelTracking(with event: UIEvent?) {
    super.cancelTracking(with: event)
    unlockAncestorPanGestures()
  }

  deinit {
    unlockAncestorPanGestures()
  }

  func lockAncestorPanGestures() {
    guard lockedPanGestureRecognizers.isEmpty else {
      return
    }

    var view = superview
    while let currentView = view {
      currentView.gestureRecognizers?.forEach { recognizer in
        guard let panGestureRecognizer = recognizer as? UIPanGestureRecognizer,
          panGestureRecognizer.isEnabled
        else {
          return
        }

        panGestureRecognizer.isEnabled = false
        lockedPanGestureRecognizers.append(panGestureRecognizer)
      }

      view = currentView.superview
    }
  }

  func unlockAncestorPanGestures() {
    lockedPanGestureRecognizers.forEach { recognizer in
      recognizer.isEnabled = true
    }
    lockedPanGestureRecognizers.removeAll()
  }
}

@available(iOS 16.0, *)
private struct AppleLiquidSheetRowLabel: View {
  let row: AppleLiquidSheetRowConfiguration
  let titleFont: Font?
  let subtitleFont: Font?
  let titleColor: Color?
  let subtitleColor: Color?

  init(
    row: AppleLiquidSheetRowConfiguration,
    titleFont: Font? = nil,
    subtitleFont: Font? = nil,
    titleColor: Color? = nil,
    subtitleColor: Color? = nil
  ) {
    self.row = row
    self.titleFont = titleFont
    self.subtitleFont = subtitleFont
    self.titleColor = titleColor
    self.subtitleColor = subtitleColor
  }

  var body: some View {
    if let subtitle = row.subtitle {
      VStack(alignment: .leading, spacing: 3) {
        title
        styledSubtitle(subtitle)
      }
    } else {
      title
    }
  }

  @ViewBuilder
  private var title: some View {
    if let systemImage = row.systemImage {
      styledTitle(Label(row.title, systemImage: systemImage))
    } else {
      styledTitle(Text(row.title))
    }
  }

  @ViewBuilder
  private func styledTitle<Content: View>(_ content: Content) -> some View {
    if let titleColor {
      content
        .font(titleFont)
        .foregroundStyle(titleColor)
    } else {
      content.font(titleFont)
    }
  }

  @ViewBuilder
  private func styledSubtitle(_ subtitle: String) -> some View {
    if let subtitleColor {
      Text(subtitle)
        .font(subtitleFont ?? .footnote)
        .foregroundStyle(subtitleColor)
    } else {
      Text(subtitle)
        .font(subtitleFont ?? .footnote)
        .foregroundStyle(.secondary)
    }
  }
}

@available(iOS 16.0, *)
private extension View {
  @ViewBuilder
  func appleLiquidSheetBackground(_ color: Color, isEnabled: Bool) -> some View {
    if isEnabled {
      let backgroundView = background(
        color.ignoresSafeArea(.container, edges: .bottom)
      )
        .ignoresSafeArea(.container, edges: .bottom)

      if #available(iOS 16.4, *) {
        backgroundView.presentationBackground(color)
      } else {
        backgroundView
      }
    } else {
      self
    }
  }

  @ViewBuilder
  func appleLiquidToolbarBackground(_ color: Color) -> some View {
    toolbarBackground(.hidden, for: .navigationBar)
      .toolbarBackground(color, for: .bottomBar)
      .toolbarBackground(.visible, for: .bottomBar)
  }

  @ViewBuilder
  func appleLiquidColorScheme(_ colorScheme: ColorScheme?) -> some View {
    if let colorScheme {
      environment(\.colorScheme, colorScheme)
    } else {
      self
    }
  }

  @ViewBuilder
  func appleLiquidSheetPreferredCornerRadius(_ radius: CGFloat) -> some View {
    if #available(iOS 16.4, *) {
      presentationCornerRadius(radius)
    } else {
      self
    }
  }

  @ViewBuilder
  func appleLiquidNavigationContainerBackground() -> some View {
    if #available(iOS 18.0, *) {
      containerBackground(.clear, for: .navigation)
    } else {
      self
    }
  }
}

@available(iOS 16.0, *)
private struct AppleLiquidSheetFrameObserver: UIViewRepresentable {
  let onFrameChange: (CGRect, CGRect) -> Void

  func makeUIView(context: Context) -> AppleLiquidSheetFrameObserverView {
    let view = AppleLiquidSheetFrameObserverView()
    view.onFrameChange = onFrameChange
    return view
  }

  func updateUIView(
    _ uiView: AppleLiquidSheetFrameObserverView,
    context: Context
  ) {
    uiView.onFrameChange = onFrameChange
  }
}

private final class AppleLiquidSheetFrameObserverView: UIView {
  var onFrameChange: ((CGRect, CGRect) -> Void)?

  private var displayLink: CADisplayLink?

  override func didMoveToWindow() {
    super.didMoveToWindow()

    if window == nil {
      stopTracking()
    } else {
      startTracking()
    }
  }

  deinit {
    stopTracking()
  }

  private func startTracking() {
    guard displayLink == nil else {
      return
    }

    let displayLink = CADisplayLink(target: self, selector: #selector(tick))
    displayLink.add(to: .main, forMode: .common)
    self.displayLink = displayLink
  }

  private func stopTracking() {
    displayLink?.invalidate()
    displayLink = nil
  }

  @objc private func tick() {
    guard let window else {
      return
    }

    onFrameChange?(observedSheetFrame(in: window), window.bounds)
  }

  private func observedSheetFrame(in window: UIWindow) -> CGRect {
    var view: UIView? = self
    var bestFrame: CGRect?
    let windowBounds = window.bounds

    while let currentView = view, currentView !== window {
      let frame = currentView.convert(currentView.bounds, to: window)
      let isSheetSized = frame.width >= windowBounds.width * 0.82 &&
        frame.height >= 120 &&
        frame.height < windowBounds.height * 0.98

      if isSheetSized &&
        (bestFrame == nil || frame.height > bestFrame!.height) {
        bestFrame = frame
      }

      view = currentView.superview
    }

    return bestFrame ?? convert(bounds, to: window)
  }
}
