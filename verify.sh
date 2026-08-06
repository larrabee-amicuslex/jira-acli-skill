#!/usr/bin/env bash
# verify.sh — jira-acli 스킬 트리 재검증 스크립트 (읽기 전용, 네트워크/Jira 호출 없음)
#
#   bash verify.sh
#
# 종료 코드: 0 = 전부 통과, 1 = 하나 이상 실패
#
# 검사 축:
#   S  구조   — 있어야 할 파일이 있고 비어 있지 않은가
#   G  일반성 — 특정 사이트/프로젝트/계정/경로가 박혀 있지 않은가
#   N  금지   — 스킬이 만들어내는 명령 템플릿에 위험한 형태가 없는가 (CLI 함정)
#   P  존재   — 반드시 있어야 할 절차/명령이 실제로 문서에 있는가
#   F  기능   — 민감정보 검사기가 실제로 동작하는가
#
# 일반성 검사에 자기 조직의 고유 문자열(회사명·도메인·프로젝트 키 등)을 더하려면, 그 값을
# 이 파일에 적지 말고 환경변수로 넘긴다. 이 파일 자체가 배포물이므로 여기에 적는 순간
# 그 값이 함께 배포된다:
#
#   SKILL_FORBIDDEN='mycorp|MYPROJ|myname' bash verify.sh

# 셸 안전 규칙 (이 파일을 고치는 사람에게):
#   - `set -e` 를 켜지 않는다. 검사 스크립트는 개별 검사가 실패해도 끝까지 돌면서 전부 보고해야 한다.
#     `set -e` 는 첫 실패에서 죽어 나머지 검사를 침묵시키므로, "전부 통과"와 "도중 사망"이 구분되지 않는다.
#   - 모든 명령치환(`X="$(...)"`)은 `|| true` 등으로 종료코드를 흡수하고 값으로 판정한다.
#     특히 `grep -v` / `grep -c` 처럼 반전 검사는 깨끗한 경우에 exit 1 을 낸다 — 정상 경로가 곧 위험 경로다.
#   - 모든 검사는 PASS 또는 FAIL 을 반드시 한 줄 출력한다. 침묵은 결과가 아니다.
#   - 이 두 규칙은 아래 S7 검사로 기계 검증된다.
set -uo pipefail

#   - 이 스크립트는 **어느 디렉터리에서 실행해도** 같은 결과를 내야 한다. 내부에서 자기 자신이나
#     스킬 파일을 가리킬 때는 반드시 아래 절대경로 변수($SELF/$SKILL)를 쓴다. 상대경로 'verify.sh' 를
#     그대로 쓰면 다른 cwd 에서 파일을 못 찾고, grep 은 조용히 빈 결과를 내 "통과"로 오판된다.
#     이 규칙은 아래 D9 검사로 기계 검증된다.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SELF="$ROOT/verify.sh"
SKILL="$ROOT/skills/jira-acli"
DOCS="$ROOT/README.md"       # M 축(설치 문자열·순서)은 영어판 기준
DOCS_ALL="$ROOT/README.md $ROOT/README.ko.md"   # 배포되는 모든 문서 — 일반성(G) 검사 대상
FAIL=0
PASSN=0

pass() { PASSN=$((PASSN+1)); printf 'PASS  %s\n' "$1"; }
fail() { FAIL=$((FAIL+1));   printf 'FAIL  %s\n' "$1"; if [ -n "${2:-}" ]; then printf '      %s\n' "$2"; fi; }

if [ ! -d "$SKILL" ]; then
  echo "FAIL  스킬 디렉터리를 찾을 수 없습니다: $SKILL"
  exit 1
fi

echo "== S: 구조 =="
REQUIRED="
SKILL.md
references/entry-check.md
references/read.md
references/transition.md
references/write.md
references/redaction.md
references/command-map.md
references/errors.md
references/config.md
references/value-safety.md
references/confluence.md
templates/transition-note.md
templates/comment.md
templates/workitem-create.md
templates/blog-post.md
scripts/scan-sensitive.sh
"
for f in $REQUIRED; do
  if [ -s "$SKILL/$f" ]; then pass "S1 존재+비어있지 않음: $f"
  else fail "S1 없음 또는 빈 파일: $f"; fi
done

if head -1 "$SKILL/SKILL.md" | grep -q '^---$'; then pass "S2 SKILL.md 프론트매터 시작"
else fail "S2 SKILL.md 첫 줄이 --- 가 아님"; fi

for k in "^name: jira-acli$" "^description:" "^when_to_use:"; do
  if grep -qE "$k" "$SKILL/SKILL.md"; then pass "S2 프론트매터 필드: $k"
  else fail "S2 프론트매터 필드 없음: $k"; fi
done

if grep -qE '^triggers:' "$SKILL/SKILL.md"; then
  fail "S3 비표준 triggers: 블록 사용 (라우팅에 효과 없음 — description/when_to_use 로 대체할 것)"
else pass "S3 비표준 triggers: 블록 없음"; fi

if [ -x "$SKILL/scripts/scan-sensitive.sh" ]; then pass "S4 scan-sensitive.sh 실행 권한"
else fail "S4 scan-sensitive.sh 에 실행 권한 없음"; fi

if bash -n "$SKILL/scripts/scan-sensitive.sh" 2>/dev/null; then pass "S5 scan-sensitive.sh 문법 정상"
else fail "S5 scan-sensitive.sh 문법 오류"; fi

