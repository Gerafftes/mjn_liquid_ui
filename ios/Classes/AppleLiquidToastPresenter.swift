import Combine
import Flutter
import SwiftUI
import UIKit

enum AppleLiquidToastPresenter {
  @available(iOS 16.0, *)
  private static var activeSession: AppleLiquidToastSession?
  @available(iOS 16.0, *)
  private static var isSheetPresented = false

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: AppleLiquidTabbarConstants.toastChannelName,
      binaryMessenger: messenger
    )

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "show":
        show(arguments: call.arguments, channel: channel, result: result)

      case "dismiss":
        dismiss(result: result)

      case "setVisibility":
        setVisibility(arguments: call.arguments, result: result)

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func show(
    arguments: Any?,
    channel: FlutterMethodChannel,
    result: @escaping FlutterResult
  ) {
    guard #available(iOS 16.0, *) else {
      result(false)
      return
    }

    guard let configuration = AppleLiquidToastConfiguration(arguments: arguments) else {
      result(
        FlutterError(
          code: "invalid_toast",
          message: "AppleLiquidToast.show received invalid arguments.",
          details: nil
        )
      )
      return
    }

    let isVisible = (arguments as? [String: Any])?["isVisible"] as? Bool ?? true

    guard let scene = activeWindowScene() else {
      result(false)
      return
    }

    if let activeSession, activeSession.isAttached(to: scene) {
      activeSession.setSheetPresented(isSheetPresented)
      activeSession.setVisible(isVisible)
      activeSession.show(configuration)
      result(true)
      return
    }

    activeSession?.dispose()

    let session = AppleLiquidToastSession(scene: scene, channel: channel)
    session.setSheetPresented(isSheetPresented)
    session.setVisible(isVisible)
    guard session.attach() else {
      result(false)
      return
    }

    activeSession = session
    session.show(configuration)
    result(true)
  }

  @available(iOS 16.0, *)
  static func setSheetPresented(_ presented: Bool) {
    isSheetPresented = presented
    activeSession?.setSheetPresented(presented)
  }

  private static func setVisibility(
    arguments: Any?,
    result: @escaping FlutterResult
  ) {
    guard #available(iOS 16.0, *) else {
      result(false)
      return
    }

    guard let visible = arguments as? Bool else {
      result(
        FlutterError(
          code: "invalid_toast_visibility",
          message: "AppleLiquidToast.setVisible expects a boolean.",
          details: nil
        )
      )
      return
    }

    guard let activeSession else {
      result(false)
      return
    }

    activeSession.setVisible(visible)
    result(true)
  }

  private static func dismiss(result: @escaping FlutterResult) {
    guard #available(iOS 16.0, *) else {
      result(false)
      return
    }

    guard let activeSession else {
      result(false)
      return
    }

    activeSession.dismiss()
    result(true)
  }

  private static func activeWindowScene() -> UIWindowScene? {
    let foregroundScenes = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .filter { scene in
        scene.activationState == .foregroundActive ||
          scene.activationState == .foregroundInactive
      }

    let windows = foregroundScenes.flatMap(\.windows)
    return windows.first(where: \.isKeyWindow)?.windowScene ??
      windows.first?.windowScene
  }
}

@available(iOS 16.0, *)
private final class AppleLiquidToastSession {
  private let overlayWindow: AppleLiquidToastOverlayWindow
  private let model: AppleLiquidToastModel
  private let hostingController: UIHostingController<AppleLiquidToastHostView>
  private var cancellables = Set<AnyCancellable>()

