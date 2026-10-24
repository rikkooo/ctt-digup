# Card 08 — Sub-agent execution + Kimi dual diligence

## Goal
Every card is executed by a sub-agent, and at the end of each card Kimi CLI performs a dual diligence inspection and produces a validation report against the card instructions.

## Why
"Each card must be executed by a sub agent. At the end of each card, please invoke a kimi, via kimi cli, for a dual dilligence and inspection and to generate a report with the validation of the deliverables against the card instructions."

## Implementation instructions

1. **Sub-agent execution**
   - Spawn one sub-agent per card (MiMoCode `actor` / general subagent) with:
     - the card markdown as the spec
     - workspace path `~/devs/ctt-digup`
     - instruction to implement, self-check deliverables, and stop before claiming done
2. **Kimi dual diligence** — run non-interactively after each card:
   ```bash
   kimi --auto -p "You are a dual-diligence inspector. Read cards/01-install-digup.md and inspect the workspace. Verify each deliverable and acceptance criterion with evidence (file paths, command outputs). Write reports/01-install-digup.md as a validation report: for every checklist item PASS/FAIL + evidence + gaps. Do not implement missing pieces; only inspect and report."
   ```
   - Use `--auto` so it does not block on prompts.
   - Same pattern for `cards/02` … `cards/09` (adjust paths).
3. **Report format** (`reports/NN-*.md`):
   ```markdown
   # Dual diligence — Card NN
   Inspector: kimi cli   Date: YYYY-MM-DD
   ## Summary
   ## Deliverable validation
   | Deliverable | Result | Evidence |
   |---|---|---|
   ## Acceptance criteria
   ## Gaps / follow-ups
   ```
4. **Automation** — `scripts/run-card.sh`:
   ```bash
   # usage: run-card.sh 04
   # 1) (spawn sub-agent out-of-band)  2) kimi diligence  3) print report path
   ```
5. Close the GitHub issue only after the Kimi report is PASS (or remaining gaps are listed and accepted).

## Deliverables
- [ ] `scripts/run-card.sh` (or documented procedure) for execute + kimi step
- [ ] `reports/` contains one Kimi report per card (01–09)
- [ ] Each report validates the card's deliverables with evidence
- [ ] Issues closed/commented with report links

## Acceptance criteria
- Nine reports exist; each maps 1:1 to a card checklist and states PASS/FAIL per item.
- Kimi report in `reports/08-subagent-kimi.md` validates deliverables against this card.
