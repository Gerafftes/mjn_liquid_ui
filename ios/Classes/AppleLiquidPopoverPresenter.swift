import Flutter
import SwiftUI
import UIKit

/// Validated channel input. Coordinates are logical Flutter-view coordinates.
struct AppleLiquidPopoverGeometry {
  let anchor: CGRect
  let viewSize: CGSize

  init?(arguments: [String: Any]) {
    guard let anchor = arguments["anchor"] as? [String: Any],
      let viewSize = arguments["viewSize"] as? [String: Any],
      let x = AppleLiquidPopoverConfiguration.number(anchor["x"]),
      let y = AppleLiquidPopoverConfiguration.number(anchor["y"]),
      let width = AppleLiquidPopoverConfiguration.positive(anchor["width"]),
      let height = AppleLiquidPopoverConfiguration.positive(anchor["height"]),
      let viewWidth = AppleLiquidPopoverConfiguration.positive(viewSize["width"]),
      let viewHeight = AppleLiquidPopoverConfiguration.positive(viewSize["height"])
    else { return nil }
    self.anchor = CGRect(x: x, y: y, width: width, height: height)
    self.viewSize = CGSize(width: viewWidth, height: viewHeight)
    guard self.anchor.maxX.isFinite, self.anchor.maxY.isFinite,
      self.anchor.intersects(CGRect(origin: .zero, size: self.viewSize))
    else { return nil }
  }

  func sourceRect(in bounds: CGRect) -> CGRect? {
    let scaleX = bounds.width / viewSize.width
    let scaleY = bounds.height / viewSize.height
    let rect = CGRect(
      x: bounds.minX + anchor.minX * scaleX,
      y: bounds.minY + anchor.minY * scaleY,
      width: anchor.width * scaleX,
      height: anchor.height * scaleY
    ).intersection(bounds)
    return rect.isNull || rect.isEmpty ? nil : rect
  }
}

struct AppleLiquidPopoverConfiguration {
  let sessionId: Int64
  let geometry: AppleLiquidPopoverGeometry
  let content: [String: Any]
  let width: CGFloat?
  let height: CGFloat?
  let minWidth: CGFloat
  let maxWidth: CGFloat?
  let minHeight: CGFloat
  let maxHeight: CGFloat?
  let arrowDirections: UIPopoverArrowDirection
  let layoutMargins: UIEdgeInsets
  let contentPadding: UIEdgeInsets
  let backgroundColor: UIColor?
  let tintColor: UIColor?
  let forcesPopover: Bool
  let dismissOnTapOutside: Bool
  let canOverlapSourceRect: Bool
  let showsToolbarActions: Bool
  let titleDisplayMode: NavigationBarItem.TitleDisplayMode
  let animated: Bool

