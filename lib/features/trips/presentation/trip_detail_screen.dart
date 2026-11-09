import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:milemaid/core/config/app_config.dart';
import 'package:milemaid/core/constants/app_colors.dart';
import 'package:milemaid/core/models/named_location.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/models/trip_expense.dart';
import 'package:milemaid/core/services/database_service.dart';
import 'package:milemaid/core/services/place_matcher.dart';
import 'package:milemaid/core/services/trip_enricher.dart';
import 'package:milemaid/core/utils/date_helpers.dart';
import 'package:milemaid/features/settings/providers/settings_provider.dart';
import 'package:milemaid/features/trips/providers/trips_provider.dart';
import 'package:milemaid/shared/widgets/category_chip.dart';
import 'package:milemaid/shared/widgets/custom_map.dart';
import 'package:uuid/uuid.dart';

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
  String? _customLabel;
  int? _customColor;
  List<TripExpense> _expenses = [];

  @override
  void initState() {
    super.initState();
    _loadTrip();
  }

  /// Current named places keyed by id, for the From/To labels.
  Map<String, NamedLocation> get _placesById =>
      locationsById(DatabaseService().getAllLocations());

  /// Re-reads the trip from the provider without touching edit-in-progress
  /// state (unlike [_loadTrip], which resets the controllers).
  void _refreshTripObject() {
    final trips = ref.read(tripsProvider);
    final idx = trips.indexWhere((t) => t.id == widget.tripId);
    if (idx != -1) {
      setState(() => _trip = trips[idx]);
    }
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
    _customLabel = _trip.customCategoryLabel;
    _customColor = _trip.customCategoryColor;
    _expenses = List.from(_trip.expenses);
  }

  Future<void> _save() async {
    final updated = _trip.copyWith(
      category: _category,
      customCategoryLabel: _customLabel,
      customCategoryColor: _customColor,
      expenses: _expenses,
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

  Future<void> _toggleCategory() async {
    final isBusiness = _trip.category == TripCategory.business;
    final updated = _trip.copyWith(
      category: isBusiness ? TripCategory.personal : TripCategory.business,
      customCategoryLabel: null,
      customCategoryColor: null,
      isConfirmed: true,
    );
    await ref.read(tripsProvider.notifier).addOrUpdateTrip(updated);
    setState(() {
      _trip = updated;
      _category = updated.category;
      _customLabel = null;
      _customColor = null;
    });
  }

  Future<void> _duplicateReturn() async {
    final newTrip = await ref.read(tripsProvider.notifier).duplicateAsReturn(_trip.id);
    if (newTrip != null && mounted) {
      context.pop();
      context.push('/trips/${newTrip.id}');
    }
  }

  Future<void> _addExpense() async {
    var type = ExpenseType.toll;
    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          title: const Text('Add expense'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                children: ExpenseType.values.map((t) {
                  return ChoiceChip(
                    label: Text(t.displayName),
                    selected: t == type,
                    onSelected: (_) => setModal(() => type = t),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Amount', prefixText: '\$'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(labelText: 'Note (optional)'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Add')),
          ],
        ),
      ),
    );
    if (ok != true) return;

    final amount = double.tryParse(amountCtrl.text.trim()) ?? 0.0;
    if (amount <= 0) return;
    setState(() {
      _expenses.add(TripExpense(
        id: const Uuid().v4(),
        type: type,
        amountCents: (amount * 100).round(),
        note: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      ));
    });
  }

  /// Purpose preset chips: the end place's [NamedLocation.defaultPurpose]
  /// first (highlighted as a suggestion, never auto-applied), then the
  /// presets sorted by [PurposePreset.sortOrder].
  List<Widget> get _purposeChips {
    final chips = <Widget>[];

    final endPlace = _placesById[_trip.endLocationId];
    final suggestion = endPlace?.defaultPurpose;
    if (suggestion != null && suggestion.isNotEmpty) {
      chips.add(
        ActionChip(
          tooltip: 'Suggested from ${endPlace!.name}',
          backgroundColor: AppColors.accent.withValues(alpha: 0.15),
          side: BorderSide(color: AppColors.accent.withValues(alpha: 0.6)),
          label: Text(
            suggestion,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.accent,
            ),
          ),
          onPressed: () => _applyPurpose(
            suggestion,
            endPlace.defaultCategory ?? _category,
          ),
        ),
      );
    }

    final presets = DatabaseService().getAllPurposes();
    chips.addAll(
      presets.map(
        (p) => ActionChip(
          label: Text(p.name, style: const TextStyle(fontSize: 13)),
          onPressed: () => _applyPurpose(p.name, p.category),
        ),
      ),
    );
    return chips;
  }

  /// Fills the purpose/category draft from a tapped chip and reveals the
  /// Save button; nothing is written until the user saves.
  void _applyPurpose(String purpose, TripCategory category) {
    setState(() {
      _category = category;
      _purposeCtrl.text = purpose;
      _isEditing = true;
    });
  }

  Widget _endpointRow(
    String title,
    String? locationId,
    String? address,
    LatLngPoint? point,
  ) {
    final label = placeLabel(locationId, address, _placesById);
    return ListTile(
      dense: true,
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: Text(label),
      trailing: point == null
          ? null
          : TextButton(
              onPressed: () => _nameThisPlace(point, address),
              child: const Text('Name this place'),
            ),
    );
  }

  /// "Name this place": asks for a name, a geofence radius (50-500 m) and an
  /// optional default category, then creates a [NamedLocation] at [point],
  /// re-matches every trip against the new place and refreshes.
  Future<void> _nameThisPlace(LatLngPoint point, String? address) async {
    final nameCtrl = TextEditingController();
    var radius = 150.0;
    TripCategory? defaultCategory;
    var nameError = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Name this place'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Name',
                  errorText: nameError ? 'Name is required' : null,
                ),
              ),
              const SizedBox(height: 8),
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
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final name = nameCtrl.text.trim();
                if (name.isEmpty) {
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

    final place = NamedLocation(
      id: const Uuid().v4(),
      name: nameCtrl.text.trim(),
      latitude: point.latitude,
      longitude: point.longitude,
      radiusMeters: radius,
      // Store the trip's address on the place so later trips here inherit it.
      address: address,
      defaultCategory: defaultCategory,
      createdAt: DateTime.now(),
    );
    await DatabaseService().saveLocation(place);
    final changed = await TripEnricher.instance.rematchAll();
    await ref.read(tripsProvider.notifier).refresh();
    _refreshTripObject();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved "${place.name}". $changed trip(s) re-matched.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_maybeTrip == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final hasRoute = _trip.routePoints.length > 1;
    final customCategories = ref.watch(settingsProvider).customCategories;

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

          // From / To endpoints, with a "Name this place" action each when
          // the route has points.
          Card(
            child: Column(
              children: [
                _endpointRow(
                  'From',
                  _trip.startLocationId,
                  _trip.startAddress,
                  _trip.routePoints.isNotEmpty ? _trip.routePoints.first : null,
                ),
                const Divider(height: 1),
                _endpointRow(
                  'To',
                  _trip.endLocationId,
                  _trip.endAddress,
                  _trip.routePoints.isNotEmpty ? _trip.routePoints.last : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Expenses
          if (!_isEditing) ...[
            if (_expenses.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Expenses', style: Theme.of(context).textTheme.titleSmall),
                    Text('\$${_trip.totalExpenses.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
          ] else ...[
            Text('Expenses', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            if (_expenses.isEmpty)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text('No expenses. Add tolls or parking.',
                    style: TextStyle(color: AppColors.textSecondary)),
              )
            else
              ..._expenses.asMap().entries.map((entry) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.receipt_outlined, size: 20),
                    title: Text(
                        '${entry.value.type.displayName} - \$${(entry.value.amountCents / 100).toStringAsFixed(2)}'),
                    subtitle: entry.value.note != null ? Text(entry.value.note!) : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => setState(() => _expenses.removeAt(entry.key)),
                    ),
                  )),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _addExpense,
                icon: const Icon(Icons.add),
                label: const Text('Add expense'),
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Category
          Text('Category', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          if (_isEditing)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...TripCategory.values.map((c) {
                  final sel = _customLabel == null && c == _category;
                  return ChoiceChip(
                    label: Text(c.displayName),
                    selected: sel,
                    onSelected: (_) => setState(() {
                      _category = c;
                      _customLabel = null;
                      _customColor = null;
                    }),
                  );
                }),
                ...customCategories.map((cl) {
                  final sel = _customLabel == cl.label;
                  return ChoiceChip(
                    label: Text(cl.label),
                    selected: sel,
                    onSelected: (_) => setState(() {
                      _customLabel = cl.label;
                      _customColor = cl.colorValue;
                      _category = TripCategory.other;
                    }),
                  );
                }),
              ],
            )
          else
            CategoryChip(
              category: _trip.category,
              customLabel: _trip.customCategoryLabel,
              customColorValue: _trip.customCategoryColor,
            ),
          const SizedBox(height: 20),

          // Purpose presets (sorted by sortOrder); the trip's end place may
          // suggest one first. Tapping a chip fills the purpose text and
          // category; the existing Save confirms the trip. Free-text editing
          // below still works.
          if (_purposeChips.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: _purposeChips,
            ),
            const SizedBox(height: 12),
          ],

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
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  void _cancelEdit() {
    setState(() => _isEditing = false);
    _loadTrip(); // revert
  }

  Widget _buildBottomBar() {
    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: _isEditing
          ? Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: _cancelEdit, child: const Text('Cancel')),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(onPressed: _save, child: const Text('Save Changes')),
                ),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: FilledButton.tonal(
                    onPressed: _toggleCategory,
                    child: Text(_trip.category == TripCategory.business
                        ? 'Mark as Personal'
                        : 'Mark as Business'),
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
