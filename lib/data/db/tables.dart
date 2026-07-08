import 'package:drift/drift.dart';

/// 전역 규약 (엔진명세 B0):
/// - PK: UUID v4 TEXT (auto-increment 금지 — v1.x 동기화 대비)
/// - created_at/updated_at: unix epoch millis, soft delete: deleted_at
/// - 금액 INTEGER 원 / 비율 INTEGER bp / 연월 INTEGER yyyymm

mixin UuidPk on Table {
  TextColumn get id => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

mixin SyncColumns on Table {
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
}

/// 계획(목표+가정). 수정 = 새 리비전 append (B1)
class Plans extends Table with UuidPk, SyncColumns {
  /// 같은 계획의 리비전 묶음 ID (첫 리비전의 id)
  TextColumn get revisionGroup => text()();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();

  /// lean/fat/coast/barista/custom
  TextColumn get fireType => text().withDefault(const Constant('custom'))();

  /// 생년월 yyyymm — 나이 계산 원천
  IntColumn get birthYm => integer()();

  /// 계획 수립 시점 순자산 (궤도 기준점)
  IntColumn get currentAssets => integer()();
  IntColumn get monthlySaving => integer()();
  IntColumn get realReturnBp => integer()();
  IntColumn get volatilityBp => integer()();
  IntColumn get monthlySpendRetire => integer()();
  IntColumn get swrBp => integer().withDefault(const Constant(400))();
  IntColumn get lifeExpectancy => integer().withDefault(const Constant(90))();
  IntColumn get npsMonthly => integer().nullable()();
  IntColumn get npsStartAge => integer().nullable()();

  /// 궤도 t=0에 해당하는 연월
  IntColumn get startedYm => integer()();
}

/// 자산 항목 마스터 (S8 첫 셋업에서 생성)
class Accounts extends Table with UuidPk, SyncColumns {
  TextColumn get name => text()();

  /// equity/bond/cash/real_estate/pension/other
  TextColumn get assetClass => text()();

  /// normal/isa/pension_savings/irp/dc_db/other — v2 절세 인출 시뮬 기반
  TextColumn get accountType => text().withDefault(const Constant('normal'))();

  /// 1이면 부채 (금액 음수 강제)
  BoolColumn get isLiability => boolean().withDefault(const Constant(false))();

  /// FIRE 자산 포함 여부 (거주 부동산 제외 토글)
  BoolColumn get includeInFire => boolean().withDefault(const Constant(true))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
}

/// 월 1회 기록 헤더. 동일 ym에 deleted_at IS NULL 행은 1개 (부분 유니크 인덱스)
class Snapshots extends Table with UuidPk, SyncColumns {
  IntColumn get ym => integer()();

  /// 이번 달 세후 소득 (저축률용, 선택 입력)
  IntColumn get income => integer().nullable()();
  IntColumn get expense => integer().nullable()();
  TextColumn get note => text().nullable()();
}

/// 스냅샷의 항목별 금액 (부채는 음수)
class SnapshotItems extends Table with UuidPk, SyncColumns {
  TextColumn get snapshotId => text().references(Snapshots, #id)();
  TextColumn get accountId => text().references(Accounts, #id)();
  IntColumn get amount => integer()();
}

/// 시뮬 놀이터 저장 (S4). 무료 1개 제한은 앱 레이어에서
class Scenarios extends Table with UuidPk, SyncColumns {
  TextColumn get name => text()();

  /// PlanInput 직렬화
  TextColumn get paramsJson => text()();
}

/// 달성 기록 — 스냅샷 저장 시 엔진이 판정, "달성 순간"의 이벤트 로그
class Milestones extends Table with UuidPk, SyncColumns {
  /// net_worth_100m, fire_25pct, saving_rate_50_6mo …
  TextColumn get milestoneKey => text()();
  IntColumn get achievedYm => integer()();
  TextColumn get snapshotId => text().nullable().references(Snapshots, #id)();
}

/// k/v 단일 테이블 — 알림 설정, 금액 가림 기본, 구독 entitlement 캐시
class Settings extends Table {
  TextColumn get key => text()();

  /// JSON 인코딩 값
  TextColumn get value => text()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => {key};
}
