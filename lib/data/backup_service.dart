import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import 'db/database.dart';

/// 백업 오류 종류 — UI는 [BackupException.code]로 번역 문구를 고른다
enum BackupError { unreadable, notFiredomBackup, newerVersion, corrupted, wrongPassphrase }

class BackupException implements Exception {
  final BackupError code;

  /// 로그·테스트용 한국어 설명 (화면 표시는 code → l10n)
  final String message;

  const BackupException(this.code, this.message);

  @override
  String toString() => message;
}

/// 백업/복원 (엔진명세 B4).
///
/// - 포맷: JSON 전체 덤프(7개 테이블, soft delete 포함) →
///   PBKDF2(HMAC-SHA256, 기본 600k iter)로 유도한 키로 AES-256-GCM 암호화
/// - 파일 레이아웃: magic(4) | ver(1) | iterations(4, BE) | salt(16) |
///   nonce(12) | mac(16) | ciphertext — salt·nonce는 평문 헤더 (B4)
/// - 복원은 전체 치환(merge 아님) — 동기화가 아니라 기기 이전 용도
class BackupService {
  static const _magic = [0x46, 0x44, 0x42, 0x4B]; // 'FDBK'
  static const _fileVersion = 1;
  static const _saltLength = 16;
  static const _nonceLength = 12;
  static const _macLength = 16;

  final AppDatabase _db;

  /// PBKDF2 반복 횟수 — 기본 600k (B4), 테스트에서는 축소
  final int pbkdf2Iterations;

  BackupService(this._db, {this.pbkdf2Iterations = 600000});

  // ── 내보내기 ────────────────────────────────────────────────

  Future<Uint8List> export({required String passphrase}) async {
    final payload = jsonEncode({
      'format': 'firedom-backup',
      'schema_version': _db.schemaVersion,
      'exported_at': DateTime.now().millisecondsSinceEpoch,
      'data': await _dumpAll(),
    });
    return encryptPayload(
      payload,
      passphrase: passphrase,
      iterations: pbkdf2Iterations,
    );
  }

  Future<Map<String, dynamic>> _dumpAll() async {
    return {
      'plans': [
        for (final row in await _db.select(_db.plans).get()) row.toJson(),
      ],
      'accounts': [
        for (final row in await _db.select(_db.accounts).get()) row.toJson(),
      ],
      'snapshots': [
        for (final row in await _db.select(_db.snapshots).get()) row.toJson(),
      ],
      'snapshot_items': [
        for (final row in await _db.select(_db.snapshotItems).get())
          row.toJson(),
      ],
      'scenarios': [
        for (final row in await _db.select(_db.scenarios).get()) row.toJson(),
      ],
      'milestones': [
        for (final row in await _db.select(_db.milestones).get())
          row.toJson(),
      ],
      'settings': [
        for (final row in await _db.select(_db.settings).get()) row.toJson(),
      ],
    };
  }

  // ── 가져오기 (전체 치환) ─────────────────────────────────────

