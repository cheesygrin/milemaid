import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milemaid/core/models/purpose_preset.dart';
import 'package:milemaid/core/models/trip.dart';
import 'package:milemaid/core/services/database_service.dart';
import 'package:milemaid/core/services/trip_sync_service.dart';
import 'package:milemaid/shared/widgets/empty_state.dart';
import 'package:uuid/uuid.dart';

/// Settings screen for trip-purpose presets: add, rename, change category,
/// delete (with confirm) and reorder by drag handle; the list order is
/// persisted as [PurposePreset.sortOrder].
class PurposesScreen extends ConsumerStatefulWidget {
  const PurposesScreen({super.key});

  @override
  ConsumerState<PurposesScreen> createState() => _PurposesScreenState();
}

class _PurposesScreenState extends ConsumerState<PurposesScreen> {
  List<PurposePreset> _presets = const [];

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    // getAllPurposes sorts by sortOrder already.
    setState(() => _presets = DatabaseService().getAllPurposes());
  }

  Future<void> _persistOrder(int oldIndex, int newIndex) async {
    final presets = [..._presets];
    final moved = presets.removeAt(oldIndex);
    presets.insert(newIndex, moved);
    for (var i = 0; i < presets.length; i++) {
      if (presets[i].sortOrder != i) {
        final reordered = presets[i].copyWith(sortOrder: i);
        await DatabaseService().savePurpose(reordered);
        unawaited(TripSyncService.instance.upsertPurpose(reordered));
      }
    }
    _reload();
  }

  Future<void> _confirmDelete(PurposePreset preset) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Delete "${preset.name}"?'),
        content: const Text('Trips already using it keep their saved purpose text.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await DatabaseService().deletePurpose(preset.id);
    unawaited(TripSyncService.instance.removePurpose(preset.id));
    _reload();
  }

  Future<void> _editPurpose([PurposePreset? existing]) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    var category = existing?.category ?? TripCategory.business;
    var nameError = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Add Purpose' : 'Edit Purpose'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: existing == null,
                decoration: InputDecoration(
                  labelText: 'Name',
                  errorText: nameError ? 'Name is required' : null,
                ),
              ),
              DropdownButtonFormField<TripCategory>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: TripCategory.values
                    .map((c) => DropdownMenuItem(value: c, child: Text(c.displayName)))
                    .toList(),
                onChanged: (v) => setDialogState(() => category = v ?? TripCategory.business),
              ),
            ],
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

    final preset = PurposePreset(
      id: existing?.id ?? const Uuid().v4(),
      name: nameCtrl.text.trim(),
      category: category,
      sortOrder: existing?.sortOrder ?? _presets.length,
    );
    await DatabaseService().savePurpose(preset);
    unawaited(TripSyncService.instance.upsertPurpose(preset));
    _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Purposes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _editPurpose(),
          ),
        ],
      ),
      body: _presets.isEmpty
          ? const EmptyState(
              icon: Icons.label_outline,
              title: 'No purposes yet',
              subtitle: 'Add presets like "Client visit" to classify drives faster.',
            )
          : ReorderableListView.builder(
              itemCount: _presets.length,
              onReorderItem: _persistOrder,
              itemBuilder: (ctx, i) {
                final preset = _presets[i];
                return ListTile(
                  key: ValueKey(preset.id),
                  leading: const Icon(Icons.drag_handle),
                  title: Text(preset.name),
                  subtitle: Text(preset.category.displayName),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(preset),
                  ),
                  onTap: () => _editPurpose(preset),
                );
              },
            ),
    );
  }
}