  init(scene: UIWindowScene, channel: FlutterMethodChannel) {
    let model = AppleLiquidToastModel { toastId in
      channel.invokeMethod(
        "toastDismissed",
        arguments: ["toastId": toastId]
      )
    }
    let overlayWindow = AppleLiquidToastOverlayWindow(windowScene: scene)

    self.overlayWindow = overlayWindow
    self.model = model
    self.hostingController = UIHostingController(
      rootView: AppleLiquidToastHostView(
        model: model,
        onHitFrameChanged: { [weak overlayWindow] frame in
          let activeToastIDs = Set(model.activeToasts.map(\.id))
          if activeToastIDs.contains(frame.id) {
            overlayWindow?.updateHitFrame(frame)
          } else {
            overlayWindow?.removeHitFrame(id: frame.id)
          }
        },
        onAction: { toast in
          if toast.dismissesOnAction {
            model.dismiss(id: toast.id)
          }

          // Let SwiftUI remove the overlay content before Dart gets a chance
          // to present another native controller from the action callback.
          DispatchQueue.main.async {
            if let actionId = toast.actionId {
              channel.invokeMethod(
                "actionInvoked",
                arguments: ["actionId": actionId]
              )
            } else if toast.dismissesOnAction {
              channel.invokeMethod(
                "toastDismissed",
                arguments: ["toastId": toast.id]
              )
            }
          }
        },
        onSwipeDismiss: { toast in
          model.dismiss(id: toast.id)
          channel.invokeMethod(
            "toastDismissed",
            arguments: ["toastId": toast.id]
          )
        }
      )
    )

    overlayWindow.windowLevel = UIWindow.Level(
      rawValue: UIWindow.Level.alert.rawValue + 1
    )
    overlayWindow.backgroundColor = .clear
    overlayWindow.isOpaque = false
    hostingController.view.backgroundColor = .clear
    hostingController.view.isOpaque = false
    hostingController.view.clipsToBounds = false

    Publishers.CombineLatest(model.$activeToasts, model.$isVisible)
      .receive(on: RunLoop.main)
      .sink { [weak overlayWindow] value in
        let (toasts, isVisible) = value
        overlayWindow?.updateLayout(for: isVisible ? toasts : [])
        overlayWindow?.isUserInteractionEnabled = isVisible && !toasts.isEmpty
      }
      .store(in: &cancellables)
  }

  func attach() -> Bool {
    overlayWindow.rootViewController = hostingController
    overlayWindow.isHidden = false
    return true
  }

  func isAttached(to scene: UIWindowScene) -> Bool {
    return overlayWindow.windowScene === scene
  }

  func show(_ toast: AppleLiquidToastConfiguration) {
    model.show(toast)
    overlayWindow.updateLayout(for: model.isVisible ? model.activeToasts : [])
  }

  func setVisible(_ visible: Bool) {
    model.setVisible(visible)
  }

  func setSheetPresented(_ presented: Bool) {
    model.setSheetPresented(presented)
  }

  func dismiss() {
    model.dismiss()
  }

  func dispose() {
    model.dismiss()
    cancellables.removeAll()
    overlayWindow.isHidden = true
    overlayWindow.rootViewController = nil
  }
}

@available(iOS 16.0, *)
private final class AppleLiquidToastOverlayWindow: UIWindow {
  private static let extraWindowHeight: CGFloat = 140
  private static let minimumWindowHeight: CGFloat = 160
  private static let stackSpacing: CGFloat = 10
  private static let toastHeight: CGFloat = 50

  private var toastHitFrames = [String: CGRect]()

  override var canBecomeKey: Bool {
    false
  }

  func updateLayout(for toasts: [AppleLiquidToastConfiguration]) {
    guard let windowScene else {
      return
    }

    toastHitFrames.removeAll(keepingCapacity: true)

    // Keep the last window frame while SwiftUI runs the removal transition.
    // Resizing a bottom-aligned host at the same time makes a fading toast
    // jump vertically, especially when the complete stack is dismissed.
    guard !toasts.isEmpty else {
      return
    }

    let sceneBounds = windowScene.coordinateSpace.bounds
    let stackHeight = CGFloat(toasts.count) * Self.toastHeight +
      CGFloat(max(toasts.count - 1, 0)) * Self.stackSpacing
    let maximumOffset = toasts.map { abs($0.placementOffset) }.max() ?? 0
    let height = min(
      sceneBounds.height,
      max(
        Self.minimumWindowHeight,
        stackHeight + maximumOffset + Self.extraWindowHeight - Self.toastHeight
      )
    )
    frame = CGRect(
      x: sceneBounds.minX,
      y: sceneBounds.maxY - height,
      width: sceneBounds.width,
      height: height
    )
  }

