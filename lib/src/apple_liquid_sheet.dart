import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Native toolbar button configuration for [AppleLiquidSheetContent].
class AppleLiquidSheetToolbarAction {
  /// Creates a toolbar action rendered as native text, SF Symbol, or both.
  const AppleLiquidSheetToolbarAction({
    this.title,
    this.systemImage,
    this.semanticLabel,
    this.foregroundColor,
    this.backgroundColor,
  }) : assert(
         title != null || systemImage != null,
         'Provide either title or systemImage.',
       ),
       assert(title == null || title != ''),
       assert(systemImage == null || systemImage != ''),
       assert(semanticLabel == null || semanticLabel != '');

  /// Optional visible button title.
  final String? title;

  /// Optional SF Symbol name for an icon button or label button.
  final String? systemImage;

  /// Optional accessibility label. Defaults to [title] on iOS when omitted.
  final String? semanticLabel;

  /// Optional text and icon color.
  final Color? foregroundColor;

  /// Optional rounded background fill for the toolbar button.
  final Color? backgroundColor;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (title != null) 'title': title,
      if (systemImage != null) 'systemImage': systemImage,
      if (semanticLabel != null) 'semanticLabel': semanticLabel,
      if (foregroundColor != null)
        'foregroundColor': foregroundColor!.toARGB32(),
      if (backgroundColor != null)
        'backgroundColor': backgroundColor!.toARGB32(),
    };
  }
}

/// Declarative content rendered inside a native iOS Liquid Glass sheet.
///
/// The content is rendered by SwiftUI as a native `NavigationStack` and `Form`.
/// Interactive rows such as buttons, toggles, pickers, segmented controls,
/// sliders, and text fields keep their state locally inside the native sheet
/// for the duration of the presentation.
class AppleLiquidSheetContent {
  /// Creates native sheet content from form sections.
  const AppleLiquidSheetContent({
    this.title = 'Settings',
    this.doneSemanticLabel = 'Done',
    this.leadingAction,
    this.trailingAction,
    this.detents,
    this.showsSectionBackgrounds = true,
    this.sectionSpacing,
    required this.sections,
  }) : assert(
         sectionSpacing == null ||
             (sectionSpacing >= 0 && sectionSpacing <= 200),
       );

