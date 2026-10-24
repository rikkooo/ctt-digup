# Card 09 — Agent skill package

## Goal
Create a skill that can be used by any other agent to operate ctt-digup (index, search, status, MCP/CLI).

## Why
"Finally, create a skill that can be used by any other agent."

## Implementation instructions

1. Create `skill/ctt-digup/SKILL.md` following the standard skill format:
   ```markdown
   ---
   name: ctt-digup
   description: Semantic file search over Windows 11 and WSL folders via DigUp. Use when the user asks to find files by meaning, index folders, or query the ctt-digup index/CLI/MCP.
   ---
   # ctt-digup skill
   ## When to use
   ## Setup check
   ## Commands
   ## Examples
   ## Troubleshooting
   ```
2. Content must teach another agent to:
   - verify install (`digup --help`, `ctt-digup --help`)
   - index Windows (`/mnt/c/...`) and WSL (`~/devs`) folders
   - search with natural language and `code:` queries
   - read `status` / JSON outputs
   - fall back to raw `digup` if mcp2cli is missing
3. Include a short prompt template for sub-agents (how to report results).
4. Install path (document both):
   - Project: `.claude/skills/ctt-digup/SKILL.md` or `.agents/skills/ctt-digup/SKILL.md`
   - User: `~/.claude/skills/ctt-digup/SKILL.md`
5. Validate: a fresh agent session can load the skill and run `digup status` + one search without extra context.

## Deliverables
- [ ] `skill/ctt-digup/SKILL.md` complete (no TODOs)
- [ ] Skill copied to a discoverable skills directory
- [ ] Manual section "Using the skill from other agents"
- [ ] Smoke-test evidence in the Kimi report

## Acceptance criteria
- Skill description triggers correctly; commands in the skill work as written.
- Kimi report in `reports/09-agent-skill.md` validates deliverables against this card.
