import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/assets/assets_screen.dart';
import '../features/home/home_screen.dart';
import '../features/simulation/simulation_screen.dart';
import '../features/snapshot/snapshot_flow_screen.dart';

/// 하단 탭 셸 (PRD 화면 맵): 홈 · 시뮬레이션 · 기록(+) · 자산
///
/// '기록'은 탭 전환이 아니라 기록 플로우를 push한다 (S5).
class AppShell extends StatelessWidget {
  final Widget child;

  const AppShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final selectedIndex = switch (location) {
      SimulationScreen.path => 1,
      AssetsScreen.path => 3,
      _ => 0,
    };

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: '홈',
          ),
          NavigationDestination(
            icon: Icon(Icons.query_stats),
            label: '시뮬레이션',
          ),
          NavigationDestination(
            icon: Icon(Icons.add_circle_outline),
            selectedIcon: Icon(Icons.add_circle),
            label: '기록',
          ),
          NavigationDestination(
            icon: Icon(Icons.pie_chart_outline),
            selectedIcon: Icon(Icons.pie_chart),
            label: '자산',
          ),
        ],
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go(HomeScreen.path);
            case 1:
              context.go(SimulationScreen.path);
            case 2:
              context.push(SnapshotFlowScreen.path);
            case 3:
              context.go(AssetsScreen.path);
          }
        },
      ),
    );
  }
}