  init?(arguments: Any?) {
    guard let arguments = arguments as? [String: Any],
      let sessionId = Self.sessionId(arguments),
      let geometry = AppleLiquidPopoverGeometry(arguments: arguments),
      let content = arguments["content"] as? [String: Any],
      content["sections"] is [Any],
      let options = arguments["options"] as? [String: Any]
    else { return nil }

    for key in ["width", "height", "minWidth", "maxWidth", "minHeight", "maxHeight"] {
      if let value = options[key], !(value is NSNull), Self.positive(value) == nil {
        return nil
      }
    }
    let minWidth = Self.positive(options["minWidth"]) ?? 1
    let minHeight = Self.positive(options["minHeight"]) ?? 1
    let maxWidth = Self.positive(options["maxWidth"])
    let maxHeight = Self.positive(options["maxHeight"])
    guard minWidth <= (maxWidth ?? .greatestFiniteMagnitude),
      minHeight <= (maxHeight ?? .greatestFiniteMagnitude),
      let margins = Self.insets(options["layoutMargins"], fallback: 10),
      let padding = Self.insets(options["contentPadding"], fallback: 0),
      let directions = options["arrowDirections"] as? [String],
      let compactBehavior = options["compactBehavior"] as? String,
      ["automatic", "popover"].contains(compactBehavior)
    else { return nil }
    var arrows: UIPopoverArrowDirection = []
    for direction in directions {
      switch direction {
      case "up": arrows.insert(.up)
      case "down": arrows.insert(.down)
      case "left": arrows.insert(.left)
      case "right": arrows.insert(.right)
      default: return nil
      }
    }
    for key in ["dismissOnTapOutside", "canOverlapSourceRect", "showsToolbarActions", "animated"] {
      if let value = options[key],
        AppleLiquidTabbarConfiguration.boolValue(value) == nil
      { return nil }
    }
    for key in ["backgroundColor", "tintColor"] {
      if let value = options[key], !(value is NSNull),
        AppleLiquidTabbarConfiguration.intValue(value) == nil
      { return nil }
    }
    let titleDisplayMode: NavigationBarItem.TitleDisplayMode
    switch options["titleDisplayMode"] as? String ?? "inline" {
    case "inline": titleDisplayMode = .inline
    case "large": titleDisplayMode = .large
    case "automatic": titleDisplayMode = .automatic
    default: return nil
    }

    self.sessionId = sessionId
    self.geometry = geometry
    self.content = content
    self.width = Self.positive(options["width"])
    self.height = Self.positive(options["height"])
    self.minWidth = minWidth
    self.maxWidth = maxWidth
    self.minHeight = minHeight
    self.maxHeight = maxHeight
    self.arrowDirections = arrows
    self.layoutMargins = margins
    self.contentPadding = padding
    self.backgroundColor = UIColor(
      appleLiquidARGB: AppleLiquidTabbarConfiguration.intValue(options["backgroundColor"])
    )
    self.tintColor = UIColor(
      appleLiquidARGB: AppleLiquidTabbarConfiguration.intValue(options["tintColor"])
    )
    self.forcesPopover = compactBehavior == "popover"
    self.dismissOnTapOutside =
      AppleLiquidTabbarConfiguration.boolValue(options["dismissOnTapOutside"]) ?? true
    self.canOverlapSourceRect =
      AppleLiquidTabbarConfiguration.boolValue(options["canOverlapSourceRect"]) ?? false
    self.showsToolbarActions =
      AppleLiquidTabbarConfiguration.boolValue(options["showsToolbarActions"]) ?? false
    self.titleDisplayMode = titleDisplayMode
    self.animated = AppleLiquidTabbarConfiguration.boolValue(options["animated"]) ?? true
  }

  static func number(_ raw: Any?) -> CGFloat? {
    guard let value = raw as? NSNumber,
      CFGetTypeID(value) != CFBooleanGetTypeID(), value.doubleValue.isFinite
    else { return nil }
    return CGFloat(value.doubleValue)
  }

  static func positive(_ raw: Any?) -> CGFloat? {
    guard let value = number(raw), value > 0 else { return nil }
    return value
  }

  static func sessionId(_ arguments: [String: Any]) -> Int64? {
    guard let raw = number(arguments["sessionId"]), raw >= 0,
      raw.rounded(.towardZero) == raw, raw < CGFloat(Int64.max)
    else { return nil }
    return Int64(raw)
  }

  private static func insets(_ raw: Any?, fallback: CGFloat) -> UIEdgeInsets? {
    guard let raw, !(raw is NSNull) else {
      return UIEdgeInsets(top: fallback, left: fallback, bottom: fallback, right: fallback)
    }
    guard let dictionary = raw as? [String: Any],
      let top = number(dictionary["top"]), top >= 0,
      let left = number(dictionary["left"]), left >= 0,
      let bottom = number(dictionary["bottom"]), bottom >= 0,
      let right = number(dictionary["right"]), right >= 0
    else { return nil }
    return UIEdgeInsets(top: top, left: left, bottom: bottom, right: right)
  }

  func preferredSize(available: CGSize, contentHeight: CGFloat) -> CGSize {
    let availableWidth = max(1, available.width - layoutMargins.left - layoutMargins.right)
    let availableHeight = max(1, available.height - layoutMargins.top - layoutMargins.bottom)
    let widthLimit = min(availableWidth, maxWidth ?? availableWidth)
    let heightLimit = min(availableHeight, maxHeight ?? availableHeight)
    // A preferred width is only a default; explicit sizes and bounds override it.
    return CGSize(
      width: min(widthLimit, max(minWidth, width ?? 320)),
      height: min(heightLimit, max(minHeight,
        height ?? (contentHeight + contentPadding.top + contentPadding.bottom)))
    )
  }
}