CAP="$(python3 - "$SKILL/SKILL.md" <<'PY' 2>/dev/null || echo "ERR"
import io,re,sys
s=io.open(sys.argv[1],encoding='utf-8').read()
m=re.match(r'^---\n(.*?)\n---\n', s, re.S)
fm=m.group(1) if m else ''
def block(key):
    mm=re.search(r'^'+key+r':\s*>-?\n((?:[ \t]+.*\n?)+)', fm, re.M)
    if mm: return ' '.join(x.strip() for x in mm.group(1).splitlines())
    mm=re.search(r'^'+key+r':[ \t]*(.*)$', fm, re.M)
    return mm.group(1).strip() if mm else ''
print(len(block('description'))+len(block('when_to_use')))
PY
)"
if [ "$CAP" != "ERR" ] && [ "$CAP" -le 1536 ] 2>/dev/null; then pass "S6 description+when_to_use 길이 ${CAP}자 (<=1536)"
else fail "S6 description+when_to_use 길이 검사 실패: $CAP"; fi

# S7 — set -e 파이프라인 대입 함정 회귀 가드
#   (1) 출하되는 셸 스크립트가 `set -e` 를 켜지 않는지
#   (2) 모든 명령치환이 종료코드를 명시적으로 흡수하는지
SETE="$(grep -nE '^[[:space:]]*set[[:space:]]+-[a-z]*e' "$SELF" "$SKILL/scripts/scan-sensitive.sh" || true)"
if [ -z "$SETE" ]; then pass "S7a 출하 스크립트가 set -e 를 켜지 않음 (정상경로 조용사 방지)"
else fail "S7a set -e 사용 발견" "$SETE"; fi

UNGUARDED="$(python3 - "$SELF" "$SKILL/scripts/scan-sensitive.sh" <<'PY2' 2>/dev/null || echo "PYERR"
import io, re, sys
bad = []
for path in sys.argv[1:]:
    lines = io.open(path, encoding='utf-8').read().split('\n')
    i = 0
    while i < len(lines):
        if re.search(r'[A-Za-z_][A-Za-z0-9_]*="\$\(', lines[i]):
            j = i
            chunk = [lines[i]]
            while ')"' not in lines[j] and j + 1 < len(lines):
                j += 1
                chunk.append(lines[j])
            body = '\n'.join(chunk)
            safe = ('|| ' in body) or re.search(r'\$\((mktemp|cd |dirname|wc |printf)', body)
            if not safe:
                bad.append('%s:%d: %s' % (path, i + 1, lines[i].strip()))
            i = j + 1
        else:
            i += 1
print('\n'.join(bad))
PY2
)"
if [ "$UNGUARDED" = "PYERR" ]; then fail "S7b 명령치환 가드 검사 실행 실패"
elif [ -z "$UNGUARDED" ]; then pass "S7b 모든 명령치환이 종료코드를 흡수함 (|| true / || exit / 안전 원시명령)"
else fail "S7b 가드 없는 명령치환 발견 (정상경로에서 조용히 죽을 수 있음)" "$UNGUARDED"; fi

# S8 — 침묵 금지: 모든 검사 헬퍼가 PASS/FAIL 양쪽 분기를 갖는지 (elif/else 누락 회귀 가드)
SILENT="$(grep -nE 'if .*; then pass ' "$SELF" | wc -l | tr -d ' ' || true)"
ELSES="$(grep -cE '(else|elif) .*fail ' "$SELF" || true)"
if [ "${SILENT:-0}" -ge 1 ] && [ "${ELSES:-0}" -ge 1 ]; then pass "S8 검사 분기: pass ${SILENT}개 / fail 분기 ${ELSES}개 (침묵 분기 없음)"
else fail "S8 검사 분기 구조 확인 실패 (pass=${SILENT:-?} fail=${ELSES:-?})"; fi

echo
echo "== G: 일반성 =="
# 기본 패턴은 조직 중립이어야 한다. 특정 회사명·도메인·프로젝트 키·계정명을 이 파일에 적지 않는다
# — 이 스크립트도 스킬과 함께 배포되므로, 여기 적는 순간 그 값이 같이 나간다.
GEN_PAT='/(Users|home)/[A-Za-z0-9._-]+|/root/'
# README.md 도 배포물이다. 스킬 본문만 검사하면 README 로 회사 정보가 새는 경로가 열린 채 남는다.
GEN="$(grep -rniE "$GEN_PAT" "$SKILL" $DOCS_ALL || true)"
if [ -n "${SKILL_FORBIDDEN:-}" ]; then
  # 조직 고유어가 주어지면 스킬·README 뿐 아니라 이 스크립트 자신도 검사한다.
  GEN="$GEN$(grep -rniE "$SKILL_FORBIDDEN" "$SKILL" $DOCS_ALL "$SELF" || true)"
fi
if [ -z "$GEN" ]; then pass "G1 사용자 홈경로${SKILL_FORBIDDEN:+ 및 지정 금칙어} 하드코딩 없음 (0건)"
else fail "G1 하드코딩 발견" "$GEN"; fi

ATL="$(grep -rnoE '[A-Za-z0-9_.-]*\.atlassian\.net' "$SKILL" $DOCS_ALL | grep -viE 'YOURSITE\.atlassian\.net' || true)"
if [ -z "$ATL" ]; then pass "G2 .atlassian.net 표기는 자리표시자(YOURSITE)뿐"
else fail "G2 실제처럼 보이는 사이트 주소 발견" "$ATL"; fi

