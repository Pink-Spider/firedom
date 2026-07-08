import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/money_format.dart';
import 'onboarding_draft.dart';
import 'onboarding_result_screen.dart';

enum _MoneyUnit { manwon, won }

class _StepConfig {
  final String title;
  final String subtitle;
  final bool isMoney;

  const _StepConfig({
    required this.title,
    required this.subtitle,
    this.isMoney = true,
  });
}

const _steps = [
  _StepConfig(
    title: '나이가 어떻게 되세요?',
    subtitle: '만 나이 기준이에요',
    isMoney: false,
  ),
  _StepConfig(
    title: '세후 월소득은 얼마인가요?',
    subtitle: '대략이면 충분해요 — 실수령액 기준',
  ),
  _StepConfig(
    title: '한 달에 얼마나 쓰세요?',
    subtitle: '대략이면 충분해요 — 고정비 포함 월 지출',
  ),
  _StepConfig(
    title: '지금 순자산은 얼마쯤인가요?',
    subtitle: '대략이면 충분해요 — 예금+투자−대출',
  ),
];

/// S1. 온보딩 — 입력 (PRD)
///
/// 4문항 1화면씩. 계정·권한 요청 없음. 이탈 시 값 보존, 재실행 시 재개.
class OnboardingScreen extends ConsumerStatefulWidget {
  static const path = '/onboarding';

  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = TextEditingController();
  _MoneyUnit _unit = _MoneyUnit.manwon;
  String? _error;

  @override
  void initState() {
    super.initState();
    // 재개 시 진행 중이던 문항의 저장값을 복원
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStepValue(ref.read(onboardingDraftProvider).step);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _loadStepValue(int step) {
    final draft = ref.read(onboardingDraftProvider);
    final value = draft.valueAt(step);
    setState(() {
      _error = null;
      if (value == null) {
        _controller.text = '';
        _unit = _MoneyUnit.manwon;
      } else if (!_steps[step].isMoney) {
        _controller.text = '$value';
      } else if (value > 0 && value % 10000 == 0) {
        _unit = _MoneyUnit.manwon;
        _controller.text = formatWithComma(value ~/ 10000);
      } else {
        _unit = _MoneyUnit.won;
        _controller.text = formatWithComma(value);
      }
    });
  }

  int? _parsedValue(int step) {
    final raw = parseAmount(_controller.text);
    if (raw == null) return null;
    if (!_steps[step].isMoney) return raw;
    return _unit == _MoneyUnit.manwon ? raw * 10000 : raw;
  }

  String? _validate(int step, int value) {
    if (step == 0 && (value < 1 || value > 85)) {
      return '1~85 사이 나이를 입력해주세요';
    }
    if (value > 1000000000000000) {
      return '금액이 너무 커요';
    }
    return null;
  }

  void _goNext(int step) {
    final value = _parsedValue(step);
    if (value == null) return;
    final error = _validate(step, value);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    final notifier = ref.read(onboardingDraftProvider.notifier);
    notifier.setValueAt(step, value);
    if (step < _steps.length - 1) {
      notifier.setStep(step + 1);
      _loadStepValue(step + 1);
    } else {
      context.push(OnboardingResultScreen.path);
    }
  }

  void _goBack(int step) {
    // 입력 중이던 값도 보존
    final value = _parsedValue(step);
    final notifier = ref.read(onboardingDraftProvider.notifier);
    if (value != null && _validate(step, value) == null) {
      notifier.setValueAt(step, value);
    }
    notifier.setStep(step - 1);
    _loadStepValue(step - 1);
  }

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(onboardingDraftProvider).step;
    final config = _steps[step];
    final theme = Theme.of(context);
    final isLast = step == _steps.length - 1;

    return Scaffold(
      appBar: AppBar(
        leading: step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => _goBack(step),
              )
            : null,
        title: Text('${step + 1} / ${_steps.length}'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (step + 1) / _steps.length,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text(config.title, style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                config.subtitle,
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                key: ValueKey('onboarding-input-$step'),
                controller: _controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [ThousandsSeparatorInputFormatter()],
                style: theme.textTheme.headlineSmall,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  suffixText: config.isMoney
                      ? (_unit == _MoneyUnit.manwon ? '만원' : '원')
                      : '세',
                  errorText: _error,
                  helperText: config.isMoney ? _helperText(step) : null,
                ),
                onChanged: (_) => setState(() => _error = null),
                onSubmitted: (_) => _goNext(step),
              ),
              if (config.isMoney) ...[
                const SizedBox(height: 12),
                SegmentedButton<_MoneyUnit>(
                  segments: const [
                    ButtonSegment(
                        value: _MoneyUnit.manwon, label: Text('만원 단위')),
                    ButtonSegment(value: _MoneyUnit.won, label: Text('원 단위')),
                  ],
                  selected: {_unit},
                  onSelectionChanged: (selection) {
                    setState(() => _unit = selection.first);
                  },
                ),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => _goNext(step),
                  child: Text(isLast ? '결과 보기' : '다음'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _helperText(int step) {
    final value = _parsedValue(step);
    if (value == null || value == 0) return null;
    return '= ${formatKoreanMoney(value)}원';
  }
}
