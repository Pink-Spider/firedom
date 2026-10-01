// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get acBond => '債券';

  @override
  String get acCash => '現金・預金';

  @override
  String get acEquity => '株式';

  @override
  String get acOther => 'その他';

  @override
  String get acPension => '年金';

  @override
  String get acRealEstate => '不動産';

  @override
  String ageLabel(int age) {
    return '$age歳';
  }

  @override
  String get ageSuffix => '歳';

  @override
  String get appTitle => 'Firedom';

  @override
  String get assetsAllocationEmpty => '資産を記録すると配分が見られます';

  @override
  String get assetsAllocationTab => '資産配分';

  @override
  String assetsAsOf(String ym) {
    return '$ym時点';
  }

  @override
  String get assetsCashflowEmpty => '記録時に収入と支出も入力するとキャッシュフローが見られます';

  @override
  String get assetsCashflowTab => 'キャッシュフロー';

  @override
  String get assetsEditTarget => '目標配分を変更';

  @override
  String get assetsIncome => '収入';

  @override
  String assetsSaving(String amount) {
    return '貯蓄 $amount';
  }

  @override
  String assetsSavingRate(int percent) {
    return '貯蓄率 $percent%';
  }

  @override
  String get assetsSavingRateNone => '貯蓄率 —';

  @override
  String get assetsSetTarget => '目標配分を設定';

  @override
  String assetsTargetDeviation(int target, String delta) {
    return '目標 $target% · $delta%pt';
  }

  @override
  String get assetsTargetDialogTitle => '目標配分（%）';

  @override
  String assetsTargetMatch(int target) {
    return '目標 $target% · 一致';
  }

  @override
  String get assetsTitle => '資産';

  @override
  String cmpEarlier(String label, int years) {
    return '$labelのほうが$years年早いです';
  }

  @override
  String get cmpReached => 'すでに達成';

  @override
  String get cmpRowFireAge => 'FIRE年齢';

  @override
  String get cmpRowFireNumber => '必要資産';

  @override
  String get cmpRowReturn => '期待リターン';

  @override
  String get cmpSameAge => 'FIRE年齢は同じです';

  @override
  String get cmpTitle => 'シナリオ比較';

  @override
  String get cmpTrajectory => '軌道';

  @override
  String get cmpUnreachable => '到達困難';

  @override
  String get commonCancel => 'キャンセル';

  @override
  String get commonClose => '閉じる';

  @override
  String get commonConfirm => 'OK';

  @override
  String get commonDelete => '削除';

  @override
  String get commonMasked => '●●●';

  @override
  String get commonNext => '次へ';

  @override
  String get commonSave => '保存';

  @override
  String get currencyJpy => '円 (JPY)';

  @override
  String get currencyKrw => '韓国ウォン (KRW)';

  @override
  String get currencyUsd => '米ドル (USD)';

  @override
  String devAhead(int months) {
    return '計画より$monthsか月先行中';
  }

  @override
  String devBehind(int months) {
    return '計画より$monthsか月遅れ — まだ追いつけます';
  }

  @override
  String get devNeedsReview => '前提の見直しが必要';

  @override
  String get devOnTrack => '計画どおり進行中';

  @override
  String get devReached => 'すでに目標到達！';

  @override
  String get disclaimerShort => '情報提供のみを目的としており、投資助言ではありません。';

  @override
  String get disclaimerSimulation => '本シミュレーションは情報提供を目的としており、投資助言ではありません。';

  @override
  String errorGeneric(String error) {
    return 'エラーが発生しました: $error';
  }

  @override
  String get goalAlreadyFire => 'すでにFIRE到達！';

  @override
  String goalBridgeAfter(int age, String amount, String pension) {
    return '受給後（$age歳〜）: 月 $amount（生活費 − 年金 $pension）';
  }

  @override
  String goalBridgeBefore(int age, String amount) {
    return '受給前（〜$age歳）: 月 $amount（生活費全額）';
  }

  @override
  String get goalCheckInputs => '入力内容を確認してください';

  @override
  String get goalExpectedReturn => '期待リターン（実質）';

  @override
  String goalFireAge(int age) {
    return 'FIRE年齢 $age歳';
  }

  @override
  String get goalFireType => 'FIREタイプ';

  @override
  String get goalFireTypeBarista => 'バリスタ';

  @override
  String get goalFireTypeCoast => 'コースト';

  @override
  String get goalFireTypeCustom => 'カスタム';

  @override
  String get goalFireTypeFat => 'ファット';

  @override
  String get goalFireTypeLean => 'リーン';

  @override
  String get goalInflation => 'インフレ率';

  @override
  String get goalLifeExpectancy => '想定寿命';

  @override
  String get goalMonthlySaving => '月間貯蓄額';

  @override
  String get goalNoActivePlan => '有効なプランがありません';

  @override
  String get goalNominalReturn => '名目リターン';

  @override
  String get goalPensionAmount => '見込み月額';

  @override
  String goalPensionEffect(int months) {
    return '年金を反映すると到達が$monthsか月早まります';
  }

  @override
  String get goalPensionHint => '見込み受給額は年金機関の案内で確認できます';

  @override
  String get goalPensionStartAge => '受給開始年齢';

  @override
  String get goalPensionToggle => '公的年金を反映';

  @override
  String goalPreviewSummary(String period, String amount) {
    return '$period後 · 目標資産 $amount';
  }

  @override
  String get goalPreviewTitle => 'この前提では';

  @override
  String goalRealReturnFisher(String rate) {
    return '実質リターン $rate%（フィッシャー方程式で計算）';
  }

  @override
  String get goalRetireSpend => '退職後の月間生活費';

  @override
  String get goalReturnAggressive => '積極';

  @override
  String get goalReturnConservative => '保守';

  @override
  String get goalReturnCustom => 'カスタム';

  @override
  String get goalReturnNeutral => '中立';

  @override
  String goalReturnSummary(String real, String vol) {
    return '実質 $real% · 変動率 $vol%';
  }

  @override
  String get goalSaveButton => '保存する';

  @override
  String get goalSaveHint => '保存すると新しいリビジョンとして記録され、ホームの軌道チャートに変更時点が表示されます。';

  @override
  String get goalSavedSnack => 'プランを更新しました — 軌道に反映されます';

  @override
  String get goalSwr => '安全引き出し率';

  @override
  String get goalTitle => '目標設定';

  @override
  String get homeComeback => 'おかえりなさい — 今月分だけ記録すれば大丈夫です';

  @override
  String get homeCreatePlan => '60秒でプランを作る';

  @override
  String homeFireProgress(String percent, String current, String target) {
    return 'FIRE進捗 $percent% · $current / $target';
  }

  @override
  String get homeFirstRecordHint => '最初の記録を残すと軌道上に点が付きます';

  @override
  String get homeGoalSettingsTooltip => '目標設定';

  @override
  String get homeHideAmounts => '金額を隠す';

  @override
  String homeMonthShort(String month) {
    return '$month月';
  }

  @override
  String homeMoreMilestones(int count) {
    return '他$count件達成';
  }

  @override
  String get homeNoPlan => 'まだプランがありません';

  @override
  String get homePastRecords => '過去の記録';

  @override
  String get homeReached => '経済的自由の目標に到達しました！';

  @override
  String get homeRecordButton => '記録する';

  @override
  String homeRecordPrompt(String month) {
    return '$month月の資産を記録しませんか？';
  }

  @override
  String get homeRecordSubtitle => '月に3分で十分です';

  @override
  String get homeRecordedThisMonth => '今月の記録は完了です — 次回は来月にお会いしましょう';

  @override
  String get homeSavingRate => '貯蓄率';

  @override
  String get homeSavingRateHint => '記録時に収入と支出も入力すると貯蓄率の推移が見られます';

  @override
  String get homeSavingRateThisMonth => '今月の貯蓄率';

  @override
  String get homeSecondRecordHint => '2回目の記録から軌道の比較が始まります';

  @override
  String get homeSettingsTooltip => '設定';

  @override
  String get homeShowAmounts => '金額を表示';

  @override
  String get homeTapToEdit => 'タップして編集';

  @override
  String get homeTrajectory => '軌道';

  @override
  String get homeUnreachable => '現在の前提では到達が難しいです';

  @override
  String homeUntilFireMonths(int months) {
    return '経済的自由まで$monthsか月';
  }

  @override
  String homeUntilFireYearsMonths(int years, int months) {
    return '経済的自由まで$years年$monthsか月';
  }

  @override
  String get languageEn => 'English';

  @override
  String get languageJa => '日本語';

  @override
  String get languageKo => '한국어';

  @override
  String get languageSystem => 'システム';

  @override
  String get lockBody => '財務データ保護のため認証が必要です';

  @override
  String get lockTitle => 'Firedomはロックされています';

  @override
  String get lockUnlock => 'ロック解除';

  @override
  String get lockUnlockReason => 'Firedomのロックを解除します';

  @override
  String get mcDepletionTitle => '資産が尽きる年齢の分布';

  @override
  String get mcEndingAssetsTitle => '期待寿命時点の資産分布（現在の貨幣価値）';

  @override
  String mcHeadline(String pct) {
    return '成功確率 $pct%';
  }

  @override
  String mcNoDepletion(int age) {
    return '期待寿命（$age歳）までに資産が尽きたシナリオはありません 👏';
  }

  @override
  String get mcP10 => '厳しい場合（下位10%）';

  @override
  String get mcP50 => '中央値 (p50)';

  @override
  String get mcP90 => 'うまくいった場合（上位10%）';

  @override
  String mcSummary(int runs, int successes, int age) {
    return '$runs通りの市場シナリオのうち$successes回、期待寿命$age歳まで資産が維持されました';
  }

  @override
  String get mcTitle => '成功確率の詳細';

  @override
  String monthsLabel(int count) {
    return '$countか月';
  }

  @override
  String get msFallback => 'マイルストーン達成！🎉';

  @override
  String get msFire100 => 'FIRE目標に到達！🏆';

  @override
  String get msFire25 => 'FIRE目標の25%達成！🔥';

  @override
  String get msFire50 => 'FIRE目標の半分達成！🔥';

  @override
  String get msFire75 => 'FIRE目標の75%達成！🔥';

  @override
  String msNetWorth(String amount) {
    return '純資産$amount突破！🎉';
  }

  @override
  String get msStreak12 => '1年連続記録 🏆';

  @override
  String get msStreak3 => '3か月連続記録 🔥';

  @override
  String get msStreak6 => '6か月連続記録 🔥🔥';

  @override
  String get needPlanFirst => 'まずホームでプランを作成してください';

  @override
  String get onbAdjustExpense => '支出を調整する';

  @override
  String get onbAlreadyFire => 'すでにFIREに到達しています';

  @override
  String get onbAssumptionMoneyBasis => '金額の基準';

  @override
  String get onbAssumptionMoneyBasisValue => 'すべて現在の貨幣価値（実質）';

  @override
  String get onbAssumptionRealReturn => '年間実質リターン';

  @override
  String onbAssumptionRealReturnValue(String rate) {
    return '$rate%（中立プリセット）';
  }

  @override
  String get onbAssumptionRetireSpendValue => '現在の月間支出と同じ';

  @override
  String get onbAssumptionSwr => '安全引き出し率（4%ルール）';

  @override
  String get onbAssumptionsEditHint => '前提は目標設定画面でいつでも変更できます。';

  @override
  String get onbAssumptionsTitle => '計算に使った前提';

  @override
  String onbAxisHundredMillion(int n) {
    return '$n億';
  }

  @override
  String get onbCongrats => 'おめでとうございます！';

  @override
  String get onbCurrencyLabel => '通貨';

  @override
  String get onbErrorAgeRange => '1〜85の年齢を入力してください';

  @override
  String get onbErrorTooLarge => '金額が大きすぎます';

  @override
  String onbFireNumberBasis(String spend, String swr) {
    return '月間支出 $spend × $swr%ルール基準';
  }

  @override
  String get onbFireNumberTitle => '必要資産（FIREナンバー）';

  @override
  String get onbHeadlineUnreachable => '100年以内の到達は難しいです';

  @override
  String get onbHeadlineUnreachableHint => '下のスライダーで貯蓄を増やすとどう変わるか確認できます。';

  @override
  String get onbHeadlineUnreachablePrefix => '今の条件では';

  @override
  String onbHelperEquals(String amount) {
    return '= $amount';
  }

  @override
  String get onbNeedInputBack => '入力が必要です — 戻る';

  @override
  String get onbNoSavingBody => '月の支出が収入と同じかそれ以上です。入力した支出を少し下げるとプランが作成できます。';

  @override
  String get onbNoSavingTitle => '現在貯蓄がないため\nFIRE年齢を計算できません';

  @override
  String get onbSeeResult => '結果を見る';

  @override
  String get onbShowAssumptions => '前提を見る';

  @override
  String onbSliderPlus(String amount) {
    return '+$amount';
  }

  @override
  String get onbStartPlan => 'このプランを始める';

  @override
  String get onbStepAgeSubtitle => '満年齢でお答えください';

  @override
  String get onbStepAgeTitle => '年齢を教えてください';

  @override
  String get onbStepAssetsSubtitle => 'おおよそで構いません — 預金＋保有資産−借入';

  @override
  String get onbStepAssetsTitle => '現在の純資産はいくらですか？';

  @override
  String get onbStepExpenseSubtitle => 'おおよそで構いません — 固定費を含む月の支出';

  @override
  String get onbStepExpenseTitle => '1か月の支出はいくらですか？';

  @override
  String get onbStepIncomeSubtitle => 'おおよそで構いません — 手取り額';

  @override
  String get onbStepIncomeTitle => '手取りの月収はいくらですか？';

  @override
  String onbUnitSegment(String unit) {
    return '$unit単位';
  }

  @override
  String onbWhatIfEffect(String amount, String age) {
    return '+$amount → $age';
  }

  @override
  String onbWhatIfEffectShortened(String amount, String age, String shortened) {
    return '+$amount → $age（$shortened短縮）';
  }

  @override
  String get onbWhatIfMoveSlider => 'スライダーを動かしてみてください';

  @override
  String get onbWhatIfStillUnreachable => 'まだ到達が難しいです';

  @override
  String get onbWhatIfTitle => '毎月もう少し貯蓄したら？';

  @override
  String onbYearsLater(int years) {
    return '約$years年後';
  }

  @override
  String onbYearsMonthsLater(int years, int months) {
    return '約$years年$monthsか月後';
  }

  @override
  String get onbYourFireAge => 'あなたのFIRE年齢';

  @override
  String get paywallAlreadyPremium => 'すでにプレミアムをご利用中です 🎉';

  @override
  String get paywallAutoRenewNote =>
      '無料体験終了後は選択したプランで自動更新されます。ストアのアカウントからいつでも解約できます。';

  @override
  String get paywallBrowserFailed => 'ブラウザを開けません';

  @override
  String get paywallFallbackPricing =>
      '年間プランは月額より割安です · 7日間無料体験\n価格はストアでご確認いただけます';

  @override
  String get paywallFeatureMonteCarlo => 'モンテカルロ詳細分布 · 資産枯渇年齢の分布';

  @override
  String get paywallFeaturePortfolio => 'ポートフォリオ比率の自由編集';

  @override
  String get paywallFeatureScenarios => 'シナリオ無制限保存 · 並べて比較';

  @override
  String get paywallNothingToRestore => '復元できる購入履歴がありません（連携準備中）';

  @override
  String get paywallPlanAnnual => '年間';

  @override
  String get paywallPlanLifetime => '永久';

  @override
  String get paywallPlanMonthly => '月間';

  @override
  String paywallPlanPrice(String plan, String price) {
    return '$plan · $price';
  }

  @override
  String get paywallPlanWeekly => '週間';

  @override
  String get paywallPrivacy => 'プライバシーポリシー';

  @override
  String get paywallPurchaseFailed => '決済が完了しませんでした';

  @override
  String get paywallRestore => '購入を復元';

  @override
  String get paywallRestored => '購入を復元しました';

  @override
  String get paywallStoreNotReady => 'ストア決済の準備中です — まもなく利用できます';

  @override
  String get paywallSubscribe => 'サブスクリプションを開始';

  @override
  String get paywallTeaserGeneric => 'プランのリスクまで確認できます';

  @override
  String paywallTeaserWithRate(String rate) {
    return 'あなたのプランの成功確率は$rate% — 詳細分布と資産枯渇リスクを確認できます';
  }

  @override
  String get paywallTerms => '利用規約';

  @override
  String get paywallTitle => 'Firedom プレミアム';

  @override
  String get pfAdd => '追加';

  @override
  String get pfAddAsset => '資産クラスを追加';

  @override
  String get pfApplyCta => 'この構成でシミュレーション';

  @override
  String get pfAssetCommodities => 'コモディティ';

  @override
  String pfAssetCustom(String label) {
    return '$label · 手入力';
  }

  @override
  String get pfAssetGlobalDmEm => '先進国・新興国株式';

  @override
  String get pfAssetGold => '金';

  @override
  String get pfAssetKrEquity => '韓国株式';

  @override
  String get pfAssetKrTreasury => '韓国国債';

  @override
  String get pfAssetKrwDeposit => 'ウォン預金';

  @override
  String pfAssetReference(String label) {
    return '$label · 参考値';
  }

  @override
  String get pfAssetReits => 'REIT';

  @override
  String get pfAssetSilver => '銀';

  @override
  String get pfAssetUsDow => 'ダウ平均';

  @override
  String get pfAssetUsNasdaq100 => 'ナスダック100';

  @override
  String get pfAssetUsSp500 => 'S&P500';

  @override
  String get pfAssetUsTreasury => '米国債';

  @override
  String get pfAssetUsdCash => '米ドル（外貨）';

  @override
  String pfAssumedReturn(String ret) {
    return '仮定 $ret%';
  }

  @override
  String pfAssumedReturnVol(String ret, String vol) {
    return '仮定 $ret% · ボラティリティ $vol%';
  }

  @override
  String get pfAssumptionsCaveat =>
      '実質（インフレ控除後）・年率幾何平均ベースです。海外資産はUSD建てで、ウォン為替変動は反映されていません。ボラティリティは資産間の分散効果を除いた保守的な簡易推定です。';

  @override
  String get pfAssumptionsTitle => '計算に使用した前提';

  @override
  String get pfCustomDialogTitle => '資産クラスを手入力';

  @override
  String get pfCustomError => '名前と仮定リターンを入力してください';

  @override
  String get pfCustomInput => '手入力';

  @override
  String get pfCustomInputSubtitle => '資産クラス名と仮定リターンを自分で入力します';

  @override
  String get pfCustomNameLabel => '資産クラス名';

  @override
  String get pfCustomNote => 'ご自身で入力した仮定です — 出典はなく、参考用としてのみお使いください';

  @override
  String get pfCustomReturnLabel => '仮定実質リターン';

  @override
  String get pfCustomSource => '手入力の仮定（出典なし）';

  @override
  String get pfCustomVolLabel => '想定ボラティリティ';

  @override
  String get pfExampleAllWeather => 'オールウェザー';

  @override
  String get pfExampleBalanced => 'バランス型';

  @override
  String get pfExampleGrowth => '成長型';

  @override
  String get pfExampleStable => '安定型';

  @override
  String get pfExpectedReturn => '期待リターン（実質）';

  @override
  String pfFooterNote(String disclaimer) {
    return '前提は過去の長期平均に基づきます（出典は「前提を見る」） · $disclaimer';
  }

  @override
  String get pfHeadlineNeedTotal => '合計を100%にすると期待リターンが計算されます';

  @override
  String get pfHintFree => '例示構成を選んで結果を試してみてください';

  @override
  String get pfHintPremium => '例示構成です — 比率は自由に変更できます（合計は自動で100%に保たれます）';

  @override
  String get pfModePortfolio => 'ポートフォリオ';

  @override
  String get pfModeSimple => 'シンプル';

  @override
  String get pfPremiumBanner => '比率の編集・資産クラスの追加はプレミアム機能です — 例示構成は自由にお試しいただけます';

  @override
  String pfRealReturnVol(String ret, String vol) {
    return '実質 $ret% · ボラティリティ $vol%';
  }

  @override
  String get pfRemoveAssetTooltip => 'この資産クラスを外す';

  @override
  String get pfResultAlreadyFire => 'すでにFIRE達成！';

  @override
  String pfResultDetail(String duration, String amount) {
    return '$duration後 · 必要資産 $amount';
  }

  @override
  String pfResultFireAge(int age) {
    return 'FIRE年齢 $age歳';
  }

  @override
  String get pfResultLead => 'この構成なら';

  @override
  String get pfResultNeedTotal => '合計を100%にすると結果が計算されます';

  @override
  String get pfResultUnreachable => '100年以内の到達は難しいです';

  @override
  String get pfShowAssumptions => '前提を見る';

  @override
  String get pfSourceCommodities => '暫定 — 後続ソーシング（BCOM）';

  @override
  String get pfSourceGlobalDmEm =>
      'DMS World 1900–2010 実質5.5% · MSCI World/EM ファクトシート 2026-06';

  @override
  String get pfSourceGold => 'Damodaran 1928– 実質2.5% · 変動相場期 1971– 4.9%（期間に敏感）';

  @override
  String get pfSourceKrEquity => '暫定 — ボラティリティはDMS単一国株式の実質SD階層（2,000〜2,300bp）';

  @override
  String get pfSourceKrTreasury => '暫定 — DMS国別平均（60〜90bp）〜米国（150bp）の保守的レンジ';

  @override
  String get pfSourceKrwDeposit => '暫定 — 実質預金金利の保守的な仮定、韓国銀行統計は後続ソーシング';

  @override
  String get pfSourceReits => '暫定 — 後続ソーシング（FTSE EPRA Nareit）';

  @override
  String get pfSourceSilver => '暫定 — 金より低リターン・高ボラティリティの仮定';

  @override
  String get pfSourceUsDow => '暫定 — S&P500で近似';

  @override
  String get pfSourceUsNasdaq100 => '暫定 — S&P500の検証値＋成長株スプレッドの仮定';

  @override
  String get pfSourceUsSp500 =>
      'Damodaran 1928–2025 · UBS/DMS 1900–2024 · Siegel 1802–2023';

  @override
  String get pfSourceUsTreasury =>
      'Damodaran 10年債 1928–2025 実質1.45%（USD建て、為替エクスポージャーは別）';

  @override
  String get pfSourceUsdCash => '3か月T-Billプロキシ、Damodaran・DMS（USD建て、為替変動は未反映）';

  @override
  String get pfTagCustom => ' · 手入力';

  @override
  String get pfTagReference => ' · 参考値';

  @override
  String get pfTitle => 'ポートフォリオ構成';

  @override
  String pfTotalPercent(String total) {
    return '合計 $total%';
  }

  @override
  String get pfVolatilitySimple => 'ボラティリティ（簡易）';

  @override
  String get pfWeightsTitle => '資産クラス比率';

  @override
  String get reminderBody => '3分で十分です — 計画に対する現在地を確認できます';

  @override
  String get reminderChannelDescription => '月1回の資産記録通知（未記録の月のみ）';

  @override
  String get reminderChannelName => '月次記録リマインダー';

  @override
  String get reminderTitle => '今月の資産記録、お忘れではありませんか？';

  @override
  String get settingsAbout => 'アプリ情報';

  @override
  String get settingsAboutDisclaimer =>
      '本アプリのシミュレーションは情報提供を目的としており、投資助言ではありません。';

  @override
  String get settingsAppName => 'Firedom';

  @override
  String get settingsBackupErrorCorrupted => 'バックアップファイルが破損しています';

  @override
  String get settingsBackupErrorNewerVersion =>
      'このバックアップは新しいバージョンで作成されました — アプリを更新してください';

  @override
  String get settingsBackupErrorNotFiredom => 'Firedomのバックアップファイルではありません';

  @override
  String get settingsBackupErrorUnreadable => 'バックアップファイルを読み込めません';

  @override
  String get settingsBackupErrorWrongPassphrase => 'パスフレーズが正しくありません';

  @override
  String get settingsBackupExport => 'バックアップファイルを書き出す';

  @override
  String get settingsBackupExportFailed => 'バックアップファイルを作成できませんでした';

  @override
  String get settingsBackupExportSubtitle =>
      '暗号化(AES-256)ファイル — iCloud/Driveに保管してください · サーバーなし';

  @override
  String get settingsBackupImport => 'バックアップを読み込む';

  @override
  String get settingsBackupImportSubtitle => '現在のデータをバックアップの内容で全て置き換えます';

  @override
  String get settingsBackupOpenFailed => 'ファイルを開けませんでした';

  @override
  String get settingsBiometricSetupReason => 'アプリロックを設定します';

  @override
  String get settingsBiometricSwitch => '生体認証アプリロック';

  @override
  String get settingsBiometricSwitchSubtitle => 'アプリを開くときにFace ID/指紋認証';

  @override
  String get settingsBiometricUnsupported => 'この端末は生体認証に対応していません';

  @override
  String get settingsCurrency => '通貨';

  @override
  String settingsCurrencyChangeBody(String currency) {
    return '入力済みの金額は換算されず、単位だけが$currencyに変わります。続けますか？';
  }

  @override
  String get settingsCurrencyChangeConfirm => '変更する';

  @override
  String get settingsCurrencyChangeTitle => '通貨の変更';

  @override
  String get settingsCustomerId => '顧客ID';

  @override
  String get settingsCustomerIdCopied => '顧客IDをコピーしました';

  @override
  String settingsCustomerIdSubtitle(String id) {
    return '$id\nサブスクリプションのお問い合わせ時にお知らせください · タップでコピー';
  }

  @override
  String get settingsLanguage => '言語';

  @override
  String get settingsMaskSwitch => '金額を隠す(●●●) 既定値';

  @override
  String get settingsMaskSwitchSubtitle => 'ホームの目のアイコンからも切り替えられます';

  @override
  String get settingsPassphraseConfirmLabel => 'もう一度入力';

  @override
  String get settingsPassphraseCreateTitle => 'バックアップのパスフレーズを作成';

  @override
  String get settingsPassphraseEnterTitle => 'バックアップのパスフレーズを入力';

  @override
  String get settingsPassphraseLabel => 'パスフレーズ (8文字以上)';

  @override
  String get settingsPassphraseMismatch => 'パスフレーズが一致しません';

  @override
  String get settingsPassphraseTooShort => '8文字以上入力してください';

  @override
  String get settingsPassphraseWarning => 'パスフレーズを忘れると復元できません — 安全な場所に保管してください';

  @override
  String get settingsPremiumActive => '利用中 🎉 — プラン変更・解約はサブスクリプション管理から';

  @override
  String get settingsPremiumInactive => 'モンテカルロ詳細分布 · ポートフォリオ比率の編集';

  @override
  String get settingsPremiumTitle => 'Firedom プレミアム';

  @override
  String get settingsPrivacy => 'プライバシーポリシー';

  @override
  String get settingsPrivacyBody =>
      'すべての財務データ（資産・記録）は会員登録や口座連携なしにこの端末だけに保存され、いかなる場合もサーバーへ送信されません。アプリを削除するとデータも一緒に削除されます。\n\n通知は端末のローカル通知のみを使用します（プッシュサーバーなし）。\n\nサブスクリプションを利用する場合、決済・購読状態の確認はストア（Apple/Google）を通じて処理され、その際も資産・記録などの財務データは送信されません。\n\n新バージョンの案内のためにストアの公開バージョン情報のみ照会し、その際も個人・財務データは送信されません。\n\n本アプリのシミュレーション結果は情報提供を目的としており、投資助言ではありません。';

  @override
  String get settingsQaPremium => 'プレミアム シミュレーション (QA)';

  @override
  String get settingsQaPremiumSubtitle => '購入なしで有料ゲートをテスト — QAビルド専用';

  @override
  String get settingsReminderDay => '通知日';

  @override
  String settingsReminderDayOfMonth(int day) {
    return '毎月$day日';
  }

  @override
  String get settingsReminderLastDay => '毎月末日';

  @override
  String get settingsReminderPermissionNeeded => '通知の許可が必要です — 端末の設定で許可してください';

  @override
  String get settingsReminderSwitch => '毎月の記録通知';

  @override
  String get settingsReminderSwitchSubtitle => '記録していない月だけお知らせします · ローカル通知';

  @override
  String get settingsReminderTime => '通知時刻';

  @override
  String get settingsRestoreConfirmBody =>
      'この端末のすべての記録・プラン・設定がバックアップの内容に置き換わります。続けますか？';

  @override
  String get settingsRestoreConfirmButton => '置き換える';

  @override
  String get settingsRestoreConfirmTitle => '全体置き換えの確認';

  @override
  String get settingsRestoreDone => '復元完了 — データを置き換えました';

  @override
  String get settingsRestoreFailed => '復元に失敗しました — ファイルとパスフレーズを確認してください';

  @override
  String get settingsSectionData => 'データ · 情報';

  @override
  String get settingsSectionDisplaySecurity => '表示 · セキュリティ';

  @override
  String get settingsSectionReminder => '記録リマインダー';

  @override
  String get settingsSectionSubscription => 'サブスクリプション';

  @override
  String get settingsTerms => '利用規約';

  @override
  String get settingsTermsSubtitle => 'Apple標準使用許諾契約(EULA)';

  @override
  String get settingsTheme => 'テーマ';

  @override
  String get settingsThemeDark => 'ダーク';

  @override
  String get settingsThemeLight => 'ライト';

  @override
  String get settingsTitle => '設定';

  @override
  String get shellAssets => '資産';

  @override
  String get shellHome => 'ホーム';

  @override
  String get shellRecord => '記録';

  @override
  String get shellSimulation => 'シミュレーション';

  @override
  String simAxisAge(int age) {
    return '$age歳';
  }

  @override
  String get simCompare => '比較';

  @override
  String get simCompareLocked => '比較 🔒';

  @override
  String get simDefaultScenarioName => 'マイシナリオ';

  @override
  String simFireAge(int age) {
    return 'FIRE年齢 $age歳';
  }

  @override
  String simHeadlineDetail(String period, String amount) {
    return '$period後 · 必要資産 $amount';
  }

  @override
  String get simHeadlineReached => 'すでにFIRE達成！';

  @override
  String get simHeadlineUnreachable => '100年以内の到達は難しそうです';

  @override
  String get simIntro => 'ここで変更した前提はプランに反映されません — 自由に試してみてください';

  @override
  String get simLoadScenario => '読み込む';

  @override
  String simLoadScenarioCount(int count) {
    return '読み込む ($count)';
  }

  @override
  String simMcCaption(int age, int runs) {
    return '期待寿命$age歳まで資産が残る確率 · $runs回のシミュレーション';
  }

  @override
  String get simMcDetail => '詳細な分布を見る';

  @override
  String get simMcDetailLocked => '詳細な分布を見る 🔒';

  @override
  String get simMcRun => '成功確率を計算';

  @override
  String get simMcRunning => '5,000通りの市場シナリオを計算しています…';

  @override
  String simMcSuccess(String pct) {
    return 'このプランの成功確率 $pct%';
  }

  @override
  String get simMcTitle => '市場の変動の中でも成功するでしょうか？';

  @override
  String get simNoScenarios => '保存されたシナリオはありません';

  @override
  String get simOpenPortfolio => 'ポートフォリオから設定';

  @override
  String get simResetTooltip => 'プランの値に戻す';

  @override
  String get simSaveScenario => 'シナリオを保存';

  @override
  String simScenarioLoaded(String name) {
    return 'シナリオ「$name」を読み込みました';
  }

  @override
  String simScenarioNameHint(int n) {
    return 'シナリオ $n';
  }

  @override
  String get simScenarioNameTitle => 'シナリオ名';

  @override
  String simScenarioSaved(String name) {
    return 'シナリオ「$name」を保存しました';
  }

  @override
  String get simScenarioSavedFree => 'シナリオを保存しました（無料版は1件まで）';

  @override
  String get simSliderAge => '現在の年齢';

  @override
  String get simSliderAssets => '現在の純資産';

  @override
  String get simSliderReturn => '期待リターン（実質・年率）';

  @override
  String get simSliderSaving => '月々の貯蓄額';

  @override
  String get simSliderSpend => '退職後の月々の生活費';

  @override
  String get simSummaryReached => 'すでにFIRE達成';

  @override
  String get simSummaryUnreachable => '100年以内の到達は困難';

  @override
  String get simTitle => 'シミュレーション';

  @override
  String get snapAccountName => '項目名';

  @override
  String get snapAccountsHeader => '資産項目';

  @override
  String get snapAdd => '追加';

  @override
  String get snapAddAccount => '項目を追加';

  @override
  String get snapAssetClass => '資産クラス';

  @override
  String get snapCashflowHeader => '今月の収入・支出（任意）';

  @override
  String get snapCashflowHint => '入力すると貯蓄率の推移が見られます';

  @override
  String get snapDefaultDeposits => '預金';

  @override
  String get snapDefaultLoans => 'ローン';

  @override
  String get snapDefaultOther => 'その他';

  @override
  String get snapDefaultPension => '年金口座';

  @override
  String get snapDefaultRealEstate => '不動産';

  @override
  String get snapDefaultStocks => '株式';

  @override
  String snapDeltaDown(String amount) {
    return '前月比 −$amount';
  }

  @override
  String snapDeltaUp(String amount) {
    return '前月比 +$amount';
  }

  @override
  String get snapExpense => '支出';

  @override
  String get snapGoHome => 'ホームへ';

  @override
  String get snapIncome => '税引後の収入';

  @override
  String snapLiabilityHelper(String assetClass) {
    return '$assetClass · 負債';
  }

  @override
  String get snapLiabilitySwitch => '負債（マイナスで計算）';

  @override
  String get snapMilestonesHeader => 'マイルストーン達成';

  @override
  String get snapNetWorth => '純資産';

  @override
  String get snapNextRecordHint => '次の記録から軌道の比較が始まります';

  @override
  String get snapPrefilledHint => '先月の値が入っています — 変わった項目だけ直してください';

  @override
  String get snapRename => '名前を変更';

  @override
  String get snapRenameConfirm => '変更';

  @override
  String snapResultTitle(String month) {
    return '$month月の記録が完了！';
  }

  @override
  String get snapTitle => '資産の記録';

  @override
  String get subActiveBody => 'モンテカルロ詳細 · シナリオ比較 · ポートフォリオ編集';

  @override
  String get subActiveTitle => 'Firedom プレミアム利用中 🎉';

  @override
  String get subInactiveBody => 'ストアで購入した履歴があれば、下から復元をお試しください';

  @override
  String get subInactiveTitle => 'サブスクリプションが確認できません';

  @override
  String get subManageInStore => 'ストアで管理する';

  @override
  String get subManagedByStore =>
      'サブスクリプションはストアのアカウントで管理されます — プラン変更と解約はストアで行え、解約しても残りの期間はプレミアムが維持されます。';

  @override
  String get subPlanRenewal => 'プラン · 次回更新日';

  @override
  String get subPlanRenewalSubtitle => 'ストアのサブスクリプション画面で確認できます';

  @override
  String get subRestore => '購入を復元';

  @override
  String get subRestoreNotFound => '復元できる購入が見つかりませんでした';

  @override
  String get subRestored => '購入を復元しました';

  @override
  String get subStoreOpenFailed => 'ストアを開けません — ストアアプリでサブスクリプションを確認してください';

  @override
  String get subTitle => 'サブスクリプション管理';

  @override
  String upgradeBody(
    String appName,
    String storeVersion,
    String installedVersion,
  ) {
    return '$appNameの新しいバージョン$storeVersionが公開されました。現在のバージョンは$installedVersionです。';
  }

  @override
  String get upgradeLater => 'あとで';

  @override
  String get upgradePrompt => '今すぐアップデートしますか？';

  @override
  String get upgradeReleaseNotes => 'アップデート内容';

  @override
  String get upgradeTitle => 'アップデートがあります';

  @override
  String get upgradeUpdate => 'アップデート';

  @override
  String widgetAheadOfPlan(int count) {
    return '計画より$countか月先行';
  }

  @override
  String widgetBehindPlan(int count) {
    return '計画より$countか月遅れ';
  }

  @override
  String get widgetCheckAssumptions => '前提の見直しが必要です';

  @override
  String get widgetGoalReached => '目標達成！';

  @override
  String get widgetNoPlan => 'プランを作成しましょう';

  @override
  String get widgetOnTrack => '計画どおり進行中';

  @override
  String widgetUntilFree(String duration) {
    return '自由まで$duration';
  }

  @override
  String yearsLabel(int count) {
    return '$count年';
  }

  @override
  String yearsMonthsLabel(int years, int months) {
    return '$years年$monthsか月';
  }
}