/// One presenter per engine; never selects another engine's key window.
final class AppleLiquidPopoverPresenter: NSObject, FlutterPlugin {
  private let channel: FlutterMethodChannel
  private let messenger: FlutterBinaryMessenger
  private let sourceProvider: (() -> UIViewController?)?
  // Stored properties cannot have narrower availability than their class.
  // Keep channel registration available on iOS 13; sessions require iOS 16.
  private var activeSessionStorage: AnyObject?
  @available(iOS 16.0, *)
  private var activeSession: AppleLiquidPopoverSession? {
    get { activeSessionStorage as? AppleLiquidPopoverSession }
    set { activeSessionStorage = newValue }
  }

  static func register(with registrar: FlutterPluginRegistrar) {
    let presenter = AppleLiquidPopoverPresenter(messenger: registrar.messenger())
    registrar.addMethodCallDelegate(presenter, channel: presenter.channel)
    registrar.publish(presenter)
  }

  init(messenger: FlutterBinaryMessenger, sourceProvider: (() -> UIViewController?)? = nil) {
    self.messenger = messenger
    self.channel = FlutterMethodChannel(
      name: AppleLiquidTabbarConstants.popoverChannelName, binaryMessenger: messenger
    )
    self.sourceProvider = sourceProvider
    super.init()
  }

  func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard #available(iOS 16.0, *) else {
      result(call.method == "showPopover" ? ["status": "notPresented"] : false)
      return
    }
    switch call.method {
    case "showPopover":
      guard let configuration = AppleLiquidPopoverConfiguration(arguments: call.arguments) else {
        result(FlutterError(code: "invalid_popover", message: "Invalid popover configuration.", details: nil))
        return
      }
      guard activeSession == nil else {
        result(["status": "alreadyShowing"])
        return
      }
      guard let source = sourceProvider?() ?? sourceViewController(),
        source.viewIfLoaded?.window != nil,
        source.presentedViewController == nil,
        !source.isBeingDismissed, !source.isBeingPresented
      else {
        result(["status": "notPresented"])
        return
      }
      let session = AppleLiquidPopoverSession(
        configuration: configuration, source: source, channel: channel, result: result,
        onFinish: { [weak self] in self?.activeSession = nil }
      )
      activeSession = session
      session.present()
    case "dismissPopover", "updateAnchor":
      guard let arguments = call.arguments as? [String: Any],
        let sessionId = AppleLiquidPopoverConfiguration.sessionId(arguments),
        let session = activeSession, session.sessionId == sessionId
      else { result(false); return }
      if call.method == "dismissPopover" {
        session.dismiss { result(true) }
      } else if let geometry = AppleLiquidPopoverGeometry(arguments: arguments) {
        result(session.updateAnchor(geometry))
      } else {
        session.dismiss()
        result(false)
      }
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  func detachFromEngine(for registrar: FlutterPluginRegistrar) {
    if #available(iOS 16.0, *) { activeSession?.dismiss(animated: false) }
    channel.setMethodCallHandler(nil)
  }

  static func isPopoverController(_ controller: UIViewController) -> Bool {
    guard #available(iOS 16.0, *) else { return false }
    var current: UIViewController? = controller
    while let candidate = current {
      if candidate is AppleLiquidPopoverHostingController { return true }
      current = candidate.presentingViewController
    }
    return false
  }

  private func sourceViewController() -> UIViewController? {
    func find(in controller: UIViewController) -> UIViewController? {
      if let flutter = controller as? FlutterViewController,
        flutter.binaryMessenger === messenger, flutter.viewIfLoaded?.window != nil
      { return flutter }
      for child in controller.children {
        if let found = find(in: child) { return found }
      }
      if let presented = controller.presentedViewController { return find(in: presented) }
      return nil
    }
    for scene in UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene })
    where scene.activationState == .foregroundActive {
      for window in scene.windows {
        if let root = window.rootViewController, let found = find(in: root) { return found }
      }
    }
    return nil
  }
}

