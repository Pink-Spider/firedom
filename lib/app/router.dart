import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/active_plan_store.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_result_screen.dart';
import '../features/onboarding/onboarding_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // 시작 위치는 앱 기동 시 1회 결정: 활성 계획이 없으면 온보딩부터 (S0 역할)
  final hasPlan = ref.watch(activePlanStoreProvider).hasPlan;

  return GoRouter(
    initialLocation: hasPlan ? HomeScreen.path : OnboardingScreen.path,
    routes: [
      GoRoute(
        path: HomeScreen.path,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: OnboardingScreen.path,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: OnboardingResultScreen.path,
        builder: (context, state) => const OnboardingResultScreen(),
      ),
    ],
  );
});
