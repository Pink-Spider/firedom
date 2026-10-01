// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get acBond => 'Bonds';

  @override
  String get acCash => 'Cash & deposits';

  @override
  String get acEquity => 'Stocks';

  @override
  String get acOther => 'Other';

  @override
  String get acPension => 'Pension';

  @override
  String get acRealEstate => 'Real estate';

  @override
  String ageLabel(int age) {
    return 'Age $age';
  }

  @override
  String get ageSuffix => '';

  @override
  String get appTitle => 'Firedom';

  @override
  String get assetsAllocationEmpty =>
      'Record your assets to see the allocation';

  @override
  String get assetsAllocationTab => 'Allocation';

  @override
  String assetsAsOf(String ym) {
    return 'As of $ym';
  }

  @override
  String get assetsCashflowEmpty =>
      'Add income and expenses when recording to see your cash flow';

  @override
  String get assetsCashflowTab => 'Cash flow';

  @override
  String get assetsEditTarget => 'Edit target allocation';

  @override
  String get assetsIncome => 'Income';

  @override
  String assetsSaving(String amount) {
    return 'Saved $amount';
  }

  @override
  String assetsSavingRate(int percent) {
    return 'Saving rate $percent%';
  }

  @override
  String get assetsSavingRateNone => 'Saving rate —';

  @override
  String get assetsSetTarget => 'Set target allocation';

  @override
  String assetsTargetDeviation(int target, String delta) {
    return 'Target $target% · ${delta}pp';
  }

  @override
  String get assetsTargetDialogTitle => 'Target allocation (%)';

  @override
  String assetsTargetMatch(int target) {
    return 'Target $target% · on target';
  }

  @override
  String get assetsTitle => 'Assets';

  @override
  String cmpEarlier(String label, int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: '$years years',
      one: '1 year',
    );
    return '$label is $_temp0 earlier';
  }

  @override
  String get cmpReached => 'Already reached';

  @override
  String get cmpRowFireAge => 'FIRE age';

  @override
  String get cmpRowFireNumber => 'FIRE number';

  @override
  String get cmpRowReturn => 'Expected return';

  @override
  String get cmpSameAge => 'Same FIRE age';

  @override
  String get cmpTitle => 'Compare scenarios';

  @override
  String get cmpTrajectory => 'Trajectory';

  @override
  String get cmpUnreachable => 'Not reached';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get commonConfirm => 'OK';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonMasked => '●●●';

  @override
  String get commonNext => 'Next';

  @override
  String get commonSave => 'Save';

  @override
  String get currencyJpy => 'Japanese yen (JPY)';

  @override
  String get currencyKrw => 'Korean won (KRW)';

  @override
  String get currencyUsd => 'US dollar (USD)';

  @override
  String devAhead(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months months',
      one: '1 month',
    );
    return '$_temp0 ahead of plan';
  }

  @override
  String devBehind(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months months',
      one: '1 month',
    );
    return '$_temp0 behind plan — still catchable';
  }

  @override
  String get devNeedsReview => 'Assumptions need a review';

  @override
  String get devOnTrack => 'On track with the plan';

  @override
  String get devReached => 'Goal already reached!';

  @override
  String get disclaimerShort =>
      'For informational purposes only. Not investment advice.';

  @override
  String get disclaimerSimulation =>
      'This simulation is for informational purposes only and is not investment advice.';

  @override
  String errorGeneric(String error) {
    return 'Something went wrong: $error';
  }

  @override
  String get goalAlreadyFire => 'FIRE already reached!';

  @override
  String goalBridgeAfter(int age, String amount, String pension) {
    return 'After pension (age $age+): $amount/mo (spending − pension $pension)';
  }

  @override
  String goalBridgeBefore(int age, String amount) {
    return 'Before pension (to age $age): $amount/mo (full spending)';
  }

  @override
  String get goalCheckInputs => 'Check your inputs';

  @override
  String get goalExpectedReturn => 'Expected return (real)';

  @override
  String goalFireAge(int age) {
    return 'FIRE at age $age';
  }

  @override
  String get goalFireType => 'FIRE type';

  @override
  String get goalFireTypeBarista => 'Barista';

  @override
  String get goalFireTypeCoast => 'Coast';

  @override
  String get goalFireTypeCustom => 'Custom';

  @override
  String get goalFireTypeFat => 'Fat';

  @override
  String get goalFireTypeLean => 'Lean';

  @override
  String get goalInflation => 'Inflation';

  @override
  String get goalLifeExpectancy => 'Life expectancy';

  @override
  String get goalMonthlySaving => 'Monthly savings';

  @override
  String get goalNoActivePlan => 'No active plan';

  @override
  String get goalNominalReturn => 'Nominal return';

  @override
  String get goalPensionAmount => 'Expected monthly benefit';

  @override
  String goalPensionEffect(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: 'Including the pension brings FIRE $months months earlier',
      one: 'Including the pension brings FIRE 1 month earlier',
    );
    return '$_temp0';
  }

  @override
  String get goalPensionHint =>
      'Your expected monthly benefit is available from your public pension provider';

  @override
  String get goalPensionStartAge => 'Start age';

  @override
  String get goalPensionToggle => 'Include public pension';

  @override
  String goalPreviewSummary(String period, String amount) {
    return '$period from now · Target $amount';
  }

  @override
  String get goalPreviewTitle => 'With these assumptions';

  @override
  String goalRealReturnFisher(String rate) {
    return 'Real return $rate% (Fisher equation)';
  }

  @override
  String get goalRetireSpend => 'Monthly spending after retirement';

  @override
  String get goalReturnAggressive => 'Aggressive';

  @override
  String get goalReturnConservative => 'Conservative';

  @override
  String get goalReturnCustom => 'Custom';

  @override
  String get goalReturnNeutral => 'Neutral';

  @override
  String goalReturnSummary(String real, String vol) {
    return 'Real $real% · Volatility $vol%';
  }

  @override
  String get goalSaveButton => 'Save';

  @override
  String get goalSaveHint =>
      'Saving records a new revision and marks the change on the home trajectory chart.';

  @override
  String get goalSavedSnack => 'Plan updated — reflected in your trajectory';

  @override
  String get goalSwr => 'Safe withdrawal rate';

  @override
  String get goalTitle => 'Goal settings';

  @override
  String get homeComeback => 'Welcome back — just record this month';

  @override
  String get homeCreatePlan => 'Create a plan in 60 seconds';

  @override
  String homeFireProgress(String percent, String current, String target) {
    return 'FIRE progress $percent% · $current / $target';
  }

  @override
  String get homeFirstRecordHint =>
      'Your first record puts a dot on the trajectory';

  @override
  String get homeGoalSettingsTooltip => 'Goal settings';

  @override
  String get homeHideAmounts => 'Hide amounts';

  @override
  String homeMonthShort(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      '1': 'Jan',
      '2': 'Feb',
      '3': 'Mar',
      '4': 'Apr',
      '5': 'May',
      '6': 'Jun',
      '7': 'Jul',
      '8': 'Aug',
      '9': 'Sep',
      '10': 'Oct',
      '11': 'Nov',
      '12': 'Dec',
      'other': '$month',
    });
    return '$_temp0';
  }

  @override
  String homeMoreMilestones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count more reached',
      one: '+1 more reached',
    );
    return '$_temp0';
  }

  @override
  String get homeNoPlan => 'No plan yet';

  @override
  String get homePastRecords => 'Past records';

  @override
  String get homeReached => 'You\'ve reached your financial independence goal!';

  @override
  String get homeRecordButton => 'Record';

  @override
  String homeRecordPrompt(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      '1': 'January',
      '2': 'February',
      '3': 'March',
      '4': 'April',
      '5': 'May',
      '6': 'June',
      '7': 'July',
      '8': 'August',
      '9': 'September',
      '10': 'October',
      '11': 'November',
      '12': 'December',
      'other': 'this month',
    });
    return 'Record your assets for $_temp0?';
  }

  @override
  String get homeRecordSubtitle => 'Three minutes a month is enough';

  @override
  String get homeRecordedThisMonth =>
      'This month is recorded — see you next month';

  @override
  String get homeSavingRate => 'Saving rate';

  @override
  String get homeSavingRateHint =>
      'Add income and expenses when recording to see your saving-rate trend';

  @override
  String get homeSavingRateThisMonth => 'This month\'s saving rate';

  @override
  String get homeSecondRecordHint =>
      'Trajectory comparison starts from your second record';

  @override
  String get homeSettingsTooltip => 'Settings';

  @override
  String get homeShowAmounts => 'Show amounts';

  @override
  String get homeTapToEdit => 'Tap to edit';

  @override
  String get homeTrajectory => 'Trajectory';

  @override
  String get homeUnreachable => 'Hard to reach with the current assumptions';

  @override
  String homeUntilFireMonths(int months) {
    String _temp0 = intl.Intl.pluralLogic(
      months,
      locale: localeName,
      other: '$months months',
      one: '1 month',
    );
    return '$_temp0 to financial independence';
  }

  @override
  String homeUntilFireYearsMonths(int years, int months) {
    return '${years}y ${months}m to financial independence';
  }

  @override
  String get languageEn => 'English';

  @override
  String get languageJa => '日本語';

  @override
  String get languageKo => '한국어';

  @override
  String get languageSystem => 'System';

  @override
  String get lockBody =>
      'Authentication is required to protect your financial data';

  @override
  String get lockTitle => 'Firedom is locked';

  @override
  String get lockUnlock => 'Unlock';

  @override
  String get lockUnlockReason => 'Unlock Firedom';

  @override
  String get mcDepletionTitle => 'Age when assets run out';

  @override
  String get mcEndingAssetsTitle =>
      'Assets at life expectancy (in today\'s money)';

  @override
  String mcHeadline(String pct) {
    return 'Success rate $pct%';
  }

  @override
  String mcNoDepletion(int age) {
    return 'No scenario ran out of assets before age $age 👏';
  }

  @override
  String get mcP10 => 'Tough case (bottom 10%)';

  @override
  String get mcP50 => 'Median (p50)';

  @override
  String get mcP90 => 'Favorable case (top 10%)';

  @override
  String mcSummary(int runs, int successes, int age) {
    return 'In $successes of $runs market scenarios, assets lasted to age $age';
  }

  @override
  String get mcTitle => 'Success rate details';

  @override
  String monthsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months',
      one: '1 month',
    );
    return '$_temp0';
  }

  @override
  String get msFallback => 'Milestone reached! 🎉';

  @override
  String get msFire100 => 'FIRE goal reached! 🏆';

  @override
  String get msFire25 => '25% of your FIRE goal! 🔥';

  @override
  String get msFire50 => 'Halfway to your FIRE goal! 🔥';

  @override
  String get msFire75 => '75% of your FIRE goal! 🔥';

  @override
  String msNetWorth(String amount) {
    return 'Net worth passed $amount! 🎉';
  }

  @override
  String get msStreak12 => 'A full year in a row 🏆';

  @override
  String get msStreak3 => '3 months in a row 🔥';

  @override
  String get msStreak6 => '6 months in a row 🔥🔥';

  @override
  String get needPlanFirst => 'Create a plan on the Home tab first';

  @override
  String get onbAdjustExpense => 'Adjust spending';

  @override
  String get onbAlreadyFire => 'You have already reached FIRE';

  @override
  String get onbAssumptionMoneyBasis => 'Money basis';

  @override
  String get onbAssumptionMoneyBasisValue =>
      'All amounts in today\'s money (real)';

  @override
  String get onbAssumptionRealReturn => 'Annual real return';

  @override
  String onbAssumptionRealReturnValue(String rate) {
    return '$rate% (neutral preset)';
  }

  @override
  String get onbAssumptionRetireSpendValue =>
      'Same as current monthly spending';

  @override
  String get onbAssumptionSwr => 'Safe withdrawal rate (4% rule)';

  @override
  String get onbAssumptionsEditHint =>
      'These assumptions can be changed anytime in Goal settings.';

  @override
  String get onbAssumptionsTitle => 'Assumptions used';

  @override
  String onbAxisHundredMillion(int n) {
    return '${n}00M';
  }

  @override
  String get onbCongrats => 'Congratulations!';

  @override
  String get onbCurrencyLabel => 'Currency';

  @override
  String get onbErrorAgeRange => 'Enter an age between 1 and 85';

  @override
  String get onbErrorTooLarge => 'Amount is too large';

  @override
  String onbFireNumberBasis(String spend, String swr) {
    return 'Monthly spending $spend × $swr% rule';
  }

  @override
  String get onbFireNumberTitle => 'Required assets (FIRE number)';

  @override
  String get onbHeadlineUnreachable => 'Not reached within 100 years';

  @override
  String get onbHeadlineUnreachableHint =>
      'The slider below shows how extra savings change the result.';

  @override
  String get onbHeadlineUnreachablePrefix => 'Under current conditions';

  @override
  String onbHelperEquals(String amount) {
    return '= $amount';
  }

  @override
  String get onbNeedInputBack => 'Input needed — go back';

  @override
  String get onbNoSavingBody =>
      'Monthly spending is equal to or higher than income. A slightly lower spending figure is enough to build a plan.';

  @override
  String get onbNoSavingTitle =>
      'With no monthly savings,\nFIRE age cannot be calculated';

  @override
  String get onbSeeResult => 'See result';

  @override
  String get onbShowAssumptions => 'View assumptions';

  @override
  String onbSliderPlus(String amount) {
    return '+$amount';
  }

  @override
  String get onbStartPlan => 'Start this plan';

  @override
  String get onbStepAgeSubtitle => 'Your current age';

  @override
  String get onbStepAgeTitle => 'How old are you?';

  @override
  String get onbStepAssetsSubtitle =>
      'A rough number is fine — cash + holdings − debt';

  @override
  String get onbStepAssetsTitle => 'What is your net worth today?';

  @override
  String get onbStepExpenseSubtitle =>
      'A rough number is fine — including fixed costs';

  @override
  String get onbStepExpenseTitle => 'How much do you spend per month?';

  @override
  String get onbStepIncomeSubtitle => 'A rough number is fine — after tax';

  @override
  String get onbStepIncomeTitle => 'What is your monthly take-home income?';

  @override
  String onbUnitSegment(String unit) {
    return 'In $unit';
  }

  @override
  String onbWhatIfEffect(String amount, String age) {
    return '+$amount → $age';
  }

  @override
  String onbWhatIfEffectShortened(String amount, String age, String shortened) {
    return '+$amount → $age ($shortened sooner)';
  }

  @override
  String get onbWhatIfMoveSlider => 'Move the slider to compare';

  @override
  String get onbWhatIfStillUnreachable => 'Still out of reach';

  @override
  String get onbWhatIfTitle => 'What if you saved a little more each month?';

  @override
  String onbYearsLater(int years) {
    String _temp0 = intl.Intl.pluralLogic(
      years,
      locale: localeName,
      other: 'In about $years years',
      one: 'In about 1 year',
    );
    return '$_temp0';
  }

  @override
  String onbYearsMonthsLater(int years, int months) {
    return 'In about ${years}y ${months}m';
  }

  @override
  String get onbYourFireAge => 'Your FIRE age';

  @override
  String get paywallAlreadyPremium => 'You\'re already on Premium 🎉';

  @override
  String get paywallAutoRenewNote =>
      'After the free trial, the selected plan renews automatically. You can cancel anytime from your store account.';

  @override
  String get paywallBrowserFailed => 'Couldn\'t open the browser';

  @override
  String get paywallFallbackPricing =>
      '₩39,000/year — about ₩3,250/month · 34% off\n₩4,900/month · 7-day free trial';

  @override
  String get paywallFeatureMonteCarlo =>
      'Monte Carlo detail · asset depletion age distribution';

  @override
  String get paywallFeaturePortfolio => 'Edit portfolio weights freely';

  @override
  String get paywallFeatureScenarios =>
      'Unlimited scenario saves · side-by-side comparison';

  @override
  String get paywallNothingToRestore =>
      'No purchases to restore (billing not yet connected)';

  @override
  String get paywallPlanAnnual => 'Annual';

  @override
  String get paywallPlanLifetime => 'Lifetime';

  @override
  String get paywallPlanMonthly => 'Monthly';

  @override
  String paywallPlanPrice(String plan, String price) {
    return '$plan · $price';
  }

  @override
  String get paywallPlanWeekly => 'Weekly';

  @override
  String get paywallPrivacy => 'Privacy Policy';

  @override
  String get paywallPurchaseFailed => 'Payment was not completed';

  @override
  String get paywallRestore => 'Restore purchases';

  @override
  String get paywallRestored => 'Purchases restored';

  @override
  String get paywallStoreNotReady =>
      'Store billing is still being set up — coming soon';

  @override
  String get paywallSubscribe => 'Start subscription';

  @override
  String get paywallTeaserGeneric => 'See the risk side of your plan too';

  @override
  String paywallTeaserWithRate(String rate) {
    return 'Your plan\'s success rate is $rate% — see the full distribution and depletion risk';
  }

  @override
  String get paywallTerms => 'Terms of Use';

  @override
  String get paywallTitle => 'Firedom Premium';

  @override
  String get pfAdd => 'Add';

  @override
  String get pfAddAsset => 'Add asset class';

  @override
  String get pfApplyCta => 'Simulate with this mix';

  @override
  String get pfAssetCommodities => 'Commodities';

  @override
  String pfAssetCustom(String label) {
    return '$label · custom';
  }

  @override
  String get pfAssetGlobalDmEm => 'Developed + emerging markets';

  @override
  String get pfAssetGold => 'Gold';

  @override
  String get pfAssetKrEquity => 'Korea equity (KOSPI)';

  @override
  String get pfAssetKrTreasury => 'Korea treasury bonds';

  @override
  String get pfAssetKrwDeposit => 'KRW deposit';

  @override
  String pfAssetReference(String label) {
    return '$label · reference';
  }

  @override
  String get pfAssetReits => 'REITs';

  @override
  String get pfAssetSilver => 'Silver';

  @override
  String get pfAssetUsDow => 'Dow Jones';

  @override
  String get pfAssetUsNasdaq100 => 'Nasdaq-100';

  @override
  String get pfAssetUsSp500 => 'S&P 500';

  @override
  String get pfAssetUsTreasury => 'US Treasuries';

  @override
  String get pfAssetUsdCash => 'USD cash (FX)';

  @override
  String pfAssumedReturn(String ret) {
    return 'Assumed $ret%';
  }

  @override
  String pfAssumedReturnVol(String ret, String vol) {
    return 'Assumed $ret% · Volatility $vol%';
  }

  @override
  String get pfAssumptionsCaveat =>
      'Real (inflation-adjusted), annual geometric mean. Foreign assets are on a USD basis; KRW exchange-rate changes are not reflected. Volatility is a conservative, simplified estimate that ignores diversification between assets.';

  @override
  String get pfAssumptionsTitle => 'Assumptions used';

  @override
  String get pfCustomDialogTitle => 'Custom asset class';

  @override
  String get pfCustomError => 'Enter a name and an assumed return';

  @override
  String get pfCustomInput => 'Custom entry';

  @override
  String get pfCustomInputSubtitle =>
      'Enter your own asset class name and assumed return';

  @override
  String get pfCustomNameLabel => 'Asset class name';

  @override
  String get pfCustomNote =>
      'This is your own assumption — no source, for reference only';

  @override
  String get pfCustomReturnLabel => 'Assumed real return';

  @override
  String get pfCustomSource => 'Custom assumption (no source)';

  @override
  String get pfCustomVolLabel => 'Expected volatility';

  @override
  String get pfExampleAllWeather => 'All Weather';

  @override
  String get pfExampleBalanced => 'Balanced';

  @override
  String get pfExampleGrowth => 'Growth';

  @override
  String get pfExampleStable => 'Stable';

  @override
  String get pfExpectedReturn => 'Expected return (real)';

  @override
  String pfFooterNote(String disclaimer) {
    return 'Assumptions are based on long-term historical averages (sources under View assumptions) · $disclaimer';
  }

  @override
  String get pfHeadlineNeedTotal =>
      'Set the total to 100% to see the expected return';

  @override
  String get pfHintFree =>
      'Pick an example allocation to see how the result changes';

  @override
  String get pfHintPremium =>
      'Example allocation — you can change the weights (the total is kept at 100% automatically)';

  @override
  String get pfModePortfolio => 'Portfolio';

  @override
  String get pfModeSimple => 'Simple';

  @override
  String get pfPremiumBanner =>
      'Editing weights and adding asset classes is Premium — example allocations are free to try';

  @override
  String pfRealReturnVol(String ret, String vol) {
    return 'Real $ret% · Volatility $vol%';
  }

  @override
  String get pfRemoveAssetTooltip => 'Remove this asset class';

  @override
  String get pfResultAlreadyFire => 'Already at FIRE!';

  @override
  String pfResultDetail(String duration, String amount) {
    return 'In $duration · FIRE number $amount';
  }

  @override
  String pfResultFireAge(int age) {
    return 'FIRE at age $age';
  }

  @override
  String get pfResultLead => 'With this mix';

  @override
  String get pfResultNeedTotal => 'Set the total to 100% to see the result';

  @override
  String get pfResultUnreachable => 'Not reached within 100 years';

  @override
  String get pfShowAssumptions => 'View assumptions';

  @override
  String get pfSourceCommodities => 'Provisional — to be sourced (BCOM)';

  @override
  String get pfSourceGlobalDmEm =>
      'DMS World 1900–2010 real 5.5% · MSCI World/EM factsheets 2026-06';

  @override
  String get pfSourceGold =>
      'Damodaran 1928– real 2.5% · free-float era 1971– 4.9% (period-sensitive)';

  @override
  String get pfSourceKrEquity =>
      'Provisional — volatility from the DMS single-country equity real SD tier (2,000–2,300bp)';

  @override
  String get pfSourceKrTreasury =>
      'Provisional — conservative range between the DMS country average (60–90bp) and the US (150bp)';

  @override
  String get pfSourceKrwDeposit =>
      'Provisional — conservative real deposit-rate assumption; Bank of Korea statistics to be sourced';

  @override
  String get pfSourceReits => 'Provisional — to be sourced (FTSE EPRA Nareit)';

  @override
  String get pfSourceSilver =>
      'Provisional — assumed lower return and higher volatility than gold';

  @override
  String get pfSourceUsDow => 'Provisional — approximated from S&P 500';

  @override
  String get pfSourceUsNasdaq100 =>
      'Provisional — S&P 500 verified value + growth-stock spread assumption';

  @override
  String get pfSourceUsSp500 =>
      'Damodaran 1928–2025 · UBS/DMS 1900–2024 · Siegel 1802–2023';

  @override
  String get pfSourceUsTreasury =>
      'Damodaran 10-year 1928–2025 real 1.45% (USD basis, FX exposure not included)';

  @override
  String get pfSourceUsdCash =>
      '3-month T-bill proxy, Damodaran · DMS (USD basis, FX changes not reflected)';

  @override
  String get pfTagCustom => ' · custom';

  @override
  String get pfTagReference => ' · reference';

  @override
  String get pfTitle => 'Portfolio Mix';

  @override
  String pfTotalPercent(String total) {
    return 'Total $total%';
  }

  @override
  String get pfVolatilitySimple => 'Volatility (simplified)';

  @override
  String get pfWeightsTitle => 'Asset weights';

  @override
  String get reminderBody =>
      'Takes about 3 minutes — see where you stand against your plan';

  @override
  String get reminderChannelDescription =>
      'Once-a-month asset record notification (only for unrecorded months)';

  @override
  String get reminderChannelName => 'Monthly record reminder';

  @override
  String get reminderTitle => 'Your monthly asset record is waiting';

  @override
  String get settingsAbout => 'About';

  @override
  String get settingsAboutDisclaimer =>
      'Simulations in this app are for informational purposes only and are not investment advice.';

  @override
  String get settingsAppName => 'Firedom';

  @override
  String get settingsBackupErrorCorrupted => 'The backup file is corrupted';

  @override
  String get settingsBackupErrorNewerVersion =>
      'This backup was made with a newer version — update the app';

  @override
  String get settingsBackupErrorNotFiredom =>
      'This is not a Firedom backup file';

  @override
  String get settingsBackupErrorUnreadable => 'Could not read the backup file';

  @override
  String get settingsBackupErrorWrongPassphrase => 'Incorrect passphrase';

  @override
  String get settingsBackupExport => 'Export backup file';

  @override
  String get settingsBackupExportFailed => 'Could not create the backup file';

  @override
  String get settingsBackupExportSubtitle =>
      'Encrypted (AES-256) file — keep it in iCloud/Drive · no server';

  @override
  String get settingsBackupImport => 'Import backup';

  @override
  String get settingsBackupImportSubtitle =>
      'Replaces all current data with the backup';

  @override
  String get settingsBackupOpenFailed => 'Could not open the file';

  @override
  String get settingsBiometricSetupReason => 'Set up app lock';

  @override
  String get settingsBiometricSwitch => 'Biometric app lock';

  @override
  String get settingsBiometricSwitchSubtitle =>
      'Face ID / fingerprint when opening the app';

  @override
  String get settingsBiometricUnsupported =>
      'This device does not support biometric authentication';

  @override
  String get settingsCurrency => 'Currency';

  @override
  String settingsCurrencyChangeBody(String currency) {
    return 'Existing amounts are not converted — only the unit changes to $currency. Continue?';
  }

  @override
  String get settingsCurrencyChangeConfirm => 'Change';

  @override
  String get settingsCurrencyChangeTitle => 'Change currency';

  @override
  String get settingsCustomerId => 'Customer ID';

  @override
  String get settingsCustomerIdCopied => 'Customer ID copied';

  @override
  String settingsCustomerIdSubtitle(String id) {
    return '$id\nShare this when contacting support about your subscription · tap to copy';
  }

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsMaskSwitch => 'Hide amounts (●●●) by default';

  @override
  String get settingsMaskSwitchSubtitle =>
      'You can also toggle it with the eye icon on Home';

  @override
  String get settingsPassphraseConfirmLabel => 'Enter again';

  @override
  String get settingsPassphraseCreateTitle => 'Create backup passphrase';

  @override
  String get settingsPassphraseEnterTitle => 'Enter backup passphrase';

  @override
  String get settingsPassphraseLabel => 'Passphrase (8+ characters)';

  @override
  String get settingsPassphraseMismatch => 'Passphrases do not match';

  @override
  String get settingsPassphraseTooShort => 'Enter at least 8 characters';

  @override
  String get settingsPassphraseWarning =>
      'If you forget the passphrase it cannot be recovered — keep it somewhere safe';

  @override
  String get settingsPremiumActive =>
      'Active 🎉 — manage plan or cancel in Subscription';

  @override
  String get settingsPremiumInactive =>
      'Monte Carlo detail · portfolio allocation editing';

  @override
  String get settingsPremiumTitle => 'Firedom Premium';

  @override
  String get settingsPrivacy => 'Privacy Policy';

  @override
  String get settingsPrivacyBody =>
      'All financial data (assets and records) is stored only on this device, with no sign-up or account linking, and is never sent to a server. Deleting the app deletes the data as well.\n\nNotifications use local device notifications only (no push server).\n\nIf you subscribe, payment and subscription status are handled through the store (Apple/Google); no financial data such as assets or records is transmitted.\n\nTo announce new versions, only the store\'s public version information is looked up; no personal or financial data is transmitted.\n\nSimulation results in this app are for informational purposes only and are not investment advice.';

  @override
  String get settingsQaPremium => 'Simulate premium (QA)';

  @override
  String get settingsQaPremiumSubtitle =>
      'Test the paid gate without purchase — QA builds only';

  @override
  String get settingsReminderDay => 'Reminder day';

  @override
  String settingsReminderDayOfMonth(int day) {
    return 'Day $day of month';
  }

  @override
  String get settingsReminderLastDay => 'Last day of month';

  @override
  String get settingsReminderPermissionNeeded =>
      'Notification permission is required — allow it in system settings';

  @override
  String get settingsReminderSwitch => 'Monthly record reminder';

  @override
  String get settingsReminderSwitchSubtitle =>
      'Only for months not yet recorded · local notification';

  @override
  String get settingsReminderTime => 'Reminder time';

  @override
  String get settingsRestoreConfirmBody =>
      'All records, plans and settings on this device will be replaced with the backup. Continue?';

  @override
  String get settingsRestoreConfirmButton => 'Replace';

  @override
  String get settingsRestoreConfirmTitle => 'Replace everything?';

  @override
  String get settingsRestoreDone => 'Restore complete — data replaced';

  @override
  String get settingsRestoreFailed =>
      'Restore failed — check the file and passphrase';

  @override
  String get settingsSectionData => 'Data · About';

  @override
  String get settingsSectionDisplaySecurity => 'Display · Security';

  @override
  String get settingsSectionReminder => 'Record reminder';

  @override
  String get settingsSectionSubscription => 'Subscription';

  @override
  String get settingsTerms => 'Terms of Use';

  @override
  String get settingsTermsSubtitle => 'Apple standard license agreement (EULA)';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get shellAssets => 'Assets';

  @override
  String get shellHome => 'Home';

  @override
  String get shellRecord => 'Record';

  @override
  String get shellSimulation => 'Simulation';

  @override
  String simAxisAge(int age) {
    return '$age';
  }

  @override
  String get simCompare => 'Compare';

  @override
  String get simCompareLocked => 'Compare 🔒';

  @override
  String get simDefaultScenarioName => 'My scenario';

  @override
  String simFireAge(int age) {
    return 'FIRE at age $age';
  }

  @override
  String simHeadlineDetail(String period, String amount) {
    return 'In $period · FIRE number $amount';
  }

  @override
  String get simHeadlineReached => 'FIRE already reached!';

  @override
  String get simHeadlineUnreachable => 'Hard to reach within 100 years';

  @override
  String get simIntro =>
      'Changes here don\'t affect your plan — experiment freely';

  @override
  String get simLoadScenario => 'Load';

  @override
  String simLoadScenarioCount(int count) {
    return 'Load ($count)';
  }

  @override
  String simMcCaption(int age, int runs) {
    return 'Chance of assets lasting to age $age · $runs runs';
  }

  @override
  String get simMcDetail => 'View detailed distribution';

  @override
  String get simMcDetailLocked => 'View detailed distribution 🔒';

  @override
  String get simMcRun => 'Calculate success rate';

  @override
  String get simMcRunning => 'Computing 5,000 market scenarios…';

  @override
  String simMcSuccess(String pct) {
    return 'Success rate of this plan: $pct%';
  }

  @override
  String get simMcTitle => 'Will it hold up through market swings?';

  @override
  String get simNoScenarios => 'No saved scenarios';

  @override
  String get simOpenPortfolio => 'Build from a portfolio';

  @override
  String get simResetTooltip => 'Reset to plan values';

  @override
  String get simSaveScenario => 'Save scenario';

  @override
  String simScenarioLoaded(String name) {
    return 'Loaded scenario \"$name\"';
  }

  @override
  String simScenarioNameHint(int n) {
    return 'Scenario $n';
  }

  @override
  String get simScenarioNameTitle => 'Scenario name';

  @override
  String simScenarioSaved(String name) {
    return 'Saved scenario \"$name\"';
  }

  @override
  String get simScenarioSavedFree => 'Scenario saved (free keeps 1)';

  @override
  String get simSliderAge => 'Current age';

  @override
  String get simSliderAssets => 'Current net worth';

  @override
  String get simSliderReturn => 'Expected return (real, annual)';

  @override
  String get simSliderSaving => 'Monthly savings';

  @override
  String get simSliderSpend => 'Monthly spending after retirement';

  @override
  String get simSummaryReached => 'FIRE already reached';

  @override
  String get simSummaryUnreachable => 'Not reached within 100 years';

  @override
  String get simTitle => 'Simulation';

  @override
  String get snapAccountName => 'Item name';

  @override
  String get snapAccountsHeader => 'Asset items';

  @override
  String get snapAdd => 'Add';

  @override
  String get snapAddAccount => 'Add item';

  @override
  String get snapAssetClass => 'Asset class';

  @override
  String get snapCashflowHeader => 'This month\'s income · expenses (optional)';

  @override
  String get snapCashflowHint => 'Fill these in to see your saving-rate trend';

  @override
  String get snapDefaultDeposits => 'Deposits';

  @override
  String get snapDefaultLoans => 'Loans';

  @override
  String get snapDefaultOther => 'Other';

  @override
  String get snapDefaultPension => 'Pension account';

  @override
  String get snapDefaultRealEstate => 'Real estate';

  @override
  String get snapDefaultStocks => 'Stocks';

  @override
  String snapDeltaDown(String amount) {
    return '−$amount vs last month';
  }

  @override
  String snapDeltaUp(String amount) {
    return '+$amount vs last month';
  }

  @override
  String get snapExpense => 'Expenses';

  @override
  String get snapGoHome => 'Go to Home';

  @override
  String get snapIncome => 'After-tax income';

  @override
  String snapLiabilityHelper(String assetClass) {
    return '$assetClass · liability';
  }

  @override
  String get snapLiabilitySwitch => 'Liability (counted as negative)';

  @override
  String get snapMilestonesHeader => 'Milestones reached';

  @override
  String get snapNetWorth => 'Net worth';

  @override
  String get snapNextRecordHint =>
      'Trajectory comparison starts from your next record';

  @override
  String get snapPrefilledHint =>
      'Last month\'s values are filled in — only change what moved';

  @override
  String get snapRename => 'Rename';

  @override
  String get snapRenameConfirm => 'Rename';

  @override
  String snapResultTitle(String month) {
    String _temp0 = intl.Intl.selectLogic(month, {
      '1': 'January',
      '2': 'February',
      '3': 'March',
      '4': 'April',
      '5': 'May',
      '6': 'June',
      '7': 'July',
      '8': 'August',
      '9': 'September',
      '10': 'October',
      '11': 'November',
      '12': 'December',
      'other': 'Month',
    });
    return '$_temp0 recorded!';
  }

  @override
  String get snapTitle => 'Record assets';

  @override
  String get subActiveBody =>
      'Monte Carlo detail · scenario comparison · portfolio editing';

  @override
  String get subActiveTitle => 'Firedom Premium is active 🎉';

  @override
  String get subInactiveBody =>
      'If you purchased through the store before, try restoring below';

  @override
  String get subInactiveTitle => 'No active subscription found';

  @override
  String get subManageInStore => 'Manage in store';

  @override
  String get subManagedByStore =>
      'Subscriptions are managed by your store account — change or cancel the plan in the store. After cancelling, Premium stays active until the end of the current period.';

  @override
  String get subPlanRenewal => 'Plan · next renewal';

  @override
  String get subPlanRenewalSubtitle =>
      'Available on the store\'s subscription page';

  @override
  String get subRestore => 'Restore purchases';

  @override
  String get subRestoreNotFound => 'No purchases to restore were found';

  @override
  String get subRestored => 'Purchases restored';

  @override
  String get subStoreOpenFailed =>
      'Could not open the store — check your subscription in the store app';

  @override
  String get subTitle => 'Subscription';

  @override
  String upgradeBody(
    String appName,
    String storeVersion,
    String installedVersion,
  ) {
    return 'A new version of $appName ($storeVersion) is available. You have $installedVersion.';
  }

  @override
  String get upgradeLater => 'Later';

  @override
  String get upgradePrompt => 'Update now?';

  @override
  String get upgradeReleaseNotes => 'What\'s new';

  @override
  String get upgradeTitle => 'Update available';

  @override
  String get upgradeUpdate => 'Update';

  @override
  String widgetAheadOfPlan(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months ahead of plan',
      one: '1 month ahead of plan',
    );
    return '$_temp0';
  }

  @override
  String widgetBehindPlan(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months behind plan',
      one: '1 month behind plan',
    );
    return '$_temp0';
  }

  @override
  String get widgetCheckAssumptions => 'Assumptions need a review';

  @override
  String get widgetGoalReached => 'Goal reached!';

  @override
  String get widgetNoPlan => 'Create a plan';

  @override
  String get widgetOnTrack => 'On track';

  @override
  String widgetUntilFree(String duration) {
    return '$duration to freedom';
  }

  @override
  String yearsLabel(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years',
      one: '1 year',
    );
    return '$_temp0';
  }

  @override
  String yearsMonthsLabel(int years, int months) {
    return '${years}y ${months}m';
  }
}
