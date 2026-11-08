import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milemaid/core/models/category_label.dart';
import 'package:milemaid/features/settings/providers/settings_provider.dart';
import 'package:uuid/uuid.dart';

/// Manage user-defined drive categories (label + color), MileIQ-style.
class CustomCategoriesScreen extends ConsumerWidget {
  const CustomCategoriesScreen({super.key});

  static const _palette = <Color>[
    Color(0xFF9C27B0), // purple
    Color(0xFFE91E63), // pink
    Color(0xFFFF9800), // orange
    Color(0xFF00BCD4), // cyan
    Color(0xFF8BC34A), // light green
    Color(0xFF607D8B), // blue grey
    Color(0xFF795548), // brown
    Color(0xFF3F51B5), // indigo
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final custom = ref.watch(settingsProvider).customCategories;
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom categories'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _addCategory(context, ref, custom),
          ),
        ],
      ),
      body: custom.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No custom categories yet.\nAdd labels like "Rideshare" or "Charity" to color-code and organize your drives.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView.builder(
              itemCount: custom.length,
              itemBuilder: (ctx, i) {
                final c = custom[i];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(c.colorValue),
                    radius: 12,
                  ),
                  title: Text(c.label),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => notifier.setCustomCategories(
                      custom.where((e) => e.id != c.id).toList(),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _addCategory(
    BuildContext context,
    WidgetRef ref,
    List<CategoryLabel> custom,
  ) async {
    final nameCtrl = TextEditingController();
    var selected = _palette.first;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => AlertDialog(
          title: const Text('New category'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Label'),
              ),
              const SizedBox(height: 16),
              const Text('Color'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _palette.map((p) {
                  final isSel = p == selected;
                  return InkWell(
                    onTap: () => setModal(() => selected = p),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: p,
                        shape: BoxShape.circle,
                        border: isSel
                            ? Border.all(color: Colors.black, width: 2.5)
                            : null,
                      ),
                      child: isSel
                          ? const Icon(Icons.check, color: Colors.white, size: 20)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                final label = nameCtrl.text.trim();
                if (label.isEmpty) return;
                ref.read(settingsProvider.notifier).setCustomCategories([
                  ...custom,
                  CategoryLabel(
                    id: const Uuid().v4(),
                    label: label,
                    colorValue: selected.toARGB32(),
                  ),
                ]);
                Navigator.pop(ctx);
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}