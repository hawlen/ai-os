# Tooling manifest

Registry of every Claude Code enhancement installed on this machine. `install.ps1` reproduces all of it.

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

---

## Global-layer state (this machine)
- `~/.local/bin/` — `uv`, `uvx`, `specify` (CLIs on PATH).
- `~/.claude/skills/` — `council-loop` (pre-existing). spec-kit skills are installed *per project*.
- `~/.claude/` plugins — `superpowers@superpowers-marketplace` (user scope, enabled).

## Adding the next tool
1. Append an entry above (repo, type, scope, install, use, update).
2. Wire its install into `install.ps1` (CLI → `uv tool install`; plugin → `claude plugin install`;
   skills/commands/agents → copy into `~/.claude/<dir>/`; MCP → `claude mcp add --scope user`).
3. Re-run `install.ps1`; commit.