@available(iOS 16.0, *)
private final class AppleLiquidPopoverHostingController: UIHostingController<AnyView> {
  var onDetached: (() -> Void)?
  var onLayout: (() -> Void)?

  override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    if presentingViewController == nil { onDetached?() }
  }

  override func viewDidLayoutSubviews() {
    super.viewDidLayoutSubviews()
    onLayout?()
  }
}

@available(iOS 16.0, *)
private final class AppleLiquidPopoverSession: NSObject, UIPopoverPresentationControllerDelegate {
  let configuration: AppleLiquidPopoverConfiguration
  var sessionId: Int64 { configuration.sessionId }
  private weak var source: UIViewController?
  private let channel: FlutterMethodChannel
  private let result: FlutterResult
  private let onFinish: () -> Void
  private var host: AppleLiquidPopoverHostingController?
  private var geometry: AppleLiquidPopoverGeometry
  private var contentHeight: CGFloat = 1
  private var textFieldValues: [String: String] = [:]
  private var dismissalStatus = "cancelled"
  private var toolbarActionId: String?
  private var isPresenting = false
  private var isDismissing = false
  private var didFinish = false
  private var pendingDismiss = false
  private var dismissalCallbacks: [() -> Void] = []

  init(configuration: AppleLiquidPopoverConfiguration, source: UIViewController,
    channel: FlutterMethodChannel, result: @escaping FlutterResult, onFinish: @escaping () -> Void
  ) {
    self.configuration = configuration
    self.geometry = configuration.geometry
    self.source = source
    self.channel = channel
    self.result = result
    self.onFinish = onFinish
    super.init()
  }

  func present() {
    guard let source, let sourceView = source.viewIfLoaded,
      let rect = geometry.sourceRect(in: sourceView.bounds)
    else { finish(status: "notPresented"); return }
    let content = AppleLiquidPopoverContentRenderer.makeView(
      content: configuration.content,
      showsToolbarActions: configuration.showsToolbarActions,
      titleDisplayMode: configuration.titleDisplayMode,
      onHeightChange: { [weak self] height in
        self?.contentHeight = height
        self?.updateSize()
      },
      onButtonAction: { [weak self] actionId, dismisses in
        guard let self, !self.didFinish, !self.isDismissing else { return }
        if let actionId { self.emit("buttonPressed", ["actionId": actionId]) }
        if dismisses { self.dismiss() }
      },
      onMultiSelectionAction: { [weak self] actionId, values in
        self?.emit("multiSelectionChanged", ["actionId": actionId, "selectedOptions": values])
      },
      onTextFieldChanged: { [weak self] actionId, value in
        guard let self, !self.didFinish else { return }
        self.textFieldValues[actionId] = value
        self.emit("textFieldChanged", ["actionId": actionId, "value": value])
      },
      onToolbarAction: { [weak self] status, actionId in
        guard let self, !self.didFinish, !self.isDismissing else { return }
        self.dismissalStatus = status
        self.toolbarActionId = actionId
        if let actionId {
          self.emit("toolbarActionPressed", ["actionId": actionId, "status": status])
        }
        self.dismiss()
      }
    )
    contentHeight = content.height
    let padding = configuration.contentPadding
    let paddedContent = AnyView(
      content.view.padding(EdgeInsets(
        top: padding.top, leading: padding.left, bottom: padding.bottom, trailing: padding.right
      ))
    )
    let rootView = configuration.tintColor.map { color in
      AnyView(paddedContent.tint(Color(uiColor: color)))
    } ?? paddedContent
    let host = AppleLiquidPopoverHostingController(rootView: rootView)
    self.host = host
    host.modalPresentationStyle = .popover
    host.isModalInPresentation = !configuration.dismissOnTapOutside
    host.view.backgroundColor = configuration.backgroundColor ?? .clear
    if let tint = configuration.tintColor { host.view.tintColor = tint }
    guard let popover = host.popoverPresentationController else {
      finish(status: "notPresented"); return
    }
    popover.sourceView = sourceView
    popover.sourceRect = rect
    popover.permittedArrowDirections = configuration.arrowDirections
    popover.popoverLayoutMargins = configuration.layoutMargins
    popover.canOverlapSourceViewRect = configuration.canOverlapSourceRect
    popover.backgroundColor = configuration.backgroundColor
    popover.delegate = self
    host.onDetached = { [weak self] in self?.finish() }
    host.onLayout = { [weak self] in self?.updateSize() }
    updateSize()
    isPresenting = true
    // Retain the session through the transition, including engine detachment.
    source.present(host, animated: configuration.animated) { [self] in
      guard !didFinish else { return }
      self.isPresenting = false
      if self.pendingDismiss { self.dismiss() }
    }
    if host.presentingViewController == nil {
      isPresenting = false
      finish(status: "notPresented")
    }
  }

