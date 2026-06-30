# Tooling manifest

Registry of every Claude Code enhancement installed on this machine. `install.ps1` reproduces all of it.

> Remote: **github.com/hawlen/claude-tooling** (private). Clone + `install.ps1` = full setup on a fresh box.

---

## 1. GitHub Spec Kit — spec-driven development
- **Repo:** https://github.com/github/spec-kit
- **Type:** CLI (`specify`, installed globally via uv) **+** per-project skills + `.specify/` infra
- **Scope:** the **CLI is global**; the workflow is **per-project** (each project needs its own `.specify/`)
- **Installed:** `uv tool install specify-cli --from git+https://github.com/github/spec-kit.git --python 3.13`
- **Enable on a project** (one command, run in the project dir):
  ```powershell
  specify init --here --integration claude --script ps --force
  ```
  That scaffolds `.specify/` (constitution, templates, scripts, workflow) + the `/speckit-*` skills.
- **Use (skills, in order):** `/speckit-constitution` → `/speckit-specify` → `/speckit-plan` →
  `/speckit-tasks` → `/speckit-implement`. Quality gates: `/speckit-clarify` (before plan),
  `/speckit-analyze` (before implement), `/speckit-checklist`, `/speckit-converge`.
- **Update:** `specify self upgrade` (or `uv tool upgrade specify-cli`).
- **Note:** spec-kit's skills *require* a project's `.specify/` directory, which is why it stays
  per-project rather than copied into `~/.claude/skills/`. The one-line `specify init --here` is the cost.

## 2. Superpowers — development-methodology plugin (obra / Jesse Vincent)
- **Repo:** https://github.com/obra/superpowers · Marketplace: `obra/superpowers-marketplace`
- **Type:** Claude Code **plugin** (skills + methodology)
- **Scope:** **user (global)** — active in every session on this machine, every project
- **Installed:**
  ```powershell
  claude plugin marketplace add obra/superpowers-marketplace
  claude plugin install superpowers@superpowers-marketplace
  ```
- **Provides (skills auto-surface when relevant):** brainstorming · writing-plans ·
  test-driven-development (RED-GREEN-REFACTOR) · systematic-debugging · verification-before-completion ·
  subagent-driven-development · code-review · git-worktrees · writing-skills · using-superpowers.
- **Use:** just ask for them, e.g. "let's brainstorm this", "do this test-first", "systematically debug".
- **Update:** `claude plugin update superpowers` (restart to apply). **Disable:** `claude plugin disable superpowers`.

## 3. Council-Loop — build-and-verify methodology (skill)
- **Source:** authored in-house; this repo (`skills/council-loop/`) is now the source of truth.
- **Type:** Claude Code **skill** (markdown — pure instructions, no code)
- **Scope:** **user (global)** — `~/.claude/skills/council-loop/`
- **Installed by:** `install.ps1` copies `skills/council-loop` → `~/.claude/skills/`.
- **Use:** write **`COUNCIL-LOOP`** in any prompt to force it on; it also self-proposes (and asks first)
  at the start of any substantial build / multi-component system / research-backtest / money-or-safety-
  critical task. Core rule: nothing is DONE or TRUE until proven by **executed evidence**, attacked, and
  reproduced — never by assertion.

## 4. Subagents — generic role agents
- **Source:** vendored markdown agent pack — **upstream unconfirmed** (wshobson/agents- or
  VoltAgent/awesome-claude-code-subagents-style). TODO: pin the exact source repo + commit.
- **Type:** Claude Code **subagents** (markdown)
- **Scope:** **user (global)** — `~/.claude/agents/`
- **Installed by:** `install.ps1` copies `agents/*.md` → `~/.claude/agents/`.
- **Provides:** `code-reviewer` (opus) · `debugger` · `python-pro` · `ml-engineer` · `nlp-engineer` ·
  `data-engineer` · `powershell-5.1-expert` (all sonnet unless noted).
- **Use:** Claude auto-delegates, or ask explicitly: "use the powershell-5.1-expert agent".

