import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'db/providers.dart';
import 'repositories/settings_store.dart';

/// RevenueCat API 키 — 빌드 시 주입 (--dart-define=REVENUECAT_IOS_KEY=..).
/// 비어 있으면 스텁 모드: 구매/복원은 실패를 반환하고, 게이트는 settings
/// 캐시로만 동작한다 (QA 토글 포함). 키가 있으면 실제 스토어 결제가 붙는다.
const _rcKeyIos = String.fromEnvironment('REVENUECAT_IOS_KEY');
const _rcKeyAndroid = String.fromEnvironment('REVENUECAT_ANDROID_KEY');

/// RevenueCat 대시보드의 entitlement 식별자 (동일하게 설정해야 함)
const _premiumEntitlement = 'premium';

/// RevenueCat은 프로세스 싱글턴이라 구성 여부는 전역으로 둔다.
bool _rcConfigured = false;

/// 프리미엄 권한 (S9). 실제 결제는 스토어 IAP + RevenueCat.
///
/// UI/게이트는 항상 settings 캐시(`premiumEntitlement`)를 본다.
/// RevenueCat이 CustomerInfo를 주면 그 값을 캐시에 반영해 오프라인에서도
/// 유지되게 한다 (스토어 상태가 진실, 캐시는 사본).
class EntitlementService {
  final SettingsStore _store;

  EntitlementService(this._store);

  bool get isConfigured => _rcConfigured;

  /// 앱 시작 시 1회. API 키가 있을 때만 RevenueCat을 구성하고,
  /// CustomerInfo 변경을 캐시에 동기화하는 리스너를 건다.
  Future<void> configure() async {
    if (_rcConfigured) return;
    final key =
        defaultTargetPlatform == TargetPlatform.iOS ? _rcKeyIos : _rcKeyAndroid;
    if (key.isEmpty) return; // 스텁 모드
    try {
      await Purchases.configure(PurchasesConfiguration(key));
      _rcConfigured = true;
      Purchases.addCustomerInfoUpdateListener(_syncFromCustomerInfo);
      _syncFromCustomerInfo(await Purchases.getCustomerInfo());
    } catch (_) {
      _rcConfigured = false; // 구성 실패 → 스텁으로 폴백 (기동은 막지 않음)
    }
  }

  /// entitlement 활성 여부를 로컬 캐시에 반영 (재무 데이터는 전송하지 않음)
  void _syncFromCustomerInfo(CustomerInfo info) {
    final active = info.entitlements.active.containsKey(_premiumEntitlement);
    _store.set(SettingKeys.premiumEntitlement, active);
  }

  Stream<bool> watchPremium() =>
      _store.watch<bool>(SettingKeys.premiumEntitlement).map((v) => v ?? false);

  Future<bool> isPremium() async =>
      await _store.get<bool>(SettingKeys.premiumEntitlement) ?? false;

  /// 현재 오퍼링의 구매 가능한 패키지(연/월). 미구성 시 빈 목록.
  Future<List<Package>> availablePackages() async {
    if (!_rcConfigured) return const [];
    try {
      final offerings = await Purchases.getOfferings();
      return offerings.current?.availablePackages ?? const [];
    } catch (_) {
      return const [];
    }
  }

  /// 선택한 패키지 구매 → 스토어 네이티브 결제 시트. 성공 시 캐시 갱신·true.
  /// 사용자 취소·실패는 false (UI에서 안내).
  Future<bool> purchasePackage(Package package) async {
    if (!_rcConfigured) return false;
    try {
      final result =
          await Purchases.purchase(PurchaseParams.package(package));
      final active = result.customerInfo.entitlements.active
          .containsKey(_premiumEntitlement);
      await _store.set(SettingKeys.premiumEntitlement, active);
      return active;
    } on PlatformException {
      return false; // 취소 포함 — 게이트 변화 없음
    }
  }

  /// 스텁 호환 경로 — 미구성 시 항상 false (연동 전 호출부 유지)
  Future<bool> purchase() async => false;

  /// 구매 복원 (기기 이전) → 스토어 계정 기준. 미구성 시 false.
  Future<bool> restore() async {
    if (!_rcConfigured) return false;
    try {
      final info = await Purchases.restorePurchases();
      final active = info.entitlements.active.containsKey(_premiumEntitlement);
      await _store.set(SettingKeys.premiumEntitlement, active);
      return active;
    } on PlatformException {
      return false;
    }
  }

  /// QA 전용: 결제 없이 유료 게이트 켜기 (프로덕션 미노출)
  Future<void> setDebugPremium(bool value) =>
      _store.set(SettingKeys.premiumEntitlement, value);
}

final entitlementServiceProvider = Provider<EntitlementService>(
  (ref) => EntitlementService(ref.watch(settingsStoreProvider)),
);

final isPremiumProvider = StreamProvider<bool>(
  (ref) => ref.watch(entitlementServiceProvider).watchPremium(),
);
