#!/bin/bash
# PostToolUse(Edit|Write) 훅: lib/engine/ 파일이 수정되면 엔진 골든 테스트를 실행한다.
# 실패 시 exit 2 → 실패 로그가 Claude에게 피드백되어 즉시 수정하도록 강제.
# (CLAUDE.md: 엔진은 엑셀 검증 기준 케이스 대비 오차 <0.1% 골든 테스트 유지)

f=$(jq -r '.tool_input.file_path // empty')
case "$f" in
  */lib/engine/*.dart) ;;
  *) exit 0 ;;
esac

cd "${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}" || exit 0

out=$(fvm flutter test test/engine 2>&1)
if [ $? -ne 0 ]; then
  {
    echo "lib/engine 변경으로 엔진 골든 테스트가 실패했습니다 (fvm flutter test test/engine):"
    echo "$out" | grep -vE '^$' | tail -40
  } >&2
  exit 2
fi
exit 0
