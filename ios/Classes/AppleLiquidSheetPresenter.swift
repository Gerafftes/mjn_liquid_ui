import Flutter
import SwiftUI
import UIKit

enum AppleLiquidSheetPresenter {
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

    guard let presenter = topViewController(from: activeRootViewController()) else {
      result(false)
      return
    }

    var sheetSession: AppleLiquidSheetSession?
    let configuration = AppleLiquidSheetConfiguration(arguments: arguments)
    let rootView = AppleLiquidTemplateSheetView(
      onFrameChange: { sheetFrame, windowBounds in
        sheetSession?.attachPresentationController()
        sheetSession?.updateBackgroundZoom(
          sheetFrame: sheetFrame,
          windowBounds: windowBounds
        )
      },
      onCancel: {
        sheetSession?.dismissFromControl()
      },
      onConfirm: {
        sheetSession?.dismissFromControl()
      }
    )

    let hostingController = UIHostingController(rootView: rootView)
    hostingController.modalPresentationStyle = .pageSheet

    if let sheetPresentationController = hostingController.sheetPresentationController {
      configuration.apply(to: sheetPresentationController)
    }

    let session = AppleLiquidSheetSession(
      hostingController: hostingController,
      presentingView: presenter.view,
      sheetConfiguration: configuration,
      backgroundZoomScale: configuration.backgroundZoomScale,
      result: result,
      onFinish: {
        activeSession = nil
      }
    )
    sheetSession = session
    activeSession = session

