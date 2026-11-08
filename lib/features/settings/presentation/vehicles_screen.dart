import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milemaid/core/models/vehicle.dart';
import 'package:milemaid/features/settings/providers/settings_provider.dart';
import 'package:uuid/uuid.dart';

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicles = ref.watch(vehiclesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showVehicleDialog(context, ref),
          ),
        ],
      ),
      body: vehicles.isEmpty
          ? const Center(child: Text('No vehicles yet'))
          : ListView.builder(
              itemCount: vehicles.length,
              itemBuilder: (ctx, i) {
                final v = vehicles[i];
                return ListTile(
                  leading: const Icon(Icons.directions_car_filled),
                  title: Text(v.name),
                  subtitle: Text(v.displayLabel),
                  onTap: () => _showVehicleDialog(context, ref, existing: v),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => ref.read(vehiclesProvider.notifier).deleteVehicle(v.id),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showVehicleDialog(
    BuildContext ctx,
    WidgetRef ref, {
    Vehicle? existing,
  }) async {
    final nameCtrl = TextEditingController(text: existing?.name ?? 'My Car');
    final makeCtrl = TextEditingController(text: existing?.makeModel ?? '');
    final yearCtrl = TextEditingController(
      text: (existing?.year ?? DateTime.now().year).toString(),
    );
    final colorCtrl = TextEditingController(text: existing?.color ?? '');

    final result = await showDialog<Vehicle>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: Text(existing == null ? 'Add Vehicle' : 'Edit Vehicle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Nickname'),
              ),
              TextField(
                controller: makeCtrl,
                decoration: const InputDecoration(labelText: 'Make & Model'),
              ),
              TextField(
                controller: yearCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Year'),
              ),
              TextField(
                controller: colorCtrl,
                decoration: const InputDecoration(labelText: 'Color (optional)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final name = nameCtrl.text.trim();
              final make = makeCtrl.text.trim();
              final v = Vehicle(
                id: existing?.id ?? const Uuid().v4(),
                name: name.isEmpty ? 'My Car' : name,
                makeModel: make.isEmpty ? 'Unknown' : make,
                year: int.tryParse(yearCtrl.text.trim()) ?? DateTime.now().year,
                color: colorCtrl.text.trim().isEmpty ? null : colorCtrl.text.trim(),
              );
              Navigator.pop(c, v);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      final notifier = ref.read(vehiclesProvider.notifier);
      if (existing == null) {
        await notifier.addVehicle(result);
      } else {
        await notifier.updateVehicle(result);
      }
    }
  }
}