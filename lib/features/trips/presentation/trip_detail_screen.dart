import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milemaid/core/config/app_config.dart';
import 'package:milemaid/core/constants/app_colors.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/utils/date_helpers.dart';
import 'package:milemaid/features/trips/providers/trips_provider.dart';
import 'package:milemaid/shared/widgets/category_chip.dart';
import 'package:milemaid/shared/widgets/custom_map.dart';

class TripDetailScreen extends ConsumerStatefulWidget {
  final String tripId;
  const TripDetailScreen({super.key, required this.tripId});

  @override
  ConsumerState<TripDetailScreen> createState() => _TripDetailScreenState();
}

class _TripDetailScreenState extends ConsumerState<TripDetailScreen> {
  Trip? _maybeTrip;
  Trip get _trip => _maybeTrip!;
  set _trip(Trip value) => _maybeTrip = value;
  bool _isEditing = false;
  final _purposeCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  TripCategory _category = TripCategory.business;
  double? _startOdo;
  double? _endOdo;

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  void _loadTrip() {
    final trips = ref.read(tripsProvider);
    final idx = trips.indexWhere((t) => t.id == widget.tripId);
    if (idx == -1) {
      // Trip was deleted or the ID is stale; bail out gracefully.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.canPop()) context.pop();
      });
      return;
    }
    _trip = trips[idx];
    _category = _trip.category;
    _purposeCtrl.text = _trip.purpose ?? '';
    _notesCtrl.text = _trip.notes ?? '';
    _startOdo = _trip.startOdometer;
    _endOdo = _trip.endOdometer;
  }

  Future<void> _save() async {
    final updated = _trip.copyWith(
      category: _category,
      purpose: _purposeCtrl.text.trim().isEmpty ? null : _purposeCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      startOdometer: _startOdo,
      endOdometer: _endOdo,
      isConfirmed: true,
    );
    await ref.read(tripsProvider.notifier).addOrUpdateTrip(updated);
    setState(() {
      _trip = updated;
      _isEditing = false;
    });
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip updated')));
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Trip?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (ok == true) {
      await ref.read(tripsProvider.notifier).deleteTrip(_trip.id);
      if (mounted) context.pop();
    }
  }

  Future<void> _markBusiness() async {
    final updated = _trip.copyWith(category: TripCategory.business, isConfirmed: true);
    await ref.read(tripsProvider.notifier).addOrUpdateTrip(updated);
    setState(() => _trip = updated);
  }

  Future<void> _duplicateReturn() async {
    final newTrip = await ref.read(tripsProvider.notifier).duplicateAsReturn(_trip.id);
    if (newTrip != null && mounted) {
      context.pop();
      context.push('/trips/${newTrip.id}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_maybeTrip == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final hasRoute = _trip.routePoints.length > 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Details'),
        actions: [
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.edit), onPressed: () => setState(() => _isEditing = true)),
          IconButton(icon: const Icon(Icons.delete_outline), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Map
          SizedBox(
            height: 260,
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: !hasRoute
                  ? const Center(child: Text('No route data recorded'))
                  : AppConfig.googleMapsEnabled
                      ? CustomMap(
                          points: _trip.routeLatLng,
                          fitBounds: true,
                        )
                      : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.route, size: 48, color: AppColors.textTertiary),
                              const SizedBox(height: 8),
                              Text(
                                '${_trip.routePoints.length} GPS points recorded',
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
            ),
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              _bigStat(_trip.formattedDistance, 'Distance'),
              _bigStat(_trip.formattedDuration, 'Duration'),
              _bigStat(DateHelpers.formatTime(_trip.startTime), 'Started'),
            ],
          ),
          const SizedBox(height: 16),

          // Category
          Text('Category', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (_isEditing)
            Wrap(
              spacing: 8,
              children: TripCategory.values.map((c) {
                final sel = c == _category;
                return ChoiceChip(
                  label: Text(c.displayName),
                  selected: sel,
                  onSelected: (_) => setState(() => _category = c),
                );
              }).toList(),
            )
          else
            CategoryChip(category: _trip.category),
          const SizedBox(height: 20),

          // Editable fields
          TextField(
            controller: _purposeCtrl,
            enabled: _isEditing,
            decoration: const InputDecoration(labelText: 'Purpose', hintText: 'Client meeting, airport run...'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesCtrl,
            enabled: _isEditing,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Notes', hintText: 'Parking, tolls, passengers...'),
          ),
          const SizedBox(height: 12),
          if (_isEditing) ...[
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _startOdo?.toStringAsFixed(1) ?? '',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Start Odometer'),
                    onChanged: (v) => _startOdo = double.tryParse(v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _endOdo?.toStringAsFixed(1) ?? '',
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'End Odometer'),
                    onChanged: (v) => _endOdo = double.tryParse(v),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 24),

          // Quick actions
          if (!_isEditing) ...[
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _markBusiness,
                    child: const Text('Mark as Business'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _duplicateReturn,
                    child: const Text('Duplicate as Return'),
                  ),
                ),
              ],
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _isEditing = false);
                      _loadTrip(); // revert
                    },
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(onPressed: _save, child: const Text('Save Changes')),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _bigStat(String value, String label) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