    session.attachPresentationController()
    session.applyBackgroundZoom()
    presenter.present(hostingController, animated: true) {
      if let sheetPresentationController = hostingController.sheetPresentationController {
        configuration.apply(to: sheetPresentationController)
      }

      session.attachPresentationController()
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
  let heightFraction: CGFloat
  let backgroundZoomScale: CGFloat
  let detentMode: AppleLiquidSheetDetentMode
  private let customDetentResolver: AppleLiquidSheetCustomDetentResolver?

  init(arguments: Any?) {
    let arguments = arguments as? [String: Any]
    let heightFraction = Self.clampedCGFloat(
      arguments?["heightFraction"],
      defaultValue: 1,
      minValue: 0.25,
      maxValue: 1
    )
    self.backgroundZoomScale = Self.clampedCGFloat(
      arguments?["backgroundZoomScale"],
      defaultValue: 1,
      minValue: 0.85,
      maxValue: 1
    )
    self.heightFraction = heightFraction
    self.detentMode = Self.detentMode(for: heightFraction)
    self.customDetentResolver = detentMode == .custom ?
      AppleLiquidSheetCustomDetentResolver(heightFraction: heightFraction)
      : nil
  }

  private static func detentMode(
    for heightFraction: CGFloat
  ) -> AppleLiquidSheetDetentMode {
    if heightFraction >= 0.995 {
      return .large
    }

    return .custom
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
}

private enum AppleLiquidSheetDetentMode: String {
  case medium
  case custom
  case large
}

private final class AppleLiquidSheetCustomDetentResolver {
  private let heightFraction: CGFloat
  private var resolvedHeight: CGFloat?

  init(heightFraction: CGFloat) {
    self.heightFraction = heightFraction
  }

  func resolve(maximumDetentValue: CGFloat) -> CGFloat {
    if let resolvedHeight {
      return resolvedHeight
    }

    let resolvedHeight = maximumDetentValue * heightFraction
    self.resolvedHeight = resolvedHeight
    return resolvedHeight
  }
}

private final class AppleLiquidSheetSession: NSObject {
  private let zoomedCornerRadius: CGFloat = 44
  private weak var hostingController: UIViewController?
  private weak var presentingView: UIView?
  private let sheetConfiguration: AppleLiquidSheetConfiguration
  private let backgroundZoomScale: CGFloat
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
  private var keyboardDetentRestoreWorkItem: DispatchWorkItem?

  init(
    hostingController: UIViewController,
    presentingView: UIView?,
    sheetConfiguration: AppleLiquidSheetConfiguration,
    backgroundZoomScale: CGFloat,
    result: @escaping FlutterResult,
    onFinish: @escaping () -> Void
  ) {
    self.hostingController = hostingController
    self.presentingView = presentingView
    self.sheetConfiguration = sheetConfiguration
    self.backgroundZoomScale = backgroundZoomScale
    self.result = result
    self.onFinish = onFinish
    self.originalTransform = presentingView?.transform ?? .identity
    self.originalCornerRadius = presentingView?.layer.cornerRadius ?? 0
    self.originalMasksToBounds = presentingView?.layer.masksToBounds ?? false
    super.init()
    registerKeyboardNotifications()
  }

  deinit {
    keyboardTransitionWorkItem?.cancel()
    keyboardDetentRestoreWorkItem?.cancel()
    NotificationCenter.default.removeObserver(self)
  }

  func applyBackgroundZoom() {
    guard backgroundZoomScale < 0.999, let presentingView else {
      return
    }

    didApplyZoom = true
    UIView.animate(
      withDuration: 0.28,
      delay: 0,
      options: [.curveEaseOut, .allowUserInteraction],
      animations: {
        presentingView.transform = CGAffineTransform(
          scaleX: self.backgroundZoomScale,
          y: self.backgroundZoomScale
        )
        presentingView.layer.cornerRadius = self.zoomedCornerRadius
        presentingView.layer.cornerCurve = .continuous
        presentingView.layer.masksToBounds = true
      }
    )
  }

  func updateBackgroundZoom(sheetFrame: CGRect, windowBounds: CGRect) {
    guard didApplyZoom,
      !didRestoreZoom,
      !didFinish,
      backgroundZoomScale < 0.999,
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

    let scale = backgroundZoomScale + (1 - backgroundZoomScale) * dragProgress

    CATransaction.begin()
    CATransaction.setDisableActions(true)
    presentingView.transform = CGAffineTransform(scaleX: scale, y: scale)
    presentingView.layer.cornerRadius = zoomedCornerRadius
    presentingView.layer.cornerCurve = .continuous
    presentingView.layer.masksToBounds = true
    CATransaction.commit()
  }

  func attachPresentationController() {
    if #available(iOS 15.0, *),
      let sheetPresentationController = hostingController?.sheetPresentationController {
      sheetPresentationController.delegate = self
    } else {
      hostingController?.presentationController?.delegate = self
    }
  }

  func dismissFromControl() {
    beginStationaryDismissAnimation(isGestureDriven: false)
    hostingController?.dismiss(animated: true) { [weak self] in
      self?.completeDismissal()
    }
  }

  private func beginStationaryDismissAnimation(isGestureDriven: Bool) {
    guard !isGestureDriven, dismissProgress <= 0.02 else {
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
      scaleX: backgroundZoomScale,
      y: backgroundZoomScale
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
    attachPresentationController()
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
    expandCustomDetentForKeyboard(event: "keyboardWillShow")
    resetKeyboardAffectedZoomState()
    logDetentState(event: "keyboardWillShow")
  }

  @objc private func keyboardWillHide(_ notification: Notification) {
    isKeyboardVisible = false
    lockKeyboardLayoutUpdates(using: notification)
    expandCustomDetentForKeyboard(event: "keyboardWillHide")
    logDetentState(event: "keyboardWillHide")
  }

  @objc private func keyboardDidHide(_ notification: Notification) {
    isKeyboardVisible = false
    keyboardTransitionWorkItem?.cancel()
    keyboardTransitionWorkItem = nil

    if restoreCustomDetentAfterKeyboard() {
      logDetentState(event: "keyboardDidHideRestoreCustom")
      return
    }

    isKeyboardTransitioning = false
    resetKeyboardAffectedZoomState()
    logDetentState(event: "keyboardDidHide")
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

      if self.keyboardDetentRestoreWorkItem != nil {
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

  private func expandCustomDetentForKeyboard(event: String) {
    guard #available(iOS 16.0, *),
      sheetConfiguration.detentMode == .custom,
      let sheetPresentationController = hostingController?.sheetPresentationController
    else {
      return
    }

    keyboardDetentRestoreWorkItem?.cancel()
    keyboardDetentRestoreWorkItem = nil
    sheetPresentationController.animateChanges {
      sheetConfiguration.applyKeyboardDetents(to: sheetPresentationController)
    }
    logDetentState(event: "\(event)ExpandLarge")
  }

  private func restoreCustomDetentAfterKeyboard() -> Bool {
    guard #available(iOS 16.0, *),
      sheetConfiguration.detentMode == .custom,
      let sheetPresentationController = hostingController?.sheetPresentationController
    else {
      return false
    }

    keyboardDetentRestoreWorkItem?.cancel()
    isKeyboardTransitioning = true
    resetKeyboardAffectedZoomState()

    sheetPresentationController.animateChanges {
      sheetConfiguration.selectRestingDetent(on: sheetPresentationController)
    }

    let workItem = DispatchWorkItem { [weak self] in
      guard let self, !self.didFinish else {
        return
      }

      if #available(iOS 16.0, *) {
        self.sheetConfiguration.apply(to: sheetPresentationController)
      }
      self.isKeyboardTransitioning = false
      self.keyboardDetentRestoreWorkItem = nil
      self.resetKeyboardAffectedZoomState()
      self.logDetentState(event: "keyboardDetentRestoreFinished")
    }

    keyboardDetentRestoreWorkItem = workItem
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.42, execute: workItem)
    return true
  }

  private func completeDismissal() {
    guard !didFinish else {
      return
    }

    didFinish = true
    keyboardDetentRestoreWorkItem?.cancel()
    keyboardDetentRestoreWorkItem = nil
    restoreBackgroundZoom()
    result(true)
    onFinish()
  }

  #if DEBUG
  private func logDetentState(event: String) {
    guard #available(iOS 15.0, *),
      let sheetPresentationController = hostingController?.sheetPresentationController
    else {
      return
    }

    let selectedDetent = sheetPresentationController.selectedDetentIdentifier
      .map { String(describing: $0) } ?? "nil"
    let frame = sheetFrame()
    let frameDescription = frame.map {
      "sheetY=\(format($0.minY)) sheetH=\(format($0.height))"
    } ?? "sheetY=nil sheetH=nil"

    AppleLiquidSheetPresenter.debugLog(
      "[mjn_liquid_ui][sheet-detent] " +
        "event=\(event) " +
        "mode=\(sheetConfiguration.detentMode.rawValue) " +
        "selected=\(selectedDetent) " +
        frameDescription
    )
  }

  private func sheetFrame() -> CGRect? {
    guard let view = hostingController?.view, let window = view.window else {
      return nil
    }

    return view.convert(view.bounds, to: window)
  }

  private func format(_ value: CGFloat) -> String {
    String(format: "%.1f", value)
  }
  #else
  private func logDetentState(event: String) {}
  #endif
}

@available(iOS 15.0, *)
extension AppleLiquidSheetSession: UISheetPresentationControllerDelegate {
  func presentationControllerWillDismiss(
    _ presentationController: UIPresentationController
  ) {
    beginStationaryDismissAnimation(
      isGestureDriven: presentationController.isGestureDrivenDismissal
    )
  }

  func presentationControllerDidDismiss(
    _ presentationController: UIPresentationController
  ) {
    completeDismissal()
  }

  func sheetPresentationControllerDidChangeSelectedDetentIdentifier(
    _ sheetPresentationController: UISheetPresentationController
  ) {
    logDetentState(event: "selectedDetentDidChange")
  }
}

@available(iOS 16.0, *)
private struct AppleLiquidTemplateSheetView: View {
  let onFrameChange: (CGRect, CGRect) -> Void
  let onCancel: () -> Void
  let onConfirm: () -> Void
  @State private var searchText = ""

  var body: some View {
    NavigationStack {
      AppleLiquidTemplatePickerContent(searchText: searchText)
        .navigationTitle("Templates")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
          AppleLiquidCancelButton(action: onCancel)
          AppleLiquidConfirmButton(action: onConfirm)

          if #available(iOS 26.0, *) {
            DefaultToolbarItem(kind: .search, placement: .bottomBar)
          }
        }
    }
    .searchable(text: $searchText, prompt: "Search templates")
    .background(
      AppleLiquidSheetFrameObserver(onFrameChange: onFrameChange)
    )
    #if DEBUG
    .background(AppleLiquidSearchFrameDebugObserver())
    #endif
  }
}

private extension UIView {
  var hasActivePanGesture: Bool {
    let hasActiveGesture = gestureRecognizers?.contains { gestureRecognizer in
      guard gestureRecognizer is UIPanGestureRecognizer else {
        return false
      }

      return gestureRecognizer.state == .began ||
        gestureRecognizer.state == .changed ||
        gestureRecognizer.state == .ended
    } ?? false

    return hasActiveGesture || subviews.contains { $0.hasActivePanGesture }
  }
}

private extension UIPresentationController {
  var isGestureDrivenDismissal: Bool {
    if presentedViewController.transitionCoordinator?.isInteractive == true {
      return true
    }

    return presentedView?.hasActivePanGesture == true ||
      containerView?.hasActivePanGesture == true
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

#if DEBUG
@available(iOS 16.0, *)
private struct AppleLiquidSearchFrameDebugObserver: UIViewRepresentable {
  func makeUIView(context: Context) -> AppleLiquidSearchFrameDebugObserverView {
    AppleLiquidSearchFrameDebugObserverView()
  }

  func updateUIView(
    _ uiView: AppleLiquidSearchFrameDebugObserverView,
    context: Context
  ) {}
}

private final class AppleLiquidSearchFrameDebugObserverView: UIView {
  private var displayLink: CADisplayLink?
  private var keyboardPhase = "idle"
  private var keyboardY: CGFloat = 0
  private var keyboardHeight: CGFloat = 0
  private var keyboardDuration: Double = 0
  private var lastFrame: CGRect?
  private var lastClassName: String?
  private var didLogMissingSearchView = false

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
    NotificationCenter.default.removeObserver(self)
  }

  private func startTracking() {
    guard displayLink == nil else {
      return
    }

    registerKeyboardNotifications()

    let displayLink = CADisplayLink(
      target: self,
      selector: #selector(tick)
    )
    displayLink.add(to: .main, forMode: .common)
    self.displayLink = displayLink
  }

  private func stopTracking() {
    displayLink?.invalidate()
    displayLink = nil
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
      selector: #selector(keyboardDidShow),
      name: UIResponder.keyboardDidShowNotification,
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
    keyboardPhase = "willShow"
    logKeyboardEvent("keyboardWillShow", notification: notification)
  }

  @objc private func keyboardDidShow(_ notification: Notification) {
    keyboardPhase = "visible"
    logKeyboardEvent("keyboardDidShow", notification: notification)
  }

  @objc private func keyboardWillHide(_ notification: Notification) {
    keyboardPhase = "willHide"
    logKeyboardEvent("keyboardWillHide", notification: notification)
  }

  @objc private func keyboardDidHide(_ notification: Notification) {
    keyboardPhase = "hidden"
    logKeyboardEvent("keyboardDidHide", notification: notification)
  }

  @objc private func tick() {
    guard let window else {
      return
    }

    guard let searchView = primarySearchView(in: window) else {
      if !didLogMissingSearchView {
        AppleLiquidSheetPresenter.debugLog(
          "[mjn_liquid_ui][search-frame] missing phase=\(keyboardPhase)"
        )
        didLogMissingSearchView = true
      }
      return
    }

    didLogMissingSearchView = false

    let frame = searchView.convert(searchView.bounds, to: window)
    let className = String(describing: type(of: searchView))

    guard shouldLog(frame: frame, className: className) else {
      return
    }

    let sheetFrame = observedSheetFrame(in: window)
    let deltaY = lastFrame.map { frame.minY - $0.minY } ?? 0

    AppleLiquidSheetPresenter.debugLog(
      "[mjn_liquid_ui][search-frame] " +
        "phase=\(keyboardPhase) " +
        "class=\(className) " +
        "y=\(format(frame.minY)) " +
        "h=\(format(frame.height)) " +
        "deltaY=\(format(deltaY)) " +
        "sheetY=\(format(sheetFrame.minY)) " +
        "sheetH=\(format(sheetFrame.height))"
    )

    lastFrame = frame
    lastClassName = className
  }

  private func shouldLog(frame: CGRect, className: String) -> Bool {
    guard let lastFrame, let lastClassName else {
      return true
    }

    return className != lastClassName ||
      abs(frame.minY - lastFrame.minY) >= 0.5 ||
      abs(frame.height - lastFrame.height) >= 0.5
  }

  private func logKeyboardEvent(
    _ name: String,
    notification: Notification
  ) {
    let duration =
      notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey]
      as? Double ?? 0
    let endFrame =
      notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey]
      as? CGRect ?? .zero
    keyboardDuration = duration
    keyboardY = endFrame.minY
    keyboardHeight = endFrame.height

