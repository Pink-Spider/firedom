import 'package:flutter/material.dart';

/// S5→S8. 월 스냅샷 기록 플로우 (placeholder — 다음 단계에서 구현)
class SnapshotFlowScreen extends StatelessWidget {
  static const path = '/snapshot';

  const SnapshotFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('이번 달 기록')),
      body: const Center(child: Text('기록 플로우 준비 중')),
    );
  }
}
