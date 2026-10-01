#!/bin/bash
# 스토어 스크린샷 촬영 — 언어별로 같은 데이터, 같은 화면을 담는다.
#
#   tool/screenshots.sh                 # 3개 언어 모두 (iPhone 6.5")
#   tool/screenshots.sh en              # 특정 언어만
#
# 결과: store_assets/screenshots/<prefix>/<locale>/NN_name.png
# 기기는 ASO 전용 시뮬레이터를 쓴다 (규격 고정 — 6.5" 1284×2778).
set -euo pipefail
cd "$(dirname "$0")/.."

DEVICE="${SHOT_DEVICE:-iPhone 14 Plus (ASO)}"
PREFIX="${SHOT_PREFIX:-iphone65}"

declare -a PAIRS=("ko:KRW" "en:USD" "ja:JPY")
if [ $# -gt 0 ]; then
  PAIRS=()
  for lang in "$@"; do
    case "$lang" in
      ko) PAIRS+=("ko:KRW") ;;
      en) PAIRS+=("en:USD") ;;
      ja) PAIRS+=("ja:JPY") ;;
      *) echo "알 수 없는 언어: $lang (ko|en|ja)" >&2; exit 1 ;;
    esac
  done
fi

UDID=$(xcrun simctl list devices available | grep -F "$DEVICE" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
[ -n "$UDID" ] || { echo "시뮬레이터를 찾을 수 없음: $DEVICE" >&2; exit 1; }
xcrun simctl boot "$UDID" 2>/dev/null || true

for pair in "${PAIRS[@]}"; do
  locale="${pair%%:*}"; currency="${pair##*:}"
  echo "▶ $locale / $currency"
  fvm flutter drive \
    --driver=test_driver/screenshots.dart \
    --target=integration_test/screenshots_test.dart \
    -d "$UDID" \
    --dart-define=SHOT_LOCALE="$locale" \
    --dart-define=SHOT_CURRENCY="$currency" \
    --dart-define=SHOT_PREFIX="$PREFIX"
done
echo "완료 — store_assets/screenshots/$PREFIX/"
