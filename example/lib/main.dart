import 'dart:math' as math;

import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const DemoShell(),
    );
  }
}

class DemoShell extends StatefulWidget {
  const DemoShell({super.key});

  @override
  State<DemoShell> createState() => _DemoShellState();
}

class _DemoShellState extends State<DemoShell> {
  int currentIndex = 0;
  bool switchValue = true;
  double normalSliderValue = 0.45;
  double steppedSliderValue = 0.6;
  double coarseSliderValue = 0.5;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: const Text('MJN Liquid UI')),
      body: Stack(
        children: <Widget>[
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: KeyedSubtree(
                key: ValueKey<int>(currentIndex),
                child: _pageFor(currentIndex),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppleLiquidTabBar(
              currentIndex: currentIndex,
              selectedTintColor: const Color(0xFF0EA5E9),
              onChanged: (int index) {
                setState(() => currentIndex = index);
              },
              items: const <AppleLiquidTabItem>[
                AppleLiquidTabItem(
                  title: 'Tabs',
                  systemImage: 'square.grid.2x2.fill',
                ),
                AppleLiquidTabItem(title: 'Switch', systemImage: 'switch.2'),
                AppleLiquidTabItem(
                  title: 'Slider',
                  systemImage: 'slider.horizontal.3',
                ),
              ],
              searchItem: const AppleLiquidTabItem(
                title: 'Surface',
                systemImage: 'plus',
                isSearch: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageFor(int index) {
    switch (index) {
      case 1:
        return _SwitchDemoPage(
          value: switchValue,
          onChanged: (bool value) {
            setState(() => switchValue = value);
          },
        );
      case 2:
        return _SliderDemoPage(
          normalValue: normalSliderValue,
          onNormalChanged: (double value) {
            setState(() => normalSliderValue = value);
          },
          steppedValue: steppedSliderValue,
          onSteppedChanged: (double value) {
            setState(() => steppedSliderValue = value);
          },
          coarseValue: coarseSliderValue,
          onCoarseChanged: (double value) {
            setState(() => coarseSliderValue = value);
          },
        );
      case 3:
        return const _SurfaceDemoPage();
      case 0:
      default:
        return const _TabbarDemoPage();
    }
  }
}

class _DemoPageScaffold extends StatelessWidget {
  const _DemoPageScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 28),
        child,
      ],
    );
  }
}

class _TabbarDemoPage extends StatelessWidget {
  const _TabbarDemoPage();

  @override
  Widget build(BuildContext context) {
    return const _DemoPageScaffold(
      title: 'Tabbar',
      subtitle:
          'The bottom navigation is the native SwiftUI TabView. The trailing plus tab keeps role: .search without .searchable.',
      child: AppleLiquidSurface(
        height: 132,
        child: _SurfaceText(
          title: 'Native tabs',
          body: 'Use the bottom bar to switch between the demo pages.',
        ),
      ),
    );
  }
}

