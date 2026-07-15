import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/backup_service.dart';
import '../../data/db/providers.dart';
import '../../data/entitlements.dart';
import '../../data/notifications/reminder_scheduler.dart';
import '../../data/reminders.dart';
import '../../data/repositories/settings_store.dart';
import '../../app/theme.dart';
import '../lock/biometric.dart';
import '../paywall/paywall_sheet.dart';
import 'subscription_screen.dart';

/// QA 릴리스 빌드 플래그 — `--dart-define=FIREDOM_QA=true`로 활성화.
/// 결제 연동 전 실기기에서 유료 게이트를 테스트하기 위한 것. 기본 false.
const _qaBuild = bool.fromEnvironment('FIREDOM_QA');

/// S10. 설정 (PRD, v0.9 — 백업/복원 제외)
///
/// 월간 기록 리마인더(로컬 알림만, 미기록 월에만 발송), 금액 가림 기본값,
/// 생체인증 앱 잠금, 구독, 개인정보 처리방침.
class SettingsScreen extends ConsumerStatefulWidget {
  static const path = '/settings';

  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _loading = true;
  ReminderSettings _reminder = const ReminderSettings(enabled: false);
  bool _biometricLock = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final store = ref.read(settingsStoreProvider);
    final reminder = await loadReminderSettings(store);
    final biometric =
        await store.get<bool>(SettingKeys.biometricLock) ?? false;
    if (!mounted) return;
    setState(() {
      _reminder = reminder;
      _biometricLock = biometric;
      _loading = false;
    });
  }

  Future<void> _saveReminder(ReminderSettings settings) async {
    final store = ref.read(settingsStoreProvider);
    await store.set(SettingKeys.reminderEnabled, settings.enabled);
    await store.set(SettingKeys.reminderDay, settings.dayOfMonth);
    await store.set(SettingKeys.reminderHour, settings.hour);
    await store.set(SettingKeys.reminderMinute, settings.minute);
    setState(() => _reminder = settings);
    await rescheduleReminders(
      db: ref.read(databaseProvider),
      scheduler: ref.read(reminderSchedulerProvider),
    );
  }

  Future<void> _toggleReminder(bool enabled) async {
    if (enabled) {
      final granted =
          await ref.read(reminderSchedulerProvider).ensurePermissions();
      if (!granted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('알림 권한이 필요해요 — 설정에서 허용해주세요')),
          );
        }
        return;
      }
    }
    await _saveReminder(ReminderSettings(
      enabled: enabled,
      dayOfMonth: _reminder.dayOfMonth,
      hour: _reminder.hour,
      minute: _reminder.minute,
    ));
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminder.hour, minute: _reminder.minute),
    );
    if (picked == null) return;
    await _saveReminder(ReminderSettings(
      enabled: _reminder.enabled,
      dayOfMonth: _reminder.dayOfMonth,
      hour: picked.hour,
      minute: picked.minute,
    ));
  }

  Future<void> _toggleBiometric(bool enabled) async {
    final authenticator = ref.read(biometricAuthenticatorProvider);
    if (enabled) {
      if (!await authenticator.isSupported) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이 기기는 생체인증을 지원하지 않아요')),
          );
        }
        return;
      }
      final ok = await authenticator.authenticate('앱 잠금을 설정합니다');
      if (!ok) return;
    }
    await ref
        .read(settingsStoreProvider)
        .set(SettingKeys.biometricLock, enabled);
    setState(() => _biometricLock = enabled);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final masked = ref.watch(maskAmountsProvider).value ?? false;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('설정')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: SafeArea(
        child: ListView(
          children: [
            _SectionHeader('기록 리마인더'),
            SwitchListTile(
              key: const ValueKey('reminder-switch'),
              title: const Text('월간 기록 알림'),
              subtitle: const Text('기록하지 않은 달에만 알려드려요 · 로컬 알림'),
              value: _reminder.enabled,
              onChanged: _toggleReminder,
            ),
            if (_reminder.enabled) ...[
              ListTile(
                title: const Text('알림 날짜'),
                trailing: DropdownButton<int>(
                  key: const ValueKey('reminder-day-dropdown'),
                  value: _reminder.dayOfMonth,
                  items: [
                    const DropdownMenuItem(value: 0, child: Text('매월 말일')),
                    for (var day = 1; day <= 28; day++)
                      DropdownMenuItem(value: day, child: Text('매월 $day일')),
                  ],
                  onChanged: (day) {
                    if (day == null) return;
                    _saveReminder(ReminderSettings(
                      enabled: _reminder.enabled,
                      dayOfMonth: day,
                      hour: _reminder.hour,
                      minute: _reminder.minute,
                    ));
                  },
                ),
              ),
              ListTile(
                title: const Text('알림 시간'),
                trailing: Text(
                  '${_reminder.hour.toString().padLeft(2, '0')}:'
                  '${_reminder.minute.toString().padLeft(2, '0')}',
                  style: theme.textTheme.titleMedium,
                ),
                onTap: _pickTime,
              ),
            ],
            const Divider(),
            _SectionHeader('표시 · 보안'),
            SwitchListTile(
              key: const ValueKey('mask-switch'),
              title: const Text('금액 가림(●●●) 기본값'),
              subtitle: const Text('홈에서 눈 아이콘으로도 바꿀 수 있어요'),
              value: masked,
              onChanged: (value) => ref
                  .read(settingsStoreProvider)
                  .set(SettingKeys.maskAmounts, value),
            ),
            SwitchListTile(
              key: const ValueKey('biometric-switch'),
              title: const Text('생체인증 앱 잠금'),
              subtitle: const Text('앱을 열 때 Face ID/지문 인증'),
              value: _biometricLock,
              onChanged: _toggleBiometric,
            ),
            ListTile(
              title: const Text('화면 테마'),
              trailing: DropdownButton<ThemeMode>(
                key: const ValueKey('theme-mode-dropdown'),
                value: ref.watch(themeModeProvider).value ?? ThemeMode.system,
                items: const [
                  DropdownMenuItem(
                      value: ThemeMode.system, child: Text('시스템')),
                  DropdownMenuItem(
                      value: ThemeMode.light, child: Text('라이트')),
                  DropdownMenuItem(value: ThemeMode.dark, child: Text('다크')),
                ],
                onChanged: (mode) {
                  if (mode == null) return;
                  ref
                      .read(settingsStoreProvider)
                      .set(SettingKeys.themeMode, themeModeName(mode));
                },
              ),
            ),
            const Divider(),
            _SectionHeader('구독'),
            Builder(builder: (context) {
              final isPremium = ref.watch(isPremiumProvider).value ?? false;
              return ListTile(
                title: const Text('파이어덤 프리미엄'),
                subtitle: Text(isPremium
                    ? '이용 중 🎉 — 플랜·해지는 구독 관리에서'
                    : '몬테카를로 상세 분포 · 포트폴리오 비중 편집'),
                trailing: const Icon(Icons.chevron_right),
                // S10-2: 구독자는 관리 화면, 미구독자는 페이월
                onTap: () {
                  if (isPremium) {
                    Navigator.of(context, rootNavigator: true).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SubscriptionScreen(),
                      ),
                    );
                  } else {
                    showPaywallSheet(context);
                  }
                },
              );
            }),
            // 디버그 빌드, 또는 --dart-define=FIREDOM_QA=true로 빌드한
            // QA용 릴리스에서 유료 게이트를 결제 없이 켜본다 (프로덕션엔 없음)
            if (kDebugMode || _qaBuild)
              SwitchListTile(
                key: const ValueKey('debug-premium-switch'),
                title: const Text('프리미엄 시뮬레이션 (QA)'),
                subtitle: const Text('결제 없이 유료 게이트 테스트 — QA 빌드 전용'),
                value: ref.watch(isPremiumProvider).value ?? false,
                onChanged: (value) => ref
                    .read(entitlementServiceProvider)
                    .setDebugPremium(value),
              ),
            const Divider(),
            _SectionHeader('데이터 · 정보'),
            ListTile(
              key: const ValueKey('backup-export-tile'),
              title: const Text('백업 파일 내보내기'),
              subtitle: const Text(
                  '암호화(AES-256) 파일 — iCloud/Drive에 보관하세요 · 서버 없음'),
              trailing: const Icon(Icons.upload_outlined),
              onTap: _exportBackup,
            ),
            ListTile(
              key: const ValueKey('backup-import-tile'),
              title: const Text('백업 가져오기'),
              subtitle: const Text('현재 데이터를 백업 내용으로 전체 교체해요'),
              trailing: const Icon(Icons.download_outlined),
              onTap: _importBackup,
            ),
            ListTile(
              title: const Text('개인정보 처리방침'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showPrivacyDialog(context),
            ),
            const AboutListTile(
              applicationName: '파이어덤 Firedom',
              applicationVersion: '0.1.0',
              aboutBoxChildren: [
                Text('본 앱의 시뮬레이션은 정보 제공 목적이며 투자 자문이 아닙니다.'),
              ],
              child: Text('앱 정보'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── 백업 / 복원 (B4) ─────────────────────────────────────────

  Future<String?> _askPassphrase({required bool creating}) {
    final controller = TextEditingController();
    final confirmController = TextEditingController();
    String? error;
    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(creating ? '백업 암호 만들기' : '백업 암호 입력'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const ValueKey('passphrase-field'),
                controller: controller,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: '패스프레이즈 (8자 이상)',
                  errorText: error,
                ),
              ),
              if (creating) ...[
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('passphrase-confirm-field'),
                  controller: confirmController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: '한 번 더 입력'),
                ),
                const SizedBox(height: 8),
                Text(
                  '암호를 잊으면 복구할 수 없어요 — 안전한 곳에 보관하세요',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                final passphrase = controller.text;
                if (passphrase.length < 8) {
                  setDialogState(() => error = '8자 이상 입력해주세요');
                  return;
                }
                if (creating && passphrase != confirmController.text) {
                  setDialogState(() => error = '암호가 서로 달라요');
                  return;
                }
                Navigator.pop(context, passphrase);
              },
              child: const Text('확인'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _exportBackup() async {
    final passphrase = await _askPassphrase(creating: true);
    if (passphrase == null) return;
    try {
      final bytes = await BackupService(ref.read(databaseProvider))
          .export(passphrase: passphrase);
      final now = DateTime.now();
      final name = 'firedom-backup-${now.year}'
          '${now.month.toString().padLeft(2, '0')}'
          '${now.day.toString().padLeft(2, '0')}.fdbk';
      final file = File('${Directory.systemTemp.path}/$name');
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } on BackupException catch (error) {
      _showSnack(error.message);
    } catch (_) {
      _showSnack('백업 파일을 만들지 못했어요');
    }
  }

  Future<void> _importBackup() async {
    final XFile? picked;
    try {
      picked = await openFile();
    } catch (_) {
      _showSnack('파일을 열지 못했어요');
      return;
    }
    if (picked == null) return;
    final bytes = await picked.readAsBytes();

    final passphrase = await _askPassphrase(creating: false);
    if (passphrase == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('전체 교체 확인'),
        content: const Text(
            '현재 기기의 모든 기록·계획·설정이 백업 내용으로 교체돼요. 계속할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('교체하기'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await BackupService(ref.read(databaseProvider))
          .import(bytes: bytes, passphrase: passphrase);
      _showSnack('복원 완료 — 데이터가 교체됐어요');
      await _load(); // 설정 항목(리마인더 등) 다시 읽기
      await rescheduleReminders(
        db: ref.read(databaseProvider),
        scheduler: ref.read(reminderSchedulerProvider),
      );
    } on BackupException catch (error) {
      _showSnack(error.message);
    } catch (_) {
      _showSnack('복원에 실패했어요 — 파일과 암호를 확인해주세요');
    }
  }

  void _showPrivacyDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('개인정보 처리방침'),
        content: const SingleChildScrollView(
          child: Text(
            '모든 재무 데이터(자산·기록)는 회원가입·계좌 연동 없이 이 기기에만 '
            '저장되며, 어떤 경우에도 서버로 전송되지 않습니다. 앱을 삭제하면 '
            '데이터도 함께 삭제됩니다.\n\n'
            '알림은 기기 로컬 알림만 사용합니다 (푸시 서버 없음).\n\n'
            '구독을 이용하는 경우 결제·구독 상태 확인은 스토어(Apple/Google)를 '
            '통해 처리되며, 이때도 자산·기록 등 재무 데이터는 전송되지 않습니다.\n\n'
            '새 버전 안내를 위해 스토어의 공개 버전 정보만 조회하며, 이때도 '
            '개인·재무 데이터는 전송되지 않습니다.\n\n'
            '본 앱의 시뮬레이션 결과는 정보 제공 목적이며 투자 자문이 아닙니다.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: theme.textTheme.labelLarge!.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
