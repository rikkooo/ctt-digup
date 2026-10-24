# Card 07 — Register cards as GitHub issues

## Goal
Create one GitHub issue per requirement card in the ctt-digup repository, so every requirement is tracked.

## Why
"Each card must be registered as github issues."

## Implementation instructions

1. Create the GitHub repository (if missing):
   ```bash
   gh repo create rikkooo/ctt-digup --public --source ~/devs/ctt-digup --push
   ```
2. For each `cards/NN-*.md`, open an issue:
   - **Title:** `NN — <card title>`
   - **Body:** full card markdown (goal, instructions, deliverables, acceptance criteria)
   - **Labels:** `card`, `requirement`, plus area labels (`install`, `indexing`, `mcp`, `cli`, `docs`, `process`)
3. Keep a mapping table in `docs/ISSUES.md`:

   | Card | Issue | URL | Status |
   |---|---|---|---|
   | 01-install-digup | #1 | ... | open |
   | ... | | | |

4. Link issues from `ROADMAP.md` status column.

## Deliverables
- [ ] GitHub repo exists and local tree is pushed
- [ ] 9 issues created (one per card) with full card body
- [ ] `docs/ISSUES.md` mapping table filled
- [ ] ROADMAP links/issue numbers updated

## Acceptance criteria
- `gh issue list` shows all nine cards; each issue body contains the deliverables checklist.
- Kimi report in `reports/07-github-issues.md` validates deliverables against this card.
