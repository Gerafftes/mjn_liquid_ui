import Combine
import Flutter
import SwiftUI
import UIKit

enum AppleLiquidSheetPresenter {
  @available(iOS 16.0, *)
  private static var activeSession: AppleLiquidSheetSession?

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: AppleLiquidTabbarConstants.sheetChannelName,
      binaryMessenger: messenger
    )

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "showTemplateSheet":
        showTemplateSheet(
          arguments: call.arguments,
          channel: channel,
          result: result
        )

      case "dismissTemplateSheet":
        dismissTemplateSheet(result: result)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func showTemplateSheet(
    arguments: Any?,
    channel: FlutterMethodChannel,
    result: @escaping FlutterResult
  ) {
    guard #available(iOS 16.0, *) else {
      result(false)
      return
    }

    if let existingSession = activeSession {
      guard existingSession.isStale else {
        result(true)
        return
      }

      existingSession.discardStaleState()
      activeSession = nil
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
      onButtonAction: { actionId in
        channel.invokeMethod(
          "buttonPressed",
          arguments: ["actionId": actionId]
        )
      },
      onMultiSelectionAction: { actionId, selectedOptions in
        channel.invokeMethod(
          "multiSelectionChanged",
          arguments: [
            "actionId": actionId,
            "selectedOptions": selectedOptions
          ]
        )
      },
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
  static let navigationChromeHeight: CGFloat = 122
  static let nativeSectionTitleContentSpacing: CGFloat = 10
  static let nativeSectionTitleHorizontalInset: CGFloat = 16
  static let nativeFormRowHorizontalInset: CGFloat = 16

  private static var exactTitledSectionHeaderHeight: CGFloat {
    40 + (1 / max(UIScreen.main.scale, 1))
  }

  private static var exactCompactRowHeight: CGFloat {
    50 + (1 / max(UIScreen.main.scale, 1))
  }

  let title: String
  let doneAccessibilityLabel: String
  let leadingAction: AppleLiquidSheetToolbarActionConfiguration?
  let trailingAction: AppleLiquidSheetToolbarActionConfiguration
  let detents: AppleLiquidSheetDetentConfiguration
  let showsSectionBackgrounds: Bool
  let sectionSpacing: CGFloat?
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
    let leadingAction = AppleLiquidSheetToolbarActionConfiguration(
      value: dictionary["leadingAction"]
    )
    let trailingAction = AppleLiquidSheetToolbarActionConfiguration(
      value: dictionary["trailingAction"]
    ) ?? .defaultConfirmation(accessibilityLabel: doneAccessibilityLabel)
    let detents = AppleLiquidSheetDetentConfiguration(
      value: dictionary["detents"]
    )
    let showsSectionBackgrounds = Self.bool(
      dictionary["showsSectionBackgrounds"],
      defaultValue: true
    )
    let sectionSpacing = Self.optionalClampedCGFloat(
      dictionary["sectionSpacing"],
      minValue: 0,
      maxValue: 200
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
      leadingAction: leadingAction,
      trailingAction: trailingAction,
      detents: detents,
      showsSectionBackgrounds: showsSectionBackgrounds,
      sectionSpacing: sectionSpacing,
      sections: sections.isEmpty ? Self.defaultContent.sections : sections
    )
  }

  private init(
    title: String,
    doneAccessibilityLabel: String,
    leadingAction: AppleLiquidSheetToolbarActionConfiguration? = nil,
    trailingAction: AppleLiquidSheetToolbarActionConfiguration? = nil,
    detents: AppleLiquidSheetDetentConfiguration = .automatic,
    showsSectionBackgrounds: Bool = true,
    sectionSpacing: CGFloat? = nil,
    sections: [AppleLiquidSheetSectionConfiguration]
  ) {
    self.title = title
    self.doneAccessibilityLabel = doneAccessibilityLabel
    self.leadingAction = leadingAction
    self.trailingAction =
      trailingAction ??
      .defaultConfirmation(accessibilityLabel: doneAccessibilityLabel)
    self.detents = detents
    self.showsSectionBackgrounds = showsSectionBackgrounds
    self.sectionSpacing = sectionSpacing
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

  private static func bool(_ value: Any?, defaultValue: Bool) -> Bool {
    if let value = value as? Bool {
      return value
    }

    if let value = value as? NSNumber {
      return value.boolValue
    }

    return defaultValue
  }

  private static func optionalClampedCGFloat(
    _ value: Any?,
    minValue: Double,
    maxValue: Double
  ) -> CGFloat? {
    let doubleValue: Double?
    if let value = value as? Double {
      doubleValue = value
    } else if let value = value as? NSNumber {
      doubleValue = value.doubleValue
    } else {
      doubleValue = nil
    }

    guard let doubleValue else {
      return nil
    }

    return CGFloat(min(max(doubleValue, minValue), maxValue))
  }

  var estimatedDetentHeight: CGFloat {
    let formGroups = self.formGroups
    let sectionHeaderHeight: CGFloat
    let sectionSpacingHeight: CGFloat
    let rowHeight: CGFloat
    if #available(iOS 17.0, *), usesExactButtonSpacing {
      sectionHeaderHeight = formGroups.reduce(CGFloat.zero) { partial, group in
        partial + (
          group.title == nil
            ? 0
            : Self.exactTitledSectionHeaderHeight +
              group.sectionStyle.titleSpacingAdjustment
        )
      }
      sectionSpacingHeight = formGroups.indices.dropFirst().reduce(
        CGFloat.zero
      ) { partial, index in
        partial + resolvedSpacing(
          after: formGroups[index - 1],
          before: formGroups[index]
        )
      }
      rowHeight = formGroups.reduce(CGFloat.zero) { partial, group in
        partial + group.rows.reduce(CGFloat.zero) { rowPartial, row in
          let estimatedHeight = row.estimatedHeight
          let resolvedHeight = row.kind == .button
            ? estimatedHeight
            : max(estimatedHeight, Self.exactCompactRowHeight)
          return rowPartial + resolvedHeight
        }
      }
    } else {
      sectionHeaderHeight = formGroups.reduce(CGFloat.zero) { partial, group in
        partial + (
          group.title == nil
            ? 12
            : 34 + group.sectionStyle.titleSpacingAdjustment
        )
      }
      sectionSpacingHeight = CGFloat(max(formGroups.count - 1, 0)) *
        (sectionSpacing ?? 12)
      rowHeight = sections.reduce(CGFloat.zero) { partial, section in
        partial + section.estimatedHeight
      }
    }

    return Self.navigationChromeHeight + sectionHeaderHeight +
      sectionSpacingHeight + rowHeight
  }

  var formGroups: [AppleLiquidSheetFormGroup] {
    sections.flatMap(\.formGroups)
  }

  var usesExactButtonSpacing: Bool {
    formGroups.contains { group in
      group.startsWithButton || group.endsWithButton
    }
  }

  func resolvedSpacing(
    after previousGroup: AppleLiquidSheetFormGroup,
    before nextGroup: AppleLiquidSheetFormGroup
  ) -> CGFloat {
    if previousGroup.endsWithButton || nextGroup.startsWithButton {
      return 0
    }

    return sectionSpacing ?? 12
  }

  func spacingAfterGroup(at index: Int) -> CGFloat {
    guard formGroups.indices.contains(index), index + 1 < formGroups.count else {
      return 0
    }

    return resolvedSpacing(
      after: formGroups[index],
      before: formGroups[index + 1]
    )
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

private struct AppleLiquidSheetToolbarActionConfiguration {
  let title: String?
  let systemImage: String?
  let accessibilityLabel: String
  let foregroundARGB: Int?
  let backgroundARGB: Int?

  init?(value: Any?) {
    guard let dictionary = value as? [String: Any] else {
      return nil
    }

    let title = Self.nonEmptyString(dictionary["title"])
    let systemImage = Self.nonEmptyString(dictionary["systemImage"])

    guard title != nil || systemImage != nil else {
      return nil
    }

    self.title = title
    self.systemImage = systemImage
    self.accessibilityLabel =
      Self.nonEmptyString(dictionary["semanticLabel"]) ??
      title ??
      systemImage ??
      "Action"
    self.foregroundARGB = AppleLiquidTabbarConfiguration.intValue(
      dictionary["foregroundColor"]
    )
    self.backgroundARGB = AppleLiquidTabbarConfiguration.intValue(
      dictionary["backgroundColor"]
    )
  }

  private init(
    title: String?,
    systemImage: String?,
    accessibilityLabel: String,
    foregroundARGB: Int? = nil,
    backgroundARGB: Int? = nil
  ) {
    self.title = title
    self.systemImage = systemImage
    self.accessibilityLabel = accessibilityLabel
    self.foregroundARGB = foregroundARGB
    self.backgroundARGB = backgroundARGB
  }

  static func defaultConfirmation(
    accessibilityLabel: String
  ) -> AppleLiquidSheetToolbarActionConfiguration {
    AppleLiquidSheetToolbarActionConfiguration(
      title: nil,
      systemImage: "checkmark",
      accessibilityLabel: accessibilityLabel
    )
  }

  var foregroundColor: Color? {
    Color(appleLiquidARGB: foregroundARGB)
  }

  var backgroundColor: Color? {
    Color(appleLiquidARGB: backgroundARGB)
  }

  private static func nonEmptyString(_ value: Any?) -> String? {
    guard let string = value as? String,
      !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    else {
      return nil
    }

    return string
  }
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

private struct AppleLiquidSheetSectionStyleConfiguration {
  let titleARGB: Int?
  let titleHorizontalInset: CGFloat?
  let titleLeadingInset: CGFloat?
  let titleTrailingInset: CGFloat?
  let titleSpacing: CGFloat?
  let showsBackground: Bool?
  let backgroundARGB: Int?
  let borderARGB: Int?
  let cornerRadius: CGFloat?

  init(value: [String: Any]) {
    self.titleARGB = AppleLiquidTabbarConfiguration.intValue(
      value["titleColor"]
    )
    self.titleHorizontalInset = Self.optionalClampedCGFloat(
      value["titleHorizontalInset"],
      minValue: 0,
      maxValue: 200
    )
    self.titleLeadingInset = Self.optionalClampedCGFloat(
      value["titleLeadingInset"],
      minValue: 0,
      maxValue: 200
    )
    self.titleTrailingInset = Self.optionalClampedCGFloat(
      value["titleTrailingInset"],
      minValue: 0,
      maxValue: 200
    )
    self.titleSpacing = Self.optionalClampedCGFloat(
      value["titleSpacing"],
      minValue: 0,
      maxValue: 200
    )
    self.showsBackground = Self.optionalBool(value["showsBackground"])
    self.backgroundARGB = AppleLiquidTabbarConfiguration.intValue(
      value["backgroundColor"]
    )
    self.borderARGB = AppleLiquidTabbarConfiguration.intValue(
      value["borderColor"]
    )
    self.cornerRadius = Self.optionalClampedCGFloat(
      value["cornerRadius"],
      minValue: 0,
      maxValue: 80
    )
  }

  init(
    titleARGB: Int? = nil,
    titleHorizontalInset: CGFloat? = nil,
    titleLeadingInset: CGFloat? = nil,
    titleTrailingInset: CGFloat? = nil,
    titleSpacing: CGFloat? = nil,
    showsBackground: Bool? = nil,
    backgroundARGB: Int? = nil,
    borderARGB: Int? = nil,
    cornerRadius: CGFloat? = nil
  ) {
    self.titleARGB = titleARGB
    self.titleHorizontalInset = titleHorizontalInset
    self.titleLeadingInset = titleLeadingInset
    self.titleTrailingInset = titleTrailingInset
    self.titleSpacing = titleSpacing
    self.showsBackground = showsBackground
    self.backgroundARGB = backgroundARGB
    self.borderARGB = borderARGB
    self.cornerRadius = cornerRadius
  }

  var hasCustomAppearance: Bool {
    backgroundARGB != nil || borderARGB != nil || cornerRadius != nil
  }

  var titleSpacingAdjustment: CGFloat {
    guard let titleSpacing else {
      return 0
    }

    return titleSpacing -
      AppleLiquidSheetContentConfiguration.nativeSectionTitleContentSpacing
  }

  func resolvesBackgroundVisibility(defaultValue: Bool) -> Bool {
    showsBackground ?? defaultValue
  }

  private static func optionalBool(_ value: Any?) -> Bool? {
    if let value = value as? Bool {
      return value
    }

    if let value = value as? NSNumber {
      return value.boolValue
    }

    return nil
  }

  private static func optionalClampedCGFloat(
    _ value: Any?,
    minValue: Double,
    maxValue: Double
  ) -> CGFloat? {
    let doubleValue: Double?
    if let value = value as? Double {
      doubleValue = value
    } else if let value = value as? NSNumber {
      doubleValue = value.doubleValue
    } else {
      doubleValue = nil
    }

    guard let doubleValue else {
      return nil
    }

    return CGFloat(min(max(doubleValue, minValue), maxValue))
  }
}

private struct AppleLiquidSheetSectionConfiguration: Identifiable {
  let id: String
  let title: String?
  let style: AppleLiquidSheetSectionStyleConfiguration
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
      style: AppleLiquidSheetSectionStyleConfiguration(value: dictionary),
      rows: rows
    )
  }

  init(
    id: String,
    title: String?,
    style: AppleLiquidSheetSectionStyleConfiguration =
      AppleLiquidSheetSectionStyleConfiguration(),
    rows: [AppleLiquidSheetRowConfiguration]
  ) {
    self.id = id
    self.title = title
    self.style = style
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

  var formGroups: [AppleLiquidSheetFormGroup] {
    if style.hasCustomAppearance {
      return [
        AppleLiquidSheetFormGroup(
          id: "\(id)-group-0",
          title: title,
          sectionStyle: style,
          rows: rows
        )
      ]
    }

    var groups: [AppleLiquidSheetFormGroup] = []
    var standardRows: [AppleLiquidSheetRowConfiguration] = []

    func appendGroup(rows: [AppleLiquidSheetRowConfiguration]) {
      guard !rows.isEmpty else {
        return
      }

      groups.append(
        AppleLiquidSheetFormGroup(
          id: "\(id)-group-\(groups.count)",
          title: groups.isEmpty ? title : nil,
          sectionStyle: style,
          rows: rows
        )
      )
    }

    for row in rows {
      if row.kind == .button {
        appendGroup(rows: standardRows)
        standardRows.removeAll(keepingCapacity: true)
        appendGroup(rows: [row])
      } else {
        standardRows.append(row)
      }
    }

    appendGroup(rows: standardRows)
    return groups
  }
}

private struct AppleLiquidSheetFormGroup: Identifiable {
  let id: String
  let title: String?
  let sectionStyle: AppleLiquidSheetSectionStyleConfiguration
  let rows: [AppleLiquidSheetRowConfiguration]

  var startsWithButton: Bool {
    rows.first?.kind == .button
  }

  var endsWithButton: Bool {
    rows.last?.kind == .button
  }
}

private enum AppleLiquidSheetRowKind: String {
  case text
  case value
  case toggle
  case picker
  case multiPicker
  case segmented
  case button
  case slider
  case navigation
  case textField
}

private enum AppleLiquidSheetSliderValuePlacement: String {
  case topTrailing
  case besideTrack
}

private enum AppleLiquidSheetMultiPickerLabelPlacement: String {
  case trailing
  case primary
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
  let rowHorizontalInset: CGFloat?
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
    self.rowHorizontalInset = Self.optionalClampedCGFloat(
      dictionary["rowHorizontalInset"],
      minValue: 0,
      maxValue: 80
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

private enum AppleLiquidSheetButtonAlignment: String {
  case leading
  case center
  case trailing
}

private struct AppleLiquidSheetButtonStyleConfiguration {
  let backgroundARGB: Int?
  let foregroundARGB: Int?
  let borderARGB: Int?
  let subtitleARGB: Int?
  let buttonHeight: CGFloat
  let cornerRadius: CGFloat
  let borderWidth: CGFloat
  let backgroundOpacity: Double
  let horizontalPadding: CGFloat
  let iconSpacing: CGFloat
  let labelSpacing: CGFloat
  let rowHorizontalInset: CGFloat
  let rowVerticalInset: CGFloat
  let rowTopInset: CGFloat
  let rowBottomInset: CGFloat
  let titleFontSize: CGFloat?
  let subtitleFontSize: CGFloat?
  let iconSize: CGFloat?
  let titleFontWeight: Font.Weight
  let subtitleFontWeight: Font.Weight
  let alignment: AppleLiquidSheetButtonAlignment
  let minimumTextScaleFactor: CGFloat
  let pressedScale: CGFloat
  let pressedOpacity: Double
  let disabledOpacity: Double
  let pressAnimationDuration: Double
  let showsFormBackground: Bool
  let showsSeparator: Bool

  init(value: Any?) {
    let dictionary = value as? [String: Any] ?? [:]
    self.backgroundARGB = AppleLiquidTabbarConfiguration.intValue(
      dictionary["backgroundColor"]
    )
    self.foregroundARGB = AppleLiquidTabbarConfiguration.intValue(
      dictionary["foregroundColor"]
    )
    self.borderARGB = AppleLiquidTabbarConfiguration.intValue(
      dictionary["borderColor"]
    )
    self.subtitleARGB = AppleLiquidTabbarConfiguration.intValue(
      dictionary["subtitleColor"]
    )
    self.buttonHeight = Self.clampedCGFloat(
      dictionary["buttonHeight"],
      defaultValue: 48,
      minValue: 28,
      maxValue: 160
    )
    self.cornerRadius = Self.clampedCGFloat(
      dictionary["cornerRadius"],
      defaultValue: 12,
      minValue: 0,
      maxValue: 80
    )
    self.borderWidth = Self.clampedCGFloat(
      dictionary["borderWidth"],
      defaultValue: 1,
      minValue: 0,
      maxValue: 12
    )
    self.backgroundOpacity = Self.clampedDouble(
      dictionary["backgroundOpacity"],
      defaultValue: 0.08,
      minValue: 0,
      maxValue: 1
    )
    self.horizontalPadding = Self.clampedCGFloat(
      dictionary["horizontalPadding"],
      defaultValue: 16,
      minValue: 0,
      maxValue: 80
    )
    self.iconSpacing = Self.clampedCGFloat(
      dictionary["iconSpacing"],
      defaultValue: 8,
      minValue: 0,
      maxValue: 48
    )
    self.labelSpacing = Self.clampedCGFloat(
      dictionary["labelSpacing"],
      defaultValue: 2,
      minValue: 0,
      maxValue: 32
    )
    self.rowHorizontalInset = Self.clampedCGFloat(
      dictionary["rowHorizontalInset"],
      defaultValue: 16,
      minValue: 0,
      maxValue: 80
    )
    let rowVerticalInset = Self.clampedCGFloat(
      dictionary["rowVerticalInset"],
      defaultValue: 6,
      minValue: 0,
      maxValue: 48
    )
    self.rowVerticalInset = rowVerticalInset
    self.rowTopInset = Self.clampedCGFloat(
      dictionary["rowTopInset"],
      defaultValue: Double(rowVerticalInset),
      minValue: 0,
      maxValue: 48
    )
    self.rowBottomInset = Self.clampedCGFloat(
      dictionary["rowBottomInset"],
      defaultValue: Double(rowVerticalInset),
      minValue: 0,
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
    self.iconSize = Self.optionalClampedCGFloat(
      dictionary["iconSize"],
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
    self.alignment = AppleLiquidSheetButtonAlignment(
      rawValue: dictionary["alignment"] as? String ?? ""
    ) ?? .center
    self.minimumTextScaleFactor = Self.clampedCGFloat(
      dictionary["minimumTextScaleFactor"],
      defaultValue: 0.75,
      minValue: 0.1,
      maxValue: 1
    )
    self.pressedScale = Self.clampedCGFloat(
      dictionary["pressedScale"],
      defaultValue: 0.97,
      minValue: 0.8,
      maxValue: 1
    )
    self.pressedOpacity = Self.clampedDouble(
      dictionary["pressedOpacity"],
      defaultValue: 0.86,
      minValue: 0.1,
      maxValue: 1
    )
    self.disabledOpacity = Self.clampedDouble(
      dictionary["disabledOpacity"],
      defaultValue: 0.45,
      minValue: 0.1,
      maxValue: 1
    )
    self.pressAnimationDuration = Self.clampedDouble(
      dictionary["pressAnimationDuration"],
      defaultValue: 0.14,
      minValue: 0,
      maxValue: 1
    )
    self.showsFormBackground = Self.bool(
      dictionary["showsFormBackground"],
      defaultValue: false
    )
    self.showsSeparator = Self.bool(
      dictionary["showsSeparator"],
      defaultValue: false
    )
  }

  var titleFont: Font {
    resolvedFont(
      size: titleFontSize,
      defaultFont: .body,
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

  var frameAlignment: Alignment {
    switch alignment {
    case .leading:
      return .leading
    case .center:
      return .center
    case .trailing:
      return .trailing
    }
  }

  var estimatedHeight: CGFloat {
    buttonHeight + rowTopInset + rowBottomInset
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
  let selectedOptions: [String]
  let sliderValue: Double
  let valueSuffix: String?
  let sliderMin: Double
  let sliderMax: Double
  let sliderStep: Double?
  let sliderValuePlacement: AppleLiquidSheetSliderValuePlacement
  let rowHorizontalInset: CGFloat?
  let rowLeadingInset: CGFloat?
  let rowTrailingInset: CGFloat?
  let multiPickerLabelPlacement: AppleLiquidSheetMultiPickerLabelPlacement
  let multiPickerSelectionSystemImages: [String: String]
  let tintColor: Int?
  let content: AppleLiquidSheetContentConfiguration?
  let systemImage: String?
  let chevronARGB: Int?
  let segmentedStyle: AppleLiquidSheetSegmentedStyleConfiguration
  let buttonStyle: AppleLiquidSheetButtonStyleConfiguration
  let buttonActionId: String?
  let multiSelectionActionId: String?
  let buttonAccessibilityLabel: String
  let buttonDismissesSheet: Bool
  let buttonEnabled: Bool

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

    if (kind == .picker || kind == .multiPicker) && options.isEmpty {
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
    self.selectedOptions = Self.stringArray(dictionary["selectedOptions"])
      .filter(options.contains)
    self.sliderMin = sliderMin
    self.sliderMax = sliderMax
    self.sliderStep = sliderStep
    self.sliderValuePlacement = AppleLiquidSheetSliderValuePlacement(
      rawValue: Self.string(
        dictionary["sliderValuePlacement"],
        defaultValue: AppleLiquidSheetSliderValuePlacement.topTrailing.rawValue
      )
    ) ?? .topTrailing
    self.rowHorizontalInset = Self.optionalClampedCGFloat(
      dictionary["rowHorizontalInset"],
      minValue: 0,
      maxValue: 80
    )
    self.rowLeadingInset = Self.optionalClampedCGFloat(
      dictionary["rowLeadingInset"],
      minValue: 0,
      maxValue: 80
    )
    self.rowTrailingInset = Self.optionalClampedCGFloat(
      dictionary["rowTrailingInset"],
      minValue: 0,
      maxValue: 80
    )
    self.multiPickerLabelPlacement = AppleLiquidSheetMultiPickerLabelPlacement(
      rawValue: Self.string(
        dictionary["selectionLabelPlacement"],
        defaultValue: AppleLiquidSheetMultiPickerLabelPlacement.trailing.rawValue
      )
    ) ?? .trailing
    self.multiPickerSelectionSystemImages = Self.stringDictionary(
      dictionary["selectionSystemImages"]
    ).filter { options.contains($0.key) }
    self.sliderValue = Self.normalizedSliderValue(
      Self.optionalDouble(dictionary["sliderValue"]) ??
        Self.optionalDouble(dictionary["value"]) ??
        sliderMin,
      min: sliderMin,
      max: sliderMax,
      step: sliderStep
    )
    self.valueSuffix = Self.optionalString(dictionary["valueSuffix"])
    self.tintColor = AppleLiquidTabbarConfiguration.intValue(
      dictionary["tintColor"]
    )
    self.content = content
    self.systemImage = Self.optionalString(dictionary["systemImage"])
    self.chevronARGB = AppleLiquidTabbarConfiguration.intValue(
      dictionary["chevronColor"]
    )
    self.segmentedStyle = AppleLiquidSheetSegmentedStyleConfiguration(
      value: dictionary["segmentedStyle"]
    )
    self.buttonStyle = AppleLiquidSheetButtonStyleConfiguration(
      value: dictionary["buttonStyle"]
    )
    self.buttonActionId = Self.optionalString(dictionary["buttonActionId"])
    self.multiSelectionActionId = Self.optionalString(
      dictionary["multiSelectionActionId"]
    )
    self.buttonAccessibilityLabel = Self.string(
      dictionary["buttonSemanticLabel"],
      defaultValue: title
    )
    self.buttonDismissesSheet = Self.bool(
      dictionary["buttonDismissesSheet"],
      defaultValue: false
    )
    self.buttonEnabled = Self.bool(
      dictionary["buttonEnabled"],
      defaultValue: true
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
    selectedOptions: [String] = [],
    sliderValue: Double = 0,
    valueSuffix: String? = nil,
    sliderMin: Double = 0,
    sliderMax: Double = 1,
    sliderStep: Double? = nil,
    sliderValuePlacement: AppleLiquidSheetSliderValuePlacement = .topTrailing,
    rowHorizontalInset: CGFloat? = nil,
    rowLeadingInset: CGFloat? = nil,
    rowTrailingInset: CGFloat? = nil,
    multiPickerLabelPlacement: AppleLiquidSheetMultiPickerLabelPlacement =
      .trailing,
    multiPickerSelectionSystemImages: [String: String] = [:],
    tintColor: Int? = nil,
    content: AppleLiquidSheetContentConfiguration? = nil,
    systemImage: String? = nil,
    chevronARGB: Int? = nil,
    segmentedStyle: AppleLiquidSheetSegmentedStyleConfiguration =
      AppleLiquidSheetSegmentedStyleConfiguration(value: nil),
    buttonStyle: AppleLiquidSheetButtonStyleConfiguration =
      AppleLiquidSheetButtonStyleConfiguration(value: nil),
    buttonActionId: String? = nil,
    multiSelectionActionId: String? = nil,
    buttonAccessibilityLabel: String? = nil,
    buttonDismissesSheet: Bool = false,
    buttonEnabled: Bool = true
  ) {
    self.id = id
    self.kind = kind
    self.title = title
    self.subtitle = subtitle
    self.value = value
    self.boolValue = boolValue
    self.options = options
    self.selectedOption = selectedOption
    self.selectedOptions = selectedOptions
    self.sliderMin = sliderMin
    self.sliderMax = sliderMax
    self.sliderStep = sliderStep
    self.sliderValuePlacement = sliderValuePlacement
    self.rowHorizontalInset = rowHorizontalInset
    self.rowLeadingInset = rowLeadingInset
    self.rowTrailingInset = rowTrailingInset
    self.multiPickerLabelPlacement = multiPickerLabelPlacement
    self.multiPickerSelectionSystemImages = multiPickerSelectionSystemImages
    self.sliderValue = Self.normalizedSliderValue(
      sliderValue,
      min: sliderMin,
      max: sliderMax,
      step: sliderStep
    )
    self.valueSuffix = valueSuffix
    self.tintColor = tintColor
    self.content = content
    self.systemImage = systemImage
    self.chevronARGB = chevronARGB
    self.segmentedStyle = segmentedStyle
    self.buttonStyle = buttonStyle
    self.buttonActionId = buttonActionId
    self.multiSelectionActionId = multiSelectionActionId
    self.buttonAccessibilityLabel = buttonAccessibilityLabel ?? title
    self.buttonDismissesSheet = buttonDismissesSheet
    self.buttonEnabled = buttonEnabled
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
    chevronARGB: Int? = nil,
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
      chevronARGB: chevronARGB,
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
    valueSuffix: String? = nil,
    tintColor: Int? = nil,
    valuePlacement: AppleLiquidSheetSliderValuePlacement = .topTrailing,
    rowHorizontalInset: CGFloat? = nil,
    rowLeadingInset: CGFloat? = nil,
    rowTrailingInset: CGFloat? = nil,
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
      valueSuffix: valueSuffix,
      sliderMin: min,
      sliderMax: resolvedMax,
      sliderStep: resolvedStep,
      sliderValuePlacement: valuePlacement,
      rowHorizontalInset: rowHorizontalInset,
      rowLeadingInset: rowLeadingInset,
      rowTrailingInset: rowTrailingInset,
      tintColor: tintColor,
      systemImage: systemImage
    )
  }

  static func navigation(
    id: String,
    title: String,
    content: AppleLiquidSheetContentConfiguration,
    subtitle: String? = nil,
    systemImage: String? = nil,
    chevronARGB: Int? = nil
  ) -> AppleLiquidSheetRowConfiguration {
    AppleLiquidSheetRowConfiguration(
      id: id,
      kind: .navigation,
      title: title,
      subtitle: subtitle,
      content: content,
      systemImage: systemImage,
      chevronARGB: chevronARGB
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
    case .picker, .multiPicker:
      baseHeight = subtitle == nil ? 50 : 68
    case .segmented:
      baseHeight = segmentedStyle.estimatedHeight(hasSubtitle: subtitle != nil)
    case .button:
      baseHeight = buttonStyle.estimatedHeight
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

  private static func stringDictionary(_ value: Any?) -> [String: String] {
    guard let dictionary = value as? [String: Any] else {
      return [:]
    }

    return dictionary.reduce(into: [String: String]()) { result, entry in
      guard let string = entry.value as? String,
        !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      else {
        return
      }

      result[entry.key] = string
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

  private static func optionalClampedCGFloat(
    _ value: Any?,
    minValue: CGFloat,
    maxValue: CGFloat
  ) -> CGFloat? {
    guard let value = optionalDouble(value) else {
      return nil
    }

    return min(max(CGFloat(value), minValue), maxValue)
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
    let formattedValue: String

    if sliderMin == 0 && sliderMax == 1 {
      formattedValue = "\(Int((normalizedValue * 100).rounded()))%"
    } else {
      formattedValue = String(format: "%.2f", normalizedValue)
        .replacingOccurrences(of: ".00", with: "")
    }

    guard let valueSuffix else {
      return formattedValue
    }

    return "\(formattedValue) \(valueSuffix)"
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

@available(iOS 16.0, *)
private final class AppleLiquidSheetSession: NSObject,
  UIAdaptivePresentationControllerDelegate,
  UISheetPresentationControllerDelegate
{
  private let zoomedCornerRadius: CGFloat = 44
  private let configuration: AppleLiquidSheetConfiguration
  private weak var presentingView: UIView?
  private var hostController: UIViewController?
  private let result: FlutterResult
  private let onButtonAction: (String) -> Void
  private let onMultiSelectionAction: (String, [String]) -> Void
  private let onFinish: () -> Void
  private let originalTransform: CGAffineTransform
  private let originalCornerRadius: CGFloat
  private let originalMasksToBounds: Bool
  private let originalUserInteractionEnabled: Bool
  private var didApplyZoom = false
  private var didDisablePresentingViewInteraction = false
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
    onButtonAction: @escaping (String) -> Void,
    onMultiSelectionAction: @escaping (String, [String]) -> Void,
    onFinish: @escaping () -> Void
  ) {
    self.configuration = configuration
    self.presentingView = presentingView
    self.result = result
    self.onButtonAction = onButtonAction
    self.onMultiSelectionAction = onMultiSelectionAction
    self.onFinish = onFinish
    self.originalTransform = presentingView?.transform ?? .identity
    self.originalCornerRadius = presentingView?.layer.cornerRadius ?? 0
    self.originalMasksToBounds = presentingView?.layer.masksToBounds ?? false
    self.originalUserInteractionEnabled =
      presentingView?.isUserInteractionEnabled ?? true
    super.init()
    registerKeyboardNotifications()
  }

  deinit {
    keyboardTransitionWorkItem?.cancel()
    NotificationCenter.default.removeObserver(self)
    restorePresentingViewInteraction()
  }

  var isStale: Bool {
    !didFinish && hostController?.viewIfLoaded?.window == nil
  }

  func discardStaleState() {
    guard !didFinish else {
      return
    }

    didFinish = true
    restorePresentingViewInteraction()
  }

  func present(from presenter: UIViewController) -> Bool {
    guard presenter.viewIfLoaded?.window != nil else {
      return false
    }

    let hostView = AppleLiquidSettingsSheetView(
      configuration: configuration,
      onFrameChange: { [weak self] sheetFrame, windowBounds in
        self?.updateBackgroundZoom(
          sheetFrame: sheetFrame,
          windowBounds: windowBounds
        )
      },
      onControlInteractionChanged: { [weak self] isInteracting in
        self?.setControlInteractionActive(isInteracting)
      },
      onButtonAction: { [weak self] row in
        guard let self, let actionId = row.buttonActionId else {
          return
        }

        self.onButtonAction(actionId)
        if row.buttonDismissesSheet {
          self.dismissFromControl()
        }
      },
      onMultiSelectionAction: { [weak self] row, selectedOptions in
        guard let self, let actionId = row.multiSelectionActionId else {
          return
        }

        self.onMultiSelectionAction(actionId, selectedOptions)
      },
      onDismissRequest: { [weak self] in
        self?.dismissFromControl()
      }
    )

    let hostController = UIHostingController(rootView: hostView)
    hostController.view.backgroundColor = .clear
    hostController.modalPresentationStyle = .pageSheet
    hostController.presentationController?.delegate = self
    configureSheetPresentationController(for: hostController)
    self.hostController = hostController

    disablePresentingViewInteraction()
    presenter.present(hostController, animated: true)
    applyBackgroundZoom()

    return true
  }

  private func configureSheetPresentationController(
    for hostController: UIViewController
  ) {
    guard let sheetPresentationController =
      hostController.sheetPresentationController
    else {
      return
    }

    let detentHeights = configuration.content.preferredDetentHeights
    let primaryIdentifier = UISheetPresentationController.Detent.Identifier(
      "appleLiquidPrimary"
    )
    let expandedIdentifier = UISheetPresentationController.Detent.Identifier(
      "appleLiquidExpanded"
    )
    var detents: [UISheetPresentationController.Detent] = [
      .custom(identifier: primaryIdentifier) { _ in
        detentHeights.primary
      }
    ]

    if let expandedHeight = detentHeights.expanded {
      detents.append(
        .custom(identifier: expandedIdentifier) { _ in
          expandedHeight
        }
      )
    }

    sheetPresentationController.delegate = self
    sheetPresentationController.detents = detents
    sheetPresentationController.selectedDetentIdentifier = primaryIdentifier
    sheetPresentationController.largestUndimmedDetentIdentifier = nil
    sheetPresentationController.prefersGrabberVisible = true
    sheetPresentationController.prefersScrollingExpandsWhenScrolledToEdge = true
  }

  private func disablePresentingViewInteraction() {
    guard let presentingView, !didDisablePresentingViewInteraction else {
      return
    }

    didDisablePresentingViewInteraction = true
    presentingView.isUserInteractionEnabled = false
  }

  private func restorePresentingViewInteraction() {
    guard didDisablePresentingViewInteraction, let presentingView else {
      return
    }

    didDisablePresentingViewInteraction = false
    presentingView.isUserInteractionEnabled = originalUserInteractionEnabled
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

    if let hostController, hostController.presentingViewController != nil {
      hostController.dismiss(animated: true) { [weak self] in
        self?.completeDismissal()
      }
    } else {
      completeDismissal()
    }
  }

  func presentationControllerWillDismiss(
    _ presentationController: UIPresentationController
  ) {
    beginStationaryDismissAnimation()
  }

  func presentationControllerDidDismiss(
    _ presentationController: UIPresentationController
  ) {
    completeDismissal()
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
      },
      completion: nil
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
      },
      completion: nil
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
  }

  @objc private func keyboardWillHide(_ notification: Notification) {
    isKeyboardVisible = false
    lockKeyboardLayoutUpdates(using: notification)
  }

  @objc private func keyboardDidHide(_ notification: Notification) {
    isKeyboardVisible = false
    keyboardTransitionWorkItem?.cancel()
    keyboardTransitionWorkItem = nil
    isKeyboardTransitioning = false
    resetKeyboardAffectedZoomState()
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

      self.restorePresentingViewInteraction()
      self.result(true)
      self.onFinish()
      callbacks.forEach { $0() }
      self.hostController?.presentationController?.delegate = nil
      self.hostController = nil
    }

    finished()
  }

}

@available(iOS 16.0, *)
private struct AppleLiquidSettingsSheetView: View {
  let configuration: AppleLiquidSheetConfiguration
  let onFrameChange: (CGRect, CGRect) -> Void
  let onControlInteractionChanged: (Bool) -> Void
  let onButtonAction: (AppleLiquidSheetRowConfiguration) -> Void
  let onMultiSelectionAction: (AppleLiquidSheetRowConfiguration, [String]) -> Void
  let onDismissRequest: () -> Void
  @State private var selectedDetent: PresentationDetent
  @State private var contentDetentHeight: CGFloat
  @State private var expandedDetentHeight: CGFloat?

  init(
    configuration: AppleLiquidSheetConfiguration,
    onFrameChange: @escaping (CGRect, CGRect) -> Void,
    onControlInteractionChanged: @escaping (Bool) -> Void,
    onButtonAction: @escaping (AppleLiquidSheetRowConfiguration) -> Void,
    onMultiSelectionAction: @escaping (
      AppleLiquidSheetRowConfiguration,
      [String]
    ) -> Void,
    onDismissRequest: @escaping () -> Void
  ) {
    self.configuration = configuration
    self.onFrameChange = onFrameChange
    self.onControlInteractionChanged = onControlInteractionChanged
    self.onButtonAction = onButtonAction
    self.onMultiSelectionAction = onMultiSelectionAction
    self.onDismissRequest = onDismissRequest

    let detentHeights = configuration.content.preferredDetentHeights
    self._selectedDetent = State(initialValue: .height(detentHeights.primary))
    self._contentDetentHeight = State(initialValue: detentHeights.primary)
    self._expandedDetentHeight = State(initialValue: detentHeights.expanded)
  }

  var body: some View {
    NavigationStack {
      AppleLiquidSheetFormScreen(
        content: configuration.content,
        showsToolbarActions: true,
        onPreferredDetentHeightsChange: setPreferredDetentHeights,
        onControlInteractionChanged: onControlInteractionChanged,
        onButtonAction: onButtonAction,
        onMultiSelectionAction: onMultiSelectionAction,
        onToolbarAction: onDismissRequest
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
private struct AppleLiquidSheetToolbarButton: View {
  let action: AppleLiquidSheetToolbarActionConfiguration
  let onTap: () -> Void

  @ViewBuilder
  var body: some View {
    if let backgroundColor = action.backgroundColor {
      Button(action: onTap) {
        label
          .foregroundStyle(resolvedForegroundColor)
      }
      .buttonStyle(.borderedProminent)
      .buttonBorderShape(.capsule)
      .tint(backgroundColor)
      .accessibilityLabel(Text(action.accessibilityLabel))
    } else {
      Button(action: onTap) {
        label
          .foregroundStyle(resolvedForegroundColor)
      }
      .accessibilityLabel(Text(action.accessibilityLabel))
    }
  }

  @ViewBuilder
  private var label: some View {
    if let title = action.title, let systemImage = action.systemImage {
      Label(title, systemImage: systemImage)
    } else if let title = action.title {
      Text(title)
    } else if let systemImage = action.systemImage {
      Image(systemName: systemImage)
    }
  }

  private var resolvedForegroundColor: Color {
    if let foregroundColor = action.foregroundColor {
      return foregroundColor
    }

    if action.backgroundColor != nil {
      return .white
    }

    return .accentColor
  }
}

@available(iOS 16.0, *)
private struct AppleLiquidSheetFormScreen: View {
  let content: AppleLiquidSheetContentConfiguration
  let showsToolbarActions: Bool
  let onPreferredDetentHeightsChange: (AppleLiquidSheetDetentHeights) -> Void
  let onControlInteractionChanged: (Bool) -> Void
  let onButtonAction: (AppleLiquidSheetRowConfiguration) -> Void
  let onMultiSelectionAction: (AppleLiquidSheetRowConfiguration, [String]) -> Void
  let onToolbarAction: (() -> Void)?

  var body: some View {
    Form {
      ForEach(Array(formGroups.enumerated()), id: \.element.id) { index, group in
        Section {
          if group.sectionStyle.hasCustomAppearance &&
            group.sectionStyle.resolvesBackgroundVisibility(
              defaultValue: content.showsSectionBackgrounds
            )
          {
            AppleLiquidSheetStyledFormGroup(
              group: group,
              onPreferredDetentHeightsChange: onPreferredDetentHeightsChange,
              onControlInteractionChanged: onControlInteractionChanged,
              onButtonAction: onButtonAction,
              onMultiSelectionAction: onMultiSelectionAction
            )
          } else {
            ForEach(group.rows) { row in
              AppleLiquidSheetRowView(
                row: row,
                onPreferredDetentHeightsChange: onPreferredDetentHeightsChange,
                onControlInteractionChanged: onControlInteractionChanged,
                onButtonAction: onButtonAction,
                onMultiSelectionAction: onMultiSelectionAction
              )
              .appleLiquidSliderRowInsets(
                horizontal: row.kind == .slider
                  ? row.rowHorizontalInset
                  : nil,
                leading: row.kind == .slider ? row.rowLeadingInset : nil,
                trailing: row.kind == .slider ? row.rowTrailingInset : nil
              )
              .appleLiquidFormRowBackground(
                isVisible: group.sectionStyle.resolvesBackgroundVisibility(
                  defaultValue: content.showsSectionBackgrounds
                )
              )
            }
          }

          if #available(iOS 17.0, *), content.usesExactButtonSpacing {
            let spacingAfterCurrentGroup = content.spacingAfterGroup(at: index)
            if spacingAfterCurrentGroup > 0 {
              Color.clear
                .frame(height: spacingAfterCurrentGroup)
                .listRowInsets(EdgeInsets())
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .environment(\.defaultMinListRowHeight, 0)
            }
          }
        } header: {
          if let title = group.title {
            Group {
              if let titleColor = Color(
                appleLiquidARGB: group.sectionStyle.titleARGB
              ) {
                Text(title)
                  .foregroundStyle(titleColor)
              } else {
                Text(title)
              }
            }
            .appleLiquidSectionTitleInsets(
              horizontal: group.sectionStyle.titleHorizontalInset,
              leading: group.sectionStyle.titleLeadingInset,
              trailing: group.sectionStyle.titleTrailingInset
            )
            .appleLiquidSectionTitleSpacing(group.sectionStyle.titleSpacing)
          }
        }
      }
    }
    .appleLiquidListSectionSpacing(
      content.usesExactButtonSpacing ? 0 : content.sectionSpacing
    )
    .appleLiquidMinimumListRowHeight(
      content.usesExactButtonSpacing ? 0 : nil
    )
    .appleLiquidRemoveBottomContentMargin(
      formGroups.last?.endsWithButton == true
    )
    .navigationTitle(content.title)
    .toolbar {
      if showsToolbarActions {
        if let leadingAction = content.leadingAction {
          ToolbarItem(placement: .cancellationAction) {
            AppleLiquidSheetToolbarButton(
              action: leadingAction,
              onTap: {
                onToolbarAction?()
              }
            )
          }
        }

        ToolbarItem(placement: .confirmationAction) {
          AppleLiquidSheetToolbarButton(
            action: content.trailingAction,
            onTap: {
              onToolbarAction?()
            }
          )
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

  private var formGroups: [AppleLiquidSheetFormGroup] {
    content.formGroups
  }
}

#if DEBUG
@available(iOS 16.0, *)
struct AppleLiquidSheetLayoutTestSnapshot {
  let groupCount: Int
  let rowCounts: [Int]
  let chevronARGBValues: [Int]
  let spacingAfterGroups: [CGFloat]
  let lastButtonTopInset: CGFloat?
  let lastButtonBottomInset: CGFloat?
  let removesBottomContentMargin: Bool
  let estimatedDetentHeight: CGFloat
  let preferredDetentHeight: CGFloat
}

@available(iOS 16.0, *)
enum AppleLiquidSheetLayoutTestSupport {
  static func snapshot(contentValue: Any?) -> AppleLiquidSheetLayoutTestSnapshot {
    let content = AppleLiquidSheetContentConfiguration(value: contentValue)
    let groups = content.formGroups
    let spacingAfterGroups = groups.indices.map { index in
      content.spacingAfterGroup(at: index)
    }
    let rowCounts = groups.indices.map { index in
      groups[index].rows.count + (spacingAfterGroups[index] > 0 ? 1 : 0)
    }
    let lastButton = groups.last?.rows.last

    return AppleLiquidSheetLayoutTestSnapshot(
      groupCount: groups.count,
      rowCounts: rowCounts,
      chevronARGBValues: groups.flatMap { group in
        group.rows.compactMap(\.chevronARGB)
      },
      spacingAfterGroups: spacingAfterGroups,
      lastButtonTopInset: lastButton?.buttonStyle.rowTopInset,
      lastButtonBottomInset: lastButton?.buttonStyle.rowBottomInset,
      removesBottomContentMargin: groups.last?.endsWithButton == true,
      estimatedDetentHeight: content.estimatedDetentHeight,
      preferredDetentHeight: content.preferredDetentHeight
    )
  }

  @MainActor
  static func makePresentedSheet(contentValue: Any?) -> AnyView {
    let configuration = AppleLiquidSheetConfiguration(
      arguments: ["content": contentValue as Any]
    )

    return AnyView(
      AppleLiquidSheetLayoutTestHost(configuration: configuration)
    )
  }
}

@available(iOS 16.0, *)
private struct AppleLiquidSheetLayoutTestHost: View {
  let configuration: AppleLiquidSheetConfiguration
  @State private var isPresented = false

  var body: some View {
    Color.clear
      .onAppear {
        isPresented = true
      }
      .sheet(isPresented: $isPresented) {
        AppleLiquidSettingsSheetView(
          configuration: configuration,
          onFrameChange: { _, _ in },
          onControlInteractionChanged: { _ in },
          onButtonAction: { _ in },
          onMultiSelectionAction: { _, _ in },
          onDismissRequest: {}
        )
      }
  }
}
#endif

@available(iOS 16.0, *)
private struct AppleLiquidSheetRowView: View {
  let row: AppleLiquidSheetRowConfiguration
  let onPreferredDetentHeightsChange: (AppleLiquidSheetDetentHeights) -> Void
  let onControlInteractionChanged: (Bool) -> Void
  let onButtonAction: (AppleLiquidSheetRowConfiguration) -> Void
  let onMultiSelectionAction: (AppleLiquidSheetRowConfiguration, [String]) -> Void
  @State private var toggleValue: Bool
  @State private var pickerSelection: String
  @State private var multiPickerSelection: Set<String>
  @State private var sliderValue: Double
  @State private var textValue: String
  @State private var isCustomNavigationActive = false

  init(
    row: AppleLiquidSheetRowConfiguration,
    onPreferredDetentHeightsChange: @escaping (
      AppleLiquidSheetDetentHeights
    ) -> Void,
    onControlInteractionChanged: @escaping (Bool) -> Void,
    onButtonAction: @escaping (AppleLiquidSheetRowConfiguration) -> Void
    , onMultiSelectionAction: @escaping (
      AppleLiquidSheetRowConfiguration,
      [String]
    ) -> Void
  ) {
    self.row = row
    self.onPreferredDetentHeightsChange = onPreferredDetentHeightsChange
    self.onControlInteractionChanged = onControlInteractionChanged
    self.onButtonAction = onButtonAction
    self.onMultiSelectionAction = onMultiSelectionAction
    self._toggleValue = State(initialValue: row.boolValue)
    self._pickerSelection = State(initialValue: row.resolvedSelectedOption)
    self._multiPickerSelection = State(initialValue: Set(row.selectedOptions))
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
      if row.chevronARGB != nil {
        customChevronNavigationRow {
          pickerDestination
        } label: {
          HStack {
            AppleLiquidSheetRowLabel(row: row)
            Spacer()
            Text(pickerSelection)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }
      } else {
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
      }

    case .multiPicker:
      if row.chevronARGB != nil {
        customChevronNavigationRow {
          multiPickerDestination
        } label: {
          multiPickerRowLabel
        }
      } else {
        NavigationLink {
          multiPickerDestination
        } label: {
          multiPickerRowLabel
        }
      }

    case .segmented:
      segmentedRow

    case .button:
      AppleLiquidSheetActionButton(
        row: row,
        onTap: {
          onButtonAction(row)
        }
      )
      .listRowInsets(
        EdgeInsets(
          top: row.buttonStyle.rowTopInset,
          leading: row.buttonStyle.rowHorizontalInset,
          bottom: row.buttonStyle.rowBottomInset,
          trailing: row.buttonStyle.rowHorizontalInset
        )
      )
      .listRowSeparator(row.buttonStyle.showsSeparator ? .visible : .hidden)
      .appleLiquidFormRowBackground(
        isVisible: row.buttonStyle.showsFormBackground
      )

    case .slider:
      sliderRow

    case .navigation:
      if let content = row.content {
        if row.chevronARGB != nil {
          customChevronNavigationRow {
            navigationDestination(content: content)
          } label: {
            AppleLiquidSheetRowLabel(row: row)
          }
        } else {
          NavigationLink {
            navigationDestination(content: content)
          } label: {
            AppleLiquidSheetRowLabel(row: row)
          }
        }
      }

    case .textField:
      TextField(row.title, text: $textValue)
    }
  }

  private var formBackgroundVisibility: Visibility {
    .hidden
  }

  private var pickerDestination: some View {
    List {
      ForEach(row.options, id: \.self) { option in
        Button {
          pickerSelection = option
        } label: {
          HStack {
            Text(option)
              .foregroundStyle(.primary)
            Spacer()
            if pickerSelection == option {
              Image(systemName: "checkmark")
                .foregroundStyle(.tint)
            }
          }
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
    }
    .navigationTitle(row.title)
    .scrollContentBackground(formBackgroundVisibility)
    .appleLiquidNavigationContainerBackground()
  }

  private var multiPickerDestination: some View {
    List {
      ForEach(row.options, id: \.self) { option in
        Button {
          toggleMultiPickerOption(option)
        } label: {
          HStack {
            if let systemImage = row.multiPickerSelectionSystemImages[option] {
              Image(systemName: systemImage)
                .foregroundStyle(.tint)
                .frame(width: 22)
            }
            Text(option)
              .foregroundStyle(.primary)
            Spacer()
            if multiPickerSelection.contains(option) {
              Image(systemName: "checkmark")
                .foregroundStyle(.tint)
            }
          }
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
      }
    }
    .navigationTitle(row.title)
    .scrollContentBackground(formBackgroundVisibility)
    .appleLiquidNavigationContainerBackground()
  }

  @ViewBuilder
  private var multiPickerRowLabel: some View {
    switch row.multiPickerLabelPlacement {
    case .trailing:
      HStack {
        AppleLiquidSheetRowLabel(
          row: row,
          labelSystemImage: multiPickerSystemImage
        )
        Spacer()
        Text(multiPickerSummary)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
    case .primary:
      AppleLiquidSheetRowLabel(
        row: row,
        labelTitle: multiPickerSummary,
        labelSystemImage: multiPickerSystemImage
      )
    }
  }

  private func navigationDestination(
    content: AppleLiquidSheetContentConfiguration
  ) -> some View {
    AppleLiquidSheetFormScreen(
      content: content,
      showsToolbarActions: false,
      onPreferredDetentHeightsChange: onPreferredDetentHeightsChange,
      onControlInteractionChanged: onControlInteractionChanged,
      onButtonAction: onButtonAction,
      onMultiSelectionAction: onMultiSelectionAction,
      onToolbarAction: nil
    )
  }

  private func customChevronNavigationRow<Destination: View, Label: View>(
    @ViewBuilder destination: @escaping () -> Destination,
    @ViewBuilder label: () -> Label
  ) -> some View {
    Button {
      isCustomNavigationActive = true
    } label: {
      HStack(spacing: 8) {
        label()
          .frame(maxWidth: .infinity, alignment: .leading)

        Image(systemName: "chevron.forward")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(
            Color(appleLiquidARGB: row.chevronARGB) ?? .secondary
          )
          .accessibilityHidden(true)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .background {
      NavigationLink(
        destination: destination(),
        isActive: $isCustomNavigationActive
      ) {
        EmptyView()
      }
      .hidden()
    }
  }

  @ViewBuilder
  private var segmentedRow: some View {
    if let horizontalInset = row.segmentedStyle.rowHorizontalInset {
      segmentedRowContent
        .listRowInsets(
          EdgeInsets(
            top: row.segmentedStyle.verticalPadding,
            leading: horizontalInset,
            bottom: row.segmentedStyle.verticalPadding,
            trailing: horizontalInset
          )
        )
    } else {
      segmentedRowContent
        .padding(.vertical, row.segmentedStyle.verticalPadding)
    }
  }

  private var segmentedRowContent: some View {
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
  }

  @ViewBuilder
  private var sliderRow: some View {
    switch row.sliderValuePlacement {
    case .topTrailing:
      sliderRowWithTopTrailingValue
    case .besideTrack:
      sliderRowWithTrackTrailingValue
    }
  }

  private var sliderRowWithTopTrailingValue: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(alignment: .firstTextBaseline, spacing: 12) {
        AppleLiquidSheetRowLabel(row: row)

        Spacer(minLength: 12)

        sliderValueLabel
      }

      sliderControl
    }
    .padding(.vertical, 4)
  }

  private var sliderRowWithTrackTrailingValue: some View {
    VStack(alignment: .leading, spacing: 8) {
      AppleLiquidSheetRowLabel(row: row)

      HStack(alignment: .center, spacing: 12) {
        sliderControl

        sliderValueLabel
          .frame(minWidth: 44, alignment: .trailing)
      }
    }
    .padding(.vertical, 4)
  }

  private var sliderControl: some View {
    AppleLiquidSheetSliderControl(
      row: row,
      value: $sliderValue,
      onInteractionChanged: onControlInteractionChanged
    )
  }

  private var sliderValueLabel: some View {
    Text(row.formattedSliderValue(sliderValue))
      .font(.footnote)
      .foregroundStyle(.secondary)
      .monospacedDigit()
      .lineLimit(1)
      .fixedSize(horizontal: true, vertical: false)
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

  private var multiPickerSummary: String {
    if multiPickerSelection.isEmpty || multiPickerSelection.contains("Alle") {
      return "Alle"
    }

    if multiPickerSelection.count == 1 {
      return multiPickerSelection.first ?? "Alle"
    }

    return "\(multiPickerSelection.count) ausgewählt"
  }

  private var multiPickerSystemImage: String? {
    let selection: String?

    if multiPickerSelection.isEmpty || multiPickerSelection.contains("Alle") {
      selection = "Alle"
    } else if multiPickerSelection.count == 1 {
      selection = multiPickerSelection.first
    } else {
      selection = nil
    }

    guard let selection else {
      return row.systemImage
    }

    return row.multiPickerSelectionSystemImages[selection] ?? row.systemImage
  }

  private func toggleMultiPickerOption(_ option: String) {
    if option == "Alle" {
      multiPickerSelection = ["Alle"]
    } else {
      multiPickerSelection.remove("Alle")
      if multiPickerSelection.contains(option) {
        multiPickerSelection.remove(option)
      } else {
        multiPickerSelection.insert(option)
      }
      if multiPickerSelection.isEmpty {
        multiPickerSelection = ["Alle"]
      }
    }

    let orderedSelection = row.options.filter(multiPickerSelection.contains)
    onMultiSelectionAction(row, orderedSelection)
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
private struct AppleLiquidSheetActionButton: View {
  let row: AppleLiquidSheetRowConfiguration
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      HStack(spacing: style.iconSpacing) {
        if let systemImage = row.systemImage {
          Image(systemName: systemImage)
            .font(iconFont)
        }

        VStack(alignment: .leading, spacing: style.labelSpacing) {
          Text(row.title)
            .font(style.titleFont)
            .lineLimit(1)
            .minimumScaleFactor(style.minimumTextScaleFactor)

          if let subtitle = row.subtitle {
            Text(subtitle)
              .font(style.subtitleFont)
              .foregroundStyle(subtitleColor)
              .lineLimit(1)
              .minimumScaleFactor(style.minimumTextScaleFactor)
          }
        }
      }
      .frame(
        maxWidth: .infinity,
        minHeight: style.buttonHeight,
        alignment: style.frameAlignment
      )
      .padding(.horizontal, style.horizontalPadding)
      .foregroundStyle(foregroundColor)
      .background(
        RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
          .fill(backgroundColor)
      )
      .overlay(
        RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
          .strokeBorder(borderColor, lineWidth: style.borderWidth)
      )
      .contentShape(
        RoundedRectangle(cornerRadius: style.cornerRadius, style: .continuous)
      )
    }
    .buttonStyle(AppleLiquidSheetActionButtonStyle(style: style))
    .disabled(!isButtonEnabled)
    .opacity(isButtonEnabled ? 1 : style.disabledOpacity)
    .accessibilityLabel(row.buttonAccessibilityLabel)
  }

  private var style: AppleLiquidSheetButtonStyleConfiguration {
    row.buttonStyle
  }

  private var isButtonEnabled: Bool {
    row.buttonEnabled && row.buttonActionId != nil
  }

  private var tintColor: Color {
    Color(appleLiquidARGB: row.tintColor) ??
      Color(red: 0, green: 122 / 255, blue: 1)
  }

  private var backgroundColor: Color {
    Color(appleLiquidARGB: style.backgroundARGB) ??
      tintColor.opacity(style.backgroundOpacity)
  }

  private var foregroundColor: Color {
    Color(appleLiquidARGB: style.foregroundARGB) ?? .primary
  }

  private var borderColor: Color {
    Color(appleLiquidARGB: style.borderARGB) ?? tintColor
  }

  private var subtitleColor: Color {
    Color(appleLiquidARGB: style.subtitleARGB) ?? .secondary
  }

  private var iconFont: Font {
    if let iconSize = style.iconSize {
      return .system(size: iconSize, weight: style.titleFontWeight)
    }

    return style.titleFont
  }
}

@available(iOS 16.0, *)
private struct AppleLiquidSheetActionButtonStyle: ButtonStyle {
  let style: AppleLiquidSheetButtonStyleConfiguration

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
  let labelTitle: String
  let labelSystemImage: String?
  let titleFont: Font?
  let subtitleFont: Font?
  let titleColor: Color?
  let subtitleColor: Color?

  init(
    row: AppleLiquidSheetRowConfiguration,
    labelTitle: String? = nil,
    labelSystemImage: String? = nil,
    titleFont: Font? = nil,
    subtitleFont: Font? = nil,
    titleColor: Color? = nil,
    subtitleColor: Color? = nil
  ) {
    self.row = row
    self.labelTitle = labelTitle ?? row.title
    self.labelSystemImage = labelSystemImage ?? row.systemImage
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
    if let systemImage = labelSystemImage {
      styledTitle(Label(labelTitle, systemImage: systemImage))
    } else {
      styledTitle(Text(labelTitle))
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
private struct AppleLiquidSheetStyledFormGroup: View {
  let group: AppleLiquidSheetFormGroup
  let onPreferredDetentHeightsChange: (AppleLiquidSheetDetentHeights) -> Void
  let onControlInteractionChanged: (Bool) -> Void
  let onButtonAction: (AppleLiquidSheetRowConfiguration) -> Void
  let onMultiSelectionAction: (AppleLiquidSheetRowConfiguration, [String]) -> Void

  var body: some View {
    VStack(spacing: 0) {
      ForEach(group.rows) { row in
        AppleLiquidSheetRowView(
          row: row,
          onPreferredDetentHeightsChange: onPreferredDetentHeightsChange,
          onControlInteractionChanged: onControlInteractionChanged,
          onButtonAction: onButtonAction,
          onMultiSelectionAction: onMultiSelectionAction
        )
        .frame(maxWidth: .infinity, minHeight: minimumContentHeight(for: row))
        .padding(horizontalInsets(for: row))
        .padding(.top, topPadding(for: row))
        .padding(.bottom, bottomPadding(for: row))

        if row.id != group.rows.last?.id {
          Divider()
            .padding(.leading, 16)
        }
      }
    }
    .background(resolvedBackgroundColor, in: sectionShape)
    .clipShape(sectionShape)
    .overlay {
      if let borderColor = Color(appleLiquidARGB: group.sectionStyle.borderARGB) {
        sectionShape.strokeBorder(borderColor, lineWidth: 1)
      }
    }
    .listRowInsets(
      EdgeInsets(top: 8, leading: 8, bottom: 8, trailing: 8)
    )
    .listRowSeparator(.hidden)
    .listRowBackground(Color.clear)
  }

  private var resolvedBackgroundColor: Color {
    Color(appleLiquidARGB: group.sectionStyle.backgroundARGB) ??
      Color(uiColor: .secondarySystemGroupedBackground)
  }

  private var sectionShape: RoundedRectangle {
    RoundedRectangle(
      cornerRadius: group.sectionStyle.cornerRadius ?? 12,
      style: .continuous
    )
  }

  private func horizontalInsets(
    for row: AppleLiquidSheetRowConfiguration
  ) -> EdgeInsets {
    if row.kind == .segmented,
      let rowHorizontalInset = row.segmentedStyle.rowHorizontalInset
    {
      return EdgeInsets(
        top: 0,
        leading: rowHorizontalInset,
        bottom: 0,
        trailing: rowHorizontalInset
      )
    }

    if row.kind == .slider {
      let nativeInset =
        AppleLiquidSheetContentConfiguration.nativeFormRowHorizontalInset
      let leadingInset =
        row.rowLeadingInset ?? row.rowHorizontalInset ?? nativeInset
      let trailingInset =
        row.rowTrailingInset ?? row.rowHorizontalInset ?? nativeInset
      return EdgeInsets(
        top: 0,
        leading: leadingInset,
        bottom: 0,
        trailing: trailingInset
      )
    }

    let nativeInset =
      AppleLiquidSheetContentConfiguration.nativeFormRowHorizontalInset
    return EdgeInsets(
      top: 0,
      leading: nativeInset,
      bottom: 0,
      trailing: nativeInset
    )
  }

  private func minimumContentHeight(
    for row: AppleLiquidSheetRowConfiguration
  ) -> CGFloat {
    if row.kind == .button {
      return row.buttonStyle.buttonHeight
    }

    return row.estimatedHeight
  }

  private func topPadding(
    for row: AppleLiquidSheetRowConfiguration
  ) -> CGFloat {
    row.kind == .button ? row.buttonStyle.rowTopInset : 0
  }

  private func bottomPadding(
    for row: AppleLiquidSheetRowConfiguration
  ) -> CGFloat {
    row.kind == .button ? row.buttonStyle.rowBottomInset : 0
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

  @ViewBuilder
  func appleLiquidFormRowBackground(isVisible: Bool) -> some View {
    if isVisible {
      self
    } else {
      listRowBackground(Color.clear)
    }
  }

  @ViewBuilder
  func appleLiquidListSectionSpacing(_ spacing: CGFloat?) -> some View {
    if let spacing {
      if #available(iOS 17.0, *) {
        listSectionSpacing(spacing)
      } else {
        self
      }
    } else {
      self
    }
  }

  @ViewBuilder
  func appleLiquidMinimumListRowHeight(_ height: CGFloat?) -> some View {
    if let height {
      environment(\.defaultMinListRowHeight, height)
    } else {
      self
    }
  }

  @ViewBuilder
  func appleLiquidSectionTitleSpacing(_ spacing: CGFloat?) -> some View {
    if let spacing {
      padding(
        .bottom,
        spacing -
          AppleLiquidSheetContentConfiguration.nativeSectionTitleContentSpacing
      )
    } else {
      self
    }
  }

  @ViewBuilder
  func appleLiquidSectionTitleInsets(
    horizontal: CGFloat?,
    leading: CGFloat?,
    trailing: CGFloat?
  ) -> some View {
    if horizontal != nil || leading != nil || trailing != nil {
      let nativeInset =
        AppleLiquidSheetContentConfiguration.nativeSectionTitleHorizontalInset
      padding(
        EdgeInsets(
          top: 0,
          leading: (leading ?? horizontal ?? nativeInset) - nativeInset,
          bottom: 0,
          trailing: (trailing ?? horizontal ?? nativeInset) - nativeInset
        )
      )
    } else {
      self
    }
  }

  @ViewBuilder
  func appleLiquidSliderRowInsets(
    horizontal: CGFloat?,
    leading: CGFloat?,
    trailing: CGFloat?
  ) -> some View {
    if horizontal != nil || leading != nil || trailing != nil {
      let nativeInset =
        AppleLiquidSheetContentConfiguration.nativeFormRowHorizontalInset
      padding(
        EdgeInsets(
          top: 0,
          leading: (leading ?? horizontal ?? nativeInset) - nativeInset,
          bottom: 0,
          trailing: (trailing ?? horizontal ?? nativeInset) - nativeInset
        )
      )
    } else {
      self
    }
  }

  @ViewBuilder
  func appleLiquidRemoveBottomContentMargin(_ isEnabled: Bool) -> some View {
    if isEnabled {
      if #available(iOS 17.0, *) {
        contentMargins(.bottom, 0, for: .scrollContent)
      } else {
        self
      }
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
