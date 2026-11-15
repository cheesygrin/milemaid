import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:milemaid/core/config/app_config.dart';
import 'package:milemaid/core/services/purchase_service.dart';

/// Stands in for the App Store: no network, no platform channel.
class FakeStore implements InAppPurchase {
  final StreamController<List<PurchaseDetails>> _updates =
      StreamController<List<PurchaseDetails>>.broadcast(sync: true);

  bool available = true;
  List<ProductDetails> products = [];

  /// Subscriptions the store reports as active on a restore.
  List<String> activeProductIds = [];
  Object? restoreError;
  int restoreCalls = 0;

  /// How the next purchase sheet ends.
  PurchaseStatus buyResult = PurchaseStatus.purchased;
  final List<String> completed = [];

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _updates.stream;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<ProductDetailsResponse> queryProductDetails(Set<String> identifiers) async =>
      ProductDetailsResponse(
        productDetails: products.where((p) => identifiers.contains(p.id)).toList(),
        notFoundIDs: const [],
      );

  @override
  Future<void> restorePurchases({String? applicationUserName}) async {
    restoreCalls++;
    final error = restoreError;
    if (error != null) throw error;
    _updates.add([
      for (final id in activeProductIds) _details(id, PurchaseStatus.restored),
    ]);
  }

  @override
  Future<bool> buyNonConsumable({required PurchaseParam purchaseParam}) async {
    _updates.add([_details(purchaseParam.productDetails.id, buyResult)]);
    return true;
  }

  @override
  Future<void> completePurchase(PurchaseDetails purchase) async =>
      completed.add(purchase.productID);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

PurchaseDetails _details(String productId, PurchaseStatus status) => PurchaseDetails(
      purchaseID: '1',
      productID: productId,
      verificationData: PurchaseVerificationData(
        localVerificationData: '',
        serverVerificationData: '',
        source: 'test',
      ),
      transactionDate: null,
      status: status,
    )..pendingCompletePurchase = status == PurchaseStatus.purchased;

ProductDetails _product(String id, double price) => ProductDetails(
      id: id,
      title: id,
      description: '',
      price: '\$$price',
      rawPrice: price,
      currencyCode: 'USD',
    );

const _annualId = AppConfig.proAnnualProductId;
const _monthlyId = AppConfig.proMonthlyProductId;

void main() {
  late FakeStore store;
  late bool cached;
  late int appStoreSyncs;

  PurchaseService build({Future<void> Function()? sync}) => PurchaseService.forTesting(
        store: store,
        readCached: () => cached,
        writeCached: (active) async => cached = active,
        syncWithAppStore: sync ??
            () async {
              appStoreSyncs++;
            },
      );

  setUp(() {
    store = FakeStore()
      ..products = [_product(_annualId, 89.99), _product(_monthlyId, 9.99)];
    cached = false;
    appStoreSyncs = 0;
  });

  group('subscription state', () {
    test('an active subscription unlocks Pro and is remembered', () async {
      store.activeProductIds = [_monthlyId];
      final service = build();
      await service.init();
      expect(service.isPro.value, isTrue);
      expect(cached, isTrue);
    });

    test('the remembered state applies before the store answers', () {
      cached = true;
      store.activeProductIds = [_annualId];
      final service = build();
      unawaited(service.init());
      expect(service.isPro.value, isTrue);
    });

    test('a subscription the store no longer reports ends Pro', () async {
      cached = true;
      final service = build();
      await service.init();
      expect(service.isPro.value, isFalse);
      expect(cached, isFalse);
    });

    test('a store that cannot answer leaves the remembered state alone', () async {
      cached = true;
      store.restoreError = StateError('offline');
      final service = build();
      await service.init();
      expect(service.isPro.value, isTrue);
      expect(cached, isTrue);
    });

    test('other products never unlock Pro', () async {
      store.activeProductIds = ['com.example.something.else'];
      final service = build();
      await service.init();
      expect(service.isPro.value, isFalse);
    });

    test('nothing touches the store before init', () async {
      final service = build();
      await service.refreshEntitlement();
      expect(store.restoreCalls, 0);
    });

    test('a later check picks up an expiry', () async {
      store.activeProductIds = [_annualId];
      final service = build();
      await service.init();
      expect(service.isPro.value, isTrue);

      store.activeProductIds = [];
      await service.refreshEntitlement();
      expect(service.isPro.value, isFalse);
      expect(cached, isFalse);
    });
  });

  group('buying', () {
    test('a completed purchase unlocks Pro and is finished with the store', () async {
      final service = build();
      await service.init();
      final outcome = await service.buy(service.annual!);
      expect(outcome, PurchaseOutcome.purchased);
      expect(service.isPro.value, isTrue);
      expect(cached, isTrue);
      expect(store.completed, [_annualId]);
    });

    for (final (status, expected) in [
      (PurchaseStatus.canceled, PurchaseOutcome.canceled),
      (PurchaseStatus.error, PurchaseOutcome.failed),
      (PurchaseStatus.pending, PurchaseOutcome.pending),
    ]) {
      test('a purchase that ends as ${status.name} does not unlock Pro', () async {
        store.buyResult = status;
        final service = build();
        await service.init();
        expect(await service.buy(service.monthly!), expected);
        expect(service.isPro.value, isFalse);
        expect(cached, isFalse);
        expect(store.completed, isEmpty);
      });
    }

    test('a second purchase can start after one is canceled', () async {
      final service = build();
      await service.init();
      store.buyResult = PurchaseStatus.canceled;
      expect(await service.buy(service.annual!), PurchaseOutcome.canceled);
      store.buyResult = PurchaseStatus.purchased;
      expect(await service.buy(service.annual!), PurchaseOutcome.purchased);
    });
  });

  group('restore purchases', () {
    test('syncs with the App Store, then reports what it found', () async {
      final service = build();
      await service.init();
      expect(await service.restore(), isFalse);

      store.activeProductIds = [_annualId];
      expect(await service.restore(), isTrue);
      expect(appStoreSyncs, 2);
    });

    test('still checks when the App Store sign-in is dismissed', () async {
      store.activeProductIds = [_annualId];
      final service = build(sync: () async => throw StateError('dismissed'));
      await service.init();
      expect(await service.restore(), isTrue);
    });
  });

  group('products', () {
    test('both plans load', () async {
      final service = build();
      await service.init();
      expect(service.status.value, StoreStatus.ready);
      expect(service.annual!.id, _annualId);
      expect(service.monthly!.id, _monthlyId);
    });

    test('one plan is enough to sell', () async {
      store.products = [_product(_annualId, 89.99)];
      final service = build();
      await service.init();
      expect(service.status.value, StoreStatus.ready);
      expect(service.monthly, isNull);
    });

    test('no plans means the store is unavailable', () async {
      store.products = [];
      final service = build();
      await service.init();
      expect(service.status.value, StoreStatus.unavailable);
    });

    test('a device that cannot make payments is unavailable', () async {
      store.available = false;
      final service = build();
      await service.init();
      expect(service.status.value, StoreStatus.unavailable);
    });
  });

  group('annualSavingsPercent', () {
    test('compares a year against twelve monthly payments', () {
      expect(
        PurchaseService.annualSavingsPercent(annualPrice: 89.99, monthlyPrice: 9.99),
        25,
      );
    });

    test('is null when yearly is not cheaper or a price is missing', () {
      expect(
        PurchaseService.annualSavingsPercent(annualPrice: 120, monthlyPrice: 10),
        isNull,
      );
      expect(
        PurchaseService.annualSavingsPercent(annualPrice: 0, monthlyPrice: 9.99),
        isNull,
      );
    });
  });
}
