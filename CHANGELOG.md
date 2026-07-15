## 0.2.22

- Added configurable absolute spacing between native section titles and their
  content through `AppleLiquidSheetSection.titleSpacing`, including a true
  zero-gap layout.

## 0.2.21

- Fixed exact button spacing to render transparent spacer rows inside existing
  native form sections without introducing extra header or footer margins.
- Aligned content-sized sheet detents with the fully rendered native form so a
  final button remains visible without unintended scrolling.

## 0.2.20

- Added independent native button-row top and bottom insets through
  `AppleLiquidSheetButtonStyle.rowTopInset` and `rowBottomInset`.
- Made zero button edge insets remove automatic section and bottom content
  spacing on iOS 17 and newer.
- Kept the native button border fully visible when a row inset is zero.

## 0.2.19

- Added optional segmented-row horizontal form insets through
  `AppleLiquidSheetSegmentedStyle.rowHorizontalInset`.

## 0.2.18

- Added configurable native section-header colors through
  `AppleLiquidSheetSection.titleColor`.
- Added page-level native form section spacing through
  `AppleLiquidSheetContent.sectionSpacing`.

## 0.2.17

- Added configurable multi-picker selection-summary placement through
  `AppleLiquidSheetMultiPickerLabelPlacement`.
- Added per-option and selection-dependent multi-picker SF Symbols through
  `selectionSystemImages`.

## 0.2.16

- Added per-section native form background, border, visibility, and corner
  styling through `AppleLiquidSheetSection`.
- Fixed custom corner radii being clipped by the native SwiftUI form radius.

## 0.2.15

- Added `AppleLiquidSheetContent.showsSectionBackgrounds` to optionally remove
  the native SwiftUI form section boxes.
- Added `AppleLiquidSheetRow.multiPicker` with initial selections and Dart
  callbacks for native multi-selection changes.

## 0.2.14

- Added `AppleLiquidSheetRow.button` for native full-width action buttons with
  SF Symbols, accent tinting, and system press feedback.
- Added optional slider value suffixes for native sheet rows.
- Added Dart callbacks and optional sheet dismissal for native sheet buttons.
- Added `AppleLiquidSheetButtonStyle` for configurable colors, dimensions,
  typography, alignment, form-row layout, and press feedback.
- Rendered outlined sheet buttons as transparent standalone form groups with
  safe horizontal insets to avoid stacked containers and clipped edges.

## 0.2.13

- Fixed pub.dev and README screenshot assets so component screenshots are
  smaller and show distinct Liquid Tab Bar, Switch, Slider, Surface, Sheet,
  Toast, and Search states.

## 0.2.12

- Added `AppleLiquidSheetSliderValuePlacement.besideTrack` so native sheet
  slider values can be displayed to the right of the slider track.
- Added optional `valueLabel` and `valueLabelBuilder` support to
  `AppleLiquidSlider` for standalone slider value labels.
- Added `AppleLiquidToast` for native iOS bottom toasts with SF Symbols and
  optional action callbacks.
- Refreshed pub.dev and README screenshots, including a new Liquid Glass toast
  screenshot.

## 0.2.11

- Reworked native iOS sheet presentation to use a direct system page sheet
  while preserving the custom medium and expanded detents.
- Added `AppleLiquidSheetBackgroundInteractionGuard` for configurable Flutter
  background interaction locking while a native sheet is active.
- Added `scrollContext` support for stopping active background scroll momentum
  before presenting a native sheet.
- Fixed background scroll passthrough and scroll-position resets while opening
  native sheets.
- Removed sheet and switch debug logging from normal debug runs.

## 0.2.10

- Added configurable native sheet toolbar actions, including optional leading
  cancel/close buttons and customizable trailing confirm buttons.
- Added icon-only toolbar actions plus foreground and background colors for
  native sheet toolbar buttons.

## 0.2.9

- Added native two-option button rows to `AppleLiquidSheetContent` via
  `AppleLiquidSheetRow.segmented`, with separate rounded buttons and local
  SwiftUI sheet state.
- Added per-row `AppleLiquidSheetSegmentedStyle` customization for colors,
  dimensions, typography, spacing, borders, text scaling, and press feedback.
- Added configurable segmented-row selection transitions that animate each
  button's selected state, including duration, curve, spring damping, selected
  shadow styling, and an option to disable the animation.

## 0.2.8

- Added native slider rows to `AppleLiquidSheetContent` via
  `AppleLiquidSheetRow.slider`, including min/max, optional step, tint color,
  and local SwiftUI sheet state.
- Isolated sheet slider tracking from the sheet drag gesture so touching or
  dragging a slider does not trigger the sheet background zoom interaction.
- Updated the built-in sheet slider examples to use continuous sliders when
  `step` is omitted.
- Added a second higher sheet detent for oversized native sheet content while
  keeping smaller sheets content-sized.
- Added per-page `AppleLiquidSheetDetents` so root and nested sheet content can
  define their own initial and expanded detent heights.

## 0.2.7

- Blocked touches from passing through the native sheet presentation to Flutter
  content behind it, including the top safe-area gap while the background is
  zoomed.
- Prevented duplicate show requests from opening fallback sheets while a native
  sheet is already active.

## 0.2.6

- Added customizable native sheet content through `AppleLiquidSheetContent`,
  `AppleLiquidSheetSection`, and `AppleLiquidSheetRow`.
- Added `AppleLiquidSheet.showSheet()` and `AppleLiquidSheetController.showSheet()`
  while keeping the previous template sheet methods as compatibility aliases.
- Changed the native sheet to use a content-sized detent instead of expanding
  to `.large`.

## 0.2.5

- Rebuilt the native sheet presentation around a Liquid Glass SwiftUI
  `NavigationStack` and `Form` settings sheet.
- Removed the sheet search bar option and related native search debug helpers.
- Updated the native sheet background to extend through the bottom safe area.

## 0.2.4

- Added configurable SF Symbol weights for standalone symbols and tab icons.

## 0.2.3

- Added `AppleLiquidSheetController` for showing, dismissing, and tracking the
  native template sheet.
- Added `AppleLiquidSheet.dismissTemplateSheet()` for dismissing the active
  native template sheet from Dart.
- Added README badges and the widget/controller overview.

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
