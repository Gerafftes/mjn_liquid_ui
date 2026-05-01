import Flutter
import SwiftUI
import UIKit

final class AppleLiquidSliderModel: ObservableObject {
  @Published private(set) var value: Double
  @Published private(set) var min: Double
  @Published private(set) var max: Double
  @Published private(set) var step: Double?
  @Published private(set) var tintColor: Color?

  var onValueChanged: ((Double) -> Void)?
  var onInteractionChanged: ((Bool) -> Void)?

  private var isInteracting = false

  init(configuration: AppleLiquidSliderConfiguration) {
    let minValue = configuration.min
    let maxValue = configuration.max

    min = minValue
    max = maxValue
    step = configuration.step
    value = Self.normalized(
      configuration.value,
      min: minValue,
      max: maxValue,
      step: configuration.step
    )
    tintColor = Color(appleLiquidARGB: configuration.tintColor)
  }

  func update(configuration: AppleLiquidSliderConfiguration) {
    min = configuration.min
    max = configuration.max
    step = configuration.step
    value = Self.normalized(
      configuration.value,
      min: min,
      max: max,
      step: step
    )
    tintColor = Color(appleLiquidARGB: configuration.tintColor)
  }

  func setValue(_ value: Double, notifyFlutter: Bool) {
    let nextValue = Self.normalized(value, min: min, max: max, step: step)
    let previousValue = self.value

    // Reassign even when the normalized value did not change. Some SwiftUI
    // slider styles report continuous drag positions before reading the bound
    // value again; publishing the snapped value keeps the thumb on the step.
    self.value = nextValue

    if notifyFlutter && previousValue != nextValue {
      onValueChanged?(nextValue)
    }
  }

  func setInteracting(_ isInteracting: Bool) {
    guard self.isInteracting != isInteracting else {
      return
    }

    self.isInteracting = isInteracting
    onInteractionChanged?(isInteracting)
  }

  private static func clamped(_ value: Double, min: Double, max: Double) -> Double {
    return Swift.min(Swift.max(value, min), max)
  }

  private static func normalized(
    _ value: Double,
    min: Double,
    max: Double,
    step: Double?
  ) -> Double {
    let clampedValue = clamped(value, min: min, max: max)
    guard let step else {
      return clampedValue
    }

    let steppedValue = min + ((clampedValue - min) / step).rounded() * step
    return clamped(steppedValue, min: min, max: max)
  }
}

struct AppleLiquidSliderView: View {
  @ObservedObject var model: AppleLiquidSliderModel

  var body: some View {
    slider
      .padding(.horizontal, 8)
      .appleLiquidControlTint(model.tintColor)
      .frame(maxHeight: .infinity)
  }

  @ViewBuilder
  private var slider: some View {
    if let step = model.step {
      Slider(
        value: Binding(
          get: { model.value },
          set: { model.setValue($0, notifyFlutter: true) }
        ),
        in: model.min...model.max,
        step: step,
        onEditingChanged: { isEditing in
          model.setInteracting(isEditing)
        }
      )
    } else {
      Slider(
        value: Binding(
          get: { model.value },
          set: { model.setValue($0, notifyFlutter: true) }
        ),
        in: model.min...model.max,
        onEditingChanged: { isEditing in
          model.setInteracting(isEditing)
        }
      )
    }
  }
}

final class AppleLiquidSliderPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func create(
    withFrame frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?
  ) -> FlutterPlatformView {
    return AppleLiquidSliderPlatformView(
      frame: frame,
      viewIdentifier: viewId,
      arguments: args,
      messenger: messenger
    )
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    return FlutterStandardMessageCodec.sharedInstance()
  }
}

final class AppleLiquidSliderPlatformView: NSObject, FlutterPlatformView {
  private let containerView: AppleLiquidPlatformViewContainer
  private let channel: FlutterMethodChannel
  private let model: AppleLiquidSliderModel
  private var hostingController: UIViewController?

  init(
    frame: CGRect,
    viewIdentifier viewId: Int64,
    arguments args: Any?,
    messenger: FlutterBinaryMessenger
  ) {
    containerView = AppleLiquidPlatformViewContainer(frame: frame)
    channel = FlutterMethodChannel(
      name: "\(AppleLiquidTabbarConstants.sliderViewType)/\(viewId)",
      binaryMessenger: messenger
    )
    model = AppleLiquidSliderModel(
      configuration: AppleLiquidSliderConfiguration(arguments: args)
    )

    super.init()

    model.onValueChanged = { [weak self] value in
      self?.channel.invokeMethod("valueChanged", arguments: ["value": value])
    }
    model.onInteractionChanged = { [weak self] isInteracting in
      self?.channel.invokeMethod(
        "interactionChanged",
        arguments: ["isInteracting": isInteracting]
      )
    }

    let hostingController = UIHostingController(
      rootView: AppleLiquidSliderView(model: model)
    )
    hostingController.view.backgroundColor = .clear
    hostingController.view.isOpaque = false
    containerView.host(hostingController)
    self.hostingController = hostingController

    channel.setMethodCallHandler(handle)
  }

  deinit {
    channel.setMethodCallHandler(nil)
    model.onValueChanged = nil
    model.onInteractionChanged = nil
    containerView.disposeHostedViewController()
  }

  func view() -> UIView {
    containerView
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "updateConfiguration":
      let configuration = AppleLiquidSliderConfiguration(arguments: call.arguments)
      model.update(configuration: configuration)
      result(nil)
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}
