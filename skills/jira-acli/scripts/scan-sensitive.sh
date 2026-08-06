#!/usr/bin/env bash
# scan-sensitive.sh — Jira에 나갈 초안 문장에서 "내부 개발 정보" 흔적을 찾아낸다.
#
# 사용법:
#   scan-sensitive.sh <파일경로>
#   cat draft.txt | scan-sensitive.sh
#
# 종료 코드:
#   0  걸린 것 없음
#   1  의심 문구 발견 (고친 뒤 다시 실행)
#   2  사용법 오류
#
# 주의: 이 검사기는 references/redaction.md 의 "두 번째 그물"입니다.
#       통과했다고 해서 안전이 보증되는 것이 아닙니다. 최종 판단은 redaction.md 의 칸 규칙입니다.
#       바꾸지 않고 "찾아내기만" 합니다 — 문장을 다시 쓰는 것은 사람(또는 모델)의 몫입니다.

# 셸 안전 규칙 (이 파일을 고치는 사람에게):
#   - `set -e` 를 켜지 않는다. 이 스크립트의 정상 경로(=아무것도 못 찾음)는 grep 이 exit 1 을 내는
#     경로다. `set -e` + 가드 없는 명령치환이면 "깨끗함"이라는 원하는 결과에서 스크립트가 조용히
#     죽고, 정상 실행과 도중 사망을 구분할 수 없게 된다.
#   - 모든 명령치환(`X="$(...)"`)은 `|| true` 등으로 종료코드를 반드시 흡수하고, 값으로 판정한다.
#   - 결과는 항상 한 줄로 출력한다. 침묵은 결과가 아니다 — 못 찾았으면 "못 찾았다"고 말하고 0 으로 끝낸다.
set -uo pipefail

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  sed -n '2,14p' "$0"
  exit 0
fi

cleanup=""
if [ "$#" -ge 1 ]; then
  SRC="$1"
  if [ ! -f "$SRC" ]; then
    echo "scan-sensitive.sh: 파일을 찾을 수 없습니다: $SRC" >&2
    exit 2
  fi
else
  SRC="$(mktemp -t jira-acli-scan)" || exit 2
  cleanup="$SRC"
  cat > "$SRC"
fi
if [ -n "$cleanup" ]; then trap 'rm -f "$cleanup"' EXIT; fi

FOUND=0

report() {
  FOUND=$((FOUND + 1))
  printf '\n[%s]\n%s\n' "$1" "$2"
}

check() {   # check <라벨> <ERE 패턴> [i]
  local label="$1" pat="$2" ic="${3:-}" out=""
  if [ "$ic" = "i" ]; then
    out="$(grep -nEi -- "$pat" "$SRC" 2>/dev/null || true)"
  else
    out="$(grep -nE -- "$pat" "$SRC" 2>/dev/null || true)"
  fi
  if [ -n "$out" ]; then report "$label" "$out"; fi
  return 0
}

# 1. 절대 파일 경로 (홈/시스템 디렉터리)
check "절대 파일 경로" '(^|[^A-Za-z0-9])/(Users|home|root|Volumes|mnt|srv|opt|private|tmp|var/(www|log|tmp))/[A-Za-z0-9._-]'
check "윈도우 경로" '[A-Za-z]:\\+[A-Za-z0-9._ -]+\\'

# 2. 소스 파일 / 코드 위치
check "소스 파일 경로" '[A-Za-z0-9_./-]+\.(py|js|jsx|ts|tsx|go|java|kt|rb|php|rs|c|cc|cpp|h|hpp|cs|swift|scala|sql|sh|bash|zsh|yml|yaml|toml|ini|env|lock|gradle)([:#][0-9]+)?([^A-Za-z0-9]|$)'
check "코드 심볼 표기" '\b[A-Za-z_][A-Za-z0-9_]*\.[a-z_][A-Za-z0-9_]*\(\)'

