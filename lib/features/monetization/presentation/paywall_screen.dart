import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milemaid/core/constants/app_strings.dart';
import 'package:milemaid/features/settings/providers/settings_provider.dart';

/// Simple Paywall / Upgrade screen.
/// In a real release this would integrate with in_app_purchase + RevenueCat
/// for actual subscription purchases and entitlement checking.
class PaywallScreen extends ConsumerWidget {
  const PaywallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.upgradeToPro)),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Icon(Icons.workspace_premium, size: 72, color: Colors.amber),
          const SizedBox(height: 16),
          const Text(
            'Go Pro',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Unlock unlimited automatic mileage tracking, full IRS-ready PDF reports, '
            'CSV exports, and more vehicles.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 32),

          _PlanCard(
            title: 'Pro',
            price: AppStrings.pricingMonthly,
            yearly: AppStrings.pricingYearly,
            features: const [
              'Unlimited trips & reports',
              'Full professional PDFs (no limits)',
              'CSV + all exports',
              'Unlimited vehicles',
              'Priority support',
            ],
            isCurrent: settings.isPro,
            onSubscribe: () => _subscribe(ref, context, pro: true),
          ),

          const SizedBox(height: 16),

          _PlanCard(
            title: 'Premium',
            price: AppStrings.pricingPremiumMonthly,
            yearly: '\$89/year',
            features: const [
              'Everything in Pro',
              'Cloud backup & sync (coming soon)',
              'Advanced analytics & categorization',
              'Early access to new features',
            ],
            isCurrent: false,
            onSubscribe: () => _subscribe(ref, context, premium: true),
            highlight: true,
          ),

          const SizedBox(height: 32),

          const Text(
            'Subscriptions can be managed in your App Store / Google Play account. '
            'Cancel anytime. Prices in USD.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Maybe later'),
          ),
        ],
      ),
    );
  }

  void _subscribe(WidgetRef ref, BuildContext context, {bool pro = false, bool premium = false}) {
    // For now this is a dev shortcut. Replace with real IAP flow.
    ref.read(settingsProvider.notifier).setProStatus(true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Thank you! Pro features unlocked (dev simulation). '
            'Replace this with real in_app_purchase + RevenueCat in production.'),
      ),
    );
    Navigator.pop(context);
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String yearly;
  final List<String> features;
  final bool isCurrent;
  final VoidCallback onSubscribe;
  final bool highlight;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.yearly,
    required this.features,
    required this.isCurrent,
    required this.onSubscribe,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: highlight ? Colors.blue.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(4)),
                    child: const Text('Current', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(price, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600)),
            Text('or $yearly', style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 12),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.check, size: 16, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(f)),
                    ],
                  ),
                )),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: isCurrent ? null : onSubscribe,
                child: Text(isCurrent ? 'Current plan' : 'Subscribe'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
