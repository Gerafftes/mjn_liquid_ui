import 'dart:async';
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
  final List<bool> switchValues = <bool>[true, false, true, false, true];
  double normalSliderValue = 0.45;
  double steppedSliderValue = 0.6;
  double coarseSliderValue = 0.5;
  bool templateSheetBackgroundZoom = true;
  bool templateSheetSectionBackgrounds = false;
  Color? templateSheetColor;
  final AppleLiquidSheetController templateSheetController =
      AppleLiquidSheetController();

  @override
  void dispose() {
    templateSheetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppleLiquidSheetBackgroundInteractionGuard(
      controller: templateSheetController,
      child: _DemoScaffold(
        currentIndex: currentIndex,
        onChanged: (int index) {
          setState(() => currentIndex = index);
        },
        page: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: KeyedSubtree(
            key: ValueKey<int>(currentIndex),
            child: _pageFor(currentIndex),
          ),
        ),
      ),
    );
  }

  Widget _pageFor(int index) {
    switch (index) {
      case 1:
        return _SwitchDemoPage(
          values: switchValues,
          onChanged: (int index, bool value) {
            setState(() => switchValues[index] = value);
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
        return _TabbarDemoPage(
          sheetBackgroundZoom: templateSheetBackgroundZoom,
          sheetSectionBackgrounds: templateSheetSectionBackgrounds,
          sheetColor: templateSheetColor,
          onSheetBackgroundZoomChanged: (bool value) {
            setState(() => templateSheetBackgroundZoom = value);
          },
          onSheetSectionBackgroundsChanged: (bool value) {
            setState(() => templateSheetSectionBackgrounds = value);
          },
          onSheetColorChanged: (Color? value) {
            setState(() => templateSheetColor = value);
          },
          onShowTemplateSheet: _showTemplateSheet,
        );
    }
  }

  AppleLiquidSheetContent get _sheetContent {
    final String colorMode = switch (templateSheetColor) {
      const Color(0xFFF7F7FA) => 'Light',
      const Color(0xFF1C1C1E) => 'Dark',
      _ => 'Automatic',
    };

    return AppleLiquidSheetContent(
      title: 'Sheet Demo',
      doneSemanticLabel: 'Close sheet',
      leadingAction: const AppleLiquidSheetToolbarAction(
        systemImage: 'xmark',
        semanticLabel: 'Dismiss sheet',
        foregroundColor: Color(0xFFFF9F0A),
      ),
      trailingAction: const AppleLiquidSheetToolbarAction(
        title: 'Apply',
        systemImage: 'checkmark',
        semanticLabel: 'Apply changes',
        foregroundColor: Color(0xFFFFFFFF),
        backgroundColor: Color(0xFF34C759),
      ),
      detents: const AppleLiquidSheetDetents(
        initialHeight: 430,
        expandedHeight: 660,
      ),
      showsSectionBackgrounds: templateSheetSectionBackgrounds,
      sectionSpacing: 8,
      sections: <AppleLiquidSheetSection>[
        const AppleLiquidSheetSection(
          title: 'Package',
          rows: <AppleLiquidSheetRow>[
            AppleLiquidSheetRow.value(
              title: 'Name',
              value: 'mjn_liquid_ui',
              systemImage: 'shippingbox.fill',
            ),
            AppleLiquidSheetRow.value(
              title: 'Content',
              value: 'Configured from Flutter',
              systemImage: 'doc.text.fill',
            ),
            AppleLiquidSheetRow.value(
              title: 'Section spacing',
              value: '8 pt',
              systemImage: 'arrow.up.and.down',
            ),
            AppleLiquidSheetRow.navigation(
              title: 'Release details',
              systemImage: 'sparkles',
              content: AppleLiquidSheetContent(
                title: 'Release',
                detents: AppleLiquidSheetDetents(
                  initialHeight: 300,
                  expandedHeight: 520,
                ),
                sectionSpacing: 24,
                sections: <AppleLiquidSheetSection>[
                  AppleLiquidSheetSection(
                    title: 'Highlights',
                    rows: <AppleLiquidSheetRow>[
                      AppleLiquidSheetRow.text(
                        title: 'Native SwiftUI form',
                        subtitle:
                            'Sections, rows, controls, and nested pages are passed from Dart.',
                        systemImage: 'rectangle.bottomthird.inset.filled',
                      ),
                      AppleLiquidSheetRow.value(
                        title: 'Detents',
                        value: 'Custom two-step',
                      ),
                    ],
                  ),
                  AppleLiquidSheetSection(
                    title: 'Spacing demo',
                    rows: <AppleLiquidSheetRow>[
                      AppleLiquidSheetRow.value(
                        title: 'Section spacing',
                        value: '24 pt',
                        systemImage: 'arrow.up.and.down',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        AppleLiquidSheetSection(
          title: 'Presentation',
          rows: <AppleLiquidSheetRow>[
            const AppleLiquidSheetRow.segmented(
              title: 'Layout',
              firstOption: 'List',
              secondOption: 'Grid',
              selectedOption: 'List',
              systemImage: 'rectangle.grid.1x2',
              style: AppleLiquidSheetSegmentedStyle(
                selectedBackgroundColor: Color(0x2634C759),
                selectedTextColor: Color(0xFF34C759),
                selectedBorderColor: Color(0x9934C759),
                selectedShadowColor: Color(0x0AFFFFFF),
                buttonHeight: 48,
                cornerRadius: 16,
                rowHorizontalInset: 8,
                selectedShadowRadius: 8,
                selectedShadowOffsetY: 2,
                buttonFontWeight: AppleLiquidSheetSegmentedFontWeight.bold,
                selectionAnimationCurve:
                    AppleLiquidSheetSegmentedAnimationCurve.easeInOut,
                selectionAnimationDuration: 0.15,
              ),
            ),
            AppleLiquidSheetRow.toggle(
              title: 'Background zoom',
              value: templateSheetBackgroundZoom,
              systemImage: 'viewfinder',
            ),
            AppleLiquidSheetRow.picker(
              title: 'Sheet color',
              options: const <String>['Automatic', 'Light', 'Dark'],
              selectedOption: colorMode,
              systemImage: 'paintpalette.fill',
            ),
            const AppleLiquidSheetRow.slider(
              title: 'Corner feel',
              value: 0.7,
              tintColor: Color(0xFF0A84FF),
              valuePlacement: AppleLiquidSheetSliderValuePlacement.besideTrack,
              systemImage: 'slider.horizontal.3',
            ),
            const AppleLiquidSheetRow.slider(
              title: 'Distance',
              value: 5,
              min: 0,
              max: 10,
              step: 1,
              valueSuffix: 'km',
              tintColor: Color(0xFF007AFF),
              valuePlacement: AppleLiquidSheetSliderValuePlacement.besideTrack,
              systemImage: 'location.fill',
            ),
            AppleLiquidSheetRow.button(
              title: 'Show on map',
              tintColor: Color(0xFF007AFF),
              systemImage: 'map.fill',
              semanticLabel: 'Open map view',
              dismissesSheet: true,
              style: const AppleLiquidSheetButtonStyle(
                rowVerticalInset: 8,
                cornerRadius: 12,
                pressedScale: 0.97,
              ),
              onPressed: _showMapAction,
            ),
          ],
        ),
        const AppleLiquidSheetSection(
          title: 'Kategorie',
          titleColor: Color(0xFFE6E6E6),
          rows: <AppleLiquidSheetRow>[
            AppleLiquidSheetRow.multiPicker(
              title: 'Kategorie',
              options: <String>['Alle', 'Garten', 'Umzug'],
              selectedOptions: <String>['Alle'],
              selectionSystemImages: <String, String>{
                'Alle': 'square.grid.2x2.fill',
                'Garten': 'leaf.fill',
                'Umzug': 'shippingbox.fill',
              },
              selectionLabelPlacement:
                  AppleLiquidSheetMultiPickerLabelPlacement.primary,
              systemImage: 'square.grid.2x2.fill',
            ),
          ],
        ),
        const AppleLiquidSheetSection(
          showsBackground: true,
          backgroundColor: Color(0x1A007AFF),
          borderColor: Color(0x80007AFF),
          cornerRadius: 15,
          rows: <AppleLiquidSheetRow>[
            AppleLiquidSheetRow.textField(
              title: 'Label',
              value: 'Liquid Glass',
            ),
          ],
        ),
        const AppleLiquidSheetSection(
          title: 'State',
          rows: <AppleLiquidSheetRow>[
            AppleLiquidSheetRow.value(title: 'Platform', value: 'iOS'),
            AppleLiquidSheetRow.value(title: 'Renderer', value: 'SwiftUI Form'),
          ],
        ),
      ],
    );
  }

  Future<void> _showTemplateSheet(BuildContext scrollContext) async {
    if (templateSheetController.isShowing || templateSheetController.isShown) {
      return;
    }

    final AppleLiquidSheetContent sheetContent = _sheetContent;

    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || !scrollContext.mounted) {
      return;
    }

    final bool didShowNativeSheet = await templateSheetController.showSheet(
      backgroundZoomScale: templateSheetBackgroundZoom ? 0.94 : 1,
      sheetColor: templateSheetColor,
      content: sheetContent,
      scrollContext: scrollContext,
    );

    if (didShowNativeSheet || !mounted) {
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.72,
      ),
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: templateSheetColor,
      builder: (BuildContext context) =>
          _TemplateSheetFallback(content: sheetContent),
    );
  }

  void _showMapAction() {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Map action triggered from native iOS')),
      );
  }
}

class _DemoScaffold extends StatelessWidget {
  const _DemoScaffold({
    required this.currentIndex,
    required this.onChanged,
    required this.page,
  });

  final int currentIndex;
  final ValueChanged<int> onChanged;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(title: const Text('MJN Liquid UI')),
      body: Stack(
        children: <Widget>[
          Positioned.fill(child: page),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppleLiquidTabBar(
              currentIndex: currentIndex,
              selectedTintColor: const Color(0xFF007AFF),
              onChanged: onChanged,
              items: const <AppleLiquidTabItem>[
                AppleLiquidTabItem(
                  title: 'Tabs',
                  systemImage: 'square.grid.2x2.fill',
                  symbolWeight: AppleLiquidSymbolWeight.regular,
                  activeSymbolWeight: AppleLiquidSymbolWeight.bold,
                ),
                AppleLiquidTabItem(
                  title: 'Switch',
                  systemImage: 'switch.2',
                  symbolWeight: AppleLiquidSymbolWeight.medium,
                  activeSymbolWeight: AppleLiquidSymbolWeight.bold,
                ),
                AppleLiquidTabItem(
                  title: 'Slider',
                  systemImage: 'slider.horizontal.3',
                  symbolWeight: AppleLiquidSymbolWeight.regular,
                  activeSymbolWeight: AppleLiquidSymbolWeight.semibold,
                  notificationDotColor: Color(0xFF007AFF),
                  notificationBadgeValue: '3',
                ),
              ],
              searchItem: const AppleLiquidTabItem(
                title: 'Surface',
                systemImage: 'plus',
                symbolWeight: AppleLiquidSymbolWeight.regular,
                activeSymbolWeight: AppleLiquidSymbolWeight.bold,
                isSearch: true,
              ),
            ),
          ),
        ],
      ),
    );
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
  const _TabbarDemoPage({
    required this.sheetBackgroundZoom,
    required this.sheetSectionBackgrounds,
    required this.sheetColor,
    required this.onSheetBackgroundZoomChanged,
    required this.onSheetSectionBackgroundsChanged,
    required this.onSheetColorChanged,
    required this.onShowTemplateSheet,
  });

  final bool sheetBackgroundZoom;
  final bool sheetSectionBackgrounds;
  final Color? sheetColor;
  final ValueChanged<bool> onSheetBackgroundZoomChanged;
  final ValueChanged<bool> onSheetSectionBackgroundsChanged;
  final ValueChanged<Color?> onSheetColorChanged;
  final ValueChanged<BuildContext> onShowTemplateSheet;

  @override
  Widget build(BuildContext context) {
    return _DemoPageScaffold(
      title: 'Tabbar',
      subtitle:
          'The bottom navigation uses native SwiftUI tabs. SF Symbols can also be placed anywhere in Flutter content.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          const AppleLiquidSurface(
            height: 152,
            child: Row(
              children: <Widget>[
                AppleLiquidSymbol(
                  'sparkles',
                  size: 36,
                  color: Color(0xFF0EA5E9),
                  weight: AppleLiquidSymbolWeight.semibold,
                  fallbackIcon: Icons.auto_awesome_rounded,
                  semanticLabel: 'Sparkles',
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _SurfaceText(
                    title: 'Native tabs and symbols',
                    body:
                        'Use SF Symbol names in the tab bar or as standalone content.',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppleLiquidSurface(
            height: 350,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const AppleLiquidSymbol(
                      'rectangle.bottomthird.inset.filled',
                      size: 34,
                      color: Color(0xFF007AFF),
                      fallbackIcon: Icons.keyboard_arrow_up_rounded,
                      semanticLabel: 'Sheet',
                    ),
                    const SizedBox(width: 16),
                    const Expanded(child: _SheetControlHeaderText()),
                    const SizedBox(width: 12),
                    Builder(
                      builder: (BuildContext context) {
                        return FilledButton(
                          onPressed: () => onShowTemplateSheet(context),
                          child: const Text('Open'),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SheetToggleRow(
                  label: 'Background zoom',
                  value: sheetBackgroundZoom,
                  onChanged: onSheetBackgroundZoomChanged,
                ),
                _SheetToggleRow(
                  label: 'Section backgrounds',
                  value: sheetSectionBackgrounds,
                  onChanged: onSheetSectionBackgroundsChanged,
                ),
                _SheetColorRow(
                  value: sheetColor,
                  onChanged: onSheetColorChanged,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppleLiquidSurface(
            height: 132,
            child: Row(
              children: <Widget>[
                const AppleLiquidSymbol(
                  'cart.fill',
                  size: 34,
                  color: Color(0xFF34C759),
                  fallbackIcon: Icons.shopping_cart_rounded,
                  semanticLabel: 'Cart',
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: _SurfaceText(
                    title: 'Glass toast',
                    body: 'Native bottom toast with an optional action.',
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _showCartToast,
                  child: const Text('Show'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const AppleLiquidSurface(height: 500, child: _SymbolGrid()),
        ],
      ),
    );
  }

  void _showCartToast() {
    unawaited(
      AppleLiquidToast.show(
        title: 'Added to Cart',
        systemImage: 'cart.fill',
        action: AppleLiquidToastAction(
          title: 'Undo',
          tintColor: const Color(0xFFFF9500),
          dismissesToast: false,
          onPressed: () {
            unawaited(
              AppleLiquidToast.show(
                title: 'Removed From Cart',
                systemImage: 'checkmark.circle.fill',
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SheetControlHeaderText extends StatelessWidget {
  const _SheetControlHeaderText();

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          'Sheet controls',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          'Open a native settings sheet with form navigation.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _SheetToggleRow extends StatelessWidget {
  const _SheetToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleSmall),
          ),
          AppleLiquidSwitch(
            value: value,
            width: 74,
            height: 52,
            tintColor: const Color(0xFF007AFF),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _SheetColorRow extends StatelessWidget {
  const _SheetColorRow({required this.value, required this.onChanged});

  static const List<_SheetColorOption> _options = <_SheetColorOption>[
    _SheetColorOption(label: 'Auto'),
    _SheetColorOption(label: 'Light', color: Color(0xFFF7F7FA)),
    _SheetColorOption(label: 'Dark', color: Color(0xFF1C1C1E)),
  ];

  final Color? value;
  final ValueChanged<Color?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 82,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Sheet color', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _options.length,
              separatorBuilder: (BuildContext context, int index) {
                return const SizedBox(width: 8);
              },
              itemBuilder: (BuildContext context, int index) {
                final _SheetColorOption option = _options[index];

                return _SheetColorChip(
                  option: option,
                  isSelected: option.color == value,
                  onSelected: () => onChanged(option.color),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetColorChip extends StatelessWidget {
  const _SheetColorChip({
    required this.option,
    required this.isSelected,
    required this.onSelected,
  });

  final _SheetColorOption option;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final Color swatchColor = option.color ?? colorScheme.surface;

    return ChoiceChip(
      selected: isSelected,
      label: Text(option.label),
      avatar: DecoratedBox(
        decoration: BoxDecoration(
          color: swatchColor,
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: const SizedBox.square(dimension: 14),
      ),
      onSelected: (_) => onSelected(),
    );
  }
}

class _SheetColorOption {
  const _SheetColorOption({required this.label, this.color});

  final String label;
  final Color? color;
}

class _SymbolGrid extends StatelessWidget {
  const _SymbolGrid();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 12,
      runSpacing: 18,
      children: <Widget>[
        _SymbolSample(
          name: 'sparkles',
          size: 18,
          weight: AppleLiquidSymbolWeight.ultraLight,
          color: Color(0xFF0EA5E9),
          fallbackIcon: Icons.auto_awesome_rounded,
        ),
        _SymbolSample(
          name: 'bell.fill',
          size: 24,
          weight: AppleLiquidSymbolWeight.light,
          color: Color(0xFFF59E0B),
          fallbackIcon: Icons.notifications_rounded,
        ),
        _SymbolSample(
          name: 'creditcard.fill',
          size: 28,
          weight: AppleLiquidSymbolWeight.regular,
          color: Color(0xFF8B5CF6),
          fallbackIcon: Icons.credit_card_rounded,
        ),
        _SymbolSample(
          name: 'checkmark.seal.fill',
          size: 32,
          weight: AppleLiquidSymbolWeight.medium,
          color: Color(0xFF22C55E),
          fallbackIcon: Icons.verified_rounded,
        ),
        _SymbolSample(
          name: 'storefront.fill',
          size: 40,
          weight: AppleLiquidSymbolWeight.semibold,
          color: Color(0xFFF97316),
          fallbackIcon: Icons.storefront_rounded,
        ),
        _SymbolSample(
          name: 'person.crop.circle.fill',
          size: 48,
          weight: AppleLiquidSymbolWeight.bold,
          color: Color(0xFFEC4899),
          fallbackIcon: Icons.account_circle_rounded,
        ),
        _SymbolSample(
          name: 'headphones',
          size: 56,
          weight: AppleLiquidSymbolWeight.heavy,
          color: Color(0xFF14B8A6),
          fallbackIcon: Icons.headphones_rounded,
        ),
        _SymbolSample(
          name: 'circle.grid.3x3.fill',
          size: 64,
          weight: AppleLiquidSymbolWeight.black,
          color: Color(0xFF6366F1),
          fallbackIcon: Icons.apps_rounded,
        ),
      ],
    );
  }
}

class _SymbolSample extends StatelessWidget {
  const _SymbolSample({
    required this.name,
    required this.size,
    required this.weight,
    required this.color,
    required this.fallbackIcon,
  });

  final String name;
  final double size;
  final AppleLiquidSymbolWeight weight;
  final Color color;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 88,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            height: 68,
            child: Align(
              alignment: Alignment.bottomLeft,
              child: AppleLiquidSymbol(
                name,
                size: size,
                color: color,
                weight: weight,
                fallbackIcon: fallbackIcon,
                semanticLabel: name,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 2),
          Text(
            '${size.round()} px / ${weight.platformValue}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

class _TemplateSheetFallback extends StatelessWidget {
  const _TemplateSheetFallback({required this.content});

  final AppleLiquidSheetContent content;

  @override
  Widget build(BuildContext context) {
    final AppleLiquidSheetToolbarAction? leadingAction = content.leadingAction;
    final AppleLiquidSheetToolbarAction? trailingAction =
        content.trailingAction;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                if (leadingAction != null)
                  _TemplateSheetFallbackToolbarButton(
                    action: leadingAction,
                    onPressed: () => Navigator.of(context).pop(),
                  )
                else
                  const SizedBox(width: 48),
                const Spacer(),
                Text(
                  content.title,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Spacer(),
                if (trailingAction != null)
                  _TemplateSheetFallbackToolbarButton(
                    action: trailingAction,
                    isFilled: true,
                    onPressed: () => Navigator.of(context).pop(),
                  )
                else
                  IconButton.filled(
                    tooltip: content.doneSemanticLabel,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.check_rounded),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            for (final AppleLiquidSheetSection section in content.sections) ...[
              _SettingsFallbackSection(
                title: section.title,
                titleColor: section.titleColor,
                children: <Widget>[
                  for (final AppleLiquidSheetRow row in section.rows)
                    _SettingsFallbackRow(
                      label: _labelFor(row),
                      value: _trailingValueFor(row),
                    ),
                ],
              ),
              SizedBox(height: content.sectionSpacing ?? 14),
            ],
          ],
        ),
      ),
    );
  }

  String _labelFor(AppleLiquidSheetRow row) {
    if (row.type == AppleLiquidSheetRowType.multiPicker &&
        row.selectionLabelPlacement ==
            AppleLiquidSheetMultiPickerLabelPlacement.primary) {
      return _valueFor(row);
    }

    return row.title;
  }

  String _trailingValueFor(AppleLiquidSheetRow row) {
    if (row.type == AppleLiquidSheetRowType.multiPicker &&
        row.selectionLabelPlacement ==
            AppleLiquidSheetMultiPickerLabelPlacement.primary) {
      return '';
    }

    return _valueFor(row);
  }

  String _valueFor(AppleLiquidSheetRow row) {
    return switch (row.type) {
      AppleLiquidSheetRowType.text => row.subtitle ?? '',
      AppleLiquidSheetRowType.value => row.value ?? '',
      AppleLiquidSheetRowType.toggle => row.boolValue == true ? 'On' : 'Off',
      AppleLiquidSheetRowType.picker =>
        row.selectedOption ?? (row.options.isEmpty ? '' : row.options.first),
      AppleLiquidSheetRowType.multiPicker =>
        row.selectedOptions.isEmpty ? 'All' : row.selectedOptions.join(', '),
      AppleLiquidSheetRowType.segmented =>
        row.selectedOption ?? (row.options.isEmpty ? '' : row.options.first),
      AppleLiquidSheetRowType.button => row.subtitle ?? '',
      AppleLiquidSheetRowType.slider => _sliderValueFor(row),
      AppleLiquidSheetRowType.navigation => 'Details',
      AppleLiquidSheetRowType.textField => row.value ?? '',
    };
  }

  String _sliderValueFor(AppleLiquidSheetRow row) {
    final double min = row.min ?? 0;
    final double max = row.max ?? 1;
    final double value = (row.sliderValue ?? min).clamp(min, max);

    if (min == 0 && max == 1) {
      return '${(value * 100).round()}%';
    }

    return value.toStringAsFixed(2).replaceAll(RegExp(r'\.00$'), '');
  }
}

class _TemplateSheetFallbackToolbarButton extends StatelessWidget {
  const _TemplateSheetFallbackToolbarButton({
    required this.action,
    required this.onPressed,
    this.isFilled = false,
  });

  final AppleLiquidSheetToolbarAction action;
  final VoidCallback onPressed;
  final bool isFilled;

  @override
  Widget build(BuildContext context) {
    final String tooltip =
        action.semanticLabel ?? action.title ?? action.systemImage ?? 'Action';
    final Color? foregroundColor = action.foregroundColor;
    final Color? backgroundColor = action.backgroundColor;
    final Widget child = _label(foregroundColor);

    if (isFilled || backgroundColor != null) {
      return FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
        ),
        onPressed: onPressed,
        child: child,
      );
    }

    if (action.title != null) {
      return TextButton(
        style: TextButton.styleFrom(foregroundColor: foregroundColor),
        onPressed: onPressed,
        child: child,
      );
    }

    return IconButton(
      tooltip: tooltip,
      color: foregroundColor,
      onPressed: onPressed,
      icon: child,
    );
  }

  Widget _label(Color? foregroundColor) {
    final String? title = action.title;
    final String? systemImage = action.systemImage;

    if (title != null && systemImage != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(_iconFor(systemImage), size: 18, color: foregroundColor),
          const SizedBox(width: 6),
          Text(title),
        ],
      );
    }

    if (title != null) {
      return Text(title);
    }

    return Icon(_iconFor(systemImage), color: foregroundColor);
  }

  IconData _iconFor(String? systemImage) {
    return switch (systemImage) {
      'checkmark' => Icons.check_rounded,
      'xmark' => Icons.close_rounded,
      'xmark.circle' => Icons.cancel_rounded,
      _ => Icons.circle_outlined,
    };
  }
}

class _SettingsFallbackSection extends StatelessWidget {
  const _SettingsFallbackSection({
    required this.title,
    required this.titleColor,
    required this.children,
  });

  final String? title;
  final Color? titleColor;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (title != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              title!,
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(color: titleColor),
            ),
          ),
          const SizedBox(height: 8),
        ],
        DecoratedBox(
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _SettingsFallbackRow extends StatelessWidget {
  const _SettingsFallbackRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(child: Text(label)),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchDemoPage extends StatelessWidget {
  const _SwitchDemoPage({required this.values, required this.onChanged});

  final List<bool> values;
  final void Function(int index, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    return _DemoPageScaffold(
      title: 'Switch',
      subtitle:
          'Five native UIKit UISwitch controls embedded through UiKitView.',
      child: AppleLiquidSurface(
        height: 360,
        child: Column(
          children: <Widget>[
            for (int index = 0; index < values.length; index += 1)
              _SwitchSampleRow(
                label: 'Native switch ${index + 1}',
                value: values[index],
                tintColor: _switchTintColors[index],
                onChanged: (bool value) {
                  onChanged(index, value);
                },
              ),
          ],
        ),
      ),
    );
  }
}

const List<Color> _switchTintColors = <Color>[
  Color(0xFF14B8A6),
  Color(0xFF0EA5E9),
  Color(0xFF8B5CF6),
  Color(0xFFF97316),
  Color(0xFF22C55E),
];

class _SwitchSampleRow extends StatelessWidget {
  const _SwitchSampleRow({
    required this.label,
    required this.value,
    required this.tintColor,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final Color tintColor;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              '$label: ${value ? 'On' : 'Off'}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          AppleLiquidSwitch(
            value: value,
            tintColor: tintColor,
            onChanged: onChanged,
          ),
        ],
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
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 6),
        AppleLiquidSlider(
          value: value,
          step: step,
          tintColor: tintColor,
          valueLabelBuilder: (BuildContext context, double value) {
            return Text(
              '${(value * 100).round()}%',
              style: Theme.of(context).textTheme.labelLarge,
            );
          },
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
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          body,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}
