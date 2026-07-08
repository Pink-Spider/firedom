import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/prefs.dart';

/// S1 온보딩 입력 초안. 금액은 원 단위 정수.
class OnboardingDraft {
  final int? age;
  final int? monthlyIncome;
  final int? monthlyExpense;
  final int? currentAssets;

  /// 진행 중인 문항 (0~3)
  final int step;

  const OnboardingDraft({
    this.age,
    this.monthlyIncome,
    this.monthlyExpense,
    this.currentAssets,
    this.step = 0,
  });

  bool get isComplete =>
      age != null &&
      monthlyIncome != null &&
      monthlyExpense != null &&
      currentAssets != null;

  /// 월 저축액 = 세후 월소득 − 월 지출
  int get monthlySaving => (monthlyIncome ?? 0) - (monthlyExpense ?? 0);

  int? valueAt(int step) => switch (step) {
        0 => age,
        1 => monthlyIncome,
        2 => monthlyExpense,
        3 => currentAssets,
        _ => null,
      };
}

/// 초안을 SharedPreferences에 즉시 보존 — 이탈/재실행 시 재개 (PRD S1)
class OnboardingDraftNotifier extends Notifier<OnboardingDraft> {
  static const _kAge = 'onboarding.age';
  static const _kIncome = 'onboarding.monthly_income';
  static const _kExpense = 'onboarding.monthly_expense';
  static const _kAssets = 'onboarding.current_assets';
  static const _kStep = 'onboarding.step';

  @override
  OnboardingDraft build() {
    final prefs = ref.read(sharedPreferencesProvider);
    return OnboardingDraft(
      age: prefs.getInt(_kAge),
      monthlyIncome: prefs.getInt(_kIncome),
      monthlyExpense: prefs.getInt(_kExpense),
      currentAssets: prefs.getInt(_kAssets),
      step: prefs.getInt(_kStep) ?? 0,
    );
  }

  void setValueAt(int step, int value) {
    state = OnboardingDraft(
      age: step == 0 ? value : state.age,
      monthlyIncome: step == 1 ? value : state.monthlyIncome,
      monthlyExpense: step == 2 ? value : state.monthlyExpense,
      currentAssets: step == 3 ? value : state.currentAssets,
      step: state.step,
    );
    final prefs = ref.read(sharedPreferencesProvider);
    final key = switch (step) {
      0 => _kAge,
      1 => _kIncome,
      2 => _kExpense,
      _ => _kAssets,
    };
    prefs.setInt(key, value);
  }

  void setStep(int step) {
    state = OnboardingDraft(
      age: state.age,
      monthlyIncome: state.monthlyIncome,
      monthlyExpense: state.monthlyExpense,
      currentAssets: state.currentAssets,
      step: step,
    );
    ref.read(sharedPreferencesProvider).setInt(_kStep, step);
  }

  Future<void> clear() async {
    final prefs = ref.read(sharedPreferencesProvider);
    for (final key in [_kAge, _kIncome, _kExpense, _kAssets, _kStep]) {
      await prefs.remove(key);
    }
    state = const OnboardingDraft();
  }
}

final onboardingDraftProvider =
    NotifierProvider<OnboardingDraftNotifier, OnboardingDraft>(
  OnboardingDraftNotifier.new,
);
