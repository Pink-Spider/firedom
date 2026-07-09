import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/engine.dart';

typedef MonteCarloRunner = Future<MonteCarloResult> Function(
    MonteCarloRequest request);

/// 몬테카를로 실행기 — isolate에서 실행해 UI 블로킹 금지 (PRD S4).
/// 테스트에서는 동기 실행으로 override한다.
final monteCarloRunnerProvider = Provider<MonteCarloRunner>(
  (ref) => (request) => compute(runMonteCarlo, request),
);