  func updateHitFrame(_ frame: AppleLiquidToastHitFrame) {
    toastHitFrames[frame.id] = frame.rect
  }

  func removeHitFrame(id: String) {
    toastHitFrames.removeValue(forKey: id)
  }

  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    toastHitFrames.values.contains { frame in
      UIBezierPath(
        roundedRect: frame,
        cornerRadius: frame.height / 2
      ).contains(point)
    }
  }
}

@available(iOS 16.0, *)
private final class AppleLiquidToastModel: ObservableObject {
  @Published private(set) var activeToasts: [AppleLiquidToastConfiguration] = []
  @Published private(set) var isVisible = true

  private var requestedVisibility = true
  private var isSheetPresented = false
  private let animation = Animation.spring(
    response: 0.26,
    dampingFraction: 0.88,
    blendDuration: 0.12
  )
  private let dismissalAnimation = Animation.easeOut(duration: 0.18)
  private let onToastDismissed: (String) -> Void
  private var dismissWorkItems = [String: DispatchWorkItem]()
  private var overflowToastID: String?
  private var overflowCount = 0

  init(
    onToastDismissed: @escaping (String) -> Void
  ) {
    self.onToastDismissed = onToastDismissed
  }

  func setVisible(_ visible: Bool) {
    requestedVisibility = visible
    updateVisibility(animation: visible ? animation : dismissalAnimation)
  }

  func setSheetPresented(_ presented: Bool) {
    isSheetPresented = presented
    updateVisibility(animation: presented ? dismissalAnimation : animation)
  }

  private func updateVisibility(animation: Animation) {
    let effectiveVisibility = requestedVisibility && !isSheetPresented
    guard isVisible != effectiveVisibility else {
      return
    }

    withAnimation(animation) {
      isVisible = effectiveVisibility
    }
  }

  func dismiss() {
    cancelDismissals()
    overflowToastID = nil
    overflowCount = 0

    withAnimation(dismissalAnimation) {
      activeToasts.removeAll()
    }
  }

  func dismiss(id: String) {
    guard let index = activeToasts.firstIndex(where: { $0.id == id }) else {
      return
    }

    dismissWorkItems.removeValue(forKey: id)?.cancel()
    if id == overflowToastID {
      overflowToastID = nil
      overflowCount = 0
    }
    withAnimation(animation) {
      _ = activeToasts.remove(at: index)
    }
  }

  func show(_ toast: AppleLiquidToastConfiguration) {
    if overflowToastID != nil {
      if toast.maxVisibleToasts == nil {
        replaceOverflow(with: toast)
      } else {
        updateOverflow(with: toast)
      }
      return
    }

    if let maxVisibleToasts = toast.maxVisibleToasts,
      activeToasts.count >= maxVisibleToasts
    {
      collapseOverflow(with: toast)
      return
    }

    present(toast)
  }

  private func present(_ toast: AppleLiquidToastConfiguration) {
    dismissWorkItems.removeValue(forKey: toast.id)?.cancel()
    withAnimation(animation) {
      activeToasts.append(toast)
    }
    scheduleDismissal(for: toast)
  }

  private func collapseOverflow(with toast: AppleLiquidToastConfiguration) {
    let collapsedToasts = activeToasts + [toast]
    let summaryID = "toast_overflow_\(UUID().uuidString)"
    let summary = toast.overflowSummary(
      id: summaryID,
      title: overflowTitle(for: toast.overflowTitle, count: collapsedToasts.count),
      duration: toast.duration
    )

    cancelDismissals()
    overflowToastID = summaryID
    overflowCount = collapsedToasts.count
    withAnimation(animation) {
      activeToasts = [summary]
    }

    for collapsedToast in collapsedToasts {
      onToastDismissed(collapsedToast.id)
    }
    scheduleDismissal(for: summary)
  }

