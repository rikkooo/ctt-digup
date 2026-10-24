# ctt-digup delivery process

Every roadmap requirement is a **card** (`cards/NN-<slug>.md`) registered as a
GitHub issue (`docs/ISSUES.md`). A card is delivered in four steps:

```
sub-agent executes card  →  kimi inspects  →  report saved  →  issue closed only on PASS
```

## 1. Sub-agent executes the card

Each card is executed by **one sub-agent** (MiMoCode `actor` / general subagent),
never by editing the card in place and never by the inspector.

- **Spec:** the card markdown (`cards/NN-<slug>.md`), verbatim.
- **Workspace:** the ctt-digup repo root (Windows `C:\devs\ctt-digup`, WSL
  `/mnt/c/devs/ctt-digup`).
- **Duty:** implement the card, self-check every Deliverables checklist item and
  every Acceptance criterion with evidence, and **stop before claiming done** —
  in particular, do not close the GitHub issue.

`scripts/run-card.sh NN` prints the ready-to-use sub-agent prompt (card text +
workspace + return format) on stdout. Spawn the sub-agent out-of-band with that
prompt.

## 2. Kimi inspects (dual diligence)

After the sub-agent is finished, Kimi CLI performs a **dual-diligence
inspection**: it re-reads the card and verifies the workspace against it.

```bash
scripts/run-card.sh NN --skip-implement
# or directly:
scripts/kimi-diligence.sh cards/NN-<slug>.md reports/NN-<slug>.md
```

The invoker runs Kimi non-interactively:

```bash
kimi --auto -p "<inspector prompt>"
```

- `--auto` keeps Kimi from blocking on prompts (never-ask mode).
- The inspector prompt names the card, the report path, the report structure
  (`reports/TEMPLATE.md`), and orders: verify every deliverable and acceptance
  criterion with evidence (file paths, command outputs), write PASS/FAIL per
  item, list gaps. **Inspection only** — the inspector must not implement or fix
  anything.

## 3. Report saved

The report lands at `reports/NN-<slug>.md` (same stem as the card). Structure
(`reports/TEMPLATE.md`):

- `# Dual diligence — Card NN` + `Inspector: kimi cli   Date: YYYY-MM-DD`
- `## Summary` — overall verdict
- `## Deliverable validation` — table, one row per Deliverables checklist item:
  `| Deliverable | Result | Evidence |`
- `## Acceptance criteria` — table, one row per acceptance criterion
- `## Gaps / follow-ups` — everything missing or partial; `(none)` only if all PASS

`run-card.sh` / `kimi-diligence.sh` **fail if the report was not created** (or is
empty). The scripts print the report path on stdout on success.

## 4. Issue closed only on PASS

Close (or comment on) the GitHub issue **only after** the Kimi report is **PASS**
— or when the remaining gaps in `## Gaps / follow-ups` are listed *and* explicitly
accepted.

- Never close an issue on the sub-agent's self-assessment alone.
- Link the report in the issue comment, e.g.
  `Dual diligence report: reports/NN-<slug>.md — PASS` (see `docs/ISSUES.md` for
  the issue map).
- If the report is FAIL: open follow-up work for the gaps, re-run the sub-agent
  for the missing pieces, then re-run diligence (`run-card.sh NN --skip-implement`).

## Tooling reference

| Command | Purpose |
|---|---|
| `scripts/run-card.sh NN` | print sub-agent prompt, then run kimi diligence |
| `scripts/run-card.sh NN --skip-implement` | run kimi diligence only (implementation already done) |
| `scripts/kimi-diligence.sh <card> <report>` | standalone kimi invoker (card path + report path) |

Both scripts are bash (work under WSL and Git Bash), LF line endings, and
auto-detect the Kimi binary (`KIMI_BIN` overrides). Relative paths are resolved
against the repo root, not the caller's cwd.
