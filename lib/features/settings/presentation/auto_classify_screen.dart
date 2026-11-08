import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milemaid/core/models/named_location.dart';
import 'package:milemaid/core/models/work_hours.dart';
import 'package:milemaid/core/services/location_service.dart';
import 'package:milemaid/features/settings/providers/settings_provider.dart';
import 'package:uuid/uuid.dart';

/// Manage the auto-classification rules (MileIQ-style): work hours and named
/// locations. A matched drive is pre-marked Business so it skips the swipe queue.
class AutoClassifyScreen extends ConsumerStatefulWidget {
  const AutoClassifyScreen({super.key});

  @override
  ConsumerState<AutoClassifyScreen> createState() => _AutoClassifyScreenState();
}

class _AutoClassifyScreenState extends ConsumerState<AutoClassifyScreen> {
  static const _dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Auto-classification')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader('Work hours'),
          const Text(
            'Drives that start during these hours are marked Business automatically.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          if (settings.workHours.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No work hours set.', style: TextStyle(color: Colors.grey)),
            )
          else
            ...settings.workHours.map((wh) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(_fmtWorkHours(wh)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => notifier.setWorkHours(
                      settings.workHours.where((e) => e.id != wh.id).toList(),
                    ),
                  ),
                )),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addWorkHours,
              icon: const Icon(Icons.add),
              label: const Text('Add work hours'),
            ),
          ),
          const SizedBox(height: 24),
          const _SectionHeader('Named locations'),
          const Text(
            'Drives that start near one of these places are marked Business automatically.',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          if (settings.namedLocations.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('No saved locations.', style: TextStyle(color: Colors.grey)),
            )
          else
            ...settings.namedLocations.map((loc) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(loc.name),
                  subtitle: Text('${loc.radiusMeters} m radius'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => notifier.setNamedLocations(
                      settings.namedLocations.where((e) => e.id != loc.id).toList(),
                    ),
                  ),
                )),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addLocation,
              icon: const Icon(Icons.add),
              label: const Text('Add location'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _addWorkHours() async {
    final weekdays = <int>{1, 2, 3, 4, 5};
    var start = const TimeOfDay(hour: 9, minute: 0);
    var end = const TimeOfDay(hour: 17, minute: 0);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Work hours',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: List.generate(7, (i) {
                    final wd = i + 1;
                    return FilterChip(
                      label: Text(_dayLabels[i]),
                      selected: weekdays.contains(wd),
                      onSelected: (v) =>
                          setModal(() => v ? weekdays.add(wd) : weekdays.remove(wd)),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _TimeButton(
                        label: 'Start',
                        time: start,
                        onTap: () async {
                          final t = await showTimePicker(context: context, initialTime: start);
                          if (t != null) setModal(() => start = t);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TimeButton(
                        label: 'End',
                        time: end,
                        onTap: () async {
                          final t = await showTimePicker(context: context, initialTime: end);
                          if (t != null) setModal(() => end = t);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                          onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: weekdays.isEmpty
                            ? null
                            : () {
                                final wh = WorkHours(
                                  id: const Uuid().v4(),
                                  weekdays: weekdays.toList()..sort(),
                                  startMinutes: start.hour * 60 + start.minute,
                                  endMinutes: end.hour * 60 + end.minute,
                                );
                                final notifier = ref.read(settingsProvider.notifier);
                                notifier.setWorkHours([
                                  ...ref.read(settingsProvider).workHours,
                                  wh,
                                ]);
                                Navigator.pop(ctx);
                              },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addLocation() async {
    final nameCtrl = TextEditingController();
    final radiusCtrl = TextEditingController(text: '100');

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add location'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: radiusCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Radius (meters)'),
            ),
            const SizedBox(height: 8),
            const Text(
              'The location is saved at your current position.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
        ],
      ),
    );
    if (ok != true) return;

    final name = nameCtrl.text.trim();
    if (name.isEmpty) return;

    final pos = await LocationService().getCurrentPosition();
    final radius = int.tryParse(radiusCtrl.text.trim()) ?? 100;
    final loc = NamedLocation(
      id: const Uuid().v4(),
      name: name,
      lat: pos?.latitude ?? 0.0,
      lng: pos?.longitude ?? 0.0,
      radiusMeters: radius,
    );
    ref.read(settingsProvider.notifier).setNamedLocations([
      ...ref.read(settingsProvider).namedLocations,
      loc,
    ]);
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16));
}

class _TimeButton extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  const _TimeButton({required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      child: Text('$label: ${_fmtTime(time)}'),
    );
  }
}

String _fmtMinutes(int m) {
  final h = m ~/ 60;
  final mm = m % 60;
  final h12 = h % 12 == 0 ? 12 : h % 12;
  final ap = h < 12 ? 'AM' : 'PM';
  return '$h12:${mm.toString().padLeft(2, '0')} $ap';
}

String _fmtTime(TimeOfDay t) => _fmtMinutes(t.hour * 60 + t.minute);

String _fmtWorkHours(WorkHours wh) {
  const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final days = wh.weekdays.map((d) => labels[d - 1]).join(', ');
  return '$days, ${_fmtMinutes(wh.startMinutes)} to ${_fmtMinutes(wh.endMinutes)}';
}