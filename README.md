# claude-tooling

A single place to **install, manage, update, and reproduce** every Claude Code enhancement on this
machine (Alec's). Each tool here becomes available to *every* Claude Code session via the global layer
at `~/.claude/` (skills, commands, agents, settings/MCP) or a global CLI on PATH.

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

- **Fresh machine / re-sync everything:** run the installer (idempotent):
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\install.ps1
  ```
- **Add a new GitHub tool:** add an entry to `MANIFEST.md`, wire its install into `install.ps1`
  (one of the patterns above), re-run `install.ps1`, commit.
- **Update everything:** `claude plugin update --all` (plugins) + `uv tool upgrade --all` (CLIs), or
  just re-run `install.ps1`.

See **`MANIFEST.md`** for the registry of what's installed and how to use each tool.
Project-kickoff prompts live in **`prompts/`**.
