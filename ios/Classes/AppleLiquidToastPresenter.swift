import Combine
import Flutter
import SwiftUI
import UIKit

enum AppleLiquidToastPresenter {
  @available(iOS 16.0, *)
  private static var activeSession: AppleLiquidToastSession?

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

    guard let scene = activeWindowScene() else {
      result(false)
      return
    }

    if let activeSession, activeSession.isAttached(to: scene) {
      activeSession.show(configuration)
      result(true)
      return
    }

    activeSession?.dispose()

    let session = AppleLiquidToastSession(scene: scene, channel: channel)
    guard session.attach() else {
      result(false)
      return
    }

    activeSession = session
    session.show(configuration)
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
    let model = AppleLiquidToastModel()
    let overlayWindow = AppleLiquidToastOverlayWindow(windowScene: scene)

    self.overlayWindow = overlayWindow
    self.model = model
    self.hostingController = UIHostingController(
      rootView: AppleLiquidToastHostView(model: model) { toast in
        if let actionId = toast.actionId {
          channel.invokeMethod(
            "actionInvoked",
            arguments: ["actionId": actionId]
          )
        }

        if toast.dismissesOnAction {
          model.dismiss()
        }
      }
    )

    overlayWindow.windowLevel = UIWindow.Level(
      rawValue: UIWindow.Level.alert.rawValue + 1
    )
    overlayWindow.backgroundColor = .clear
    overlayWindow.isOpaque = false
    hostingController.view.backgroundColor = .clear
    hostingController.view.isOpaque = false
    hostingController.view.clipsToBounds = false

    model.$activeToast
      .receive(on: RunLoop.main)
      .sink { [weak overlayWindow] toast in
        overlayWindow?.isUserInteractionEnabled = toast != nil
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
    overlayWindow.updateLayout(for: toast)
    model.show(toast)
  }

  func dismiss() {
    model.dismiss()
  }

  func dispose() {
    cancellables.removeAll()
    overlayWindow.isHidden = true
    overlayWindow.rootViewController = nil
  }
}

@available(iOS 16.0, *)
private final class AppleLiquidToastOverlayWindow: UIWindow {
  private static let extraWindowHeight: CGFloat = 140
  private static let hitAreaVerticalPadding: CGFloat = 18
  private static let minimumWindowHeight: CGFloat = 160
  private static let toastHeight: CGFloat = 50

  private var toastHitFrame = CGRect.null

  func updateLayout(for toast: AppleLiquidToastConfiguration) {
    guard let windowScene else {
      return
    }

    let sceneBounds = windowScene.coordinateSpace.bounds
    let height = min(
      sceneBounds.height,
      max(
        Self.minimumWindowHeight,
        abs(toast.placementOffset) + Self.extraWindowHeight
      )
    )
    frame = CGRect(
      x: sceneBounds.minX,
      y: sceneBounds.maxY - height,
      width: sceneBounds.width,
      height: height
    )

    let toastTop = height - Self.toastHeight + toast.placementOffset
    toastHitFrame = CGRect(
      x: 0,
      y: toastTop - Self.hitAreaVerticalPadding,
      width: sceneBounds.width,
      height: Self.toastHeight + Self.hitAreaVerticalPadding * 2
    ).intersection(CGRect(origin: .zero, size: frame.size))
  }

  override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
    return toastHitFrame.contains(point)
  }
}

@available(iOS 16.0, *)
private final class AppleLiquidToastModel: ObservableObject {
  @Published private(set) var activeToast: AppleLiquidToastConfiguration?

  private let animation = Animation.interpolatingSpring(
    stiffness: 260,
    damping: 28
  )
  private var dismissWorkItem: DispatchWorkItem?

  func show(_ toast: AppleLiquidToastConfiguration) {
    dismissWorkItem?.cancel()

    guard activeToast != nil else {
      present(toast)
      return
    }

    withAnimation(animation) {
      activeToast = nil
    }

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.17) { [weak self] in
      self?.present(toast)
    }
  }

  func dismiss() {
    withAnimation(animation) {
      activeToast = nil
    }

    dismissWorkItem?.cancel()
    dismissWorkItem = nil
  }

  private func present(_ toast: AppleLiquidToastConfiguration) {
    withAnimation(animation) {
      activeToast = toast
    }

    let dismissWorkItem = DispatchWorkItem { [weak self] in
      self?.dismiss()
    }

    self.dismissWorkItem = dismissWorkItem
    DispatchQueue.main.asyncAfter(
      deadline: .now() + max(toast.duration, 1),
      execute: dismissWorkItem
    )
  }
}

@available(iOS 16.0, *)
private struct AppleLiquidToastHostView: View {
  @ObservedObject var model: AppleLiquidToastModel
  let onAction: (AppleLiquidToastConfiguration) -> Void

  var body: some View {
    ZStack(alignment: .bottom) {
      Color.clear
        .allowsHitTesting(false)

      if let activeToast = model.activeToast {
        toastView(activeToast)
          .padding(.horizontal, 15)
          .offset(y: activeToast.placementOffset)
          .gesture(
            DragGesture()
              .onEnded { value in
                if value.translation.height > 30 {
                  model.dismiss()
                }
              }
          )
          .transition(
            .offset(y: activeToast.transitionOffset)
              .combined(with: .opacity)
          )
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
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
        Button {
          onAction(toast)
        } label: {
          Text(actionTitle)
            .font(.body.weight(.semibold))
            .foregroundStyle(toast.actionTintColor ?? Color.accentColor)
        }
        .buttonStyle(.plain)
        .transition(.identity)
      }
    }
    .padding(.horizontal, 18)
    .frame(height: 50)
    .clipShape(Capsule())
    .contentShape(Capsule())
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
  let duration: TimeInterval
  let placementOffset: CGFloat
  let transitionOffset: CGFloat
  let systemImage: String?
  let actionTitle: String?
  let actionTintColor: Color?
  let actionId: String?
  let dismissesOnAction: Bool

  init?(arguments: Any?) {
    guard let dictionary = arguments as? [String: Any],
      let title = Self.optionalString(dictionary["title"])
    else {
      return nil
    }

    self.id = Self.optionalString(dictionary["id"]) ?? UUID().uuidString
    self.title = title
    self.duration = Self.double(dictionary["duration"], defaultValue: 3)
    self.placementOffset = CGFloat(
      Self.double(dictionary["placementOffset"], defaultValue: -60)
    )
    self.transitionOffset = CGFloat(
      Self.double(dictionary["transitionOffset"], defaultValue: 100)
    )
    self.systemImage = Self.optionalString(dictionary["systemImage"])
    self.actionTitle = Self.optionalString(dictionary["actionTitle"])
    self.actionTintColor = Color(
      appleLiquidARGB: Self.optionalInt(dictionary["actionTintColor"])
    )
    self.actionId = Self.optionalString(dictionary["actionId"])
    self.dismissesOnAction = Self.bool(
      dictionary["dismissesOnAction"],
      defaultValue: true
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

  private static func optionalInt(_ value: Any?) -> Int? {
    if let value = value as? Int {
      return value
    }

    if let value = value as? NSNumber {
      return value.intValue
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
