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
      child: AppleLiquidSwitchGroup(
        rowHeight: 64,
        items: <AppleLiquidSwitchGroupItem>[
          for (int index = 0; index < values.length; index++)
            AppleLiquidSwitchGroupItem(
              id: 'sample-$index',
              label: Text(
                'Native switch ${index + 1}: ${values[index] ? 'On' : 'Off'}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              semanticLabel: 'Native switch ${index + 1}',
              value: values[index],
              tintColor: _switchTintColors[index],
              onChanged: (bool value) => onChanged(index, value),
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
