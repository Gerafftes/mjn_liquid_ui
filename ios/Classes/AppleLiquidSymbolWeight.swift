import SwiftUI
import UIKit

enum AppleLiquidSymbolWeight {
  static func imageWeight(_ value: String?) -> UIImage.SymbolWeight? {
    switch value {
    case "ultraLight":
      return .ultraLight
    case "thin":
      return .thin
    case "light":
      return .light
    case "regular":
      return .regular
    case "medium":
      return .medium
    case "semibold":
      return .semibold
    case "bold":
      return .bold
    case "heavy":
      return .heavy
    case "black":
      return .black
    default:
      return nil
    }
  }

  static func fontWeight(_ value: String?) -> Font.Weight? {
    switch value {
    case "ultraLight":
      return .ultraLight
    case "thin":
      return .thin
    case "light":
      return .light
    case "regular":
      return .regular
    case "medium":
      return .medium
    case "semibold":
      return .semibold
    case "bold":
      return .bold
    case "heavy":
      return .heavy
    case "black":
      return .black
    default:
      return nil
    }
  }
}
