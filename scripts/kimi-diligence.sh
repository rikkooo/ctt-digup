#!/usr/bin/env bash
# kimi-diligence.sh — standalone Kimi dual-diligence invoker for ctt-digup.
#
# Runs Kimi CLI non-interactively as a dual-diligence inspector for one card
# and writes a validation report. Does NOT implement anything: inspection only.
#
# usage: kimi-diligence.sh <card-path> <report-path>
#   card-path    path to cards/NN-<slug>.md  (relative to repo root, or absolute)
#   report-path  path to write the report    (relative to repo root, or absolute)
#
# examples:
#   scripts/kimi-diligence.sh cards/01-install-digup.md reports/01-install-digup.md
#   scripts/kimi-diligence.sh cards/08-subagent-kimi.md reports/08-subagent-kimi.md
#
# Exit codes:
#   0  report written
#   1  usage / card not found / kimi not found
#   2  kimi ran but report was not created
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
TEMPLATE="${REPO_ROOT}/reports/TEMPLATE.md"

usage() {
  cat >&2 <<'EOF'
usage: kimi-diligence.sh <card-path> <report-path>

  card-path    cards/NN-<slug>.md (relative to repo root, or absolute)
  report-path  reports/NN-<slug>.md (relative to repo root, or absolute)

Runs `kimi --auto -p <inspector prompt>` from the repo root and writes the
dual-diligence report to <report-path>. Fails if the report is not created.

Env:
  KIMI_BIN  override the kimi executable (otherwise auto-detected)
EOF
}

