import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';

/// 자산군 코드 목록 (B1 accounts.asset_class) — 드롭다운 표시 순서
const assetClassCodes = [
  'cash',
  'equity',
  'bond',
  'real_estate',
  'pension',
  'other',
];

/// 자산군 코드 → 라벨 (언어별)
String assetClassLabel(AppLocalizations l10n, String assetClass) =>
    switch (assetClass) {
      'cash' => l10n.acCash,
      'equity' => l10n.acEquity,
      'bond' => l10n.acBond,
      'real_estate' => l10n.acRealEstate,
      'pension' => l10n.acPension,
      _ => l10n.acOther,
    };

/// 자산군별 차트 색 (도넛/범례 공용)
const assetClassColors = {
  'equity': Color(0xFFE8590C),
  'cash': Color(0xFF2B8A3E),
  'bond': Color(0xFF1971C2),
  'real_estate': Color(0xFF9C36B5),
  'pension': Color(0xFFE8B90C),
  'other': Color(0xFF868E96),
};

Color assetClassColor(String assetClass) =>
    assetClassColors[assetClass] ?? assetClassColors['other']!;
