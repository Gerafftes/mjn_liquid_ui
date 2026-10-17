# mjn_liquid_ui_example

Demo app for `mjn_liquid_ui` 0.3.2. Its path dependency uses the package in the
parent directory, including toast overflow actions and stack visibility.

The example targets iOS only. This release excludes desktop and web UI.
Android fallback code remains in the package for future development, but Android
is untested and unsupported and this example has no Android runner.

Use a Flutter SDK with Dart 3.9.2 or newer (below 4.0.0) and Xcode 26 or newer
with an iOS 26+ SDK. Start an iOS simulator, then run from this directory:

```sh
flutter pub get
flutter devices
flutter run -d <ios-simulator-id>
```

Replace `<ios-simulator-id>` with the simulator ID from `flutter devices`.
Use iOS 26+ to see Liquid Glass and tab bar minimization.

Hosts built with the iOS 27 SDK must adopt the UIScene lifecycle and use a
supported deployment target. This plugin update does not migrate legacy host
runners, including the bundled example configuration.

The demo has **Tabs**, **Switch**, **Slider**, and **Surface** tabs. Surface is
the separate trailing tab with a plus icon. On iOS 27, Xcode 27 / Swift 6.4 builds
use native SwiftUI `TabRole.prominent`; earlier iOS versions and older toolchains
retain the search role. The demo covers SF Symbols, switches, continuous and stepped sliders,
glass surfaces, concentric rectangles, toast stacking, overflow actions and
visibility, and native sheets with nested form pages.

See the [package README](../README.md) for API examples, feature-specific iOS
requirements, and installation from pub.dev or a local checkout.