    AppleLiquidSheetPresenter.debugLog(
      "[mjn_liquid_ui][search-frame] " +
        "event=\(name) " +
        "duration=\(format(duration)) " +
        "keyboardY=\(format(endFrame.minY)) " +
        "keyboardH=\(format(endFrame.height))"
    )
  }

  private func primarySearchView(in rootView: UIView) -> UIView? {
    let candidates = searchCandidates(in: rootView)

    return candidates.first { $0 is UISearchBar } ??
      candidates.first { $0 is UISearchTextField } ??
      candidates.max { first, second in
        first.bounds.width < second.bounds.width
      }
  }

  private func searchCandidates(in view: UIView) -> [UIView] {
    var candidates: [UIView] = []

    if isSearchView(view) {
      candidates.append(view)
    }

    for subview in view.subviews {
      candidates.append(contentsOf: searchCandidates(in: subview))
    }

    return candidates
  }

  private func isSearchView(_ view: UIView) -> Bool {
    if view is UISearchBar || view is UISearchTextField {
      return true
    }

    let className = String(describing: type(of: view))
    let hasSearchClassName = className.localizedCaseInsensitiveContains("Search")
    let hasSearchBarSize = view.bounds.width >= 120 &&
      view.bounds.height >= 28 &&
      view.bounds.height <= 80

    return hasSearchClassName && hasSearchBarSize
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

  private func format(_ value: CGFloat) -> String {
    String(format: "%.1f", value)
  }

  private func format(_ value: Double) -> String {
    String(format: "%.2f", value)
  }
}
#endif

@available(iOS 16.0, *)
private extension AppleLiquidSheetConfiguration {
  static let customDetentIdentifier =
    UISheetPresentationController.Detent.Identifier("appleLiquidTemplate")

