import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ];

  /// No description provided for @acBond.
  ///
  /// In ko, this message translates to:
  /// **'채권'**
  String get acBond;

  /// No description provided for @acCash.
  ///
  /// In ko, this message translates to:
  /// **'현금/예금'**
  String get acCash;

  /// No description provided for @acEquity.
  ///
  /// In ko, this message translates to:
  /// **'주식'**
  String get acEquity;

  /// No description provided for @acOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get acOther;

  /// No description provided for @acPension.
  ///
  /// In ko, this message translates to:
  /// **'연금'**
  String get acPension;

  /// No description provided for @acRealEstate.
  ///
  /// In ko, this message translates to:
  /// **'부동산'**
  String get acRealEstate;

  /// No description provided for @ageLabel.
  ///
  /// In ko, this message translates to:
  /// **'{age}세'**
  String ageLabel(int age);

  /// 나이 뒤 단위 — 영어는 없음
  ///
  /// In ko, this message translates to:
  /// **'세'**
  String get ageSuffix;

  /// 앱 이름 — 한국어만 한글 브랜드 표기
  ///
  /// In ko, this message translates to:
  /// **'파이어덤'**
  String get appTitle;

  /// No description provided for @assetsAllocationEmpty.
  ///
  /// In ko, this message translates to:
  /// **'자산을 기록하면 배분을 볼 수 있어요'**
  String get assetsAllocationEmpty;

  /// No description provided for @assetsAllocationTab.
  ///
  /// In ko, this message translates to:
  /// **'자산배분'**
  String get assetsAllocationTab;

  /// ym은 formatYm 결과
  ///
  /// In ko, this message translates to:
  /// **'{ym} 기준'**
  String assetsAsOf(String ym);

  /// No description provided for @assetsCashflowEmpty.
  ///
  /// In ko, this message translates to:
  /// **'기록할 때 소득/지출을 함께 적으면 현금흐름을 볼 수 있어요'**
  String get assetsCashflowEmpty;

  /// No description provided for @assetsCashflowTab.
  ///
  /// In ko, this message translates to:
  /// **'현금흐름'**
  String get assetsCashflowTab;

  /// No description provided for @assetsEditTarget.
  ///
  /// In ko, this message translates to:
  /// **'목표 배분 수정'**
  String get assetsEditTarget;

  /// No description provided for @assetsIncome.
  ///
  /// In ko, this message translates to:
  /// **'소득'**
  String get assetsIncome;

  /// No description provided for @assetsSaving.
  ///
  /// In ko, this message translates to:
  /// **'저축 {amount}'**
  String assetsSaving(String amount);

  /// No description provided for @assetsSavingRate.
  ///
  /// In ko, this message translates to:
  /// **'저축률 {percent}%'**
  String assetsSavingRate(int percent);

  /// No description provided for @assetsSavingRateNone.
  ///
  /// In ko, this message translates to:
  /// **'저축률 —'**
  String get assetsSavingRateNone;

  /// No description provided for @assetsSetTarget.
  ///
  /// In ko, this message translates to:
  /// **'목표 배분 설정'**
  String get assetsSetTarget;

  /// delta는 부호 포함 문자열(+10 / −10). 사실 표시만
  ///
  /// In ko, this message translates to:
  /// **'목표 {target}% · {delta}%p'**
  String assetsTargetDeviation(int target, String delta);

  /// No description provided for @assetsTargetDialogTitle.
  ///
  /// In ko, this message translates to:
  /// **'목표 배분 (%)'**
  String get assetsTargetDialogTitle;

  /// 사실 표시만 — 행동 지시 금지
  ///
  /// In ko, this message translates to:
  /// **'목표 {target}% · 일치'**
  String assetsTargetMatch(int target);

  /// No description provided for @assetsTitle.
  ///
  /// In ko, this message translates to:
  /// **'자산'**
  String get assetsTitle;

  /// 사실만 표시 — 우열 판단 문구 금지
  ///
  /// In ko, this message translates to:
  /// **'{label}가 {years}년 빨라요'**
  String cmpEarlier(String label, int years);

  /// No description provided for @cmpReached.
  ///
  /// In ko, this message translates to:
  /// **'이미 도달'**
  String get cmpReached;

  /// No description provided for @cmpRowFireAge.
  ///
  /// In ko, this message translates to:
  /// **'FIRE 나이'**
  String get cmpRowFireAge;

  /// No description provided for @cmpRowFireNumber.
  ///
  /// In ko, this message translates to:
  /// **'필요 자산'**
  String get cmpRowFireNumber;

  /// No description provided for @cmpRowReturn.
  ///
  /// In ko, this message translates to:
  /// **'기대수익률'**
  String get cmpRowReturn;

  /// No description provided for @cmpSameAge.
  ///
  /// In ko, this message translates to:
  /// **'FIRE 나이가 같아요'**
  String get cmpSameAge;

  /// No description provided for @cmpTitle.
  ///
  /// In ko, this message translates to:
  /// **'시나리오 비교'**
  String get cmpTitle;

  /// No description provided for @cmpTrajectory.
  ///
  /// In ko, this message translates to:
  /// **'궤도'**
  String get cmpTrajectory;

  /// No description provided for @cmpUnreachable.
  ///
  /// In ko, this message translates to:
  /// **'도달 어려움'**
  String get cmpUnreachable;

  /// No description provided for @commonCancel.
  ///
  /// In ko, this message translates to:
  /// **'취소'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get commonClose;

  /// No description provided for @commonConfirm.
  ///
  /// In ko, this message translates to:
  /// **'확인'**
  String get commonConfirm;

  /// No description provided for @commonDelete.
  ///
  /// In ko, this message translates to:
  /// **'삭제'**
  String get commonDelete;

  /// 금액 가림 표시 — 번역하지 않는다
  ///
  /// In ko, this message translates to:
  /// **'●●●'**
  String get commonMasked;

  /// No description provided for @commonNext.
  ///
  /// In ko, this message translates to:
  /// **'다음'**
  String get commonNext;

  /// No description provided for @commonSave.
  ///
  /// In ko, this message translates to:
  /// **'저장'**
  String get commonSave;

  /// No description provided for @currencyJpy.
  ///
  /// In ko, this message translates to:
  /// **'엔 (JPY)'**
  String get currencyJpy;

  /// No description provided for @currencyKrw.
  ///
  /// In ko, this message translates to:
  /// **'원 (KRW)'**
  String get currencyKrw;

  /// No description provided for @currencyUsd.
  ///
  /// In ko, this message translates to:
  /// **'미국 달러 (USD)'**
  String get currencyUsd;

  /// 관찰형 — 행동 지시 금지
  ///
  /// In ko, this message translates to:
  /// **'계획보다 {months}개월 앞서는 중'**
  String devAhead(int months);

  /// 비난 톤 금지
  ///
  /// In ko, this message translates to:
  /// **'계획보다 {months}개월 뒤 — 따라잡을 수 있어요'**
  String devBehind(int months);

  /// No description provided for @devNeedsReview.
  ///
  /// In ko, this message translates to:
  /// **'가정 점검 필요'**
  String get devNeedsReview;

  /// No description provided for @devOnTrack.
  ///
  /// In ko, this message translates to:
  /// **'계획대로 진행 중'**
  String get devOnTrack;

  /// No description provided for @devReached.
  ///
  /// In ko, this message translates to:
  /// **'이미 목표 도달!'**
  String get devReached;

  /// No description provided for @disclaimerShort.
  ///
  /// In ko, this message translates to:
  /// **'정보 제공 목적이며 투자 자문이 아닙니다.'**
  String get disclaimerShort;

  /// 시뮬레이션 결과 화면 면책 — 반드시 유지
  ///
  /// In ko, this message translates to:
  /// **'본 시뮬레이션은 정보 제공 목적이며 투자 자문이 아닙니다.'**
  String get disclaimerSimulation;

  /// No description provided for @errorGeneric.
  ///
  /// In ko, this message translates to:
  /// **'오류가 발생했어요: {error}'**
  String errorGeneric(String error);

  /// No description provided for @goalAlreadyFire.
  ///
  /// In ko, this message translates to:
  /// **'이미 FIRE 도달!'**
  String get goalAlreadyFire;

  /// No description provided for @goalBridgeAfter.
  ///
  /// In ko, this message translates to:
  /// **'수령 후({age}세~): 월 {amount} (생활비 − 연금 {pension})'**
  String goalBridgeAfter(int age, String amount, String pension);

  /// No description provided for @goalBridgeBefore.
  ///
  /// In ko, this message translates to:
  /// **'수령 전(~{age}세): 월 {amount} (생활비 전액)'**
  String goalBridgeBefore(int age, String amount);

  /// No description provided for @goalCheckInputs.
  ///
  /// In ko, this message translates to:
  /// **'입력값을 확인해주세요'**
  String get goalCheckInputs;

  /// No description provided for @goalExpectedReturn.
  ///
  /// In ko, this message translates to:
  /// **'기대수익률 (실질)'**
  String get goalExpectedReturn;

  /// No description provided for @goalFireAge.
  ///
  /// In ko, this message translates to:
  /// **'FIRE 나이 {age}세'**
  String goalFireAge(int age);

  /// No description provided for @goalFireType.
  ///
  /// In ko, this message translates to:
  /// **'FIRE 유형'**
  String get goalFireType;

  /// No description provided for @goalFireTypeBarista.
  ///
  /// In ko, this message translates to:
  /// **'바리스타'**
  String get goalFireTypeBarista;

  /// No description provided for @goalFireTypeCoast.
  ///
  /// In ko, this message translates to:
  /// **'코스트'**
  String get goalFireTypeCoast;

  /// No description provided for @goalFireTypeCustom.
  ///
  /// In ko, this message translates to:
  /// **'직접 설정'**
  String get goalFireTypeCustom;

  /// No description provided for @goalFireTypeFat.
  ///
  /// In ko, this message translates to:
  /// **'팻'**
  String get goalFireTypeFat;

  /// No description provided for @goalFireTypeLean.
  ///
  /// In ko, this message translates to:
  /// **'린'**
  String get goalFireTypeLean;

  /// No description provided for @goalInflation.
  ///
  /// In ko, this message translates to:
  /// **'인플레이션'**
  String get goalInflation;

  /// No description provided for @goalLifeExpectancy.
  ///
  /// In ko, this message translates to:
  /// **'기대수명'**
  String get goalLifeExpectancy;

  /// No description provided for @goalMonthlySaving.
  ///
  /// In ko, this message translates to:
  /// **'월 저축액'**
  String get goalMonthlySaving;

  /// No description provided for @goalNoActivePlan.
  ///
  /// In ko, this message translates to:
  /// **'활성 계획이 없어요'**
  String get goalNoActivePlan;

  /// No description provided for @goalNominalReturn.
  ///
  /// In ko, this message translates to:
  /// **'명목수익률'**
  String get goalNominalReturn;

  /// No description provided for @goalPensionAmount.
  ///
  /// In ko, this message translates to:
  /// **'예상 월 수령액'**
  String get goalPensionAmount;

  /// No description provided for @goalPensionEffect.
  ///
  /// In ko, this message translates to:
  /// **'연금 반영으로 은퇴가 {months}개월 앞당겨져요'**
  String goalPensionEffect(int months);

  /// No description provided for @goalPensionHint.
  ///
  /// In ko, this message translates to:
  /// **'예상 수령액은 통합연금포털(fss.or.kr)에서 확인할 수 있어요'**
  String get goalPensionHint;

  /// No description provided for @goalPensionStartAge.
  ///
  /// In ko, this message translates to:
  /// **'수령 나이'**
  String get goalPensionStartAge;

  /// No description provided for @goalPensionToggle.
  ///
  /// In ko, this message translates to:
  /// **'국민연금 반영'**
  String get goalPensionToggle;

  /// period는 yearsMonthsLabel
  ///
  /// In ko, this message translates to:
  /// **'{period} 후 · 목표 자산 {amount}'**
  String goalPreviewSummary(String period, String amount);

  /// No description provided for @goalPreviewTitle.
  ///
  /// In ko, this message translates to:
  /// **'이 가정이라면'**
  String get goalPreviewTitle;

  /// No description provided for @goalRealReturnFisher.
  ///
  /// In ko, this message translates to:
  /// **'실질수익률 {rate}% (피셔 방정식으로 계산)'**
  String goalRealReturnFisher(String rate);

  /// No description provided for @goalRetireSpend.
  ///
  /// In ko, this message translates to:
  /// **'은퇴 후 월 생활비'**
  String get goalRetireSpend;

  /// No description provided for @goalReturnAggressive.
  ///
  /// In ko, this message translates to:
  /// **'공격'**
  String get goalReturnAggressive;

  /// No description provided for @goalReturnConservative.
  ///
  /// In ko, this message translates to:
  /// **'보수'**
  String get goalReturnConservative;

  /// No description provided for @goalReturnCustom.
  ///
  /// In ko, this message translates to:
  /// **'직접'**
  String get goalReturnCustom;

  /// No description provided for @goalReturnNeutral.
  ///
  /// In ko, this message translates to:
  /// **'중립'**
  String get goalReturnNeutral;

  /// No description provided for @goalReturnSummary.
  ///
  /// In ko, this message translates to:
  /// **'실질 {real}% · 변동성 {vol}%'**
  String goalReturnSummary(String real, String vol);

  /// No description provided for @goalSaveButton.
  ///
  /// In ko, this message translates to:
  /// **'저장하기'**
  String get goalSaveButton;

  /// No description provided for @goalSaveHint.
  ///
  /// In ko, this message translates to:
  /// **'저장하면 새 리비전으로 기록되고, 홈 궤도 차트에 변경 시점이 표시돼요.'**
  String get goalSaveHint;

  /// No description provided for @goalSavedSnack.
  ///
  /// In ko, this message translates to:
  /// **'계획을 업데이트했어요 — 궤도에 반영됩니다'**
  String get goalSavedSnack;

  /// No description provided for @goalSwr.
  ///
  /// In ko, this message translates to:
  /// **'안전인출률'**
  String get goalSwr;

  /// No description provided for @goalTitle.
  ///
  /// In ko, this message translates to:
  /// **'목표 설정'**
  String get goalTitle;

  /// 3개월 이상 비운 사용자 — 비난 톤 금지
  ///
  /// In ko, this message translates to:
  /// **'다시 오셨네요 — 이번 달만 기록하면 돼요'**
  String get homeComeback;

  /// No description provided for @homeCreatePlan.
  ///
  /// In ko, this message translates to:
  /// **'60초 만에 계획 만들기'**
  String get homeCreatePlan;

  /// No description provided for @homeFireProgress.
  ///
  /// In ko, this message translates to:
  /// **'FIRE 진행률 {percent}% · {current} / {target}'**
  String homeFireProgress(String percent, String current, String target);

  /// No description provided for @homeFirstRecordHint.
  ///
  /// In ko, this message translates to:
  /// **'첫 기록을 남기면 궤도 위에 점이 찍혀요'**
  String get homeFirstRecordHint;

  /// 홈 앱바 아이콘 툴팁
  ///
  /// In ko, this message translates to:
  /// **'목표 설정'**
  String get homeGoalSettingsTooltip;

  /// No description provided for @homeHideAmounts.
  ///
  /// In ko, this message translates to:
  /// **'금액 가리기'**
  String get homeHideAmounts;

  /// 차트 축·목록용 짧은 월 라벨. month는 1~12 숫자 문자열
  ///
  /// In ko, this message translates to:
  /// **'{month}월'**
  String homeMonthShort(String month);

  /// No description provided for @homeMoreMilestones.
  ///
  /// In ko, this message translates to:
  /// **'외 {count}개 달성'**
  String homeMoreMilestones(int count);

  /// No description provided for @homeNoPlan.
  ///
  /// In ko, this message translates to:
  /// **'아직 계획이 없어요'**
  String get homeNoPlan;

  /// No description provided for @homePastRecords.
  ///
  /// In ko, this message translates to:
  /// **'지난 기록'**
  String get homePastRecords;

  /// No description provided for @homeReached.
  ///
  /// In ko, this message translates to:
  /// **'재정적 자유 목표에 도달했어요!'**
  String get homeReached;

  /// No description provided for @homeRecordButton.
  ///
  /// In ko, this message translates to:
  /// **'기록하기'**
  String get homeRecordButton;

  /// month는 1~12 숫자 문자열
  ///
  /// In ko, this message translates to:
  /// **'{month}월 자산을 기록해볼까요?'**
  String homeRecordPrompt(String month);

  /// No description provided for @homeRecordSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'한 달에 3분이면 충분해요'**
  String get homeRecordSubtitle;

  /// No description provided for @homeRecordedThisMonth.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 기록 완료 — 다음 기록은 다음 달에 만나요'**
  String get homeRecordedThisMonth;

  /// No description provided for @homeSavingRate.
  ///
  /// In ko, this message translates to:
  /// **'저축률'**
  String get homeSavingRate;

  /// No description provided for @homeSavingRateHint.
  ///
  /// In ko, this message translates to:
  /// **'기록할 때 소득/지출을 함께 적으면 저축률 추이를 볼 수 있어요'**
  String get homeSavingRateHint;

  /// No description provided for @homeSavingRateThisMonth.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 저축률'**
  String get homeSavingRateThisMonth;

  /// No description provided for @homeSecondRecordHint.
  ///
  /// In ko, this message translates to:
  /// **'2번째 기록부터 궤도 비교가 시작돼요'**
  String get homeSecondRecordHint;

  /// No description provided for @homeSettingsTooltip.
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get homeSettingsTooltip;

  /// No description provided for @homeShowAmounts.
  ///
  /// In ko, this message translates to:
  /// **'금액 보이기'**
  String get homeShowAmounts;

  /// No description provided for @homeTapToEdit.
  ///
  /// In ko, this message translates to:
  /// **'탭해서 수정'**
  String get homeTapToEdit;

  /// No description provided for @homeTrajectory.
  ///
  /// In ko, this message translates to:
  /// **'궤도'**
  String get homeTrajectory;

  /// No description provided for @homeUnreachable.
  ///
  /// In ko, this message translates to:
  /// **'현재 가정으로는 도달이 어려워요'**
  String get homeUnreachable;

  /// No description provided for @homeUntilFireMonths.
  ///
  /// In ko, this message translates to:
  /// **'재정적 자유까지 {months}개월'**
  String homeUntilFireMonths(int months);

  /// No description provided for @homeUntilFireYearsMonths.
  ///
  /// In ko, this message translates to:
  /// **'재정적 자유까지 {years}년 {months}개월'**
  String homeUntilFireYearsMonths(int years, int months);

  /// No description provided for @languageEn.
  ///
  /// In ko, this message translates to:
  /// **'English'**
  String get languageEn;

  /// No description provided for @languageJa.
  ///
  /// In ko, this message translates to:
  /// **'日本語'**
  String get languageJa;

  /// 언어 이름은 해당 언어로 고정
  ///
  /// In ko, this message translates to:
  /// **'한국어'**
  String get languageKo;

  /// No description provided for @languageSystem.
  ///
  /// In ko, this message translates to:
  /// **'시스템'**
  String get languageSystem;

  /// No description provided for @lockBody.
  ///
  /// In ko, this message translates to:
  /// **'재무 데이터 보호를 위해 인증이 필요해요'**
  String get lockBody;

  /// No description provided for @lockTitle.
  ///
  /// In ko, this message translates to:
  /// **'파이어덤이 잠겨 있어요'**
  String get lockTitle;

  /// No description provided for @lockUnlock.
  ///
  /// In ko, this message translates to:
  /// **'잠금 해제'**
  String get lockUnlock;

  /// OS 생체인증 프롬프트 사유
  ///
  /// In ko, this message translates to:
  /// **'파이어덤 잠금을 해제합니다'**
  String get lockUnlockReason;

  /// No description provided for @mcDepletionTitle.
  ///
  /// In ko, this message translates to:
  /// **'자산 고갈 나이 분포'**
  String get mcDepletionTitle;

  /// No description provided for @mcEndingAssetsTitle.
  ///
  /// In ko, this message translates to:
  /// **'기대수명 시점 자산 분포 (오늘 돈 가치)'**
  String get mcEndingAssetsTitle;

  /// No description provided for @mcHeadline.
  ///
  /// In ko, this message translates to:
  /// **'성공 확률 {pct}%'**
  String mcHeadline(String pct);

  /// No description provided for @mcNoDepletion.
  ///
  /// In ko, this message translates to:
  /// **'기대수명({age}세)까지 자산이 고갈된 시나리오가 없어요 👏'**
  String mcNoDepletion(int age);

  /// No description provided for @mcP10.
  ///
  /// In ko, this message translates to:
  /// **'어려운 경우 (하위 10%)'**
  String get mcP10;

  /// No description provided for @mcP50.
  ///
  /// In ko, this message translates to:
  /// **'중간 (p50)'**
  String get mcP50;

  /// No description provided for @mcP90.
  ///
  /// In ko, this message translates to:
  /// **'잘 풀린 경우 (상위 10%)'**
  String get mcP90;

  /// No description provided for @mcSummary.
  ///
  /// In ko, this message translates to:
  /// **'{runs}가지 시장 시나리오 중 {successes}번, 기대수명 {age}세까지 자산이 유지됐어요'**
  String mcSummary(int runs, int successes, int age);

  /// No description provided for @mcTitle.
  ///
  /// In ko, this message translates to:
  /// **'성공 확률 상세'**
  String get mcTitle;

  /// No description provided for @monthsLabel.
  ///
  /// In ko, this message translates to:
  /// **'{count}개월'**
  String monthsLabel(int count);

  /// No description provided for @msFallback.
  ///
  /// In ko, this message translates to:
  /// **'마일스톤 달성! 🎉'**
  String get msFallback;

  /// No description provided for @msFire100.
  ///
  /// In ko, this message translates to:
  /// **'FIRE 목표 도달! 🏆'**
  String get msFire100;

  /// No description provided for @msFire25.
  ///
  /// In ko, this message translates to:
  /// **'FIRE 목표 25% 달성! 🔥'**
  String get msFire25;

  /// No description provided for @msFire50.
  ///
  /// In ko, this message translates to:
  /// **'FIRE 목표 절반 달성! 🔥'**
  String get msFire50;

  /// No description provided for @msFire75.
  ///
  /// In ko, this message translates to:
  /// **'FIRE 목표 75% 달성! 🔥'**
  String get msFire75;

  /// amount는 통화별 축약 금액
  ///
  /// In ko, this message translates to:
  /// **'순자산 {amount} 돌파! 🎉'**
  String msNetWorth(String amount);

  /// No description provided for @msStreak12.
  ///
  /// In ko, this message translates to:
  /// **'1년 연속 기록 🏆'**
  String get msStreak12;

  /// No description provided for @msStreak3.
  ///
  /// In ko, this message translates to:
  /// **'3개월 연속 기록 🔥'**
  String get msStreak3;

  /// No description provided for @msStreak6.
  ///
  /// In ko, this message translates to:
  /// **'6개월 연속 기록 🔥🔥'**
  String get msStreak6;

  /// No description provided for @needPlanFirst.
  ///
  /// In ko, this message translates to:
  /// **'먼저 홈에서 계획을 만들어 주세요'**
  String get needPlanFirst;

  /// No description provided for @onbAdjustExpense.
  ///
  /// In ko, this message translates to:
  /// **'지출 조정하기'**
  String get onbAdjustExpense;

  /// No description provided for @onbAlreadyFire.
  ///
  /// In ko, this message translates to:
  /// **'이미 FIRE에 도달했어요'**
  String get onbAlreadyFire;

  /// No description provided for @onbAssumptionMoneyBasis.
  ///
  /// In ko, this message translates to:
  /// **'금액 기준'**
  String get onbAssumptionMoneyBasis;

  /// No description provided for @onbAssumptionMoneyBasisValue.
  ///
  /// In ko, this message translates to:
  /// **'모든 금액은 오늘 돈 가치(실질)'**
  String get onbAssumptionMoneyBasisValue;

  /// No description provided for @onbAssumptionRealReturn.
  ///
  /// In ko, this message translates to:
  /// **'연 실질수익률'**
  String get onbAssumptionRealReturn;

  /// No description provided for @onbAssumptionRealReturnValue.
  ///
  /// In ko, this message translates to:
  /// **'{rate}% (중립 프리셋)'**
  String onbAssumptionRealReturnValue(String rate);

  /// No description provided for @onbAssumptionRetireSpendValue.
  ///
  /// In ko, this message translates to:
  /// **'현재 월 지출과 동일'**
  String get onbAssumptionRetireSpendValue;

  /// No description provided for @onbAssumptionSwr.
  ///
  /// In ko, this message translates to:
  /// **'안전인출률 (4% 룰)'**
  String get onbAssumptionSwr;

  /// 면책(disclaimerSimulation) 뒤에 붙는 안내
  ///
  /// In ko, this message translates to:
  /// **'가정은 목표 설정 화면에서 언제든 바꿀 수 있어요.'**
  String get onbAssumptionsEditHint;

  /// No description provided for @onbAssumptionsTitle.
  ///
  /// In ko, this message translates to:
  /// **'계산에 사용한 가정'**
  String get onbAssumptionsTitle;

  /// 궤도 차트 세로축 눈금 (억/億 단위) — CJK UI + 만 단위 통화일 때만
  ///
  /// In ko, this message translates to:
  /// **'{n}억'**
  String onbAxisHundredMillion(int n);

  /// No description provided for @onbCongrats.
  ///
  /// In ko, this message translates to:
  /// **'축하해요!'**
  String get onbCongrats;

  /// 온보딩 첫 화면 통화 선택 라벨
  ///
  /// In ko, this message translates to:
  /// **'통화'**
  String get onbCurrencyLabel;

  /// No description provided for @onbErrorAgeRange.
  ///
  /// In ko, this message translates to:
  /// **'1~85 사이 나이를 입력해주세요'**
  String get onbErrorAgeRange;

  /// No description provided for @onbErrorTooLarge.
  ///
  /// In ko, this message translates to:
  /// **'금액이 너무 커요'**
  String get onbErrorTooLarge;

  /// No description provided for @onbFireNumberBasis.
  ///
  /// In ko, this message translates to:
  /// **'월 지출 {spend} × {swr}% 룰 기준'**
  String onbFireNumberBasis(String spend, String swr);

  /// No description provided for @onbFireNumberTitle.
  ///
  /// In ko, this message translates to:
  /// **'필요 자산 (FIRE Number)'**
  String get onbFireNumberTitle;

  /// No description provided for @onbHeadlineUnreachable.
  ///
  /// In ko, this message translates to:
  /// **'100년 안에 도달이 어려워요'**
  String get onbHeadlineUnreachable;

  /// No description provided for @onbHeadlineUnreachableHint.
  ///
  /// In ko, this message translates to:
  /// **'아래 슬라이더로 저축을 늘리면 얼마나 달라지는지 볼 수 있어요.'**
  String get onbHeadlineUnreachableHint;

  /// No description provided for @onbHeadlineUnreachablePrefix.
  ///
  /// In ko, this message translates to:
  /// **'지금 조건으로는'**
  String get onbHeadlineUnreachablePrefix;

  /// No description provided for @onbHelperEquals.
  ///
  /// In ko, this message translates to:
  /// **'= {amount}'**
  String onbHelperEquals(String amount);

  /// No description provided for @onbNeedInputBack.
  ///
  /// In ko, this message translates to:
  /// **'입력이 필요해요 — 돌아가기'**
  String get onbNeedInputBack;

  /// No description provided for @onbNoSavingBody.
  ///
  /// In ko, this message translates to:
  /// **'월 지출이 소득과 같거나 더 커요. 입력한 지출을 조금만 낮추면 계획이 만들어져요.'**
  String get onbNoSavingBody;

  /// No description provided for @onbNoSavingTitle.
  ///
  /// In ko, this message translates to:
  /// **'현재 저축이 없어\nFIRE 나이를 계산할 수 없어요'**
  String get onbNoSavingTitle;

  /// No description provided for @onbSeeResult.
  ///
  /// In ko, this message translates to:
  /// **'결과 보기'**
  String get onbSeeResult;

  /// No description provided for @onbShowAssumptions.
  ///
  /// In ko, this message translates to:
  /// **'가정 보기'**
  String get onbShowAssumptions;

  /// 슬라이더 양끝 라벨
  ///
  /// In ko, this message translates to:
  /// **'+{amount}'**
  String onbSliderPlus(String amount);

  /// No description provided for @onbStartPlan.
  ///
  /// In ko, this message translates to:
  /// **'이 계획 시작하기'**
  String get onbStartPlan;

  /// No description provided for @onbStepAgeSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'만 나이 기준이에요'**
  String get onbStepAgeSubtitle;

  /// No description provided for @onbStepAgeTitle.
  ///
  /// In ko, this message translates to:
  /// **'나이가 어떻게 되세요?'**
  String get onbStepAgeTitle;

  /// No description provided for @onbStepAssetsSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'대략이면 충분해요 — 예금+보유자산−대출'**
  String get onbStepAssetsSubtitle;

  /// No description provided for @onbStepAssetsTitle.
  ///
  /// In ko, this message translates to:
  /// **'지금 순자산은 얼마쯤인가요?'**
  String get onbStepAssetsTitle;

  /// No description provided for @onbStepExpenseSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'대략이면 충분해요 — 고정비 포함 월 지출'**
  String get onbStepExpenseSubtitle;

  /// No description provided for @onbStepExpenseTitle.
  ///
  /// In ko, this message translates to:
  /// **'한 달에 얼마나 쓰세요?'**
  String get onbStepExpenseTitle;

  /// No description provided for @onbStepIncomeSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'대략이면 충분해요 — 실수령액 기준'**
  String get onbStepIncomeSubtitle;

  /// No description provided for @onbStepIncomeTitle.
  ///
  /// In ko, this message translates to:
  /// **'세후 월소득은 얼마인가요?'**
  String get onbStepIncomeTitle;

  /// 금액 입력 단위 토글 — unit은 '만원'/'원'/'万円'
  ///
  /// In ko, this message translates to:
  /// **'{unit} 단위'**
  String onbUnitSegment(String unit);

  /// No description provided for @onbWhatIfEffect.
  ///
  /// In ko, this message translates to:
  /// **'+{amount} → {age}'**
  String onbWhatIfEffect(String amount, String age);

  /// No description provided for @onbWhatIfEffectShortened.
  ///
  /// In ko, this message translates to:
  /// **'+{amount} → {age} ({shortened} 단축)'**
  String onbWhatIfEffectShortened(String amount, String age, String shortened);

  /// No description provided for @onbWhatIfMoveSlider.
  ///
  /// In ko, this message translates to:
  /// **'슬라이더를 움직여 보세요'**
  String get onbWhatIfMoveSlider;

  /// No description provided for @onbWhatIfStillUnreachable.
  ///
  /// In ko, this message translates to:
  /// **'아직 도달이 어려워요'**
  String get onbWhatIfStillUnreachable;

  /// No description provided for @onbWhatIfTitle.
  ///
  /// In ko, this message translates to:
  /// **'매달 조금 더 저축한다면?'**
  String get onbWhatIfTitle;

  /// No description provided for @onbYearsLater.
  ///
  /// In ko, this message translates to:
  /// **'약 {years}년 후'**
  String onbYearsLater(int years);

  /// No description provided for @onbYearsMonthsLater.
  ///
  /// In ko, this message translates to:
  /// **'약 {years}년 {months}개월 후'**
  String onbYearsMonthsLater(int years, int months);

  /// No description provided for @onbYourFireAge.
  ///
  /// In ko, this message translates to:
  /// **'당신의 FIRE 나이'**
  String get onbYourFireAge;

  /// No description provided for @paywallAlreadyPremium.
  ///
  /// In ko, this message translates to:
  /// **'이미 프리미엄을 이용 중이에요 🎉'**
  String get paywallAlreadyPremium;

  /// No description provided for @paywallAutoRenewNote.
  ///
  /// In ko, this message translates to:
  /// **'무료 체험 종료 후 선택한 플랜으로 자동 갱신되며, 언제든 스토어 계정에서 해지할 수 있어요.'**
  String get paywallAutoRenewNote;

  /// No description provided for @paywallBrowserFailed.
  ///
  /// In ko, this message translates to:
  /// **'브라우저를 열 수 없어요'**
  String get paywallBrowserFailed;

  /// 스토어 가격을 받아오지 못했을 때의 안내. 통화·금액·할인율을 넣지 않는다 — 지역별 통화가 다르고 RevenueCat localized price가 진실이다. 가격을 모르는 상태라 '더 저렴하다' 같은 단정도 하지 않는다 (과거 원화 고정 문구로 해외에서 오표기)
  ///
  /// In ko, this message translates to:
  /// **'연간·월간 중에서 고를 수 있어요 · 7일 무료 체험\n가격은 사용 중인 스토어에서 지역에 맞게 보여드려요'**
  String get paywallFallbackPricing;

  /// 프리미엄 기능 1 — 실제 동작하는 기능만 올린다
  ///
  /// In ko, this message translates to:
  /// **'몬테카를로 상세 분포 · 자산 고갈 나이 분포'**
  String get paywallFeatureMonteCarlo;

  /// 프리미엄 기능 2
  ///
  /// In ko, this message translates to:
  /// **'포트폴리오 비중 자유 편집'**
  String get paywallFeaturePortfolio;

  /// 프리미엄 기능 3
  ///
  /// In ko, this message translates to:
  /// **'시나리오 무제한 저장 · 나란히 비교'**
  String get paywallFeatureScenarios;

  /// No description provided for @paywallNothingToRestore.
  ///
  /// In ko, this message translates to:
  /// **'복원할 구매 내역이 없어요 (연동 준비 중)'**
  String get paywallNothingToRestore;

  /// No description provided for @paywallPlanAnnual.
  ///
  /// In ko, this message translates to:
  /// **'연간'**
  String get paywallPlanAnnual;

  /// No description provided for @paywallPlanLifetime.
  ///
  /// In ko, this message translates to:
  /// **'평생'**
  String get paywallPlanLifetime;

  /// No description provided for @paywallPlanMonthly.
  ///
  /// In ko, this message translates to:
  /// **'월간'**
  String get paywallPlanMonthly;

  /// 플랜 라벨 + 스토어 localized price(RevenueCat priceString 그대로)
  ///
  /// In ko, this message translates to:
  /// **'{plan} · {price}'**
  String paywallPlanPrice(String plan, String price);

  /// No description provided for @paywallPlanWeekly.
  ///
  /// In ko, this message translates to:
  /// **'주간'**
  String get paywallPlanWeekly;

  /// 오퍼링 조회 실패(오프라인 등)용. '연동 준비 중'(paywallStoreNotReady)은 RevenueCat 미구성 빌드에서만 쓴다 — 구독이 라이브인 출시 빌드에서 섞이면 사실과 다르다
  ///
  /// In ko, this message translates to:
  /// **'가격을 불러오지 못했어요 · 네트워크를 확인한 뒤 다시 시도해주세요'**
  String get paywallPricesUnavailable;

  /// App Store 3.1.2(c) 필수 링크 — 링크 URL은 paywallPrivacyUrl 상수
  ///
  /// In ko, this message translates to:
  /// **'개인정보 처리방침'**
  String get paywallPrivacy;

  /// No description provided for @paywallPurchaseFailed.
  ///
  /// In ko, this message translates to:
  /// **'결제가 완료되지 않았어요'**
  String get paywallPurchaseFailed;

  /// No description provided for @paywallRestore.
  ///
  /// In ko, this message translates to:
  /// **'구매 복원'**
  String get paywallRestore;

  /// No description provided for @paywallRestored.
  ///
  /// In ko, this message translates to:
  /// **'구매를 복원했어요'**
  String get paywallRestored;

  /// App Store 3.1.2: 기간당 가격을 표시하지 못하는 화면에 결제 개시 버튼을 두지 않는다
  ///
  /// In ko, this message translates to:
  /// **'가격 다시 불러오기'**
  String get paywallRetryPrices;

  /// No description provided for @paywallStoreNotReady.
  ///
  /// In ko, this message translates to:
  /// **'스토어 결제 연동 준비 중이에요 — 곧 열려요'**
  String get paywallStoreNotReady;

  /// No description provided for @paywallSubscribe.
  ///
  /// In ko, this message translates to:
  /// **'구독 시작하기'**
  String get paywallSubscribe;

  /// 성공 확률이 없을 때 페이월 부제
  ///
  /// In ko, this message translates to:
  /// **'내 계획의 리스크까지 확인해보세요'**
  String get paywallTeaserGeneric;

  /// rate는 정수 퍼센트 문자열(소수 없음)
  ///
  /// In ko, this message translates to:
  /// **'회원님 계획의 성공 확률 {rate}% — 상세 분포와 자산 고갈 리스크를 확인해보세요'**
  String paywallTeaserWithRate(String rate);

  /// App Store 3.1.2(c) 필수 링크 — 링크 URL은 paywallTermsUrl 상수
  ///
  /// In ko, this message translates to:
  /// **'이용약관'**
  String get paywallTerms;

  /// 페이월 시트 제목
  ///
  /// In ko, this message translates to:
  /// **'파이어덤 프리미엄'**
  String get paywallTitle;

  /// No description provided for @pfAdd.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get pfAdd;

  /// No description provided for @pfAddAsset.
  ///
  /// In ko, this message translates to:
  /// **'자산군 추가'**
  String get pfAddAsset;

  /// No description provided for @pfApplyCta.
  ///
  /// In ko, this message translates to:
  /// **'이 구성으로 시뮬레이션'**
  String get pfApplyCta;

  /// No description provided for @pfAssetCommodities.
  ///
  /// In ko, this message translates to:
  /// **'원자재'**
  String get pfAssetCommodities;

  /// No description provided for @pfAssetCustom.
  ///
  /// In ko, this message translates to:
  /// **'{label} · 직접 입력'**
  String pfAssetCustom(String label);

  /// No description provided for @pfAssetGlobalDmEm.
  ///
  /// In ko, this message translates to:
  /// **'선진국·신흥국'**
  String get pfAssetGlobalDmEm;

  /// No description provided for @pfAssetGold.
  ///
  /// In ko, this message translates to:
  /// **'금'**
  String get pfAssetGold;

  /// No description provided for @pfAssetKrEquity.
  ///
  /// In ko, this message translates to:
  /// **'국내주식'**
  String get pfAssetKrEquity;

  /// No description provided for @pfAssetKrTreasury.
  ///
  /// In ko, this message translates to:
  /// **'국고채'**
  String get pfAssetKrTreasury;

  /// No description provided for @pfAssetKrwDeposit.
  ///
  /// In ko, this message translates to:
  /// **'원화 예금'**
  String get pfAssetKrwDeposit;

  /// No description provided for @pfAssetReference.
  ///
  /// In ko, this message translates to:
  /// **'{label} · 참고치'**
  String pfAssetReference(String label);

  /// No description provided for @pfAssetReits.
  ///
  /// In ko, this message translates to:
  /// **'리츠'**
  String get pfAssetReits;

  /// No description provided for @pfAssetSilver.
  ///
  /// In ko, this message translates to:
  /// **'은'**
  String get pfAssetSilver;

  /// No description provided for @pfAssetUsDow.
  ///
  /// In ko, this message translates to:
  /// **'다우존스'**
  String get pfAssetUsDow;

  /// No description provided for @pfAssetUsNasdaq100.
  ///
  /// In ko, this message translates to:
  /// **'나스닥100'**
  String get pfAssetUsNasdaq100;

  /// 엔진 PortfolioAsset.label과 ko 동일
  ///
  /// In ko, this message translates to:
  /// **'S&P500'**
  String get pfAssetUsSp500;

  /// No description provided for @pfAssetUsTreasury.
  ///
  /// In ko, this message translates to:
  /// **'미국채'**
  String get pfAssetUsTreasury;

  /// No description provided for @pfAssetUsdCash.
  ///
  /// In ko, this message translates to:
  /// **'달러(외환)'**
  String get pfAssetUsdCash;

  /// 자산 행의 가정 수익률
  ///
  /// In ko, this message translates to:
  /// **'가정 {ret}%'**
  String pfAssumedReturn(String ret);

  /// No description provided for @pfAssumedReturnVol.
  ///
  /// In ko, this message translates to:
  /// **'가정 {ret}% · 변동성 {vol}%'**
  String pfAssumedReturnVol(String ret, String vol);

  /// No description provided for @pfAssumptionsCaveat.
  ///
  /// In ko, this message translates to:
  /// **'실질(인플레 차감)·연 기하평균 기준. 해외자산은 USD 기준으로 원화 환변동이 반영되지 않았어요. 변동성은 자산 간 분산효과를 뺀 보수적 간이 추정이에요.'**
  String get pfAssumptionsCaveat;

  /// No description provided for @pfAssumptionsTitle.
  ///
  /// In ko, this message translates to:
  /// **'계산에 사용한 가정'**
  String get pfAssumptionsTitle;

  /// No description provided for @pfCustomDialogTitle.
  ///
  /// In ko, this message translates to:
  /// **'자산군 직접 입력'**
  String get pfCustomDialogTitle;

  /// No description provided for @pfCustomError.
  ///
  /// In ko, this message translates to:
  /// **'이름과 가정 수익률을 입력해주세요'**
  String get pfCustomError;

  /// No description provided for @pfCustomInput.
  ///
  /// In ko, this message translates to:
  /// **'직접 입력'**
  String get pfCustomInput;

  /// No description provided for @pfCustomInputSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'자산군 이름·가정 수익률을 직접 넣어요'**
  String get pfCustomInputSubtitle;

  /// No description provided for @pfCustomNameLabel.
  ///
  /// In ko, this message translates to:
  /// **'자산군 이름'**
  String get pfCustomNameLabel;

  /// No description provided for @pfCustomNote.
  ///
  /// In ko, this message translates to:
  /// **'직접 입력한 가정이에요 — 출처 없이 참고용으로만 쓰세요'**
  String get pfCustomNote;

  /// No description provided for @pfCustomReturnLabel.
  ///
  /// In ko, this message translates to:
  /// **'가정 실질수익률'**
  String get pfCustomReturnLabel;

  /// No description provided for @pfCustomSource.
  ///
  /// In ko, this message translates to:
  /// **'직접 입력한 가정 (출처 없음)'**
  String get pfCustomSource;

  /// No description provided for @pfCustomVolLabel.
  ///
  /// In ko, this message translates to:
  /// **'예상 변동성'**
  String get pfCustomVolLabel;

  /// No description provided for @pfExampleAllWeather.
  ///
  /// In ko, this message translates to:
  /// **'올웨더'**
  String get pfExampleAllWeather;

  /// No description provided for @pfExampleBalanced.
  ///
  /// In ko, this message translates to:
  /// **'균형형'**
  String get pfExampleBalanced;

  /// No description provided for @pfExampleGrowth.
  ///
  /// In ko, this message translates to:
  /// **'성장형'**
  String get pfExampleGrowth;

  /// 예시 구성 — '추천' 아님
  ///
  /// In ko, this message translates to:
  /// **'안정형'**
  String get pfExampleStable;

  /// No description provided for @pfExpectedReturn.
  ///
  /// In ko, this message translates to:
  /// **'기대수익률(실질)'**
  String get pfExpectedReturn;

  /// 하단 안내 — disclaimer에는 disclaimerSimulation을 넣는다
  ///
  /// In ko, this message translates to:
  /// **'가정은 과거 장기 평균 기준(출처는 가정 보기) · {disclaimer}'**
  String pfFooterNote(String disclaimer);

  /// No description provided for @pfHeadlineNeedTotal.
  ///
  /// In ko, this message translates to:
  /// **'합계를 100%로 맞추면 기대수익률이 계산돼요'**
  String get pfHeadlineNeedTotal;

  /// No description provided for @pfHintFree.
  ///
  /// In ko, this message translates to:
  /// **'예시 구성을 골라 결과를 체험해보세요'**
  String get pfHintFree;

  /// No description provided for @pfHintPremium.
  ///
  /// In ko, this message translates to:
  /// **'예시 구성이에요 — 비중은 직접 바꿀 수 있어요 (합계는 100%로 자동 유지)'**
  String get pfHintPremium;

  /// No description provided for @pfModePortfolio.
  ///
  /// In ko, this message translates to:
  /// **'포트폴리오'**
  String get pfModePortfolio;

  /// 단순 ↔ 포트폴리오 세그먼트
  ///
  /// In ko, this message translates to:
  /// **'단순'**
  String get pfModeSimple;

  /// No description provided for @pfPremiumBanner.
  ///
  /// In ko, this message translates to:
  /// **'비중 편집·자산군 추가는 프리미엄 — 예시 구성은 자유롭게 체험해보세요'**
  String get pfPremiumBanner;

  /// No description provided for @pfRealReturnVol.
  ///
  /// In ko, this message translates to:
  /// **'실질 {ret}% · 변동성 {vol}%'**
  String pfRealReturnVol(String ret, String vol);

  /// No description provided for @pfRemoveAssetTooltip.
  ///
  /// In ko, this message translates to:
  /// **'이 자산군 빼기'**
  String get pfRemoveAssetTooltip;

  /// No description provided for @pfResultAlreadyFire.
  ///
  /// In ko, this message translates to:
  /// **'이미 FIRE 도달!'**
  String get pfResultAlreadyFire;

  /// duration=yearsMonthsLabel, amount=money.compact
  ///
  /// In ko, this message translates to:
  /// **'{duration} 후 · 필요 자산 {amount}'**
  String pfResultDetail(String duration, String amount);

  /// No description provided for @pfResultFireAge.
  ///
  /// In ko, this message translates to:
  /// **'FIRE 나이 {age}세'**
  String pfResultFireAge(int age);

  /// No description provided for @pfResultLead.
  ///
  /// In ko, this message translates to:
  /// **'이 구성이라면'**
  String get pfResultLead;

  /// No description provided for @pfResultNeedTotal.
  ///
  /// In ko, this message translates to:
  /// **'합계를 100%로 맞추면 결과가 계산돼요'**
  String get pfResultNeedTotal;

  /// No description provided for @pfResultUnreachable.
  ///
  /// In ko, this message translates to:
  /// **'100년 안에 도달이 어려워요'**
  String get pfResultUnreachable;

  /// No description provided for @pfShowAssumptions.
  ///
  /// In ko, this message translates to:
  /// **'가정 보기'**
  String get pfShowAssumptions;

  /// No description provided for @pfSourceCommodities.
  ///
  /// In ko, this message translates to:
  /// **'잠정 — 후속 소싱 (BCOM)'**
  String get pfSourceCommodities;

  /// No description provided for @pfSourceGlobalDmEm.
  ///
  /// In ko, this message translates to:
  /// **'DMS World 1900–2010 실질 5.5% · MSCI World/EM 팩트시트 2026-06'**
  String get pfSourceGlobalDmEm;

  /// No description provided for @pfSourceGold.
  ///
  /// In ko, this message translates to:
  /// **'Damodaran 1928– 실질 2.5% · 자유변동기 1971– 4.9% (기간 민감)'**
  String get pfSourceGold;

  /// No description provided for @pfSourceKrEquity.
  ///
  /// In ko, this message translates to:
  /// **'잠정 — 변동성은 DMS 단일국 주식 실질 SD 계층(2,000~2,300bp)'**
  String get pfSourceKrEquity;

  /// No description provided for @pfSourceKrTreasury.
  ///
  /// In ko, this message translates to:
  /// **'잠정 — DMS 국가평균(60~90bp)~미국(150bp) 보수 구간'**
  String get pfSourceKrTreasury;

  /// No description provided for @pfSourceKrwDeposit.
  ///
  /// In ko, this message translates to:
  /// **'잠정 — 실질 예금금리 보수 가정, 한국은행 통계 후속 소싱'**
  String get pfSourceKrwDeposit;

  /// No description provided for @pfSourceReits.
  ///
  /// In ko, this message translates to:
  /// **'잠정 — 후속 소싱 (FTSE EPRA Nareit)'**
  String get pfSourceReits;

  /// No description provided for @pfSourceSilver.
  ///
  /// In ko, this message translates to:
  /// **'잠정 — 금 대비 저수익·고변동 가정'**
  String get pfSourceSilver;

  /// No description provided for @pfSourceUsDow.
  ///
  /// In ko, this message translates to:
  /// **'잠정 — S&P500 근사'**
  String get pfSourceUsDow;

  /// No description provided for @pfSourceUsNasdaq100.
  ///
  /// In ko, this message translates to:
  /// **'잠정 — S&P500 검증치 + 성장주 스프레드 가정'**
  String get pfSourceUsNasdaq100;

  /// 엔진 PortfolioAsset.source와 ko 동일
  ///
  /// In ko, this message translates to:
  /// **'Damodaran 1928–2025 · UBS/DMS 1900–2024 · Siegel 1802–2023'**
  String get pfSourceUsSp500;

  /// No description provided for @pfSourceUsTreasury.
  ///
  /// In ko, this message translates to:
  /// **'Damodaran 10년물 1928–2025 실질 1.45% (USD 기준, 환노출 별도)'**
  String get pfSourceUsTreasury;

  /// No description provided for @pfSourceUsdCash.
  ///
  /// In ko, this message translates to:
  /// **'3개월 T-Bill 프록시, Damodaran·DMS (USD 기준, 환변동 미반영)'**
  String get pfSourceUsdCash;

  /// 직접 입력 자산 꼬리표 (앞 구분점 포함)
  ///
  /// In ko, this message translates to:
  /// **' · 직접 입력'**
  String get pfTagCustom;

  /// 미검증 프리셋 꼬리표 (앞 구분점 포함)
  ///
  /// In ko, this message translates to:
  /// **' · 참고치'**
  String get pfTagReference;

  /// S4-2 앱바 제목
  ///
  /// In ko, this message translates to:
  /// **'포트폴리오 구성'**
  String get pfTitle;

  /// No description provided for @pfTotalPercent.
  ///
  /// In ko, this message translates to:
  /// **'합계 {total}%'**
  String pfTotalPercent(String total);

  /// No description provided for @pfVolatilitySimple.
  ///
  /// In ko, this message translates to:
  /// **'변동성(간이)'**
  String get pfVolatilitySimple;

  /// No description provided for @pfWeightsTitle.
  ///
  /// In ko, this message translates to:
  /// **'자산군 비중'**
  String get pfWeightsTitle;

  /// 로컬 알림 본문
  ///
  /// In ko, this message translates to:
  /// **'3분이면 충분해요 — 계획 대비 어디쯤인지 확인해보세요'**
  String get reminderBody;

  /// Android 알림 채널 설명
  ///
  /// In ko, this message translates to:
  /// **'월 1회 자산 기록 알림 (미기록 월에만)'**
  String get reminderChannelDescription;

  /// Android 알림 채널 이름
  ///
  /// In ko, this message translates to:
  /// **'월간 기록 리마인더'**
  String get reminderChannelName;

  /// 로컬 알림 제목
  ///
  /// In ko, this message translates to:
  /// **'이번 달 자산 기록, 잊지 않으셨죠?'**
  String get reminderTitle;

  /// No description provided for @settingsAbout.
  ///
  /// In ko, this message translates to:
  /// **'앱 정보'**
  String get settingsAbout;

  /// No description provided for @settingsAboutDisclaimer.
  ///
  /// In ko, this message translates to:
  /// **'본 앱의 시뮬레이션은 정보 제공 목적이며 투자 자문이 아닙니다.'**
  String get settingsAboutDisclaimer;

  /// 앱 정보 다이얼로그의 앱 이름
  ///
  /// In ko, this message translates to:
  /// **'파이어덤 Firedom'**
  String get settingsAppName;

  /// No description provided for @settingsBackupErrorCorrupted.
  ///
  /// In ko, this message translates to:
  /// **'백업 파일이 손상됐어요'**
  String get settingsBackupErrorCorrupted;

  /// No description provided for @settingsBackupErrorNewerVersion.
  ///
  /// In ko, this message translates to:
  /// **'이 백업은 더 새 버전에서 만들어졌어요 — 앱을 업데이트해주세요'**
  String get settingsBackupErrorNewerVersion;

  /// No description provided for @settingsBackupErrorNotFiredom.
  ///
  /// In ko, this message translates to:
  /// **'파이어덤 백업 파일이 아니에요'**
  String get settingsBackupErrorNotFiredom;

  /// No description provided for @settingsBackupErrorUnreadable.
  ///
  /// In ko, this message translates to:
  /// **'백업 파일을 읽을 수 없어요'**
  String get settingsBackupErrorUnreadable;

  /// No description provided for @settingsBackupErrorWrongPassphrase.
  ///
  /// In ko, this message translates to:
  /// **'패스프레이즈가 올바르지 않아요'**
  String get settingsBackupErrorWrongPassphrase;

  /// No description provided for @settingsBackupExport.
  ///
  /// In ko, this message translates to:
  /// **'백업 파일 내보내기'**
  String get settingsBackupExport;

  /// No description provided for @settingsBackupExportFailed.
  ///
  /// In ko, this message translates to:
  /// **'백업 파일을 만들지 못했어요'**
  String get settingsBackupExportFailed;

  /// No description provided for @settingsBackupExportSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'암호화(AES-256) 파일 — iCloud/Drive에 보관하세요 · 서버 없음'**
  String get settingsBackupExportSubtitle;

  /// No description provided for @settingsBackupImport.
  ///
  /// In ko, this message translates to:
  /// **'백업 가져오기'**
  String get settingsBackupImport;

  /// No description provided for @settingsBackupImportSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'현재 데이터를 백업 내용으로 전체 교체해요'**
  String get settingsBackupImportSubtitle;

  /// No description provided for @settingsBackupOpenFailed.
  ///
  /// In ko, this message translates to:
  /// **'파일을 열지 못했어요'**
  String get settingsBackupOpenFailed;

  /// OS 생체인증 프롬프트 사유
  ///
  /// In ko, this message translates to:
  /// **'앱 잠금을 설정합니다'**
  String get settingsBiometricSetupReason;

  /// No description provided for @settingsBiometricSwitch.
  ///
  /// In ko, this message translates to:
  /// **'생체인증 앱 잠금'**
  String get settingsBiometricSwitch;

  /// No description provided for @settingsBiometricSwitchSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'앱을 열 때 Face ID/지문 인증'**
  String get settingsBiometricSwitchSubtitle;

  /// No description provided for @settingsBiometricUnsupported.
  ///
  /// In ko, this message translates to:
  /// **'이 기기는 생체인증을 지원하지 않아요'**
  String get settingsBiometricUnsupported;

  /// No description provided for @settingsCurrency.
  ///
  /// In ko, this message translates to:
  /// **'통화'**
  String get settingsCurrency;

  /// No description provided for @settingsCurrencyChangeBody.
  ///
  /// In ko, this message translates to:
  /// **'기존에 입력한 금액은 환산되지 않고 단위만 {currency}(으)로 바뀌어요. 계속할까요?'**
  String settingsCurrencyChangeBody(String currency);

  /// No description provided for @settingsCurrencyChangeConfirm.
  ///
  /// In ko, this message translates to:
  /// **'변경하기'**
  String get settingsCurrencyChangeConfirm;

  /// No description provided for @settingsCurrencyChangeTitle.
  ///
  /// In ko, this message translates to:
  /// **'통화 변경'**
  String get settingsCurrencyChangeTitle;

  /// No description provided for @settingsCustomerId.
  ///
  /// In ko, this message translates to:
  /// **'고객 ID'**
  String get settingsCustomerId;

  /// No description provided for @settingsCustomerIdCopied.
  ///
  /// In ko, this message translates to:
  /// **'고객 ID를 복사했어요'**
  String get settingsCustomerIdCopied;

  /// No description provided for @settingsCustomerIdSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'{id}\n구독 문의 시 알려주세요 · 탭하면 복사'**
  String settingsCustomerIdSubtitle(String id);

  /// No description provided for @settingsLanguage.
  ///
  /// In ko, this message translates to:
  /// **'언어'**
  String get settingsLanguage;

  /// No description provided for @settingsMaskSwitch.
  ///
  /// In ko, this message translates to:
  /// **'금액 가림(●●●) 기본값'**
  String get settingsMaskSwitch;

  /// No description provided for @settingsMaskSwitchSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'홈에서 눈 아이콘으로도 바꿀 수 있어요'**
  String get settingsMaskSwitchSubtitle;

  /// No description provided for @settingsPassphraseConfirmLabel.
  ///
  /// In ko, this message translates to:
  /// **'한 번 더 입력'**
  String get settingsPassphraseConfirmLabel;

  /// No description provided for @settingsPassphraseCreateTitle.
  ///
  /// In ko, this message translates to:
  /// **'백업 암호 만들기'**
  String get settingsPassphraseCreateTitle;

  /// No description provided for @settingsPassphraseEnterTitle.
  ///
  /// In ko, this message translates to:
  /// **'백업 암호 입력'**
  String get settingsPassphraseEnterTitle;

  /// No description provided for @settingsPassphraseLabel.
  ///
  /// In ko, this message translates to:
  /// **'패스프레이즈 (8자 이상)'**
  String get settingsPassphraseLabel;

  /// No description provided for @settingsPassphraseMismatch.
  ///
  /// In ko, this message translates to:
  /// **'암호가 서로 달라요'**
  String get settingsPassphraseMismatch;

  /// No description provided for @settingsPassphraseTooShort.
  ///
  /// In ko, this message translates to:
  /// **'8자 이상 입력해주세요'**
  String get settingsPassphraseTooShort;

  /// No description provided for @settingsPassphraseWarning.
  ///
  /// In ko, this message translates to:
  /// **'암호를 잊으면 복구할 수 없어요 — 안전한 곳에 보관하세요'**
  String get settingsPassphraseWarning;

  /// No description provided for @settingsPremiumActive.
  ///
  /// In ko, this message translates to:
  /// **'이용 중 🎉 — 플랜·해지는 구독 관리에서'**
  String get settingsPremiumActive;

  /// No description provided for @settingsPremiumInactive.
  ///
  /// In ko, this message translates to:
  /// **'몬테카를로 상세 분포 · 포트폴리오 비중 편집'**
  String get settingsPremiumInactive;

  /// No description provided for @settingsPremiumTitle.
  ///
  /// In ko, this message translates to:
  /// **'파이어덤 프리미엄'**
  String get settingsPremiumTitle;

  /// No description provided for @settingsPrivacy.
  ///
  /// In ko, this message translates to:
  /// **'개인정보 처리방침'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacyBody.
  ///
  /// In ko, this message translates to:
  /// **'모든 재무 데이터(자산·기록)는 회원가입·계좌 연동 없이 이 기기에만 저장되며, 어떤 경우에도 서버로 전송되지 않습니다. 앱을 삭제하면 데이터도 함께 삭제됩니다.\n\n알림은 기기 로컬 알림만 사용합니다 (푸시 서버 없음).\n\n구독을 이용하는 경우 결제·구독 상태 확인은 스토어(Apple/Google)를 통해 처리되며, 이때도 자산·기록 등 재무 데이터는 전송되지 않습니다.\n\n새 버전 안내를 위해 스토어의 공개 버전 정보만 조회하며, 이때도 개인·재무 데이터는 전송되지 않습니다.\n\n본 앱의 시뮬레이션 결과는 정보 제공 목적이며 투자 자문이 아닙니다.'**
  String get settingsPrivacyBody;

  /// No description provided for @settingsQaPremium.
  ///
  /// In ko, this message translates to:
  /// **'프리미엄 시뮬레이션 (QA)'**
  String get settingsQaPremium;

  /// No description provided for @settingsQaPremiumSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'결제 없이 유료 게이트 테스트 — QA 빌드 전용'**
  String get settingsQaPremiumSubtitle;

  /// No description provided for @settingsReminderDay.
  ///
  /// In ko, this message translates to:
  /// **'알림 날짜'**
  String get settingsReminderDay;

  /// No description provided for @settingsReminderDayOfMonth.
  ///
  /// In ko, this message translates to:
  /// **'매월 {day}일'**
  String settingsReminderDayOfMonth(int day);

  /// No description provided for @settingsReminderLastDay.
  ///
  /// In ko, this message translates to:
  /// **'매월 말일'**
  String get settingsReminderLastDay;

  /// No description provided for @settingsReminderPermissionNeeded.
  ///
  /// In ko, this message translates to:
  /// **'알림 권한이 필요해요 — 설정에서 허용해주세요'**
  String get settingsReminderPermissionNeeded;

  /// No description provided for @settingsReminderSwitch.
  ///
  /// In ko, this message translates to:
  /// **'월간 기록 알림'**
  String get settingsReminderSwitch;

  /// No description provided for @settingsReminderSwitchSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'기록하지 않은 달에만 알려드려요 · 로컬 알림'**
  String get settingsReminderSwitchSubtitle;

  /// No description provided for @settingsReminderTime.
  ///
  /// In ko, this message translates to:
  /// **'알림 시간'**
  String get settingsReminderTime;

  /// No description provided for @settingsRestoreConfirmBody.
  ///
  /// In ko, this message translates to:
  /// **'현재 기기의 모든 기록·계획·설정이 백업 내용으로 교체돼요. 계속할까요?'**
  String get settingsRestoreConfirmBody;

  /// No description provided for @settingsRestoreConfirmButton.
  ///
  /// In ko, this message translates to:
  /// **'교체하기'**
  String get settingsRestoreConfirmButton;

  /// No description provided for @settingsRestoreConfirmTitle.
  ///
  /// In ko, this message translates to:
  /// **'전체 교체 확인'**
  String get settingsRestoreConfirmTitle;

  /// No description provided for @settingsRestoreDone.
  ///
  /// In ko, this message translates to:
  /// **'복원 완료 — 데이터가 교체됐어요'**
  String get settingsRestoreDone;

  /// No description provided for @settingsRestoreFailed.
  ///
  /// In ko, this message translates to:
  /// **'복원에 실패했어요 — 파일과 암호를 확인해주세요'**
  String get settingsRestoreFailed;

  /// No description provided for @settingsSectionData.
  ///
  /// In ko, this message translates to:
  /// **'데이터 · 정보'**
  String get settingsSectionData;

  /// No description provided for @settingsSectionDisplaySecurity.
  ///
  /// In ko, this message translates to:
  /// **'표시 · 보안'**
  String get settingsSectionDisplaySecurity;

  /// No description provided for @settingsSectionReminder.
  ///
  /// In ko, this message translates to:
  /// **'기록 리마인더'**
  String get settingsSectionReminder;

  /// No description provided for @settingsSectionSubscription.
  ///
  /// In ko, this message translates to:
  /// **'구독'**
  String get settingsSectionSubscription;

  /// No description provided for @settingsTerms.
  ///
  /// In ko, this message translates to:
  /// **'이용약관'**
  String get settingsTerms;

  /// No description provided for @settingsTermsSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'Apple 표준 사용권 계약(EULA)'**
  String get settingsTermsSubtitle;

  /// No description provided for @settingsTheme.
  ///
  /// In ko, this message translates to:
  /// **'화면 테마'**
  String get settingsTheme;

  /// No description provided for @settingsThemeDark.
  ///
  /// In ko, this message translates to:
  /// **'다크'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeLight.
  ///
  /// In ko, this message translates to:
  /// **'라이트'**
  String get settingsThemeLight;

  /// 설정 화면 앱바
  ///
  /// In ko, this message translates to:
  /// **'설정'**
  String get settingsTitle;

  /// 하단 탭
  ///
  /// In ko, this message translates to:
  /// **'자산'**
  String get shellAssets;

  /// 하단 탭
  ///
  /// In ko, this message translates to:
  /// **'홈'**
  String get shellHome;

  /// 하단 탭 — 기록 플로우 push
  ///
  /// In ko, this message translates to:
  /// **'기록'**
  String get shellRecord;

  /// 하단 탭
  ///
  /// In ko, this message translates to:
  /// **'시뮬레이션'**
  String get shellSimulation;

  /// 차트 x축 나이 눈금 — 영어는 겹침 방지로 숫자만
  ///
  /// In ko, this message translates to:
  /// **'{age}세'**
  String simAxisAge(int age);

  /// No description provided for @simCompare.
  ///
  /// In ko, this message translates to:
  /// **'비교'**
  String get simCompare;

  /// No description provided for @simCompareLocked.
  ///
  /// In ko, this message translates to:
  /// **'비교 🔒'**
  String get simCompareLocked;

  /// 무료 사용자 저장 시 자동 이름
  ///
  /// In ko, this message translates to:
  /// **'내 시나리오'**
  String get simDefaultScenarioName;

  /// 헤드라인·시나리오 부제 공용
  ///
  /// In ko, this message translates to:
  /// **'FIRE 나이 {age}세'**
  String simFireAge(int age);

  /// period = yearsMonthsLabel, amount = money.compact
  ///
  /// In ko, this message translates to:
  /// **'{period} 후 · 필요 자산 {amount}'**
  String simHeadlineDetail(String period, String amount);

  /// No description provided for @simHeadlineReached.
  ///
  /// In ko, this message translates to:
  /// **'이미 FIRE 도달!'**
  String get simHeadlineReached;

  /// No description provided for @simHeadlineUnreachable.
  ///
  /// In ko, this message translates to:
  /// **'100년 안에 도달이 어려워요'**
  String get simHeadlineUnreachable;

  /// No description provided for @simIntro.
  ///
  /// In ko, this message translates to:
  /// **'여기서 바꾼 가정은 계획에 반영되지 않아요 — 마음껏 실험해보세요'**
  String get simIntro;

  /// No description provided for @simLoadScenario.
  ///
  /// In ko, this message translates to:
  /// **'불러오기'**
  String get simLoadScenario;

  /// No description provided for @simLoadScenarioCount.
  ///
  /// In ko, this message translates to:
  /// **'불러오기 ({count})'**
  String simLoadScenarioCount(int count);

  /// No description provided for @simMcCaption.
  ///
  /// In ko, this message translates to:
  /// **'기대수명 {age}세까지 자산이 남아있을 확률 · {runs}회 시뮬레이션'**
  String simMcCaption(int age, int runs);

  /// No description provided for @simMcDetail.
  ///
  /// In ko, this message translates to:
  /// **'상세 분포 보기'**
  String get simMcDetail;

  /// No description provided for @simMcDetailLocked.
  ///
  /// In ko, this message translates to:
  /// **'상세 분포 보기 🔒'**
  String get simMcDetailLocked;

  /// No description provided for @simMcRun.
  ///
  /// In ko, this message translates to:
  /// **'성공 확률 계산하기'**
  String get simMcRun;

  /// No description provided for @simMcRunning.
  ///
  /// In ko, this message translates to:
  /// **'5,000가지 시장 시나리오를 계산하고 있어요…'**
  String get simMcRunning;

  /// No description provided for @simMcSuccess.
  ///
  /// In ko, this message translates to:
  /// **'이 계획의 성공 확률 {pct}%'**
  String simMcSuccess(String pct);

  /// No description provided for @simMcTitle.
  ///
  /// In ko, this message translates to:
  /// **'시장 변동성 속에서도 성공할까?'**
  String get simMcTitle;

  /// No description provided for @simNoScenarios.
  ///
  /// In ko, this message translates to:
  /// **'저장된 시나리오가 없어요'**
  String get simNoScenarios;

  /// No description provided for @simOpenPortfolio.
  ///
  /// In ko, this message translates to:
  /// **'포트폴리오로 구성하기'**
  String get simOpenPortfolio;

  /// No description provided for @simResetTooltip.
  ///
  /// In ko, this message translates to:
  /// **'계획 값으로 되돌리기'**
  String get simResetTooltip;

  /// No description provided for @simSaveScenario.
  ///
  /// In ko, this message translates to:
  /// **'시나리오 저장'**
  String get simSaveScenario;

  /// No description provided for @simScenarioLoaded.
  ///
  /// In ko, this message translates to:
  /// **'시나리오 \"{name}\"를 불러왔어요'**
  String simScenarioLoaded(String name);

  /// No description provided for @simScenarioNameHint.
  ///
  /// In ko, this message translates to:
  /// **'시나리오 {n}'**
  String simScenarioNameHint(int n);

  /// No description provided for @simScenarioNameTitle.
  ///
  /// In ko, this message translates to:
  /// **'시나리오 이름'**
  String get simScenarioNameTitle;

  /// No description provided for @simScenarioSaved.
  ///
  /// In ko, this message translates to:
  /// **'시나리오 \"{name}\"를 저장했어요'**
  String simScenarioSaved(String name);

  /// No description provided for @simScenarioSavedFree.
  ///
  /// In ko, this message translates to:
  /// **'시나리오를 저장했어요 (무료는 1개까지)'**
  String get simScenarioSavedFree;

  /// No description provided for @simSliderAge.
  ///
  /// In ko, this message translates to:
  /// **'현재 나이'**
  String get simSliderAge;

  /// No description provided for @simSliderAssets.
  ///
  /// In ko, this message translates to:
  /// **'현재 순자산'**
  String get simSliderAssets;

  /// No description provided for @simSliderReturn.
  ///
  /// In ko, this message translates to:
  /// **'기대수익률 (실질, 연)'**
  String get simSliderReturn;

  /// 슬라이더 제목·비교표 행 라벨 공용
  ///
  /// In ko, this message translates to:
  /// **'월 저축액'**
  String get simSliderSaving;

  /// No description provided for @simSliderSpend.
  ///
  /// In ko, this message translates to:
  /// **'은퇴 후 월 생활비'**
  String get simSliderSpend;

  /// No description provided for @simSummaryReached.
  ///
  /// In ko, this message translates to:
  /// **'이미 FIRE 도달'**
  String get simSummaryReached;

  /// 시나리오 목록 부제
  ///
  /// In ko, this message translates to:
  /// **'100년 내 도달 어려움'**
  String get simSummaryUnreachable;

  /// S4 앱바 제목 (하단 탭 라벨과 동일 문구)
  ///
  /// In ko, this message translates to:
  /// **'시뮬레이션'**
  String get simTitle;

  /// No description provided for @snapAccountName.
  ///
  /// In ko, this message translates to:
  /// **'항목 이름'**
  String get snapAccountName;

  /// No description provided for @snapAccountsHeader.
  ///
  /// In ko, this message translates to:
  /// **'자산 항목'**
  String get snapAccountsHeader;

  /// No description provided for @snapAdd.
  ///
  /// In ko, this message translates to:
  /// **'추가'**
  String get snapAdd;

  /// No description provided for @snapAddAccount.
  ///
  /// In ko, this message translates to:
  /// **'항목 추가'**
  String get snapAddAccount;

  /// No description provided for @snapAssetClass.
  ///
  /// In ko, this message translates to:
  /// **'자산군'**
  String get snapAssetClass;

  /// No description provided for @snapCashflowHeader.
  ///
  /// In ko, this message translates to:
  /// **'이번 달 소득 · 지출 (선택)'**
  String get snapCashflowHeader;

  /// No description provided for @snapCashflowHint.
  ///
  /// In ko, this message translates to:
  /// **'적으면 저축률 추이를 볼 수 있어요'**
  String get snapCashflowHint;

  /// 첫 셋업 기본 항목 이름
  ///
  /// In ko, this message translates to:
  /// **'예금'**
  String get snapDefaultDeposits;

  /// No description provided for @snapDefaultLoans.
  ///
  /// In ko, this message translates to:
  /// **'대출'**
  String get snapDefaultLoans;

  /// No description provided for @snapDefaultOther.
  ///
  /// In ko, this message translates to:
  /// **'기타'**
  String get snapDefaultOther;

  /// No description provided for @snapDefaultPension.
  ///
  /// In ko, this message translates to:
  /// **'연금계좌'**
  String get snapDefaultPension;

  /// No description provided for @snapDefaultRealEstate.
  ///
  /// In ko, this message translates to:
  /// **'부동산'**
  String get snapDefaultRealEstate;

  /// No description provided for @snapDefaultStocks.
  ///
  /// In ko, this message translates to:
  /// **'주식'**
  String get snapDefaultStocks;

  /// No description provided for @snapDeltaDown.
  ///
  /// In ko, this message translates to:
  /// **'전월 대비 −{amount}'**
  String snapDeltaDown(String amount);

  /// No description provided for @snapDeltaUp.
  ///
  /// In ko, this message translates to:
  /// **'전월 대비 +{amount}'**
  String snapDeltaUp(String amount);

  /// No description provided for @snapExpense.
  ///
  /// In ko, this message translates to:
  /// **'지출'**
  String get snapExpense;

  /// No description provided for @snapGoHome.
  ///
  /// In ko, this message translates to:
  /// **'홈으로'**
  String get snapGoHome;

  /// No description provided for @snapIncome.
  ///
  /// In ko, this message translates to:
  /// **'세후 소득'**
  String get snapIncome;

  /// No description provided for @snapLiabilityHelper.
  ///
  /// In ko, this message translates to:
  /// **'{assetClass} · 부채'**
  String snapLiabilityHelper(String assetClass);

  /// No description provided for @snapLiabilitySwitch.
  ///
  /// In ko, this message translates to:
  /// **'부채 (음수로 계산)'**
  String get snapLiabilitySwitch;

  /// No description provided for @snapMilestonesHeader.
  ///
  /// In ko, this message translates to:
  /// **'마일스톤 달성'**
  String get snapMilestonesHeader;

  /// No description provided for @snapNetWorth.
  ///
  /// In ko, this message translates to:
  /// **'순자산'**
  String get snapNetWorth;

  /// No description provided for @snapNextRecordHint.
  ///
  /// In ko, this message translates to:
  /// **'다음 기록부터 궤도 비교가 시작돼요'**
  String get snapNextRecordHint;

  /// No description provided for @snapPrefilledHint.
  ///
  /// In ko, this message translates to:
  /// **'지난달 값이 채워져 있어요 — 바뀐 항목만 고치면 돼요'**
  String get snapPrefilledHint;

  /// No description provided for @snapRename.
  ///
  /// In ko, this message translates to:
  /// **'이름 변경'**
  String get snapRename;

  /// No description provided for @snapRenameConfirm.
  ///
  /// In ko, this message translates to:
  /// **'변경'**
  String get snapRenameConfirm;

  /// month는 1~12 숫자 문자열
  ///
  /// In ko, this message translates to:
  /// **'{month}월 기록 완료!'**
  String snapResultTitle(String month);

  /// No description provided for @snapTitle.
  ///
  /// In ko, this message translates to:
  /// **'자산 기록'**
  String get snapTitle;

  /// 구독 활성 시 열려 있는 기능 — 실제 동작하는 3종만 (미출시 기능 노출 금지)
  ///
  /// In ko, this message translates to:
  /// **'몬테카를로 상세 · 시나리오 비교 · 포트폴리오 편집'**
  String get subActiveBody;

  /// No description provided for @subActiveTitle.
  ///
  /// In ko, this message translates to:
  /// **'파이어덤 프리미엄 이용 중 🎉'**
  String get subActiveTitle;

  /// No description provided for @subInactiveBody.
  ///
  /// In ko, this message translates to:
  /// **'스토어에서 결제한 이력이 있다면 아래에서 복원해보세요'**
  String get subInactiveBody;

  /// No description provided for @subInactiveTitle.
  ///
  /// In ko, this message translates to:
  /// **'구독이 확인되지 않아요'**
  String get subInactiveTitle;

  /// No description provided for @subManageInStore.
  ///
  /// In ko, this message translates to:
  /// **'스토어에서 구독 관리'**
  String get subManageInStore;

  /// No description provided for @subManagedByStore.
  ///
  /// In ko, this message translates to:
  /// **'구독은 스토어 계정으로 관리돼요 — 플랜 변경과 해지는 스토어에서 할 수 있고, 해지해도 남은 기간까지는 프리미엄이 유지돼요.'**
  String get subManagedByStore;

  /// No description provided for @subPlanRenewal.
  ///
  /// In ko, this message translates to:
  /// **'플랜 · 다음 갱신일'**
  String get subPlanRenewal;

  /// No description provided for @subPlanRenewalSubtitle.
  ///
  /// In ko, this message translates to:
  /// **'스토어 구독 화면에서 확인할 수 있어요'**
  String get subPlanRenewalSubtitle;

  /// No description provided for @subRestore.
  ///
  /// In ko, this message translates to:
  /// **'구매 복원'**
  String get subRestore;

  /// No description provided for @subRestoreNotFound.
  ///
  /// In ko, this message translates to:
  /// **'복원할 구매를 찾지 못했어요'**
  String get subRestoreNotFound;

  /// No description provided for @subRestored.
  ///
  /// In ko, this message translates to:
  /// **'구매를 복원했어요'**
  String get subRestored;

  /// No description provided for @subStoreOpenFailed.
  ///
  /// In ko, this message translates to:
  /// **'스토어를 열 수 없어요 — 스토어 앱에서 구독을 확인해주세요'**
  String get subStoreOpenFailed;

  /// No description provided for @subTitle.
  ///
  /// In ko, this message translates to:
  /// **'구독 관리'**
  String get subTitle;

  /// upgrader 템플릿 토큰({{appName}} 등)이 플레이스홀더로 들어온다
  ///
  /// In ko, this message translates to:
  /// **'{appName}의 새 버전 {storeVersion}이 나왔어요. 지금 버전은 {installedVersion}이에요.'**
  String upgradeBody(
    String appName,
    String storeVersion,
    String installedVersion,
  );

  /// No description provided for @upgradeLater.
  ///
  /// In ko, this message translates to:
  /// **'나중에'**
  String get upgradeLater;

  /// No description provided for @upgradePrompt.
  ///
  /// In ko, this message translates to:
  /// **'지금 업데이트할까요?'**
  String get upgradePrompt;

  /// No description provided for @upgradeReleaseNotes.
  ///
  /// In ko, this message translates to:
  /// **'이번 업데이트 내용'**
  String get upgradeReleaseNotes;

  /// No description provided for @upgradeTitle.
  ///
  /// In ko, this message translates to:
  /// **'업데이트가 있어요'**
  String get upgradeTitle;

  /// No description provided for @upgradeUpdate.
  ///
  /// In ko, this message translates to:
  /// **'업데이트'**
  String get upgradeUpdate;

  /// No description provided for @widgetAheadOfPlan.
  ///
  /// In ko, this message translates to:
  /// **'계획보다 {count}개월 앞'**
  String widgetAheadOfPlan(int count);

  /// No description provided for @widgetBehindPlan.
  ///
  /// In ko, this message translates to:
  /// **'계획보다 {count}개월 뒤'**
  String widgetBehindPlan(int count);

  /// 홈 위젯 — 목표 도달 불가
  ///
  /// In ko, this message translates to:
  /// **'가정 점검이 필요해요'**
  String get widgetCheckAssumptions;

  /// No description provided for @widgetGoalReached.
  ///
  /// In ko, this message translates to:
  /// **'목표 도달!'**
  String get widgetGoalReached;

  /// 홈 위젯 — 계획 없음
  ///
  /// In ko, this message translates to:
  /// **'계획을 만들어보세요'**
  String get widgetNoPlan;

  /// No description provided for @widgetOnTrack.
  ///
  /// In ko, this message translates to:
  /// **'계획대로 진행 중'**
  String get widgetOnTrack;

  /// duration은 yearsMonthsLabel/monthsLabel 결과. 위젯에 금액은 넣지 않는다
  ///
  /// In ko, this message translates to:
  /// **'자유까지 {duration}'**
  String widgetUntilFree(String duration);

  /// No description provided for @yearsLabel.
  ///
  /// In ko, this message translates to:
  /// **'{count}년'**
  String yearsLabel(int count);

  /// No description provided for @yearsMonthsLabel.
  ///
  /// In ko, this message translates to:
  /// **'{years}년 {months}개월'**
  String yearsMonthsLabel(int years, int months);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
