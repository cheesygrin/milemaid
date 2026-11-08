import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milemaid/core/constants/app_colors.dart';
import 'package:milemaid/core/models/named_location.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/services/database_service.dart';
import 'package:milemaid/core/services/trip_enricher.dart';
import 'package:milemaid/features/trips/providers/trips_provider.dart';
import 'package:milemaid/shared/widgets/empty_state.dart';

/// Settings screen listing the user's named places. Tap to edit, swipe or
/// use the button to delete; every change re-matches all trips. New places
/// are created from a drive's details ("Name this place"), where the
/// coordinates come from the trip itself.
class PlacesScreen extends ConsumerStatefulWidget {
  const PlacesScreen({super.key});

  @override
  ConsumerState<PlacesScreen> createState() => _PlacesScreenState();
}

class _PlacesScreenState extends ConsumerState<PlacesScreen> {
  List<NamedLocation> _places = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() => _places = DatabaseService().getAllLocations());
  }

  Future<void> _afterChange() async {
    // A place was moved, resized or deleted: re-match every trip.
    await TripEnricher.instance.rematchAll();
    await ref.read(tripsProvider.notifier).refresh();
    _reload();
  }

  Future<bool> _confirmDelete(NamedLocation place) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Delete "${place.name}"?'),
        content: const Text(
          'Trips will keep their recorded addresses but lose the place name.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _delete(NamedLocation place) async {
    await DatabaseService().deleteLocation(place.id);
    await _afterChange();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Places')),
      body: _places.isEmpty
          ? const EmptyState(
              icon: Icons.place_outlined,
              title: 'No places yet',
              subtitle: "Name a place from any drive's details.",
            )
          : ListView.builder(
              itemCount: _places.length,
              itemBuilder: (ctx, i) {
                final place = _places[i];
                return Dismissible(
                  key: ValueKey(place.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  confirmDismiss: (_) => _confirmDelete(place),
                  onDismissed: (_) => _delete(place),
                  child: ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: Text(place.name),
                    subtitle: Text(
                      '${place.address ?? 'No address'} • ${place.radiusMeters.round()} m',
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        if (await _confirmDelete(place)) await _delete(place);
                      },
                    ),
                    onTap: () => _editPlace(place),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _editPlace(NamedLocation existing) async {
    final nameCtrl = TextEditingController(text: existing.name);
    var radius = existing.radiusMeters.clamp(50, 500).toDouble();
    var defaultCategory = existing.defaultCategory;
    final purposeCtrl = TextEditingController(text: existing.defaultPurpose ?? '');
    var nameError = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Edit Place'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    errorText: nameError ? 'Name is required' : null,
                  ),
                ),
                Text('Radius: ${radius.round()} m',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                Slider(
                  value: radius,
                  min: 50,
                  max: 500,
                  divisions: 45,
                  label: '${radius.round()} m',
                  onChanged: (v) => setDialogState(() => radius = v),
                ),
                DropdownButtonFormField<TripCategory>(
                  initialValue: defaultCategory,
                  decoration: const InputDecoration(labelText: 'Default category (optional)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('None')),
                    ...TripCategory.values.map(
                      (c) => DropdownMenuItem(value: c, child: Text(c.displayName)),
                    ),
                  ],
                  onChanged: (v) => setDialogState(() => defaultCategory = v),
                ),
                TextField(
                  controller: purposeCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Default purpose (optional)',
                    hintText: 'Client visit',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) {
                  setDialogState(() => nameError = true);
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true) return;

    // Built directly (not copyWith) so an emptied purpose text clears the
    // stored value; copyWith cannot set a field back to null.
    final purpose = purposeCtrl.text.trim();
    final place = NamedLocation(
      id: existing.id,
      name: nameCtrl.text.trim(),
      latitude: existing.latitude,
      longitude: existing.longitude,
      radiusMeters: radius,
      address: existing.address,
      defaultCategory: defaultCategory,
      defaultPurpose: purpose.isEmpty ? null : purpose,
      createdAt: existing.createdAt,
    );
    await DatabaseService().saveLocation(place);
    await _afterChange();
  }
}
