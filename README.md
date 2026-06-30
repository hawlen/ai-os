# claude-tooling

A single place to **install, manage, update, and reproduce** every Claude Code enhancement on this
machine (Alec's). Each tool here becomes available to *every* Claude Code session via the global layer
at `~/.claude/` (skills, commands, agents, settings/MCP) or a global CLI on PATH.

## Install on a new machine (one line)

Public repo — bootstrap straight from GitHub. Needs **git** + **Claude Code** already present (the script
self-installs `uv`; export `TWENTY_FIRST_API_KEY` first if you want the Magic MCP).

**Windows (PowerShell):**
```powershell
irm https://raw.githubusercontent.com/hawlen/claude-tooling/main/bootstrap.ps1 | iex
```

**macOS / Linux:**
```bash
curl -fsSL https://raw.githubusercontent.com/hawlen/claude-tooling/main/bootstrap.sh | bash
```

The bootstrap clones the hub to `~/claude-tooling` (override with `CLAUDE_TOOLING_DIR`) and runs the
idempotent installer, deploying every skill, subagent, plugin, and CLI into `~/.claude`. Re-run any time to update.

## How the global layer works

Everything under **`C:\Users\Mr.arp\.claude\`** applies to every Claude Code session, any project:

| Tool type | Lives here → global everywhere |
|---|---|
| Skills | `~/.claude/skills/<name>/SKILL.md` |
| Slash commands | `~/.claude/commands/<name>.md` |
| Subagents | `~/.claude/agents/<name>.md` |
| MCP servers | `~/.claude/settings.json` → `mcpServers` (or `claude mcp add --scope user`) |
| Plugins (bundle of the above) | `claude plugin install <name>@<marketplace>` (scope: user) |
| CLI tools | `uv tool install …` → on PATH |

## Usage

- **Fresh machine / re-sync everything:** run the idempotent installer from a clone —
  `powershell -ExecutionPolicy Bypass -File .\install.ps1` (Windows) or `bash install.sh` (macOS/Linux).
  Or just use the one-line bootstrap above.
- **Add a new GitHub tool:** add an entry to `MANIFEST.md`, wire its install into `install.ps1`
  (one of the patterns above), re-run `install.ps1`, commit.
- **Update everything:** `claude plugin update --all` (plugins) + `uv tool upgrade --all` (CLIs), or
  just re-run `install.ps1`.

See **`MANIFEST.md`** for the registry of what's installed and how to use each tool.
Project-kickoff prompts live in **`prompts/`**.