  func apply(to sheetPresentationController: UISheetPresentationController) {
    sheetPresentationController.detents = detents
    sheetPresentationController.selectedDetentIdentifier = detentIdentifier
    sheetPresentationController.prefersGrabberVisible = false
    sheetPresentationController.prefersScrollingExpandsWhenScrolledToEdge = false
  }

  var detents: [UISheetPresentationController.Detent] {
    switch detentMode {
    case .medium:
      return [.medium(), .large()]

    case .large:
      return [.large()]

    case .custom:
      return [customDetent]
    }
  }

  var detentIdentifier: UISheetPresentationController.Detent.Identifier {
    switch detentMode {
    case .medium:
      return .medium

    case .large:
      return .large

    case .custom:
      return Self.customDetentIdentifier
    }
  }

  func applyKeyboardDetents(
    to sheetPresentationController: UISheetPresentationController
  ) {
    guard detentMode == .custom else {
      return
    }

    sheetPresentationController.detents = [customDetent, .large()]
    sheetPresentationController.selectedDetentIdentifier = .large
    sheetPresentationController.prefersScrollingExpandsWhenScrolledToEdge = false
  }

  func selectRestingDetent(
    on sheetPresentationController: UISheetPresentationController
  ) {
    sheetPresentationController.detents = [customDetent, .large()]
    sheetPresentationController.selectedDetentIdentifier = detentIdentifier
  }

