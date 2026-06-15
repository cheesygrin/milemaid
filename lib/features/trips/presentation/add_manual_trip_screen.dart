import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milemaid/core/constants/app_colors.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/services/tracking_service.dart';
import 'package:milemaid/features/dashboard/providers/dashboard_provider.dart';
import 'package:milemaid/features/trips/providers/trips_provider.dart';

class AddManualTripScreen extends ConsumerStatefulWidget {
  const AddManualTripScreen({super.key});

  @override
  ConsumerState<AddManualTripScreen> createState() => _AddManualTripScreenState();
}

class _AddManualTripScreenState extends ConsumerState<AddManualTripScreen> {
  final _formKey = GlobalKey<FormState>();
  final _milesCtrl = TextEditingController();
  final _purposeCtrl = TextEditingController();
  TripCategory _category = TripCategory.business;
  DateTime _start = DateTime.now().subtract(const Duration(minutes: 45));
  DateTime _end = DateTime.now();

  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Manual Trip')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _milesCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Distance (miles)', suffixText: 'mi'),
              validator: (v) {
                final d = double.tryParse(v ?? '');
                if (d == null || d <= 0) return 'Enter a valid distance';
                return null;
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _dateTimePicker('Start', _start, (d) => setState(() => _start = d)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _dateTimePicker('End', _end, (d) => setState(() => _end = d)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Category'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: TripCategory.values.map((c) => ChoiceChip(
                label: Text(c.displayName),
                selected: c == _category,
                onSelected: (_) => setState(() => _category = c),
              )).toList(),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _purposeCtrl,
              decoration: const InputDecoration(labelText: 'Purpose (optional)'),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _isSaving ? null : _save,
              child: _isSaving ? const CircularProgressIndicator() : const Text('Save Trip'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _quickStartLive,
              child: const Text('Start Live Tracking Instead'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateTimePicker(String label, DateTime value, ValueChanged<DateTime> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 1)),
            );
            if (date == null || !mounted) return;
            final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(value));
            if (time == null) return;
            onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${value.month}/${value.day}  ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}',
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    final miles = double.parse(_milesCtrl.text);
    final duration = _end.difference(_start).inMinutes.abs().clamp(1, 999);

    final trip = Trip(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: _start,
      endTime: _end,
      distanceMiles: miles,
      durationMinutes: duration,
      routePoints: const [], // manual has no route
      category: _category,
      purpose: _purposeCtrl.text.trim().isEmpty ? null : _purposeCtrl.text.trim(),
      isConfirmed: true,
    );

    await ref.read(tripsProvider.notifier).addOrUpdateTrip(trip);
    ref.read(dashboardProvider.notifier).refresh();
    if (mounted) {
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Manual trip saved')));
    }
  }

  Future<void> _quickStartLive() async {
    await TrackingService().startManualTrip();
    if (mounted) context.pop();
  }
}
