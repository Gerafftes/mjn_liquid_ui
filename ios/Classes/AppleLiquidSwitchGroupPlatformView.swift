import CoreFoundation
import Flutter
import UIKit

struct AppleLiquidSwitchGroupConfiguration {
  struct Item {
    let id: String
    let value: Bool
    let tintColor: Int?
    let semanticLabel: String
  }

  let items: [Item]
  let rowHeight: CGFloat

  init?(arguments: Any?) {
    guard let args = arguments as? [String: Any],
      let height = args["rowHeight"] as? NSNumber,
      CFGetTypeID(height) != CFBooleanGetTypeID(),
      height.doubleValue.isFinite, height.doubleValue >= 44,
      let rows = args["items"] as? [[String: Any]],
      (height.doubleValue * Double(rows.count)).isFinite
    else { return nil }
    var ids = Set<String>()
    var items: [Item] = []
    for row in rows {
      guard let id = row["id"] as? String, !id.isEmpty,
        ids.insert(id).inserted,
        let value = row["value"] as? NSNumber,
        CFGetTypeID(value) == CFBooleanGetTypeID(),
        let label = row["semanticLabel"] as? String
      else { return nil }
      var tint: Int?
      if let color = row["tintColor"], !(color is NSNull) {
        guard let number = color as? NSNumber,
          CFGetTypeID(number) != CFBooleanGetTypeID(),
          number.doubleValue.isFinite,
          number.doubleValue >= 0, number.doubleValue <= Double(UInt32.max),
          number.doubleValue.rounded() == number.doubleValue
        else { return nil }
        tint = number.intValue
      }
      items.append(Item(id: id, value: value.boolValue, tintColor: tint, semanticLabel: label))
    }
    self.items = items
    rowHeight = CGFloat(height.doubleValue)
  }
}

final class AppleLiquidSwitchGroupPlatformViewFactory: NSObject, FlutterPlatformViewFactory {
  private let messenger: FlutterBinaryMessenger

  init(messenger: FlutterBinaryMessenger) {
    self.messenger = messenger
    super.init()
  }

  func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?)
    -> FlutterPlatformView
  {
    AppleLiquidSwitchGroupPlatformView(
      frame: frame, viewIdentifier: viewId,
      arguments: args, messenger: messenger)
  }

  func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
    FlutterStandardMessageCodec.sharedInstance()
  }
}

/// Controls and pending configurations are keyed by stable IDs, never row indices.
final class AppleLiquidSwitchGroupPlatformView: NSObject, FlutterPlatformView {
  private let containerView: UIView
  private let channel: FlutterMethodChannel
  private var controls: [String: UISwitch] = [:]
  private var latest: AppleLiquidSwitchGroupConfiguration?
  private var interacting = Set<String>()
  private var pendingValueChanges = Set<String>()
  private var pendingTintChanges = Set<String>()
  private var constraints: [NSLayoutConstraint] = []

