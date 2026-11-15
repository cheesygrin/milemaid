import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:intl/intl.dart';
import 'package:milemaid/core/config/app_config.dart';
import 'package:milemaid/core/constants/app_colors.dart';
import 'package:milemaid/core/constants/app_strings.dart';
import 'package:milemaid/core/services/purchase_service.dart';
import 'package:milemaid/features/monetization/providers/pro_provider.dart';
import 'package:url_launcher/url_launcher.dart';

/// Sells MileMaid Pro. Prices and billing periods come from the App Store,
/// never from strings in the app.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  final PurchaseService _purchases = PurchaseService.instance;
  bool _annualSelected = true;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    if (_purchases.status.value == StoreStatus.unavailable) {
      _purchases.loadProducts();
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _subscribe(ProductDetails product) async {
    setState(() => _busy = true);
    final outcome = await _purchases.buy(product);
    if (!mounted) return;
    setState(() => _busy = false);
    switch (outcome) {
      case PurchaseOutcome.purchased:
        _snack(AppStrings.proWelcome);
        if (context.canPop()) context.pop();
      case PurchaseOutcome.pending:
        _snack('Your purchase is waiting for approval. Pro unlocks as soon as it goes through.');
      case PurchaseOutcome.failed:
        _snack('The purchase did not go through. You have not been charged.');
      case PurchaseOutcome.canceled:
        break;
    }
  }

  Future<void> _restore() async {
    setState(() => _busy = true);
    final restored = await _purchases.restore();
    if (!mounted) return;
    setState(() => _busy = false);
    if (restored) {
      _snack(AppStrings.proWelcome);
      if (context.canPop()) context.pop();
    } else {
      _snack('No active MileMaid Pro subscription was found for this Apple ID.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPro = ref.watch(proProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.proName)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          children: [
            Text(
              AppStrings.proHeadline,
              style: theme.textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(AppStrings.proSubhead, style: theme.textTheme.bodyLarge),
            const SizedBox(height: 24),
            for (final feature in AppStrings.proFeatures)
              _FeatureRow(title: feature.$1, detail: feature.$2),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                AppStrings.freeForever,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            if (isPro)
              const _ActivePlan()
            else
              ValueListenableBuilder<StoreStatus>(
                valueListenable: _purchases.status,
                builder: (context, status, _) => switch (status) {
                  StoreStatus.loading => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  StoreStatus.unavailable => _StoreUnavailable(
                      onRetry: _purchases.loadProducts,
                    ),
                  StoreStatus.ready => _plans(),
                },
              ),
            const SizedBox(height: 8),
            if (!isPro)
              TextButton(
                onPressed: _busy ? null : _restore,
                child: const Text('Restore purchases'),
              ),
            const SizedBox(height: 8),
            Text(
              AppStrings.subscriptionTerms,
              style: theme.textTheme.bodySmall?.copyWith(color: AppColors.textTertiary),
              textAlign: TextAlign.center,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => _open(AppConfig.termsOfUseUrl),
                  child: const Text('Terms of Use'),
                ),
                TextButton(
                  onPressed: () => _open(AppConfig.privacyPolicyUrl),
                  child: const Text('Privacy Policy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _plans() {
    final annual = _purchases.annual;
    final monthly = _purchases.monthly;
    final selected = (_annualSelected ? annual : monthly) ?? annual ?? monthly!;
    final savings = annual == null || monthly == null
        ? null
        : PurchaseService.annualSavingsPercent(
            annualPrice: annual.rawPrice,
            monthlyPrice: monthly.rawPrice,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (annual != null)
          _PlanTile(
            title: 'Yearly',
            price: '${annual.price} / year',
            detail: '${_perMonth(annual)} / month, billed once a year',
            badge: savings == null ? null : 'Save $savings%',
            selected: identical(selected, annual),
            onTap: _busy ? null : () => setState(() => _annualSelected = true),
          ),
        if (annual != null && monthly != null) const SizedBox(height: 12),
        if (monthly != null)
          _PlanTile(
            title: 'Monthly',
            price: '${monthly.price} / month',
            detail: 'Billed every month',
            selected: identical(selected, monthly),
            onTap: _busy ? null : () => setState(() => _annualSelected = false),
          ),
        const SizedBox(height: 20),
        FilledButton(
          onPressed: _busy ? null : () => _subscribe(selected),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
          child: _busy
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(identical(selected, annual)
                  ? 'Subscribe for ${annual!.price} / year'
                  : 'Subscribe for ${selected.price} / month'),
        ),
      ],
    );
  }

  /// The yearly price shown per month, in the store's own currency.
  String _perMonth(ProductDetails annual) =>
      NumberFormat.simpleCurrency(name: annual.currencyCode)
          .format(annual.rawPrice / 12);

  Future<void> _open(String url) async {
    final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!opened) _snack('Could not open the link.');
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({required this.title, required this.detail});

  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle, size: 20, color: AppColors.accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text(detail, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanTile extends StatelessWidget {
  const _PlanTile({
    required this.title,
    required this.price,
    required this.detail,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  final String title;
  final String price;
  final String detail;
  final String? badge;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: selected ? primary.withValues(alpha: 0.08) : null,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? primary : theme.dividerColor,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: selected ? primary : AppColors.textTertiary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title, style: theme.textTheme.titleMedium),
                        if (badge != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accent,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              badge!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(price, style: theme.textTheme.titleSmall),
                    Text(detail, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivePlan extends StatelessWidget {
  const _ActivePlan();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(Icons.verified, color: AppColors.accent),
          title: Text(AppStrings.proActive),
          subtitle: Text('Reports and cloud sync are unlocked. Thank you for supporting MileMaid.'),
        ),
        OutlinedButton(
          onPressed: () => launchUrl(
            Uri.parse(AppConfig.manageSubscriptionsUrl),
            mode: LaunchMode.externalApplication,
          ),
          child: const Text(AppStrings.manageSubscription),
        ),
      ],
    );
  }
}

class _StoreUnavailable extends StatelessWidget {
  const _StoreUnavailable({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Plans could not be loaded from the App Store. Check your connection and try again.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
      ],
    );
  }
}
