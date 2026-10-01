// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get acBond => '채권';

  @override
  String get acCash => '현금/예금';

  @override
  String get acEquity => '주식';

  @override
  String get acOther => '기타';

  @override
  String get acPension => '연금';

  @override
  String get acRealEstate => '부동산';

  @override
  String ageLabel(int age) {
    return '$age세';
  }

  @override
  String get ageSuffix => '세';

  @override
  String get appTitle => '파이어덤';

  @override
  String get assetsAllocationEmpty => '자산을 기록하면 배분을 볼 수 있어요';

  @override
  String get assetsAllocationTab => '자산배분';

  @override
  String assetsAsOf(String ym) {
    return '$ym 기준';
  }

  @override
  String get assetsCashflowEmpty => '기록할 때 소득/지출을 함께 적으면 현금흐름을 볼 수 있어요';

  @override
  String get assetsCashflowTab => '현금흐름';

  @override
  String get assetsEditTarget => '목표 배분 수정';

  @override
  String get assetsIncome => '소득';

  @override
  String assetsSaving(String amount) {
    return '저축 $amount';
  }

  @override
  String assetsSavingRate(int percent) {
    return '저축률 $percent%';
  }

  @override
  String get assetsSavingRateNone => '저축률 —';

  @override
  String get assetsSetTarget => '목표 배분 설정';

  @override
  String assetsTargetDeviation(int target, String delta) {
    return '목표 $target% · $delta%p';
  }

  @override
  String get assetsTargetDialogTitle => '목표 배분 (%)';

  @override
  String assetsTargetMatch(int target) {
    return '목표 $target% · 일치';
  }

  @override
  String get assetsTitle => '자산';

  @override
  String cmpEarlier(String label, int years) {
    return '$label가 $years년 빨라요';
  }

  @override
  String get cmpReached => '이미 도달';

  @override
  String get cmpRowFireAge => 'FIRE 나이';

  @override
  String get cmpRowFireNumber => '필요 자산';

  @override
  String get cmpRowReturn => '기대수익률';

  @override
  String get cmpSameAge => 'FIRE 나이가 같아요';

  @override
  String get cmpTitle => '시나리오 비교';

  @override
  String get cmpTrajectory => '궤도';

  @override
  String get cmpUnreachable => '도달 어려움';

  @override
  String get commonCancel => '취소';

  @override
  String get commonClose => '닫기';

  @override
  String get commonConfirm => '확인';

  @override
  String get commonDelete => '삭제';

  @override
  String get commonMasked => '●●●';

  @override
  String get commonNext => '다음';

  @override
  String get commonSave => '저장';

  @override
  String get currencyJpy => '엔 (JPY)';

  @override
  String get currencyKrw => '원 (KRW)';

  @override
  String get currencyUsd => '미국 달러 (USD)';

  @override
  String devAhead(int months) {
    return '계획보다 $months개월 앞서는 중';
  }

  @override
  String devBehind(int months) {
    return '계획보다 $months개월 뒤 — 따라잡을 수 있어요';
  }

  @override
  String get devNeedsReview => '가정 점검 필요';

  @override
  String get devOnTrack => '계획대로 진행 중';

  @override
  String get devReached => '이미 목표 도달!';

  @override
  String get disclaimerShort => '정보 제공 목적이며 투자 자문이 아닙니다.';

  @override
  String get disclaimerSimulation => '본 시뮬레이션은 정보 제공 목적이며 투자 자문이 아닙니다.';

  @override
  String errorGeneric(String error) {
    return '오류가 발생했어요: $error';
  }

  @override
  String get goalAlreadyFire => '이미 FIRE 도달!';

  @override
  String goalBridgeAfter(int age, String amount, String pension) {
    return '수령 후($age세~): 월 $amount (생활비 − 연금 $pension)';
  }

  @override
  String goalBridgeBefore(int age, String amount) {
    return '수령 전(~$age세): 월 $amount (생활비 전액)';
  }

  @override
  String get goalCheckInputs => '입력값을 확인해주세요';

  @override
  String get goalExpectedReturn => '기대수익률 (실질)';

  @override
  String goalFireAge(int age) {
    return 'FIRE 나이 $age세';
  }

  @override
  String get goalFireType => 'FIRE 유형';

  @override
  String get goalFireTypeBarista => '바리스타';

  @override
  String get goalFireTypeCoast => '코스트';

  @override
  String get goalFireTypeCustom => '직접 설정';

  @override
  String get goalFireTypeFat => '팻';

  @override
  String get goalFireTypeLean => '린';

  @override
  String get goalInflation => '인플레이션';

  @override
  String get goalLifeExpectancy => '기대수명';

  @override
  String get goalMonthlySaving => '월 저축액';

  @override
  String get goalNoActivePlan => '활성 계획이 없어요';

  @override
  String get goalNominalReturn => '명목수익률';

  @override
  String get goalPensionAmount => '예상 월 수령액';

  @override
  String goalPensionEffect(int months) {
    return '연금 반영으로 은퇴가 $months개월 앞당겨져요';
  }

  @override
  String get goalPensionHint => '예상 수령액은 통합연금포털(fss.or.kr)에서 확인할 수 있어요';

  @override
  String get goalPensionStartAge => '수령 나이';

  @override
  String get goalPensionToggle => '국민연금 반영';

  @override
  String goalPreviewSummary(String period, String amount) {
    return '$period 후 · 목표 자산 $amount';
  }

  @override
  String get goalPreviewTitle => '이 가정이라면';

  @override
  String goalRealReturnFisher(String rate) {
    return '실질수익률 $rate% (피셔 방정식으로 계산)';
  }

  @override
  String get goalRetireSpend => '은퇴 후 월 생활비';

  @override
  String get goalReturnAggressive => '공격';

  @override
  String get goalReturnConservative => '보수';

  @override
  String get goalReturnCustom => '직접';

  @override
  String get goalReturnNeutral => '중립';

  @override
  String goalReturnSummary(String real, String vol) {
    return '실질 $real% · 변동성 $vol%';
  }

  @override
  String get goalSaveButton => '저장하기';

  @override
  String get goalSaveHint => '저장하면 새 리비전으로 기록되고, 홈 궤도 차트에 변경 시점이 표시돼요.';

  @override
  String get goalSavedSnack => '계획을 업데이트했어요 — 궤도에 반영됩니다';

  @override
  String get goalSwr => '안전인출률';

  @override
  String get goalTitle => '목표 설정';

  @override
  String get homeComeback => '다시 오셨네요 — 이번 달만 기록하면 돼요';

  @override
  String get homeCreatePlan => '60초 만에 계획 만들기';

  @override
  String homeFireProgress(String percent, String current, String target) {
    return 'FIRE 진행률 $percent% · $current / $target';
  }

  @override
  String get homeFirstRecordHint => '첫 기록을 남기면 궤도 위에 점이 찍혀요';

  @override
  String get homeGoalSettingsTooltip => '목표 설정';

  @override
  String get homeHideAmounts => '금액 가리기';

  @override
  String homeMonthShort(String month) {
    return '$month월';
  }

  @override
  String homeMoreMilestones(int count) {
    return '외 $count개 달성';
  }

  @override
  String get homeNoPlan => '아직 계획이 없어요';

  @override
  String get homePastRecords => '지난 기록';

  @override
  String get homeReached => '재정적 자유 목표에 도달했어요!';

  @override
  String get homeRecordButton => '기록하기';

  @override
  String homeRecordPrompt(String month) {
    return '$month월 자산을 기록해볼까요?';
  }

  @override
  String get homeRecordSubtitle => '한 달에 3분이면 충분해요';

  @override
  String get homeRecordedThisMonth => '이번 달 기록 완료 — 다음 기록은 다음 달에 만나요';

  @override
  String get homeSavingRate => '저축률';

  @override
  String get homeSavingRateHint => '기록할 때 소득/지출을 함께 적으면 저축률 추이를 볼 수 있어요';

  @override
  String get homeSavingRateThisMonth => '이번 달 저축률';

  @override
  String get homeSecondRecordHint => '2번째 기록부터 궤도 비교가 시작돼요';

  @override
  String get homeSettingsTooltip => '설정';

  @override
  String get homeShowAmounts => '금액 보이기';

  @override
  String get homeTapToEdit => '탭해서 수정';

  @override
  String get homeTrajectory => '궤도';

  @override
  String get homeUnreachable => '현재 가정으로는 도달이 어려워요';

  @override
  String homeUntilFireMonths(int months) {
    return '재정적 자유까지 $months개월';
  }

  @override
  String homeUntilFireYearsMonths(int years, int months) {
    return '재정적 자유까지 $years년 $months개월';
  }

  @override
  String get languageEn => 'English';

  @override
  String get languageJa => '日本語';

  @override
  String get languageKo => '한국어';

  @override
  String get languageSystem => '시스템';

  @override
  String get lockBody => '재무 데이터 보호를 위해 인증이 필요해요';

  @override
  String get lockTitle => '파이어덤이 잠겨 있어요';

  @override
  String get lockUnlock => '잠금 해제';

  @override
  String get lockUnlockReason => '파이어덤 잠금을 해제합니다';

  @override
  String get mcDepletionTitle => '자산 고갈 나이 분포';

  @override
  String get mcEndingAssetsTitle => '기대수명 시점 자산 분포 (오늘 돈 가치)';

  @override
  String mcHeadline(String pct) {
    return '성공 확률 $pct%';
  }

  @override
  String mcNoDepletion(int age) {
    return '기대수명($age세)까지 자산이 고갈된 시나리오가 없어요 👏';
  }

  @override
  String get mcP10 => '어려운 경우 (하위 10%)';

  @override
  String get mcP50 => '중간 (p50)';

  @override
  String get mcP90 => '잘 풀린 경우 (상위 10%)';

  @override
  String mcSummary(int runs, int successes, int age) {
    return '$runs가지 시장 시나리오 중 $successes번, 기대수명 $age세까지 자산이 유지됐어요';
  }

  @override
  String get mcTitle => '성공 확률 상세';

  @override
  String monthsLabel(int count) {
    return '$count개월';
  }

  @override
  String get msFallback => '마일스톤 달성! 🎉';

  @override
  String get msFire100 => 'FIRE 목표 도달! 🏆';

  @override
  String get msFire25 => 'FIRE 목표 25% 달성! 🔥';

  @override
  String get msFire50 => 'FIRE 목표 절반 달성! 🔥';

  @override
  String get msFire75 => 'FIRE 목표 75% 달성! 🔥';

  @override
  String msNetWorth(String amount) {
    return '순자산 $amount 돌파! 🎉';
  }

  @override
  String get msStreak12 => '1년 연속 기록 🏆';

  @override
  String get msStreak3 => '3개월 연속 기록 🔥';

  @override
  String get msStreak6 => '6개월 연속 기록 🔥🔥';

  @override
  String get needPlanFirst => '먼저 홈에서 계획을 만들어 주세요';

  @override
  String get onbAdjustExpense => '지출 조정하기';

  @override
  String get onbAlreadyFire => '이미 FIRE에 도달했어요';

  @override
  String get onbAssumptionMoneyBasis => '금액 기준';

  @override
  String get onbAssumptionMoneyBasisValue => '모든 금액은 오늘 돈 가치(실질)';

  @override
  String get onbAssumptionRealReturn => '연 실질수익률';

  @override
  String onbAssumptionRealReturnValue(String rate) {
    return '$rate% (중립 프리셋)';
  }

  @override
  String get onbAssumptionRetireSpendValue => '현재 월 지출과 동일';

  @override
  String get onbAssumptionSwr => '안전인출률 (4% 룰)';

  @override
  String get onbAssumptionsEditHint => '가정은 목표 설정 화면에서 언제든 바꿀 수 있어요.';

  @override
  String get onbAssumptionsTitle => '계산에 사용한 가정';

  @override
  String onbAxisHundredMillion(int n) {
    return '$n억';
  }

  @override
  String get onbCongrats => '축하해요!';

  @override
  String get onbCurrencyLabel => '통화';

  @override
  String get onbErrorAgeRange => '1~85 사이 나이를 입력해주세요';

  @override
  String get onbErrorTooLarge => '금액이 너무 커요';

  @override
  String onbFireNumberBasis(String spend, String swr) {
    return '월 지출 $spend × $swr% 룰 기준';
  }

  @override
  String get onbFireNumberTitle => '필요 자산 (FIRE Number)';

  @override
  String get onbHeadlineUnreachable => '100년 안에 도달이 어려워요';

  @override
  String get onbHeadlineUnreachableHint =>
      '아래 슬라이더로 저축을 늘리면 얼마나 달라지는지 볼 수 있어요.';

  @override
  String get onbHeadlineUnreachablePrefix => '지금 조건으로는';

  @override
  String onbHelperEquals(String amount) {
    return '= $amount';
  }

  @override
  String get onbNeedInputBack => '입력이 필요해요 — 돌아가기';

  @override
  String get onbNoSavingBody =>
      '월 지출이 소득과 같거나 더 커요. 입력한 지출을 조금만 낮추면 계획이 만들어져요.';

  @override
  String get onbNoSavingTitle => '현재 저축이 없어\nFIRE 나이를 계산할 수 없어요';

  @override
  String get onbSeeResult => '결과 보기';

  @override
  String get onbShowAssumptions => '가정 보기';

  @override
  String onbSliderPlus(String amount) {
    return '+$amount';
  }

  @override
  String get onbStartPlan => '이 계획 시작하기';

  @override
  String get onbStepAgeSubtitle => '만 나이 기준이에요';

  @override
  String get onbStepAgeTitle => '나이가 어떻게 되세요?';

  @override
  String get onbStepAssetsSubtitle => '대략이면 충분해요 — 예금+보유자산−대출';

  @override
  String get onbStepAssetsTitle => '지금 순자산은 얼마쯤인가요?';

  @override
  String get onbStepExpenseSubtitle => '대략이면 충분해요 — 고정비 포함 월 지출';

  @override
  String get onbStepExpenseTitle => '한 달에 얼마나 쓰세요?';

  @override
  String get onbStepIncomeSubtitle => '대략이면 충분해요 — 실수령액 기준';

  @override
  String get onbStepIncomeTitle => '세후 월소득은 얼마인가요?';

  @override
  String onbUnitSegment(String unit) {
    return '$unit 단위';
  }

  @override
  String onbWhatIfEffect(String amount, String age) {
    return '+$amount → $age';
  }

  @override
  String onbWhatIfEffectShortened(String amount, String age, String shortened) {
    return '+$amount → $age ($shortened 단축)';
  }

  @override
  String get onbWhatIfMoveSlider => '슬라이더를 움직여 보세요';

  @override
  String get onbWhatIfStillUnreachable => '아직 도달이 어려워요';

  @override
  String get onbWhatIfTitle => '매달 조금 더 저축한다면?';

  @override
  String onbYearsLater(int years) {
    return '약 $years년 후';
  }

  @override
  String onbYearsMonthsLater(int years, int months) {
    return '약 $years년 $months개월 후';
  }

  @override
  String get onbYourFireAge => '당신의 FIRE 나이';

  @override
  String get paywallAlreadyPremium => '이미 프리미엄을 이용 중이에요 🎉';

  @override
  String get paywallAutoRenewNote =>
      '무료 체험 종료 후 선택한 플랜으로 자동 갱신되며, 언제든 스토어 계정에서 해지할 수 있어요.';

  @override
  String get paywallBrowserFailed => '브라우저를 열 수 없어요';

  @override
  String get paywallFallbackPricing =>
      '연 39,000원 — 월 3,250원꼴 · 34% 할인\n월 4,900원 · 7일 무료 체험';

  @override
  String get paywallFeatureMonteCarlo => '몬테카를로 상세 분포 · 자산 고갈 나이 분포';

  @override
  String get paywallFeaturePortfolio => '포트폴리오 비중 자유 편집';

  @override
  String get paywallFeatureScenarios => '시나리오 무제한 저장 · 나란히 비교';

  @override
  String get paywallNothingToRestore => '복원할 구매 내역이 없어요 (연동 준비 중)';

  @override
  String get paywallPlanAnnual => '연간';

  @override
  String get paywallPlanLifetime => '평생';

  @override
  String get paywallPlanMonthly => '월간';

  @override
  String paywallPlanPrice(String plan, String price) {
    return '$plan · $price';
  }

  @override
  String get paywallPlanWeekly => '주간';

  @override
  String get paywallPrivacy => '개인정보 처리방침';

  @override
  String get paywallPurchaseFailed => '결제가 완료되지 않았어요';

  @override
  String get paywallRestore => '구매 복원';

  @override
  String get paywallRestored => '구매를 복원했어요';

  @override
  String get paywallStoreNotReady => '스토어 결제 연동 준비 중이에요 — 곧 열려요';

  @override
  String get paywallSubscribe => '구독 시작하기';

  @override
  String get paywallTeaserGeneric => '내 계획의 리스크까지 확인해보세요';

  @override
  String paywallTeaserWithRate(String rate) {
    return '회원님 계획의 성공 확률 $rate% — 상세 분포와 자산 고갈 리스크를 확인해보세요';
  }

  @override
  String get paywallTerms => '이용약관';

  @override
  String get paywallTitle => '파이어덤 프리미엄';

  @override
  String get pfAdd => '추가';

  @override
  String get pfAddAsset => '자산군 추가';

  @override
  String get pfApplyCta => '이 구성으로 시뮬레이션';

  @override
  String get pfAssetCommodities => '원자재';

  @override
  String pfAssetCustom(String label) {
    return '$label · 직접 입력';
  }

  @override
  String get pfAssetGlobalDmEm => '선진국·신흥국';

  @override
  String get pfAssetGold => '금';

  @override
  String get pfAssetKrEquity => '국내주식';

  @override
  String get pfAssetKrTreasury => '국고채';

  @override
  String get pfAssetKrwDeposit => '원화 예금';

  @override
  String pfAssetReference(String label) {
    return '$label · 참고치';
  }

  @override
  String get pfAssetReits => '리츠';

  @override
  String get pfAssetSilver => '은';

  @override
  String get pfAssetUsDow => '다우존스';

  @override
  String get pfAssetUsNasdaq100 => '나스닥100';

  @override
  String get pfAssetUsSp500 => 'S&P500';

  @override
  String get pfAssetUsTreasury => '미국채';

  @override
  String get pfAssetUsdCash => '달러(외환)';

  @override
  String pfAssumedReturn(String ret) {
    return '가정 $ret%';
  }

  @override
  String pfAssumedReturnVol(String ret, String vol) {
    return '가정 $ret% · 변동성 $vol%';
  }

  @override
  String get pfAssumptionsCaveat =>
      '실질(인플레 차감)·연 기하평균 기준. 해외자산은 USD 기준으로 원화 환변동이 반영되지 않았어요. 변동성은 자산 간 분산효과를 뺀 보수적 간이 추정이에요.';

  @override
  String get pfAssumptionsTitle => '계산에 사용한 가정';

  @override
  String get pfCustomDialogTitle => '자산군 직접 입력';

  @override
  String get pfCustomError => '이름과 가정 수익률을 입력해주세요';

  @override
  String get pfCustomInput => '직접 입력';

  @override
  String get pfCustomInputSubtitle => '자산군 이름·가정 수익률을 직접 넣어요';

  @override
  String get pfCustomNameLabel => '자산군 이름';

  @override
  String get pfCustomNote => '직접 입력한 가정이에요 — 출처 없이 참고용으로만 쓰세요';

  @override
  String get pfCustomReturnLabel => '가정 실질수익률';

  @override
  String get pfCustomSource => '직접 입력한 가정 (출처 없음)';

  @override
  String get pfCustomVolLabel => '예상 변동성';

  @override
  String get pfExampleAllWeather => '올웨더';

  @override
  String get pfExampleBalanced => '균형형';

  @override
  String get pfExampleGrowth => '성장형';

  @override
  String get pfExampleStable => '안정형';

  @override
  String get pfExpectedReturn => '기대수익률(실질)';

  @override
  String pfFooterNote(String disclaimer) {
    return '가정은 과거 장기 평균 기준(출처는 가정 보기) · $disclaimer';
  }

  @override
  String get pfHeadlineNeedTotal => '합계를 100%로 맞추면 기대수익률이 계산돼요';

  @override
  String get pfHintFree => '예시 구성을 골라 결과를 체험해보세요';

  @override
  String get pfHintPremium => '예시 구성이에요 — 비중은 직접 바꿀 수 있어요 (합계는 100%로 자동 유지)';

  @override
  String get pfModePortfolio => '포트폴리오';

  @override
  String get pfModeSimple => '단순';

  @override
  String get pfPremiumBanner => '비중 편집·자산군 추가는 프리미엄 — 예시 구성은 자유롭게 체험해보세요';

  @override
  String pfRealReturnVol(String ret, String vol) {
    return '실질 $ret% · 변동성 $vol%';
  }

  @override
  String get pfRemoveAssetTooltip => '이 자산군 빼기';

  @override
  String get pfResultAlreadyFire => '이미 FIRE 도달!';

  @override
  String pfResultDetail(String duration, String amount) {
    return '$duration 후 · 필요 자산 $amount';
  }

  @override
  String pfResultFireAge(int age) {
    return 'FIRE 나이 $age세';
  }

  @override
  String get pfResultLead => '이 구성이라면';

  @override
  String get pfResultNeedTotal => '합계를 100%로 맞추면 결과가 계산돼요';

  @override
  String get pfResultUnreachable => '100년 안에 도달이 어려워요';

  @override
  String get pfShowAssumptions => '가정 보기';

  @override
  String get pfSourceCommodities => '잠정 — 후속 소싱 (BCOM)';

  @override
  String get pfSourceGlobalDmEm =>
      'DMS World 1900–2010 실질 5.5% · MSCI World/EM 팩트시트 2026-06';

  @override
  String get pfSourceGold =>
      'Damodaran 1928– 실질 2.5% · 자유변동기 1971– 4.9% (기간 민감)';

  @override
  String get pfSourceKrEquity => '잠정 — 변동성은 DMS 단일국 주식 실질 SD 계층(2,000~2,300bp)';

  @override
  String get pfSourceKrTreasury => '잠정 — DMS 국가평균(60~90bp)~미국(150bp) 보수 구간';

  @override
  String get pfSourceKrwDeposit => '잠정 — 실질 예금금리 보수 가정, 한국은행 통계 후속 소싱';

  @override
  String get pfSourceReits => '잠정 — 후속 소싱 (FTSE EPRA Nareit)';

  @override
  String get pfSourceSilver => '잠정 — 금 대비 저수익·고변동 가정';

  @override
  String get pfSourceUsDow => '잠정 — S&P500 근사';

  @override
  String get pfSourceUsNasdaq100 => '잠정 — S&P500 검증치 + 성장주 스프레드 가정';

  @override
  String get pfSourceUsSp500 =>
      'Damodaran 1928–2025 · UBS/DMS 1900–2024 · Siegel 1802–2023';

  @override
  String get pfSourceUsTreasury =>
      'Damodaran 10년물 1928–2025 실질 1.45% (USD 기준, 환노출 별도)';

  @override
  String get pfSourceUsdCash =>
      '3개월 T-Bill 프록시, Damodaran·DMS (USD 기준, 환변동 미반영)';

  @override
  String get pfTagCustom => ' · 직접 입력';

  @override
  String get pfTagReference => ' · 참고치';

  @override
  String get pfTitle => '포트폴리오 구성';

  @override
  String pfTotalPercent(String total) {
    return '합계 $total%';
  }

  @override
  String get pfVolatilitySimple => '변동성(간이)';

  @override
  String get pfWeightsTitle => '자산군 비중';

  @override
  String get reminderBody => '3분이면 충분해요 — 계획 대비 어디쯤인지 확인해보세요';

  @override
  String get reminderChannelDescription => '월 1회 자산 기록 알림 (미기록 월에만)';

  @override
  String get reminderChannelName => '월간 기록 리마인더';

  @override
  String get reminderTitle => '이번 달 자산 기록, 잊지 않으셨죠?';

  @override
  String get settingsAbout => '앱 정보';

  @override
  String get settingsAboutDisclaimer => '본 앱의 시뮬레이션은 정보 제공 목적이며 투자 자문이 아닙니다.';

  @override
  String get settingsAppName => '파이어덤 Firedom';

  @override
  String get settingsBackupErrorCorrupted => '백업 파일이 손상됐어요';

  @override
  String get settingsBackupErrorNewerVersion =>
      '이 백업은 더 새 버전에서 만들어졌어요 — 앱을 업데이트해주세요';

  @override
  String get settingsBackupErrorNotFiredom => '파이어덤 백업 파일이 아니에요';

  @override
  String get settingsBackupErrorUnreadable => '백업 파일을 읽을 수 없어요';

  @override
  String get settingsBackupErrorWrongPassphrase => '패스프레이즈가 올바르지 않아요';

  @override
  String get settingsBackupExport => '백업 파일 내보내기';

  @override
  String get settingsBackupExportFailed => '백업 파일을 만들지 못했어요';

  @override
  String get settingsBackupExportSubtitle =>
      '암호화(AES-256) 파일 — iCloud/Drive에 보관하세요 · 서버 없음';

  @override
  String get settingsBackupImport => '백업 가져오기';

  @override
  String get settingsBackupImportSubtitle => '현재 데이터를 백업 내용으로 전체 교체해요';

  @override
  String get settingsBackupOpenFailed => '파일을 열지 못했어요';

  @override
  String get settingsBiometricSetupReason => '앱 잠금을 설정합니다';

  @override
  String get settingsBiometricSwitch => '생체인증 앱 잠금';

  @override
  String get settingsBiometricSwitchSubtitle => '앱을 열 때 Face ID/지문 인증';

  @override
  String get settingsBiometricUnsupported => '이 기기는 생체인증을 지원하지 않아요';

  @override
  String get settingsCurrency => '통화';

  @override
  String settingsCurrencyChangeBody(String currency) {
    return '기존에 입력한 금액은 환산되지 않고 단위만 $currency(으)로 바뀌어요. 계속할까요?';
  }

  @override
  String get settingsCurrencyChangeConfirm => '변경하기';

  @override
  String get settingsCurrencyChangeTitle => '통화 변경';

  @override
  String get settingsCustomerId => '고객 ID';

  @override
  String get settingsCustomerIdCopied => '고객 ID를 복사했어요';

  @override
  String settingsCustomerIdSubtitle(String id) {
    return '$id\n구독 문의 시 알려주세요 · 탭하면 복사';
  }

  @override
  String get settingsLanguage => '언어';

  @override
  String get settingsMaskSwitch => '금액 가림(●●●) 기본값';

  @override
  String get settingsMaskSwitchSubtitle => '홈에서 눈 아이콘으로도 바꿀 수 있어요';

  @override
  String get settingsPassphraseConfirmLabel => '한 번 더 입력';

  @override
  String get settingsPassphraseCreateTitle => '백업 암호 만들기';

  @override
  String get settingsPassphraseEnterTitle => '백업 암호 입력';

  @override
  String get settingsPassphraseLabel => '패스프레이즈 (8자 이상)';

  @override
  String get settingsPassphraseMismatch => '암호가 서로 달라요';

  @override
  String get settingsPassphraseTooShort => '8자 이상 입력해주세요';

  @override
  String get settingsPassphraseWarning => '암호를 잊으면 복구할 수 없어요 — 안전한 곳에 보관하세요';

  @override
  String get settingsPremiumActive => '이용 중 🎉 — 플랜·해지는 구독 관리에서';

  @override
  String get settingsPremiumInactive => '몬테카를로 상세 분포 · 포트폴리오 비중 편집';

  @override
  String get settingsPremiumTitle => '파이어덤 프리미엄';

  @override
  String get settingsPrivacy => '개인정보 처리방침';

  @override
  String get settingsPrivacyBody =>
      '모든 재무 데이터(자산·기록)는 회원가입·계좌 연동 없이 이 기기에만 저장되며, 어떤 경우에도 서버로 전송되지 않습니다. 앱을 삭제하면 데이터도 함께 삭제됩니다.\n\n알림은 기기 로컬 알림만 사용합니다 (푸시 서버 없음).\n\n구독을 이용하는 경우 결제·구독 상태 확인은 스토어(Apple/Google)를 통해 처리되며, 이때도 자산·기록 등 재무 데이터는 전송되지 않습니다.\n\n새 버전 안내를 위해 스토어의 공개 버전 정보만 조회하며, 이때도 개인·재무 데이터는 전송되지 않습니다.\n\n본 앱의 시뮬레이션 결과는 정보 제공 목적이며 투자 자문이 아닙니다.';

  @override
  String get settingsQaPremium => '프리미엄 시뮬레이션 (QA)';

  @override
  String get settingsQaPremiumSubtitle => '결제 없이 유료 게이트 테스트 — QA 빌드 전용';

  @override
  String get settingsReminderDay => '알림 날짜';

  @override
  String settingsReminderDayOfMonth(int day) {
    return '매월 $day일';
  }

  @override
  String get settingsReminderLastDay => '매월 말일';

  @override
  String get settingsReminderPermissionNeeded => '알림 권한이 필요해요 — 설정에서 허용해주세요';

  @override
  String get settingsReminderSwitch => '월간 기록 알림';

  @override
  String get settingsReminderSwitchSubtitle => '기록하지 않은 달에만 알려드려요 · 로컬 알림';

  @override
  String get settingsReminderTime => '알림 시간';

  @override
  String get settingsRestoreConfirmBody =>
      '현재 기기의 모든 기록·계획·설정이 백업 내용으로 교체돼요. 계속할까요?';

  @override
  String get settingsRestoreConfirmButton => '교체하기';

  @override
  String get settingsRestoreConfirmTitle => '전체 교체 확인';

  @override
  String get settingsRestoreDone => '복원 완료 — 데이터가 교체됐어요';

  @override
  String get settingsRestoreFailed => '복원에 실패했어요 — 파일과 암호를 확인해주세요';

  @override
  String get settingsSectionData => '데이터 · 정보';

  @override
  String get settingsSectionDisplaySecurity => '표시 · 보안';

  @override
  String get settingsSectionReminder => '기록 리마인더';

  @override
  String get settingsSectionSubscription => '구독';

  @override
  String get settingsTerms => '이용약관';

  @override
  String get settingsTermsSubtitle => 'Apple 표준 사용권 계약(EULA)';

  @override
  String get settingsTheme => '화면 테마';

  @override
  String get settingsThemeDark => '다크';

  @override
  String get settingsThemeLight => '라이트';

  @override
  String get settingsTitle => '설정';

  @override
  String get shellAssets => '자산';

  @override
  String get shellHome => '홈';

  @override
  String get shellRecord => '기록';

  @override
  String get shellSimulation => '시뮬레이션';

  @override
  String simAxisAge(int age) {
    return '$age세';
  }

  @override
  String get simCompare => '비교';

  @override
  String get simCompareLocked => '비교 🔒';

  @override
  String get simDefaultScenarioName => '내 시나리오';

  @override
  String simFireAge(int age) {
    return 'FIRE 나이 $age세';
  }

  @override
  String simHeadlineDetail(String period, String amount) {
    return '$period 후 · 필요 자산 $amount';
  }

  @override
  String get simHeadlineReached => '이미 FIRE 도달!';

  @override
  String get simHeadlineUnreachable => '100년 안에 도달이 어려워요';

  @override
  String get simIntro => '여기서 바꾼 가정은 계획에 반영되지 않아요 — 마음껏 실험해보세요';

  @override
  String get simLoadScenario => '불러오기';

  @override
  String simLoadScenarioCount(int count) {
    return '불러오기 ($count)';
  }

  @override
  String simMcCaption(int age, int runs) {
    return '기대수명 $age세까지 자산이 남아있을 확률 · $runs회 시뮬레이션';
  }

  @override
  String get simMcDetail => '상세 분포 보기';

  @override
  String get simMcDetailLocked => '상세 분포 보기 🔒';

  @override
  String get simMcRun => '성공 확률 계산하기';

  @override
  String get simMcRunning => '5,000가지 시장 시나리오를 계산하고 있어요…';

  @override
  String simMcSuccess(String pct) {
    return '이 계획의 성공 확률 $pct%';
  }

  @override
  String get simMcTitle => '시장 변동성 속에서도 성공할까?';

  @override
  String get simNoScenarios => '저장된 시나리오가 없어요';

  @override
  String get simOpenPortfolio => '포트폴리오로 구성하기';

  @override
  String get simResetTooltip => '계획 값으로 되돌리기';

  @override
  String get simSaveScenario => '시나리오 저장';

  @override
  String simScenarioLoaded(String name) {
    return '시나리오 \"$name\"를 불러왔어요';
  }

  @override
  String simScenarioNameHint(int n) {
    return '시나리오 $n';
  }

  @override
  String get simScenarioNameTitle => '시나리오 이름';

  @override
  String simScenarioSaved(String name) {
    return '시나리오 \"$name\"를 저장했어요';
  }

  @override
  String get simScenarioSavedFree => '시나리오를 저장했어요 (무료는 1개까지)';

  @override
  String get simSliderAge => '현재 나이';

  @override
  String get simSliderAssets => '현재 순자산';

  @override
  String get simSliderReturn => '기대수익률 (실질, 연)';

  @override
  String get simSliderSaving => '월 저축액';

  @override
  String get simSliderSpend => '은퇴 후 월 생활비';

  @override
  String get simSummaryReached => '이미 FIRE 도달';

  @override
  String get simSummaryUnreachable => '100년 내 도달 어려움';

  @override
  String get simTitle => '시뮬레이션';

  @override
  String get snapAccountName => '항목 이름';

  @override
  String get snapAccountsHeader => '자산 항목';

  @override
  String get snapAdd => '추가';

  @override
  String get snapAddAccount => '항목 추가';

  @override
  String get snapAssetClass => '자산군';

  @override
  String get snapCashflowHeader => '이번 달 소득 · 지출 (선택)';

  @override
  String get snapCashflowHint => '적으면 저축률 추이를 볼 수 있어요';

  @override
  String get snapDefaultDeposits => '예금';

  @override
  String get snapDefaultLoans => '대출';

  @override
  String get snapDefaultOther => '기타';

  @override
  String get snapDefaultPension => '연금계좌';

  @override
  String get snapDefaultRealEstate => '부동산';

  @override
  String get snapDefaultStocks => '주식';

  @override
  String snapDeltaDown(String amount) {
    return '전월 대비 −$amount';
  }

  @override
  String snapDeltaUp(String amount) {
    return '전월 대비 +$amount';
  }

  @override
  String get snapExpense => '지출';

  @override
  String get snapGoHome => '홈으로';

  @override
  String get snapIncome => '세후 소득';

  @override
  String snapLiabilityHelper(String assetClass) {
    return '$assetClass · 부채';
  }

  @override
  String get snapLiabilitySwitch => '부채 (음수로 계산)';

  @override
  String get snapMilestonesHeader => '마일스톤 달성';

  @override
  String get snapNetWorth => '순자산';

  @override
  String get snapNextRecordHint => '다음 기록부터 궤도 비교가 시작돼요';

  @override
  String get snapPrefilledHint => '지난달 값이 채워져 있어요 — 바뀐 항목만 고치면 돼요';

  @override
  String get snapRename => '이름 변경';

  @override
  String get snapRenameConfirm => '변경';

  @override
  String snapResultTitle(String month) {
    return '$month월 기록 완료!';
  }

  @override
  String get snapTitle => '자산 기록';

  @override
  String get subActiveBody => '몬테카를로 상세 · 시나리오 비교 · 포트폴리오 편집';

  @override
  String get subActiveTitle => '파이어덤 프리미엄 이용 중 🎉';

  @override
  String get subInactiveBody => '스토어에서 결제한 이력이 있다면 아래에서 복원해보세요';

  @override
  String get subInactiveTitle => '구독이 확인되지 않아요';

  @override
  String get subManageInStore => '스토어에서 구독 관리';

  @override
  String get subManagedByStore =>
      '구독은 스토어 계정으로 관리돼요 — 플랜 변경과 해지는 스토어에서 할 수 있고, 해지해도 남은 기간까지는 프리미엄이 유지돼요.';

  @override
  String get subPlanRenewal => '플랜 · 다음 갱신일';

  @override
  String get subPlanRenewalSubtitle => '스토어 구독 화면에서 확인할 수 있어요';

  @override
  String get subRestore => '구매 복원';

  @override
  String get subRestoreNotFound => '복원할 구매를 찾지 못했어요';

  @override
  String get subRestored => '구매를 복원했어요';

  @override
  String get subStoreOpenFailed => '스토어를 열 수 없어요 — 스토어 앱에서 구독을 확인해주세요';

  @override
  String get subTitle => '구독 관리';

  @override
  String upgradeBody(
    String appName,
    String storeVersion,
    String installedVersion,
  ) {
    return '$appName의 새 버전 $storeVersion이 나왔어요. 지금 버전은 $installedVersion이에요.';
  }

  @override
  String get upgradeLater => '나중에';

  @override
  String get upgradePrompt => '지금 업데이트할까요?';

  @override
  String get upgradeReleaseNotes => '이번 업데이트 내용';

  @override
  String get upgradeTitle => '업데이트가 있어요';

  @override
  String get upgradeUpdate => '업데이트';

  @override
  String widgetAheadOfPlan(int count) {
    return '계획보다 $count개월 앞';
  }

  @override
  String widgetBehindPlan(int count) {
    return '계획보다 $count개월 뒤';
  }

  @override
  String get widgetCheckAssumptions => '가정 점검이 필요해요';

  @override
  String get widgetGoalReached => '목표 도달!';

  @override
  String get widgetNoPlan => '계획을 만들어보세요';

  @override
  String get widgetOnTrack => '계획대로 진행 중';

  @override
  String widgetUntilFree(String duration) {
    return '자유까지 $duration';
  }

  @override
  String yearsLabel(int count) {
    return '$count년';
  }

  @override
  String yearsMonthsLabel(int years, int months) {
    return '$years년 $months개월';
  }
}
