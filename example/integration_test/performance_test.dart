// Run once per fresh app process on a physical iPhone in profile mode.
// See doc/performance.md for the alternating 20-run matrix.
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';

const _scenario = String.fromEnvironment(
  'MJN_SCENARIO',
  defaultValue: 'switches',
);
const _variant = String.fromEnvironment(
  'MJN_VARIANT',
  defaultValue: 'baseline',
);
const _count = int.fromEnvironment('MJN_COUNT', defaultValue: 5);
const _run = int.fromEnvironment('MJN_RUN');
const _symbols = <String>[
  'star',
  'heart',
  'house',
  'gear',
  'bell',
  'person',
  'magnifyingglass',
  'plus',
  'checkmark',
  'calendar',
  'folder',
  'sparkles',
];

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  testWidgets(
    'physical-device performance comparison',
    (tester) async {
      expect(
        kProfileMode,
        isTrue,
        reason: 'Use a physical iPhone and --profile.',
      );
      expect(defaultTargetPlatform, TargetPlatform.iOS);
      expect(<String>['switches', 'surfaces', 'symbols'], contains(_scenario));
      expect(
        _scenario == 'symbols'
            ? <String>['baseline', 'png', 'precache']
            : <String>['baseline', 'optimized'],
        contains(_variant),
      );
      expect(_scenario == 'symbols' ? _count == 12 : _count > 0, isTrue);
      final navigator = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigator,
          home: const Scaffold(
            body: Center(child: Text('Preparing comparison')),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final rssAtStart = ProcessInfo.currentRss;
      final preparation = Stopwatch()..start();
      if (_scenario == 'symbols' && _variant != 'baseline') {
        final context = navigator.currentContext!;
        final results = await Future.wait(
          _symbols.map(
            (name) =>
                AppleLiquidSymbol.precache(context, name, color: Colors.indigo),
          ),
        );
        expect(results.every((result) => result), isTrue);
        await SchedulerBinding.instance.endOfFrame;
        if (_variant == 'png') {
          // The plugin's byte cache stays warm while Flutter must decode again.
          PaintingBinding.instance.imageCache.clear();
          PaintingBinding.instance.imageCache.clearLiveImages();
        }
      }
      preparation.stop();

      final frames = <ui.FrameTiming>[];
      void onTimings(List<ui.FrameTiming> timings) => frames.addAll(timings);
      int nativeViews = 0;
      int decodedImages = 0;
      int readyMicros = 0;
      int transitionMicros = 0;
      final rssBefore = ProcessInfo.currentRss;
      try {
        await binding.watchPerformance(() async {
          // watchPerformance flushes earlier timing batches before starting action.
          SchedulerBinding.instance.addTimingsCallback(onTimings);
          final stopwatch = Stopwatch()..start();
          final route = MaterialPageRoute<void>(
            builder: (_) => _ComparisonPage(),
          );
          unawaited(navigator.currentState!.push(route));
          // Animation is installed by Navigator.push, not by the constructor.
          route.animation!.addStatusListener((status) {
            if (status == AnimationStatus.completed) {
              transitionMicros = stopwatch.elapsedMicroseconds;
            }
          });
          final expectedViews = _scenario == 'symbols'
              ? 0
              : (_scenario == 'switches' && _variant == 'optimized'
                    ? 1
                    : _count);
          while (stopwatch.elapsed < const Duration(seconds: 10)) {
            await Future<void>.delayed(const Duration(milliseconds: 16));
            nativeViews = find
                .byElementPredicate(
                  (element) =>
                      element is RenderObjectElement &&
                      element.renderObject is RenderUiKitView,
                )
                .evaluate()
                .length;
            decodedImages = tester
                .widgetList<RawImage>(find.byType(RawImage))
                .where((image) => image.image != null)
                .length;
            if (nativeViews == expectedViews &&
                (_scenario != 'symbols' || decodedImages == 12) &&
                route.animation!.status == AnimationStatus.completed) {
              readyMicros = stopwatch.elapsedMicroseconds;
              break;
            }
          }
          expect(
            readyMicros,
            greaterThan(0),
            reason: 'Native/image readiness timed out.',
          );
          // Include the first second after readiness so deferred setup cannot
          // hide a later hitch. Native GPU/main-thread costs also need Instruments.
          await Future<void>.delayed(const Duration(seconds: 1));
        });
      } finally {
        SchedulerBinding.instance.removeTimingsCallback(onTimings);
      }
      expect(frames, isNotEmpty);
      final refreshRate = tester.view.display.refreshRate;
      final budget = 1000000 / refreshRate;
      final build =
          frames.map((frame) => frame.buildDuration.inMicroseconds).toList()
            ..sort();
      final raster =
          frames.map((frame) => frame.rasterDuration.inMicroseconds).toList()
            ..sort();
      int percentile(List<int> values, double p) =>
          values[(values.length * p).ceil() - 1];
      binding.reportData!['comparison'] = <String, Object>{
        'scenario': _scenario,
        'variant': _variant,
        'count': _count,
        'run': _run,
        'preparation_us': preparation.elapsedMicroseconds,
        'route_completed_us': transitionMicros,
        'ready_us': readyMicros,
        'native_views_ready': nativeViews,
        'decoded_images_ready': decodedImages,
        'rss_at_start_bytes': rssAtStart,
        'rss_before_bytes': rssBefore,
        'rss_after_bytes': ProcessInfo.currentRss,
        'refresh_hz': refreshRate,
        'frames': frames.length,
        'build_median_us': percentile(build, .5),
        'build_p95_us': percentile(build, .95),
        'raster_median_us': percentile(raster, .5),
        'raster_p95_us': percentile(raster, .95),
        'frames_over_budget': frames
            .where(
              (frame) =>
                  math.max(
                    frame.buildDuration.inMicroseconds,
                    frame.rasterDuration.inMicroseconds,
                  ) >
                  budget,
            )
            .length,
      };
      // Machine-readable output also survives flutter test without a driver.
      debugPrint('MJN_PERFORMANCE ${jsonEncode(binding.reportData)}');
      await tester.pumpWidget(const SizedBox());
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

class _ComparisonPage extends StatefulWidget {
  @override
  State<_ComparisonPage> createState() => _ComparisonPageState();
}

class _ComparisonPageState extends State<_ComparisonPage> {
  late final values = List<bool>.filled(_count, false);

  @override
  Widget build(BuildContext context) {
    final Widget content;
    if (_scenario == 'symbols') {
      content = Wrap(
        children: <Widget>[
          for (final name in _symbols)
            AppleLiquidSymbol(name, color: Colors.indigo),
        ],
      );
    } else if (_scenario == 'surfaces') {
      content = Column(
        children: <Widget>[
          for (int i = 0; i < _count; i++)
            AppleLiquidSurface(
              height: 60,
              deferMountUntilRouteTransitionCompletes: _variant == 'optimized',
              child: Text('Surface $i'),
            ),
        ],
      );
    } else if (_variant == 'optimized') {
      content = AppleLiquidSwitchGroup(
        items: <AppleLiquidSwitchGroupItem>[
          for (int i = 0; i < _count; i++)
            AppleLiquidSwitchGroupItem(
              id: '$i',
              label: Text('Switch $i'),
              semanticLabel: 'Switch $i',
              value: values[i],
              onChanged: (value) => setState(() => values[i] = value),
            ),
        ],
      );
    } else {
      content = Column(
        children: <Widget>[
          for (int i = 0; i < _count; i++)
            SizedBox(
              height: 60,
              child: Row(
                children: <Widget>[
                  Expanded(child: Text('Switch $i')),
                  const SizedBox(width: 12),
                  AppleLiquidSwitch(
                    value: values[i],
                    onChanged: (value) => setState(() => values[i] = value),
                  ),
                ],
              ),
            ),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Performance comparison')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: content,
      ),
    );
  }
}
