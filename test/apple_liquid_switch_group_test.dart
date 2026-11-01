import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';
import 'package:mjn_liquid_ui/src/apple_liquid_platform_view.dart';

AppleLiquidSwitchGroupItem item(
  String id, {
  bool value = false,
  ValueChanged<bool>? onChanged,
  Color? tintColor,
}) => AppleLiquidSwitchGroupItem(
  id: id,
  label: Text(id),
  semanticLabel: 'Switch $id',
  value: value,
  tintColor: tintColor,
  onChanged: onChanged ?? (_) {},
);

Widget host(
  List<AppleLiquidSwitchGroupItem> items, {
  TextDirection direction = TextDirection.ltr,
}) => MaterialApp(
  home: Material(
    child: Directionality(
      textDirection: direction,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: 320,
          child: AppleLiquidSwitchGroup(items: items),
        ),
      ),
    ),
  ),
);

Future<void> event(
  MethodChannel channel,
  String name,
  Map<String, Object?> args,
) async {
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(
        channel.name,
        const StandardMethodCodec().encodeMethodCall(MethodCall(name, args)),
        (_) {},
      );
}

void groupTest(String name, Future<void> Function(WidgetTester) body) {
  testWidgets(name, (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    try {
      await body(tester);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  final List<MethodCall> platformCalls = <MethodCall>[];
  final List<MethodCall> updates = <MethodCall>[];
  final List<MethodChannel> channels = <MethodChannel>[];
  Completer<void>? creation;

  setUp(() {
    platformCalls.clear();
    updates.clear();
    channels.clear();
    creation = null;
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, (
      call,
    ) async {
      platformCalls.add(call);
      if (call.method == 'create') {
        final args = call.arguments as Map;
        final channel = MethodChannel(
          'mjn_liquid_ui_switch_group/${args['id']}',
        );
        channels.add(channel);
        messenger.setMockMethodCallHandler(channel, (call) async {
          updates.add(call);
          return null;
        });
        await creation?.future;
      }
      return null;
    });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    messenger.setMockMethodCallHandler(SystemChannels.platform_views, null);
    for (final channel in channels) {
      messenger.setMockMethodCallHandler(channel, null);
    }
  });

  test('rejects invalid geometry and IDs and snapshots the list', () {
    for (final height in <double>[43, double.infinity, double.nan, -1]) {
      expect(
        () => AppleLiquidSwitchGroup(items: [item('a')], rowHeight: height),
        throwsArgumentError,
      );
    }
    expect(
      () => AppleLiquidSwitchGroup(items: [item('')]),
      throwsArgumentError,
    );
    expect(
      () => AppleLiquidSwitchGroup(items: [item('a'), item('a')]),
      throwsArgumentError,
    );
    final source = [item('a')];
    final group = AppleLiquidSwitchGroup(items: source);
    source.clear();
    expect(group.items, hasLength(1));
    expect(() => group.items.clear(), throwsUnsupportedError);
  });

  groupTest('one view/channel, stable ID routing, removal, and teardown', (
    tester,
  ) async {
    final values = <String>[];
    await tester.pumpWidget(
      host([
        item('a', onChanged: (_) => values.add('a')),
        item('b', onChanged: (_) => values.add('b')),
      ]),
    );
    await tester.pump();
    expect(find.byType(AppleLiquidUiKitView), findsOneWidget);
    expect(
      platformCalls.where((call) => call.method == 'create'),
      hasLength(1),
    );
    expect(channels, hasLength(1));
    final channel = channels.single;
    await tester.pumpWidget(
      host([item('b', onChanged: (_) => values.add('latest b')), item('a')]),
    );
    await event(channel, 'valueChanged', {'id': 'b', 'value': true});
    expect(values, ['latest b']);
    final config = updates.last.arguments as Map;
    expect((config['items'] as List).map((e) => (e as Map)['id']), ['b', 'a']);
    await tester.pumpWidget(host([item('a')]));
    await event(channel, 'valueChanged', {'id': 'b', 'value': false});
    expect(values, ['latest b']);
    await tester.pumpWidget(host([]));
    await tester.pump();
    expect(find.byType(AppleLiquidUiKitView), findsNothing);
    expect(
      platformCalls.where((call) => call.method == 'dispose'),
      hasLength(1),
    );
    await event(channel, 'valueChanged', {'id': 'a', 'value': true});
    expect(values, ['latest b']);
  });

  groupTest(
    'recreated group ignores old channels and disposes a late old creation',
    (tester) async {
      final callbacks = <String>[];
      await tester.pumpWidget(
        host([item('a', onChanged: (_) => callbacks.add('original'))]),
      );
      await tester.pump();
      final originalChannel = channels.single;
      await tester.pumpWidget(host([]));
      await tester.pump();

      final pendingCreation = Completer<void>();
      creation = pendingCreation;
      await tester.pumpWidget(
        host([item('a', onChanged: (_) => callbacks.add('pending'))]),
      );
      final pendingChannel = channels.last;
      await tester.pumpWidget(host([]));
      creation = null;
      await tester.pumpWidget(
        host([item('a', onChanged: (_) => callbacks.add('latest'))]),
      );
      await tester.pump();
      final latestChannel = channels.last;
      expect(channels, hasLength(3));
      expect(latestChannel.name, isNot(originalChannel.name));
      expect(latestChannel.name, isNot(pendingChannel.name));

      final updatesBeforeLateCreation = updates.length;
      pendingCreation.complete();
      await tester.pump();
      await tester.pump();
      expect(updates, hasLength(updatesBeforeLateCreation));
      final disposedIds = platformCalls
          .where((call) => call.method == 'dispose')
          .map((call) => call.arguments as int);
      final createdIds = platformCalls
          .where((call) => call.method == 'create')
          .map((call) => (call.arguments as Map)['id'])
          .toList();
      expect(disposedIds, containsAll(createdIds.take(2)));
      expect(disposedIds, isNot(contains(createdIds.last)));

      for (final oldChannel in [originalChannel, pendingChannel]) {
        await event(oldChannel, 'valueChanged', {'id': 'a', 'value': true});
      }
      expect(callbacks, isEmpty);
      await event(latestChannel, 'valueChanged', {'id': 'a', 'value': true});
      expect(callbacks, ['latest']);

      await tester.pumpWidget(host([]));
      await tester.pump();
      await event(latestChannel, 'valueChanged', {'id': 'a', 'value': false});
      expect(callbacks, ['latest']);
    },
  );

  groupTest(
    'latest configuration wins delayed creation and interaction completion',
    (tester) async {
      creation = Completer<void>();
      await tester.pumpWidget(host([item('a')]));
      await tester.pumpWidget(
        host([item('a', value: true, tintColor: Colors.red), item('b')]),
      );
      creation!.complete();
      await tester.pump();
      await tester.pump();
      expect(channels, hasLength(1));
      Map config = updates.last.arguments as Map;
      expect((config['items'] as List).first['value'], true);
      expect(
        (config['items'] as List).first['tintColor'],
        Colors.red.toARGB32(),
      );
      final channel = channels.single;
      await event(channel, 'interactionChanged', {
        'id': 'a',
        'isInteracting': true,
      });
      await tester.pumpWidget(
        host([item('a', value: false, tintColor: Colors.blue)]),
      );
      await event(channel, 'interactionChanged', {
        'id': 'a',
        'isInteracting': false,
      });
      await tester.pump();
      config = updates.last.arguments as Map;
      expect((config['items'] as List).single['value'], false);
      expect(
        (config['items'] as List).single['tintColor'],
        Colors.blue.toARGB32(),
      );
    },
  );

  groupTest('RTL mirrors columns and eager recognizer stays in native column', (
    tester,
  ) async {
    await tester.pumpWidget(host([item('a')], direction: TextDirection.rtl));
    await tester.pump();
    final native = tester.widget<AppleLiquidUiKitView>(
      find.byType(AppleLiquidUiKitView),
    );
    expect(native.layoutDirection, TextDirection.rtl);
    expect(native.gestureRecognizers, hasLength(1));
    expect(tester.getSize(find.byType(AppleLiquidUiKitView)).width, 76);
    expect(
      tester.getTopLeft(find.text('a')).dx,
      greaterThan(tester.getTopLeft(find.byType(AppleLiquidUiKitView)).dx),
    );
  });

  groupTest('Android uses adaptive switches and no native view', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    bool? changed;
    await tester.pumpWidget(
      host([item('a', onChanged: (v) => changed = v), item('b')]),
    );
    expect(find.byType(Switch), findsNWidgets(2));
    expect(find.byType(AppleLiquidUiKitView), findsNothing);
    expect(platformCalls, isEmpty);
    await tester.tap(find.byType(Switch).first);
    expect(changed, true);
  });
}