MAIL="$(grep -rnoE '[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+\.[A-Za-z]{2,}' "$SKILL" $DOCS_ALL || true)"
if [ -z "$MAIL" ]; then pass "G3 구체적인 이메일 주소 없음"
else fail "G3 이메일 주소 발견" "$MAIL"; fi

# 예외 'Z0-9': command-map.md 6번의 키 모양 정규식 문자클래스 [A-Z0-9] 에서 잘려 나오는 조각이며
#            실제 작업항목 키가 아니다. 토큰 전체가 정확히 Z0-9 인 경우에만 제외한다.
KEYS="$(grep -rnoE '\b[A-Z][A-Z0-9]{1,9}-[0-9]+\b' "$SKILL" $DOCS_ALL | grep -viE 'PROJ-[0-9]+|KEY-[0-9]+|ABC-[0-9]+|:Z0-9$' || true)"
if [ -z "$KEYS" ]; then pass "G4 예시 작업항목 키는 자리표시자(PROJ-###)뿐"
else fail "G4 실제처럼 보이는 작업항목 키 발견" "$KEYS"; fi

echo
echo "== M: 설치 경로 (배포물 정합성) =="
# 스킬 본문은 촘촘히 검사되는데 설치 경로에는 검사가 없었다. 여기가 틀리면 사용자가 처음 만나는
# 안내가 조용히 거짓이 된다 — 스킬이 아무리 정확해도 설치가 안 되면 소용이 없다.
MJ="$(python3 - "$ROOT" <<'PYM' 2>/dev/null || echo "PYERR"
import io, json, os, sys
root = sys.argv[1]
try:
    mk = json.load(io.open(os.path.join(root, '.claude-plugin/marketplace.json'), encoding='utf-8'))
    pl = json.load(io.open(os.path.join(root, '.claude-plugin/plugin.json'), encoding='utf-8'))
except Exception as e:
    print("READERR %s" % e); raise SystemExit
mkname = mk.get('name', '')
plname = pl.get('name', '')
entry  = (mk.get('plugins') or [{}])[0].get('name', '')
skills = pl.get('skills', '')
skills_ok = os.path.isdir(os.path.join(root, skills.lstrip('./'))) if skills else False
readme = io.open(os.path.join(root, 'README.md'), encoding='utf-8').read()
install = '%s@%s' % (plname, mkname)
print('%s|%s|%s|%s|%s' % (install, 'yes' if install in readme else 'no',
                          'yes' if entry == plname else 'no',
                          'yes' if skills_ok else 'no', skills))
PYM
)"
if [ "$MJ" = "PYERR" ] || [ -z "$MJ" ]; then fail "M0 매니페스트 파싱 실패"
else
  M_INSTALL="$(printf '%s' "$MJ" | cut -d'|' -f1)"
  M_INREADME="$(printf '%s' "$MJ" | cut -d'|' -f2)"
  M_NAMEOK="$(printf '%s' "$MJ" | cut -d'|' -f3)"
  M_SKILLSOK="$(printf '%s' "$MJ" | cut -d'|' -f4)"
  M_SKILLSDIR="$(printf '%s' "$MJ" | cut -d'|' -f5)"
  if [ "$M_INREADME" = "yes" ]; then pass "M1 README 설치 문자열이 매니페스트와 일치 ($M_INSTALL)"
  else fail "M1 README 에 설치 문자열이 없거나 매니페스트와 어긋남" "기대: $M_INSTALL"; fi

  if [ "$M_NAMEOK" = "yes" ]; then pass "M2 marketplace 항목 이름 == plugin.json name"
  else fail "M2 marketplace.plugins[0].name 과 plugin.json name 불일치"; fi

  if [ "$M_SKILLSOK" = "yes" ]; then pass "M3 plugin.json 의 skills 경로가 실재 ($M_SKILLSDIR)"
  else fail "M3 plugin.json 의 skills 경로가 없는 디렉터리" "$M_SKILLSDIR"; fi
fi

# M4 — README 에서 플러그인 설치가 git clone 보다 먼저 나와야 한다.
#      에이전트는 "실행 가능한 첫 완결 레시피"를 고른다. clone 이 먼저 나오면 그쪽으로 간다.
M_PLUGIN_LINE="$(grep -n 'claude plugin marketplace add' "$DOCS" | head -1 | cut -d: -f1 || true)"
M_CLONE_LINE="$(grep -n 'git clone' "$DOCS" | head -1 | cut -d: -f1 || true)"
if [ -n "$M_PLUGIN_LINE" ] && { [ -z "$M_CLONE_LINE" ] || [ "$M_PLUGIN_LINE" -lt "$M_CLONE_LINE" ]; }; then
  pass "M4 README 에서 플러그인 설치가 git clone 보다 먼저 나옴"
else fail "M4 README 에서 git clone 이 플러그인 설치보다 먼저 나옴 (에이전트가 clone 으로 샌다)" \
  "plugin=${M_PLUGIN_LINE:-없음} clone=${M_CLONE_LINE:-없음}"; fi

# M5 — 에이전트용 지시 파일이 있고, clone 설치를 억제한다 (이미 clone 한 경우의 복구 백스톱)
if [ -s "$ROOT/AGENTS.md" ] && grep -q 'do not copy files' "$ROOT/AGENTS.md"; then
  pass "M5 AGENTS.md 가 파일 복사 설치를 억제함"
