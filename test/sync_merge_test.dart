import 'package:flutter_test/flutter_test.dart';
import 'package:milemaid/core/services/trip_sync_service.dart';

/// Stand-in for a vehicle, place or purpose: an id plus whether it is still
/// an untouched starter item.
class _Item {
  const _Item(this.id, {this.starter = false});

  final String id;
  final bool starter;
}

MergePlan<_Item> _plan(List<_Item> local, List<_Item> cloud) => planMerge<_Item>(
      local: local,
      cloud: cloud,
      idOf: (i) => i.id,
      isUntouchedDefault: (i) => i.starter,
    );

List<String> _ids(List<_Item> items) => items.map((i) => i.id).toList();

void main() {
  group('planMerge', () {
    test('adds cloud items this phone does not have', () {
      final plan = _plan(
        const [_Item('a')],
        const [_Item('a'), _Item('b')],
      );
      expect(_ids(plan.toAdd), ['b']);
      expect(plan.toDrop, isEmpty);
    });

    test('a new phone drops its starter items when the account has its own', () {
      final plan = _plan(
        const [_Item('seed', starter: true)],
        const [_Item('truck')],
      );
      expect(_ids(plan.toAdd), ['truck']);
      expect(_ids(plan.toDrop), ['seed']);
    });

    test('a first sign-in to an empty account keeps the starter items', () {
      final plan = _plan(const [_Item('seed', starter: true)], const []);
      expect(plan.toAdd, isEmpty);
      expect(plan.toDrop, isEmpty);
    });

    test('never drops something the user made', () {
      final plan = _plan(
        const [_Item('mine'), _Item('seed', starter: true)],
        const [_Item('truck')],
      );
      expect(_ids(plan.toDrop), ['seed']);
    });

    test('keeps a starter item the account already holds', () {
      final plan = _plan(
        const [_Item('seed', starter: true)],
        const [_Item('seed', starter: true)],
      );
      expect(plan.toAdd, isEmpty);
      expect(plan.toDrop, isEmpty);
    });

    test('without a starter check nothing is ever dropped', () {
      final plan = planMerge<_Item>(
        local: const [_Item('seed', starter: true)],
        cloud: const [_Item('other')],
        idOf: (i) => i.id,
      );
      expect(_ids(plan.toAdd), ['other']);
      expect(plan.toDrop, isEmpty);
    });
  });
}
