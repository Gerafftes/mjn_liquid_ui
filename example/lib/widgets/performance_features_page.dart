import 'package:flutter/material.dart';
import 'package:mjn_liquid_ui/mjn_liquid_ui.dart';

/// Interactive examples of the optional performance APIs.
class PerformanceFeaturesPage extends StatefulWidget {
  const PerformanceFeaturesPage({super.key});

  @override
  State<PerformanceFeaturesPage> createState() =>
      _PerformanceFeaturesPageState();
}

class _PerformanceFeaturesPageState extends State<PerformanceFeaturesPage> {
  bool _notifications = false;
  bool _reminders = true;
  bool _rtl = false;
  bool _preparing = false;
  String _precacheStatus = 'Prepare the star before displaying it.';
  bool _showStar = false;

  Future<void> _prepareStar() async {
    setState(() => _preparing = true);
    final bool ready = await AppleLiquidSymbol.precache(
      context,
      'star.fill',
      size: 32,
      color: Colors.amber,
    );
    if (!mounted) return;
    setState(() {
      _preparing = false;
      _showStar = true;
      _precacheStatus = ready ? 'Star prepared' : 'Using the platform fallback';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Performance examples')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          Text(
            'Grouped switches',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          AppleLiquidSurface(
            height: 160,
            deferMountUntilRouteTransitionCompletes: true,
            child: Directionality(
              textDirection: _rtl ? TextDirection.rtl : TextDirection.ltr,
              child: AppleLiquidSwitchGroup(
                items: <AppleLiquidSwitchGroupItem>[
                  AppleLiquidSwitchGroupItem(
                    id: 'notifications',
                    label: Text(
                      'Notifications: ${_notifications ? 'On' : 'Off'}',
                    ),
                    semanticLabel: 'Notifications',
                    value: _notifications,
                    onChanged: (value) =>
                        setState(() => _notifications = value),
                  ),
                  AppleLiquidSwitchGroupItem(
                    id: 'reminders',
                    label: Text('Reminders: ${_reminders ? 'On' : 'Off'}'),
                    semanticLabel: 'Reminders',
                    value: _reminders,
                    tintColor: Colors.teal,
                    onChanged: (value) => setState(() => _reminders = value),
                  ),
                ],
              ),
            ),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Right-to-left layout'),
            value: _rtl,
            onChanged: (value) => setState(() => _rtl = value!),
          ),
          const Text(
            'The glass background appears after the entrance transition. '
            'Scroll from a label to keep scrolling the Flutter list.',
          ),
          const SizedBox(height: 24),
          Text(
            'Symbol precache',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _preparing ? null : _prepareStar,
            child: Text(_preparing ? 'Preparing…' : 'Prepare and show star'),
          ),
          Text(_precacheStatus),
          if (_showStar)
            const Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppleLiquidSymbol(
                'star.fill',
                size: 32,
                color: Colors.amber,
                fallbackIcon: Icons.star,
                semanticLabel: 'Prepared star',
              ),
            ),
          // Leave enough Flutter content to exercise scrolling over the labels.
          const SizedBox(height: 400),
          const Text('End of performance examples'),
        ],
      ),
    );
  }
}