# Resolve a path given relative to REPO_ROOT (not cwd) or already absolute.
abs_from_root() {
  case "$1" in
    /* | [A-Za-z]:[\\/]* | \\\\*) printf '%s\n' "$1" ;;
    *) printf '%s\n' "${REPO_ROOT}/$1" ;;
  esac
}

# Map a /mnt/<drive>/... path to a Windows <DRIVE>:\... path; else echo unchanged.
win_path() {
  local p="$1"
  if [[ "$p" =~ ^/mnt/([A-Za-z])/(.*)$ ]]; then
    local drive="${BASH_REMATCH[1]}"
    local rest="${BASH_REMATCH[2]//\//\\}"
    printf '%s\n' "${drive^^}:\\${rest}"
  else
    printf '%s\n' "$p"
  fi
}

# Quote a string as ONE Windows argv element (CommandLineToArgvW rules).
# Needed when a Windows exe is invoked from WSL: WSL interop inserts argv
# values into the Windows command line without quoting, so a multi-word -p
# value is silently truncated at the first space. Emitting the quoting from
# this side restores the full argument.
win_argv_quote() {
  local s="$1"
  local out='"' bs=0 i c n
  for (( i = 0; i < ${#s}; i++ )); do
    c="${s:i:1}"
    if [ "$c" = '\' ]; then
      bs=$((bs + 1))
      continue
    fi
    if [ "$c" = '"' ]; then
      n=$((2 * bs + 1))
    else
      n=$((2 * bs))
    fi
    while [ "$n" -gt 0 ]; do out+='\'; n=$((n - 1)); done
    out+="$c"
    bs=0
  done
  n=$((2 * bs))
  while [ "$n" -gt 0 ]; do out+='\'; n=$((n - 1)); done
  out+='"'
  printf '%s' "$out"
}

# True when we are in WSL about to invoke a Windows binary — the one case
# where win_argv_quote must be applied. Git Bash/MSYS quotes correctly on
# its own; a native Linux kimi needs no quoting at all.
needs_win_quoting() {
  local bin="$1"
  case "$bin" in
    *.[eE][xX][eE]) ;;
    *) return 1 ;;
  esac
  [ -n "${WSL_DISTRO_NAME:-}" ] || [ -n "${WSL_INTEROP:-}" ] || grep -qi microsoft /proc/version 2>/dev/null
}

# Find a working kimi binary. The Windows npm shim on the WSL PATH loads
# Windows native modules under Linux node and fails; skip any candidate that
# cannot report --version. Prefer KIMI_BIN, then kimi, then kimi.exe (WSL
# interop), then known install locations.
resolve_kimi() {
  local cand u tested=""
  local candidates=()
  if [ -n "${KIMI_BIN:-}" ]; then
    candidates+=("${KIMI_BIN}")
  fi
  candidates+=(kimi kimi.exe)
  # Known Windows per-user install locations, via WSL interop or Git Bash.
  for u in "${USERPROFILE:-}" "/mnt/c/Users/${USERNAME:-}" "/mnt/c/Users/${WIN_USER:-}"; do
    if [ -n "$u" ]; then
      candidates+=("${u}/.kimi-code/bin/kimi.exe")
    fi
  done
  if [ -d /mnt/c/Users ]; then
    for u in /mnt/c/Users/*; do
      candidates+=("${u}/.kimi-code/bin/kimi.exe")
    done
  fi

  for cand in "${candidates[@]}"; do
    [ -n "$cand" ] || continue
    tested="${tested}  ${cand}"$'\n'
    if command -v "$cand" >/dev/null 2>&1 || [ -x "$cand" ]; then
      if "$cand" --version >/dev/null 2>&1; then
        printf '%s\n' "$cand"
        return 0
      fi
    fi
  done
  echo "error: no working kimi binary found (tried:" >&2
  printf '%s' "$tested" >&2
  echo ")" >&2
  echo "hint: install Kimi CLI or set KIMI_BIN=/path/to/kimi(.exe)" >&2
  return 1
}

# Run kimi once with the given extra flags + the inspector prompt.
# Uses win_argv_quote when talking to a Windows exe from WSL.
run_kimi() {
  local bin="$1"
  shift
  local prompt_arg="$INSPECTOR_PROMPT"
  if needs_win_quoting "$bin"; then
    prompt_arg="$(win_argv_quote "$INSPECTOR_PROMPT")"
  fi
  ( cd "$REPO_ROOT" && "$bin" "$@" -p "$prompt_arg" )
}

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
  usage
  exit 0
fi
if [ "$#" -ne 2 ]; then
  usage
  exit 1
fi

CARD_ARG="$1"
REPORT_ARG="$2"

CARD_PATH="$(abs_from_root "$CARD_ARG")"
REPORT_PATH="$(abs_from_root "$REPORT_ARG")"

if [ ! -f "$CARD_PATH" ]; then
  echo "error: card not found: ${CARD_ARG} (resolved: ${CARD_PATH})" >&2
  echo "available cards:" >&2
  ls "${REPO_ROOT}/cards" 2>/dev/null | sed 's/^/  /' >&2 || true
  exit 1
fi

# Paths as the inspector should reference them (relative to the repo root when
# the file lives inside it; Windows-style absolute otherwise).
case "$CARD_PATH" in
  "${REPO_ROOT}/"*) CARD_REL="${CARD_PATH#"${REPO_ROOT}"/}" ;;
  *) CARD_REL="$(win_path "$CARD_PATH")" ;;
esac
case "$REPORT_PATH" in
  "${REPO_ROOT}/"*) REPORT_REL="${REPORT_PATH#"${REPO_ROOT}"/}" ;;
  *) REPORT_REL="$(win_path "$REPORT_PATH")" ;;
esac

REPORT_DIR="$(dirname "$REPORT_PATH")"
mkdir -p "$REPORT_DIR"

KIMI="$(resolve_kimi)"

CARD_WIN="$(win_path "$CARD_PATH")"
REPORT_WIN="$(win_path "$REPORT_PATH")"
ROOT_WIN="$(win_path "$REPO_ROOT")"

TEMPLATE_BODY=""
if [ -f "$TEMPLATE" ]; then
  TEMPLATE_BODY="$(cat "$TEMPLATE")"
fi

INSPECTOR_PROMPT="$(cat <<EOF
You are a dual-diligence inspector for the ctt-digup project.

Workspace root: ${REPO_ROOT}  (Windows: ${ROOT_WIN})
Card to validate: ${CARD_REL}  (Windows: ${CARD_WIN})
Report to write: ${REPORT_REL}  (Windows: ${REPORT_WIN})

Do the following:
1. Read ${CARD_REL} fully (goal, why, implementation instructions, deliverables checklist, acceptance criteria).
2. Inspect the workspace deliverables that the card claims. Verify every Deliverables checklist item and every Acceptance criterion with concrete evidence (file paths, command outputs, excerpts).
3. Write the validation report to ${REPORT_REL} using exactly the structure below (also saved at reports/TEMPLATE.md).
4. For every checklist item and acceptance criterion, state PASS or FAIL in the Result column plus evidence. Never mark PASS without evidence.
5. Put everything missing or only partially satisfied under "Gaps / follow-ups". Use "(none)" there only if every row is PASS.
6. Do not implement missing pieces, do not fix files, do not modify anything except writing ${REPORT_REL}. Only inspect and report.

Report structure:

${TEMPLATE_BODY}

Card text for reference:

--- BEGIN CARD ${CARD_REL} ---
$(cat "$CARD_PATH")
--- END CARD ---

When finished, ensure ${REPORT_REL} exists and contains the filled report.
EOF
)"

echo "==> kimi dual diligence: ${CARD_REL}" >&2
echo "==> inspector: ${KIMI}" >&2
echo "==> report:    ${REPORT_REL}" >&2

# Preferred invocation from the card spec: kimi --auto -p "..."
# Kimi 2.2.0 rejects the combination ("Cannot combine --prompt with --auto.")
# and -p is already a non-interactive one-shot, so fall back to plain -p when
# the documented form leaves no report behind.
set +e
run_kimi "$KIMI" --auto
KIMI_RC=$?
set -e

if [ ! -f "$REPORT_PATH" ] || [ ! -s "$REPORT_PATH" ]; then
  echo "==> report still missing; retrying without --auto (kimi 2.2 rejects --auto with -p)" >&2
  set +e
  run_kimi "$KIMI"
  KIMI_RC=$?
  set -e
fi

if [ ! -f "$REPORT_PATH" ]; then
  echo "error: report not created: ${REPORT_ARG} (expected at ${REPORT_PATH})" >&2
  echo "error: kimi exit code: ${KIMI_RC}" >&2
  exit 2
fi

if [ ! -s "$REPORT_PATH" ]; then
  echo "error: report is empty: ${REPORT_PATH}" >&2
  exit 2
fi

if [ "$KIMI_RC" -ne 0 ]; then
  echo "warning: kimi exited with code ${KIMI_RC}, but the report exists" >&2
fi

echo "==> report written: ${REPORT_REL}" >&2
printf '%s\n' "$REPORT_REL"