  private func updateOverflow(with toast: AppleLiquidToastConfiguration) {
    guard let summaryID = overflowToastID else {
      return
    }

    overflowCount += 1
    let summary = toast.overflowSummary(
      id: summaryID,
      title: overflowTitle(for: toast.overflowTitle, count: overflowCount),
      duration: toast.duration
    )

    dismissWorkItems.removeValue(forKey: summaryID)?.cancel()
    withAnimation(animation) {
      activeToasts = [summary]
    }
    onToastDismissed(toast.id)
    scheduleDismissal(for: summary)
  }

  private func replaceOverflow(with toast: AppleLiquidToastConfiguration) {
    cancelDismissals()
    overflowToastID = nil
    overflowCount = 0
    withAnimation(animation) {
      activeToasts = [toast]
    }
    scheduleDismissal(for: toast)
  }

  private func scheduleDismissal(for toast: AppleLiquidToastConfiguration) {
    guard let duration = toast.duration else {
      return
    }

    let dismissWorkItem = DispatchWorkItem { [weak self] in
      self?.dismissAutomatically(id: toast.id)
    }

    dismissWorkItems[toast.id] = dismissWorkItem
    DispatchQueue.main.asyncAfter(
      deadline: .now() + max(duration, 1),
      execute: dismissWorkItem
    )
  }

  private func dismissAutomatically(id: String) {
    guard let index = activeToasts.firstIndex(where: { $0.id == id }) else {
      return
    }

    let toast = activeToasts[index]
    dismissWorkItems.removeValue(forKey: id)
    if id == overflowToastID {
      overflowToastID = nil
      overflowCount = 0
    }
    withAnimation(animation) {
      _ = activeToasts.remove(at: index)
    }
    onToastDismissed(toast.id)
  }

  private func cancelDismissals() {
    for workItem in dismissWorkItems.values {
      workItem.cancel()
    }
    dismissWorkItems.removeAll()
  }

  private func overflowTitle(for template: String, count: Int) -> String {
    template.replacingOccurrences(of: "{count}", with: String(count))
  }
}

@available(iOS 16.0, *)
struct AppleLiquidToastHitFrame: Equatable {
  let id: String
  let rect: CGRect

  init(
    id: String,
    geometryFrame: CGRect,
    placementOffset: CGFloat
  ) {
    self.id = id
    // The named SwiftUI coordinate space moves with the row offset, while
    // UIWindow hit testing remains in the window's fixed coordinate space.
    self.rect = geometryFrame.offsetBy(dx: 0, dy: -placementOffset)
  }
}

@available(iOS 16.0, *)
private struct AppleLiquidToastHostView: View {
  @ObservedObject var model: AppleLiquidToastModel
  let onHitFrameChanged: (AppleLiquidToastHitFrame) -> Void
  let onAction: (AppleLiquidToastConfiguration) -> Void
  let onSwipeDismiss: (AppleLiquidToastConfiguration) -> Void

  var body: some View {
    ZStack(alignment: .bottom) {
      Color.clear
        .allowsHitTesting(false)

      if model.isVisible {
        VStack(spacing: 10) {
          ForEach(model.activeToasts.reversed()) { toast in
            toastView(toast)
              .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .named("appleLiquidToast"))
              } action: { frame in
                onHitFrameChanged(
                  AppleLiquidToastHitFrame(
                    id: toast.id,
                    geometryFrame: frame,
                    placementOffset: toast.placementOffset
                  )
                )
              }
              .padding(.horizontal, 15)
              .offset(y: toast.placementOffset)
              .gesture(
                DragGesture()
                  .onEnded { value in
                    if value.translation.height > 30 {
                      guard model.activeToasts.contains(where: {
                        $0.id == toast.id
                      }) else {
                        return
                      }
                      onSwipeDismiss(toast)
                    }
                  }
              )
              .transition(toastTransition(for: toast))
          }
        }
        .transition(.opacity)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
    .coordinateSpace(name: "appleLiquidToast")
  }

