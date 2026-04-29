import Foundation

struct AppleLiquidSwitchConfiguration {
  let value: Bool
  let tintColor: Int?

  init(arguments: Any?) {
    let dictionary = arguments as? [String: Any] ?? [:]
    value = AppleLiquidTabbarConfiguration.boolValue(dictionary["value"]) ?? false
    tintColor = AppleLiquidTabbarConfiguration.intValue(dictionary["tintColor"])
  }
}

struct AppleLiquidSliderConfiguration {
  let value: Double
  let min: Double
  let max: Double
  let step: Double?
  let tintColor: Int?

  init(arguments: Any?) {
    let dictionary = arguments as? [String: Any] ?? [:]
    min = Self.doubleValue(dictionary["min"]) ?? 0
    max = Self.doubleValue(dictionary["max"]) ?? 1
    value = Self.doubleValue(dictionary["value"]) ?? min
    step = Self.validStep(Self.doubleValue(dictionary["step"]), min: min, max: max)
    tintColor = AppleLiquidTabbarConfiguration.intValue(dictionary["tintColor"])
  }

  private static func validStep(_ step: Double?, min: Double, max: Double) -> Double? {
    guard let step, step > 0, step <= max - min else {
      return nil
    }

    return step
  }

  static func doubleValue(_ value: Any?) -> Double? {
    if let doubleValue = value as? Double {
      return doubleValue
    }
    if let number = value as? NSNumber {
      return number.doubleValue
    }
    return nil
  }
}

struct AppleLiquidSurfaceConfiguration {
  let borderRadius: Double
  let tintColor: Int?
  let isClear: Bool
  let interactive: Bool

  init(arguments: Any?) {
    let dictionary = arguments as? [String: Any] ?? [:]
    borderRadius = AppleLiquidSliderConfiguration.doubleValue(
      dictionary["borderRadius"]
    ) ?? 28
    tintColor = AppleLiquidTabbarConfiguration.intValue(dictionary["tintColor"])
    isClear = AppleLiquidTabbarConfiguration.boolValue(dictionary["clear"]) ?? false
    interactive = AppleLiquidTabbarConfiguration.boolValue(
      dictionary["interactive"]
    ) ?? false
  }
}
