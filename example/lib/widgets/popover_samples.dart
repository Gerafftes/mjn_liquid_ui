import 'package:flutter/material.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';

/// Consumer-owned example content; the plugin contains no popover template.
class PopoverSamplesPage extends StatefulWidget {
  const PopoverSamplesPage({super.key});

  @override
  State<PopoverSamplesPage> createState() => _PopoverSamplesPageState();
}

class _PopoverSamplesPageState extends State<PopoverSamplesPage> {
  final _title = TextEditingController(text: 'Your popover');
  final _message = TextEditingController(
    text: 'This content comes from the app.',
  );
  double _width = 320;
  double _height = 380;
  bool _fixedHeight = false;
  bool _forcePopover = true;
  bool _dismissOnTapOutside = true;
  bool _customColor = false;
  String _result = 'No presentation yet';

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Native popover')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          TextField(
            controller: _title,
            decoration: const InputDecoration(labelText: 'Popover title'),
          ),
          TextField(
            controller: _message,
            decoration: const InputDecoration(labelText: 'Popover message'),
          ),
          const SizedBox(height: 20),
          Text('Preferred width: ${_width.round()} pt'),
          Slider(
            value: _width,
            min: 200,
            max: 600,
            onChanged: (value) => setState(() => _width = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Use a preferred height'),
            value: _fixedHeight,
            onChanged: (value) => setState(() => _fixedHeight = value),
          ),
          if (_fixedHeight) ...[
            Text('Preferred height: ${_height.round()} pt'),
            Slider(
              value: _height,
              min: 180,
              max: 700,
              onChanged: (value) => setState(() => _height = value),
            ),
          ],
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Keep popover in compact layouts'),
            value: _forcePopover,
            onChanged: (value) => setState(() => _forcePopover = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Dismiss when tapping outside'),
            value: _dismissOnTapOutside,
            onChanged: (value) => setState(() => _dismissOnTapOutside = value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Use a custom background color'),
            value: _customColor,
            onChanged: (value) => setState(() => _customColor = value),
          ),
          const SizedBox(height: 16),
          Center(
            child: AppleLiquidPopoverAnchor(
              builder: (context, popover) => FilledButton.icon(
                icon: const Icon(Icons.open_in_new),
                label: const Text('Show native popover'),
                onPressed: () => _show(popover),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(_result, key: const ValueKey('popover-result')),
        ],
      ),
    );
  }

  Future<void> _show(AppleLiquidPopoverController popover) async {
    final result = await popover.show(
      options: AppleLiquidPopoverOptions(
        width: _width,
        height: _fixedHeight ? _height : null,
        maxHeight: 700,
        compactBehavior: _forcePopover
            ? AppleLiquidPopoverCompactBehavior.popover
            : AppleLiquidPopoverCompactBehavior.automatic,
        dismissOnTapOutside: _dismissOnTapOutside,
        backgroundColor: _customColor ? const Color(0xFFF2F7FF) : null,
        tintColor: const Color(0xFF007AFF),
        showsToolbarActions: true,
      ),
      content: AppleLiquidPopoverContent(
        title: _title.text,
        trailingAction: const AppleLiquidSheetToolbarAction(title: 'Apply'),
        sections: [
          AppleLiquidSheetSection(
            rows: [
              AppleLiquidSheetRow.text(title: _message.text),
              const AppleLiquidSheetRow.textField(
                identifier: 'name',
                title: 'Name',
                value: 'Editable native text',
              ),
              const AppleLiquidSheetRow.toggle(
                title: 'Notifications',
                value: true,
              ),
              const AppleLiquidSheetRow.slider(title: 'Intensity', value: 0.6),
            ],
          ),
        ],
      ),
    );
    if (!mounted) return;
    setState(() {
      _result = result.status == AppleLiquidSheetResultStatus.notPresented
          ? 'Native popovers require iOS 16+ and a visible anchor.'
          : '${result.status.name}: ${result.textField('name')?.value ?? ''}';
    });
  }
}
