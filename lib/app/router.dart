import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/ym.dart';
import '../data/db/providers.dart';
import '../features/assets/assets_screen.dart';
import '../features/goal/goal_settings_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_result_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/simulation/simulation_screen.dart';
import '../features/snapshot/snapshot_flow_screen.dart';
import '../features/snapshot/snapshot_result_screen.dart';
import 'shell.dart';

/// go_router 루트 네비게이터 키 — 인앱 업데이트 알림 등 라우터 밖에서
/// 다이얼로그를 띄울 때 참조한다.
final rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // 시작 위치는 앱 기동 시 1회 결정: 활성 계획이 없으면 온보딩부터 (S0 역할)
  final hasPlan = ref.watch(hasActivePlanAtLaunchProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: hasPlan ? HomeScreen.path : OnboardingScreen.path,
    routes: [
      // 하단 탭 셸: 홈 · 시뮬레이션 · 자산 (기록은 push)
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: HomeScreen.path,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: SimulationScreen.path,
            builder: (context, state) => const SimulationScreen(),
          ),
          GoRoute(
            path: AssetsScreen.path,
            builder: (context, state) => const AssetsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: OnboardingScreen.path,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: OnboardingResultScreen.path,
        builder: (context, state) => const OnboardingResultScreen(),
      ),
      GoRoute(
        path: GoalSettingsScreen.path,
        builder: (context, state) => const GoalSettingsScreen(),
      ),
      GoRoute(
        path: SettingsScreen.path,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: SnapshotFlowScreen.path,
        builder: (context, state) => SnapshotFlowScreen(
          initialYm: int.tryParse(state.uri.queryParameters['ym'] ?? ''),
        ),
      ),
      GoRoute(
        path: SnapshotResultScreen.path,
        builder: (context, state) => SnapshotResultScreen(
          ym: int.tryParse(state.uri.queryParameters['ym'] ?? '') ?? nowYm(),
        ),
      ),
    ],
  );
});
