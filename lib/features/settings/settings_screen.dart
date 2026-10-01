import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/locale.dart';
import '../../core/currency.dart';
import '../../data/backup_service.dart';
import '../../data/db/providers.dart';
import '../../data/entitlements.dart';
import '../../data/notifications/reminder_scheduler.dart';
import '../../data/reminders.dart';
import '../../data/repositories/settings_store.dart';
import '../../app/theme.dart';
import '../../l10n/l10n.dart';
import '../lock/biometric.dart';
import '../paywall/paywall_sheet.dart';
import 'subscription_screen.dart';

/// QA 릴리스 빌드 플래그 — `--dart-define=FIREDOM_QA=true`로 활성화.
/// 결제 연동 전 실기기에서 유료 게이트를 테스트하기 위한 것. 기본 false.
const _qaBuild = bool.fromEnvironment('FIREDOM_QA');

/// 언어 드롭다운의 '시스템' 항목 값 (설정에는 null로 저장)
const _systemLocaleValue = 'system';

/// 백업 오류 코드 → 현재 언어 문구
String backupErrorMessage(AppLocalizations l10n, BackupError code) =>
    switch (code) {
      BackupError.unreadable => l10n.settingsBackupErrorUnreadable,
      BackupError.notFiredomBackup => l10n.settingsBackupErrorNotFiredom,
      BackupError.newerVersion => l10n.settingsBackupErrorNewerVersion,
      BackupError.corrupted => l10n.settingsBackupErrorCorrupted,
      BackupError.wrongPassphrase => l10n.settingsBackupErrorWrongPassphrase,
    };

