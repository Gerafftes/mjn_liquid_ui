import CoreGraphics
import Foundation

struct AppleLiquidSheetDetentConfiguration {
  static let automatic = AppleLiquidSheetDetentConfiguration(
    initialHeight: nil,
    expandedHeight: nil,
    allowsAutomaticExpansion: true
  )

  let initialHeight: CGFloat?
  let expandedHeight: CGFloat?
  let allowsAutomaticExpansion: Bool

  init(value: Any?) {
    let dictionary = value as? [String: Any] ?? [:]
    self.init(
      initialHeight: Self.height(dictionary["initialHeight"]),
      expandedHeight: Self.height(dictionary["expandedHeight"]),
      allowsAutomaticExpansion: Self.bool(
        dictionary["allowsAutomaticExpansion"],
        defaultValue: true
      )
    )
  }

  private init(
    initialHeight: CGFloat?,
    expandedHeight: CGFloat?,
    allowsAutomaticExpansion: Bool
  ) {
    self.initialHeight = initialHeight
    self.expandedHeight = expandedHeight
    self.allowsAutomaticExpansion = allowsAutomaticExpansion
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
