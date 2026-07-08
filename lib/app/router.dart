import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';

final router = GoRouter(
  initialLocation: OnboardingScreen.path,
  routes: [
    GoRoute(
      path: HomeScreen.path,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: OnboardingScreen.path,
      builder: (context, state) => const OnboardingScreen(),
    ),
  ],
);