# 3. 내부 호스트 / 사설 IP / 포트 / API 경로
check "로컬 호스트" '(localhost|127\.0\.0\.1|0\.0\.0\.0)(:[0-9]{2,5})?'
check "사설 IP 대역" '\b(10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3})\b'
check "내부 도메인" '[A-Za-z0-9-]+\.(internal|local|localdomain|intranet|corp|lan|test)\b'
check "호스트:포트" '\b[a-z0-9][a-z0-9.-]*:[0-9]{4,5}\b'
check "API 엔드포인트 / 내부 API 호스트" '(/rest/api/|atl-paas\.net)'

# 4. 브랜치 / PR / 커밋
check "브랜치 이름" '\b(feature|feat|fix|hotfix|bugfix|release|chore|refactor|develop)/[A-Za-z0-9._/-]+'
check "PR / MR 번호" '\b(PR|MR|pull request|merge request)[[:space:]#-]*[0-9]+' i
check "커밋 표기" '(commit|커밋|sha)[[:space:]:#=]*[0-9a-f]{7,40}' i

# 4b. 커밋 해시로 보이는 토큰 (7~40자, 16진수, 숫자와 a-f 를 모두 포함)
hexout="$(
  awk '{
    n = split($0, w, /[^0-9A-Za-z]/)
    for (i = 1; i <= n; i++) {
      t = tolower(w[i])
      if (length(t) >= 7 && length(t) <= 40 && t ~ /^[0-9a-f]+$/ && t ~ /[a-f]/ && t ~ /[0-9]/) {
        printf "%d:%s\n", FNR, w[i]
      }
    }
  }' "$SRC" 2>/dev/null || true
)"
if [ -n "$hexout" ]; then report "커밋 해시로 보이는 값" "$hexout"; fi

# 5. 스택트레이스 / 예외 / 로그 줄
check "스택트레이스" 'Traceback \(most recent call last\)|File "[^"]+", line [0-9]+|^[[:space:]]+at [A-Za-z0-9_.$]+\('
check "예외 클래스명" '\b[A-Za-z_][A-Za-z0-9_]*(Exception|Error)\b'
check "로그 레벨 표기" '(\[(DEBUG|TRACE|INFO|WARN|WARNING|ERROR|FATAL)\]|^[0-9]{4}-[0-9]{2}-[0-9]{2}[T ][0-9]{2}:[0-9]{2}:[0-9]{2})'

# 6. 자격증명 / 비밀값
check "자격증명 키워드" '(token|api[-_ ]?key|apikey|secret|password|passwd|credential|authorization|private[_-]?key)[[:space:]]*[:=]' i
check "Bearer 토큰" 'bearer[[:space:]]+[A-Za-z0-9._~+/-]{10,}' i
check "개인 키 블록" '-----BEGIN [A-Z ]*PRIVATE KEY-----'
check "알려진 토큰 접두어" '\b(xox[baprs]-|ghp_|gho_|github_pat_|AKIA[0-9A-Z]{6,})'

# 7. 환경변수 / 셸 흔적
check "환경변수 대입" '\b[A-Z][A-Z0-9_]{3,}=[^[:space:]]+'
check "셸 프롬프트/명령" '(^\$[[:space:]]|^[a-z_][a-z0-9_-]*@[A-Za-z0-9._-]+:[~/]|\bgit[[:space:]]+(commit|push|pull|checkout|rebase|merge|log|diff|clone)\b|\bnpm[[:space:]]+run\b|\bdocker[[:space:]]+(run|exec|compose)\b|\b(kubectl|ssh|scp)[[:space:]]+)'

if [ "$FOUND" -gt 0 ]; then
  printf '\n----\n검사 결과: 의심 문구 %d종 발견. 위 부분을 지우거나 업무 언어로 다시 쓴 뒤 다시 실행하세요.\n' "$FOUND"
  printf '규칙: references/redaction.md\n'
  exit 1
fi

printf '검사 결과: 걸린 것 없음. (이것은 안전 보증이 아닙니다 — references/redaction.md 의 칸 규칙으로 최종 확인하세요.)\n'
exit 0
