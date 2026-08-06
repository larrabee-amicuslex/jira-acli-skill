#!/usr/bin/env bash
# scan-sensitive.sh - finds traces of internal engineering detail in a draft bound for Jira.
#
# Usage:
#   scan-sensitive.sh <file path>
#   cat draft.txt | scan-sensitive.sh
#
# Exit codes:
#   0  nothing caught
#   1  suspicious text found (fix it and run again)
#   2  usage error
#
# Note: this scanner is the "second net" described in references/redaction.md.
#       Passing it does NOT guarantee safety. The final judgement is the slot rules in redaction.md.
#       It only FINDS - it never rewrites. Rewriting is the human's (or model's) job.

# Shell safety rules (for whoever edits this file):
#   - Do NOT turn on `set -e`. This script's happy path (= nothing found) is the path where grep
#     exits 1. With `set -e` plus an unguarded command substitution, the script dies silently on the
#     very outcome you wanted ("clean"), and a normal run becomes indistinguishable from a crash.
#   - Every command substitution (`X="$(...)"`) must absorb the exit code (e.g. `|| true`) and be
#     judged by its value.
#   - Always print a result line. Silence is not a result - if nothing was found, say so and exit 0.
set -uo pipefail

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  sed -n '2,14p' "$0"
  exit 0
fi

cleanup=""
if [ "$#" -ge 1 ]; then
  SRC="$1"
  if [ ! -f "$SRC" ]; then
    echo "scan-sensitive.sh: file not found: $SRC" >&2
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

check() {   # check <label> <ERE pattern> [i]
  local label="$1" pat="$2" ic="${3:-}" out=""
  if [ "$ic" = "i" ]; then
    out="$(grep -nEi -- "$pat" "$SRC" 2>/dev/null || true)"
  else
    out="$(grep -nE -- "$pat" "$SRC" 2>/dev/null || true)"
  fi
  if [ -n "$out" ]; then report "$label" "$out"; fi
  return 0
}

# 1. Absolute file paths (home / system directories)
check "absolute file path" '(^|[^A-Za-z0-9])/(Users|home|root|Volumes|mnt|srv|opt|private|tmp|var/(www|log|tmp))/[A-Za-z0-9._-]'
check "windows path" '[A-Za-z]:\\+[A-Za-z0-9._ -]+\\'

# 2. Source files / code locations
check "source file path" '[A-Za-z0-9_./-]+\.(py|js|jsx|ts|tsx|go|java|kt|rb|php|rs|c|cc|cpp|h|hpp|cs|swift|scala|sql|sh|bash|zsh|yml|yaml|toml|ini|env|lock|gradle)([:#][0-9]+)?([^A-Za-z0-9]|$)'
check "code symbol" '\b[A-Za-z_][A-Za-z0-9_]*\.[a-z_][A-Za-z0-9_]*\(\)'

# 3. Internal hosts / private IPs / ports / API paths
check "local host" '(localhost|127\.0\.0\.1|0\.0\.0\.0)(:[0-9]{2,5})?'
check "private IP range" '\b(10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3})\b'
check "internal domain" '[A-Za-z0-9-]+\.(internal|local|localdomain|intranet|corp|lan|test)\b'
check "host:port" '\b[a-z0-9][a-z0-9.-]*:[0-9]{4,5}\b'
check "API endpoint / internal API host" '(/rest/api/|atl-paas\.net)'

# 4. Branches / PRs / commits
check "branch name" '\b(feature|feat|fix|hotfix|bugfix|release|chore|refactor|develop)/[A-Za-z0-9._/-]+'
check "PR / MR number" '\b(PR|MR|pull request|merge request)[[:space:]#-]*[0-9]+' i
check "commit reference" '(commit|커밋|sha)[[:space:]:#=]*[0-9a-f]{7,40}' i

# 4b. Tokens that look like a commit hash (7-40 chars, hex, containing both digits and a-f)
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
if [ -n "$hexout" ]; then report "commit-hash-like value" "$hexout"; fi

# 5. Stack traces / exceptions / log lines
check "stack trace" 'Traceback \(most recent call last\)|File "[^"]+", line [0-9]+|^[[:space:]]+at [A-Za-z0-9_.$]+\('
check "exception class name" '\b[A-Za-z_][A-Za-z0-9_]*(Exception|Error)\b'
check "log level marker" '(\[(DEBUG|TRACE|INFO|WARN|WARNING|ERROR|FATAL)\]|^[0-9]{4}-[0-9]{2}-[0-9]{2}[T ][0-9]{2}:[0-9]{2}:[0-9]{2})'

# 6. Credentials / secrets
check "credential keyword" '(token|api[-_ ]?key|apikey|secret|password|passwd|credential|authorization|private[_-]?key)[[:space:]]*[:=]' i
check "bearer token" 'bearer[[:space:]]+[A-Za-z0-9._~+/-]{10,}' i
check "private key block" '-----BEGIN [A-Z ]*PRIVATE KEY-----'
check "known token prefix" '\b(xox[baprs]-|ghp_|gho_|github_pat_|AKIA[0-9A-Z]{6,})'

# 7. Environment variables / shell traces
check "environment variable assignment" '\b[A-Z][A-Z0-9_]{3,}=[^[:space:]]+'
check "shell prompt/command" '(^\$[[:space:]]|^[a-z_][a-z0-9_-]*@[A-Za-z0-9._-]+:[~/]|\bgit[[:space:]]+(commit|push|pull|checkout|rebase|merge|log|diff|clone)\b|\bnpm[[:space:]]+run\b|\bdocker[[:space:]]+(run|exec|compose)\b|\b(kubectl|ssh|scp)[[:space:]]+)'

if [ "$FOUND" -gt 0 ]; then
  printf '\n----\nScan result: %d kind(s) of suspicious text found. Remove them or rewrite in business language, then run again.\n' "$FOUND"
  printf 'Rules: references/redaction.md\n'
  exit 1
fi

printf 'Scan result: nothing caught. (This is NOT a safety guarantee - make the final call with the slot rules in references/redaction.md.)\n'
exit 0
