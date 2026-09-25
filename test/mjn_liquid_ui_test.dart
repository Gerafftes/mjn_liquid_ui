import 'dart:async';
import 'dart:convert';

import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _sendPlatformMethodCall(
  MethodChannel channel,
  String method, [
  Object? arguments,
]) async {
  final ByteData message = const StandardMethodCodec().encodeMethodCall(
    MethodCall(method, arguments),
  );

  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(channel.name, message, (_) {});
}

void main() {
  const MethodChannel symbolChannel = MethodChannel('mjn_liquid_ui/symbols');
  const MethodChannel sheetChannel = MethodChannel('mjn_liquid_ui/sheets');
  const MethodChannel toastChannel = MethodChannel('mjn_liquid_ui/toasts');
  final Uint8List transparentPng = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAFgwJ/lv5Q9wAAAABJRU5ErkJggg==',
  );

  test('identity row serializes content, inset, and visual style', () {
    const AppleLiquidSheetRow row = AppleLiquidSheetRow.identity(
      title: 'Du',
      role: 'Helfer',
      activityType: 'Gartenarbeit',
      description: 'Unterstützt den Auftrag vor Ort.',
      systemImage: 'person.fill',
      avatarUrl: 'https://example.com/avatar.jpg',
      avatarAllowedHosts: <String>['example.com'],
      avatarText: 'D',
      tintColor: Color(0xFF0A84FF),
      rowHorizontalInset: 8,
      style: AppleLiquidSheetIdentityStyle(
        avatarSize: 48,
        iconSize: 22,
        cardPadding: 12,
        cornerRadius: 16,
        backgroundOpacity: 0.14,
        avatarContentSpacing: 11,
        primaryTextSpacing: 4,
        relatedTextSpacing: 3,
        statusContentSpacing: 6,
        badgeContentSpacing: 2,
        metadataSeparatorSpacing: 5,
        metadataSeparator: '•',
        avatarTextColor: Color(0xFFFFFFFF),
        avatarBackgroundColor: Color(0xFF0A84FF),
      ),
    );

    expect(row.toMap(), <String, Object?>{
      'type': 'identity',
      'title': 'Du',
      'tintColor': 0xFF0A84FF,
      'systemImage': 'person.fill',
      'role': 'Helfer',
      'activityType': 'Gartenarbeit',
      'description': 'Unterstützt den Auftrag vor Ort.',
      'avatarUrl': 'https://example.com/avatar.jpg',
      'avatarAllowedHosts': <String>['example.com'],
      'avatarText': 'D',
      'rowHorizontalInset': 8.0,
      'identityStyle': <String, Object?>{
        'avatarSize': 48.0,
        'iconSize': 22.0,
        'cardPadding': 12.0,
        'cornerRadius': 16.0,
        'backgroundOpacity': 0.14,
        'secondaryAvatarSize': 34.0,
        'contentSpacing': 10.0,
        'statusHorizontalPadding': 12.0,
        'statusVerticalPadding': 6.0,
        'badgeSpacing': 6.0,
        'avatarContentSpacing': 11.0,
        'primaryTextSpacing': 4.0,
        'relatedTextSpacing': 3.0,
        'statusContentSpacing': 6.0,
        'badgeContentSpacing': 2.0,
        'metadataSeparatorSpacing': 5.0,
        'metadataSeparator': '•',
        'avatarTextColor': 0xFFFFFFFF,
        'avatarBackgroundColor': 0xFF0A84FF,
      },
    });
  });

  test('identity avatar URLs require an explicit host allowlist', () {
    const AppleLiquidSheetRow row = AppleLiquidSheetRow.identity(
      title: 'Du',
      avatarUrl: 'https://example.com/avatar.jpg',
      relatedPeople: <AppleLiquidSheetIdentityPerson>[
        AppleLiquidSheetIdentityPerson(
          title: 'Mara König',
          avatarUrl: 'https://example.com/mara.jpg',
        ),
      ],
    );

    final Map<String, Object?> map = row.toMap();
    expect(map.containsKey('avatarUrl'), isFalse);
    expect((map['relatedPeople']! as List<Object?>).single, <String, Object?>{
      'title': 'Mara König',
    });
  });

  test('identity row serializes status and related people', () {
    const AppleLiquidSheetRow row = AppleLiquidSheetRow.identity(
      title: 'Du',
      role: 'Helfer',
      status: AppleLiquidSheetIdentityStatus(
        label: 'Anfrage gesendet',
        systemImage: 'circle.fill',
        foregroundColor: Color(0xFFBBD7FF),
        backgroundColor: Color(0x262A82D7),
        borderColor: Color(0xFF2A6DAD),
      ),
      relatedPeople: <AppleLiquidSheetIdentityPerson>[
        AppleLiquidSheetIdentityPerson(
          title: 'Mara König',
          subtitle: 'Auftraggeberin',
          systemImage: 'person.fill',
          avatarText: 'M',
          badges: <AppleLiquidSheetIdentityBadge>[
            AppleLiquidSheetIdentityBadge(
              label: 'Verifiziert',
              systemImage: 'checkmark.seal.fill',
              foregroundColor: Color(0xFF34C759),
            ),
            AppleLiquidSheetIdentityBadge(
              label: '4,9',
              systemImage: 'star.fill',
              foregroundColor: Color(0xFFFFCC00),
            ),
          ],
        ),
      ],
    );

    expect(row.toMap(), <String, Object?>{
      'type': 'identity',
      'title': 'Du',
      'role': 'Helfer',
      'status': <String, Object?>{
        'label': 'Anfrage gesendet',
        'systemImage': 'circle.fill',
        'foregroundColor': 0xFFBBD7FF,
        'backgroundColor': 0x262A82D7,
        'borderColor': 0xFF2A6DAD,
      },
      'relatedPeople': <Map<String, Object?>>[
        <String, Object?>{
          'title': 'Mara König',
          'subtitle': 'Auftraggeberin',
          'systemImage': 'person.fill',
          'avatarText': 'M',
          'badges': <Map<String, Object?>>[
            <String, Object?>{
              'label': 'Verifiziert',
              'systemImage': 'checkmark.seal.fill',
              'foregroundColor': 0xFF34C759,
            },
            <String, Object?>{
              'label': '4,9',
              'systemImage': 'star.fill',
              'foregroundColor': 0xFFFFCC00,
            },
          ],
        },
      ],
    });
  });

  test('identity row serializes selectable card variants', () {
    const AppleLiquidSheetRow legacy = AppleLiquidSheetRow.identity(
      title: 'Du',
      variant: AppleLiquidSheetIdentityVariant.legacy,
    );
    const AppleLiquidSheetRow composed = AppleLiquidSheetRow.identity(
      title: 'Projekt',
      variant: AppleLiquidSheetIdentityVariant.composed,
    );
    const AppleLiquidSheetRow automatic = AppleLiquidSheetRow.identity(
      title: 'Automatisch',
      variant: AppleLiquidSheetIdentityVariant.automatic,
    );

    expect(legacy.toMap()['identityVariant'], 'legacy');
    expect(composed.toMap()['identityVariant'], 'composed');
    expect(automatic.toMap()['identityVariant'], 'automatic');
  });

  test('identity row supports a compact primary-only card', () {
    const AppleLiquidSheetRow row = AppleLiquidSheetRow.identity(
      title: 'Gassi gehen',
      avatarText: 'G',
      status: AppleLiquidSheetIdentityStatus(label: 'Offen'),
    );

    expect(row.role, isNull);
    expect(row.activityType, isNull);
    expect(row.toMap(), <String, Object?>{
      'type': 'identity',
      'title': 'Gassi gehen',
      'avatarText': 'G',
      'status': <String, Object?>{'label': 'Offen'},
    });
  });

  test('identity row keeps its original payload when style is omitted', () {
    const AppleLiquidSheetRow row = AppleLiquidSheetRow.identity(
      title: 'Du',
      role: 'Helfer',
      activityType: 'Gartenarbeit',
    );

    expect(row.identityStyle, isNull);
    expect(row.identityVariant, isNull);
    expect(row.toMap().containsKey('identityStyle'), isFalse);
    expect(row.toMap().containsKey('identityVariant'), isFalse);
  });

  test('timeline row serializes typed steps and current index', () {
    final AppleLiquidSheetRow row = AppleLiquidSheetRow.timeline(
      title: 'Status',
      currentStepIndex: 1,
      collapsedStepLimit: 2,
      initiallyExpanded: false,
      expandLabel: 'Alle Schritte anzeigen',
      collapseLabel: 'Weniger anzeigen',
      tintColor: Color(0xFF34C759),
      steps: <AppleLiquidSheetTimelineStep>[
        AppleLiquidSheetTimelineStep(
          title: 'Angefragt',
          subtitle: 'Heute · 09:30',
        ),
        AppleLiquidSheetTimelineStep(
          title: 'Bestätigt',
          systemImage: 'hand.thumbsup.fill',
        ),
        AppleLiquidSheetTimelineStep(title: 'Erledigt'),
      ],
    );

    expect(row.toMap(), <String, Object?>{
      'type': 'timeline',
      'title': 'Status',
      'tintColor': 0xFF34C759,
      'steps': <Map<String, Object?>>[
        <String, Object?>{'title': 'Angefragt', 'subtitle': 'Heute · 09:30'},
        <String, Object?>{
          'title': 'Bestätigt',
          'systemImage': 'hand.thumbsup.fill',
        },
        <String, Object?>{'title': 'Erledigt'},
      ],
      'currentStepIndex': 1,
      'collapsedStepLimit': 2,
      'initiallyExpanded': false,
      'expandLabel': 'Alle Schritte anzeigen',
      'collapseLabel': 'Weniger anzeigen',
    });
  });

  test('facts grid row serializes facts and column count', () {
    final AppleLiquidSheetRow row = AppleLiquidSheetRow.factsGrid(
      title: 'Auftrag',
      columns: 3,
      tintColor: Color(0xFFFF9F0A),
      facts: <AppleLiquidSheetFact>[
        AppleLiquidSheetFact(
          label: 'Termin',
          value: 'Mo · 18:00',
          systemImage: 'calendar',
        ),
        AppleLiquidSheetFact(label: 'Ort', value: '2,4 km'),
        AppleLiquidSheetFact(label: 'Vergütung', value: '18 €/Std.'),
      ],
    );

    expect(row.toMap(), <String, Object?>{
      'type': 'factsGrid',
      'title': 'Auftrag',
      'tintColor': 0xFFFF9F0A,
      'facts': <Map<String, Object?>>[
        <String, Object?>{
          'label': 'Termin',
          'value': 'Mo · 18:00',
          'systemImage': 'calendar',
        },
        <String, Object?>{'label': 'Ort', 'value': '2,4 km'},
        <String, Object?>{'label': 'Vergütung', 'value': '18 €/Std.'},
      ],
      'columns': 3,
    });
  });

  test('structured rows reject empty or out-of-range configurations', () {
    expect(
      () => AppleLiquidSheetRow.timeline(
        title: 'Status',
        steps: const <AppleLiquidSheetTimelineStep>[],
        currentStepIndex: 0,
      ),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetRow.timeline(
        title: 'Status',
        steps: const <AppleLiquidSheetTimelineStep>[
          AppleLiquidSheetTimelineStep(title: 'Start'),
        ],
        currentStepIndex: 1,
      ),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetRow.factsGrid(
        title: 'Fakten',
        facts: const <AppleLiquidSheetFact>[
          AppleLiquidSheetFact(label: 'Ort', value: 'Berlin'),
        ],
        columns: 5,
      ),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetRow.timeline(
        title: 'Status',
        steps: const <AppleLiquidSheetTimelineStep>[
          AppleLiquidSheetTimelineStep(title: 'Start'),
        ],
        currentStepIndex: 0,
        collapsedStepLimit: 0,
      ),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetRow.timeline(
        title: 'Status',
        steps: const <AppleLiquidSheetTimelineStep>[
          AppleLiquidSheetTimelineStep(title: 'Start'),
          AppleLiquidSheetTimelineStep(title: 'Ende'),
        ],
        currentStepIndex: 0,
        collapsedStepLimit: 1,
        expandLabel: '',
      ),
      throwsAssertionError,
    );
  });

  test('multi-picker row serializes its initial selection', () {
    const AppleLiquidSheetRow row = AppleLiquidSheetRow.multiPicker(
      title: 'Category',
      options: <String>['All', 'Garden', 'Moving'],
      selectedOptions: <String>['Garden', 'Moving'],
    );

    expect(row.toMap(), <String, Object?>{
      'type': 'multiPicker',
      'title': 'Category',
      'options': <String>['All', 'Garden', 'Moving'],
      'selectedOptions': <String>['Garden', 'Moving'],
    });
  });

  test('multi-picker row serializes primary selection label placement', () {
    const AppleLiquidSheetRow row = AppleLiquidSheetRow.multiPicker(
      title: 'Kategorie',
      options: <String>['Alle', 'Garten', 'Umzug'],
      selectedOptions: <String>['Alle'],
      systemImage: 'square.grid.2x2.fill',
      chevronColor: Color(0xFF0A84FF),
      selectionSystemImages: <String, String>{
        'Alle': 'square.grid.2x2.fill',
        'Garten': 'leaf.fill',
        'Nicht vorhanden': 'questionmark',
      },
      selectionLabelPlacement:
          AppleLiquidSheetMultiPickerLabelPlacement.primary,
    );

    expect(row.toMap(), <String, Object?>{
      'type': 'multiPicker',
      'title': 'Kategorie',
      'options': <String>['Alle', 'Garten', 'Umzug'],
      'selectedOptions': <String>['Alle'],
      'systemImage': 'square.grid.2x2.fill',
      'chevronColor': 0xFF0A84FF,
      'selectionLabelPlacement': 'primary',
      'selectionSystemImages': <String, String>{
        'Alle': 'square.grid.2x2.fill',
        'Garten': 'leaf.fill',
      },
    });
  });

  test('AppleLiquidTabItem serializes to platform arguments', () {
    const AppleLiquidTabItem item = AppleLiquidTabItem(
      title: 'Search',
      systemImage: 'plus',
      activeSystemImage: 'plus.circle.fill',
      symbolWeight: AppleLiquidSymbolWeight.regular,
      activeSymbolWeight: AppleLiquidSymbolWeight.bold,
      isSearch: true,
      notificationDotColor: Color(0xFFEF4444),
      notificationBadgeValue: '3',
    );

    expect(item.toMap(), <String, Object?>{
      'title': 'Search',
      'systemImage': 'plus',
      'activeSystemImage': 'plus.circle.fill',
      'symbolWeight': 'regular',
      'activeSymbolWeight': 'bold',
      'isSearch': true,
      'notificationDotColor': 0xFFEF4444,
      'notificationBadgeValue': '3',
    });
  });

  test('AppleLiquidTabBar keeps the full presentation by default', () {
    final AppleLiquidTabBar tabBar = AppleLiquidTabBar(
      currentIndex: 0,
      onChanged: (int _) {},
      items: const <AppleLiquidTabItem>[
        AppleLiquidTabItem(title: 'Home', systemImage: 'house.fill'),
      ],
      searchItem: const AppleLiquidTabItem(
        title: 'Add',
        systemImage: 'plus',
        isSearch: true,
      ),
    );

    expect(tabBar.minimizeBehavior, AppleLiquidTabBarMinimizeBehavior.never);
    expect(
      tabBar.minimizeTrigger,
      const AppleLiquidTabBarMinimizeTrigger.contentScroll(),
    );
  });

  test('AppleLiquidTabBar accepts a pixel minimization trigger', () {
    const AppleLiquidTabBarMinimizeTrigger trigger =
        AppleLiquidTabBarMinimizeTrigger.pixels(72);

    expect(trigger.followsContentScroll, isFalse);
    expect(trigger.pixelDistance, 72);
    expect(
      () => AppleLiquidTabBarMinimizeTrigger.pixels(-1),
      throwsAssertionError,
    );
  });

  test('AppleLiquidSheetContent serializes to platform arguments', () {
    const AppleLiquidSheetContent content = AppleLiquidSheetContent(
      title: 'Project',
      doneSemanticLabel: 'Close sheet',
      leadingAction: AppleLiquidSheetToolbarAction(
        systemImage: 'xmark',
        semanticLabel: 'Cancel',
        foregroundColor: Color(0xFFFF453A),
      ),
      trailingAction: AppleLiquidSheetToolbarAction(
        title: 'Confirm',
        systemImage: 'checkmark',
        semanticLabel: 'Confirm changes',
        foregroundColor: Color(0xFFFFFFFF),
        backgroundColor: Color(0xFF0A84FF),
      ),
      detents: AppleLiquidSheetDetents(initialHeight: 420, expandedHeight: 640),
      showsSectionBackgrounds: false,
      sectionSpacing: 8,
      sections: <AppleLiquidSheetSection>[
        AppleLiquidSheetSection(
          title: 'Overview',
          titleColor: Color(0xFFE6E6E6),
          titleHorizontalInset: 8,
          titleLeadingInset: 4,
          titleTrailingInset: 12,
          titleSpacing: 10,
          showsBackground: true,
          backgroundColor: Color(0xFF1A1A1A),
          borderColor: Color(0xFF2C2C2E),
          cornerRadius: 14,
          rows: <AppleLiquidSheetRow>[
            AppleLiquidSheetRow.value(
              title: 'Name',
              value: 'mjn_liquid_ui',
              systemImage: 'shippingbox.fill',
            ),
            AppleLiquidSheetRow.toggle(title: 'Enabled', value: true),
            AppleLiquidSheetRow.picker(
              title: 'Theme',
              options: <String>['Auto', 'Light', 'Dark'],
              selectedOption: 'Auto',
              chevronColor: Color(0xFFFF9F0A),
            ),
            AppleLiquidSheetRow.segmented(
              title: 'Layout',
              firstOption: 'List',
              secondOption: 'Grid',
              selectedOption: 'Grid',
              systemImage: 'rectangle.grid.1x2',
              style: AppleLiquidSheetSegmentedStyle(
                selectedBackgroundColor: Color(0x2234C759),
                unselectedBackgroundColor: Color(0x11222222),
                selectedTextColor: Color(0xFF34C759),
                unselectedTextColor: Color(0xFF8E8E93),
                selectedBorderColor: Color(0x9934C759),
                unselectedBorderColor: Color(0x338E8E93),
                selectedShadowColor: Color(0x0AFFFFFF),
                titleColor: Color(0xFF111111),
                subtitleColor: Color(0xFF666666),
                buttonHeight: 52,
                cornerRadius: 18,
                buttonSpacing: 16,
                contentSpacing: 14,
                verticalPadding: 8,
                rowHorizontalInset: 10,
                borderWidth: 2,
                selectedShadowRadius: 9,
                selectedShadowOffsetX: 1,
                selectedShadowOffsetY: 3,
                titleFontSize: 19,
                subtitleFontSize: 13,
                buttonFontSize: 17,
                titleFontWeight: AppleLiquidSheetSegmentedFontWeight.bold,
                subtitleFontWeight: AppleLiquidSheetSegmentedFontWeight.medium,
                buttonFontWeight: AppleLiquidSheetSegmentedFontWeight.heavy,
                minimumTextScaleFactor: 0.7,
                pressedScale: 0.96,
                pressedOpacity: 0.8,
                pressAnimationDuration: 0.14,
                selectionAnimationEnabled: false,
                selectionAnimationCurve:
                    AppleLiquidSheetSegmentedAnimationCurve.spring,
                selectionAnimationDuration: 0.32,
                selectionSpringDamping: 0.72,
              ),
            ),
            AppleLiquidSheetRow.button(
              title: 'Show on map',
              systemImage: 'map',
              tintColor: Color(0xFF0A84FF),
              semanticLabel: 'Open map',
              dismissesSheet: true,
              enabled: false,
            ),
            AppleLiquidSheetRow.slider(
              title: 'Intensity',
              value: 0.75,
              min: 0,
              max: 1,
              tintColor: Color(0xFF0A84FF),
              valuePlacement: AppleLiquidSheetSliderValuePlacement.besideTrack,
              rowHorizontalInset: 8,
              rowLeadingInset: 6,
              rowTrailingInset: 14,
              systemImage: 'slider.horizontal.3',
            ),
            AppleLiquidSheetRow.slider(
              title: 'Stepped amount',
              value: 0.5,
              step: 0.25,
              valueSuffix: 'kg',
            ),
            AppleLiquidSheetRow.navigation(
              title: 'Details',
              chevronColor: Color(0xFF34C759),
              content: AppleLiquidSheetContent(
                title: 'Details',
                detents: AppleLiquidSheetDetents(
                  initialHeight: 300,
                  allowsAutomaticExpansion: false,
                ),
                sections: <AppleLiquidSheetSection>[
                  AppleLiquidSheetSection(
                    rows: <AppleLiquidSheetRow>[
                      AppleLiquidSheetRow.textField(
                        title: 'Label',
                        value: 'Liquid',
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

    expect(content.toMap(), <String, Object?>{
      'title': 'Project',
      'doneSemanticLabel': 'Close sheet',
      'leadingAction': <String, Object?>{
        'systemImage': 'xmark',
        'semanticLabel': 'Cancel',
        'foregroundColor': 0xFFFF453A,
      },
      'trailingAction': <String, Object?>{
        'title': 'Confirm',
        'systemImage': 'checkmark',
        'semanticLabel': 'Confirm changes',
        'foregroundColor': 0xFFFFFFFF,
        'backgroundColor': 0xFF0A84FF,
      },
      'detents': <String, Object?>{
        'initialHeight': 420.0,
        'expandedHeight': 640.0,
      },
      'showsSectionBackgrounds': false,
      'sectionSpacing': 8.0,
      'sections': <Object?>[
        <String, Object?>{
          'title': 'Overview',
          'titleColor': 0xFFE6E6E6,
          'titleHorizontalInset': 8.0,
          'titleLeadingInset': 4.0,
          'titleTrailingInset': 12.0,
          'titleSpacing': 10.0,
          'showsBackground': true,
          'backgroundColor': 0xFF1A1A1A,
          'borderColor': 0xFF2C2C2E,
          'cornerRadius': 14.0,
          'rows': <Object?>[
            <String, Object?>{
              'type': 'value',
              'title': 'Name',
              'value': 'mjn_liquid_ui',
              'systemImage': 'shippingbox.fill',
            },
            <String, Object?>{
              'type': 'toggle',
              'title': 'Enabled',
              'boolValue': true,
            },
            <String, Object?>{
              'type': 'picker',
              'title': 'Theme',
              'options': <String>['Auto', 'Light', 'Dark'],
              'selectedOption': 'Auto',
              'chevronColor': 0xFFFF9F0A,
            },
            <String, Object?>{
              'type': 'segmented',
              'title': 'Layout',
              'options': <String>['List', 'Grid'],
              'selectedOption': 'Grid',
              'systemImage': 'rectangle.grid.1x2',
              'segmentedStyle': <String, Object?>{
                'selectedBackgroundColor': 0x2234C759,
                'unselectedBackgroundColor': 0x11222222,
                'selectedTextColor': 0xFF34C759,
                'unselectedTextColor': 0xFF8E8E93,
                'selectedBorderColor': 0x9934C759,
                'unselectedBorderColor': 0x338E8E93,
                'selectedShadowColor': 0x0AFFFFFF,
                'titleColor': 0xFF111111,
                'subtitleColor': 0xFF666666,
                'buttonHeight': 52.0,
                'cornerRadius': 18.0,
                'buttonSpacing': 16.0,
                'contentSpacing': 14.0,
                'verticalPadding': 8.0,
                'rowHorizontalInset': 10.0,
                'borderWidth': 2.0,
                'selectedShadowRadius': 9.0,
                'selectedShadowOffsetX': 1.0,
                'selectedShadowOffsetY': 3.0,
                'titleFontSize': 19.0,
                'subtitleFontSize': 13.0,
                'buttonFontSize': 17.0,
                'titleFontWeight': 'bold',
                'subtitleFontWeight': 'medium',
                'buttonFontWeight': 'heavy',
                'minimumTextScaleFactor': 0.7,
                'pressedScale': 0.96,
                'pressedOpacity': 0.8,
                'pressAnimationDuration': 0.14,
                'selectionAnimationEnabled': false,
                'selectionAnimationCurve': 'spring',
                'selectionAnimationDuration': 0.32,
                'selectionSpringDamping': 0.72,
              },
            },
            <String, Object?>{
              'type': 'button',
              'title': 'Show on map',
              'tintColor': 0xFF0A84FF,
              'systemImage': 'map',
              'buttonSemanticLabel': 'Open map',
              'buttonDismissesSheet': true,
              'buttonEnabled': false,
            },
            <String, Object?>{
              'type': 'slider',
              'title': 'Intensity',
              'sliderValue': 0.75,
              'min': 0.0,
              'max': 1.0,
              'tintColor': 0xFF0A84FF,
              'sliderValuePlacement': 'besideTrack',
              'rowHorizontalInset': 8.0,
              'rowLeadingInset': 6.0,
              'rowTrailingInset': 14.0,
              'systemImage': 'slider.horizontal.3',
            },
            <String, Object?>{
              'type': 'slider',
              'title': 'Stepped amount',
              'sliderValue': 0.5,
              'min': 0.0,
              'max': 1.0,
              'step': 0.25,
              'valueSuffix': 'kg',
            },
            <String, Object?>{
              'type': 'navigation',
              'title': 'Details',
              'chevronColor': 0xFF34C759,
              'content': <String, Object?>{
                'title': 'Details',
                'doneSemanticLabel': 'Done',
                'detents': <String, Object?>{
                  'initialHeight': 300.0,
                  'allowsAutomaticExpansion': false,
                },
                'sections': <Object?>[
                  <String, Object?>{
                    'rows': <Object?>[
                      <String, Object?>{
                        'type': 'textField',
                        'title': 'Label',
                        'value': 'Liquid',
                      },
                    ],
                  },
                ],
              },
            },
          ],
        },
      ],
    });
  });

  test('sheet button styles serialize every native appearance option', () {
    final Map<String, Object?> defaultStyle =
        const AppleLiquidSheetButtonStyle().toMap();
    expect(defaultStyle['rowHorizontalInset'], 16.0);
    expect(defaultStyle['rowVerticalInset'], 6.0);
    expect(defaultStyle, isNot(contains('rowTopInset')));
    expect(defaultStyle, isNot(contains('rowBottomInset')));

    const AppleLiquidSheetButtonStyle style = AppleLiquidSheetButtonStyle(
      backgroundColor: Color(0x22007AFF),
      foregroundColor: Color(0xFFFFFFFF),
      borderColor: Color(0xFF007AFF),
      subtitleColor: Color(0xFF8E8E93),
      buttonHeight: 52,
      cornerRadius: 16,
      borderWidth: 2,
      backgroundOpacity: 0.12,
      horizontalPadding: 18,
      iconSpacing: 10,
      labelSpacing: 3,
      rowHorizontalInset: 4,
      rowVerticalInset: 7,
      rowTopInset: 12,
      rowBottomInset: 0,
      titleFontSize: 17,
      subtitleFontSize: 12,
      iconSize: 18,
      titleFontWeight: AppleLiquidSheetSegmentedFontWeight.bold,
      subtitleFontWeight: AppleLiquidSheetSegmentedFontWeight.medium,
      alignment: AppleLiquidSheetButtonAlignment.leading,
      minimumTextScaleFactor: 0.7,
      pressedScale: 0.96,
      pressedOpacity: 0.8,
      disabledOpacity: 0.4,
      pressAnimationDuration: 0.16,
      showsFormBackground: true,
      showsSeparator: true,
    );

    expect(style.toMap(), <String, Object?>{
      'backgroundColor': 0x22007AFF,
      'foregroundColor': 0xFFFFFFFF,
      'borderColor': 0xFF007AFF,
      'subtitleColor': 0xFF8E8E93,
      'buttonHeight': 52.0,
      'cornerRadius': 16.0,
      'borderWidth': 2.0,
      'backgroundOpacity': 0.12,
      'horizontalPadding': 18.0,
      'iconSpacing': 10.0,
      'labelSpacing': 3.0,
      'rowHorizontalInset': 4.0,
      'rowVerticalInset': 7.0,
      'rowTopInset': 12.0,
      'rowBottomInset': 0.0,
      'titleFontSize': 17.0,
      'subtitleFontSize': 12.0,
      'iconSize': 18.0,
      'titleFontWeight': 'bold',
      'subtitleFontWeight': 'medium',
      'alignment': 'leading',
      'minimumTextScaleFactor': 0.7,
      'pressedScale': 0.96,
      'pressedOpacity': 0.8,
      'disabledOpacity': 0.4,
      'pressAnimationDuration': 0.16,
      'showsFormBackground': true,
      'showsSeparator': true,
    });
  });

  test('sheet buttons route native presses to Dart callbacks', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final Completer<bool> showCompleter = Completer<bool>();
    String? actionId;
    int pressCount = 0;
    final AppleLiquidSheetContent content = AppleLiquidSheetContent(
      sections: <AppleLiquidSheetSection>[
        AppleLiquidSheetSection(
          rows: <AppleLiquidSheetRow>[
            AppleLiquidSheetRow.button(
              title: 'Show on map',
              onPressed: () {
                pressCount += 1;
              },
            ),
          ],
        ),
      ],
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sheetChannel, (MethodCall call) async {
          if (call.method == 'showTemplateSheet') {
            final Map<Object?, Object?> arguments =
                call.arguments as Map<Object?, Object?>;
            final Map<Object?, Object?> nativeContent =
                arguments['content'] as Map<Object?, Object?>;
            final List<Object?> sections =
                nativeContent['sections'] as List<Object?>;
            final Map<Object?, Object?> section =
                sections.single as Map<Object?, Object?>;
            final List<Object?> rows = section['rows'] as List<Object?>;
            final Map<Object?, Object?> row =
                rows.single as Map<Object?, Object?>;
            actionId = row['buttonActionId'] as String?;
            return showCompleter.future;
          }

          return null;
        });

    try {
      final Future<AppleLiquidSheetResult> showFuture =
          AppleLiquidSheet.showSheet(content: content);
      await Future<void>.delayed(Duration.zero);

      expect(actionId, isNotNull);
      await _sendPlatformMethodCall(
        sheetChannel,
        'buttonPressed',
        <String, Object?>{'actionId': actionId},
      );
      expect(pressCount, 1);

      showCompleter.complete(true);
      expect((await showFuture).didPresent, isTrue);
    } finally {
      if (!showCompleter.isCompleted) {
        showCompleter.complete(false);
      }
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(sheetChannel, null);
    }
  });

  test('sheet results return text and report save status', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final Completer<Object?> resultCompleter = Completer<Object?>();
    final List<String> textChanges = <String>[];
    final List<AppleLiquidSheetResultStatus> toolbarStatuses =
        <AppleLiquidSheetResultStatus>[];
    String? textFieldActionId;
    String? saveActionId;

    final AppleLiquidSheetContent content = AppleLiquidSheetContent(
      leadingAction: AppleLiquidSheetToolbarAction(
        title: 'Cancel',
        onPressed: toolbarStatuses.add,
      ),
      trailingAction: AppleLiquidSheetToolbarAction(
        title: 'Save',
        onPressed: toolbarStatuses.add,
      ),
      sections: <AppleLiquidSheetSection>[
        AppleLiquidSheetSection(
          rows: <AppleLiquidSheetRow>[
            AppleLiquidSheetRow.textField(
              identifier: 'title',
              title: 'Title',
              value: 'Initial',
              onChanged: textChanges.add,
            ),
          ],
        ),
      ],
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sheetChannel, (MethodCall call) async {
          if (call.method == 'showTemplateSheet') {
            final Map<Object?, Object?> arguments =
                call.arguments as Map<Object?, Object?>;
            final Map<Object?, Object?> nativeContent =
                arguments['content'] as Map<Object?, Object?>;
            final List<Object?> sections =
                nativeContent['sections'] as List<Object?>;
            final Map<Object?, Object?> section =
                sections.single as Map<Object?, Object?>;
            final List<Object?> rows = section['rows'] as List<Object?>;
            final Map<Object?, Object?> row =
                rows.single as Map<Object?, Object?>;
            final Map<Object?, Object?> trailingAction =
                nativeContent['trailingAction'] as Map<Object?, Object?>;
            textFieldActionId = row['textFieldActionId'] as String?;
            saveActionId = trailingAction['actionId'] as String?;
            return resultCompleter.future;
          }

          return null;
        });

    try {
      final Future<AppleLiquidSheetResult> showFuture =
          AppleLiquidSheet.showSheet(content: content);
      await Future<void>.delayed(Duration.zero);

      expect(textFieldActionId, isNotNull);
      expect(saveActionId, isNotNull);
      await _sendPlatformMethodCall(
        sheetChannel,
        'textFieldChanged',
        <String, Object?>{'actionId': textFieldActionId, 'value': 'Live edit'},
      );
      await _sendPlatformMethodCall(
        sheetChannel,
        'toolbarActionPressed',
        <String, Object?>{'actionId': saveActionId, 'status': 'saved'},
      );

      expect(textChanges, <String>['Live edit']);
      expect(toolbarStatuses, <AppleLiquidSheetResultStatus>[
        AppleLiquidSheetResultStatus.saved,
      ]);

      resultCompleter.complete(<String, Object?>{
        'status': 'saved',
        'toolbarActionId': saveActionId,
        'textFieldValues': <String, String>{textFieldActionId!: 'Final title'},
      });

      final AppleLiquidSheetResult result = await showFuture;
      expect(result.status, AppleLiquidSheetResultStatus.saved);
      expect(result.isSaved, isTrue);
      expect(result.didPresent, isTrue);
      expect(result.textField('title')?.value, 'Final title');
      expect(textChanges, <String>['Live edit', 'Final title']);
      expect(toolbarStatuses, <AppleLiquidSheetResultStatus>[
        AppleLiquidSheetResultStatus.saved,
      ]);
    } finally {
      if (!resultCompleter.isCompleted) {
        resultCompleter.complete(<String, Object?>{'status': 'cancelled'});
      }
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(sheetChannel, null);
    }
  });

  test(
    'sheet cancellation invokes the toolbar callback with cancelled',
    () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final Completer<Object?> resultCompleter = Completer<Object?>();
      final List<AppleLiquidSheetResultStatus> toolbarStatuses =
          <AppleLiquidSheetResultStatus>[];
      String? cancelActionId;

      final AppleLiquidSheetContent content = AppleLiquidSheetContent(
        leadingAction: AppleLiquidSheetToolbarAction(
          title: 'Cancel',
          onPressed: toolbarStatuses.add,
        ),
        sections: <AppleLiquidSheetSection>[
          AppleLiquidSheetSection(rows: <AppleLiquidSheetRow>[]),
        ],
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(sheetChannel, (MethodCall call) async {
            if (call.method == 'showTemplateSheet') {
              final Map<Object?, Object?> arguments =
                  call.arguments as Map<Object?, Object?>;
              final Map<Object?, Object?> nativeContent =
                  arguments['content'] as Map<Object?, Object?>;
              final Map<Object?, Object?> leadingAction =
                  nativeContent['leadingAction'] as Map<Object?, Object?>;
              cancelActionId = leadingAction['actionId'] as String?;
              return resultCompleter.future;
            }

            return null;
          });

      try {
        final Future<AppleLiquidSheetResult> showFuture =
            AppleLiquidSheet.showSheet(content: content);
        await Future<void>.delayed(Duration.zero);

        expect(cancelActionId, isNotNull);
        resultCompleter.complete(<String, Object?>{
          'status': 'cancelled',
          'toolbarActionId': cancelActionId,
        });

        final AppleLiquidSheetResult result = await showFuture;
        expect(result.status, AppleLiquidSheetResultStatus.cancelled);
        expect(result.isCancelled, isTrue);
        expect(result.didPresent, isTrue);
        expect(toolbarStatuses, <AppleLiquidSheetResultStatus>[
          AppleLiquidSheetResultStatus.cancelled,
        ]);
      } finally {
        if (!resultCompleter.isCompleted) {
          resultCompleter.complete(<String, Object?>{'status': 'cancelled'});
        }
        debugDefaultTargetPlatformOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(sheetChannel, null);
      }
    },
  );

  test('sheet toolbar actions require visible content', () {
    expect(() => AppleLiquidSheetToolbarAction(), throwsAssertionError);
    expect(
      () => AppleLiquidSheetToolbarAction(title: ''),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetToolbarAction(systemImage: ''),
      throwsAssertionError,
    );
  });

  test('sheet section corner radius stays within native bounds', () {
    expect(
      () => AppleLiquidSheetSection(
        cornerRadius: -1,
        rows: const <AppleLiquidSheetRow>[
          AppleLiquidSheetRow.text(title: 'Row'),
        ],
      ),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetSection(
        cornerRadius: 81,
        rows: const <AppleLiquidSheetRow>[
          AppleLiquidSheetRow.text(title: 'Row'),
        ],
      ),
      throwsAssertionError,
    );
  });

  test('sheet section title spacing stays within native bounds', () {
    const List<AppleLiquidSheetRow> rows = <AppleLiquidSheetRow>[
      AppleLiquidSheetRow.text(title: 'Row'),
    ];

    expect(
      () => AppleLiquidSheetSection(titleSpacing: -1, rows: rows),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetSection(titleSpacing: 201, rows: rows),
      throwsAssertionError,
    );
  });

  test('sheet section title inset stays within native bounds', () {
    const List<AppleLiquidSheetRow> rows = <AppleLiquidSheetRow>[
      AppleLiquidSheetRow.text(title: 'Row'),
    ];

    expect(
      () => AppleLiquidSheetSection(titleHorizontalInset: -1, rows: rows),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetSection(titleHorizontalInset: 201, rows: rows),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetSection(titleLeadingInset: -1, rows: rows),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetSection(titleTrailingInset: 201, rows: rows),
      throwsAssertionError,
    );
  });

  test('sheet slider row inset stays within native bounds', () {
    expect(
      () =>
          AppleLiquidSheetRow.slider(title: 'Distance', rowHorizontalInset: -1),
      throwsAssertionError,
    );
    expect(
      () =>
          AppleLiquidSheetRow.slider(title: 'Distance', rowHorizontalInset: 81),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetRow.slider(title: 'Distance', rowLeadingInset: -1),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetRow.slider(title: 'Distance', rowTrailingInset: 81),
      throwsAssertionError,
    );
  });

  test('sheet identity row inset stays within native bounds', () {
    expect(
      () => AppleLiquidSheetRow.identity(
        title: 'Du',
        role: 'Helfer',
        activityType: 'Gartenarbeit',
        rowHorizontalInset: -1,
      ),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetRow.identity(
        title: 'Du',
        role: 'Helfer',
        activityType: 'Gartenarbeit',
        rowHorizontalInset: 81,
      ),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetRow.identity(
        title: 'Du',
        role: 'Helfer',
        activityType: 'Gartenarbeit',
        description: '',
      ),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetRow.identity(title: 'Du', avatarText: ''),
      throwsAssertionError,
    );
  });

  test('identity style validates dimensions, opacity, and chip spacing', () {
    const AppleLiquidSheetIdentityStyle defaultStyle =
        AppleLiquidSheetIdentityStyle();
    expect(
      defaultStyle.statusHorizontalPadding,
      defaultStyle.statusVerticalPadding * 2,
    );
    expect(
      () => AppleLiquidSheetIdentityStyle(avatarSize: 0),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetIdentityStyle(iconSize: 0),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetIdentityStyle(avatarSize: 20, iconSize: 21),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetIdentityStyle(cardPadding: -1),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetIdentityStyle(cornerRadius: -1),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetIdentityStyle(backgroundOpacity: 1.01),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetIdentityStyle(secondaryAvatarSize: 0),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetIdentityStyle(contentSpacing: -1),
      throwsAssertionError,
    );
  });

  test('sheet section spacing stays within native bounds', () {
    const List<AppleLiquidSheetSection> sections = <AppleLiquidSheetSection>[
      AppleLiquidSheetSection(
        rows: <AppleLiquidSheetRow>[AppleLiquidSheetRow.text(title: 'Row')],
      ),
    ];

    expect(
      () => AppleLiquidSheetContent(sectionSpacing: -1, sections: sections),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetContent(sectionSpacing: 201, sections: sections),
      throwsAssertionError,
    );
  });

  test('segmented sheet rows require non-empty distinct options', () {
    expect(
      () => AppleLiquidSheetRow.segmented(
        title: 'Layout',
        firstOption: 'List',
        secondOption: 'List',
      ),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetRow.segmented(
        title: 'Layout',
        firstOption: '',
        secondOption: 'Grid',
      ),
      throwsAssertionError,
    );
  });

  test('segmented sheet styles validate dimensions and feedback values', () {
    expect(
      () => AppleLiquidSheetSegmentedStyle(buttonHeight: 0),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetSegmentedStyle(pressedScale: 1.1),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetSegmentedStyle(selectedShadowRadius: -1),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetSegmentedStyle(rowHorizontalInset: -1),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetSegmentedStyle(rowHorizontalInset: 81),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetSegmentedStyle(selectionAnimationDuration: -0.1),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSheetSegmentedStyle(selectionSpringDamping: 1.1),
      throwsAssertionError,
    );
  });

  test('AppleLiquidSheet returns false outside iOS', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    try {
      expect(
        await AppleLiquidSheet.showTemplateSheet(
          heightFraction: 0.72,
          backgroundZoomScale: 0.94,
        ),
        isFalse,
      );
      expect(await AppleLiquidSheet.dismissTemplateSheet(), isFalse);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('AppleLiquidSheetController returns false outside iOS', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    final AppleLiquidSheetController controller = AppleLiquidSheetController(
      heightFraction: 0.72,
      backgroundZoomScale: 0.94,
      sheetColor: const Color(0xFFEAF3FF),
    );

    try {
      expect(await controller.showTemplateSheet(), isFalse);
      expect(await controller.dismiss(), isFalse);
      expect(controller.isShowing, isFalse);
      expect(controller.isShown, isFalse);
    } finally {
      controller.dispose();
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('AppleLiquidSheetController tracks native presentation state', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final Completer<bool> showCompleter = Completer<bool>();
    final List<MethodCall> calls = <MethodCall>[];
    const AppleLiquidSheetContent content = AppleLiquidSheetContent(
      title: 'Project',
      sections: <AppleLiquidSheetSection>[
        AppleLiquidSheetSection(
          rows: <AppleLiquidSheetRow>[
            AppleLiquidSheetRow.value(title: 'Name', value: 'mjn_liquid_ui'),
          ],
        ),
      ],
    );
    final AppleLiquidSheetController controller = AppleLiquidSheetController(
      heightFraction: 0.72,
      backgroundZoomScale: 0.94,
      sheetColor: const Color(0xFFEAF3FF),
      content: content,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sheetChannel, (MethodCall call) async {
          calls.add(call);

          switch (call.method) {
            case 'showTemplateSheet':
              return showCompleter.future;
            case 'dismissTemplateSheet':
              if (!showCompleter.isCompleted) {
                showCompleter.complete(true);
              }
              return true;
            default:
              return null;
          }
        });

    try {
      final Future<AppleLiquidSheetResult> showFuture = controller.showSheet();
      await Future<void>.delayed(Duration.zero);

      expect(controller.isShowing, isTrue);
      expect(controller.isShown, isTrue);
      expect(calls, hasLength(1));
      expect(calls.single.method, 'showTemplateSheet');
      expect(calls.single.arguments, containsPair('heightFraction', 0.72));
      expect(calls.single.arguments, containsPair('backgroundZoomScale', 0.94));
      expect(calls.single.arguments, containsPair('sheetColor', 0xFFEAF3FF));
      expect(calls.single.arguments, containsPair('content', content.toMap()));

      expect((await controller.showSheet()).didPresent, isTrue);
      expect(calls, hasLength(1));

      expect(await controller.dismiss(), isTrue);
      expect((await showFuture).didPresent, isTrue);
      expect(controller.isShowing, isFalse);
      expect(controller.isShown, isFalse);
      expect(calls.map((MethodCall call) => call.method), <String>[
        'showTemplateSheet',
        'dismissTemplateSheet',
      ]);
    } finally {
      controller.dispose();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(sheetChannel, null);
    }
  });

  testWidgets(
    'AppleLiquidSheetBackgroundInteractionGuard blocks background while showing',
    (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final AppleLiquidSheetController controller =
          AppleLiquidSheetController();
      final Completer<bool> showCompleter = Completer<bool>();
      int tapCount = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(sheetChannel, (MethodCall call) async {
            if (call.method == 'showTemplateSheet') {
              return showCompleter.future;
            }

            return null;
          });

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: AppleLiquidSheetBackgroundInteractionGuard(
              controller: controller,
              child: TextButton(
                onPressed: () {
                  tapCount += 1;
                },
                child: const Text('Background action'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Background action'));
        expect(tapCount, 1);

        final Future<AppleLiquidSheetResult> showFuture = controller
            .showSheet();
        await tester.pump();

        await tester.tap(find.text('Background action'), warnIfMissed: false);
        expect(tapCount, 1);

        showCompleter.complete(true);
        expect((await showFuture).didPresent, isTrue);
        await tester.pump();

        await tester.tap(find.text('Background action'));
        expect(tapCount, 2);
      } finally {
        controller.dispose();
        debugDefaultTargetPlatformOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(sheetChannel, null);
      }
    },
  );

  testWidgets(
    'AppleLiquidSheetBackgroundInteractionGuard preserves scroll offset',
    (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final AppleLiquidSheetController controller =
          AppleLiquidSheetController();
      final Completer<bool> showCompleter = Completer<bool>();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(sheetChannel, (MethodCall call) async {
            if (call.method == 'showTemplateSheet') {
              return showCompleter.future;
            }

            return null;
          });

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: AppleLiquidSheetBackgroundInteractionGuard(
              controller: controller,
              child: ListView.builder(
                itemCount: 80,
                itemExtent: 48,
                itemBuilder: (BuildContext context, int index) {
                  return Text('Row $index');
                },
              ),
            ),
          ),
        );

        await tester.drag(find.byType(ListView), const Offset(0, -360));
        await tester.pumpAndSettle();

        final ScrollableState scrollable = tester.state<ScrollableState>(
          find.byType(Scrollable),
        );
        final double offsetBeforeSheet = scrollable.position.pixels;
        expect(offsetBeforeSheet, greaterThan(0));

        final Future<AppleLiquidSheetResult> showFuture = controller
            .showSheet();
        await tester.pump();

        expect(scrollable.position.pixels, offsetBeforeSheet);

        showCompleter.complete(true);
        expect((await showFuture).didPresent, isTrue);
        await tester.pump();

        expect(scrollable.position.pixels, offsetBeforeSheet);
      } finally {
        controller.dispose();
        debugDefaultTargetPlatformOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(sheetChannel, null);
      }
    },
  );

  testWidgets(
    'AppleLiquidSheetBackgroundInteractionGuard exposes customization hooks',
    (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final AppleLiquidSheetController controller =
          AppleLiquidSheetController();
      final Completer<bool> showCompleter = Completer<bool>();
      bool? isBlockedFromBuilder;
      int tapCount = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(sheetChannel, (MethodCall call) async {
            if (call.method == 'showTemplateSheet') {
              return showCompleter.future;
            }

            return null;
          });

      try {
        await tester.pumpWidget(
          MaterialApp(
            home: AppleLiquidSheetBackgroundInteractionGuard(
              controller: controller,
              absorbPointers: false,
              lockScrolling: false,
              builder: (BuildContext context, bool isBlocked, Widget? child) {
                isBlockedFromBuilder = isBlocked;
                return child!;
              },
              child: TextButton(
                onPressed: () {
                  tapCount += 1;
                },
                child: const Text('Custom background action'),
              ),
            ),
          ),
        );

        expect(isBlockedFromBuilder, isFalse);

        final Future<AppleLiquidSheetResult> showFuture = controller
            .showSheet();
        await tester.pump();
        expect(isBlockedFromBuilder, isTrue);

        await tester.tap(find.text('Custom background action'));
        expect(tapCount, 1);

        showCompleter.complete(true);
        expect((await showFuture).didPresent, isTrue);
        await tester.pump();
        expect(isBlockedFromBuilder, isFalse);
      } finally {
        controller.dispose();
        debugDefaultTargetPlatformOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(sheetChannel, null);
      }
    },
  );

  test('AppleLiquidSheet ignores duplicate native show requests', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final Completer<bool> showCompleter = Completer<bool>();
    final List<MethodCall> calls = <MethodCall>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sheetChannel, (MethodCall call) async {
          calls.add(call);

          switch (call.method) {
            case 'showTemplateSheet':
              return showCompleter.future;
            default:
              return null;
          }
        });

    try {
      final Future<AppleLiquidSheetResult> showFuture =
          AppleLiquidSheet.showSheet();
      await Future<void>.delayed(Duration.zero);

      expect(calls, hasLength(1));
      expect((await AppleLiquidSheet.showSheet()).didPresent, isTrue);
      expect(calls, hasLength(1));

      showCompleter.complete(true);
      expect((await showFuture).didPresent, isTrue);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(sheetChannel, null);
    }
  });

  test('AppleLiquidToast returns false outside iOS', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    final List<MethodCall> calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (MethodCall call) async {
          calls.add(call);
          return true;
        });

    try {
      expect(await AppleLiquidToast.show(title: 'Saved'), isFalse);
      expect(await AppleLiquidToast.dismiss(), isFalse);
      expect(await AppleLiquidToast.setVisible(false), isFalse);
      expect(await AppleLiquidToast.setVisible(true), isFalse);
      expect(calls, isEmpty);
    } finally {
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(toastChannel, null);
    }
  });

  test('AppleLiquidToast hides and restores the active stack', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final List<MethodCall> calls = <MethodCall>[];
    String? actionId;
    int actionTapCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (MethodCall call) async {
          calls.add(call);
          if (call.method == 'show') {
            final Map<Object?, Object?> arguments =
                call.arguments as Map<Object?, Object?>;
            actionId = arguments['actionId'] as String?;
          }
          return true;
        });

    try {
      expect(
        await AppleLiquidToast.show(
          title: 'Saved',
          duration: null,
          action: AppleLiquidToastAction(
            title: 'Undo',
            dismissesToast: false,
            onPressed: () {
              actionTapCount += 1;
            },
          ),
        ),
        isTrue,
      );

      expect(await AppleLiquidToast.setVisible(false), isTrue);
      expect(await AppleLiquidToast.setVisible(true), isTrue);

      expect(calls.map((MethodCall call) => call.method).toList(), <String>[
        'show',
        'setVisibility',
        'setVisibility',
      ]);
      expect(calls[1].arguments, isFalse);
      expect(calls[2].arguments, isTrue);

      await _sendPlatformMethodCall(
        toastChannel,
        'actionInvoked',
        <String, Object?>{'actionId': actionId},
      );
      expect(actionTapCount, 1);
    } finally {
      await AppleLiquidToast.setVisible(true);
      await AppleLiquidToast.dismiss();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(toastChannel, null);
    }
  });

  test('AppleLiquidToast sends native show payload on iOS', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final List<MethodCall> calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (MethodCall call) async {
          calls.add(call);
          return true;
        });

    try {
      expect(
        await AppleLiquidToast.show(
          title: 'Added to Cart',
          duration: const Duration(milliseconds: 1500),
          placementOffset: -44,
          transitionOffset: 120,
          systemImage: 'cart.fill',
          action: AppleLiquidToastAction(
            title: 'Undo',
            tintColor: const Color(0xFFFF9500),
            dismissesToast: false,
            isWholeToastTappable: true,
            onPressed: () {},
          ),
        ),
        isTrue,
      );

      expect(calls, hasLength(1));
      expect(calls.single.method, 'show');

      final Map<Object?, Object?> arguments =
          calls.single.arguments as Map<Object?, Object?>;
      expect(arguments, containsPair('title', 'Added to Cart'));
      expect(arguments, containsPair('duration', 1.5));
      expect(arguments, containsPair('placementOffset', -44.0));
      expect(arguments, containsPair('transitionOffset', 120.0));
      expect(arguments['maxVisibleToasts'], isNull);
      expect(arguments, containsPair('overflowTitle', 'More notifications'));
      expect(arguments, containsPair('isVisible', true));
      expect(arguments, containsPair('systemImage', 'cart.fill'));
      expect(arguments, containsPair('actionTitle', 'Undo'));
      expect(arguments, containsPair('actionTintColor', 0xFFFF9500));
      expect(arguments, containsPair('dismissesOnAction', false));
      expect(arguments, containsPair('isWholeToastTappable', true));
      expect(arguments['actionId'], isA<String>());
    } finally {
      await AppleLiquidToast.dismiss();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(toastChannel, null);
    }
  });

  test('AppleLiquidToast keeps stacked actions independent', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final List<String> actionIds = <String>[];
    final List<String> toastIds = <String>[];
    int firstTapCount = 0;
    int secondTapCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (MethodCall call) async {
          if (call.method == 'show') {
            final Map<Object?, Object?> arguments =
                call.arguments as Map<Object?, Object?>;
            actionIds.add(arguments['actionId'] as String);
            toastIds.add(arguments['id'] as String);
          }

          return true;
        });

    try {
      expect(
        await AppleLiquidToast.show(
          title: 'First',
          duration: null,
          action: AppleLiquidToastAction(
            title: 'Undo first',
            dismissesToast: false,
            onPressed: () {
              firstTapCount += 1;
            },
          ),
        ),
        isTrue,
      );
      expect(
        await AppleLiquidToast.show(
          title: 'Second',
          duration: null,
          action: AppleLiquidToastAction(
            title: 'Undo second',
            dismissesToast: false,
            onPressed: () {
              secondTapCount += 1;
            },
          ),
        ),
        isTrue,
      );

      expect(actionIds, hasLength(2));
      expect(actionIds[0], isNot(equals(actionIds[1])));
      expect(toastIds, hasLength(2));
      expect(toastIds[0], isNot(equals(toastIds[1])));

      await _sendPlatformMethodCall(
        toastChannel,
        'actionInvoked',
        <String, Object?>{'actionId': actionIds[0]},
      );
      await _sendPlatformMethodCall(
        toastChannel,
        'actionInvoked',
        <String, Object?>{'actionId': actionIds[1]},
      );

      expect(firstTapCount, 1);
      expect(secondTapCount, 1);

      await _sendPlatformMethodCall(
        toastChannel,
        'toastDismissed',
        <String, Object?>{'toastId': toastIds[0]},
      );
      await _sendPlatformMethodCall(
        toastChannel,
        'actionInvoked',
        <String, Object?>{'actionId': actionIds[0]},
      );
      await _sendPlatformMethodCall(
        toastChannel,
        'actionInvoked',
        <String, Object?>{'actionId': actionIds[1]},
      );

      expect(firstTapCount, 1);
      expect(secondTapCount, 2);
    } finally {
      await AppleLiquidToast.dismiss();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(toastChannel, null);
    }
  });

  test('AppleLiquidToast keeps actions trailing-only by default', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final List<MethodCall> calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (MethodCall call) async {
          calls.add(call);
          return true;
        });

    try {
      expect(
        await AppleLiquidToast.show(
          title: 'Added to Cart',
          action: AppleLiquidToastAction(title: 'Undo', onPressed: () {}),
        ),
        isTrue,
      );

      final Map<Object?, Object?> arguments =
          calls.single.arguments as Map<Object?, Object?>;
      expect(arguments, containsPair('isWholeToastTappable', false));
    } finally {
      await AppleLiquidToast.dismiss();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(toastChannel, null);
    }
  });

  test('AppleLiquidToast serializes configurable stack options', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final List<MethodCall> calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (MethodCall call) async {
          calls.add(call);
          return true;
        });

    final AppleLiquidToastStackOptions previousStackOptions =
        AppleLiquidToast.stackOptions;
    AppleLiquidToast.stackOptions = const AppleLiquidToastStackOptions(
      maxVisibleToasts: 2,
      overflowTitle: '{count} weitere Toasts',
    );

    try {
      expect(
        await AppleLiquidToast.show(title: 'First', duration: null),
        isTrue,
      );
      expect(
        await AppleLiquidToast.show(title: 'Second', duration: null),
        isTrue,
      );

      final List<Map<Object?, Object?>> showArguments = calls
          .where((MethodCall call) => call.method == 'show')
          .map((MethodCall call) => call.arguments as Map<Object?, Object?>)
          .toList();

      expect(showArguments, hasLength(2));
      for (final Map<Object?, Object?> arguments in showArguments) {
        expect(arguments, containsPair('maxVisibleToasts', 2));
        expect(
          arguments,
          containsPair('overflowTitle', '{count} weitere Toasts'),
        );
      }
    } finally {
      AppleLiquidToast.stackOptions = previousStackOptions;
      await AppleLiquidToast.dismiss();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(toastChannel, null);
    }
  });

  test('AppleLiquidToast keeps the three-second default duration', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final List<MethodCall> calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (MethodCall call) async {
          calls.add(call);
          return true;
        });

    try {
      expect(await AppleLiquidToast.show(title: 'Saved'), isTrue);

      final Map<Object?, Object?> arguments =
          calls.single.arguments as Map<Object?, Object?>;
      expect(arguments, containsPair('duration', 3.0));
    } finally {
      await AppleLiquidToast.dismiss();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(toastChannel, null);
    }
  });

  test('AppleLiquidToast supports an indefinite native duration', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    String? actionId;
    String? toastId;
    int actionTapCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (MethodCall call) async {
          if (call.method == 'show') {
            final Map<Object?, Object?> arguments =
                call.arguments as Map<Object?, Object?>;
            actionId = arguments['actionId'] as String?;
            toastId = arguments['id'] as String?;
            expect(arguments['duration'], isNull);
          }

          return true;
        });

    try {
      expect(
        await AppleLiquidToast.show(
          title: 'Needs attention',
          duration: null,
          action: AppleLiquidToastAction(
            title: 'Undo',
            dismissesToast: false,
            onPressed: () {
              actionTapCount += 1;
            },
          ),
        ),
        isTrue,
      );

      expect(actionId, isNotNull);
      expect(toastId, isNotNull);

      await _sendPlatformMethodCall(
        toastChannel,
        'toastDismissed',
        <String, Object?>{'toastId': toastId},
      );
      await _sendPlatformMethodCall(
        toastChannel,
        'actionInvoked',
        <String, Object?>{'actionId': actionId},
      );

      expect(actionTapCount, 0);
    } finally {
      await AppleLiquidToast.dismiss();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(toastChannel, null);
    }
  });

  test('AppleLiquidToast.dismiss clears persistent action callbacks', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    String? actionId;
    int actionTapCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (MethodCall call) async {
          if (call.method == 'show') {
            final Map<Object?, Object?> arguments =
                call.arguments as Map<Object?, Object?>;
            actionId = arguments['actionId'] as String?;
          }

          return true;
        });

    try {
      await AppleLiquidToast.show(
        title: 'Needs attention',
        duration: null,
        action: AppleLiquidToastAction(
          title: 'Undo',
          dismissesToast: false,
          onPressed: () {
            actionTapCount += 1;
          },
        ),
      );

      await AppleLiquidToast.dismiss();
      await _sendPlatformMethodCall(
        toastChannel,
        'actionInvoked',
        <String, Object?>{'actionId': actionId},
      );

      expect(actionTapCount, 0);
    } finally {
      await AppleLiquidToast.dismiss();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(toastChannel, null);
    }
  });

  test('AppleLiquidToast action dismissal clears its callback', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    String? actionId;
    int actionTapCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (MethodCall call) async {
          if (call.method == 'show') {
            final Map<Object?, Object?> arguments =
                call.arguments as Map<Object?, Object?>;
            actionId = arguments['actionId'] as String?;
          }

          return true;
        });

    try {
      await AppleLiquidToast.show(
        title: 'Saved',
        action: AppleLiquidToastAction(
          title: 'Undo',
          onPressed: () {
            actionTapCount += 1;
          },
        ),
      );

      await _sendPlatformMethodCall(
        toastChannel,
        'actionInvoked',
        <String, Object?>{'actionId': actionId},
      );
      await _sendPlatformMethodCall(
        toastChannel,
        'actionInvoked',
        <String, Object?>{'actionId': actionId},
      );

      expect(actionTapCount, 1);
    } finally {
      await AppleLiquidToast.dismiss();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(toastChannel, null);
    }
  });

  test('AppleLiquidToast routes native action callbacks', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    String? actionId;
    int actionTapCount = 0;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(toastChannel, (MethodCall call) async {
          if (call.method == 'show') {
            final Map<Object?, Object?> arguments =
                call.arguments as Map<Object?, Object?>;
            actionId = arguments['actionId'] as String?;
          }

          return true;
        });

    try {
      expect(
        await AppleLiquidToast.show(
          title: 'Added to Cart',
          action: AppleLiquidToastAction(
            title: 'Undo',
            dismissesToast: false,
            onPressed: () {
              actionTapCount += 1;
            },
          ),
        ),
        isTrue,
      );

      expect(actionId, isNotNull);

      await _sendPlatformMethodCall(
        toastChannel,
        'actionInvoked',
        <String, Object?>{'actionId': actionId},
      );

      expect(actionTapCount, 1);
    } finally {
      await AppleLiquidToast.dismiss();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(toastChannel, null);
    }
  });

  test('AppleLiquidToastAction requires visible content', () {
    expect(() => AppleLiquidToastAction(title: ''), throwsAssertionError);
  });

  testWidgets('AppleLiquidSheet stops active scroll before native show', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

    final ScrollController scrollController = ScrollController();
    late BuildContext scrollContext;

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(sheetChannel, (MethodCall call) async {
          if (call.method == 'showTemplateSheet') {
            return true;
          }

          return null;
        });

    try {
      await tester.pumpWidget(
        MaterialApp(
          home: ListView(
            controller: scrollController,
            children: <Widget>[
              Builder(
                builder: (BuildContext context) {
                  scrollContext = context;
                  return const SizedBox(height: 2000);
                },
              ),
            ],
          ),
        ),
      );
      expect(scrollController.position.maxScrollExtent, greaterThan(0));

      final Future<void> scrollAnimation = scrollController.animateTo(
        600,
        duration: const Duration(seconds: 1),
        curve: Curves.linear,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(scrollController.offset, greaterThan(0));

      expect(
        (await AppleLiquidSheet.showSheet(
          scrollContext: scrollContext,
        )).didPresent,
        isTrue,
      );
      final double stoppedOffset = scrollController.offset;

      await scrollAnimation;
      await tester.pump(const Duration(milliseconds: 500));
      expect(scrollController.offset, stoppedOffset);
    } finally {
      scrollController.dispose();
      debugDefaultTargetPlatformOverride = null;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(sheetChannel, null);
    }
  });

  testWidgets('AppleLiquidSymbol uses an Icon fallback outside iOS', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    try {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: AppleLiquidSymbol(
              'sparkles',
              size: 32,
              color: Color(0xFF0EA5E9),
              weight: AppleLiquidSymbolWeight.semibold,
              fallbackIcon: Icons.auto_awesome_rounded,
              semanticLabel: 'Highlights',
            ),
          ),
        ),
      );

      final Icon icon = tester.widget<Icon>(
        find.byIcon(Icons.auto_awesome_rounded),
      );

      expect(icon.size, 32);
      expect(icon.color, const Color(0xFF0EA5E9));
      expect(icon.weight, AppleLiquidSymbolWeight.semibold.fallbackIconWeight);
      expect(icon.semanticLabel, 'Highlights');
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets(
    'AppleLiquidSymbol paints native bytes as a Flutter image on iOS',
    (WidgetTester tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final List<MethodCall> calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(symbolChannel, (MethodCall call) async {
            calls.add(call);
            return transparentPng;
          });

      try {
        await tester.pumpWidget(
          const MaterialApp(
            home: Center(
              child: AppleLiquidSymbol(
                'sparkles',
                size: 32,
                color: Color(0xFF0EA5E9),
                weight: AppleLiquidSymbolWeight.heavy,
                fallbackIcon: Icons.auto_awesome_rounded,
              ),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(Image), findsOneWidget);
        expect(find.byIcon(Icons.auto_awesome_rounded), findsNothing);
        expect(calls, hasLength(1));
        expect(calls.single.method, 'render');
        expect(calls.single.arguments, containsPair('name', 'sparkles'));
        expect(calls.single.arguments, containsPair('size', 32.0));
        expect(calls.single.arguments, containsPair('color', 0xFF0EA5E9));
        expect(calls.single.arguments, containsPair('weight', 'heavy'));
      } finally {
        debugDefaultTargetPlatformOverride = null;
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(symbolChannel, null);
      }
    },
  );

  testWidgets('uses a tappable Flutter fallback outside iOS', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    int selectedIndex = 0;

    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AppleLiquidTabBar(
              currentIndex: selectedIndex,
              selectedTintColor: const Color(0xFF0EA5E9),
              onChanged: (int index) {
                selectedIndex = index;
              },
              items: const <AppleLiquidTabItem>[
                AppleLiquidTabItem(title: 'Home', systemImage: 'house.fill'),
                AppleLiquidTabItem(
                  title: 'Jobs',
                  systemImage: 'briefcase.fill',
                ),
                AppleLiquidTabItem(
                  title: 'Chat',
                  systemImage: 'message.fill',
                  notificationDotColor: Color(0xFFEF4444),
                  notificationBadgeValue: '3',
                ),
              ],
              searchItem: const AppleLiquidTabItem(
                title: 'Search',
                systemImage: 'plus',
                isSearch: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Jobs'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(
        tester
            .widget<BottomNavigationBar>(find.byType(BottomNavigationBar))
            .selectedItemColor,
        const Color(0xFF0EA5E9),
      );
      expect(
        find.byWidgetPredicate((Widget widget) {
          final Decoration? decoration = widget is DecoratedBox
              ? widget.decoration
              : null;

          return decoration is BoxDecoration &&
              decoration.shape == BoxShape.circle &&
              decoration.color == const Color(0xFFEF4444);
        }),
        findsAtLeastNWidgets(1),
      );
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.text('Jobs'));

      expect(selectedIndex, 1);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('uses Flutter fallbacks for switch, slider, and surface', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    bool switchValue = false;
    double sliderValue = 0.25;

    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: <Widget>[
                AppleLiquidSwitch(
                  value: switchValue,
                  onChanged: (bool value) {
                    switchValue = value;
                  },
                ),
                AppleLiquidSlider(
                  value: sliderValue,
                  step: 0.25,
                  onChanged: (double value) {
                    sliderValue = value;
                  },
                ),
                const AppleLiquidSurface(child: Text('Surface child')),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(Switch), findsOneWidget);
      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('Surface child'), findsOneWidget);
      expect(tester.widget<Slider>(find.byType(Slider)).divisions, 4);

      await tester.tap(find.byType(Switch));

      expect(switchValue, isTrue);
      expect(sliderValue, 0.25);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('AppleLiquidSlider can render a trailing value label', (
    WidgetTester tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;

    try {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppleLiquidSlider(
              value: 1.25,
              min: 0,
              max: 1,
              valueLabelBuilder: (BuildContext context, double value) {
                return Text('${(value * 100).round()}%');
              },
              onChanged: (_) {},
            ),
          ),
        ),
      );

      expect(find.byType(Slider), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  test('AppleLiquidSlider accepts one value label source', () {
    expect(
      () => AppleLiquidSlider(
        value: 0.5,
        valueLabel: const Text('50%'),
        valueLabelBuilder: (BuildContext context, double value) {
          return const Text('50%');
        },
        onChanged: (_) {},
      ),
      throwsAssertionError,
    );
  });

  test('AppleLiquidSlider keeps release-relevant range guards', () {
    expect(
      () => AppleLiquidSlider(value: 0.5, min: 1, max: 0, onChanged: (_) {}),
      throwsAssertionError,
    );
    expect(
      () => AppleLiquidSlider(value: 0.5, step: 2, onChanged: (_) {}),
      throwsAssertionError,
    );
  });

  test('AppleLiquidSymbol keeps native render-size guards', () {
    expect(
      () => AppleLiquidSymbol('sparkles', size: 513),
      throwsAssertionError,
    );
  });

  testWidgets('AppleLiquidStretch keeps wrapped content interactive', (
    WidgetTester tester,
  ) async {
    int taps = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: AppleLiquidStretch(
              child: GestureDetector(
                onTap: () {
                  taps += 1;
                },
                child: const SizedBox(
                  width: 160,
                  height: 80,
                  child: Center(child: Text('Stretch child')),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Stretch child'));
    await tester.drag(find.text('Stretch child'), const Offset(32, 6));
    await tester.pumpAndSettle();

    expect(taps, 1);
    expect(find.text('Stretch child'), findsOneWidget);
  });

  testWidgets(
    'AppleLiquidStretch gestureDetector mode lets taps pass through',
    (WidgetTester tester) async {
      int taps = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AppleLiquidStretch(
                gestureMode: AppleLiquidStretchGestureMode.gestureDetector,
                child: GestureDetector(
                  onTap: () {
                    taps += 1;
                  },
                  child: const SizedBox(
                    width: 160,
                    height: 80,
                    child: Center(child: Text('Button-like child')),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final TestGesture tapGesture = await tester.startGesture(
        tester.getCenter(find.text('Button-like child')),
      );
      await tester.pump();

      expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);

      await tapGesture.up();
      await tester.pumpAndSettle();

      expect(taps, 1);

      final TestGesture dragGesture = await tester.startGesture(
        tester.getCenter(find.text('Button-like child')),
      );
      await dragGesture.moveBy(const Offset(36, 0));
      await tester.pump();

      expect(
        tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale,
        greaterThan(1),
      );

      await dragGesture.up();
      await tester.pumpAndSettle();
    },
  );
}
