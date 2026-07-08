import 'dart:math' as math;

/// bp(베이시스포인트) → 비율. 400bp = 0.04 (엔진명세 R6)
double bpToRate(int bp) => bp / 10000;

/// 명목수익률·인플레이션(bp) → 실질수익률(bp).
/// 피셔 방정식 r_real = (1+r_nom)/(1+π) − 1 (엔진명세 R4 — 근사식 금지)
int fisherRealBp({required int nominalBp, required int inflationBp}) {
  final real = (1 + bpToRate(nominalBp)) / (1 + bpToRate(inflationBp)) - 1;
  return (real * 10000).round();
}

/// 수익률 프리셋 — 실질 기준 (엔진명세 A6. 근거 출처는 출시 전 확정)
enum ReturnPreset {
  conservative(realReturnBp: 250, volatilityBp: 800),
  neutral(realReturnBp: 400, volatilityBp: 1200),
  aggressive(realReturnBp: 550, volatilityBp: 1700);

  final int realReturnBp;
  final int volatilityBp;

  const ReturnPreset({
    required this.realReturnBp,
    required this.volatilityBp,
  });
}

/// 국민연금 입력 (엔진명세 A1). 금액은 현재가치(실질) 원.
class NpsInput {
  /// 예상 월 수령액 (원, 현재가치)
  final int monthlyAmount;

  /// 수령 개시 나이 (만)
  final int startAge;

  const NpsInput({required this.monthlyAmount, this.startAge = 65});
}

/// 계획 입력 (엔진명세 A1).
///
/// 전역 규약: 금액은 정수 원(R1), 모든 금액·수익률은 실질 기준(R3),
/// 수익률은 bp 정수(R6).
class PlanInput {
  /// 현재 나이 (만)
  final int age0;

  /// 현재 순자산 (원)
  final int currentAssets;

  /// 월 저축액 (원, 실질). 음수 허용.
  final int monthlySaving;

  /// 연 실질수익률 (bp)
  final int realReturnBp;

  /// 은퇴 후 월 생활비 (원, 실질)
  final int monthlySpendRetire;

  /// 안전인출률 (bp)
  final int swrBp;

  /// 기대수명 (만 나이)
  final int lifeExpectancy;

  /// 국민연금 (선택). 입력 시 FIRE 판정이 모드 2(인출 판정)로 바뀐다 (A2).
  final NpsInput? nps;

  /// 연 변동성 (bp, 몬테카를로용)
  final int volatilityBp;

  const PlanInput({
    required this.age0,
    required this.currentAssets,
    required this.monthlySaving,
    required this.realReturnBp,
    required this.monthlySpendRetire,
    this.swrBp = 400,
    this.lifeExpectancy = 90,
    this.nps,
    this.volatilityBp = 1200, // ReturnPreset.neutral의 변동성
  }) : assert(
          lifeExpectancy > age0,
          '기대수명은 현재 나이보다 커야 한다 (엔진명세 A9)',
        );

  /// 월 실질수익률 — 기하 변환 (1+r)^(1/12) − 1 (R4, 산술 r/12 금지)
  double get monthlyRealReturn =>
      math.pow(1 + bpToRate(realReturnBp), 1 / 12).toDouble() - 1.0;

  /// 기대수명까지 월 수 (t=0 = 현재 월, R2)
  int get lifeMonths => (lifeExpectancy - age0) * 12;

  /// 연금 수령 개시 월 (t=0 기준). null = 연금 없음.
  int? get npsStartMonth =>
      nps == null ? null : (nps!.startAge - age0) * 12;

  /// What-if(A5)용: 해당 필드만 바꾼 사본. [clearNps]로 연금 제거.
  PlanInput copyWith({
    int? age0,
    int? currentAssets,
    int? monthlySaving,
    int? realReturnBp,
    int? monthlySpendRetire,
    int? swrBp,
    int? lifeExpectancy,
    NpsInput? nps,
    bool clearNps = false,
    int? volatilityBp,
  }) {
    return PlanInput(
      age0: age0 ?? this.age0,
      currentAssets: currentAssets ?? this.currentAssets,
      monthlySaving: monthlySaving ?? this.monthlySaving,
      realReturnBp: realReturnBp ?? this.realReturnBp,
      monthlySpendRetire: monthlySpendRetire ?? this.monthlySpendRetire,
      swrBp: swrBp ?? this.swrBp,
      lifeExpectancy: lifeExpectancy ?? this.lifeExpectancy,
      nps: clearNps ? null : (nps ?? this.nps),
      volatilityBp: volatilityBp ?? this.volatilityBp,
    );
  }
}
