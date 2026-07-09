import 'package:flutter/material.dart';

/// 자산군 코드 → 라벨 (B1 accounts.asset_class)
const assetClassLabels = {
  'cash': '현금/예금',
  'equity': '주식',
  'bond': '채권',
  'real_estate': '부동산',
  'pension': '연금',
  'other': '기타',
};

String assetClassLabel(String assetClass) =>
    assetClassLabels[assetClass] ?? '기타';

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