  @discardableResult func updateAnchor(_ geometry: AppleLiquidPopoverGeometry) -> Bool {
    guard !didFinish, let sourceView = source?.viewIfLoaded,
      sourceView.window != nil, let rect = geometry.sourceRect(in: sourceView.bounds)
    else { dismiss(); return false }
    self.geometry = geometry
    host?.popoverPresentationController?.sourceRect = rect
    updateSize()
    return true
  }

  private func updateSize() {
    guard !didFinish, let host, let window = source?.viewIfLoaded?.window else { return }
    let scaledHeight = UIFontMetrics.default.scaledValue(for: contentHeight)
    let size = configuration.preferredSize(
      available: window.safeAreaLayoutGuide.layoutFrame.size, contentHeight: scaledHeight
    )
    if host.preferredContentSize != size { host.preferredContentSize = size }
  }

  func dismiss(animated: Bool? = nil, onDismissed: (() -> Void)? = nil) {
    guard !didFinish else { onDismissed?(); return }
    if let onDismissed { dismissalCallbacks.append(onDismissed) }
    if isPresenting { pendingDismiss = true; return }
    guard !isDismissing else { return }
    isDismissing = true
    guard let host, host.presentingViewController != nil else { finish(); return }
    host.dismiss(animated: animated ?? configuration.animated) { [self] in finish() }
  }

  func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
    configuration.dismissOnTapOutside
  }

  func popoverPresentationControllerShouldDismissPopover(
    _ popoverPresentationController: UIPopoverPresentationController
  ) -> Bool {
    configuration.dismissOnTapOutside
  }

  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) { finish() }

  func adaptivePresentationStyle(
    for controller: UIPresentationController, traitCollection: UITraitCollection
  ) -> UIModalPresentationStyle {
    configuration.forcesPopover ? .none : .automatic
  }

  func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
    configuration.forcesPopover ? .none : .automatic
  }

  func popoverPresentationController(_ popoverPresentationController: UIPopoverPresentationController,
    willRepositionPopoverTo rect: UnsafeMutablePointer<CGRect>, in view: AutoreleasingUnsafeMutablePointer<UIView>
  ) {
    guard let sourceView = source?.viewIfLoaded,
      let anchor = geometry.sourceRect(in: sourceView.bounds)
    else { return }
    rect.pointee = anchor
    view.pointee = sourceView
  }

  private func emit(_ method: String, _ arguments: [String: Any]) {
    guard !didFinish else { return }
    channel.invokeMethod(method, arguments: arguments)
  }

  private func finish(status: String? = nil) {
    guard !didFinish else { return }
    didFinish = true
    var response: [String: Any] = [
      "status": status ?? dismissalStatus, "textFieldValues": textFieldValues
    ]
    if let toolbarActionId { response["toolbarActionId"] = toolbarActionId }
    let callbacks = dismissalCallbacks
    dismissalCallbacks.removeAll()
    host?.onDetached = nil
    host?.onLayout = nil
    host?.presentationController?.delegate = nil
    host = nil
    onFinish()
    result(response)
    callbacks.forEach { $0() }
  }
}