  Future<void> import({
    required Uint8List bytes,
    required String passphrase,
  }) async {
    final payload = await decryptPayload(bytes, passphrase: passphrase);
    final Map<String, dynamic> map;
    try {
      map = jsonDecode(payload) as Map<String, dynamic>;
    } catch (_) {
      throw const BackupException(BackupError.unreadable, '백업 파일을 읽을 수 없어요');
    }
    if (map['format'] != 'firedom-backup') {
      throw const BackupException(BackupError.notFiredomBackup, '파이어덤 백업 파일이 아니에요');
    }
    final version = map['schema_version'] as int? ?? 0;
    if (version > _db.schemaVersion) {
      // 더 새 스키마의 백업 — 거부 (B4)
      throw const BackupException(BackupError.newerVersion, '이 백업은 더 새 버전에서 만들어졌어요 — 앱을 업데이트해주세요');
    }
    // version < schemaVersion이면 여기서 마이그레이션 체인을 태운다 (B5).
    // 현재 스키마 v1뿐이므로 체인 없음.

    final data = map['data'] as Map<String, dynamic>;
    List<Map<String, dynamic>> rows(String key) => [
          for (final row in data[key] as List? ?? const [])
            (row as Map).cast<String, dynamic>(),
        ];

    await _db.transaction(() async {
      // FK 순서: 자식 먼저 삭제
      await _db.delete(_db.snapshotItems).go();
      await _db.delete(_db.milestones).go();
      await _db.delete(_db.snapshots).go();
      await _db.delete(_db.accounts).go();
      await _db.delete(_db.scenarios).go();
      await _db.delete(_db.plans).go();
      await _db.delete(_db.settings).go();

      for (final row in rows('plans')) {
        await _db.into(_db.plans).insert(Plan.fromJson(row));
      }
      for (final row in rows('accounts')) {
        await _db.into(_db.accounts).insert(Account.fromJson(row));
      }
      for (final row in rows('snapshots')) {
        await _db.into(_db.snapshots).insert(Snapshot.fromJson(row));
      }
      for (final row in rows('snapshot_items')) {
        await _db.into(_db.snapshotItems).insert(SnapshotItem.fromJson(row));
      }
      for (final row in rows('scenarios')) {
        await _db.into(_db.scenarios).insert(Scenario.fromJson(row));
      }
      for (final row in rows('milestones')) {
        await _db.into(_db.milestones).insert(Milestone.fromJson(row));
      }
      for (final row in rows('settings')) {
        await _db.into(_db.settings).insert(Setting.fromJson(row));
      }
    });
  }

  // ── 암호화 코어 (순수 — 단위 테스트 대상) ────────────────────

  static Future<Uint8List> encryptPayload(
    String payload, {
    required String passphrase,
    required int iterations,
  }) async {
    final random = Random.secure();
    final salt = Uint8List.fromList(
        List.generate(_saltLength, (_) => random.nextInt(256)));
    final key = await _deriveKey(passphrase, salt, iterations);
    final box = await AesGcm.with256bits()
        .encrypt(utf8.encode(payload), secretKey: key);

    final builder = BytesBuilder()
      ..add(_magic)
      ..addByte(_fileVersion)
      ..add((ByteData(4)..setUint32(0, iterations)).buffer.asUint8List())
      ..add(salt)
      ..add(box.nonce)
      ..add(box.mac.bytes)
      ..add(box.cipherText);
    return builder.toBytes();
  }

  static Future<String> decryptPayload(
    Uint8List bytes, {
    required String passphrase,
  }) async {
    const headerLength = 4 + 1 + 4 + _saltLength + _nonceLength + _macLength;
    if (bytes.length < headerLength) {
      throw const BackupException(BackupError.corrupted, '백업 파일이 손상됐어요');
    }
    for (var i = 0; i < _magic.length; i++) {
      if (bytes[i] != _magic[i]) {
        throw const BackupException(BackupError.notFiredomBackup, '파이어덤 백업 파일이 아니에요');
      }
    }
    var offset = 4 + 1; // magic + file version
    final iterations =
        ByteData.sublistView(bytes, offset, offset + 4).getUint32(0);
    offset += 4;
    final salt = bytes.sublist(offset, offset + _saltLength);
    offset += _saltLength;
    final nonce = bytes.sublist(offset, offset + _nonceLength);
    offset += _nonceLength;
    final mac = bytes.sublist(offset, offset + _macLength);
    offset += _macLength;
    final cipherText = bytes.sublist(offset);

    final key = await _deriveKey(passphrase, salt, iterations);
    try {
      final clear = await AesGcm.with256bits().decrypt(
        SecretBox(cipherText, nonce: nonce, mac: Mac(mac)),
        secretKey: key,
      );
      return utf8.decode(clear);
    } on SecretBoxAuthenticationError {
      throw const BackupException(BackupError.wrongPassphrase, '패스프레이즈가 올바르지 않아요');
    }
  }

  static Future<SecretKey> _deriveKey(
      String passphrase, List<int> salt, int iterations) {
    final pbkdf2 = Pbkdf2(
      macAlgorithm: Hmac.sha256(),
      iterations: iterations,
      bits: 256,
    );
    return pbkdf2.deriveKeyFromPassword(password: passphrase, nonce: salt);
  }
}