else fail "M5 AGENTS.md 가 없거나 복사 설치 억제 문장이 없음"; fi

# M5b — 플러그인 루트에 CLAUDE.md 를 두지 않는다.
#       루트 CLAUDE.md 는 플러그인으로 배포될 때 로드되지 않으며,
#       claude plugin validate --strict 를 실패시킨다. 에이전트 안내는 AGENTS.md 로 통일한다.
if [ ! -e "$ROOT/CLAUDE.md" ]; then pass "M5b 플러그인 루트에 CLAUDE.md 없음 (strict 검증 통과 조건)"
else fail "M5b 플러그인 루트 CLAUDE.md 발견 — plugin validate --strict 가 실패한다" "AGENTS.md 로 옮길 것"; fi

# M7 — 두 README 가 함께 존재하고 서로를 가리키는지 (한쪽만 갱신되어 갈라지는 것을 막는 최소 가드)
if [ -s "$ROOT/README.ko.md" ] && grep -q 'README.ko.md' "$ROOT/README.md" && grep -q 'README.md' "$ROOT/README.ko.md"; then
  pass "M7 영어/한국어 README 가 모두 존재하고 상호 링크됨"
else fail "M7 README 두 버전 중 하나가 없거나 상호 링크가 끊김"; fi

# M8 — claude CLI 가 있으면 공식 검증기를 strict 로 돌린다. 이 검사가 없어서 루트 CLAUDE.md 로 인한
#      스키마 경고를 놓쳤다. CLI 가 없는 환경에서도 침묵하지 않고 결과를 한 줄 남긴다.
if command -v claude >/dev/null 2>&1; then
  MKV="$(claude plugin validate "$ROOT" --strict 2>&1 || true)"
  PLV="$(claude plugin validate "$ROOT/.claude-plugin/plugin.json" --strict 2>&1 || true)"
  if printf '%s%s' "$MKV" "$PLV" | grep -q 'Validation failed'; then
    fail "M8 claude plugin validate --strict 실패" "$(printf '%s\n%s' "$MKV" "$PLV" | grep -E '❯|✘' | head -4)"
  else pass "M8 claude plugin validate --strict 통과 (marketplace + plugin)"; fi
else
  pass "M8 claude CLI 없음 — strict 검증 건너뜀 (CI 에서는 claude 를 설치할 것)"
fi

echo
echo "== N: 금지 패턴 (명령 템플릿 한정) =="
SPANS="$(grep -rhoE 'acli [^`]*' "$SKILL" | sed 's/[[:space:]]*$//' | sort -u || true)"
span_must_not() { # <라벨> <ERE>
  local hit; hit="$(printf '%s\n' "$SPANS" | grep -E -- "$2" || true)"
  if [ -z "$hit" ]; then pass "N $1"
  else fail "N $1" "$hit"; fi
}
MUT='(transition|create|create-bulk|edit|assign|delete|archive|unarchive|clone|link)'
span_must_not "N1 쓰기 명령에 --jql 없음"            "workitem +$MUT( |[^|]*)--jql"
span_must_not "N2 쓰기 명령에 --filter 없음"          "workitem +$MUT[^|]*--filter"
span_must_not "N3 --ignore-errors 없음"               '\-\-ignore-errors'
span_must_not "N4 --key 에 쉼표 다중 지정 없음"        '\-\-key[[:space:]]*"?[^"[:space:]]*,'
span_must_not "N5 -k 축약형 미사용"                    '(^| )-k '
span_must_not "N6 명령에 --token 없음 (토큰 취급 금지)" '\-\-token'
span_must_not "N7 --json 출력을 /dev/null 로 버리지 않음" '>[[:space:]]*/dev/null'
span_must_not "N8 view 는 --key 를 쓰지 않음(위치 인자)"  'workitem view [^|]*--key'
span_must_not "N9 존재하지 않는 attachment 다운로드/업로드 명령 없음" 'attachment +(download|get|save|fetch|create|upload|add)'

DEVNULL="$(grep -rnE '\-\-json[^|]*>[[:space:]]*/dev/null' "$SKILL" || true)"
if [ -z "$DEVNULL" ]; then pass "N10 문서 전체에 --json >/dev/null 형태 없음"
else fail "N10 --json 출력 폐기 형태 발견" "$DEVNULL"; fi

TOK="$(grep -rniE 'security find-generic-password|export[[:space:]]+[A-Z_]*TOKEN|echo[[:space:]]+[^|]*token[^|]*\||JIRA_API_TOKEN' "$SKILL" || true)"
if [ -z "$TOK" ]; then pass "N11 토큰을 읽거나 저장하거나 흘리는 형태 없음"
else fail "N11 토큰 취급 흔적 발견" "$TOK"; fi

HARD="$(grep -rnE '\|[[:space:]]*[0-9]{1,3}[[:space:]]*\|[^|]*(해야 할 일|진행 중|완료|검토 중|To Do|In Progress|Done|Backlog)' "$SKILL" || true)"
if [ -z "$HARD" ]; then pass "N12 상태 ID/상태명 하드코딩 표 없음 (jira-cli 안티패턴)"
else fail "N12 상태 ID 표로 보이는 블록 발견" "$HARD"; fi

