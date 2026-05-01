# mjn_liquid_ui

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
- SF Symbols outside the tab bar through native `UIImage(systemName:)`.
- Native iOS-focused implementation using Swift, SwiftUI, and UIKit.
- Flutter fallbacks for unsupported platforms to avoid crashes during development.

## Screenshots

| Liquid Tab Bar | Liquid Switch |
| --- | --- |
| ![Liquid Tab Bar](https://raw.githubusercontent.com/Gerafftes/mjn_liquid_ui/main/screenshots/liquid_tabbar.png) | ![Liquid Switch](https://raw.githubusercontent.com/Gerafftes/mjn_liquid_ui/main/screenshots/liquid_switch.png) |

| Liquid Slider | Liquid Surface |
| --- | --- |
| ![Liquid Slider](https://raw.githubusercontent.com/Gerafftes/mjn_liquid_ui/main/screenshots/liquid_slider.png) | ![Liquid Surface](https://raw.githubusercontent.com/Gerafftes/mjn_liquid_ui/main/screenshots/liquid_surface.png) |

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
  mjn_liquid_ui: ^0.1.6
```

Then import the package:

```dart
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';
```

## Usage

```dart
AppleLiquidTabBar(
  currentIndex: currentIndex,
  selectedTintColor: const Color(0xFF0EA5E9),
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

`AppleLiquidSymbol` renders the provided SF Symbol name natively on iOS. On
unsupported platforms it uses `fallbackIcon` when provided.

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
