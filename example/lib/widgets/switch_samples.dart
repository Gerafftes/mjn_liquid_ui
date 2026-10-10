import 'package:flutter/material.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';

class SwitchSamples extends StatelessWidget {
  const SwitchSamples({
    super.key,
    required this.values,
    required this.onChanged,
  });

  final List<bool> values;
  final void Function(int index, bool value) onChanged;

  @override
  Widget build(BuildContext context) {
    return AppleLiquidSurface(
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