class _SwitchDemoPage extends StatelessWidget {
  const _SwitchDemoPage({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _DemoPageScaffold(
      title: 'Switch',
      subtitle: 'A native SwiftUI Toggle embedded through UiKitView.',
      child: AppleLiquidSurface(
        height: 112,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                value ? 'Enabled' : 'Disabled',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            AppleLiquidSwitch(
              value: value,
              tintColor: const Color(0xFF14B8A6),
              onChanged: onChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderDemoPage extends StatelessWidget {
  const _SliderDemoPage({
    required this.normalValue,
    required this.onNormalChanged,
    required this.steppedValue,
    required this.onSteppedChanged,
    required this.coarseValue,
    required this.onCoarseChanged,
  });

  final double normalValue;
  final ValueChanged<double> onNormalChanged;
  final double steppedValue;
  final ValueChanged<double> onSteppedChanged;
  final double coarseValue;
  final ValueChanged<double> onCoarseChanged;

  @override
  Widget build(BuildContext context) {
    return _DemoPageScaffold(
      title: 'Slider',
      subtitle: 'Native SwiftUI sliders: continuous, stepped, and coarse.',
      child: AppleLiquidSurface(
        height: 390,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _SliderExample(
              title: 'Normal',
              value: normalValue,
              onChanged: onNormalChanged,
            ),
            const SizedBox(height: 18),
            _SliderExample(
              title: 'Steps',
              value: steppedValue,
              step: 0.1,
              tintColor: const Color(0xFF14B8A6),
              onChanged: onSteppedChanged,
            ),
            const SizedBox(height: 18),
            _SliderExample(
              title: 'Fewer steps',
              value: coarseValue,
              step: 0.25,
              tintColor: const Color(0xFFF59E0B),
              onChanged: onCoarseChanged,
            ),
          ],
        ),
      ),
    );
  }
}

class _SliderExample extends StatelessWidget {
  const _SliderExample({
    required this.title,
    required this.value,
    required this.onChanged,
    this.step,
    this.tintColor,
  });

  final String title;
  final double value;
  final ValueChanged<double> onChanged;
  final double? step;
  final Color? tintColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Text(
              '${(value * 100).round()}%',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
        const SizedBox(height: 6),
        AppleLiquidSlider(
          value: value,
          step: step,
          tintColor: tintColor,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _SurfaceDemoPage extends StatelessWidget {
  const _SurfaceDemoPage();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Surface', style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(
            'Drag the transparent glass surface. The confetti behind it makes refraction easier to see.',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          const Expanded(child: _ConfettiGlassStage()),
        ],
      ),
    );
  }
}

class _ConfettiGlassStage extends StatelessWidget {
  const _ConfettiGlassStage();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: Stack(
        children: <Widget>[
          const Positioned.fill(child: _ConfettiBackdrop()),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: const AppleLiquidSurface(
                height: 190,
                clear: true,
                interactive: true,
                deformable: true,
                stretchGestureMode:
                    AppleLiquidStretchGestureMode.gestureDetector,
                child: _SurfaceActionContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfettiBackdrop extends StatefulWidget {
  const _ConfettiBackdrop();

  @override
  State<_ConfettiBackdrop> createState() => _ConfettiBackdropState();
}

class _ConfettiBackdropState extends State<_ConfettiBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return CustomPaint(
          foregroundPainter: _ConfettiPainter(progress: _controller.value),
          child: child,
        );
      },
      child: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFFF8FAFC),
              Color(0xFFEFF6FF),
              Color(0xFFFFFBEB),
            ],
          ),
        ),
        child: SizedBox.expand(),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  const _ConfettiPainter({required this.progress});

  final double progress;

  static const List<_ConfettiPiece> _pieces = <_ConfettiPiece>[
    _ConfettiPiece(0.05, 0.00, 24, 7, 0.5, Color(0xFFFFC857), false, 0.7),
    _ConfettiPiece(0.15, 0.10, 14, 14, 0.0, Color(0xFF2EC4B6), true, 1.0),
    _ConfettiPiece(0.28, 0.05, 22, 6, -0.7, Color(0xFFFF6B6B), false, 0.8),
    _ConfettiPiece(0.40, 0.00, 18, 8, 0.9, Color(0xFF7C3AED), false, 1.2),
    _ConfettiPiece(0.55, 0.08, 24, 7, -0.4, Color(0xFF38BDF8), false, 0.9),
    _ConfettiPiece(0.68, 0.02, 16, 16, 0.0, Color(0xFFF97316), true, 1.1),
    _ConfettiPiece(0.80, 0.12, 20, 6, 0.6, Color(0xFF84CC16), false, 0.75),
    _ConfettiPiece(0.92, 0.00, 14, 14, 0.0, Color(0xFFE879F9), true, 1.0),
    _ConfettiPiece(0.10, 0.25, 26, 7, -0.9, Color(0xFF84CC16), false, 0.85),
    _ConfettiPiece(0.22, 0.30, 18, 18, 0.0, Color(0xFFE879F9), true, 1.05),
    _ConfettiPiece(0.35, 0.22, 34, 9, 0.3, Color(0xFFFFC857), false, 0.95),
    _ConfettiPiece(0.48, 0.28, 28, 8, -0.8, Color(0xFF06B6D4), false, 1.15),
    _ConfettiPiece(0.60, 0.20, 17, 17, 0.0, Color(0xFFFB7185), true, 0.80),
    _ConfettiPiece(0.73, 0.32, 32, 8, 0.6, Color(0xFF22C55E), false, 1.00),
    _ConfettiPiece(0.86, 0.24, 20, 7, -0.5, Color(0xFFA78BFA), false, 0.90),
    _ConfettiPiece(0.03, 0.50, 18, 18, 0.0, Color(0xFF60A5FA), true, 1.10),
    _ConfettiPiece(0.18, 0.55, 30, 8, 0.8, Color(0xFFF59E0B), false, 0.70),
    _ConfettiPiece(0.33, 0.48, 23, 7, -0.5, Color(0xFFA78BFA), false, 1.20),
    _ConfettiPiece(0.50, 0.60, 18, 18, 0.0, Color(0xFF14B8A6), true, 0.85),
    _ConfettiPiece(0.65, 0.52, 28, 8, -0.7, Color(0xFFEF4444), false, 1.05),
    _ConfettiPiece(0.78, 0.58, 24, 7, 0.5, Color(0xFF8B5CF6), false, 0.95),
    _ConfettiPiece(0.91, 0.46, 16, 16, 0.0, Color(0xFF2EC4B6), true, 1.00),
    _ConfettiPiece(0.08, 0.72, 22, 8, 0.4, Color(0xFFFFC857), false, 0.80),
    _ConfettiPiece(0.20, 0.78, 18, 18, 0.0, Color(0xFFFF6B6B), true, 1.10),
    _ConfettiPiece(0.36, 0.70, 26, 7, -0.6, Color(0xFF38BDF8), false, 0.90),
    _ConfettiPiece(0.52, 0.80, 14, 14, 0.0, Color(0xFF7C3AED), true, 1.15),
    _ConfettiPiece(0.67, 0.75, 30, 9, 0.7, Color(0xFF22C55E), false, 0.75),
    _ConfettiPiece(0.82, 0.68, 20, 7, -0.3, Color(0xFFF97316), false, 1.00),
    _ConfettiPiece(0.95, 0.82, 18, 18, 0.0, Color(0xFFE879F9), true, 0.85),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    for (final _ConfettiPiece piece in _pieces) {
      // Jedes Stück fällt mit seiner eigenen Geschwindigkeit durch den Viewport.
      // (progress + phase) % 1.0 ergibt eine kontinuierliche Schleife.
      final double phase = piece.y;
      final double t = (progress * piece.speed + phase) % 1.0;

      final double x = size.width * piece.x;
      // y läuft von -10 % bis 110 % der Höhe
      final double y = size.height * (t * 1.2 - 0.10);

      // Sanfte Rotation basierend auf Fortschritt
      final double rotation =
          piece.angle + progress * piece.speed * math.pi * 4;

      final Paint paint = Paint()
        ..color = piece.color.withValues(alpha: 0.88)
        ..style = PaintingStyle.fill;

      canvas
        ..save()
        ..translate(x, y)
        ..rotate(rotation);

      if (piece.isCircle) {
        canvas.drawCircle(Offset.zero, piece.width / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: Offset.zero,
              width: piece.width,
              height: piece.height,
            ),
            const Radius.circular(3),
          ),
          paint,
        );
      }

      canvas.restore();
    }

    final Paint ringPaint = Paint()
      ..color = const Color(0xFF111827).withValues(alpha: 0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;

    canvas.drawCircle(
      Offset(size.width * 0.50, size.height * 0.50),
      math.min(size.width, size.height) * 0.32,
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

class _ConfettiPiece {
  const _ConfettiPiece(
    this.x,
    this.y,
    this.width,
    this.height,
    this.angle,
    this.color, [
    this.isCircle = false,
    this.speed = 1.0,
  ]);

  final double x;
  final double y;
  final double width;
  final double height;
  final double angle;
  final Color color;
  final bool isCircle;
  final double speed; // neu: steuert Fallgeschwindigkeit (0.7–1.2)
}

class _SurfaceActionContent extends StatelessWidget {
  const _SurfaceActionContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          'Transparent Liquid Glass',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(
          'Button taps stay on the button. Drag outside it to stretch the surface.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 14),
        FilledButton.tonal(
          onPressed: () {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('Button tapped')));
          },
          child: const Text('Test button'),
        ),
      ],
    );
  }
}

class _SurfaceText extends StatelessWidget {
  const _SurfaceText({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(body, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
