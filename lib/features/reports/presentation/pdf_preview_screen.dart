import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import 'package:milemaid/core/config/app_config.dart';
import 'package:milemaid/core/services/export_service.dart';
import 'package:milemaid/features/settings/providers/settings_provider.dart';

class PdfPreviewScreen extends StatelessWidget {
  const PdfPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0);

    return Scaffold(
      appBar: AppBar(title: const Text('PDF Preview')),
      body: Consumer(
        builder: (context, ref, _) {
          final settings = ref.watch(settingsProvider);
          final userName = settings.name.isNotEmpty ? settings.name : 'Mileage Log';
          final isPro = !AppConfig.monetizationEnabled || settings.isPro;
          return PdfPreview(
            build: (format) async {
              final svc = ExportService();
              final doc = await svc.buildPdfPreview(start, end, userName, isPro: isPro);
              return doc.save();
            },
            initialPageFormat: PdfPageFormat.letter,
          );
        },
      ),
    );
  }
}
