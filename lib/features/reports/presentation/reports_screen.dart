import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:milemaid/core/config/app_config.dart';
import 'package:milemaid/core/constants/app_colors.dart';
import 'package:milemaid/core/constants/irs_rates.dart';
import 'package:milemaid/core/services/export_service.dart';
import 'package:milemaid/features/reports/providers/reports_provider.dart';
import 'package:milemaid/features/settings/providers/settings_provider.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedRange = 'Month';

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(reportsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Date range selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Date Range', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: ['Month', 'Quarter', 'Year', 'All'].map((r) => ChoiceChip(
                      label: Text(r),
                      selected: r == _selectedRange,
                      onSelected: (_) {
                        setState(() => _selectedRange = r);
                        ref.read(reportsProvider.notifier).setQuickRange(r);
                      },
                    )).toList(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${report.startDate.month}/${report.startDate.day}/${report.startDate.year} – ${report.endDate.month}/${report.endDate.day}/${report.endDate.year}',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Summary KPIs
          Row(
            children: [
              _kpi('Business', '${report.businessMiles.toStringAsFixed(1)} mi', AppColors.accent),
              _kpi('Total', '${report.totalMiles.toStringAsFixed(1)} mi', AppColors.primary),
              _kpi('Trips', '${report.totalTrips}', AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            color: AppColors.accent.withValues(alpha: 0.08),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Estimated Deduction', style: TextStyle(fontSize: 16)),
                  Text(
                    '\$${report.deductionAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.accent),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),
          const Text('Category Breakdown', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 120, child: _CategoryPie()),

          const SizedBox(height: 16),

          // Export buttons. Pro gating is disabled until real IAP exists
          // (see AppConfig.monetizationEnabled) — v1 ships fully free.
          Consumer(
            builder: (context, ref, _) {
              final settings = ref.watch(settingsProvider);
              final isPro = !AppConfig.monetizationEnabled || settings.isPro;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () async {
                            if (!isPro) {
                              _showUpgradeDialog(context);
                              return;
                            }
                            final svc = ExportService();
                            await svc.exportPdfReport(
                              start: report.startDate,
                              end: report.endDate,
                              userName: settings.name.isNotEmpty ? settings.name : 'Mileage Log',
                              isPro: isPro,
                            );
                          },
                          icon: const Icon(Icons.picture_as_pdf),
                          label: const Text('Export PDF'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            if (!isPro) {
                              _showUpgradeDialog(context);
                              return;
                            }
                            final svc = ExportService();
                            await svc.exportCsv(report.startDate, report.endDate);
                          },
                          icon: const Icon(Icons.table_chart),
                          label: const Text('Export CSV'),
                        ),
                      ),
                    ],
                  ),
                  if (!isPro) ...[
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => _showUpgradeDialog(context),
                      child: const Text('Upgrade to Pro for unlimited exports & full PDFs →'),
                    ),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => context.push('/reports/pdf-preview'),
            child: const Text('Preview PDF layout'),
          ),

          const SizedBox(height: 24),

          // Prominent legal disclaimer
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade200),
            ),
            child: Text(
              IrsRates.shortDisclaimer,
              style: const TextStyle(fontSize: 11, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kpi(String label, String value, Color color) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryPie extends ConsumerWidget {
  const _CategoryPie();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(reportsProvider);
    final data = [
      PieChartSectionData(value: report.businessMiles, color: AppColors.accent, title: 'Biz', radius: 50),
      PieChartSectionData(value: report.personalMiles, color: AppColors.personal, title: 'Pers', radius: 50),
      PieChartSectionData(value: report.commuteMiles, color: AppColors.commute, title: 'Comm', radius: 50),
      PieChartSectionData(value: report.otherMiles, color: AppColors.other, title: 'Oth', radius: 50),
    ];
    return PieChart(PieChartData(sections: data, centerSpaceRadius: 40));
  }
}

void _showUpgradeDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Unlock Pro'),
      content: const Text(
        'Pro unlocks unlimited PDF & CSV exports, full professional reports without limits, and more vehicles.\n\n'
        r'$4.99/month or $49/year. Cancel anytime.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(ctx);
            context.push('/upgrade');
          },
          child: const Text('View plans'),
        ),
      ],
    ),
  );
}
