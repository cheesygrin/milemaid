import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart' as storekit;
import 'package:milemaid/core/config/app_config.dart';
import 'package:milemaid/core/services/database_service.dart';

/// Whether the store's products can be shown and bought right now.
enum StoreStatus { loading, ready, unavailable }

/// How one purchase attempt ended.
enum PurchaseOutcome { purchased, pending, canceled, failed }

/// MileMaid Pro: the App Store subscription that unlocks reports and cloud
/// sync. The store is the only source of truth; the copy kept in Hive just
/// makes paid features right at launch and while offline.
class PurchaseService {
  PurchaseService._()
      : _injectedStore = null,
        _readCached = _readFromHive,
        _writeCached = _writeToHive,
        _syncWithAppStore = _appStoreSync,
        _settle = const Duration(seconds: 1);
  static final PurchaseService instance = PurchaseService._();

  @visibleForTesting
  PurchaseService.forTesting({
    required InAppPurchase store,
    required bool Function() readCached,
    required Future<void> Function(bool active) writeCached,
    Future<void> Function()? syncWithAppStore,
  })  : _injectedStore = store,
        _readCached = readCached,
        _writeCached = writeCached,
        _syncWithAppStore = syncWithAppStore ?? _noSync,
        _settle = Duration.zero;

  static const Set<String> productIds = {
    AppConfig.proAnnualProductId,
    AppConfig.proMonthlyProductId,
  };

  /// True when paid features should work: the subscription is active, or this
  /// build has monetization turned off.
  static bool get proUnlocked =>
      !AppConfig.monetizationEnabled || instance.isPro.value;

  final InAppPurchase? _injectedStore;
  InAppPurchase get _store => _injectedStore ?? InAppPurchase.instance;

  final bool Function() _readCached;
  final Future<void> Function(bool active) _writeCached;
  final Future<void> Function() _syncWithAppStore;

  /// StoreKit reports each entitlement in its own message, which can land
  /// just after the restore call returns. Wait this long before deciding the
  /// user has none.
  final Duration _settle;

  final ValueNotifier<bool> isPro = ValueNotifier(false);
  final ValueNotifier<StoreStatus> status = ValueNotifier(StoreStatus.loading);

  ProductDetails? annual;
  ProductDetails? monthly;

  bool _started = false;
  bool _sawEntitlement = false;
  Future<void>? _refresh;
  Completer<PurchaseOutcome>? _buying;

  /// Call once at startup, after Hive is open. Returns when products are
  /// loaded and the subscription state has been checked.
  Future<void> init() async {
    if (!AppConfig.monetizationEnabled || _started) return;
    _started = true;
    isPro.value = _readCached();
    try {
      _store.purchaseStream.listen(_onPurchases, onError: (Object _) {});
    } catch (_) {
      // No store on this platform: stay on the remembered state.
      status.value = StoreStatus.unavailable;
      return;
    }
    await Future.wait([loadProducts(), refreshEntitlement()]);
  }

  Future<void> loadProducts() async {
    status.value = StoreStatus.loading;
    try {
      if (!await _store.isAvailable()) {
        status.value = StoreStatus.unavailable;
        return;
      }
      final response = await _store.queryProductDetails(productIds);
      ProductDetails? byId(String id) {
        for (final p in response.productDetails) {
          if (p.id == id) return p;
        }
        return null;
      }

      annual = byId(AppConfig.proAnnualProductId);
      monthly = byId(AppConfig.proMonthlyProductId);
      status.value = annual == null && monthly == null
          ? StoreStatus.unavailable
          : StoreStatus.ready;
    } catch (_) {
      status.value = StoreStatus.unavailable;
    }
  }

  /// Re-reads the active subscriptions from the store without prompting.
  /// Expired, refunded and revoked subscriptions are simply not reported, so
  /// a check that reports nothing ends Pro.
  Future<void> refreshEntitlement() {
    if (!_started) return Future<void>.value();
    return _refresh ??= _runRefresh();
  }

  Future<void> _runRefresh() async {
    _sawEntitlement = false;
    try {
      await _store.restorePurchases();
      await Future<void>.delayed(_settle);
      if (!_sawEntitlement) await _setPro(false);
    } catch (_) {
      // The store could not answer: keep the last known state.
    } finally {
      _refresh = null;
    }
  }

  /// The paywall's "Restore purchases": asks the App Store to re-sync this
  /// Apple ID (which may show a sign-in prompt), then re-checks.
  Future<bool> restore() async {
    try {
      await _syncWithAppStore();
    } catch (_) {
      // Sign-in dismissed or offline; the local check below still runs.
    }
    await refreshEntitlement();
    return isPro.value;
  }

  /// Starts the purchase sheet and completes when the store reports how it
  /// ended.
  Future<PurchaseOutcome> buy(ProductDetails product) async {
    if (_buying != null) return PurchaseOutcome.failed;
    final completer = _buying = Completer<PurchaseOutcome>();
    try {
      final started = await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) _finishBuy(PurchaseOutcome.failed);
    } catch (_) {
      _finishBuy(PurchaseOutcome.failed);
    }
    return completer.future;
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (!productIds.contains(purchase.productID)) continue;
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _sawEntitlement = true;
          await _setPro(true);
          if (purchase.pendingCompletePurchase) {
            try {
              await _store.completePurchase(purchase);
            } catch (_) {
              // Left unfinished, the store simply delivers it again later.
            }
          }
          if (purchase.status == PurchaseStatus.purchased) {
            _finishBuy(PurchaseOutcome.purchased);
          }
        case PurchaseStatus.pending:
          _finishBuy(PurchaseOutcome.pending);
        case PurchaseStatus.canceled:
          _finishBuy(PurchaseOutcome.canceled);
        case PurchaseStatus.error:
          _finishBuy(PurchaseOutcome.failed);
      }
    }
  }

  void _finishBuy(PurchaseOutcome outcome) {
    final completer = _buying;
    _buying = null;
    if (completer != null && !completer.isCompleted) completer.complete(outcome);
  }

  Future<void> _setPro(bool active) async {
    if (isPro.value == active) return;
    isPro.value = active;
    await _writeCached(active);
  }

  /// Whole-number percent saved by paying yearly instead of twelve monthly
  /// payments, or null when there is no saving to show.
  static int? annualSavingsPercent({
    required double annualPrice,
    required double monthlyPrice,
  }) {
    if (annualPrice <= 0 || monthlyPrice <= 0) return null;
    final saved = 1 - annualPrice / (monthlyPrice * 12);
    final percent = (saved * 100).round();
    return percent > 0 ? percent : null;
  }

  static bool _readFromHive() => DatabaseService().getProEntitlement();

  static Future<void> _writeToHive(bool active) =>
      DatabaseService().saveProEntitlement(active);

  static Future<void> _appStoreSync() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) return;
    await storekit.AppStore().sync();
  }

  static Future<void> _noSync() async {}
}
