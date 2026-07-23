---
name: drift-migration
description: Drift(SQLite) 스키마 변경 절차. lib/data/db/의 테이블 추가, 컬럼 추가·변경, 인덱스 추가 등 스키마를 건드릴 때 반드시 사용. 동기화 대비 규약(UUID PK, SyncColumns, soft delete), schemaVersion 범프, onUpgrade 마이그레이션, build_runner 코드젠, 마이그레이션 테스트까지 한 절차로 안내한다.
---

# Drift 스키마 변경 절차

## 전역 규약 (엔진명세 B0 — 위반 금지)

- PK는 UUID v4 TEXT — `UuidPk` mixin 사용. auto-increment **금지** (v1.x 동기화 대비)
- 모든 도메인 테이블에 `SyncColumns` mixin — `createdAt`/`updatedAt`(unix epoch millis), `deletedAt`(soft delete)
- 삭제는 `deletedAt` UPDATE로 — 물리 DELETE **금지**. 조회는 `deleted_at IS NULL` 필터
- 금액 INTEGER 원 / 비율 INTEGER bp / 연월 INTEGER yyyymm — double **금지**
- 예외: `Settings` 테이블은 k/v 저장소라 위 규약 미적용. 새 테이블의 근거로 삼지 말 것

## 절차

1. **테이블/컬럼 정의** — `lib/data/db/tables.dart`
   - 새 테이블: `class Foo extends Table with UuidPk, SyncColumns { ... }`
   - FK는 `text().references(Other, #id)()` 패턴, boolean은 `withDefault` 필수
   - 컬럼 doc comment에 단위·허용값을 기존 스타일대로 남긴다 (예: `/// equity/bond/cash/...`)

2. **테이블 등록** — 새 테이블이면 `lib/data/db/database.dart`의 `@DriftDatabase(tables: [...])`에 추가

3. **schemaVersion +1** — `database.dart`의 `schemaVersion` getter

4. **onUpgrade 마이그레이션 추가** (B5: additive 우선)
   ```dart
   onUpgrade: (m, from, to) async {
     if (from < 2) {
       await m.createTable(foo);        // 새 테이블
       await m.addColumn(bar, bar.baz); // 새 컬럼 (nullable 또는 default 필수)
     }
   },
   ```
   - `from→to` 단계별 블록을 누적한다. 기존 블록은 절대 수정하지 않는다
   - 파괴적 변경(컬럼 삭제·타입 변경)은 지양. 불가피하면 `TableMigration` 사용 여부를 사용자와 논의

5. **인덱스** — 부분 인덱스(`WHERE deleted_at IS NULL`)는 Drift 테이블 API 미지원이므로 `customStatement` SQL로 작성. **onCreate와 onUpgrade 양쪽에** 추가해야 신규 설치와 업그레이드가 같은 스키마가 된다

6. **코드젠** — `fvm dart run build_runner build --delete-conflicting-outputs`
   - `database.g.dart`는 산출물이므로 직접 수정 금지

7. **마이그레이션 테스트** — `test/data/`에 이전 버전 fixture 기반 테스트 추가 (구버전 스키마로 만든 DB를 열어 onUpgrade가 데이터 보존하며 새 스키마로 전환되는지 검증)

8. **최종 검증** — `fvm flutter analyze && fvm flutter test`

## 자주 하는 실수

- schemaVersion만 올리고 onUpgrade를 비워둠 → 기존 사용자 업그레이드 시 테이블 없음 크래시
- 새 컬럼을 non-nullable + default 없음으로 추가 → 마이그레이션 실패
- 인덱스를 onCreate에만 추가 → 업그레이드 사용자만 인덱스 누락 (또는 그 반대)
- 금액 컬럼을 `real()`로 선언 → 정수 원 단위 규약 위반
