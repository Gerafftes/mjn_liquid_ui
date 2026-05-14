# mjn_liquid_ui

[![Platform](https://img.shields.io/badge/platform-iOS-lightgrey)](https://flutter.dev)
[![Pub Version](https://img.shields.io/pub/v/mjn_liquid_ui)](https://pub.dev/packages/mjn_liquid_ui)
[![License](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg)](LICENSE)

A Flutter plugin for native-inspired liquid glass UI components, focused on iOS.

`mjn_liquid_ui` embeds iOS SwiftUI/UIKit controls in Flutter through platform
views. It is designed for apps that want a native-feeling Liquid Glass tab bar,
search segment, switch, slider, and glass surface while keeping the Flutter app
structure.

## Features

- Liquid glass tab bar.
- Separate search tab / search segment using native SwiftUI `TabRole.search`.
- Liquid switch.
- Liquid slider with optional stepped values.
- Liquid glass surfaces.
- Native iOS sheet presentation with configurable detent height, toolbar
  controls, search, and background zoom.
- SF Symbols outside the tab bar through native `UIImage(systemName:)` rendering.
- Native iOS-focused implementation using Swift, SwiftUI, and UIKit.
- Flutter fallbacks for unsupported platforms to avoid crashes during development.

## Widgets

| Widget | Description | Controller |
| --- | --- | --- |
| `AppleLiquidTabBar` | Native iOS Liquid Glass tab bar with a dedicated search-role item, tint support, and badges | - |
| `AppleLiquidSwitch` | Native Liquid Glass toggle switch with animated state changes | - |
| `AppleLiquidSlider` | Native Liquid Glass slider with min/max range and optional step support | - |
| `AppleLiquidSymbol` | SF Symbols rendered through native `UIImage(systemName:)` with optional Flutter icon fallback | - |
| `AppleLiquidSurface` | Apply Liquid Glass effects to any Flutter widget | - |
| `AppleLiquidStretch` | Flutter squash and stretch interaction wrapper for glass content | - |
| `AppleLiquidSheet` | Static API for presenting and dismissing native iOS Liquid Glass sheets | `AppleLiquidSheetController` |

## Icon support

`AppleLiquidSymbol` renders standalone SF Symbols by name. For tab icons, pass
SF Symbol names through `AppleLiquidTabItem.systemImage` and optionally
`AppleLiquidTabItem.activeSystemImage`.

| API | Source |
| --- | --- |
| `AppleLiquidSymbol('name')` | Standalone SF Symbol rendered by native iOS |
| `AppleLiquidTabItem(systemImage: 'name')` | SF Symbol for tab bar items |
| `AppleLiquidTabItem(activeSystemImage: 'name')` | Optional selected-state SF Symbol for tab bar items |
| `fallbackIcon: Icons.example` | Flutter `IconData` fallback for unsupported platforms |

## Screenshots

| Liquid Tab Bar | Liquid Switch |
| --- | --- |
| ![Liquid Tab Bar](https://raw.githubusercontent.com/Gerafftes/mjn_liquid_ui/main/screenshots/liquid_tabbar.png) | ![Liquid Switch](https://raw.githubusercontent.com/Gerafftes/mjn_liquid_ui/main/screenshots/liquid_switch.png) |

| Liquid Slider | Liquid Surface |
| --- | --- |
| ![Liquid Slider](https://raw.githubusercontent.com/Gerafftes/mjn_liquid_ui/main/screenshots/liquid_slider.png) | ![Liquid Surface](https://raw.githubusercontent.com/Gerafftes/mjn_liquid_ui/main/screenshots/liquid_surface.png) |

| Liquid Sheet | Liquid Search |
| --- | --- |
| ![Liquid Sheet](https://raw.githubusercontent.com/Gerafftes/mjn_liquid_ui/main/screenshots/liquid_sheet.png) | ![Liquid Search](https://raw.githubusercontent.com/Gerafftes/mjn_liquid_ui/main/screenshots/liquid_search.png) |

## Platform support

| Platform | Support |
| --- | --- |
| iOS | Supported |
| Android | Not officially supported yet |
| Web | Not officially supported yet |
| macOS | Not officially supported yet |
| Windows | Not officially supported yet |
| Linux | Not officially supported yet |

The Dart widgets include simple Flutter fallbacks on unsupported platforms so
apps should not crash during development. These fallbacks are experimental and
are not official Android, web, or desktop support.

## Installation

```yaml
dependencies:
  mjn_liquid_ui: ^0.2.2
```

Then import the package:

```dart
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';
```

## Usage

```dart
AppleLiquidTabBar(
  currentIndex: currentIndex,
  selectedTintColor: const Color(0xFF007AFF),
  onChanged: (int index) {
    setState(() => currentIndex = index);
  },
  items: const <AppleLiquidTabItem>[
    AppleLiquidTabItem(
      title: 'Home',
      systemImage: 'house.fill',
    ),
    AppleLiquidTabItem(
      title: 'Jobs',
      systemImage: 'briefcase.fill',
    ),
    AppleLiquidTabItem(
      title: 'Chat',
      systemImage: 'message.fill',
      notificationDotColor: Color(0xFF007AFF),
      notificationBadgeValue: '3',
    ),
  ],
  searchItem: const AppleLiquidTabItem(
    title: 'Search',
    systemImage: 'magnifyingglass',
    isSearch: true,
  ),
)
```

Use the tab bar as an overlay when page content should continue behind the
native bar:

```dart
Scaffold(
  extendBody: true,
  body: Stack(
    children: <Widget>[
      const Positioned.fill(child: YourPageContent()),
      Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: AppleLiquidTabBar(
          currentIndex: currentIndex,
          onChanged: (int index) {
            setState(() => currentIndex = index);
          },
          items: const <AppleLiquidTabItem>[
            AppleLiquidTabItem(title: 'Home', systemImage: 'house.fill'),
            AppleLiquidTabItem(title: 'Jobs', systemImage: 'briefcase.fill'),
            AppleLiquidTabItem(title: 'Chat', systemImage: 'message.fill'),
          ],
          searchItem: const AppleLiquidTabItem(
            title: 'Search',
            systemImage: 'magnifyingglass',
            isSearch: true,
          ),
        ),
      ),
    ],
  ),
)
```

## Components

### Liquid tab bar

`AppleLiquidTabBar` renders a native iOS SwiftUI `TabView` on iOS. The trailing
`searchItem` is created as a separate native search-role tab.
Use `selectedTintColor` to customize the selected icon and label tint while
keeping the native Liquid Glass tab bar rendering intact.
Set `notificationDotColor` on any `AppleLiquidTabItem` to show a notification
dot on the icon. Add `notificationBadgeValue` to show text inside the badge.

### Liquid switch

```dart
AppleLiquidSwitch(
  value: enabled,
  tintColor: const Color(0xFF14B8A6),
  onChanged: (bool value) {
    setState(() => enabled = value);
  },
)
```

### Liquid slider

```dart
AppleLiquidSlider(
  value: amount,
  min: 0,
  max: 1,
  step: 0.1,
  tintColor: const Color(0xFF8B5CF6),
  onChanged: (double value) {
    setState(() => amount = value);
  },
)
```

Omit `step` for a continuous slider.

### SF Symbols

```dart
const AppleLiquidSymbol(
  'sparkles',
  size: 32,
  color: Color(0xFF0EA5E9),
  fallbackIcon: Icons.auto_awesome_rounded,
  semanticLabel: 'Highlights',
)
```

`AppleLiquidSymbol` renders the provided SF Symbol name natively on iOS and
paints the result as a normal Flutter image. On unsupported platforms it uses
`fallbackIcon` when provided.

### Liquid glass surface

```dart
AppleLiquidSurface(
  height: 160,
  borderRadius: 28,
  clear: true,
  interactive: true,
  deformable: true,
  stretchGestureMode: AppleLiquidStretchGestureMode.gestureDetector,
  child: const Text('Flutter content over native Liquid Glass'),
)
```

Use `deformable: true` for interactive squash and stretch feedback. Use
`AppleLiquidStretchGestureMode.gestureDetector` when the surface contains
buttons or other tappable Flutter children.

### Native sheet

`AppleLiquidSheet` presents a native iOS sheet from Flutter. The current
template sheet uses SwiftUI navigation, native toolbar controls, a bottom search
field, configurable detent height, and optional background zoom on the
presenting page.

```dart
final bool didShow = await AppleLiquidSheet.showTemplateSheet(
  heightFraction: 0.72,
  backgroundZoomScale: 0.94,
);
```

Use `AppleLiquidSheetController` when the calling code needs imperative control
or presentation state:

```dart
final AppleLiquidSheetController sheetController =
    AppleLiquidSheetController(
  heightFraction: 0.72,
  backgroundZoomScale: 0.94,
);

final bool didShow = await sheetController.showTemplateSheet();
await sheetController.dismiss();
```

`heightFraction` controls the presented detent height and `backgroundZoomScale`
controls how far the presenting view scales back while the sheet is open.
The method returns `true` after a native iOS sheet was shown and dismissed. It
returns `false` on unsupported platforms so apps can present their own Flutter
fallback.
The controller exposes `isShowing` and `isShown` for UI state while its
presentation is active.

Use `heightFraction` values between `0.25` and `1.0`. Custom heights are backed
by UIKit sheet detents and the implementation keeps keyboard transitions
separate from detent restoration to avoid search-bar overshoot while typing.

## iOS notes

- The iOS implementation uses Swift, SwiftUI, UIKit, and Flutter platform views.
- The tab bar's search segment is implemented with native SwiftUI
  `Tab(..., role: .search)`.
- SF Symbols names are passed through `systemImage` for tab items and through
  `AppleLiquidSymbol.name` for standalone symbols.
- Liquid Glass appearance depends on the iOS and Xcode versions used to build
  and run the app. Unsupported iOS versions may display a simpler fallback
  surface.

## Limitations

- iOS is the only officially supported platform for this release.
- Android, web, and desktop are not officially supported yet.
- Unsupported-platform fallbacks are intentionally simple and experimental.
- The plugin does not provide an Android native implementation yet.
- The search tab is a native search-role segment; app-specific search UI should
  be implemented by your Flutter page content.

## Example

Run the bundled example app on an iOS simulator:

```sh
cd example
flutter run -d <ios-simulator-id>
```

The example demonstrates the liquid tab bar, standalone SF Symbols, search
segment, switch, slider, and liquid glass surface.

## License

This package is licensed under the BSD 3-Clause License. See [LICENSE](LICENSE).