  /// Default content used when no custom content is passed.
  static const AppleLiquidSheetContent settings = AppleLiquidSheetContent(
    sections: <AppleLiquidSheetSection>[
      AppleLiquidSheetSection(
        title: 'Overview',
        rows: <AppleLiquidSheetRow>[
          AppleLiquidSheetRow.value(title: 'Component', value: 'Liquid Sheet'),
          AppleLiquidSheetRow.value(title: 'Mode', value: 'Navigation Form'),
          AppleLiquidSheetRow.navigation(
            title: 'Preview details',
            content: AppleLiquidSheetContent(
              title: 'Preview',
              sections: <AppleLiquidSheetSection>[
                AppleLiquidSheetSection(
                  title: 'Preview',
                  rows: <AppleLiquidSheetRow>[
                    AppleLiquidSheetRow.textField(
                      title: 'Title',
                      value: 'Sheet Preview',
                    ),
                    AppleLiquidSheetRow.textField(
                      title: 'Owner',
                      value: 'Design Team',
                    ),
                  ],
                ),
                AppleLiquidSheetSection(
                  title: 'Context',
                  rows: <AppleLiquidSheetRow>[
                    AppleLiquidSheetRow.value(title: 'Surface', value: 'Form'),
                    AppleLiquidSheetRow.value(
                      title: 'Detents',
                      value: 'Content-sized',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      AppleLiquidSheetSection(
        title: 'Appearance',
        rows: <AppleLiquidSheetRow>[
          AppleLiquidSheetRow.toggle(title: 'Liquid Glass', value: true),
          AppleLiquidSheetRow.toggle(title: 'Reduce motion'),
          AppleLiquidSheetRow.picker(
            title: 'Accent',
            options: <String>['Blue', 'Teal', 'Graphite'],
            selectedOption: 'Blue',
          ),
          AppleLiquidSheetRow.segmented(
            title: 'Layout',
            firstOption: 'List',
            secondOption: 'Grid',
            selectedOption: 'List',
          ),
          AppleLiquidSheetRow.slider(
            title: 'Intensity',
            value: 0.72,
            tintColor: Color(0xFF0A84FF),
          ),
        ],
      ),
      AppleLiquidSheetSection(
        title: 'Updates',
        rows: <AppleLiquidSheetRow>[
          AppleLiquidSheetRow.picker(
            title: 'Refresh',
            options: <String>['Manual', 'Daily', 'Weekly'],
            selectedOption: 'Daily',
          ),
          AppleLiquidSheetRow.navigation(
            title: 'Notification rules',
            content: AppleLiquidSheetContent(
              title: 'Rules',
              sections: <AppleLiquidSheetSection>[
                AppleLiquidSheetSection(
                  title: 'Rules',
                  rows: <AppleLiquidSheetRow>[
                    AppleLiquidSheetRow.toggle(
                      title: 'Critical updates',
                      value: true,
                    ),
                    AppleLiquidSheetRow.toggle(title: 'Weekly digest'),
                  ],
                ),
                AppleLiquidSheetSection(
                  title: 'Routing',
                  rows: <AppleLiquidSheetRow>[
                    AppleLiquidSheetRow.value(
                      title: 'Channel',
                      value: 'In-app',
                    ),
                    AppleLiquidSheetRow.value(
                      title: 'Priority',
                      value: 'Normal',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      AppleLiquidSheetSection(
        title: 'Metadata',
        rows: <AppleLiquidSheetRow>[
          AppleLiquidSheetRow.value(title: 'Platform', value: 'iOS'),
          AppleLiquidSheetRow.value(title: 'Status', value: 'Prototype'),
        ],
      ),
    ],
  );

  /// Native navigation title used by the sheet.
  final String title;

  /// Accessibility label for the default checkmark dismiss button.
  ///
  /// This is only used when [trailingAction] is null.
  final String doneSemanticLabel;

  /// Optional leading toolbar button, usually used for Cancel or Close.
  final AppleLiquidSheetToolbarAction? leadingAction;

  /// Optional trailing toolbar button, usually used for Confirm or Save.
  ///
  /// When null, iOS shows the default checkmark button.
  final AppleLiquidSheetToolbarAction? trailingAction;

  /// Optional per-page sheet detent configuration.
  ///
  /// Heights are interpreted as native iOS points. When null, iOS estimates the
  /// detents from the active form content.
  final AppleLiquidSheetDetents? detents;

  /// Whether native SwiftUI form sections keep their default backgrounds.
  ///
  /// Set this to false to render the rows without the rounded section boxes.
  final bool showsSectionBackgrounds;

  /// Optional spacing between native form sections in iOS points.
  ///
  /// When null, SwiftUI keeps its native default spacing. Custom spacing is
  /// supported natively on iOS 17 and newer.
  final double? sectionSpacing;

  /// Form sections rendered in order.
  final List<AppleLiquidSheetSection> sections;

  Map<String, Object?> toMap() {
    return _toMap();
  }

  Map<String, Object?> _toMap([
    _AppleLiquidSheetButtonActionRegistry? actionRegistry,
  ]) {
    return <String, Object?>{
      'title': title,
      'doneSemanticLabel': doneSemanticLabel,
      if (leadingAction != null) 'leadingAction': leadingAction!.toMap(),
      if (trailingAction != null) 'trailingAction': trailingAction!.toMap(),
      if (detents != null) 'detents': detents!.toMap(),
      if (!showsSectionBackgrounds) 'showsSectionBackgrounds': false,
      if (sectionSpacing != null) 'sectionSpacing': sectionSpacing,
      'sections': sections
          .map(
            (AppleLiquidSheetSection section) => section._toMap(actionRegistry),
          )
          .toList(),
    };
  }
}

/// Optional native sheet detent heights for one [AppleLiquidSheetContent] page.
class AppleLiquidSheetDetents {
  /// Creates custom detent heights for native iOS sheets.
  ///
  /// Heights are native iOS points. Omit [initialHeight] to keep the automatic
  /// content-sized starting detent. Omit [expandedHeight] to keep the automatic
  /// second detent behavior for oversized content. Set
  /// [allowsAutomaticExpansion] to false to keep a single detent when no
  /// [expandedHeight] is supplied.
  const AppleLiquidSheetDetents({
    this.initialHeight,
    this.expandedHeight,
    this.allowsAutomaticExpansion = true,
  }) : assert(initialHeight == null || initialHeight > 0),
       assert(expandedHeight == null || expandedHeight > 0),
       assert(
         initialHeight == null ||
             expandedHeight == null ||
             expandedHeight > initialHeight,
       );

  /// Starting sheet height in native iOS points.
  final double? initialHeight;

  /// Optional second, higher sheet height in native iOS points.
  final double? expandedHeight;

  /// Whether iOS may add a second detent for content it estimates as oversized.
  final bool allowsAutomaticExpansion;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (initialHeight != null) 'initialHeight': initialHeight,
      if (expandedHeight != null) 'expandedHeight': expandedHeight,
      if (!allowsAutomaticExpansion) 'allowsAutomaticExpansion': false,
    };
  }
}

/// A native SwiftUI `Form` section inside [AppleLiquidSheetContent].
class AppleLiquidSheetSection {
  /// Creates a section with optional title and rows.
  const AppleLiquidSheetSection({
    this.title,
    this.titleColor,
    this.titleHorizontalInset,
    this.titleLeadingInset,
    this.titleTrailingInset,
    this.titleSpacing,
    this.showsBackground,
    this.backgroundColor,
    this.borderColor,
    this.cornerRadius,
    required this.rows,
  }) : assert(
         cornerRadius == null || (cornerRadius >= 0 && cornerRadius <= 80),
       ),
       assert(
         titleHorizontalInset == null ||
             (titleHorizontalInset >= 0 && titleHorizontalInset <= 200),
       ),
       assert(
         titleLeadingInset == null ||
             (titleLeadingInset >= 0 && titleLeadingInset <= 200),
       ),
       assert(
         titleTrailingInset == null ||
             (titleTrailingInset >= 0 && titleTrailingInset <= 200),
       ),
       assert(
         titleSpacing == null || (titleSpacing >= 0 && titleSpacing <= 200),
       );

  /// Optional section header.
  final String? title;

  /// Optional custom color for the section header.
  final Color? titleColor;

  /// Optional absolute horizontal inset for the section header.
  ///
  /// The value uses native iOS points. Set it to `0` to align the title with
  /// the section edge, or leave it null to preserve SwiftUI's system inset.
  final double? titleHorizontalInset;

  /// Optional absolute leading inset for the section header.
  ///
  /// This overrides [titleHorizontalInset] only on the leading edge. When both
  /// values are null, SwiftUI's system inset is preserved.
  final double? titleLeadingInset;

  /// Optional absolute trailing inset for the section header.
  ///
  /// This overrides [titleHorizontalInset] only on the trailing edge. When
  /// both values are null, SwiftUI's system inset is preserved.
  final double? titleTrailingInset;

  /// Optional absolute spacing between the section title and its content.
  ///
  /// The value uses native iOS points. Set it to `0` to remove the native gap,
  /// or leave it null to preserve SwiftUI's system spacing.
  final double? titleSpacing;

  /// Whether this section keeps a native form background.
  ///
  /// When null, the section inherits
  /// [AppleLiquidSheetContent.showsSectionBackgrounds]. Set this to true or
  /// false to override the page-level setting for this section.
  final bool? showsBackground;

  /// Optional custom background color for this section.
  final Color? backgroundColor;

  /// Optional 1-point border color around this section.
  final Color? borderColor;

  /// Optional custom corner radius in native iOS points.
  final double? cornerRadius;

  /// Rows rendered in this section.
  final List<AppleLiquidSheetRow> rows;

  Map<String, Object?> toMap() {
    return _toMap();
  }

  Map<String, Object?> _toMap([
    _AppleLiquidSheetButtonActionRegistry? actionRegistry,
  ]) {
    return <String, Object?>{
      if (title != null) 'title': title,
      if (titleColor != null) 'titleColor': titleColor!.toARGB32(),
      if (titleHorizontalInset != null)
        'titleHorizontalInset': titleHorizontalInset,
      if (titleLeadingInset != null) 'titleLeadingInset': titleLeadingInset,
      if (titleTrailingInset != null) 'titleTrailingInset': titleTrailingInset,
      if (titleSpacing != null) 'titleSpacing': titleSpacing,
      if (showsBackground != null) 'showsBackground': showsBackground,
      if (backgroundColor != null)
        'backgroundColor': backgroundColor!.toARGB32(),
      if (borderColor != null) 'borderColor': borderColor!.toARGB32(),
      if (cornerRadius != null) 'cornerRadius': cornerRadius,
      'rows': rows
          .map((AppleLiquidSheetRow row) => row._toMap(actionRegistry))
          .toList(),
    };
  }
}

/// Font weights supported by [AppleLiquidSheetSegmentedStyle].
enum AppleLiquidSheetSegmentedFontWeight {
  /// The thinnest available native font weight.
  ultraLight('ultraLight'),

  /// A very thin native font weight.
  thin('thin'),

  /// A light native font weight.
  light('light'),

  /// The regular native font weight.
  regular('regular'),

  /// A medium native font weight.
  medium('medium'),

  /// A semibold native font weight.
  semibold('semibold'),

  /// A bold native font weight.
  bold('bold'),

  /// A heavy native font weight.
  heavy('heavy'),

  /// The heaviest available native font weight.
  black('black');

  const AppleLiquidSheetSegmentedFontWeight(this.platformValue);

  /// Value sent to the native SwiftUI implementation.
  final String platformValue;
}

/// Selection transition curves supported by [AppleLiquidSheetSegmentedStyle].
enum AppleLiquidSheetSegmentedAnimationCurve {
  /// Linear movement without easing.
  linear('linear'),

  /// Starts slowly and finishes faster.
  easeIn('easeIn'),

  /// Starts faster and settles slowly.
  easeOut('easeOut'),

  /// Smoothly eases at the beginning and end.
  easeInOut('easeInOut'),

  /// Spring movement with configurable damping.
  spring('spring');

  const AppleLiquidSheetSegmentedAnimationCurve(this.platformValue);

  /// Value sent to the native SwiftUI implementation.
  final String platformValue;
}

/// Visual configuration for [AppleLiquidSheetRow.segmented].
class AppleLiquidSheetSegmentedStyle {
  /// Creates a native two-button row style.
  const AppleLiquidSheetSegmentedStyle({
    this.selectedBackgroundColor,
    this.unselectedBackgroundColor,
    this.selectedTextColor,
    this.unselectedTextColor,
    this.selectedBorderColor,
    this.unselectedBorderColor,
    this.selectedShadowColor,
    this.titleColor,
    this.subtitleColor,
    this.buttonHeight = 46,
    this.cornerRadius = 14,
    this.buttonSpacing = 12,
    this.contentSpacing = 12,
    this.verticalPadding = 6,
    this.rowHorizontalInset,
    this.borderWidth = 1,
    this.selectedShadowRadius = 8,
    this.selectedShadowOffsetX = 0,
    this.selectedShadowOffsetY = 2,
    this.titleFontSize,
    this.subtitleFontSize,
    this.buttonFontSize,
    this.titleFontWeight = AppleLiquidSheetSegmentedFontWeight.semibold,
    this.subtitleFontWeight = AppleLiquidSheetSegmentedFontWeight.regular,
    this.buttonFontWeight = AppleLiquidSheetSegmentedFontWeight.semibold,
    this.minimumTextScaleFactor = 0.75,
    this.pressedScale = 0.98,
    this.pressedOpacity = 0.86,
    this.pressAnimationDuration = 0.12,
    this.selectionAnimationEnabled = true,
    this.selectionAnimationCurve =
        AppleLiquidSheetSegmentedAnimationCurve.easeInOut,
    this.selectionAnimationDuration = 0.15,
    this.selectionSpringDamping = 0.82,
  }) : assert(buttonHeight > 0),
       assert(cornerRadius >= 0),
       assert(buttonSpacing >= 0),
       assert(contentSpacing >= 0),
       assert(verticalPadding >= 0),
       assert(
         rowHorizontalInset == null ||
             (rowHorizontalInset >= 0 && rowHorizontalInset <= 80),
       ),
       assert(borderWidth >= 0),
       assert(selectedShadowRadius >= 0),
       assert(titleFontSize == null || titleFontSize > 0),
       assert(subtitleFontSize == null || subtitleFontSize > 0),
       assert(buttonFontSize == null || buttonFontSize > 0),
       assert(minimumTextScaleFactor > 0 && minimumTextScaleFactor <= 1),
       assert(pressedScale > 0 && pressedScale <= 1),
       assert(pressedOpacity > 0 && pressedOpacity <= 1),
       assert(pressAnimationDuration >= 0),
       assert(selectionAnimationDuration >= 0),
       assert(selectionSpringDamping > 0 && selectionSpringDamping <= 1);

  /// Selected button fill. Null uses the native accent tint.
  final Color? selectedBackgroundColor;

  /// Unselected button fill. Null uses the native adaptive fill.
  final Color? unselectedBackgroundColor;

  /// Selected button text color. Null uses the native accent color.
  final Color? selectedTextColor;

  /// Unselected button text color. Null uses the native primary color.
  final Color? unselectedTextColor;

  /// Selected button border color. Null uses the native accent color.
  final Color? selectedBorderColor;

  /// Unselected button border color. Null uses an adaptive subtle border.
  final Color? unselectedBorderColor;

  /// Selected button shadow color. Null uses a very subtle native highlight.
  final Color? selectedShadowColor;

  /// Row title and SF Symbol color. Null uses the native primary color.
  final Color? titleColor;

  /// Row subtitle color. Null uses the native secondary label color.
  final Color? subtitleColor;

  /// Button height in native iOS points.
  final double buttonHeight;

  /// Button corner radius in native iOS points.
  final double cornerRadius;

  /// Horizontal space between the two buttons in native iOS points.
  final double buttonSpacing;

  /// Vertical space between the row label and buttons in native iOS points.
  final double contentSpacing;

  /// Vertical padding around the complete row in native iOS points.
  final double verticalPadding;

  /// Optional horizontal inset for the surrounding SwiftUI form row.
  ///
  /// When null, SwiftUI keeps its native default row insets.
  final double? rowHorizontalInset;

  /// Button border width in native iOS points.
  final double borderWidth;

  /// Selected button shadow blur radius in native iOS points.
  final double selectedShadowRadius;

  /// Selected button shadow horizontal offset in native iOS points.
  final double selectedShadowOffsetX;

  /// Selected button shadow vertical offset in native iOS points.
  final double selectedShadowOffsetY;

  /// Optional row title font size. Null keeps native Dynamic Type sizing.
  final double? titleFontSize;

  /// Optional row subtitle font size. Null keeps native Dynamic Type sizing.
  final double? subtitleFontSize;

  /// Optional button font size. Null keeps native Dynamic Type sizing.
  final double? buttonFontSize;

  /// Row title font weight.
  final AppleLiquidSheetSegmentedFontWeight titleFontWeight;

  /// Row subtitle font weight.
  final AppleLiquidSheetSegmentedFontWeight subtitleFontWeight;

  /// Button label font weight.
  final AppleLiquidSheetSegmentedFontWeight buttonFontWeight;

  /// Smallest scale allowed for long button labels.
  final double minimumTextScaleFactor;

  /// Scale applied while a button is pressed.
  final double pressedScale;

  /// Opacity applied while a button is pressed.
  final double pressedOpacity;

  /// Press feedback animation duration in seconds.
  final double pressAnimationDuration;

  /// Whether the selected button background should animate between buttons.
  final bool selectionAnimationEnabled;

  /// Curve used when the selected button background moves between buttons.
  final AppleLiquidSheetSegmentedAnimationCurve selectionAnimationCurve;

  /// Selection transition duration in seconds.
  ///
  /// For [AppleLiquidSheetSegmentedAnimationCurve.spring], this is used as the
  /// spring response value.
  final double selectionAnimationDuration;

  /// Damping fraction for the spring selection transition.
  ///
  /// Only used when [selectionAnimationCurve] is
  /// [AppleLiquidSheetSegmentedAnimationCurve.spring].
  final double selectionSpringDamping;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (selectedBackgroundColor != null)
        'selectedBackgroundColor': selectedBackgroundColor!.toARGB32(),
      if (unselectedBackgroundColor != null)
        'unselectedBackgroundColor': unselectedBackgroundColor!.toARGB32(),
      if (selectedTextColor != null)
        'selectedTextColor': selectedTextColor!.toARGB32(),
      if (unselectedTextColor != null)
        'unselectedTextColor': unselectedTextColor!.toARGB32(),
      if (selectedBorderColor != null)
        'selectedBorderColor': selectedBorderColor!.toARGB32(),
      if (unselectedBorderColor != null)
        'unselectedBorderColor': unselectedBorderColor!.toARGB32(),
      if (selectedShadowColor != null)
        'selectedShadowColor': selectedShadowColor!.toARGB32(),
      if (titleColor != null) 'titleColor': titleColor!.toARGB32(),
      if (subtitleColor != null) 'subtitleColor': subtitleColor!.toARGB32(),
      'buttonHeight': buttonHeight,
      'cornerRadius': cornerRadius,
      'buttonSpacing': buttonSpacing,
      'contentSpacing': contentSpacing,
      'verticalPadding': verticalPadding,
      if (rowHorizontalInset != null) 'rowHorizontalInset': rowHorizontalInset,
      'borderWidth': borderWidth,
      'selectedShadowRadius': selectedShadowRadius,
      'selectedShadowOffsetX': selectedShadowOffsetX,
      'selectedShadowOffsetY': selectedShadowOffsetY,
      if (titleFontSize != null) 'titleFontSize': titleFontSize,
      if (subtitleFontSize != null) 'subtitleFontSize': subtitleFontSize,
      if (buttonFontSize != null) 'buttonFontSize': buttonFontSize,
      'titleFontWeight': titleFontWeight.platformValue,
      'subtitleFontWeight': subtitleFontWeight.platformValue,
      'buttonFontWeight': buttonFontWeight.platformValue,
      'minimumTextScaleFactor': minimumTextScaleFactor,
      'pressedScale': pressedScale,
      'pressedOpacity': pressedOpacity,
      'pressAnimationDuration': pressAnimationDuration,
      'selectionAnimationEnabled': selectionAnimationEnabled,
      'selectionAnimationCurve': selectionAnimationCurve.platformValue,
      'selectionAnimationDuration': selectionAnimationDuration,
      'selectionSpringDamping': selectionSpringDamping,
    };
  }
}

/// Visual configuration for [AppleLiquidSheetRow.identity].
class AppleLiquidSheetIdentityStyle {
  /// Creates a native identity-card style.
  const AppleLiquidSheetIdentityStyle({
    this.avatarSize = 44,
    this.iconSize = 20,
    this.cardPadding = 10,
    this.cornerRadius = 14,
    this.backgroundOpacity = 0.12,
  }) : assert(avatarSize > 0),
       assert(iconSize > 0),
       assert(iconSize <= avatarSize),
       assert(cardPadding >= 0),
       assert(cornerRadius >= 0),
       assert(backgroundOpacity >= 0 && backgroundOpacity <= 1);

  /// Diameter of the remote avatar or SF Symbol background in iOS points.
  final double avatarSize;

  /// SF Symbol size used by the identity fallback avatar in iOS points.
  final double iconSize;

  /// Padding between the identity content and card edges in iOS points.
  final double cardPadding;

  /// Identity-card corner radius in iOS points.
  final double cornerRadius;

  /// Opacity applied to the tint-derived identity-card background.
  final double backgroundOpacity;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'avatarSize': avatarSize,
      'iconSize': iconSize,
      'cardPadding': cardPadding,
      'cornerRadius': cornerRadius,
      'backgroundOpacity': backgroundOpacity,
    };
  }
}

/// Horizontal label alignment for [AppleLiquidSheetButtonStyle].
enum AppleLiquidSheetButtonAlignment {
  /// Aligns the icon and text to the leading edge.
  leading('leading'),

  /// Centers the icon and text.
  center('center'),

  /// Aligns the icon and text to the trailing edge.
  trailing('trailing');

  const AppleLiquidSheetButtonAlignment(this.platformValue);

  /// Value sent to the native SwiftUI implementation.
  final String platformValue;
}

/// Visual configuration for [AppleLiquidSheetRow.button].
class AppleLiquidSheetButtonStyle {
  /// Creates a native full-width button style.
  const AppleLiquidSheetButtonStyle({
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.subtitleColor,
    this.buttonHeight = 48,
    this.cornerRadius = 12,
    this.borderWidth = 1,
    this.backgroundOpacity = 0.08,
    this.horizontalPadding = 16,
    this.iconSpacing = 8,
    this.labelSpacing = 2,
    this.rowHorizontalInset = 16,
    this.rowVerticalInset = 6,
    this.rowTopInset,
    this.rowBottomInset,
    this.titleFontSize,
    this.subtitleFontSize,
    this.iconSize,
    this.titleFontWeight = AppleLiquidSheetSegmentedFontWeight.semibold,
    this.subtitleFontWeight = AppleLiquidSheetSegmentedFontWeight.regular,
    this.alignment = AppleLiquidSheetButtonAlignment.center,
    this.minimumTextScaleFactor = 0.75,
    this.pressedScale = 0.97,
    this.pressedOpacity = 0.86,
    this.disabledOpacity = 0.45,
    this.pressAnimationDuration = 0.14,
    this.showsFormBackground = false,
    this.showsSeparator = false,
  }) : assert(buttonHeight > 0),
       assert(cornerRadius >= 0),
       assert(borderWidth >= 0),
       assert(backgroundOpacity >= 0 && backgroundOpacity <= 1),
       assert(horizontalPadding >= 0),
       assert(iconSpacing >= 0),
       assert(labelSpacing >= 0),
       assert(rowHorizontalInset >= 0),
       assert(rowVerticalInset >= 0),
       assert(rowTopInset == null || rowTopInset >= 0),
       assert(rowBottomInset == null || rowBottomInset >= 0),
       assert(titleFontSize == null || titleFontSize > 0),
       assert(subtitleFontSize == null || subtitleFontSize > 0),
       assert(iconSize == null || iconSize > 0),
       assert(minimumTextScaleFactor > 0 && minimumTextScaleFactor <= 1),
       assert(pressedScale > 0 && pressedScale <= 1),
       assert(pressedOpacity > 0 && pressedOpacity <= 1),
       assert(disabledOpacity > 0 && disabledOpacity <= 1),
       assert(pressAnimationDuration >= 0);

  /// Explicit button fill. Null derives a translucent fill from `tintColor`.
  final Color? backgroundColor;

  /// Button title and icon color. Null uses the native primary color.
  final Color? foregroundColor;

  /// Button stroke color. Null uses the row's `tintColor`.
  final Color? borderColor;

  /// Subtitle color. Null uses the native secondary color.
  final Color? subtitleColor;

  /// Minimum button height in native iOS points.
  final double buttonHeight;

  /// Button corner radius in native iOS points.
  final double cornerRadius;

  /// Button stroke width in native iOS points.
  final double borderWidth;

  /// Opacity used for the tint-derived background fill.
  final double backgroundOpacity;

  /// Horizontal padding around the button label.
  final double horizontalPadding;

  /// Space between the SF Symbol and text.
  final double iconSpacing;

  /// Space between title and subtitle.
  final double labelSpacing;

  /// Horizontal inset applied to the surrounding SwiftUI form row.
  final double rowHorizontalInset;

  /// Default vertical inset applied to the surrounding SwiftUI form row.
  ///
  /// [rowTopInset] and [rowBottomInset] can override the individual sides.
  final double rowVerticalInset;

  /// Optional top inset for the surrounding SwiftUI form row.
  ///
  /// On iOS 17 and newer this is the complete distance to a preceding native
  /// form section when the button starts its own section.
  final double? rowTopInset;

  /// Optional bottom inset for the surrounding SwiftUI form row.
  ///
  /// On iOS 17 and newer this is the complete distance to the next native form
  /// section or the form's bottom edge. A value of zero adds no extra space.
  final double? rowBottomInset;

  /// Optional title font size. Null keeps native Dynamic Type sizing.
  final double? titleFontSize;

  /// Optional subtitle font size. Null keeps native Dynamic Type sizing.
  final double? subtitleFontSize;

  /// Optional SF Symbol size. Null keeps native Dynamic Type sizing.
  final double? iconSize;

  /// Button title font weight.
  final AppleLiquidSheetSegmentedFontWeight titleFontWeight;

  /// Button subtitle font weight.
  final AppleLiquidSheetSegmentedFontWeight subtitleFontWeight;

  /// Horizontal alignment of the complete label.
  final AppleLiquidSheetButtonAlignment alignment;

  /// Smallest scale allowed for long labels.
  final double minimumTextScaleFactor;

  /// Scale applied while the button is pressed.
  final double pressedScale;

  /// Opacity applied while the button is pressed.
  final double pressedOpacity;

  /// Opacity applied while the button is disabled.
  final double disabledOpacity;

  /// Press feedback animation duration in seconds.
  final double pressAnimationDuration;

  /// Whether the surrounding native form row keeps its default background.
  final bool showsFormBackground;

  /// Whether the surrounding native form row displays a separator.
  final bool showsSeparator;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      if (backgroundColor != null)
        'backgroundColor': backgroundColor!.toARGB32(),
      if (foregroundColor != null)
        'foregroundColor': foregroundColor!.toARGB32(),
      if (borderColor != null) 'borderColor': borderColor!.toARGB32(),
      if (subtitleColor != null) 'subtitleColor': subtitleColor!.toARGB32(),
      'buttonHeight': buttonHeight,
      'cornerRadius': cornerRadius,
      'borderWidth': borderWidth,
      'backgroundOpacity': backgroundOpacity,
      'horizontalPadding': horizontalPadding,
      'iconSpacing': iconSpacing,
      'labelSpacing': labelSpacing,
      'rowHorizontalInset': rowHorizontalInset,
      'rowVerticalInset': rowVerticalInset,
      if (rowTopInset != null) 'rowTopInset': rowTopInset,
      if (rowBottomInset != null) 'rowBottomInset': rowBottomInset,
      if (titleFontSize != null) 'titleFontSize': titleFontSize,
      if (subtitleFontSize != null) 'subtitleFontSize': subtitleFontSize,
      if (iconSize != null) 'iconSize': iconSize,
      'titleFontWeight': titleFontWeight.platformValue,
      'subtitleFontWeight': subtitleFontWeight.platformValue,
      'alignment': alignment.platformValue,
      'minimumTextScaleFactor': minimumTextScaleFactor,
      'pressedScale': pressedScale,
      'pressedOpacity': pressedOpacity,
      'disabledOpacity': disabledOpacity,
      'pressAnimationDuration': pressAnimationDuration,
      'showsFormBackground': showsFormBackground,
      'showsSeparator': showsSeparator,
    };
  }
}

/// Callback invoked when a native sheet button is pressed.
typedef AppleLiquidSheetButtonCallback = void Function();

/// Callback invoked when a native multi-picker selection changes.
typedef AppleLiquidSheetMultiSelectionCallback =
    void Function(List<String> selectedOptions);

/// Native row types supported by [AppleLiquidSheetRow].
enum AppleLiquidSheetRowType {
  /// Plain title/subtitle row.
  text('text'),

  /// Label-value row rendered as native `LabeledContent`.
  value('value'),

  /// Native SwiftUI toggle with local state.
  toggle('toggle'),

  /// Native SwiftUI navigation-link picker with local state.
  picker('picker'),

  /// Native navigation-link picker that allows multiple selections.
  multiPicker('multiPicker'),

  /// Native two-option button group with local state.
  segmented('segmented'),

  /// Native full-width outlined button.
  button('button'),

  /// Native SwiftUI slider with local state.
  slider('slider'),

  /// Navigation row that pushes nested [AppleLiquidSheetContent].
  navigation('navigation'),

  /// Native SwiftUI text field with local state.
  textField('textField'),

  /// Highlighted identity header with a role and activity type.
  identity('identity'),

  /// Connected sequence of past, current, and upcoming status steps.
  timeline('timeline'),

  /// Compact grid of short labeled facts.
  factsGrid('factsGrid');

  const AppleLiquidSheetRowType(this.platformValue);

  /// Value sent over the platform channel.
  final String platformValue;
}

/// A single step rendered by [AppleLiquidSheetRow.timeline].
@immutable
class AppleLiquidSheetTimelineStep {
  /// Creates a timeline step.
  const AppleLiquidSheetTimelineStep({
    required this.title,
    this.subtitle,
    this.systemImage,
  }) : assert(title != '');

  /// Main status text.
  final String title;

  /// Optional supporting text, such as a date or short explanation.
  final String? subtitle;

  /// Optional SF Symbol for the current or upcoming marker.
  ///
  /// Completed steps always use a checkmark.
  final String? systemImage;

  Map<String, Object?> toMap() => <String, Object?>{
    'title': title,
    if (subtitle != null) 'subtitle': subtitle,
    if (systemImage != null) 'systemImage': systemImage,
  };
}

/// A compact label-value item rendered by [AppleLiquidSheetRow.factsGrid].
@immutable
class AppleLiquidSheetFact {
  /// Creates a fact grid item.
  const AppleLiquidSheetFact({
    required this.label,
    required this.value,
    this.systemImage,
  }) : assert(label != ''),
       assert(value != '');

  /// Short descriptor, for example `Termin` or `Ort`.
  final String label;

  /// Short value displayed below the label.
  final String value;

  /// Optional SF Symbol displayed beside the label.
  final String? systemImage;

  Map<String, Object?> toMap() => <String, Object?>{
    'label': label,
    'value': value,
    if (systemImage != null) 'systemImage': systemImage,
  };
}

/// Placement for the value text rendered by [AppleLiquidSheetRow.slider].
enum AppleLiquidSheetSliderValuePlacement {
  /// Shows the value at the trailing edge of the title row above the slider.
  topTrailing('topTrailing'),

  /// Shows the value to the right of the slider track.
  besideTrack('besideTrack');

  const AppleLiquidSheetSliderValuePlacement(this.platformValue);

  /// Value sent over the platform channel.
  final String platformValue;
}

/// Placement for the selection summary rendered by
/// [AppleLiquidSheetRow.multiPicker].
enum AppleLiquidSheetMultiPickerLabelPlacement {
  /// Shows the fixed row title first and the selection summary at the trailing
  /// edge.
  trailing('trailing'),

  /// Shows the selection summary as the primary row label. The fixed title is
  /// still used as the title of the pushed picker page.
  primary('primary');

  const AppleLiquidSheetMultiPickerLabelPlacement(this.platformValue);

  /// Value sent over the platform channel.
  final String platformValue;
}

/// A row rendered inside a native iOS Liquid Glass sheet form.
class AppleLiquidSheetRow {
  const AppleLiquidSheetRow._({
    required this.type,
    required this.title,
    this.subtitle,
    this.value,
    this.boolValue,
    List<String> options = const <String>[],
    String? firstSegmentOption,
    String? secondSegmentOption,
    this.selectedOption,
    List<String> selectedOptions = const <String>[],
    Map<String, String> selectionSystemImages = const <String, String>{},
    this.sliderValue,
    this.valueSuffix,
    this.min,
    this.max,
    this.step,
    this.tintColor,
    this.sliderValuePlacement =
        AppleLiquidSheetSliderValuePlacement.topTrailing,
    this.rowHorizontalInset,
    this.rowLeadingInset,
    this.rowTrailingInset,
    this.selectionLabelPlacement =
        AppleLiquidSheetMultiPickerLabelPlacement.trailing,
    this.content,
    this.systemImage,
    this.role,
    this.activityType,
    this.description,
    this.avatarUrl,
    this.identityStyle,
    List<AppleLiquidSheetTimelineStep> timelineSteps =
        const <AppleLiquidSheetTimelineStep>[],
    this.currentStepIndex,
    this.collapsedStepLimit,
    this.initiallyExpanded = false,
    this.expandLabel = 'Alle Schritte anzeigen',
    this.collapseLabel = 'Weniger anzeigen',
    List<AppleLiquidSheetFact> facts = const <AppleLiquidSheetFact>[],
    this.columns,
    this.chevronColor,
    this.segmentedStyle,
    this.buttonStyle,
    this.buttonSemanticLabel,
    this.buttonDismissesSheet = false,
    this.buttonEnabled = true,
    this.onButtonPressed,
    this.onMultiSelectionChanged,
  }) : _options = options,
       _selectedOptions = selectedOptions,
       _selectionSystemImages = selectionSystemImages,
       _timelineSteps = timelineSteps,
       _facts = facts,
       _firstSegmentOption = firstSegmentOption,
       _secondSegmentOption = secondSegmentOption,
       assert(
         type != AppleLiquidSheetRowType.slider || (min ?? 0) < (max ?? 1),
       ),
       assert(
         type != AppleLiquidSheetRowType.slider || step == null || step > 0,
       ),
       assert(
         type != AppleLiquidSheetRowType.slider ||
             step == null ||
             step <= (max ?? 1) - (min ?? 0),
       ),
       assert(
         (type != AppleLiquidSheetRowType.slider &&
                 type != AppleLiquidSheetRowType.identity) ||
             rowHorizontalInset == null ||
             (rowHorizontalInset >= 0 && rowHorizontalInset <= 80),
       ),
       assert(
         type != AppleLiquidSheetRowType.slider ||
             rowLeadingInset == null ||
             (rowLeadingInset >= 0 && rowLeadingInset <= 80),
       ),
       assert(
         type != AppleLiquidSheetRowType.slider ||
             rowTrailingInset == null ||
             (rowTrailingInset >= 0 && rowTrailingInset <= 80),
       ),
       assert(
         type != AppleLiquidSheetRowType.segmented ||
             firstSegmentOption != null && secondSegmentOption != null,
       ),
       assert(
         type != AppleLiquidSheetRowType.segmented ||
             firstSegmentOption != '' && secondSegmentOption != '',
       ),
       assert(
         type != AppleLiquidSheetRowType.segmented ||
             firstSegmentOption != secondSegmentOption,
       ),
       assert(type != AppleLiquidSheetRowType.identity || role != null),
       assert(type != AppleLiquidSheetRowType.identity || role != ''),
       assert(type != AppleLiquidSheetRowType.identity || activityType != null),
       assert(type != AppleLiquidSheetRowType.identity || activityType != ''),
       assert(
         type != AppleLiquidSheetRowType.identity ||
             description == null ||
             description != '',
       ),
       assert(
         type != AppleLiquidSheetRowType.identity ||
             avatarUrl == null ||
             avatarUrl != '',
       ),
       assert(
         type != AppleLiquidSheetRowType.factsGrid ||
             columns != null && columns >= 1 && columns <= 4,
       );

  /// Creates a plain text row.
  const AppleLiquidSheetRow.text({
    required String title,
    String? subtitle,
    String? systemImage,
  }) : this._(
         type: AppleLiquidSheetRowType.text,
         title: title,
         subtitle: subtitle,
         systemImage: systemImage,
       );

  /// Creates a label-value row.
  const AppleLiquidSheetRow.value({
    required String title,
    required String value,
    String? subtitle,
    String? systemImage,
  }) : this._(
         type: AppleLiquidSheetRowType.value,
         title: title,
         subtitle: subtitle,
         value: value,
         systemImage: systemImage,
       );

  /// Creates a native toggle row.
  const AppleLiquidSheetRow.toggle({
    required String title,
    bool value = false,
    String? subtitle,
    String? systemImage,
  }) : this._(
         type: AppleLiquidSheetRowType.toggle,
         title: title,
         subtitle: subtitle,
         boolValue: value,
         systemImage: systemImage,
       );

  /// Creates a native picker row.
  const AppleLiquidSheetRow.picker({
    required String title,
    required List<String> options,
    String? selectedOption,
    String? subtitle,
    String? systemImage,
    Color? chevronColor,
  }) : this._(
         type: AppleLiquidSheetRowType.picker,
         title: title,
         subtitle: subtitle,
         options: options,
         selectedOption: selectedOption,
         systemImage: systemImage,
         chevronColor: chevronColor,
       );

  /// Creates a native picker row that allows multiple selected options.
  const AppleLiquidSheetRow.multiPicker({
    required String title,
    required List<String> options,
    List<String> selectedOptions = const <String>[],
    String? subtitle,
    String? systemImage,
    Color? chevronColor,
    Map<String, String> selectionSystemImages = const <String, String>{},
    AppleLiquidSheetMultiPickerLabelPlacement selectionLabelPlacement =
        AppleLiquidSheetMultiPickerLabelPlacement.trailing,
    AppleLiquidSheetMultiSelectionCallback? onSelectionChanged,
  }) : this._(
         type: AppleLiquidSheetRowType.multiPicker,
         title: title,
         subtitle: subtitle,
         options: options,
         selectedOptions: selectedOptions,
         systemImage: systemImage,
         chevronColor: chevronColor,
         selectionSystemImages: selectionSystemImages,
         selectionLabelPlacement: selectionLabelPlacement,
         onMultiSelectionChanged: onSelectionChanged,
       );

  /// Creates a native segmented row with two side-by-side options.
  const AppleLiquidSheetRow.segmented({
    required String title,
    required String firstOption,
    required String secondOption,
    String? selectedOption,
    String? subtitle,
    String? systemImage,
    AppleLiquidSheetSegmentedStyle? style,
  }) : this._(
         type: AppleLiquidSheetRowType.segmented,
         title: title,
         subtitle: subtitle,
         firstSegmentOption: firstOption,
         secondSegmentOption: secondOption,
         selectedOption: selectedOption,
         systemImage: systemImage,
         segmentedStyle: style,
       );

  /// Creates a native full-width outlined button row.
  ///
  /// [onPressed] is invoked in Dart through the sheet method channel. Use
  /// [style] to configure the complete native appearance and form-row layout.
  const AppleLiquidSheetRow.button({
    required String title,
    Color? tintColor,
    String? subtitle,
    String? systemImage,
    String? semanticLabel,
    bool dismissesSheet = false,
    bool enabled = true,
    AppleLiquidSheetButtonStyle? style,
    AppleLiquidSheetButtonCallback? onPressed,
  }) : this._(
         type: AppleLiquidSheetRowType.button,
         title: title,
         subtitle: subtitle,
         tintColor: tintColor,
         systemImage: systemImage,
         buttonSemanticLabel: semanticLabel,
         buttonDismissesSheet: dismissesSheet,
         buttonEnabled: enabled,
         buttonStyle: style,
         onButtonPressed: onPressed,
       );

  /// Creates a native slider row.
  const AppleLiquidSheetRow.slider({
    required String title,
    double value = 0,
    double min = 0,
    double max = 1,
    double? step,
    String? valueSuffix,
    Color? tintColor,
    AppleLiquidSheetSliderValuePlacement valuePlacement =
        AppleLiquidSheetSliderValuePlacement.topTrailing,
    double? rowHorizontalInset,
    double? rowLeadingInset,
    double? rowTrailingInset,
    String? subtitle,
    String? systemImage,
  }) : this._(
         type: AppleLiquidSheetRowType.slider,
         title: title,
         subtitle: subtitle,
         sliderValue: value,
         min: min,
         max: max,
         step: step,
         valueSuffix: valueSuffix,
         tintColor: tintColor,
         sliderValuePlacement: valuePlacement,
         rowHorizontalInset: rowHorizontalInset,
         rowLeadingInset: rowLeadingInset,
         rowTrailingInset: rowTrailingInset,
         systemImage: systemImage,
       );

  /// Creates a navigation row with nested sheet content.
  const AppleLiquidSheetRow.navigation({
    required String title,
    required AppleLiquidSheetContent content,
    String? subtitle,
    String? systemImage,
    Color? chevronColor,
  }) : this._(
         type: AppleLiquidSheetRowType.navigation,
         title: title,
         subtitle: subtitle,
         content: content,
         systemImage: systemImage,
         chevronColor: chevronColor,
       );

  /// Creates a native text field row.
  const AppleLiquidSheetRow.textField({
    required String title,
    String value = '',
    String? subtitle,
    String? systemImage,
  }) : this._(
         type: AppleLiquidSheetRowType.textField,
         title: title,
         subtitle: subtitle,
         value: value,
         systemImage: systemImage,
       );

  /// Creates a highlighted identity header.
  ///
  /// [systemImage] is used as the avatar fallback. When [avatarUrl] is set and
  /// the image can be loaded, the remote avatar is shown instead.
  /// [description] is rendered below the activity type inside the same card.
  /// [style] configures the card geometry and avatar presentation.
  const AppleLiquidSheetRow.identity({
    required String title,
    required String role,
    required String activityType,
    String? description,
    String? systemImage,
    String? avatarUrl,
    Color? tintColor,
    double? rowHorizontalInset,
    AppleLiquidSheetIdentityStyle? style,
  }) : this._(
         type: AppleLiquidSheetRowType.identity,
         title: title,
         role: role,
         activityType: activityType,
         description: description,
         systemImage: systemImage,
         avatarUrl: avatarUrl,
         tintColor: tintColor,
         rowHorizontalInset: rowHorizontalInset,
         identityStyle: style,
       );

  /// Creates a connected status timeline.
  ///
  /// Steps before [currentStepIndex] are rendered as completed, the indexed
  /// step is highlighted, and later steps remain subdued. Set
  /// [collapsedStepLimit] to add a native expand/collapse control whose state
  /// remains internal to SwiftUI while the sheet is presented.
  factory AppleLiquidSheetRow.timeline({
    required String title,
    required List<AppleLiquidSheetTimelineStep> steps,
    required int currentStepIndex,
    int? collapsedStepLimit,
    bool initiallyExpanded = false,
    String expandLabel = 'Alle Schritte anzeigen',
    String collapseLabel = 'Weniger anzeigen',
    Color? tintColor,
  }) {
    assert(steps.isNotEmpty);
    assert(currentStepIndex >= 0 && currentStepIndex < steps.length);
    assert(collapsedStepLimit == null || collapsedStepLimit > 0);
    assert(collapsedStepLimit == null || expandLabel.isNotEmpty);
    assert(collapsedStepLimit == null || collapseLabel.isNotEmpty);
    return AppleLiquidSheetRow._(
      type: AppleLiquidSheetRowType.timeline,
      title: title,
      timelineSteps: steps,
      currentStepIndex: currentStepIndex,
      collapsedStepLimit: collapsedStepLimit,
      initiallyExpanded: initiallyExpanded,
      expandLabel: expandLabel,
      collapseLabel: collapseLabel,
      tintColor: tintColor,
    );
  }

  /// Creates a compact grid of short facts.
  ///
  /// [columns] accepts values from 1 through 4 and defaults to three compact
  /// columns.
  factory AppleLiquidSheetRow.factsGrid({
    required String title,
    required List<AppleLiquidSheetFact> facts,
    int columns = 3,
    Color? tintColor,
  }) {
    assert(facts.isNotEmpty);
    assert(columns >= 1 && columns <= 4);
    return AppleLiquidSheetRow._(
      type: AppleLiquidSheetRowType.factsGrid,
      title: title,
      facts: facts,
      columns: columns,
      tintColor: tintColor,
    );
  }

  /// Row type rendered on iOS.
  final AppleLiquidSheetRowType type;

  /// Main row title.
  final String title;

  /// Optional secondary text shown below the title where the native row supports
  /// it.
  final String? subtitle;

  /// Text value for [AppleLiquidSheetRow.value] and initial text-field value.
  final String? value;

  /// Initial toggle value for [AppleLiquidSheetRow.toggle].
  final bool? boolValue;

  final List<String> _options;
  final List<String> _selectedOptions;
  final Map<String, String> _selectionSystemImages;
  final String? _firstSegmentOption;
  final String? _secondSegmentOption;

  /// Options for picker and segmented rows.
  ///
  /// [AppleLiquidSheetRow.segmented] always returns its two distinct values.
  List<String> get options {
    if (type == AppleLiquidSheetRowType.segmented) {
      return <String>[_firstSegmentOption!, _secondSegmentOption!];
    }

    return _options;
  }

  /// Initial picker or segmented selection.
  ///
  /// Defaults to the first option on iOS when null or not present in [options].
  final String? selectedOption;

  /// Initial selections for [AppleLiquidSheetRow.multiPicker].
  List<String> get selectedOptions =>
      List<String>.unmodifiable(_selectedOptions.where(options.contains));

  /// SF Symbols used for individual multi-picker selections.
  ///
  /// Entries whose keys are not present in [options] are ignored. When more
  /// than one option is selected, [systemImage] remains the fallback icon.
  Map<String, String> get selectionSystemImages =>
      Map<String, String>.unmodifiable(<String, String>{
        for (final MapEntry<String, String> entry
            in _selectionSystemImages.entries)
          if (options.contains(entry.key) && entry.value.isNotEmpty)
            entry.key: entry.value,
      });

  /// Initial slider value for [AppleLiquidSheetRow.slider].
  final double? sliderValue;

  /// Optional suffix appended to the rendered slider value.
  final String? valueSuffix;

  /// Smallest selectable slider value.
  final double? min;

  /// Largest selectable slider value.
  final double? max;

  /// Optional fixed slider increment.
  final double? step;

  /// Optional accent color for sliders, buttons, and structured rows.
  final Color? tintColor;

  /// Placement for the slider value text.
  final AppleLiquidSheetSliderValuePlacement sliderValuePlacement;

  /// Optional absolute horizontal form-row inset for slider or identity content.
  ///
  /// The value uses native iOS points. Set it to `0` to align the supported row
  /// with the section edge, or leave it null to preserve SwiftUI's system inset.
  final double? rowHorizontalInset;

  /// Optional absolute leading form-row inset for slider content.
  ///
  /// This overrides [rowHorizontalInset] only on the leading edge. When both
  /// values are null, SwiftUI's system inset is preserved.
  final double? rowLeadingInset;

  /// Optional absolute trailing form-row inset for slider content.
  ///
  /// This overrides [rowHorizontalInset] only on the trailing edge. When both
  /// values are null, SwiftUI's system inset is preserved.
  final double? rowTrailingInset;

  /// Placement for the selection summary of a multi-picker row.
  final AppleLiquidSheetMultiPickerLabelPlacement selectionLabelPlacement;

  /// Nested content for [AppleLiquidSheetRow.navigation].
  final AppleLiquidSheetContent? content;

  /// Optional SF Symbol name used by native rows that can show a label icon.
  final String? systemImage;

  /// Role shown by [AppleLiquidSheetRow.identity].
  final String? role;

  /// Activity type shown by [AppleLiquidSheetRow.identity].
  final String? activityType;

  /// Optional description shown inside [AppleLiquidSheetRow.identity].
  final String? description;

  /// Optional remote avatar URL for [AppleLiquidSheetRow.identity].
  final String? avatarUrl;

  /// Visual style for [AppleLiquidSheetRow.identity].
  final AppleLiquidSheetIdentityStyle? identityStyle;

  final List<AppleLiquidSheetTimelineStep> _timelineSteps;

  /// Ordered steps rendered by [AppleLiquidSheetRow.timeline].
  List<AppleLiquidSheetTimelineStep> get timelineSteps =>
      List<AppleLiquidSheetTimelineStep>.unmodifiable(_timelineSteps);

  /// Index of the active step in [timelineSteps].
  final int? currentStepIndex;

  /// Maximum number of steps shown while the timeline is collapsed.
  ///
  /// Leave this null to keep the timeline permanently expanded. When the
  /// timeline contains no more steps than this limit, no toggle is rendered.
  final int? collapsedStepLimit;

  /// Whether a collapsible timeline starts in its expanded state.
  final bool initiallyExpanded;

  /// Button label used to reveal all timeline steps.
  final String expandLabel;

  /// Button label used to collapse the timeline.
  final String collapseLabel;

  final List<AppleLiquidSheetFact> _facts;

  /// Items rendered by [AppleLiquidSheetRow.factsGrid].
  List<AppleLiquidSheetFact> get facts =>
      List<AppleLiquidSheetFact>.unmodifiable(_facts);

  /// Number of columns used by [AppleLiquidSheetRow.factsGrid].
  final int? columns;

  /// Optional color for the navigation chevron.
  ///
  /// Supported by picker, multi-picker, and navigation rows. When null, the
  /// native SwiftUI chevron and its system color are preserved.
  final Color? chevronColor;

  /// Visual style for [AppleLiquidSheetRow.segmented].
  final AppleLiquidSheetSegmentedStyle? segmentedStyle;

  /// Visual style for [AppleLiquidSheetRow.button].
  final AppleLiquidSheetButtonStyle? buttonStyle;

  /// Optional accessibility label for [AppleLiquidSheetRow.button].
  final String? buttonSemanticLabel;

  /// Whether a button press dismisses the native sheet.
  final bool buttonDismissesSheet;

  /// Whether the native button accepts interaction.
  final bool buttonEnabled;

  /// Optional Dart callback invoked for [AppleLiquidSheetRow.button].
  final AppleLiquidSheetButtonCallback? onButtonPressed;

  /// Called whenever the selection of a multi-picker changes.
  final AppleLiquidSheetMultiSelectionCallback? onMultiSelectionChanged;

  Map<String, Object?> toMap() {
    return _toMap();
  }

  Map<String, Object?> _toMap([
    _AppleLiquidSheetButtonActionRegistry? actionRegistry,
  ]) {
    final String? buttonActionId = type == AppleLiquidSheetRowType.button
        ? actionRegistry?.register(onButtonPressed)
        : null;
    final String? multiSelectionActionId =
        type == AppleLiquidSheetRowType.multiPicker
        ? actionRegistry?.registerMultiSelection(onMultiSelectionChanged)
        : null;

    return <String, Object?>{
      'type': type.platformValue,
      'title': title,
      if (subtitle != null) 'subtitle': subtitle,
      if (value != null) 'value': value,
      if (boolValue != null) 'boolValue': boolValue,
      if (options.isNotEmpty) 'options': options,
      if (selectedOption != null) 'selectedOption': selectedOption,
      if (selectedOptions.isNotEmpty) 'selectedOptions': selectedOptions,
      if (sliderValue != null) 'sliderValue': sliderValue,
      if (valueSuffix != null) 'valueSuffix': valueSuffix,
      if (min != null) 'min': min,
      if (max != null) 'max': max,
      if (step != null) 'step': step,
      if (tintColor != null) 'tintColor': tintColor!.toARGB32(),
      if (type == AppleLiquidSheetRowType.slider &&
          sliderValuePlacement !=
              AppleLiquidSheetSliderValuePlacement.topTrailing)
        'sliderValuePlacement': sliderValuePlacement.platformValue,
      if ((type == AppleLiquidSheetRowType.slider ||
              type == AppleLiquidSheetRowType.identity) &&
          rowHorizontalInset != null)
        'rowHorizontalInset': rowHorizontalInset,
      if (type == AppleLiquidSheetRowType.slider && rowLeadingInset != null)
        'rowLeadingInset': rowLeadingInset,
      if (type == AppleLiquidSheetRowType.slider && rowTrailingInset != null)
        'rowTrailingInset': rowTrailingInset,
      if (type == AppleLiquidSheetRowType.multiPicker &&
          selectionLabelPlacement !=
              AppleLiquidSheetMultiPickerLabelPlacement.trailing)
        'selectionLabelPlacement': selectionLabelPlacement.platformValue,
      if (type == AppleLiquidSheetRowType.multiPicker &&
          selectionSystemImages.isNotEmpty)
        'selectionSystemImages': selectionSystemImages,
      if (content != null) 'content': content!._toMap(actionRegistry),
      if (systemImage != null) 'systemImage': systemImage,
      if (role != null) 'role': role,
      if (activityType != null) 'activityType': activityType,
      if (description != null) 'description': description,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      if (identityStyle != null) 'identityStyle': identityStyle!.toMap(),
      if (timelineSteps.isNotEmpty)
        'steps': timelineSteps
            .map((AppleLiquidSheetTimelineStep step) => step.toMap())
            .toList(growable: false),
      if (currentStepIndex != null) 'currentStepIndex': currentStepIndex,
      if (type == AppleLiquidSheetRowType.timeline &&
          collapsedStepLimit != null) ...<String, Object?>{
        'collapsedStepLimit': collapsedStepLimit,
        'initiallyExpanded': initiallyExpanded,
        'expandLabel': expandLabel,
        'collapseLabel': collapseLabel,
      },
      if (facts.isNotEmpty)
        'facts': facts
            .map((AppleLiquidSheetFact fact) => fact.toMap())
            .toList(growable: false),
      if (columns != null) 'columns': columns,
      if ((type == AppleLiquidSheetRowType.picker ||
              type == AppleLiquidSheetRowType.multiPicker ||
              type == AppleLiquidSheetRowType.navigation) &&
          chevronColor != null)
        'chevronColor': chevronColor!.toARGB32(),
      if (segmentedStyle != null) 'segmentedStyle': segmentedStyle!.toMap(),
      if (buttonStyle != null) 'buttonStyle': buttonStyle!.toMap(),
      if (buttonSemanticLabel != null)
        'buttonSemanticLabel': buttonSemanticLabel,
      if (buttonDismissesSheet) 'buttonDismissesSheet': true,
      if (!buttonEnabled) 'buttonEnabled': false,
      if (buttonActionId != null) 'buttonActionId': buttonActionId,
      if (multiSelectionActionId != null)
        'multiSelectionActionId': multiSelectionActionId,
    };
  }
}

class _AppleLiquidSheetButtonActionRegistry {
  final Set<String> _actionIds = <String>{};
  final Set<String> _multiSelectionActionIds = <String>{};

  String? register(AppleLiquidSheetButtonCallback? callback) {
    if (callback == null) {
      return null;
    }

    final String actionId = AppleLiquidSheet._registerButtonAction(callback);
    _actionIds.add(actionId);
    return actionId;
  }

  String? registerMultiSelection(
    AppleLiquidSheetMultiSelectionCallback? callback,
  ) {
    if (callback == null) {
      return null;
    }

    final String actionId = AppleLiquidSheet._registerMultiSelectionAction(
      callback,
    );
    _multiSelectionActionIds.add(actionId);
    return actionId;
  }

  void dispose() {
    for (final String actionId in _actionIds) {
      AppleLiquidSheet._removeButtonAction(actionId);
    }
    _actionIds.clear();
    for (final String actionId in _multiSelectionActionIds) {
      AppleLiquidSheet._removeMultiSelectionAction(actionId);
    }
    _multiSelectionActionIds.clear();
  }
}

/// Imperative controller for the native iOS sheet.
class AppleLiquidSheetController extends ChangeNotifier {
  /// Creates a controller with default presentation options.
  AppleLiquidSheetController({
    double heightFraction = 1,
    double backgroundZoomScale = 1,
    Color? sheetColor,
    AppleLiquidSheetContent? content,
  }) : assert(heightFraction >= 0.25 && heightFraction <= 1),
       assert(backgroundZoomScale >= 0.85 && backgroundZoomScale <= 1),
       _heightFraction = heightFraction,
       _backgroundZoomScale = backgroundZoomScale,
       _sheetColor = sheetColor,
       _content = content;

  double _heightFraction;
  double _backgroundZoomScale;
  Color? _sheetColor;
  AppleLiquidSheetContent? _content;
  Future<bool>? _activeShow;
  bool _isShown = false;
  bool _isDisposed = false;

  /// Legacy maximum detent height option used by [showSheet].
  double get heightFraction => _heightFraction;

  set heightFraction(double value) {
    assert(value >= 0.25 && value <= 1);

    if (_heightFraction == value) {
      return;
    }

    _heightFraction = value;
    _notifyStateChanged();
  }

  /// Default presenting-page zoom scale used by [showTemplateSheet].
  double get backgroundZoomScale => _backgroundZoomScale;

  set backgroundZoomScale(double value) {
    assert(value >= 0.85 && value <= 1);

    if (_backgroundZoomScale == value) {
      return;
    }

    _backgroundZoomScale = value;
    _notifyStateChanged();
  }

  /// Optional sheet background color.
  ///
  /// When null, iOS uses an automatic dynamic color that adapts to light and
  /// dark mode.
  Color? get sheetColor => _sheetColor;

  set sheetColor(Color? value) {
    if (_sheetColor == value) {
      return;
    }

    _sheetColor = value;
    _notifyStateChanged();
  }

  /// Default native form content used by [showSheet].
  AppleLiquidSheetContent? get content => _content;

  set content(AppleLiquidSheetContent? value) {
    if (_content == value) {
      return;
    }

    _content = value;
    _notifyStateChanged();
  }

  /// Whether this controller currently has a native sheet presentation pending.
  bool get isShowing => _activeShow != null;

  /// Whether this controller considers the native sheet visible.
  bool get isShown => _isShown;

  /// Shows the native sheet.
  ///
  /// Returns false on unsupported platforms, when the native side cannot present
  /// a sheet. Repeated calls while a native presentation is already active
  /// return true so callers do not open a fallback sheet on top.
  Future<bool> showSheet({
    double? heightFraction,
    double? backgroundZoomScale,
    Color? sheetColor,
    AppleLiquidSheetContent? content,
    BuildContext? scrollContext,
  }) async {
    if (_activeShow != null) {
      return true;
    }

    if (!AppleLiquidSheet._supportsNativeSheets) {
      return false;
    }

    final double effectiveHeightFraction = heightFraction ?? _heightFraction;
    final double effectiveBackgroundZoomScale =
        backgroundZoomScale ?? _backgroundZoomScale;
    final Color? effectiveSheetColor = sheetColor ?? _sheetColor;
    final AppleLiquidSheetContent? effectiveContent = content ?? _content;

    assert(effectiveHeightFraction >= 0.25 && effectiveHeightFraction <= 1);
    assert(
      effectiveBackgroundZoomScale >= 0.85 && effectiveBackgroundZoomScale <= 1,
    );

    final Future<bool> showFuture = AppleLiquidSheet.showSheet(
      heightFraction: effectiveHeightFraction,
      backgroundZoomScale: effectiveBackgroundZoomScale,
      sheetColor: effectiveSheetColor,
      content: effectiveContent,
      scrollContext: scrollContext,
    );

    _updateState(activeShow: showFuture, isShown: true);

    try {
      return await showFuture;
    } finally {
      if (identical(_activeShow, showFuture)) {
        _updateState(clearActiveShow: true, isShown: false);
      }
    }
  }

  /// Shows the native sheet.
  ///
  /// This legacy name is kept for source compatibility with earlier releases.
  Future<bool> showTemplateSheet({
    double? heightFraction,
    double? backgroundZoomScale,
    Color? sheetColor,
    AppleLiquidSheetContent? content,
    BuildContext? scrollContext,
  }) {
    return showSheet(
      heightFraction: heightFraction,
      backgroundZoomScale: backgroundZoomScale,
      sheetColor: sheetColor,
      content: content,
      scrollContext: scrollContext,
    );
  }

  /// Dismisses the active native sheet.
  ///
  /// Returns false when no native sheet is active or the platform is unsupported.
  Future<bool> dismiss() async {
    final bool didDismiss = await AppleLiquidSheet.dismissTemplateSheet();
    if (didDismiss) {
      _updateState(isShown: false);
    }
    return didDismiss;
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _updateState({
    Future<bool>? activeShow,
    bool clearActiveShow = false,
    bool? isShown,
  }) {
    final Future<bool>? previousActiveShow = _activeShow;
    final bool previousIsShown = _isShown;

    if (clearActiveShow) {
      _activeShow = null;
    } else if (activeShow != null) {
      _activeShow = activeShow;
    }

    if (isShown != null) {
      _isShown = isShown;
    }

    if (!identical(previousActiveShow, _activeShow) ||
        previousIsShown != _isShown) {
      _notifyStateChanged();
    }
  }

  void _notifyStateChanged() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }
}

/// Builds a background subtree for [AppleLiquidSheetBackgroundInteractionGuard].
typedef AppleLiquidSheetBackgroundInteractionBuilder =
    Widget Function(BuildContext context, bool isBlocked, Widget? child);

/// Blocks or customizes Flutter background interaction while a sheet is active.
///
/// The guard listens to an [AppleLiquidSheetController]. By default it absorbs
/// pointer events and applies [lockedScrollPhysics] to descendant scrollables
/// while the controller is showing a native sheet.
class AppleLiquidSheetBackgroundInteractionGuard extends StatelessWidget {
  /// Creates a guard for Flutter content behind a native Liquid sheet.
  const AppleLiquidSheetBackgroundInteractionGuard({
    super.key,
    required this.controller,
    this.child,
    this.builder,
    this.enabled = true,
    this.absorbPointers = true,
    this.lockScrolling = true,
    this.lockedScrollPhysics = const NeverScrollableScrollPhysics(),
  }) : assert(
         child != null || builder != null,
         'Provide either child or builder.',
       );

  /// Controller whose sheet state drives the background interaction lock.
  final AppleLiquidSheetController controller;

  /// Optional child passed through to [builder] or guarded directly.
  final Widget? child;

  /// Optional builder for apps that need custom locked/unlocked rendering.
  final AppleLiquidSheetBackgroundInteractionBuilder? builder;

  /// Whether the guard should react to the controller state.
  final bool enabled;

  /// Whether pointer events should be absorbed while the sheet is active.
  final bool absorbPointers;

  /// Whether descendant scrollables should receive [lockedScrollPhysics].
  ///
  /// Scrollables with their own explicit physics keep their local setting.
  final bool lockScrolling;

  /// Scroll physics applied to descendants while [lockScrolling] is true.
  final ScrollPhysics lockedScrollPhysics;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      child: child,
      builder: (BuildContext context, Widget? child) {
        final bool isBlocked =
            enabled && (controller.isShowing || controller.isShown);
        Widget result = builder?.call(context, isBlocked, child) ?? child!;

        if (lockScrolling) {
          final ScrollBehavior baseBehavior = ScrollConfiguration.of(context);
          result = ScrollConfiguration(
            behavior: isBlocked
                ? baseBehavior.copyWith(physics: lockedScrollPhysics)
                : baseBehavior.copyWith(),
            child: result,
          );
        }

        if (absorbPointers) {
          result = AbsorbPointer(absorbing: isBlocked, child: result);
        }

        return result;
      },
    );
  }
}

/// Presents native iOS Liquid Glass sheets.
class AppleLiquidSheet {
  const AppleLiquidSheet._();

  static const MethodChannel _channel = MethodChannel('mjn_liquid_ui/sheets');
  static final Map<String, AppleLiquidSheetButtonCallback> _buttonActions =
      <String, AppleLiquidSheetButtonCallback>{};
  static final Map<String, AppleLiquidSheetMultiSelectionCallback>
  _multiSelectionActions = <String, AppleLiquidSheetMultiSelectionCallback>{};
  static Future<bool>? _activeShow;
  static bool _handlerAttached = false;
  static int _nextButtonActionId = 0;

  /// Shows a native sheet on iOS.
  ///
  /// Pass [sheetColor] to force a specific sheet background color. When
  /// [sheetColor] is null, iOS uses an automatic dynamic color for light and
  /// dark mode.
  ///
  /// Pass [content] to customize the native SwiftUI `Form` rendered inside the
  /// sheet. When null, a built-in settings example is shown.
  ///
  /// [heightFraction] is retained for compatibility with earlier sheet demos.
  /// Pass [scrollContext] from inside the presenting scrollable content to stop
  /// active fling momentum before the native sheet is shown.
  ///
  /// Returns false on unsupported platforms so callers can provide a fallback.
  /// Repeated calls while a native presentation is already active return true
  /// without opening another sheet.
  /// On iOS, the returned future completes after the sheet has closed.
  static Future<bool> showSheet({
    double heightFraction = 1,
    double backgroundZoomScale = 1,
    Color? sheetColor,
    AppleLiquidSheetContent? content,
    BuildContext? scrollContext,
  }) async {
    assert(heightFraction >= 0.25 && heightFraction <= 1);
    assert(backgroundZoomScale >= 0.85 && backgroundZoomScale <= 1);

    if (!_supportsNativeSheets) {
      return false;
    }

    if (_activeShow != null) {
      return true;
    }

    _ensureHandlerAttached();

    final ScrollHoldController? backgroundScrollHold = _holdActiveScroll(
      scrollContext,
    );
    final _AppleLiquidSheetButtonActionRegistry actionRegistry =
        _AppleLiquidSheetButtonActionRegistry();
    final Map<String, Object?>? contentMap = content?._toMap(actionRegistry);

    final Future<bool> showFuture = _channel
        .invokeMethod<bool>('showTemplateSheet', <String, Object?>{
          'heightFraction': heightFraction,
          'backgroundZoomScale': backgroundZoomScale,
          'sheetColor': sheetColor?.toARGB32(),
          if (contentMap != null) 'content': contentMap,
        })
        .then((bool? didShow) => didShow ?? false);

    _activeShow = showFuture;

    try {
      return await showFuture;
    } finally {
      actionRegistry.dispose();
      backgroundScrollHold?.cancel();
      if (identical(_activeShow, showFuture)) {
        _activeShow = null;
      }
    }
  }

  /// Shows a native sheet on iOS.
  ///
  /// This legacy name is kept for source compatibility with earlier releases.
  static Future<bool> showTemplateSheet({
    double heightFraction = 1,
    double backgroundZoomScale = 1,
    Color? sheetColor,
    AppleLiquidSheetContent? content,
    BuildContext? scrollContext,
  }) {
    return showSheet(
      heightFraction: heightFraction,
      backgroundZoomScale: backgroundZoomScale,
      sheetColor: sheetColor,
      content: content,
      scrollContext: scrollContext,
    );
  }

  /// Dismisses the active native sheet on iOS.
  ///
  /// Returns false when no native sheet is active or the platform is unsupported.
  static Future<bool> dismissTemplateSheet() async {
    if (!_supportsNativeSheets) {
      return false;
    }

    return await _channel.invokeMethod<bool>('dismissTemplateSheet') ?? false;
  }

  static bool get _supportsNativeSheets {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  }

  static void _ensureHandlerAttached() {
    if (_handlerAttached) {
      return;
    }

    _channel.setMethodCallHandler(_handleMethodCall);
    _handlerAttached = true;
  }

  static Future<void> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'buttonPressed':
        final Object? arguments = call.arguments;
        if (arguments is Map && arguments['actionId'] is String) {
          _buttonActions[arguments['actionId'] as String]?.call();
          return;
        }
        throw MissingPluginException('Invalid sheet buttonPressed payload.');
      case 'multiSelectionChanged':
        final Object? arguments = call.arguments;
        if (arguments is Map &&
            arguments['actionId'] is String &&
            arguments['selectedOptions'] is List) {
          final List<String> selectedOptions =
              (arguments['selectedOptions'] as List).whereType<String>().toList(
                growable: false,
              );
          _multiSelectionActions[arguments['actionId'] as String]?.call(
            selectedOptions,
          );
          return;
        }
        throw MissingPluginException(
          'Invalid sheet multiSelectionChanged payload.',
        );
      default:
        throw MissingPluginException('No handler for ${call.method}.');
    }
  }

  static String _registerButtonAction(AppleLiquidSheetButtonCallback callback) {
    final String actionId = 'sheet_button_${_nextButtonActionId++}';
    _buttonActions[actionId] = callback;
    return actionId;
  }

  static void _removeButtonAction(String actionId) {
    _buttonActions.remove(actionId);
  }

  static String _registerMultiSelectionAction(
    AppleLiquidSheetMultiSelectionCallback callback,
  ) {
    final String actionId = 'sheet_multi_selection_${_nextButtonActionId++}';
    _multiSelectionActions[actionId] = callback;
    return actionId;
  }

  static void _removeMultiSelectionAction(String actionId) {
    _multiSelectionActions.remove(actionId);
  }

  static ScrollHoldController? _holdActiveScroll(BuildContext? context) {
    if (context == null) {
      return null;
    }

    final ScrollableState? scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) {
      return null;
    }

    final ScrollPosition position = scrollable.position;
    if (!position.hasPixels) {
      return null;
    }

    return position.hold(() {});
  }
}
