# ROADMAP — ctt-digup

**Mission (restated):** Make DigUp's on-device semantic file search available to every agent and every shell — on Windows 11 and WSL Ubuntu-26.04 — through a first-class MCP server and a well-documented CLI, with each requirement shipped as a verifiable card, executed by a sub-agent and dual-checked by Kimi.

## Milestones

| # | Card | Milestone | Status |
|---|---|---|---|
| 1 | [cards/01-install-digup.md](cards/01-install-digup.md) | DigUp engine + CLI installed on WSL Ubuntu-26.04 and Windows 11 | [#1](https://github.com/rikkooo/ctt-digup/issues/1) |
| 2 | [cards/02-index-windows.md](cards/02-index-windows.md) | Windows 11 user folders indexed and searchable | [#2](https://github.com/rikkooo/ctt-digup/issues/2) |
| 3 | [cards/03-index-wsl.md](cards/03-index-wsl.md) | WSL Ubuntu-26.04 folders indexed and searchable | [#3](https://github.com/rikkooo/ctt-digup/issues/3) |
| 4 | [cards/04-mcp-server.md](cards/04-mcp-server.md) | MCP server exposing DigUp operations | [#4](https://github.com/rikkooo/ctt-digup/issues/4) |
| 5 | [cards/05-mcp2cli.md](cards/05-mcp2cli.md) | MCP server converted to CLI via mcp2cli | [#5](https://github.com/rikkooo/ctt-digup/issues/5) |
| 6 | [cards/06-cli-docs.md](cards/06-cli-docs.md) | bash man page + comprehensive manual with setup/usage/examples | [#6](https://github.com/rikkooo/ctt-digup/issues/6) |
| 7 | [cards/07-github-issues.md](cards/07-github-issues.md) | All cards registered as GitHub issues and tracked | [#7](https://github.com/rikkooo/ctt-digup/issues/7) |
| 8 | [cards/08-subagent-kimi.md](cards/08-subagent-kimi.md) | Sub-agent execution + Kimi dual-diligence reports per card | [#8](https://github.com/rikkooo/ctt-digup/issues/8) |
| 9 | [cards/09-agent-skill.md](cards/09-agent-skill.md) | Skill package usable by any other agent | [#9](https://github.com/rikkooo/ctt-digup/issues/9) |

## Principles

1. **Card = requirement = issue.** No silent work. Everything is specified in `cards/` and tracked on GitHub.
2. **Sub-agent implements, Kimi inspects.** Implementation and validation are separate roles.
3. **Local-first.** Indexes and models never leave the machine.
4. **Documented before claimed.** A feature is done when the man page and manual cover it.

## Exit criteria (project complete)

- [ ] `digup status` shows non-empty indexes for Windows and WSL scopes
- [ ] MCP server lists and executes DigUp tools over stdio
- [ ] `ctt-digup` (mcp2cli) CLI runs the same tools from bash
- [ ] `man ctt-digup` works and `docs/MANUAL.md` covers setup + usage + examples
- [ ] Nine GitHub issues exist and are closed with linked reports
- [ ] `reports/*.md` Kimi validation reports exist per card
- [ ] `skill/` is installable and another agent can invoke it
