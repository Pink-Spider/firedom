import 'package:flutter/material.dart';

/// S1. 온보딩 — 입력 (placeholder)
class OnboardingScreen extends StatelessWidget {
  static const path = '/onboarding';

  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('S1 온보딩 (준비 중)')),
    );
  }
}