  private func toastTransition(
    for toast: AppleLiquidToastConfiguration
  ) -> AnyTransition {
    let insertion: AnyTransition
    if model.activeToasts.count > 1 {
      // The spring moves existing rows; sliding a new top row through them
      // creates overlap during burst updates.
      insertion = .opacity
    } else {
      insertion = .offset(y: toast.transitionOffset)
        .combined(with: .opacity)
    }

    return .asymmetric(insertion: insertion, removal: .opacity)
  }

  @ViewBuilder
  private func toastView(_ toast: AppleLiquidToastConfiguration) -> some View {
    if #available(iOS 26.0, *) {
      AppleLiquidGlassToastView(toast: toast, onAction: onAction)
    } else {
      AppleLiquidFallbackToastView(toast: toast, onAction: onAction)
    }
  }
}

@available(iOS 16.0, *)
private struct AppleLiquidToastContent: View {
  let toast: AppleLiquidToastConfiguration
  let onAction: (AppleLiquidToastConfiguration) -> Void

  var body: some View {
    if toast.isWholeToastTappable, toast.actionTitle != nil {
      Button {
        onAction(toast)
      } label: {
        toastLayout
      }
      .buttonStyle(.plain)
      .contentShape(Capsule())
    } else {
      toastLayout
    }
  }

  @ViewBuilder
  private var toastLayout: some View {
    HStack(spacing: 10) {
      if let systemImage = toast.systemImage {
        Image(systemName: systemImage)
          .font(.title3)
          .foregroundStyle(Color.primary)
          .transition(.identity)
      }

      Text(toast.title)
        .font(.body)
        .lineLimit(1)
        .minimumScaleFactor(0.85)

      Spacer(minLength: 0)

      if let actionTitle = toast.actionTitle {
        Group {
          if toast.isWholeToastTappable {
            actionLabel(actionTitle)
          } else {
            Button {
              onAction(toast)
            } label: {
              actionLabel(actionTitle)
            }
            .buttonStyle(.plain)
          }
        }
        .transition(.identity)
      }
    }
    .padding(.horizontal, 18)
    .frame(height: 50)
    .clipShape(Capsule())
    .contentShape(Capsule())
  }

  private func actionLabel(_ title: String) -> some View {
    Text(title)
      .font(.body.weight(.semibold))
      .foregroundStyle(toast.actionTintColor ?? Color.accentColor)
  }
}

@available(iOS 16.0, *)
private struct AppleLiquidFallbackToastView: View {
  let toast: AppleLiquidToastConfiguration
  let onAction: (AppleLiquidToastConfiguration) -> Void

  var body: some View {
    AppleLiquidToastContent(toast: toast, onAction: onAction)
      .background(
        Capsule()
          .fill(Color(UIColor.secondarySystemBackground).opacity(0.94))
      )
      .overlay(
        Capsule()
          .stroke(Color(UIColor.separator).opacity(0.28), lineWidth: 1)
      )
      .shadow(color: Color.black.opacity(0.16), radius: 18, y: 8)
  }
}

@available(iOS 26.0, *)
private struct AppleLiquidGlassToastView: View {
  let toast: AppleLiquidToastConfiguration
  let onAction: (AppleLiquidToastConfiguration) -> Void

  var body: some View {
    GlassEffectContainer(spacing: 10) {
      AppleLiquidToastContent(toast: toast, onAction: onAction)
        .glassEffect(Glass.regular, in: Capsule())
    }
  }
}

@available(iOS 16.0, *)
private struct AppleLiquidToastConfiguration: Identifiable {
  let id: String
  let title: String
  let duration: TimeInterval?
  let placementOffset: CGFloat
  let transitionOffset: CGFloat
  let systemImage: String?
  let actionTitle: String?
  let actionTintColor: Color?
  let actionId: String?
  let dismissesOnAction: Bool
  let isWholeToastTappable: Bool
  let maxVisibleToasts: Int?
  let overflowTitle: String

