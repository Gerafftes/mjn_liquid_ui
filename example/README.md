# mjn_liquid_ui_example

Demo app for `mjn_liquid_ui` 0.3.1. Its path dependency uses the package in the
parent directory, including toast overflow actions and stack visibility.

Use a Flutter SDK with Dart 3.9.2 or newer (below 4.0.0) and Xcode 26 or newer
with an iOS 26+ SDK. Start an iOS simulator, then run from this directory:

```sh
flutter pub get
flutter devices
flutter run -d <ios-simulator-id>
```

Replace `<ios-simulator-id>` with the simulator ID from `flutter devices`.
Use iOS 26+ to see Liquid Glass and tab bar minimization.

The demo has **Tabs**, **Switch**, **Slider**, and **Surface** tabs. On iOS 18+,
Surface occupies the native SwiftUI `Tab(..., role: .search)` segment with a plus
icon. The demo covers SF Symbols, switches, continuous and stepped sliders,
glass surfaces, concentric rectangles, toast stacking, overflow actions and
visibility, and native sheets with nested form pages.

See the [package README](../README.md) for API examples, feature-specific iOS
requirements, and installation from pub.dev or a local checkout.