  private var customDetent: UISheetPresentationController.Detent {
    .custom(identifier: Self.customDetentIdentifier) { context in
      customDetentResolver?.resolve(
        maximumDetentValue: context.maximumDetentValue
      ) ?? context.maximumDetentValue * heightFraction
    }
  }
}

@available(iOS 16.0, *)
private struct AppleLiquidCancelButton: ToolbarContent {
  var isDisabled = false
  let action: () -> Void

  @ToolbarContentBuilder
  var body: some ToolbarContent {
    ToolbarItem(placement: .cancellationAction) {
      Button(role: .cancel, action: action) {
        Image(systemName: "xmark")
      }
      .disabled(isDisabled)
      .accessibilityLabel("Cancel")
    }
  }
}

@available(iOS 16.0, *)
private struct AppleLiquidConfirmButton: ToolbarContent {
  var isDisabled = false
  let action: () -> Void

  @ToolbarContentBuilder
  var body: some ToolbarContent {
    ToolbarItem {
      if #available(iOS 26.0, *) {
        Button(role: .confirm, action: action) {
          Image(systemName: "checkmark")
        }
        .disabled(isDisabled)
        .accessibilityLabel("Confirm")
      } else {
        Button(action: action) {
          Image(systemName: "checkmark")
        }
        .disabled(isDisabled)
        .accessibilityLabel("Confirm")
      }
    }
  }
}