/// 통화 → 설정 화면 표시 이름
String currencyLabel(AppLocalizations l10n, Currency currency) =>
    switch (currency) {
      Currency.krw => l10n.currencyKrw,
      Currency.usd => l10n.currencyUsd,
      Currency.jpy => l10n.currencyJpy,
    };

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

  /// 앱 정보 타일용 "1.0.0 (10)". 플랫폼 채널 실패(테스트 등) 시 빈 문자열
  String _version = '';
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
    var version = '';
    try {
      final info = await PackageInfo.fromPlatform();
      version = '${info.version} (${info.buildNumber})';
    } catch (_) {
      // 플랫폼 채널이 없는 환경 — 버전 미표시
    }
    if (!mounted) return;
    setState(() {
      _reminder = reminder;
      _biometricLock = biometric;
      _version = version;
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
          _showSnack(context.l10n.settingsReminderPermissionNeeded);
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
          _showSnack(context.l10n.settingsBiometricUnsupported);
        }
        return;
      }
      if (!mounted) return;
      final ok = await authenticator
          .authenticate(context.l10n.settingsBiometricSetupReason);
      if (!ok) return;
    }
    await ref
        .read(settingsStoreProvider)
        .set(SettingKeys.biometricLock, enabled);
    setState(() => _biometricLock = enabled);
  }

  Future<void> _changeLocale(String? value) async {
    if (value == null) return;
    await ref.read(settingsStoreProvider).set(
          SettingKeys.locale,
          value == _systemLocaleValue ? null : value,
        );
  }

  /// 통화 변경 — 저장된 금액은 환산하지 않고 단위만 바뀌므로 확인을 받는다
  Future<void> _changeCurrency(Currency? currency) async {
    if (currency == null) return;
    final current = ref.read(currencyProvider).value ?? Currency.fallback;
    if (currency == current) return;
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsCurrencyChangeTitle),
        content: Text(
          l10n.settingsCurrencyChangeBody(currencyLabel(l10n, currency)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            key: const ValueKey('currency-change-confirm'),
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.settingsCurrencyChangeConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref
        .read(settingsStoreProvider)
        .set(SettingKeys.currency, currency.code);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final masked = ref.watch(maskAmountsProvider).value ?? false;

    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.settingsTitle)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final localeCode =
        ref.watch(localeProvider).value?.languageCode ?? _systemLocaleValue;
    final currency = ref.watch(currencyProvider).value ?? Currency.fallback;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: SafeArea(
        child: ListView(
          children: [
            _SectionHeader(l10n.settingsSectionReminder),
            SwitchListTile(
              key: const ValueKey('reminder-switch'),
              title: Text(l10n.settingsReminderSwitch),
              subtitle: Text(l10n.settingsReminderSwitchSubtitle),
              value: _reminder.enabled,
              onChanged: _toggleReminder,
            ),
            if (_reminder.enabled) ...[
              ListTile(
                title: Text(l10n.settingsReminderDay),
                trailing: DropdownButton<int>(
                  key: const ValueKey('reminder-day-dropdown'),
                  value: _reminder.dayOfMonth,
                  items: [
                    DropdownMenuItem(
                        value: 0, child: Text(l10n.settingsReminderLastDay)),
                    for (var day = 1; day <= 28; day++)
                      DropdownMenuItem(
                        value: day,
                        child: Text(l10n.settingsReminderDayOfMonth(day)),
                      ),
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
                title: Text(l10n.settingsReminderTime),
                trailing: Text(
                  '${_reminder.hour.toString().padLeft(2, '0')}:'
                  '${_reminder.minute.toString().padLeft(2, '0')}',
                  style: theme.textTheme.titleMedium,
                ),
                onTap: _pickTime,
              ),
            ],
            const Divider(),
            _SectionHeader(l10n.settingsSectionDisplaySecurity),
            SwitchListTile(
              key: const ValueKey('mask-switch'),
              title: Text(l10n.settingsMaskSwitch),
              subtitle: Text(l10n.settingsMaskSwitchSubtitle),
              value: masked,
              onChanged: (value) => ref
                  .read(settingsStoreProvider)
                  .set(SettingKeys.maskAmounts, value),
            ),
            SwitchListTile(
              key: const ValueKey('biometric-switch'),
              title: Text(l10n.settingsBiometricSwitch),
              subtitle: Text(l10n.settingsBiometricSwitchSubtitle),
              value: _biometricLock,
              onChanged: _toggleBiometric,
            ),
            ListTile(
              title: Text(l10n.settingsTheme),
              trailing: DropdownButton<ThemeMode>(
                key: const ValueKey('theme-mode-dropdown'),
                value: ref.watch(themeModeProvider).value ?? ThemeMode.system,
                items: [
                  DropdownMenuItem(
                      value: ThemeMode.system,
                      child: Text(l10n.languageSystem)),
                  DropdownMenuItem(
                      value: ThemeMode.light,
                      child: Text(l10n.settingsThemeLight)),
                  DropdownMenuItem(
                      value: ThemeMode.dark,
                      child: Text(l10n.settingsThemeDark)),
                ],
                onChanged: (mode) {
                  if (mode == null) return;
                  ref
                      .read(settingsStoreProvider)
                      .set(SettingKeys.themeMode, themeModeName(mode));
                },
              ),
            ),
            ListTile(
              title: Text(l10n.settingsLanguage),
              trailing: DropdownButton<String>(
                key: const ValueKey('language-dropdown'),
                value: localeCode,
                items: [
                  for (final locale in selectableLocales)
                    DropdownMenuItem(
                      value: locale?.languageCode ?? _systemLocaleValue,
                      child: Text(_languageLabel(l10n, locale?.languageCode)),
                    ),
                ],
                onChanged: _changeLocale,
              ),
            ),
            ListTile(
              title: Text(l10n.settingsCurrency),
              trailing: DropdownButton<Currency>(
                key: const ValueKey('currency-dropdown'),
                value: currency,
                items: [
                  for (final c in Currency.values)
                    DropdownMenuItem(
                      value: c,
                      child: Text(currencyLabel(l10n, c)),
                    ),
                ],
                onChanged: _changeCurrency,
              ),
            ),
            const Divider(),
            _SectionHeader(l10n.settingsSectionSubscription),
            Builder(builder: (context) {
              final isPremium = ref.watch(isPremiumProvider).value ?? false;
              return ListTile(
                title: Text(l10n.settingsPremiumTitle),
                subtitle: Text(isPremium
                    ? l10n.settingsPremiumActive
                    : l10n.settingsPremiumInactive),
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
            // 구독 문의·프로모셔널 엔타이틀먼트 부여용 식별자 (익명, 설치 단위).
            // RevenueCat 미구성(스텁) 빌드에서는 표시하지 않는다.
            Builder(builder: (context) {
              final customerId = ref.watch(customerIdProvider).value;
              if (customerId == null) return const SizedBox.shrink();
              return ListTile(
                key: const ValueKey('customer-id-tile'),
                title: Text(l10n.settingsCustomerId),
                subtitle: Text(l10n.settingsCustomerIdSubtitle(customerId)),
                isThreeLine: true,
                trailing: const Icon(Icons.copy_outlined, size: 18),
                onTap: () async {
                  await Clipboard.setData(ClipboardData(text: customerId));
                  if (!context.mounted) return;
                  _showSnack(l10n.settingsCustomerIdCopied);
                },
              );
            }),
            // 디버그 빌드, 또는 --dart-define=FIREDOM_QA=true로 빌드한
            // QA용 릴리스에서 유료 게이트를 결제 없이 켜본다 (프로덕션엔 없음)
            if (kDebugMode || _qaBuild)
              SwitchListTile(
                key: const ValueKey('debug-premium-switch'),
                title: Text(l10n.settingsQaPremium),
                subtitle: Text(l10n.settingsQaPremiumSubtitle),
                value: ref.watch(isPremiumProvider).value ?? false,
                onChanged: (value) => ref
                    .read(entitlementServiceProvider)
                    .setDebugPremium(value),
              ),
            const Divider(),
            _SectionHeader(l10n.settingsSectionData),
            ListTile(
              key: const ValueKey('backup-export-tile'),
              title: Text(l10n.settingsBackupExport),
              subtitle: Text(l10n.settingsBackupExportSubtitle),
              trailing: const Icon(Icons.upload_outlined),
              onTap: _exportBackup,
            ),
            ListTile(
              key: const ValueKey('backup-import-tile'),
              title: Text(l10n.settingsBackupImport),
              subtitle: Text(l10n.settingsBackupImportSubtitle),
              trailing: const Icon(Icons.download_outlined),
              onTap: _importBackup,
            ),
            ListTile(
              key: const ValueKey('settings-terms-tile'),
              title: Text(l10n.settingsTerms),
              subtitle: Text(l10n.settingsTermsSubtitle),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => launchUrl(
                Uri.parse(paywallTermsUrl),
                mode: LaunchMode.externalApplication,
              ),
            ),
            ListTile(
              title: Text(l10n.settingsPrivacy),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showPrivacyDialog(context),
            ),
            AboutListTile(
              applicationName: l10n.settingsAppName,
              applicationVersion: _version,
              aboutBoxChildren: [
                Text(l10n.settingsAboutDisclaimer),
              ],
              child: Text(l10n.settingsAbout),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _languageLabel(AppLocalizations l10n, String? code) =>
      switch (code) {
        'ko' => l10n.languageKo,
        'en' => l10n.languageEn,
        'ja' => l10n.languageJa,
        _ => l10n.languageSystem,
      };

  // ── 백업 / 복원 (B4) ─────────────────────────────────────────

  Future<String?> _askPassphrase({required bool creating}) {
    final controller = TextEditingController();
    final confirmController = TextEditingController();
    final l10n = context.l10n;
    String? error;
    return showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(creating
              ? l10n.settingsPassphraseCreateTitle
              : l10n.settingsPassphraseEnterTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const ValueKey('passphrase-field'),
                controller: controller,
                obscureText: true,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.settingsPassphraseLabel,
                  errorText: error,
                ),
              ),
              if (creating) ...[
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('passphrase-confirm-field'),
                  controller: confirmController,
                  obscureText: true,
                  decoration: InputDecoration(
                      labelText: l10n.settingsPassphraseConfirmLabel),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.settingsPassphraseWarning,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                final passphrase = controller.text;
                if (passphrase.length < 8) {
                  setDialogState(
                      () => error = l10n.settingsPassphraseTooShort);
                  return;
                }
                if (creating && passphrase != confirmController.text) {
                  setDialogState(
                      () => error = l10n.settingsPassphraseMismatch);
                  return;
                }
                Navigator.pop(context, passphrase);
              },
              child: Text(l10n.commonConfirm),
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
    if (passphrase == null || !mounted) return;
    final l10n = context.l10n;
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
      _showSnack(backupErrorMessage(l10n, error.code));
    } catch (_) {
      _showSnack(l10n.settingsBackupExportFailed);
    }
  }

  Future<void> _importBackup() async {
    final l10n = context.l10n;
    final XFile? picked;
    try {
      picked = await openFile();
    } catch (_) {
      _showSnack(l10n.settingsBackupOpenFailed);
      return;
    }
    if (picked == null) return;
    final bytes = await picked.readAsBytes();

    final passphrase = await _askPassphrase(creating: false);
    if (passphrase == null || !mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsRestoreConfirmTitle),
        content: Text(l10n.settingsRestoreConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.settingsRestoreConfirmButton),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await BackupService(ref.read(databaseProvider))
          .import(bytes: bytes, passphrase: passphrase);
      _showSnack(l10n.settingsRestoreDone);
      await _load(); // 설정 항목(리마인더 등) 다시 읽기
      await rescheduleReminders(
        db: ref.read(databaseProvider),
        scheduler: ref.read(reminderSchedulerProvider),
      );
    } on BackupException catch (error) {
      _showSnack(backupErrorMessage(l10n, error.code));
    } catch (_) {
      _showSnack(l10n.settingsRestoreFailed);
    }
  }

  void _showPrivacyDialog(BuildContext context) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.settingsPrivacy),
        content: SingleChildScrollView(
          child: Text(l10n.settingsPrivacyBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.commonConfirm),
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