# N13~N15 — Confluence: 존재하지 않는 명령을 지어내지 않는다.
#   acli confluence page 에는 view 하나뿐이고, blog 에는 create/list/view 뿐이다(1.3.22-stable 관측).
#   문서에 없는 명령이 적히면 모델이 그걸 실행하려 든다 — 스킬이 거짓말을 하는 가장 흔한 경로다.
span_must_not "N13 confluence page 에 view 외 명령 없음 (생성·수정 명령 자체가 없음)" \
  'confluence page +(create|edit|update|delete|remove|add|move|copy)'
span_must_not "N14 confluence blog 에 create/list/view 외 명령 없음" \
  'confluence blog +(edit|update|delete|remove|archive|restore)'
# space 를 바꾸는 명령은 존재하지만 이 스킬은 쓰지 않는다(조직 전체에 영향을 주는 관리자 작업).
span_must_not "N15 confluence space 를 바꾸는 관리자 명령 미사용" \
  'confluence space +(create|archive|restore|update|delete)'
# 본문은 항상 파일로 넘긴다. --body 는 명령줄에 XHTML 을 그대로 넣어 따옴표/줄바꿈에서 깨진다.
span_must_not "N16 blog create 는 --body 직접 사용 안 함 (--from-file 강제)" \
  'confluence blog create[^|]*--body '

echo
echo "== P: 반드시 있어야 할 것 =="
p_has() { # <라벨> <파일> <ERE>
  if grep -qE -- "$3" "$SKILL/$2"; then pass "P $1"
  else fail "P $1" "$2 에서 찾지 못함: $3"; fi
}
# P17~P22 — Confluence 절차가 실제로 문서에 있는가 (없는데 라우팅만 되면 모델이 지어낸다)
p_has "P17 confluence 페이지 읽기 명령"       references/confluence.md 'acli confluence page view --id'
p_has "P18 confluence 공간 목록(키→ID) 명령"  references/confluence.md 'acli confluence space list'
p_has "P19 confluence 블로그 작성 명령"       references/confluence.md 'acli confluence blog create'
p_has "P20 blog 본문은 파일로 넘김"           references/confluence.md '\-\-from-file'
p_has "P21 confluence: page create/edit stated impossible" references/confluence.md 'cannot create or edit a page'
p_has "P22 Jira 와 별개 로그인임을 명시"      references/confluence.md 'acli confluence auth status'
# P23~P25 — Confluence 쓰기도 Jira 와 똑같이 확인 게이트를 통과해야 한다.
#           절차는 있는데 게이트가 빠지면, 확인 없이 조직 공간에 글이 올라간다.
p_has "P23 confluence write confirmation gate" references/confluence.md 'Confirmation gate'
p_has "P24 confluence gate shows exact command" references/confluence.md 'exact command'
p_has "P25 confluence states it cannot delete"  references/confluence.md 'cannot delete it'

p_has "P1 진입점검: acli --version"          references/entry-check.md 'acli --version'
p_has "P2 진입점검: acli jira auth status"   references/entry-check.md 'acli jira auth status'
# P1b/P2b — 해피패스가 SKILL.md 에 직접 있어야 한다. 이게 없으면 모델은 두 줄을 알아내려고
#           entry-check.md(실패 경로 포함) 전체를 매번 읽게 된다. 승격이 되돌려지면 여기서 잡힌다.
p_has "P1b 해피패스: SKILL.md 에 acli --version"        SKILL.md 'acli --version'
p_has "P2b 해피패스: SKILL.md 에 acli jira auth status" SKILL.md 'acli jira auth status'
p_has "P3 진입점검: 안내 로그인은 --web 뿐"   references/entry-check.md 'acli jira auth login --web'
p_has "P4 진입점검: brew tap 설치 안내"       references/entry-check.md 'brew tap atlassian/homebrew-acli'
p_has "P5 진입점검: brew install 설치 안내"   references/entry-check.md 'brew install acli'
p_has "P6 상태전환: 현재 상태 조회"           references/transition.md 'acli jira workitem view <KEY> --fields "status" --json'
p_has "P7 상태전환: 사용 중 상태 도출에 --paginate 필수" references/transition.md 'workitem search --jql "project = <your-project>"[^`]*--paginate'
p_has "P8 상태전환: 단일 키 transition 명령"  references/transition.md 'workitem transition --key "<KEY>" --status "<STATUS>"'
p_has "P9 transition: confirmation gate shows command + text" references/transition.md 'Confirmation gate'
p_has "P10 transition: states reachability is not guaranteed" references/transition.md 'not a guarantee'
p_has "P11 write: confirmation gate defined"   references/write.md 'The exact command'
p_has "P12 비공개: 검사기 호출"               references/redaction.md 'scan-sensitive.sh'
p_has "P13 attachments: download stated impossible"          references/read.md 'Download and upload commands do not exist'
p_has "P14 limit: cannot query transitions"     SKILL.md 'cannot query'
p_has "P15 근거: 버전 명시"                   SKILL.md '1\.3\.22-stable'

for f in entry-check read transition write redaction command-map errors config value-safety confluence; do
  if grep -q "references/$f.md" "$SKILL/SKILL.md"; then pass "P16 SKILL.md 가 references/$f.md 를 안내"
  else fail "P16 SKILL.md 에 references/$f.md 안내 없음"; fi
done

echo
echo "== D: 결함 회귀 가드 (이번 라운드 수정분) =="