## 5. Magic MCP — 21st.dev UI component generator
- **Repo:** https://github.com/21st-dev/magic-mcp · npm `@21st-dev/magic`
- **Type:** **MCP server** (npx)
- **Scope:** **user (global)** — `~/.claude.json` `mcpServers` / `claude mcp add --scope user`
- **🔑 Secret:** needs a **21st.dev API key**. **NEVER commit it.** Before running `install.ps1`, set
  `--% $env:TWENTY_FIRST_API_KEY = "<your key>"` (get one at https://21st.dev).
- **Installed by:** `install.ps1` runs (only if the env var is set):
  ```powershell
  claude mcp add magic --scope user --env "API_KEY=$env:TWENTY_FIRST_API_KEY" -- npx -y "@21st-dev/magic@latest"
  ```
- **Use:** mainly frontend/website projects — ask for UI components; Magic's tools generate/refine them.

## 6. guard-destructive — destructive-command backstop hook  ⚠️ OFF BY DEFAULT
- **Source:** authored in-house (from the TT Bot project).
- **Type:** **PreToolUse hook** (PowerShell) — pattern-blocks irreversible commands
  (`rm -rf`, `format X:`, `Format-Volume`, `Clear-Disk`, `dd if=`, `DROP TABLE`, fork bomb, …).
  Fails **open** (any error → allow), so a bug here can never stop you working.
- **Scope:** **NOT auto-enabled.** Vendored at `hooks/guard-destructive.ps1`; `install.ps1` does **not**
  wire it. It runs on *every* Bash/PowerShell call and can false-positive — opt in deliberately.
- **Enable (opt-in):** copy `hooks/guard-destructive.ps1` into a project's `.claude/hooks/` and add a
  `PreToolUse` matcher (Bash/PowerShell) in that project's `.claude/settings.local.json`, or wire it
  globally in `~/.claude/settings.json`. Remove/relax the regex list freely.

## 7. skills.sh / `npx skills` — skill discovery + install (Vercel Labs)
- **Repo:** https://github.com/vercel-labs/skills (24K★, official Vercel Labs) · Registry: https://skills.sh
- **Type:** CLI run on-demand via `npx` — nothing installed globally.
- **Role here:** the **discovery front-end** for this hub. Find battle-tested skills, vet them, then
  **vendor the keepers into this hub** (preferred over relying only on `npx skills add -g`).
- **Discover:** browse the https://skills.sh leaderboard, or `npx -y skills find "<query>" [--owner <owner>]`.
- **Vet before adopting (mirrors our own rule):** prefer 1K+ installs; trust official sources
  (`vercel-labs`, `anthropics`, `microsoft`); check the source repo's stars (<100★ → skeptical).
- **Adopt — preferred (hub stays the single gate):** copy the chosen `SKILL.md` into `skills/<name>/`, add a
  section here, wire `install.ps1`.
  **Alt — quick:** `npx skills add <owner/repo@skill> -g -y` — but the CLI targets `~/.agent/skills/` while
  Claude Code reads `~/.claude/skills/`, so verify it actually lands where CC finds it.
- **Note:** our `anthropic-skills` (docx/pdf/pptx/xlsx/skill-creator) come from `anthropics/skills` — the #2
  source on the leaderboard — so we're already in this ecosystem.

---

## Global-layer state (this machine)
- `~/.local/bin/` — `uv`, `uvx`, `specify` (CLIs on PATH).
- `~/.claude/skills/` — `council-loop` (**now hub-managed** — see §3). spec-kit skills are per-project.
- `~/.claude/agents/` — the 7 generic subagents (see §4), deployed by `install.ps1`.
- `~/.claude/` plugins — `superpowers@superpowers-marketplace` (user scope, enabled).
- `~/.claude.json` `mcpServers` — `magic` (see §5; key lives only on the machine, never in this repo).
- `reference/` — read-only ECC snapshot to mine from; never installed/run (see `reference/README.md`).

## Adding the next tool
1. Append an entry above (repo, type, scope, install, use, update).
2. Wire its install into `install.ps1` (CLI → `uv tool install`; plugin → `claude plugin install`;
   skills/commands/agents → copy into `~/.claude/<dir>/`; MCP → `claude mcp add --scope user`).
3. Re-run `install.ps1`; commit.
