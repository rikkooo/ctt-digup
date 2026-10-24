# ctt-digup skill package

Agent skill that teaches any agent to run DigUp / ctt-digup: verify install, index Windows 11 and WSL folders, search by meaning and by `code:` query, read status/JSON, and fall back to raw `digup` when mcp2cli is missing.

Source of truth: [`skill/ctt-digup/SKILL.md`](ctt-digup/SKILL.md).

## Install paths

Copy `skill/ctt-digup/SKILL.md` to one of these (keep the `ctt-digup/` folder name):

| Scope | Path | Who loads it |
|---|---|---|
| Project (Claude Code) | `.claude/skills/ctt-digup/SKILL.md` | Claude Code sessions in this repo |
| Project (in-repo, agent-agnostic) | `.agents/skills/ctt-digup/SKILL.md` | Agents that scan `.agents/skills/` (also kept in this repo) |
| User (all projects) | `~/.claude/skills/ctt-digup/SKILL.md` | Every Claude Code project for that user |

On Windows, the user path is `C:\Users\<name>\.claude\skills\ctt-digup\SKILL.md`. In WSL, `~/.claude/skills/ctt-digup/SKILL.md`.

One-shot install (from the repo root, bash/WSL):

```bash
# Project — Claude Code
mkdir -p .claude/skills/ctt-digup
cp skill/ctt-digup/SKILL.md .claude/skills/ctt-digup/SKILL.md

# Project — .agents (already present in this repo; re-copy after edits)
mkdir -p .agents/skills/ctt-digup
cp skill/ctt-digup/SKILL.md .agents/skills/ctt-digup/SKILL.md

# User — all projects
mkdir -p ~/.claude/skills/ctt-digup
cp skill/ctt-digup/SKILL.md ~/.claude/skills/ctt-digup/SKILL.md
```

PowerShell (Windows):

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.claude\skills\ctt-digup" | Out-Null
Copy-Item -Force skill\ctt-digup\SKILL.md "$env:USERPROFILE\.claude\skills\ctt-digup\SKILL.md"
```

After editing `skill/ctt-digup/SKILL.md`, re-copy to every install path you use.

## Using the skill from other agents

1. **Load it.** Point the agent at the installed `SKILL.md` (project skill dir or user skill dir). In a prompt you can say: *"Use the ctt-digup skill to find …"* or *"Follow `.agents/skills/ctt-digup/SKILL.md`"*.
2. **First action in the session** is the skill's Setup check: `digup --help`, optional `ctt-digup --help`, then `digup status`.
3. **Give the agent a corpus.** Windows files live under `/mnt/c/Users/enric/...` (index `~/.local/share/digup-index-windows`); WSL files under `~/devs` (index `~/.local/share/digup-index-wsl`). Pass the matching `--index DIR` on every call.
4. **Ask for the skill's result-reporting template** when the agent is a sub-agent reporting back — every hit must carry a real `path`, and `vectors: 0` must be reported as "unindexed", not "no results".
5. **Sub-agent prompt you can paste:**

   ```text
   Use the ctt-digup skill (skill/ctt-digup/SKILL.md).
   1. Run: digup --help && digup status
   2. Find files matching: <user request>
      - Documents/Desktop/Downloads -> --index ~/.local/share/digup-index-windows
      - ~/devs or code             -> --index ~/.local/share/digup-index-wsl  (code: queries after digup index ~/devs --code)
   3. Use digup search "<words>" -n 5 --json (fall back to raw digup if ctt-digup is missing).
   4. Reply with the skill's "digup result report" template (command, index, hits with path+score+excerpt, notes).
   ```

6. **MCP agents** can call tools `digup_search`, `digup_index`, `digup_estimate`, `digup_status`, `digup_download_model` when `src/mcp-server/index.js` is running; otherwise run the same operations through `digup`.

## Smoke-test (fresh agent session)

A session with only this skill loaded must be able to run:

```bash
digup --help
digup status
digup search "invoice from last March" -n 5 --json
```

Expected on a healthy machine:

- `digup --help` prints the DigUp developer CLI command list (install: `/usr/local/bin/digup`).
- `digup status` prints `index: …`, `vectors: N …`, per-kind counts. If `vectors: 0`, indexing has not run yet — the agent should say so and offer `digup index …`.
- `digup search … --json` prints a JSON array of hits (`path`, `kind`, `score`, …) or a pretty-printed empty array / `no good matches` when nothing is indexed.

`ctt-digup --help` may still be absent (mcp2cli not linked yet). The skill's fallback covers that; it is not a smoke-test failure.
