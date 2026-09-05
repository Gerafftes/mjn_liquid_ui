import CoreGraphics
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
  static let fallback = AppleLiquidSliderConfiguration(
    value: 0,
    min: 0,
    max: 1,
    step: nil,
    tintColor: nil
  )

  let value: Double
  let min: Double
  let max: Double
  let step: Double?
  let tintColor: Int?

  init?(arguments: Any?) {
    let dictionary = arguments as? [String: Any] ?? [:]
    let minValue: Double
    if let rawMin = dictionary["min"] {
      guard let parsedMin = Self.finiteDoubleValue(rawMin) else {
        return nil
      }
      minValue = parsedMin
    } else {
      minValue = 0
    }

    let maxValue: Double
    if let rawMax = dictionary["max"] {
      guard let parsedMax = Self.finiteDoubleValue(rawMax) else {
        return nil
      }
      maxValue = parsedMax
    } else {
      maxValue = 1
    }

    guard minValue < maxValue else {
      return nil
    }

    let sliderValue: Double
    if let rawValue = dictionary["value"] {
      guard let parsedValue = Self.finiteDoubleValue(rawValue) else {
        return nil
      }
      sliderValue = parsedValue
    } else {
      sliderValue = minValue
    }

    let sliderStep: Double?
    if let rawStep = dictionary["step"], !(rawStep is NSNull) {
      guard let parsedStep = Self.finiteDoubleValue(rawStep),
        parsedStep > 0,
        parsedStep <= maxValue - minValue
      else {
        return nil
      }
      sliderStep = parsedStep
    } else {
      sliderStep = nil
    }

    self.init(
      value: sliderValue,
      min: minValue,
      max: maxValue,
      step: sliderStep,
      tintColor: AppleLiquidTabbarConfiguration.intValue(
        dictionary["tintColor"]
      )
    )
  }

  private init(
    value: Double,
    min: Double,
    max: Double,
    step: Double?,
    tintColor: Int?
  ) {
    self.value = value
    self.min = min
    self.max = max
    self.step = step
    self.tintColor = tintColor
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

  private static func finiteDoubleValue(_ value: Any?) -> Double? {
    guard let doubleValue = doubleValue(value), doubleValue.isFinite else {
      return nil
    }

    return doubleValue
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

struct AppleLiquidSymbolConfiguration {
  static let maxPointSize: CGFloat = 512
  static let maxScale: CGFloat = 4
  static let maxPixelDimension: CGFloat = 2048

  let name: String
  let pointSize: CGFloat
  let scale: CGFloat
  let tintColor: Int?
  let weight: String?

  init?(arguments: Any?) {
    let dictionary = arguments as? [String: Any] ?? [:]
    name = dictionary["name"] as? String ?? "circle"
    let parsedPointSize: CGFloat
    if let rawSize = dictionary["size"] {
      guard let doubleSize = AppleLiquidSliderConfiguration.doubleValue(rawSize),
        doubleSize.isFinite
      else {
        return nil
      }
      parsedPointSize = CGFloat(doubleSize)
    } else {
      parsedPointSize = 24
    }

    let parsedScale: CGFloat
    if let rawScale = dictionary["scale"] {
      guard let doubleScale = AppleLiquidSliderConfiguration.doubleValue(rawScale),
        doubleScale.isFinite
      else {
        return nil
      }
      parsedScale = CGFloat(doubleScale)
    } else {
      parsedScale = 1
    }

    guard parsedPointSize > 0,
      parsedPointSize <= Self.maxPointSize,
      parsedScale > 0,
      parsedScale <= Self.maxScale,
      parsedPointSize * parsedScale <= Self.maxPixelDimension
    else {
      return nil
    }

    pointSize = parsedPointSize
    scale = parsedScale
    tintColor = AppleLiquidTabbarConfiguration.intValue(dictionary["color"])
    weight = dictionary["weight"] as? String
  }
}
