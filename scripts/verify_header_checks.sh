#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-target}" # target | global

# 1) 대상 파일(헤더 통일 범위)
TARGETS=(
  "lib/features/home/presentation/home_screen.dart"
  "lib/features/journey/presentation/journey_list_screen.dart"
  "lib/features/journey/presentation/journey_inbox_screen.dart"
  "lib/features/profile/presentation/profile_screen.dart"
  "lib/features/journey/presentation/journey_compose_screen.dart"
  "lib/core/presentation/widgets/app_header.dart"
)

# 2) 제외 규칙(토큰/테마 파일)
EXCLUDES=( --glob '!**/app_colors.dart' --glob '!**/*theme*.dart' )

# 3) 검사 대상 선택
if [[ "$MODE" == "global" ]]; then
  SCAN_PATHS=( "lib/" )
else
  SCAN_PATHS=( "${TARGETS[@]}" )
fi

echo "[verify] mode=$MODE"

# 4) 파일 존재 체크(target 모드에서만)
if [[ "$MODE" == "target" ]]; then
  for f in "${TARGETS[@]}"; do
    if [[ ! -f "$f" ]]; then
      echo "[verify][ERROR] target file missing: $f"
      echo "-> Update scripts/verify_header_checks.sh TARGETS list."
      exit 1
    fi
  done
fi

echo "[verify] 1) AppBar 잔존 여부"
rg "AppBar\\(|SliverAppBar\\(|PreferredSize\\(" "${SCAN_PATHS[@]}" -n && {
  echo "[verify][ERROR] AppBar/Sliver/PreferredSize still exists in scan paths."
  exit 1
} || true

echo "[verify] 2) Colors.* 직접 사용"
rg -n "\\bColors\\." "${SCAN_PATHS[@]}" "${EXCLUDES[@]}" && {
  echo "[verify][ERROR] Colors.* detected."
  exit 1
} || true

echo "[verify] 3) Color(0x...) 사용"
rg -n "Color\\(0x[0-9A-Fa-f]{6,8}\\)" "${SCAN_PATHS[@]}" "${EXCLUDES[@]}" && {
  echo "[verify][ERROR] Color(0x...) detected."
  exit 1
} || true

echo "[verify] 4) withOpacity/withAlpha 사용"
rg -n "\\.withOpacity\\(|\\.withAlpha\\(" "${SCAN_PATHS[@]}" "${EXCLUDES[@]}" && {
  echo "[verify][ERROR] withOpacity/withAlpha detected."
  exit 1
} || true

echo "[verify] ✅ PASS"
