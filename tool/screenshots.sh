#!/bin/bash
# 스토어 스크린샷 촬영 — 통합 테스트가 화면을 넘기고, 바깥에서 simctl로 캡처한다.
#
#   tool/screenshots.sh            # ko·en·ja 모두
#   tool/screenshots.sh en         # 특정 언어만
#
# iOS에서 integration_test의 takeScreenshot은 드라이버 응답을 기다리다 멈추는 일이
# 있어 쓰지 않는다. 테스트는 각 화면에서 HOLD초 머물고, 이 스크립트가 그 중간 시점에
# `xcrun simctl io screenshot`으로 1284×2778 원본을 받는다.
set -euo pipefail
cd "$(dirname "$0")/.."

DEVICE="${SHOT_DEVICE:-iPhone 14 Plus (ASO)}"
PREFIX="${SHOT_PREFIX:-iphone65}"
HOLD="${SHOT_HOLD:-8}"
SCREENS=(01_home_orbit 02_simulation 03_assets 04_snapshot 05_settings)

declare -a PAIRS=("ko:KRW" "en:USD" "ja:JPY")
if [ $# -gt 0 ]; then
  PAIRS=()
  for lang in "$@"; do
    case "$lang" in
      ko) PAIRS+=("ko:KRW") ;; en) PAIRS+=("en:USD") ;; ja) PAIRS+=("ja:JPY") ;;
      *) echo "알 수 없는 언어: $lang (ko|en|ja)" >&2; exit 1 ;;
    esac
  done
fi

UDID=$(xcrun simctl list devices available | grep -F "$DEVICE" | head -1 | sed -E 's/.*\(([0-9A-F-]{36})\).*/\1/')
[ -n "$UDID" ] || { echo "시뮬레이터를 찾을 수 없음: $DEVICE" >&2; exit 1; }
xcrun simctl boot "$UDID" 2>/dev/null || true

for pair in "${PAIRS[@]}"; do
  locale="${pair%%:*}"; currency="${pair##*:}"
  out="store_assets/screenshots/$PREFIX/$locale"
  mkdir -p "$out"
  echo "▶ $locale / $currency"

  # 시뮬레이터는 profile/release 빌드를 지원하지 않아 디버그로 찍는다.
  # QA 토글은 FIREDOM_QA 플래그로만 켜지므로(디버그 자동 노출 아님) 화면에 찍히지 않는다.
  fvm flutter drive \
    --driver=test_driver/screenshots.dart \
    --target=integration_test/screenshots_test.dart \
    -d "$UDID" \
    --dart-define=SHOT_LOCALE="$locale" \
    --dart-define=SHOT_CURRENCY="$currency" \
    --dart-define=SHOT_PREFIX="$PREFIX" >/tmp/firedom_drive_$locale.log 2>&1 &
  drive_pid=$!

  # 첫 화면이 뜰 때까지 기다린다 (빌드·설치 포함)
  until grep -q "SHOT_READY ${SCREENS[0]}" /tmp/firedom_drive_$locale.log 2>/dev/null; do
    kill -0 $drive_pid 2>/dev/null || { echo "drive가 먼저 종료됨 — /tmp/firedom_drive_$locale.log 확인" >&2; exit 1; }
    sleep 3
  done

  for name in "${SCREENS[@]}"; do
    until grep -q "SHOT_READY $name" /tmp/firedom_drive_$locale.log 2>/dev/null; do
      kill -0 $drive_pid 2>/dev/null || break 2
      sleep 1
    done
    sleep 3                                   # 애니메이션이 가라앉을 시간
    xcrun simctl io "$UDID" screenshot --type=png "$out/$name.png" >/dev/null 2>&1
    echo "  $name"
  done
  wait $drive_pid 2>/dev/null || true
done
echo "완료 — store_assets/screenshots/$PREFIX/"