  init(
    frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?,
    messenger: FlutterBinaryMessenger
  ) {
    containerView = UIView(frame: frame)
    channel = FlutterMethodChannel(
      name: "\(AppleLiquidTabbarConstants.switchGroupViewType)/\(viewId)",
      binaryMessenger: messenger)
    super.init()
    containerView.backgroundColor = .clear
    containerView.isOpaque = false
    // Invalid creation arguments produce no controls. The platform-view factory
    // cannot return a FlutterError; channel updates report invalid arguments.
    if let configuration = AppleLiquidSwitchGroupConfiguration(arguments: args) {
      apply(configuration)
    }
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else {
        result(nil)
        return
      }
      guard call.method == "updateConfiguration" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let configuration = AppleLiquidSwitchGroupConfiguration(arguments: call.arguments)
      else {
        result(
          FlutterError(
            code: "invalid_arguments", message: "Invalid switch group configuration.", details: nil)
        )
        return
      }
      self.apply(configuration)
      result(nil)
    }
  }

  deinit {
    channel.setMethodCallHandler(nil)
    for control in controls.values {
      control.removeTarget(nil, action: nil, for: .allEvents)
    }
  }

  func view() -> UIView { containerView }

  private func apply(_ configuration: AppleLiquidSwitchGroupConfiguration) {
    let previousItems = Dictionary(uniqueKeysWithValues: (latest?.items ?? []).map { ($0.id, $0) })
    for item in configuration.items where interacting.contains(item.id) {
      if let previous = previousItems[item.id] {
        if previous.value != item.value {
          pendingValueChanges.insert(item.id)
        }
        if previous.tintColor != item.tintColor {
          pendingTintChanges.insert(item.id)
        }
      }
    }
    latest = configuration
    let ids = Set(configuration.items.map { $0.id })
    for id in Array(controls.keys) where !ids.contains(id) {
      controls[id]?.removeTarget(nil, action: nil, for: .allEvents)
      controls.removeValue(forKey: id)?.removeFromSuperview()
      interacting.remove(id)
      pendingValueChanges.remove(id)
      pendingTintChanges.remove(id)
    }
    NSLayoutConstraint.deactivate(constraints)
    constraints = []
    for (index, item) in configuration.items.enumerated() {
      let control: UISwitch
      if let existing = controls[item.id] {
        control = existing
      } else {
        control = UISwitch(frame: .zero)
        control.translatesAutoresizingMaskIntoConstraints = false
        control.addTarget(self, action: #selector(valueChanged(_:)), for: .valueChanged)
        control.addTarget(
          self, action: #selector(interactionStarted(_:)), for: [.touchDown, .touchDragEnter])
        control.addTarget(
          self, action: #selector(interactionEnded(_:)),
          for: [.touchUpInside, .touchUpOutside, .touchCancel, .touchDragExit])
        controls[item.id] = control
        containerView.addSubview(control)
      }
      control.accessibilityLabel = item.semanticLabel
      if !interacting.contains(item.id) { synchronize(control, item: item) }
      constraints.append(contentsOf: [
        control.centerXAnchor.constraint(equalTo: containerView.centerXAnchor),
        control.centerYAnchor.constraint(
          equalTo: containerView.topAnchor,
          constant: (CGFloat(index) + 0.5) * configuration.rowHeight),
      ])
    }
    // VoiceOver follows the displayed row order after reordering IDs.
    containerView.accessibilityElements = configuration.items.compactMap { controls[$0.id] }
    NSLayoutConstraint.activate(constraints)
  }

  private func synchronize(
    _ control: UISwitch, item: AppleLiquidSwitchGroupConfiguration.Item,
    updateValue: Bool = true, updateTint: Bool = true
  ) {
    if updateValue && control.isOn != item.value { control.setOn(item.value, animated: false) }
    if updateTint {
      control.onTintColor = UIColor(appleLiquidARGB: item.tintColor)
    }
  }

  private func id(for control: UISwitch) -> String? {
    controls.first(where: { $0.value === control })?.key
  }

  @objc private func valueChanged(_ control: UISwitch) {
    guard let id = id(for: control) else { return }
    channel.invokeMethod("valueChanged", arguments: ["id": id, "value": control.isOn])
  }

  @objc private func interactionStarted(_ control: UISwitch) {
    guard let id = id(for: control), interacting.insert(id).inserted else { return }
    channel.invokeMethod("interactionChanged", arguments: ["id": id, "isInteracting": true])
  }

  @objc private func interactionEnded(_ control: UISwitch) {
    guard let id = id(for: control), interacting.remove(id) != nil else { return }
    channel.invokeMethod("interactionChanged", arguments: ["id": id, "isInteracting": false])
    // A tint-only update must not replay a cached value predating the user's
    // toggle. Deferred fields are independent; later Flutter updates stay authoritative.
    let updateValue = pendingValueChanges.remove(id) != nil
    let updateTint = pendingTintChanges.remove(id) != nil
    guard updateValue || updateTint else { return }
    DispatchQueue.main.async { [weak self, weak control] in
      guard let self = self, let control = control,
        self.controls[id] === control, !self.interacting.contains(id),
        let item = self.latest?.items.first(where: { $0.id == id })
      else { return }
      self.synchronize(control, item: item, updateValue: updateValue, updateTint: updateTint)
    }
  }
}
