import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
import 'biometric.dart';

/// 기동 시점의 생체인증 잠금 설정 — main()/테스트에서 override.
final biometricLockAtLaunchProvider = Provider<bool>(
  (ref) => throw UnimplementedError(
      'biometricLockAtLaunchProvider는 main()에서 override'),
);

class AppLockNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(biometricLockAtLaunchProvider);

  /// [reason]은 OS 생체인증 프롬프트에 표시되는 사유 (현재 언어 문구)
  Future<void> unlock(String reason) async {
    final ok =
        await ref.read(biometricAuthenticatorProvider).authenticate(reason);
    if (ok) state = false;
  }
}

/// true = 잠김 (생체인증 통과 전)
final appLockedProvider =
    NotifierProvider<AppLockNotifier, bool>(AppLockNotifier.new);

/// S10 생체인증 앱 잠금 화면 — 해제 전까지 앱 내용을 가린다
class AppLockScreen extends ConsumerWidget {
  const AppLockScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline,
                size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(l10n.lockTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              l10n.lockBody,
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref
                  .read(appLockedProvider.notifier)
                  .unlock(l10n.lockUnlockReason),
              icon: const Icon(Icons.fingerprint),
              label: Text(l10n.lockUnlock),
            ),
          ],
        ),
      ),
    );
  }
}
