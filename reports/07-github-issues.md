# Dual diligence - Card 07

Inspector: kimi cli   Date: 2026-10-24

## Summary

Inspected the GitHub repo `rikkooo/ctt-digup` via `gh`, the local git state, `docs/ISSUES.md`, and `ROADMAP.md` against every deliverable and acceptance criterion in `cards/07-github-issues.md`. The repo exists (public, default branch `main`) and the committed local tree is fully pushed (HEAD == origin/main, zero unpushed commits). All nine issues #1–#9 exist — one per card, correct `NN — <title>` titles, `card`/`requirement`/area labels — and every issue body is a verbatim copy of its card markdown (diff-verified for all 9), including the Deliverables checklist. Two deliverables fall short: `docs/ISSUES.md` is a bullet list rather than the card-specified mapping table (no Issue-number/Status columns) and is untracked in git, so it is not on GitHub at all; and `ROADMAP.md` has no issue links or numbers — the Status column is empty for all nine milestone rows. Overall verdict: **FAIL** (2 of 4 deliverables fully pass; ROADMAP linking missing, ISSUES.md only partial).

## Deliverable validation

| Deliverable | Result | Evidence |
|---|---|---|
| GitHub repo exists and local tree is pushed | PASS | `gh repo view rikkooo/ctt-digup --json ...` → `{"name":"ctt-digup","owner":"rikkooo","visibility":"PUBLIC","defaultBranchRef":"main","pushedAt":"2026-10-24T07:02:23Z","url":"https://github.com/rikkooo/ctt-digup"}`. `git remote -v` → `origin https://github.com/rikkooo/ctt-digup.git (fetch/push)`; `git status -sb` → `## main...origin/main` (no ahead/behind); `git rev-parse HEAD` == `git rev-parse @{u}` == `a87043655f6513e9cd3ae1c88ff640cdba627b3b`; `git log origin/main..HEAD` empty. Remote tree (`git ls-tree -r origin/main --name-only`) contains README.md, ROADMAP.md, cards/01..09. Caveat (not part of this card's original push): current working tree has untracked paths (`docs/`, `reports/`, `scripts/`, `skill/`, `src/`, `man/`, `.agents/`, `mcp.json`, `.gitignore`) and a modified README.md from later cards' work — not yet pushed; see Gaps. |
| 9 issues created (one per card) with full card body | PASS | `gh issue list -R rikkooo/ctt-digup --state all` returns exactly 9 OPEN issues: #1 `01 — Install DigUp engine + CLI` (install), #2 `02 — Index Windows 11 folders` (indexing), #3 `03 — Index WSL Ubuntu-26.04 folders` (indexing), #4 `04 — MCP server for DigUp` (mcp), #5 `05 — Convert MCP to CLI with mcp2cli` (mcp, cli), #6 `06 — CLI documentation (man + manual)` (docs), #7 `07 — Register cards as GitHub issues` (process), #8 `08 — Sub-agent execution + Kimi dual diligence` (process), #9 `09 — Agent skill package` (skill). All carry `card` + `requirement` labels plus area labels, matching card instruction 2. Bodies: `gh issue view N --json body` diffed against `cards/NN-*.md` for all nine — verbatim matches (only a trailing blank line added by GitHub on some); every body contains a `Deliverables` section (grep count 1 each) with 3–4 `- [ ]` checklist items and an `Acceptance criteria` section. |
| `docs/ISSUES.md` mapping table filled | PARTIAL | `docs/ISSUES.md` exists locally and maps all nine cards to their issue URLs, e.g. `- 01-install-digup.md => https://github.com/rikkooo/ctt-digup/issues/1` … `- 09-agent-skill.md => …/issues/9` (docs/ISSUES.md:3-11). Two shortfalls: (a) format deviates from the card's specified table `\| Card \| Issue \| URL \| Status \|` — it is a bullet list with no explicit issue-number column and no Status column (card step 3 shows a markdown table with an `open` status value); (b) `docs/` is untracked in git (`git status` shows `?? docs/`), so the mapping is not committed or pushed and does not exist on GitHub. |
| ROADMAP links/issue numbers updated | FAIL | `ROADMAP.md:9-17` milestone table has an empty Status cell for all nine rows; grep for `issues/`, `#1`..`#9` or any issue reference in `ROADMAP.md` returns nothing. Card instruction 4 explicitly requires "Link issues from `ROADMAP.md` status column" — not implemented. ROADMAP.md is tracked and pushed, so the omission is visible on GitHub, not a push lag. |

## Acceptance criteria

| Criterion | Result | Evidence |
|---|---|---|
| `gh issue list` shows all nine cards; each issue body contains the deliverables checklist | PASS | `gh issue list -R rikkooo/ctt-digup --limit 30 --state all` → exactly 9 issues, numbers 1–9, titles matching `NN — <card title>` for cards 01–09 (see Deliverable 2 evidence). Each of the 9 bodies contains a `## Deliverables` section with the card's `- [ ]` checklist (verified by diffing every body against its source card file — verbatim). |
| Kimi report in `reports/07-github-issues.md` validates deliverables against this card | PASS | This report: `reports/07-github-issues.md`, mapping 1:1 to the card's four Deliverables and two Acceptance criteria with command-output evidence. |

## Gaps / follow-ups

- **ROADMAP Status column empty (blocks deliverable 4)**: add the issue number/link per milestone row in `ROADMAP.md` (e.g. `#7` / `https://github.com/rikkooo/ctt-digup/issues/7` in the Status column), then commit and push.
- **`docs/ISSUES.md` format + visibility**: convert the bullet list to the card-specified table with `Card | Issue | URL | Status` columns (fill Status as `open` for all nine), and commit/push it — currently the whole `docs/` tree is untracked, so the mapping exists only on this machine.
- **Unpushed work tree**: unrelated to this card's original scope but worth noting — `docs/`, `reports/`, `scripts/`, `skill/`, `src/`, `man/`, `.agents/`, `mcp.json`, `.gitignore` are untracked and `README.md` has uncommitted modifications; later cards' outputs (including this report) are not on GitHub until committed and pushed.