# D1 — 상태 도출 명령은 --fields "status" + --paginate 여야 한다 (key,status 금지)
D1BAD="$(grep -rn -- '--fields "key,status"' "$SKILL" || true)"
D1T="$(grep -nE -- 'workitem search --jql .*--paginate' "$SKILL/references/transition.md" | grep -F -- '--fields "status"' || true)"
D1C="$(grep -nE -- 'workitem search --jql .*--paginate' "$SKILL/references/command-map.md" | grep -F -- '--fields "status"' || true)"
if [ -z "$D1BAD" ] && [ -n "$D1T" ] && [ -n "$D1C" ]; then pass "D1 상태 도출 명령 = --fields \"status\" + --paginate (문서 간 축자 일치)"
else fail "D1 상태 도출 명령 형태 불일치" "key,status=[$D1BAD] / transition=[$D1T] / command-map=[$D1C]"; fi

# D2 — 진입 점검이 토큰 로그인 플래그 조합을 나열하지 않는다
D2="$(grep -nE -- '--(token|site|email)' "$SKILL/references/entry-check.md" || true)"
if [ -z "$D2" ]; then pass "D2 진입점검이 토큰 로그인 플래그(--site/--email/--token)를 나열하지 않음"
else fail "D2 토큰 로그인 플래그 나열 발견" "$D2"; fi

# D3/D4/D6 — 산문 단정 가드 (줄바꿈에 흔들리지 않도록 공백을 정규화한 뒤 검사)
PROSE="$(python3 - "$SKILL" <<'PY3' 2>/dev/null || echo "PYERR"
import io, os, re, sys
root = sys.argv[1]
bad = []
for dirpath, _dirs, files in os.walk(root):
    for fn in sorted(files):
        if not fn.endswith('.md'):
            continue
        p = os.path.join(dirpath, fn)
        flat = re.sub(r'\s+', ' ', io.open(p, encoding='utf-8').read())
        rel = os.path.relpath(p, root)
        # D3: '나머지 ... 전부 --key' 보편 주장은 '이 스킬' 범위 한정어를 달고 있어야 한다
        for m in re.finditer(r'나머지[^|]{0,40}(전부|모두)[^|]{0,40}--key', flat):
            seg = flat[max(0, m.start() - 40):m.end()]
            if '이 스킬' not in seg:
                bad.append('D3 %s: %s' % (rel, seg.strip()))
        # D4: 확인 플래그가 없다는 관측을 '바로 실행된다'는 단정으로 옮기지 않는다 ('간주' 필수)
        for m in re.finditer(r'바로 실행', flat):
            if '간주' not in flat[m.start():m.start() + 40]:
                bad.append('D4 %s: %s' % (rel, flat[max(0, m.start() - 40):m.start() + 40].strip()))
        # D6: --paginate 를 붙이지 않으면 '조용히 빠진다'는 미관측 인과 단정 금지
        for m in re.finditer(r'조용히 ?빠', flat):
            bad.append('D6 %s: %s' % (rel, flat[max(0, m.start() - 40):m.start() + 40].strip()))
print('\n'.join(bad))
PY3
)"
prose_clean() { # <라벨> <코드>
  local hit
  if [ "$PROSE" = "PYERR" ]; then fail "$1" "산문 가드 실행 실패 (python3)"; return 0; fi
  hit="$(printf '%s\n' "$PROSE" | grep "^$2 " || true)"
  if [ -z "$hit" ]; then pass "$1"
  else fail "$1" "$hit"; fi
}
prose_clean "D3 --key 보편 주장 없음 (이 스킬이 쓰는 명령으로 한정)" D3
prose_clean "D4 확인 플래그 부재를 즉시 실행으로 단정하지 않음 (모두 '간주' 형태)" D4
prose_clean "D6 --paginate 미사용을 누락 원인으로 단정하지 않음" D6

# D5 — 생성 결과에 새 키가 없을 때의 방어적 처리가 적혀 있다
if grep -q 'is not visible, do not invent' "$SKILL/references/write.md"; then pass "D5 생성 결과 키 부재 시 방어적 처리 명시 (미관측 단정 제거)"
else fail "D5 write.md 에 생성 결과 키 방어 처리 문장이 없음"; fi

# D6b — --paginate 기본 동작이 미문서화라는 사실이 적혀 있다
if grep -q 'default behaviour with no flags at all' "$SKILL/references/transition.md"; then pass "D6b --paginate 무플래그 기본 동작이 미문서화임을 명시"
else fail "D6b transition.md 에 기본 동작 미문서화 서술이 없음"; fi

# D7 — 검사기가 못 잡는 형태(빗금 없는 브랜치 이름)를 솔직히 적고, 그 책임을 칸 규칙에 넘겼다
#      두 조각을 모두 요구한다: (1) 못 잡는다는 사실, (2) 그럼 누가 잡는지(첫 번째 그물)
D7A="$(grep -c 'without a slash' "$SKILL/references/redaction.md" || true)"
D7B="$(grep -c 'the first net' "$SKILL/references/redaction.md" || true)"
if [ "${D7A:-0}" -ge 1 ] && [ "${D7B:-0}" -ge 1 ]; then pass "D7 검사기 한계(빗금 없는 브랜치 이름) + 칸 규칙이 그 몫을 진다는 명시"
else fail "D7 redaction.md 검사기 한계 문장 불완전" "못잡음=${D7A:-0} 첫번째그물=${D7B:-0}"; fi

