import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'db/providers.dart';
import 'repositories/settings_store.dart';

/// 프리미엄 권한 (S9).
///
/// TODO(payments): RevenueCat + 스토어 IAP 연동.
/// - Purchases.configure(apiKey) 후 CustomerInfo의 entitlement를
///   settings 캐시(premiumEntitlement)에 반영하고 listener로 동기화한다.
/// - 연동 전까지 purchase/restore는 실패를 반환하고, 게이트는
///   settings 캐시로만 동작한다 (디버그 시뮬레이션 포함).
class EntitlementService {
  final SettingsStore _store;

  EntitlementService(this._store);

  Stream<bool> watchPremium() {
    return _store
        .watch<bool>(SettingKeys.premiumEntitlement)
        .map((value) => value ?? false);
  }

  Future<bool> isPremium() async {
    return await _store.get<bool>(SettingKeys.premiumEntitlement) ?? false;
  }

  /// 구독 구매. 스토어 연동 전에는 항상 false.
  Future<bool> purchase() async => false;

  /// 구매 복원. 스토어 연동 전에는 항상 false.
  Future<bool> restore() async => false;

  /// 디버그 전용: 유료 게이트 QA를 위한 프리미엄 시뮬레이션
  Future<void> setDebugPremium(bool value) {
    return _store.set(SettingKeys.premiumEntitlement, value);
  }
}

final entitlementServiceProvider = Provider<EntitlementService>(
  (ref) => EntitlementService(ref.watch(settingsStoreProvider)),
);

final isPremiumProvider = StreamProvider<bool>(
  (ref) => ref.watch(entitlementServiceProvider).watchPremium(),
);