  init?(arguments: Any?) {
    guard let dictionary = arguments as? [String: Any],
      let title = Self.optionalString(dictionary["title"])
    else {
      return nil
    }

    self.init(
      id: Self.optionalString(dictionary["id"]) ?? UUID().uuidString,
      title: title,
      duration: Self.duration(dictionary["duration"]),
      placementOffset: CGFloat(
        Self.double(dictionary["placementOffset"], defaultValue: -60)
      ),
      transitionOffset: CGFloat(
        Self.double(dictionary["transitionOffset"], defaultValue: 100)
      ),
      systemImage: Self.optionalString(dictionary["systemImage"]),
      actionTitle: Self.optionalString(dictionary["actionTitle"]),
      actionTintColor: Color(
        appleLiquidARGB: Self.optionalInt(dictionary["actionTintColor"])
      ),
      actionId: Self.optionalString(dictionary["actionId"]),
      dismissesOnAction: Self.bool(
        dictionary["dismissesOnAction"],
        defaultValue: true
      ),
      isWholeToastTappable: Self.bool(
        dictionary["isWholeToastTappable"],
        defaultValue: false
      ),
      maxVisibleToasts: Self.positiveInt(dictionary["maxVisibleToasts"]),
      overflowTitle: Self.optionalString(dictionary["overflowTitle"])
        ?? "More notifications"
    )
  }

  init(
    id: String,
    title: String,
    duration: TimeInterval?,
    placementOffset: CGFloat,
    transitionOffset: CGFloat,
    systemImage: String?,
    actionTitle: String?,
    actionTintColor: Color?,
    actionId: String?,
    dismissesOnAction: Bool,
    isWholeToastTappable: Bool,
    maxVisibleToasts: Int?,
    overflowTitle: String
  ) {
    self.id = id
    self.title = title
    self.duration = duration
    self.placementOffset = placementOffset
    self.transitionOffset = transitionOffset
    self.systemImage = systemImage
    self.actionTitle = actionTitle
    self.actionTintColor = actionTintColor
    self.actionId = actionId
    self.dismissesOnAction = dismissesOnAction
    self.isWholeToastTappable = isWholeToastTappable
    self.maxVisibleToasts = maxVisibleToasts
    self.overflowTitle = overflowTitle
  }

  func overflowSummary(
    id: String,
    title: String,
    duration: TimeInterval?
  ) -> AppleLiquidToastConfiguration {
    AppleLiquidToastConfiguration(
      id: id,
      title: title,
      duration: duration,
      placementOffset: placementOffset,
      transitionOffset: transitionOffset,
      systemImage: nil,
      actionTitle: nil,
      actionTintColor: nil,
      actionId: nil,
      dismissesOnAction: true,
      isWholeToastTappable: false,
      maxVisibleToasts: maxVisibleToasts,
      overflowTitle: overflowTitle
    )
  }

  private static func optionalString(_ value: Any?) -> String? {
    guard let string = value as? String else {
      return nil
    }

    let trimmedString = string.trimmingCharacters(
      in: .whitespacesAndNewlines
    )
    return trimmedString.isEmpty ? nil : trimmedString
  }

  private static func double(_ value: Any?, defaultValue: Double) -> Double {
    if let value = value as? Double {
      return value
    }

    if let value = value as? NSNumber {
      return value.doubleValue
    }

    return defaultValue
  }

  private static func duration(_ value: Any?) -> TimeInterval? {
    guard let value else {
      return 3
    }

    if value is NSNull {
      return nil
    }

    return double(value, defaultValue: 3)
  }

  private static func optionalInt(_ value: Any?) -> Int? {
    if let value = value as? Int {
      return value
    }

    if let value = value as? NSNumber {
      return value.intValue
    }

    return nil
  }

  private static func positiveInt(_ value: Any?) -> Int? {
    guard let value = optionalInt(value), value > 0 else {
      return nil
    }

    return value
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
