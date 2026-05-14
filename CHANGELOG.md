## Unreleased

- Added `AppleLiquidSheetController` for showing, dismissing, and tracking the
  native template sheet.
- Added `AppleLiquidSheet.dismissTemplateSheet()` for dismissing the active
  native template sheet from Dart.

## 0.2.2

- Added the native iOS sheet demo with configurable height and background
  zoom.
- Updated the sheet demo controls to use `AppleLiquidSlider` and
  `AppleLiquidSwitch`.
- Fixed custom sheet detent handling while the keyboard opens and closes.

## 0.2.1

- Fixed the iOS podspec version so CocoaPods reports the published package
  version during `pod install`.

## 0.2.0

- Added optional notification badges for `AppleLiquidTabItem`, including
  numberless dots and text values.
- Added configurable notification badge colors to the native iOS tab bar.
- Updated the example iOS project so simulator builds target iOS simulators.

## 0.1.9

- Fixed an iOS search-tab navigation container that could trigger native tab bar layout constraint warnings.

## 0.1.8

- Reworked the native iOS switch to use `UISwitch` directly instead of a SwiftUI hosting controller.

## 0.1.7

- Changed `AppleLiquidSymbol` to render native SF Symbols as Flutter images instead of platform views.
- Fixed small-symbol compositing artifacts in lists, cards, and page transitions.

## 0.1.6

- Added `AppleLiquidSymbol` for rendering SF Symbols outside the tab bar on iOS.

## 0.1.5

- Added Dart API documentation for exported widgets and configuration objects.

## 0.1.4

- Fixed iOS hot restart handling for native liquid UI platform views.
- Added stable native SwiftUI hosting cleanup for embedded controls.

## 0.1.3

- Fixed the installation snippet for the latest published package version.

## 0.1.2

- Added `selectedTintColor` support for `AppleLiquidTabBar`.

## 0.1.1

- Fixed pub.dev screenshot rendering in the README.
- Removed pre-publish screenshot placeholder text.

## 0.1.0

- Initial public release.
- Added iOS-focused liquid glass UI components.
- Added liquid tab bar.
- Added search tab / search segment support through native SwiftUI `TabRole.search`.
- Added liquid switch.
- Added liquid slider with optional stepped values.
- Added liquid glass surfaces.
- Added example app.
- Added BSD 3-Clause License.
