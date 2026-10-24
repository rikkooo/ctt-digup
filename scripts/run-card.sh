#!/usr/bin/env bash
# run-card.sh — execute one ctt-digup card: print the sub-agent prompt, then
# run Kimi dual diligence and print the report path.
#
# usage: run-card.sh NN [--skip-implement]
#   NN                card number (8, 08) or card stem (08-subagent-kimi)
#   --skip-implement  do not print the sub-agent implementer prompt; go straight
#                     to kimi diligence (use when the implementation is already
#                     done and you only need the inspection)
#
# Flow (see docs/PROCESS.md):
#   1) print sub-agent prompt   (spawning the sub-agent is done out-of-band)
#   2) kimi dual diligence      (kimi --auto -p "...")
#   3) print report path        (fails if reports/NN-<slug>.md was not created)
#
# examples:
#   scripts/run-card.sh 08
#   scripts/run-card.sh 8 --skip-implement
#   scripts/run-card.sh 08-subagent-kimi --skip-implement
#
# Exit codes:
#   0  report written
#   1  usage / card not found
#   2  kimi diligence failed to create the report
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
KIMI_DILIGENCE="${SCRIPT_DIR}/kimi-diligence.sh"

usage() {
  cat >&2 <<'EOF'
usage: run-card.sh NN [--skip-implement]

  NN                card number (8, 08) or card stem (08-subagent-kimi)
  --skip-implement  skip printing the sub-agent prompt; only run kimi diligence

Steps:
  1) validates cards/NN-*.md exists
  2) prints the sub-agent implementer prompt (card text + workspace + return format)
  3) runs kimi dual diligence non-interactively (reports/NN-<slug>.md)
  4) prints the report path; fails if the report was not created

Env:
  KIMI_BIN  override the kimi executable (forwarded to kimi-diligence.sh)
EOF
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

SKIP_IMPLEMENT=0
CARD_KEY=""

for arg in "$@"; do
  case "$arg" in
    -h | --help)
      usage
      exit 0
      ;;
    --skip-implement)
      SKIP_IMPLEMENT=1
      ;;
    -*)
      echo "error: unknown option: ${arg}" >&2
      usage
      exit 1
      ;;
    *)
      if [ -n "$CARD_KEY" ]; then
        echo "error: unexpected extra argument: ${arg}" >&2
        usage
        exit 1
      fi
      CARD_KEY="$arg"
      ;;
  esac
done

if [ -z "$CARD_KEY" ]; then
  echo "error: missing card number NN" >&2
  usage
  exit 1
fi

# Normalize NN: "8" -> "08"; "08-subagent-kimi" stays as a full stem.
if [[ "$CARD_KEY" =~ ^[0-9]+$ ]]; then
  CARD_KEY="$(printf '%02d' "$((10#$CARD_KEY))")"
fi

shopt -s nullglob
CARD_CANDIDATES=("${REPO_ROOT}/cards/${CARD_KEY}"*.md)
shopt -u nullglob

# For a bare number require the "NN-" stem, e.g. 08-*.md, not 080-*.md.
if [[ "$CARD_KEY" =~ ^[0-9]+$ ]]; then
  FILTERED=()
  for c in "${CARD_CANDIDATES[@]}"; do
    base="$(basename "$c")"
    if [[ "$base" =~ ^${CARD_KEY}-.*\.md$ ]]; then
      FILTERED+=("$c")
    fi
  done
  CARD_CANDIDATES=("${FILTERED[@]+"${FILTERED[@]}"}")
fi

if [ "${#CARD_CANDIDATES[@]}" -eq 0 ]; then
  echo "error: no card matches cards/${CARD_KEY}-*.md (or cards/${CARD_KEY}.md)" >&2
  echo "available cards:" >&2
  ls "${REPO_ROOT}/cards" 2>/dev/null | sed 's/^/  /' >&2 || true
  exit 1
fi
if [ "${#CARD_CANDIDATES[@]}" -gt 1 ]; then
  echo "error: multiple cards match '${CARD_KEY}':" >&2
  for c in "${CARD_CANDIDATES[@]}"; do
    echo "  $(basename "$c")" >&2
  done
  echo "hint: pass the full stem, e.g. run-card.sh $(basename "${CARD_CANDIDATES[0]}" .md)" >&2
  exit 1
fi

CARD_PATH="${CARD_CANDIDATES[0]}"
CARD_BASE="$(basename "$CARD_PATH" .md)"   # e.g. 08-subagent-kimi
CARD_REL="cards/${CARD_BASE}.md"
REPORT_REL="reports/${CARD_BASE}.md"
REPORT_PATH="${REPO_ROOT}/${REPORT_REL}"

WORKSPACE_POSIX="$REPO_ROOT"
WORKSPACE_WIN="$(win_path "$REPO_ROOT")"

if [ "$SKIP_IMPLEMENT" -eq 0 ]; then
  # --- Sub-agent implementer prompt (to stdout; progress goes to stderr) ---
  cat <<EOF
========== SUB-AGENT PROMPT (card ${CARD_BASE}) ==========
You are a sub-agent executing one requirement card of the ctt-digup project.

Workspace: ${WORKSPACE_POSIX}  (Windows: ${WORKSPACE_WIN})
Card (this is your spec): ${CARD_REL}

Implement the card in that workspace. The card text is below.

Instructions:
1. Implement exactly what the card specifies in this workspace.
2. Self-check every Deliverables checklist item and every Acceptance criterion
   and gather evidence (file paths, command outputs).
3. Stop before claiming done: do not close any GitHub issue and do not declare
   the card complete. Dual diligence (kimi) must produce a PASS report first.
4. Report back using exactly this return format:

**Status**: success | partial | failed | blocked
**Summary**: <one-line>
<deliverables>
**Files touched**: <paths>
**Findings worth promoting**: <bullets or (none)>

----- CARD TEXT: ${CARD_REL} -----
EOF
  cat "$CARD_PATH"
  cat <<'EOF'
----- END CARD TEXT -----
========== END SUB-AGENT PROMPT ==========
EOF
  echo "==> sub-agent prompt printed above (spawn the sub-agent out-of-band with it)" >&2
else
  echo "==> --skip-implement: skipping sub-agent prompt; running kimi diligence only" >&2
fi

# --- Kimi dual diligence (inspection only; writes reports/NN-<slug>.md) ---
echo "==> kimi dual diligence for ${CARD_REL} -> ${REPORT_REL}" >&2
KIMI_DILIGENCE_ARGS=("${CARD_REL}" "${REPORT_REL}")
if ! REPORT_WRITTEN="$("${KIMI_DILIGENCE}" "${KIMI_DILIGENCE_ARGS[@]}")"; then
  echo "error: kimi diligence failed for ${CARD_REL} (no report at ${REPORT_REL})" >&2
  exit 2
fi

if [ ! -f "$REPORT_PATH" ]; then
  echo "error: report not created: ${REPORT_REL}" >&2
  exit 2
fi

echo "==> done. Report: ${REPORT_REL}" >&2
printf '%s\n' "${REPORT_WRITTEN:-$REPORT_REL}"
