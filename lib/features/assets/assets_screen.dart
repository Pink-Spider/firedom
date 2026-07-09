import 'package:flutter/material.dart';

/// S6. 자산 뷰 — 다중 관점 (placeholder)
///
/// TODO(assets): 자산배분 도넛 + 목표 배분 편차, 현금흐름 뷰 (P0),
/// 연금·세제 뷰 (P1, 유료)
class AssetsScreen extends StatelessWidget {
  static const path = '/assets';

  const AssetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('자산')),
      body: const Center(child: Text('자산배분·현금흐름 뷰 준비 중')),
    );
  }
}
