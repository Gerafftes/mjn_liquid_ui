# mjn_liquid_ui

[![Pub Version](https://img.shields.io/pub/v/mjn_liquid_ui)](https://pub.dev/packages/mjn_liquid_ui)
[![License](https://img.shields.io/badge/license-BSD--3--Clause-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-iOS-lightgrey)](https://flutter.dev)

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
- Native iOS sheet presentation with a Liquid Glass `NavigationStack` + `Form`
  sheet, customizable Dart-provided form content, content-sized detents,
  optional background color, and background zoom.
- Native iOS bottom toasts with Liquid Glass chrome, SF Symbols, and optional
  action callbacks.
- Optional, configurable Flutter background interaction guard for native sheets.
- SF Symbols outside the tab bar through native `UIImage(systemName:)` rendering.
- Native iOS-focused implementation using Swift, SwiftUI, and UIKit.
- Flutter fallbacks for unsupported platforms to avoid crashes during development.

## Widgets

| Widget | Description | Controller |
| --- | --- | --- |
| `AppleLiquidTabBar` | Native iOS Liquid Glass tab bar with a dedicated search-role item, tint support, and badges | - |
| `AppleLiquidSwitch` | Native Liquid Glass toggle switch with animated state changes | - |
| `AppleLiquidSlider` | Native Liquid Glass slider with min/max range, optional step support, and optional trailing value labels | - |
| `AppleLiquidSymbol` | SF Symbols rendered through native `UIImage(systemName:)` with optional Flutter icon fallback | - |
| `AppleLiquidSurface` | Apply Liquid Glass effects to any Flutter widget | - |
| `AppleLiquidStretch` | Flutter squash and stretch interaction wrapper for glass content | - |
| `AppleLiquidSheet` | Static API for presenting and dismissing native iOS Liquid Glass sheets | `AppleLiquidSheetController` |
| `AppleLiquidSheetBackgroundInteractionGuard` | Optional Flutter background interaction guard while a native sheet is active | `AppleLiquidSheetController` |
| `AppleLiquidToast` | Static API for native iOS Liquid Glass bottom toasts | - |

## Icon support

`AppleLiquidSymbol` renders standalone SF Symbols by name. Use
`AppleLiquidSymbolWeight` to select SF Symbol stroke weights such as
`regular`, `semibold`, or `bold`. For tab icons, pass SF Symbol names through
`AppleLiquidTabItem.systemImage` and optionally
`AppleLiquidTabItem.activeSystemImage`; use `symbolWeight` and
`activeSymbolWeight` when individual tab icons need different weights.

| API | Source |
| --- | --- |
| `AppleLiquidSymbol('name')` | Standalone SF Symbol rendered by native iOS |
| `AppleLiquidSymbol(weight: AppleLiquidSymbolWeight.bold)` | Optional SF Symbol stroke weight |
| `AppleLiquidTabItem(systemImage: 'name')` | SF Symbol for tab bar items |
| `AppleLiquidTabItem(activeSystemImage: 'name')` | Optional selected-state SF Symbol for tab bar items |
| `AppleLiquidTabItem(symbolWeight: AppleLiquidSymbolWeight.regular)` | Optional inactive tab icon weight |
| `AppleLiquidTabItem(activeSymbolWeight: AppleLiquidSymbolWeight.bold)` | Optional selected tab icon weight |
| `fallbackIcon: Icons.example` | Flutter `IconData` fallback for unsupported platforms |

## Screenshots

| Liquid Tab Bar | Liquid Switch |
| --- | --- |
| <img src="https://raw.githubusercontent.com/Gerafftes/mjn_liquid_ui/main/screenshots/liquid_tabbar.png" alt="Liquid Tab Bar" width="260"> | <img src="https://raw.githubusercontent.com/Gerafftes/mjn_liquid_ui/main/screenshots/liquid_switch.png" alt="Liquid Switch" width="260"> |

| Liquid Slider | Liquid Surface |
| --- | --- |
| <img src="https://raw.githubusercontent.com/Gerafftes/mjn_liquid_ui/main/screenshots/liquid_slider.png" alt="Liquid Slider" width="260"> | <img src="https://raw.githubusercontent.com/Gerafftes/mjn_liquid_ui/main/screenshots/liquid_surface.png" alt="Liquid Surface" width="260"> |

| Liquid Sheet | Liquid Toast |
| --- | --- |
| <img src="https://raw.githubusercontent.com/Gerafftes/mjn_liquid_ui/main/screenshots/liquid_sheet.png" alt="Liquid Sheet" width="260"> | <img src="https://raw.githubusercontent.com/Gerafftes/mjn_liquid_ui/main/screenshots/liquid_toast.png" alt="Liquid Toast" width="260"> |

| Search Role Tab |
| --- |
| <img src="https://raw.githubusercontent.com/Gerafftes/mjn_liquid_ui/main/screenshots/liquid_search.png" alt="Search Role Tab" width="360"> |

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
  mjn_liquid_ui: ^0.2.22
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
      symbolWeight: AppleLiquidSymbolWeight.regular,
      activeSymbolWeight: AppleLiquidSymbolWeight.bold,
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
Use `symbolWeight` and `activeSymbolWeight` on `AppleLiquidTabItem` to tune the
normal and selected SF Symbol stroke weights for individual icons.
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
  valueLabelBuilder: (BuildContext context, double value) {
    return Text('${(value * 100).round()}%');
  },
  onChanged: (double value) {
    setState(() => amount = value);
  },
)
```

Omit `step` for a continuous slider. Use `valueLabel` or
`valueLabelBuilder` to render a value to the right of the slider track; without
one, the standalone slider keeps the previous slider-only layout.

### SF Symbols

```dart
const AppleLiquidSymbol(
  'sparkles',
  size: 32,
  color: Color(0xFF0EA5E9),
  weight: AppleLiquidSymbolWeight.semibold,
  fallbackIcon: Icons.auto_awesome_rounded,
  semanticLabel: 'Highlights',
)
```

`AppleLiquidSymbol` renders the provided SF Symbol name natively on iOS and
paints the result as a normal Flutter image. On unsupported platforms it uses
`fallbackIcon` when provided. The optional `weight` parameter supports
`ultraLight`, `thin`, `light`, `regular`, `medium`, `semibold`, `bold`,
`heavy`, and `black`.

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

### Native toast

```dart
await AppleLiquidToast.show(
  title: 'Added to Cart',
  systemImage: 'cart.fill',
  action: AppleLiquidToastAction(
    title: 'Undo',
    tintColor: const Color(0xFFFF9500),
    dismissesToast: false,
    onPressed: () {
      AppleLiquidToast.show(
        title: 'Removed From Cart',
        systemImage: 'checkmark.circle.fill',
      );
    },
  ),
);
```

`AppleLiquidToast.show` returns `false` when no native iOS overlay can be
attached, including unsupported platforms. Native toasts require iOS 16 or
newer; iOS 26 uses the system Liquid Glass effect, while older supported iOS
versions use a native rounded fallback.

### Native sheet

`AppleLiquidSheet` presents a native iOS sheet from Flutter. The sheet renders a
Liquid Glass SwiftUI `NavigationStack` with `Form` content, a content-sized
detent, optional background zoom on the presenting page, and configurable
toolbar actions to dismiss.

Pass `AppleLiquidSheetContent` to customize the native form. The content model
supports sections plus text, value, button, toggle, picker, multi-picker,
segmented, slider, text-field, and nested navigation rows. Toggle, picker,
multi-picker, segmented, slider, and text-field state stays local to the native
sheet while it is presented. Omit `step` on `AppleLiquidSheetRow.slider` for a
continuous slider. Set
`valuePlacement` to `AppleLiquidSheetSliderValuePlacement.besideTrack` to show
the value beside the slider track instead of above it. Pass `valueSuffix` to
append a unit to the rendered value.

For multi-pickers, the selection summary appears at the trailing edge by
default. Set `selectionLabelPlacement` to
`AppleLiquidSheetMultiPickerLabelPlacement.primary` to use the current
selection as the primary row label while keeping `title` for the pushed picker
page:

```dart
const AppleLiquidSheetRow.multiPicker(
  title: 'Kategorie',
  options: <String>['Alle', 'Garten', 'Umzug'],
  selectedOptions: <String>['Alle'],
  systemImage: 'square.grid.2x2.fill',
  selectionSystemImages: <String, String>{
    'Alle': 'square.grid.2x2.fill',
    'Garten': 'leaf.fill',
    'Umzug': 'shippingbox.fill',
  },
  selectionLabelPlacement:
      AppleLiquidSheetMultiPickerLabelPlacement.primary,
);
```

`selectionSystemImages` displays each mapped SF Symbol beside its option and
changes the main-row icon immediately when exactly one matching option is
selected. For multiple selections, or when no mapping exists, `systemImage`
remains the main-row fallback.

| API | Purpose |
| --- | --- |
| `AppleLiquidSheetContent` | One native sheet page with title, optional detents, section backgrounds, section spacing, and sections |
| `AppleLiquidSheetToolbarAction` | Optional leading or trailing toolbar button with text and/or SF Symbol |
| `AppleLiquidSheetSection` | Optional section header with configurable color and content spacing, native form rows, and per-section background, border, and corner styling |
| `AppleLiquidSheetRow.text` | Title and optional subtitle |
| `AppleLiquidSheetRow.value` | Native label-value row |
| `AppleLiquidSheetRow.toggle` | Native SwiftUI toggle with local sheet state |
| `AppleLiquidSheetRow.picker` | Native picker row with local sheet state |
| `AppleLiquidSheetRow.multiPicker` | Native multi-selection picker with initial selections, configurable summary placement, and a Dart change callback |
| `AppleLiquidSheetRow.segmented` | Two separate, equal-width native buttons with local selection state |
| `AppleLiquidSheetSegmentedStyle` | Per-row colors, dimensions, typography, spacing, borders, shadows, press feedback, and selection transitions |
| `AppleLiquidSheetRow.button` | Full-width native action button with a Dart callback, optional sheet dismissal, accessibility label, and configurable enabled state |
| `AppleLiquidSheetButtonStyle` | Button colors, dimensions, typography, alignment, form-row insets/background/separator, and press feedback |
| `AppleLiquidSheetRow.slider` | Native slider row with local sheet state, optional `step`, min/max, tint, and value placement |
| `AppleLiquidSheetRow.textField` | Native text field row with local sheet state |
| `AppleLiquidSheetRow.navigation` | Pushes another `AppleLiquidSheetContent` page |

`AppleLiquidSheetDetents` can be set on every `AppleLiquidSheetContent`, not
only the root sheet. Heights are native iOS points:

```dart
const AppleLiquidSheetContent(
  title: 'Release',
  detents: AppleLiquidSheetDetents(
    initialHeight: 300,
    expandedHeight: 520,
  ),
  sections: <AppleLiquidSheetSection>[
    AppleLiquidSheetSection(
      rows: <AppleLiquidSheetRow>[
        AppleLiquidSheetRow.value(title: 'Detents', value: 'Two-step'),
      ],
    ),
  ],
)
```

```dart
void openMap() {
  // App-specific navigation or state update.
}

final AppleLiquidSheetContent content = AppleLiquidSheetContent(
  title: 'Project',
  showsSectionBackgrounds: false,
  sectionSpacing: 8,
  doneSemanticLabel: 'Close sheet',
  leadingAction: AppleLiquidSheetToolbarAction(
    systemImage: 'xmark',
    semanticLabel: 'Dismiss sheet',
    foregroundColor: Color(0xFFFF9F0A),
  ),
  trailingAction: AppleLiquidSheetToolbarAction(
    title: 'Apply',
    systemImage: 'checkmark',
    semanticLabel: 'Apply changes',
    foregroundColor: Color(0xFFFFFFFF),
    backgroundColor: Color(0xFF34C759),
  ),
  detents: AppleLiquidSheetDetents(
    initialHeight: 420,
    expandedHeight: 640,
  ),
  sections: <AppleLiquidSheetSection>[
    AppleLiquidSheetSection(
      title: 'Overview',
      titleColor: Color(0xFFE6E6E6),
      showsBackground: true,
      backgroundColor: Color(0xFF1A1A1A),
      borderColor: Color(0xFF2C2C2E),
      cornerRadius: 14,
      rows: <AppleLiquidSheetRow>[
        AppleLiquidSheetRow.value(
          title: 'Package',
          value: 'mjn_liquid_ui',
          systemImage: 'shippingbox.fill',
        ),
        AppleLiquidSheetRow.toggle(
          title: 'Background zoom',
          value: true,
        ),
        AppleLiquidSheetRow.picker(
          title: 'Theme',
          options: <String>['Auto', 'Light', 'Dark'],
          selectedOption: 'Auto',
        ),
        AppleLiquidSheetRow.segmented(
          title: 'Layout',
          firstOption: 'List',
          secondOption: 'Grid',
          selectedOption: 'List',
        ),
        AppleLiquidSheetRow.button(
          title: 'Show on map',
          systemImage: 'map',
          tintColor: Color(0xFF007AFF),
          semanticLabel: 'Open map view',
          dismissesSheet: true,
          style: const AppleLiquidSheetButtonStyle(
            rowTopInset: 12,
            rowBottomInset: 0,
            cornerRadius: 12,
          ),
          onPressed: openMap,
        ),
        AppleLiquidSheetRow.slider(
          title: 'Intensity',
          value: 0.72,
          valueSuffix: 'x',
          tintColor: Color(0xFF0A84FF),
          valuePlacement: AppleLiquidSheetSliderValuePlacement.besideTrack,
        ),
        AppleLiquidSheetRow.navigation(
          title: 'Details',
          content: AppleLiquidSheetContent(
            title: 'Details',
            detents: AppleLiquidSheetDetents(
              initialHeight: 300,
              expandedHeight: 520,
            ),
            sections: <AppleLiquidSheetSection>[
              AppleLiquidSheetSection(
                rows: <AppleLiquidSheetRow>[
                  AppleLiquidSheetRow.text(
                    title: 'Rendered natively',
                    subtitle: 'This page is a SwiftUI Form pushed from Dart.',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  ],
);

final bool didShow = await AppleLiquidSheet.showSheet(
  backgroundZoomScale: 0.94,
  sheetColor: const Color(0xFFEAF3FF),
  content: content,
);
```

Sheet buttons do not contain app-specific behavior. `onPressed` is registered
for the active presentation and invoked in Dart when the native SwiftUI button
is tapped. `dismissesSheet` controls whether iOS closes the sheet after the
callback. Omit `style` for the blue outlined default, or pass
`AppleLiquidSheetButtonStyle` to configure colors, sizing, typography,
alignment, row insets, the form background and separator, disabled appearance,
and press feedback.

### Button row spacing

`rowTopInset` and `rowBottomInset` override the corresponding side of
`rowVerticalInset`. On iOS 17 and newer they describe the complete distance to
adjacent native form content. A value of `0` therefore adds no section gap:

```dart
AppleLiquidSheetContent(
  sectionSpacing: 8,
  sections: <AppleLiquidSheetSection>[
    AppleLiquidSheetSection(
      rows: <AppleLiquidSheetRow>[
        AppleLiquidSheetRow.button(
          title: 'Show on map',
          systemImage: 'map.fill',
          style: const AppleLiquidSheetButtonStyle(
            rowTopInset: 12,
            rowBottomInset: 0,
          ),
          onPressed: openMap,
        ),
      ],
    ),
    const AppleLiquidSheetSection(
      title: 'Category',
      rows: <AppleLiquidSheetRow>[
        AppleLiquidSheetRow.text(title: 'Garden'),
      ],
    ),
  ],
);
```

Here the automatic space between the button and the `Category` section is
removed, even though the other section boundaries continue to use
`sectionSpacing: 8`. The section header keeps only its own intrinsic text
height. If the button is the final row of the final section,
`rowBottomInset: 0` also removes the form's automatic bottom content margin.

In exact button-spacing mode, non-zero gaps are rendered as transparent rows at
the end of the preceding native `Section`. No additional `Section` is created,
so SwiftUI does not add another header or footer margin. The content-sized
detent includes the rendered section headers, rows, gaps, and sheet chrome up to
the final button row.

If only `rowVerticalInset` is set, it remains the fallback for both sides. On
iOS 16, SwiftUI keeps its native inter-section and bottom form spacing because
the required per-list spacing APIs are available from iOS 17.

`AppleLiquidSheetRow.segmented` requires exactly two distinct, non-empty
options. It renders them as separate, equal-width rounded buttons. Keep both
labels short so they fit comfortably next to each other.

Pass `AppleLiquidSheetSegmentedStyle` to customize colors, dimensions,
typography, spacing, borders, shadows, text scaling, press feedback, and the
selection transition for each row:

```dart
AppleLiquidSheetRow.segmented(
  title: 'Sort by',
  subtitle: 'Choose the result order',
  firstOption: 'Newest',
  secondOption: 'Oldest',
  selectedOption: 'Newest',
  style: const AppleLiquidSheetSegmentedStyle(
    selectedBackgroundColor: Color(0x2634C759),
    unselectedBackgroundColor: Color(0xFFE5E5EA),
    selectedTextColor: Color(0xFF34C759),
    unselectedTextColor: Color(0xFF1C1C1E),
    selectedBorderColor: Color(0x9934C759),
    unselectedBorderColor: Color(0x338E8E93),
    selectedShadowColor: Color(0x0AFFFFFF),
    titleColor: Color(0xFF111111),
    subtitleColor: Color(0xFF666666),
    buttonHeight: 50,
    cornerRadius: 16,
    buttonSpacing: 14,
    contentSpacing: 12,
    verticalPadding: 8,
    rowHorizontalInset: 8,
    borderWidth: 1,
    selectedShadowRadius: 8,
    selectedShadowOffsetX: 0,
    selectedShadowOffsetY: 2,
    titleFontSize: 18,
    subtitleFontSize: 13,
    buttonFontSize: 17,
    titleFontWeight: AppleLiquidSheetSegmentedFontWeight.bold,
    subtitleFontWeight: AppleLiquidSheetSegmentedFontWeight.regular,
    buttonFontWeight: AppleLiquidSheetSegmentedFontWeight.semibold,
    minimumTextScaleFactor: 0.7,
    pressedScale: 0.97,
    pressedOpacity: 0.82,
    pressAnimationDuration: 0.14,
    selectionAnimationEnabled: true,
    selectionAnimationCurve: AppleLiquidSheetSegmentedAnimationCurve.easeInOut,
    selectionAnimationDuration: 0.15,
  ),
)
```

Leave individual color or font-size values null to retain adaptive native iOS
colors and Dynamic Type sizing. Set `borderWidth` to `0` for borderless
buttons. Set `selectionAnimationEnabled` to `false` or
`selectionAnimationDuration` to `0` when the selected state should change
without a transition.

Use `AppleLiquidSheetController` when the calling code needs imperative control
or presentation state:

```dart
final AppleLiquidSheetController sheetController =
    AppleLiquidSheetController(
  backgroundZoomScale: 0.94,
  sheetColor: null,
  content: content,
);

final bool didShow = await sheetController.showSheet();
await sheetController.dismiss();
```

Wrap Flutter content behind the native sheet with
`AppleLiquidSheetBackgroundInteractionGuard` when the app wants the plugin to
manage background interaction while the sheet is active:

```dart
AppleLiquidSheetBackgroundInteractionGuard(
  controller: sheetController,
  absorbPointers: true,
  lockScrolling: true,
  lockedScrollPhysics: const NeverScrollableScrollPhysics(),
  child: const YourPageContent(),
)
```

The guard is optional and configurable. Set `absorbPointers` or `lockScrolling`
to `false` to keep those behaviors under app control, provide a custom
`lockedScrollPhysics`, or use `builder` to react to the active sheet state with
app-specific UI.

Pass `scrollContext` from inside the presenting scrollable when calling
`showSheet` to stop active fling momentum before the native sheet opens:

```dart
await sheetController.showSheet(scrollContext: context);
```

`backgroundZoomScale` controls how far the presenting view scales back while
the sheet is open. Set `sheetColor` to force a specific sheet background color;
leave it null to use the native Liquid Glass/system presentation background.
The method returns `true` after a native iOS sheet was shown and dismissed. It
returns `false` on unsupported platforms so apps can present their own Flutter
fallback.
Repeated show calls return `true` without opening another sheet so fallback code
does not stack a second presentation.
The controller exposes `isShowing` and `isShown` for UI state while its
presentation is active.

Set `showsSectionBackgrounds: false` on an `AppleLiquidSheetContent` page to
remove the rounded native SwiftUI section boxes while keeping the form rows and
controls. The option can be configured independently for nested pages. Each
`AppleLiquidSheetSection` can inherit that setting or override it with
`showsBackground`, `titleColor`, `titleSpacing`, `backgroundColor`,
`borderColor`, and `cornerRadius`.
These options work with every supported sheet row type. To style only one
element, place that row in its own `AppleLiquidSheetSection`, as shown by the
`Label` field in the example app.

Use `titleSpacing` to set the absolute distance between a section's native title
and first content row. The value is measured in native iOS points. Set it to `0`
to remove the gap completely, or omit it to keep SwiftUI's system spacing:

```dart
const AppleLiquidSheetSection(
  title: 'Kategorie',
  titleColor: Color(0xFFE6E6E6),
  titleSpacing: 0,
  rows: <AppleLiquidSheetRow>[
    AppleLiquidSheetRow.text(title: 'Garten'),
  ],
)
```

Set `sectionSpacing` on an `AppleLiquidSheetContent` page to control the native
vertical distance between its form sections. When omitted, SwiftUI keeps its
system spacing. Custom section spacing is applied on iOS 17 and newer. The
example app demonstrates `8` points on the main sheet page and `24` points on
the nested Release page.

```dart
const AppleLiquidSheetContent(
  title: 'Main sheet',
  sectionSpacing: 8,
  sections: <AppleLiquidSheetSection>[
    AppleLiquidSheetSection(
      title: 'Overview',
      rows: <AppleLiquidSheetRow>[
        AppleLiquidSheetRow.navigation(
          title: 'Release details',
          content: AppleLiquidSheetContent(
            title: 'Release',
            sectionSpacing: 24,
            sections: <AppleLiquidSheetSection>[
              AppleLiquidSheetSection(
                title: 'Highlights',
                rows: <AppleLiquidSheetRow>[
                  AppleLiquidSheetRow.text(title: 'Native SwiftUI form'),
                ],
              ),
              AppleLiquidSheetSection(
                title: 'Spacing demo',
                rows: <AppleLiquidSheetRow>[
                  AppleLiquidSheetRow.value(
                    title: 'Section spacing',
                    value: '24 pt',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  ],
);
```

The iOS implementation opens at a SwiftUI content-sized sheet detent instead of
expanding straight to `.large`. Pass `AppleLiquidSheetDetents` to any
`AppleLiquidSheetContent` to customize the starting height and optional second
higher height for that page, including nested navigation pages. When no custom
detents are supplied and the estimated active form content is taller than the
normal sheet height, iOS also gets an automatic second higher detent so the user
can pull the sheet up. The form scroll background stays hidden so the Liquid
Glass sheet remains visible behind the form content.
`showTemplateSheet()` and `AppleLiquidSheetController.showTemplateSheet()` are
kept as compatibility aliases for older code.
The earlier bottom search bar option has been removed from the sheet API.

## iOS notes

- The iOS implementation uses Swift, SwiftUI, UIKit, and Flutter platform views.
- The tab bar's search segment is implemented with native SwiftUI
  `Tab(..., role: .search)`.
- SF Symbols names are passed through `systemImage` for tab items and through
  `AppleLiquidSymbol.name` for standalone symbols.
- SF Symbol weights are optional and use native `UIImage.SymbolConfiguration`
  for standalone symbols. Tabbar weights are passed to native tab labels and
  may still be influenced by iOS tab bar styling.
- Liquid Glass appearance depends on the iOS and Xcode versions used to build
  and run the app. Unsupported iOS versions may display a simpler fallback
  surface.
- Changes inside `ios/Classes` are native Swift/SwiftUI changes. Flutter hot
  restart does not recompile those files; stop and rerun the example app so
  Xcode performs an incremental iOS build.

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
segment, switch, slider, liquid glass surface, and native settings sheet.

## License

This package is licensed under the BSD 3-Clause License. See [LICENSE](LICENSE).
