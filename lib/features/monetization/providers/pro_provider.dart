import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:milemaid/core/services/purchase_service.dart';

/// True when reports and cloud sync are unlocked. Rebuilds listeners the
/// moment a purchase, restore or expiry changes the answer.
final proProvider = Provider<bool>((ref) {
  final isPro = PurchaseService.instance.isPro;
  void changed() => ref.invalidateSelf();
  isPro.addListener(changed);
  ref.onDispose(() => isPro.removeListener(changed));
  return PurchaseService.proUnlocked;
});
