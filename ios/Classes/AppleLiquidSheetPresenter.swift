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
      result(false)
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
      sections: sections.isEmpty ? Self.defaultContent.sections : sections
    )
  }

  private init(
    title: String,
    doneAccessibilityLabel: String,
    sections: [AppleLiquidSheetSectionConfiguration]
  ) {
    self.title = title
    self.doneAccessibilityLabel = doneAccessibilityLabel
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

  var preferredDetentHeight: CGFloat {
    let navigationChromeHeight: CGFloat = 92
    let sectionHeaderHeight = sections.reduce(CGFloat.zero) { partial, section in
      partial + (section.title == nil ? 12 : 34)
    }
    let sectionSpacing = CGFloat(max(sections.count - 1, 0)) * 12
    let rowHeight = sections.reduce(CGFloat.zero) { partial, section in
      partial + section.estimatedHeight
    }

    return Self.normalizedDetentHeight(
      navigationChromeHeight + sectionHeaderHeight + sectionSpacing + rowHeight
    )
  }

  static func normalizedDetentHeight(_ height: CGFloat) -> CGFloat {
    let screenHeight = UIScreen.main.bounds.height
    let screenBoundedMaximum = max(320, screenHeight * 0.82)
    let maximumHeight = min(700, screenBoundedMaximum)
    return min(max(height.rounded(.up), 240), maximumHeight)
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
  case navigation
  case textField
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
  let content: AppleLiquidSheetContentConfiguration?
  let systemImage: String?

  init?(value: Any?, id: String) {
    guard let dictionary = value as? [String: Any] else {
      return nil
    }

    let kind = AppleLiquidSheetRowKind(
      rawValue: Self.string(dictionary["type"], defaultValue: "text")
    ) ?? .text
    let title = Self.string(dictionary["title"], defaultValue: "Item")
    let options = Self.stringArray(dictionary["options"])

    if kind == .picker && options.isEmpty {
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
    self.content = content
    self.systemImage = Self.optionalString(dictionary["systemImage"])
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
    content: AppleLiquidSheetContentConfiguration? = nil,
    systemImage: String? = nil
  ) {
    self.id = id
    self.kind = kind
    self.title = title
    self.subtitle = subtitle
    self.value = value
    self.boolValue = boolValue
    self.options = options
    self.selectedOption = selectedOption
    self.content = content
    self.systemImage = systemImage
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
    systemImage: String? = nil
  ) -> AppleLiquidSheetRowConfiguration {
    AppleLiquidSheetRowConfiguration(
      id: id,
      kind: .picker,
      title: title,
      subtitle: subtitle,
      options: options,
      selectedOption: selectedOption,
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
private final class AppleLiquidSheetSession {
  private let zoomedCornerRadius: CGFloat = 44
  private let configuration: AppleLiquidSheetConfiguration
  private let presentationState = AppleLiquidSheetPresentationState()
  private weak var presentingView: UIView?
  private var hostController: UIViewController?
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
  }

  func present(from presenter: UIViewController) -> Bool {
    guard presenter.viewIfLoaded?.window != nil else {
      return false
    }

    let hostView = AppleLiquidSheetPresentationHost(
      configuration: configuration,
      presentationState: presentationState,
      onFrameChange: { [weak self] sheetFrame, windowBounds in
        self?.updateBackgroundZoom(
          sheetFrame: sheetFrame,
          windowBounds: windowBounds
        )
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
  let onDismiss: () -> Void

  var body: some View {
    Color.clear
      .ignoresSafeArea()
      .sheet(
        isPresented: $presentationState.isPresented,
        onDismiss: onDismiss
      ) {
        AppleLiquidSettingsSheetView(
          configuration: configuration,
          onFrameChange: onFrameChange
        )
      }
  }
}

@available(iOS 16.0, *)
private struct AppleLiquidSettingsSheetView: View {
  let configuration: AppleLiquidSheetConfiguration
  let onFrameChange: (CGRect, CGRect) -> Void
  @Environment(\.dismiss) private var dismiss
  @State private var selectedDetent: PresentationDetent
  @State private var contentDetentHeight: CGFloat

  init(
    configuration: AppleLiquidSheetConfiguration,
    onFrameChange: @escaping (CGRect, CGRect) -> Void
  ) {
    self.configuration = configuration
    self.onFrameChange = onFrameChange

    let detentHeight = configuration.content.preferredDetentHeight
    self._selectedDetent = State(initialValue: .height(detentHeight))
    self._contentDetentHeight = State(initialValue: detentHeight)
  }

  var body: some View {
    NavigationStack {
      AppleLiquidSheetFormScreen(
        content: configuration.content,
        showsDoneButton: true,
        onPreferredDetentHeightChange: setPreferredDetentHeight,
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
    .presentationDetents([contentDetent], selection: $selectedDetent)
    .presentationDragIndicator(.visible)
    .background(
      AppleLiquidSheetFrameObserver(onFrameChange: onFrameChange)
    )
  }

  private var contentDetent: PresentationDetent {
    .height(contentDetentHeight)
  }

  private func setPreferredDetentHeight(_ height: CGFloat) {
    let normalizedHeight = AppleLiquidSheetContentConfiguration
      .normalizedDetentHeight(height)

    guard abs(contentDetentHeight - normalizedHeight) > 0.5 else {
      return
    }

    contentDetentHeight = normalizedHeight
    selectedDetent = .height(normalizedHeight)
  }
}

@available(iOS 16.0, *)
private struct AppleLiquidSheetFormScreen: View {
  let content: AppleLiquidSheetContentConfiguration
  let showsDoneButton: Bool
  let onPreferredDetentHeightChange: (CGFloat) -> Void
  let onDone: (() -> Void)?

  var body: some View {
    Form {
      ForEach(content.sections) { section in
        Section {
          ForEach(section.rows) { row in
            AppleLiquidSheetRowView(
              row: row,
              onPreferredDetentHeightChange: onPreferredDetentHeightChange
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
      onPreferredDetentHeightChange(content.preferredDetentHeight)
    }
  }

  private var formBackgroundVisibility: Visibility {
    .hidden
  }
}

@available(iOS 16.0, *)
private struct AppleLiquidSheetRowView: View {
  let row: AppleLiquidSheetRowConfiguration
  let onPreferredDetentHeightChange: (CGFloat) -> Void
  @State private var toggleValue: Bool
  @State private var pickerSelection: String
  @State private var textValue: String

  init(
    row: AppleLiquidSheetRowConfiguration,
    onPreferredDetentHeightChange: @escaping (CGFloat) -> Void
  ) {
    self.row = row
    self.onPreferredDetentHeightChange = onPreferredDetentHeightChange
    self._toggleValue = State(initialValue: row.boolValue)
    self._pickerSelection = State(initialValue: row.resolvedSelectedOption)
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

    case .navigation:
      if let content = row.content {
        NavigationLink {
          AppleLiquidSheetFormScreen(
            content: content,
            showsDoneButton: false,
            onPreferredDetentHeightChange: onPreferredDetentHeightChange,
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
}

@available(iOS 16.0, *)
private struct AppleLiquidSheetRowLabel: View {
  let row: AppleLiquidSheetRowConfiguration

  var body: some View {
    if let subtitle = row.subtitle {
      VStack(alignment: .leading, spacing: 3) {
        title
        Text(subtitle)
          .font(.footnote)
          .foregroundStyle(.secondary)
      }
    } else {
      title
    }
  }

  @ViewBuilder
  private var title: some View {
    if let systemImage = row.systemImage {
      Label(row.title, systemImage: systemImage)
    } else {
      Text(row.title)
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