# D8 — 값 안전 규칙 정본이 value-safety.md 에 있고, 그것을 참조하는 쪽이 실제로 그 파일을 가리킨다
#      정본이 옮겨졌으므로 요약(command-map)이 아니라 정본 파일을 검사한다. 요약만 남고 정본이
#      사라지는 상황을 잡으려면 D8V/D8VR 두 조각이 반드시 필요하다.
D8V="$(grep -c 'alue safety' "$SKILL/references/value-safety.md" || true)"
D8VR="$(grep -cF '^[A-Z][A-Z0-9]*-[0-9]+$' "$SKILL/references/value-safety.md" || true)"
D8A="$(grep -c 'alue safety' "$SKILL/references/command-map.md" || true)"
D8R="$(grep -cF '^[A-Z][A-Z0-9]*-[0-9]+$' "$SKILL/references/command-map.md" || true)"
D8W="$(grep -c 'alue safety' "$SKILL/references/write.md" || true)"
D8T="$(grep -c 'alue safety' "$SKILL/references/transition.md" || true)"
if [ "${D8V:-0}" -ge 1 ] && [ "${D8VR:-0}" -ge 1 ] && [ "${D8A:-0}" -ge 1 ] && [ "${D8R:-0}" -ge 1 ] && [ "${D8W:-0}" -ge 1 ] && [ "${D8T:-0}" -ge 1 ]; then pass "D8 값 안전 규칙 정본(키 모양 검사 포함) + command-map 요약 + write/transition 참조"
else fail "D8 값 안전 규칙 누락" "value-safety=${D8V:-0} keyshape=${D8VR:-0} command-map=${D8A:-0} cm-keyshape=${D8R:-0} write=${D8W:-0} transition=${D8T:-0}"; fi

# D8b — write/transition 이 정본 파일을 파일 이름으로 실제로 가리키는지 (문구만 남고 링크가 끊긴 경우 탐지)
D8PW="$(grep -c 'value-safety\.md' "$SKILL/references/write.md" || true)"
D8PT="$(grep -c 'value-safety\.md' "$SKILL/references/transition.md" || true)"
D8PC="$(grep -c 'value-safety\.md' "$SKILL/references/command-map.md" || true)"
if [ "${D8PW:-0}" -ge 1 ] && [ "${D8PT:-0}" -ge 1 ] && [ "${D8PC:-0}" -ge 1 ]; then pass "D8b write/transition/command-map 이 정본 파일(value-safety.md)을 이름으로 가리킴"
else fail "D8b 정본 파일 포인터 끊김" "write=${D8PW:-0} transition=${D8PT:-0} command-map=${D8PC:-0}"; fi

# D12 — 절차 파일의 "전제" 줄이 entry-check.md 가 아니라 SKILL.md 0.5 를 가리킨다
#       이 줄들이 entry-check.md 를 직접 부르면, 모델은 절차 파일을 여는 순간 그 파일도 열게 되어
#       진입 점검 승격으로 아낀 분량(약 7.4KB)이 매 호출 그대로 반납된다. 절감의 존폐가 걸린 줄이다.
D12BAD=""
D12OK=0
for f in read write transition; do
  LINE="$(grep -nE '^(Prerequisite:|Prerequisite )' "$SKILL/references/$f.md" | head -1 || true)"
  if printf '%s' "$LINE" | grep -q 'SKILL\.md'; then D12OK=$((D12OK+1))
  else D12BAD="$D12BAD $f.md=[${LINE:-없음}]"; fi
done
if [ "$D12OK" -eq 3 ]; then pass "D12 read/write/transition 전제 줄이 SKILL.md 0.5 를 가리킴 (entry-check 재유입 차단)"
else fail "D12 전제 줄이 SKILL.md 를 가리키지 않음 (승격 절감이 반납됨)" "$D12BAD"; fi

# D13 — 이미 로그인된 사용자에게 재로그인을 요구하지 않는다는 규칙이 SKILL.md 0.5 에도 있다
#       P5("안내하는 로그인은 --web 하나뿐")와 결합하면, 이 규칙이 없을 때 토큰으로 인증된 사용자에게
#       불필요한 재로그인을 요구하는 오작동이 나온다.
if grep -q 'Never ask an already-authenticated user to log in again' "$SKILL/SKILL.md"; then pass "D13 SKILL.md 0.5 에 재로그인 금지 규칙 있음"
else fail "D13 SKILL.md 에 재로그인 금지 규칙이 없음 (P5 와 결합해 오작동 유발)"; fi

# D14 — 값 안전 규칙 요약(command-map)과 정본이 어긋날 때 정본이 이긴다는 우선순위 명시
if grep -q 'canonical file always wins' "$SKILL/references/command-map.md"; then pass "D14 스텁↔정본 우선순위 명시 (발산 시 정본 우선)"
else fail "D14 command-map 요약에 정본 우선 문장이 없음"; fi

# D11 — 기본 응답의 null 을 "값 없음"으로 단정하지 않는다 (실측된 오독 함정)
#       라벨·코멘트는 기본 view 응답에 담기지 않아 null 로 오는데, 그걸 "없음"으로 보고하면 거짓이 된다.
D11A="$(grep -c 'Fields not included in the default response' "$SKILL/references/read.md" || true)"
D11B="$(grep -cF -- '--fields "labels"' "$SKILL/references/read.md" || true)"
if [ "${D11A:-0}" -ge 1 ] && [ "${D11B:-0}" -ge 1 ]; then pass "D11 기본 응답 null 을 '값 없음'으로 단정하지 않음 + 필드 지정 재조회 명시"
else fail "D11 read.md 에 null 오독 방지 서술이 없음" "설명=${D11A:-0} 재조회명령=${D11B:-0}"; fi

