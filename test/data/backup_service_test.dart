import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:firedom/data/backup_service.dart';
import 'package:firedom/data/db/database.dart';
import 'package:firedom/data/repositories/plan_repository.dart';
import 'package:firedom/data/repositories/settings_store.dart';
import 'package:firedom/data/repositories/snapshot_repository.dart';
import 'package:firedom/engine/engine.dart';
import 'package:flutter_test/flutter_test.dart';

const _g1 = PlanInput(
  age0: 35,
  currentAssets: 100000000,
  monthlySaving: 2000000,
  realReturnBp: 400,
  monthlySpendRetire: 3000000,
);

// 테스트에서는 PBKDF2 반복을 축소 (기본 600k는 실기기 기준)
BackupService service(AppDatabase db) =>
    BackupService(db, pbkdf2Iterations: 1000);

Future<AppDatabase> seededDb() async {
  final db = AppDatabase(NativeDatabase.memory());
  await PlanRepository(db)
      .createPlan(input: _g1, birthYm: 199107, startedYm: 202607);
  final repo = SnapshotRepository(db);
  final accounts = await repo.ensureDefaultAccounts();
  await repo.saveSnapshot(
    ym: 202607,
    amountsByAccountId: {accounts.first.id: 150000000},
    income: 5000000,
    expense: 3000000,
  );
  // 소급 수정으로 soft delete 행도 만들어 둔다 (백업은 전체 상태 보존)
  await repo.saveSnapshot(
    ym: 202607,
    amountsByAccountId: {accounts.first.id: 160000000},
    income: 5000000,
    expense: 3000000,
  );
  await SettingsStore(db).set(SettingKeys.maskAmounts, true);
  return db;
}

void main() {
  test('라운드트립: 내보내기 → 새 DB로 복원 → 데이터·설정 일치', () async {
    final source = await seededDb();
    addTearDown(source.close);

    final bytes = await service(source).export(passphrase: 'correct horse');

    final target = AppDatabase(NativeDatabase.memory());
    addTearDown(target.close);
    // 복원 전 다른 데이터가 있어도 전체 치환된다 (merge 아님)
    await PlanRepository(target).createPlan(
      input: _g1.copyWith(monthlySaving: 9999999),
      birthYm: 198001,
      startedYm: 202501,
    );

    await service(target).import(bytes: bytes, passphrase: 'correct horse');

    final plan = await PlanRepository(target).getActivePlan();
    expect(plan!.monthlySaving, 2000000);
    expect(plan.birthYm, 199107);
    final plans = await target.select(target.plans).get();
    expect(plans.length, 1); // 기존 계획은 치환으로 사라짐

    final summaries = await SnapshotRepository(target).getSummaries();
    expect(summaries.single.netWorth, 160000000);
    expect(summaries.single.snapshot.income, 5000000);

    // soft delete된 항목 행도 그대로 (전체 상태 보존)
    final items = await target.select(target.snapshotItems).get();
    expect(items.where((i) => i.deletedAt != null), isNotEmpty);

    expect(
        await SettingsStore(target).get<bool>(SettingKeys.maskAmounts), isTrue);
  });

  test('잘못된 패스프레이즈 → BackupException', () async {
    final source = await seededDb();
    addTearDown(source.close);
    final bytes = await service(source).export(passphrase: 'correct horse');

    final target = AppDatabase(NativeDatabase.memory());
    addTearDown(target.close);
    await expectLater(
      service(target).import(bytes: bytes, passphrase: 'wrong pass!!'),
      throwsA(isA<BackupException>().having(
          (e) => e.message, 'message', contains('패스프레이즈'))),
    );
  });

  test('더 새 스키마 버전의 백업 → 거부 (앱 업데이트 안내)', () async {
    final payload = jsonEncode({
      'format': 'firedom-backup',
      'schema_version': 99,
      'exported_at': 0,
      'data': <String, dynamic>{},
    });
    final bytes = await BackupService.encryptPayload(
      payload,
      passphrase: 'correct horse',
      iterations: 1000,
    );

    final target = AppDatabase(NativeDatabase.memory());
    addTearDown(target.close);
    await expectLater(
      service(target).import(bytes: bytes, passphrase: 'correct horse'),
      throwsA(isA<BackupException>()
          .having((e) => e.message, 'message', contains('업데이트'))),
    );
  });

  test('손상된 파일 / 다른 파일 → 친절한 오류', () async {
    final target = AppDatabase(NativeDatabase.memory());
    addTearDown(target.close);

    await expectLater(
      service(target).import(
        bytes: Uint8List.fromList(List.filled(10, 0)),
        passphrase: 'correct horse',
      ),
      throwsA(isA<BackupException>()),
    );
    await expectLater(
      service(target).import(
        bytes: Uint8List.fromList(List.filled(200, 7)),
        passphrase: 'correct horse',
      ),
      throwsA(isA<BackupException>()),
    );
  });

  test('암호화 파일에 평문 페이로드가 노출되지 않는다', () async {
    final source = await seededDb();
    addTearDown(source.close);
    final bytes = await service(source).export(passphrase: 'correct horse');
    final asString = String.fromCharCodes(bytes);
    expect(asString.contains('firedom-backup'), isFalse);
    expect(asString.contains('150000000'), isFalse);
  });
}