@available(iOS 16.0, *)
private struct AppleLiquidTemplatePickerContent: View {
  let searchText: String

  private let templates = [
    AppleLiquidTemplatePreview(
      title: "Meeting notes",
      accentColor: Color(red: 0.00, green: 0.48, blue: 1.00),
      rowWidths: [0.74, 0.60, 0.86, 0.42, 0.66]
    ),
    AppleLiquidTemplatePreview(
      title: "Class notes",
      accentColor: Color(red: 0.65, green: 0.54, blue: 0.96),
      rowWidths: [0.68, 0.82, 0.54, 0.70, 0.46]
    ),
    AppleLiquidTemplatePreview(
      title: "Project plan",
      accentColor: Color(red: 0.13, green: 0.77, blue: 0.37),
      rowWidths: [0.58, 0.76, 0.64, 0.88, 0.50]
    ),
    AppleLiquidTemplatePreview(
      title: "Research brief",
      accentColor: Color(red: 0.96, green: 0.62, blue: 0.04),
      rowWidths: [0.84, 0.72, 0.52, 0.78, 0.60]
    ),
  ]

  private let columns = [
    GridItem(.flexible(), spacing: 18),
    GridItem(.flexible(), spacing: 18),
  ]

  var body: some View {
    ScrollView {
      LazyVGrid(columns: columns, spacing: 22) {
        ForEach(filteredTemplates) { template in
          AppleLiquidTemplatePreviewCard(template: template)
        }
      }
      .padding(.horizontal, 24)
      .padding(.top, 18)
      .padding(.bottom, 36)
    }
    .scrollDismissesKeyboard(.interactively)
  }

  private var filteredTemplates: [AppleLiquidTemplatePreview] {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !query.isEmpty else {
      return templates
    }

    return templates.filter { template in
      template.title.localizedCaseInsensitiveContains(query)
    }
  }
}

@available(iOS 16.0, *)
private struct AppleLiquidTemplatePreview: Identifiable {
  let id = UUID()
  let title: String
  let accentColor: Color
  let rowWidths: [CGFloat]
}

@available(iOS 16.0, *)
private struct AppleLiquidTemplatePreviewCard: View {
  let template: AppleLiquidTemplatePreview

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      preview
      Text(template.title)
        .font(.headline)
        .lineLimit(1)
        .foregroundStyle(.primary)
    }
  }

  private var preview: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(template.title)
        .font(.caption.weight(.bold))
        .lineLimit(1)

      ForEach(Array(template.rowWidths.enumerated()), id: \.offset) { _, width in
        Capsule()
          .fill(.secondary.opacity(0.22))
          .frame(maxWidth: .infinity, alignment: .leading)
          .frame(width: 130 * width, height: 7)
      }

      Spacer()

      Capsule()
        .fill(template.accentColor.opacity(0.75))
        .frame(width: 78, height: 12)
    }
    .padding(14)
    .frame(height: 150)
    .foregroundStyle(.white)
    .background(Color.black.opacity(0.86), in: RoundedRectangle(cornerRadius: 18))
  }
}
