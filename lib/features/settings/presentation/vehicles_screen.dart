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
            onPressed: () => _showAddDialog(context, ref),
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
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => ref.read(vehiclesProvider.notifier).deleteVehicle(v.id),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _showAddDialog(BuildContext ctx, WidgetRef ref) async {
    final nameCtrl = TextEditingController(text: 'My Car');
    final makeCtrl = TextEditingController(text: 'Honda Civic');
    final yearCtrl = TextEditingController(text: DateTime.now().year.toString());

    final result = await showDialog<Vehicle>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('Add Vehicle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Nickname')),
            TextField(controller: makeCtrl, decoration: const InputDecoration(labelText: 'Make & Model')),
            TextField(controller: yearCtrl, decoration: const InputDecoration(labelText: 'Year'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final v = Vehicle(
                id: const Uuid().v4(),
                name: nameCtrl.text.trim(),
                makeModel: makeCtrl.text.trim(),
                year: int.tryParse(yearCtrl.text) ?? 2024,
              );
              Navigator.pop(c, v);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null) {
      await ref.read(vehiclesProvider.notifier).addVehicle(result);
    }
  }
}
