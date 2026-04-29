import SwiftUI
import UIKit

extension Color {
  init?(appleLiquidARGB value: Int?) {
    guard let value else {
      return nil
    }

    let unsignedValue = UInt32(truncatingIfNeeded: value)
    let alpha = Double((unsignedValue >> 24) & 0xFF) / 255
    let red = Double((unsignedValue >> 16) & 0xFF) / 255
    let green = Double((unsignedValue >> 8) & 0xFF) / 255
    let blue = Double(unsignedValue & 0xFF) / 255

    self.init(.sRGB, red: red, green: green, blue: blue, opacity: alpha)
  }
}

extension UIColor {
  convenience init?(appleLiquidARGB value: Int?) {
    guard let value else {
      return nil
    }

    let unsignedValue = UInt32(truncatingIfNeeded: value)
    let alpha = CGFloat((unsignedValue >> 24) & 0xFF) / 255
    let red = CGFloat((unsignedValue >> 16) & 0xFF) / 255
    let green = CGFloat((unsignedValue >> 8) & 0xFF) / 255
    let blue = CGFloat(unsignedValue & 0xFF) / 255

    self.init(red: red, green: green, blue: blue, alpha: alpha)
  }
}

extension View {
  @ViewBuilder
  func appleLiquidControlTint(_ tintColor: Color?) -> some View {
    if #available(iOS 16.0, *) {
      tint(tintColor)
    } else {
      accentColor(tintColor)
    }
  }
}
