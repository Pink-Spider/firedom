import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'biometric.dart';

/// 기동 시점의 생체인증 잠금 설정 — main()/테스트에서 override.
final biometricLockAtLaunchProvider = Provider<bool>(
  (ref) => throw UnimplementedError(
      'biometricLockAtLaunchProvider는 main()에서 override'),
);

class AppLockNotifier extends Notifier<bool> {
  @override
  bool build() => ref.watch(biometricLockAtLaunchProvider);

  Future<void> unlock() async {
    final ok = await ref
        .read(biometricAuthenticatorProvider)
        .authenticate('파이어덤 잠금을 해제합니다');
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
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_outline,
                size: 48, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text('파이어덤이 잠겨 있어요', style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '재무 데이터 보호를 위해 인증이 필요해요',
              style: theme.textTheme.bodyMedium!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.read(appLockedProvider.notifier).unlock(),
              icon: const Icon(Icons.fingerprint),
              label: const Text('잠금 해제'),
            ),
          ],
        ),
      ),
    );
  }
}