# D9 — 이 스크립트가 자기 자신을 상대경로로 참조하지 않는다 (cwd 독립)
D9="$(grep -nE '(^|[^/$])verify\.sh' "$SELF" | grep -vE '^[0-9]+:[[:space:]]*#' || true)"
if [ -z "$D9" ]; then pass "D9 자기 파일 상대경로 참조 없음 (다른 cwd 에서도 동일 결과)"
else fail "D9 상대경로 자기참조 발견 (다른 cwd 에서 조용히 실패함)" "$D9"; fi

# D10 — 전이 목록을 못 보는 한계를 Jira 가 아니라 acli(도구)에 귀속시킨다
if grep -q 'not a limit of Jira' "$SKILL/references/transition.md"; then pass "D10 전이 목록 한계를 도구(acli)에 귀속 — 안전 문장 보존"
else fail "D10 transition.md 에 한계 귀속 문장이 없음"; fi

echo
echo "== F: 검사기 기능 =="
TMPD="$(mktemp -d)"
trap 'rm -rf "$TMPD"' EXIT
cat > "$TMPD/dirty.txt" <<'DIRTY'
/home/dev/work/service/src/upload_handler.py 의 타임아웃을 늘림
src/api/handler.py:142 에서 UserService.validate() 수정
api-internal.example.local:8080 과 localhost:3000 에서 확인, 10.0.12.7 서버
feature/ABC-12-refactor 브랜치, 커밋 a1b2c3d4, PR #482
Traceback (most recent call last):
KeyError: 'user_id'
API_KEY=abcd1234efgh
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9abcdefg
$ git commit -m "fix"
DIRTY
cat > "$TMPD/clean.txt" <<'CLEAN'
[상태 변경] 진행 중 → 검토 요청
■ 무엇을 했나
큰 첨부 파일이 있는 요청이 중간에 끊기던 문제를 처리 방식 변경으로 해결했습니다.
■ 확인된 결과
동일 조건으로 다시 시도했을 때 끝까지 정상 처리되는 것을 확인했습니다.
■ 영향 범위
첨부를 많이 올리는 요청 전체. 현재는 개발 환경에서 확인된 상태입니다.
■ 참고
PROJ-124
CLEAN

"$SKILL/scripts/scan-sensitive.sh" "$TMPD/dirty.txt" > "$TMPD/dirty.out" 2>&1
DRC=$?
"$SKILL/scripts/scan-sensitive.sh" "$TMPD/clean.txt" > "$TMPD/clean.out" 2>&1
CRC=$?

if [ "$DRC" -eq 1 ]; then pass "F1 민감정보 초안을 검사기가 걸러냄 (exit 1)"
else fail "F1 민감정보 초안이 통과됨 (exit $DRC)" "$(cat "$TMPD/dirty.out")"; fi

for cat_ in "absolute file path" "source file path" "local host" "private IP range" "branch name" "commit-hash-like value" "stack trace" "credential keyword" "shell prompt/command"; do
  if grep -q "$cat_" "$TMPD/dirty.out"; then pass "F2 탐지 범주: $cat_"
  else fail "F2 탐지 실패 범주: $cat_"; fi
done

if [ "$CRC" -eq 0 ]; then pass "F3 정상 업무 문구는 통과 (exit 0)"
else fail "F3 정상 문구가 걸림 (exit $CRC)" "$(cat "$TMPD/clean.out")"; fi

if "$SKILL/scripts/scan-sensitive.sh" < "$TMPD/clean.txt" >/dev/null 2>&1; then pass "F4 표준입력 모드 동작"
else fail "F4 표준입력 모드 실패"; fi

# F5/F6 — 이번 라운드에 넓힌 패턴 두 가지에 대한 반증 씨앗 (각각 단독으로 걸려야 한다)
cat > "$TMPD/seed-apikey.txt" <<'AKS'
API Key: abcdefgh
AKS
cat > "$TMPD/seed-tmp.txt" <<'TMPP'
/tmp/draft-note.txt 에 저장했습니다
TMPP

"$SKILL/scripts/scan-sensitive.sh" "$TMPD/seed-apikey.txt" > "$TMPD/seed-apikey.out" 2>&1
AKRC=$?
"$SKILL/scripts/scan-sensitive.sh" "$TMPD/seed-tmp.txt" > "$TMPD/seed-tmp.out" 2>&1
TPRC=$?

if [ "$AKRC" -eq 1 ] && grep -q "credential keyword" "$TMPD/seed-apikey.out"; then pass "F5 공백으로 구분된 'API Key:' 형태를 자격증명으로 탐지 (exit 1)"
else fail "F5 공백 구분 API Key 형태를 놓침 (exit $AKRC)" "$(cat "$TMPD/seed-apikey.out")"; fi

if [ "$TPRC" -eq 1 ] && grep -q "absolute file path" "$TMPD/seed-tmp.out"; then pass "F6 /tmp 절대경로를 탐지 (exit 1)"
else fail "F6 /tmp 절대경로를 놓침 (exit $TPRC)" "$(cat "$TMPD/seed-tmp.out")"; fi

echo
echo "==================================="
printf '통과 %d건 / 실패 %d건\n' "$PASSN" "$FAIL"
if [ "$FAIL" -eq 0 ]; then echo "RESULT: OK"; exit 0; fi
echo "RESULT: FAILED"; exit 1
