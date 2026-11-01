# Performance and validation in 0.3.4

These APIs reduce repeated native setup or let applications prepare work before
it is needed. They preserve the existing single-control APIs and defaults.
No physical-device speedup or fixed FPS improvement is claimed.

## Shared native switches

`AppleLiquidSwitchGroup` keeps Flutter labels beside one native switch column.
A nonempty group creates one platform view and one channel, while still creating
one `UISwitch` for each item. IDs must be stable, nonempty, and unique. RTL mirrors
the columns; Android retains adaptive Flutter switches.

Value and tint changes received during a gesture are deferred independently.
A tint-only update cannot replay an old Boolean over the user's new value.
Explicit later Flutter configuration remains authoritative.

Flutter documents the [cost of embedding native iOS views](https://api.flutter.dev/flutter/widgets/UiKitView-class.html)
and the [additional iOS composition work](https://api.flutter.dev/flutter/dart-ui/SceneBuilder/addPlatformView.html).
Fewer embeddings remove that repeated setup; they do not eliminate native
per-control work or guarantee a particular speedup.

## Deferred glass mounting

`AppleLiquidSurface.deferMountUntilRouteTransitionCompletes` defaults to false.
When enabled, it shows a lightweight Flutter decoration while the enclosing
route enters, then creates the native background after the route is current,
its entrance animation completes, and a frame boundary passes. Disabled
`TickerMode` holds initial creation. Without a route/animation, creation follows
the first frame. Flutter content keeps its state throughout; an already mounted
surface stays mounted during later navigation.

This moves setup work out of the entrance transition. It does not reduce the
final number of hosting controllers. Flutter suggests
[placeholders during platform-view animations](https://docs.flutter.dev/platform-integration/ios/platform-views#performance);
our deferred initial mount is a project-specific application of that principle.
Measure the first second after the transition too, to detect a delayed hitch.

## Symbol precaching

`AppleLiquidSymbol.precache(context, name, size:, color:, weight:)` reuses the
widget's PNG cache and coalesces concurrent requests. Its key includes name,
size, effective color, weight, and device pixel ratio. It also prepares Flutter
image decoding with the same byte-buffer identity and `MemoryImage` scale as
the eventual widget.

`true` means rendering and decoding completed with a still-mounted context.
Missing symbols, channel/decode failure, unsupported raster scale, Android, and
an unmounted context return false. Invalid names/sizes throw `ArgumentError`;
web/desktop retain the unsupported-platform error. Call outside `build`, shortly
before an expected use. Match the eventual widget's size, color, weight, and DPR.

The PNG cache remains bounded to 128 entries / 4 MiB. Flutter manages decoded
images separately. Neither cache is pinned and success does not guarantee a
finished GPU texture upload. See [precacheImage](https://api.flutter.dev/flutter/widgets/precacheImage.html)
and [MemoryImage equality](https://api.flutter.dev/flutter/painting/MemoryImage/operator_equals.html).

## Example navigation and scrolling

The example creates each tab on first use, retains visited pages/native views,
and disables Flutter tickers and focus in inactive tabs. Cards and the inner
settings list mount on demand and retain visited native content. The five
sample switches share the group host. Each tab owns its scroll controller;
keyboard and iOS status-bar scrolling target the active tab without changing
hidden scroll offsets. An initial focus target also preserves PageDown before
the user clicks a control.

The native tabbar compares actual UIKit state before writing badge values,
colors, text attributes, or appearances. Recreated/reset native items still
receive configuration; standard and scroll-edge appearance styles stay distinct.
Unchanged selected indices do not cause another Combine publication.

A repeated `Tabs → Switch → Tabs → Switch` widget test, using the same 800×600
viewport and mocked native replies, counted these platform-view requests:

| Measurement | Before | After |
| --- | --- | --- |
| Cumulative create requests | 7 → 22 → 28 → 43 | 6 → 14 → 14 → 14 |
| Disposal requests during tab switches | 27 | 0 |
| Inner settings scroll revisit | 17 → 21 creates, 1 → 4 disposals | 17 → 17 creates, 0 → 0 disposals |

These are structural counts, not simulator/device FPS. A real channel test also
checks that native view IDs remain identical after revisiting a tab. Retention
trades memory for avoiding repeated setup; it is bounded to four tabs and their
finite visited entries and ends when the demo is disposed.

## Validation boundaries

Preparation for 0.3.4 passed 124 package tests, 22 example tests, 55 native XCTests,
both analyzers, and a Swift 5 / iOS 13-target typecheck. Tests cover independent
switch values/tints, stale channels, deferred mount cancellation, cache reuse,
primary scrolling and focus restoration, native badge setter counts, popover
configuration/session handling, and sheet compatibility. Native tests ran on an
iOS 27 simulator, not on every supported runtime. Two genuine popover integration tests also passed, covering native consumer
content/results and anchor removal during animated presentation. Other channel
checks are recorded by the separate release preparation report.

The repository retains its existing iOS 13 pod target. The installed iOS 27 SDK
requires temporary simulator build overrides for that target and a scene manifest
in the generated test app. Those validation-only adjustments do not migrate the
example source or raise the package minimum. An app built with Xcode 27 must adopt
[UIScene](https://docs.flutter.dev/release/breaking-changes/uiscenedelegate).
No physical iPhone profile measurement, older-runtime acceptance, or VoiceOver
acceptance is implied by unit/native test results.

## Repeatable physical-iPhone comparison

Use the same iPhone, iOS/Flutter versions, refresh rate, and thermal conditions
for each variant. Flutter recommends a [physical device in profile mode](https://docs.flutter.dev/perf/ui-performance).
Use an example host that builds, launches, and signs correctly with your SDK.
From the repository's `example/` directory:

```sh
flutter devices
python3 tool/run_performance.py "$MJN_IPHONE_ID" /path/to/new-results-directory
```

The runner rejects simulators and creates a new output directory. It performs
20 runs for each of 11 cases (220 app starts), alternating pair order and rotating
symbol-variant order. Every invocation has a fresh plugin cache; system SF Symbol
caches may remain warm.

- Switches: 5 and 20 individual controls versus a group, with identical content.
- Surfaces: 1 and 10 immediate versus deferred backgrounds.
- Symbols: 12 identical variants with cold, PNG-only warm, or PNG+decode warm caches.

PNG-only warm preparation first calls precache and then clears Flutter's decoded
image cache inside the benchmark. Its preparation time therefore includes the
subsequently discarded decode; it is not an isolated PNG-loading benchmark.

Logs/JSONL include preparation time, route completion, readiness, median/p95 build
and raster times, frames over the display budget, native view counts, and RSS
samples. Readiness means native controllers or decoded RawImages are available
after entrance; it is not a measurement of the first native pixel. The first
second after readiness remains in the measured window. Use
[Instruments](https://developer.apple.com/videos/play/wwdc2023/10248/) for native
main-thread spikes, first visible frames, and memory peaks as well. Report
regressions, placeholder delay, and cache memory alongside any repeatable gain.
