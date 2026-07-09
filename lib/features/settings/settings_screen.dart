import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/db/providers.dart';
import '../../data/entitlements.dart';
import '../../data/notifications/reminder_scheduler.dart';
import '../../data/reminders.dart';
import '../../data/repositories/settings_store.dart';
import '../lock/biometric.dart';
import '../paywall/paywall_sheet.dart';

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
            const Divider(),
            _SectionHeader('구독'),
            Builder(builder: (context) {
              final isPremium = ref.watch(isPremiumProvider).value ?? false;
              return ListTile(
                title: const Text('파이어덤 프리미엄'),
                subtitle: Text(isPremium
                    ? '이용 중 🎉'
                    : '몬테카를로 상세 · 시나리오 비교 · 연금 뷰'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showPaywallSheet(context),
              );
            }),
            if (kDebugMode)
              SwitchListTile(
                key: const ValueKey('debug-premium-switch'),
                title: const Text('프리미엄 시뮬레이션 (디버그)'),
                subtitle: const Text('개발 빌드 전용 — 유료 게이트 QA'),
                value: ref.watch(isPremiumProvider).value ?? false,
                onChanged: (value) => ref
                    .read(entitlementServiceProvider)
                    .setDebugPremium(value),
              ),
            const Divider(),
            _SectionHeader('데이터 · 정보'),
            const ListTile(
              title: Text('백업 / 복원'),
              subtitle: Text('암호화 백업 — 준비 중 (v1.0)'),
              enabled: false,
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

  void _showPrivacyDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('개인정보 처리방침'),
        content: const Text(
          '모든 재무 데이터는 회원가입·계좌 연동 없이 이 기기에만 저장됩니다. '
          '서버로 전송되지 않으며, 앱을 삭제하면 데이터도 함께 삭제됩니다.\n\n'
          '알림은 기기 로컬 알림만 사용합니다 (푸시 서버 없음).\n\n'
          '본 앱의 시뮬레이션 결과는 정보 제공 목적이며 투자 자문이 아닙니다.',
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
