# Tooling manifest

Registry of every Claude Code enhancement installed on this machine. `install.ps1` reproduces all of it.

> Remote: **github.com/hawlen/ai-os** (public; formerly `claude-tooling`). Clone + `install.ps1` = full setup on a fresh box.
> This is the **machine layer** of AI OS. The **project template** lives at github.com/hawlen/ai-os-template.

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
- **Repo:** https://github.com/obra/superpowers · Marketplace: `claude-plugins-official` (Anthropic's official)
- **Type:** Claude Code **plugin** (skills + methodology)
- **Scope:** **user (global)** — active in every session on this machine, every project
- **Installed:**
  ```powershell
  claude plugin install superpowers@claude-plugins-official
  ```
- **Coordinate note (2026-07-04):** standardized from `superpowers@superpowers-marketplace` to the
  official marketplace, because hawlen/ai-os-template enables `superpowers@claude-plugins-official` at project
  scope — two coordinates for the same plugin load its ~20 skills TWICE per session (pure token waste).
  `install.ps1`/`install.sh` auto-migrate (uninstall the old coordinate before installing).
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
- **Re-tuned in-house:** `powershell-5.1-expert` was rewritten for **Windows dev-scripting** (5.1 gotchas:
  UTF-16/BOM encoding, no `&&`/ternary, native-exe stderr & stdin corruption, TLS 1.2, no coreutils) — it is
  no longer the upstream AD/DNS/DHCP/GPO enterprise-infra version.
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
  **Alt — quick:** `npx skills add <owner/repo@skill> -g -y` — **verified**: it auto-detects Claude Code,
  runs Socket/Snyk/Gen supply-chain scans, then **copies the skill into `~/.claude/skills/`** (staging in
  `~/.agents/skills/`), so it works for CC out of the box. `npx skills list -g` lists global installs.
- **Note:** our `anthropic-skills` (docx/pdf/pptx/xlsx/skill-creator) come from `anthropics/skills` — the #2
  source on the leaderboard — so we're already in this ecosystem.

## 8. python-performance-optimization — skill (first adopted via §7)
- **Source:** `wshobson/agents@python-performance-optimization` (MIT, 37K★, 27.7K installs on skills.sh).
  The first skill brought in through the discovery→vet→vendor workflow.
- **Type:** Claude Code **skill** — profile/optimize Python (cProfile, memory profilers, perf best practices).
- **Scope:** user (global) — `skills/python-performance-optimization/` → `~/.claude/skills/` (via `install.ps1`).
- **Vetting:** passed the `npx skills` Socket/Snyk/Gen scans at install (Safe / 0 alerts / Low Risk).
- **Use:** ARPWIZ Python hot-paths — ask to profile or optimize slow Python.

## 9. python-testing-patterns — skill (via §7)
- **Source:** `wshobson/agents@python-testing-patterns` (MIT, 37K★, 25.8K installs).
- **Type:** skill — pytest, fixtures, mocking, TDD strategies.
- **Scope:** user (global) — `skills/python-testing-patterns/` → `~/.claude/skills/`.
- **Vetting:** Socket/Snyk/Gen = Safe / 0 alerts / Low Risk. Markdown only (SKILL.md + 2 refs).
- **Use:** ARPWIZ test suites.

## 10. web-design-guidelines — skill (via §7)
- **Source:** `vercel-labs/agent-skills@web-design-guidelines` (official Vercel, 28.5K★, **425K installs** — #5 leaderboard).
- **Type:** skill — audits UI code against Vercel's Web Interface Guidelines (accessibility / UX / design).
- **Scope:** user (global) — `skills/web-design-guidelines/` → `~/.claude/skills/`.
- **Vetting — Snyk Med, RESOLVED by pinning:** upstream the skill WebFetched its rules live at runtime (the
  Med flag). We **pinned** a snapshot — `web-interface-guidelines.md` (commit `4e799d4`) sits beside `SKILL.md`,
  which now reads the local copy instead of fetching. Self-contained, reproducible, no runtime network call.
  Re-pin by re-fetching `command.md` from `vercel-labs/web-interface-guidelines`.
- **Use:** AIOX client sites — "review my UI / check accessibility / audit design".

## 11. tailwind-css-patterns — skill (via §7)
- **Source:** `giuseppe-trisciuoglio/developer-kit@tailwind-css-patterns` (MIT, 294★, 12.8K installs; indie author).
- **Type:** skill — Tailwind utility-first patterns: responsive, layout, flex/grid, spacing, typography.
- **Scope:** user (global) — `skills/tailwind-css-patterns/` → `~/.claude/skills/`.
- **Vetting:** Socket/Snyk/Gen = Safe / 0 alerts / Low Risk. 9 files, no executables.
- **Use:** upcoming Tailwind work on the AIOX client sites.

## 12. ECC-mined: money-critical correctness & safety (agents + skills)
Cherry-picked from the read-only ECC reference (`reference/ECC/` @ `2159ed2`, ECC is MIT) via the §7 mining pass.
All five are **markdown-only and self-contained** (independently re-scanned: no runtime fetch/exec).
`mle-workflow` and `llm-trading-agent-security` have been **re-skinned in-house for ARPWIZ** (walk-forward /
leakage / fake-edge framing; FTMO/Vantage rules, Alpaca bars, paper-first + human-in-the-loop). The other
three are stock ECC — patterns transfer; re-skin opportunistically.
- **Agents → `~/.claude/agents/`:**
  - `mle-reviewer` — adversarially reviews ML/backtests for **leakage & look-ahead bias** (fake-edge defense).
  - `silent-failure-hunter` — hunts swallowed exceptions / stale-data fallbacks in money-critical paths.
- **Skills → `~/.claude/skills/`:**
  - `mle-workflow` — chronological-split + data-contract + promotion-gate discipline for strategy search.
  - `latency-critical-systems` — p50/p95/p99 + freshness method for the Alpaca → bar-store → execution hot path.
  - `llm-trading-agent-security` — spend limits, circuit breakers, treat-market-input-as-attack for order authority.
- **Deployed by:** `install.ps1` (agents + skills loops). **Provenance TODO:** original ECC sub-authors unpinned.

## 13. AI OS Dashboard — local project/observability dashboard
- **Repo:** https://github.com/hawlen/ai-os-dashboard-dist (public, code-only distribution mirror).
  Active development is in a separate **private** repo; the mirror is a clean-history snapshot with
  no build docs — so section 7 can clone it anonymously without exposing dev history.
- **Type:** PowerShell 5.1 generator (`generate.ps1` → self-contained `dashboard.html`) + desktop shortcut.
- **Scope:** **per-machine** — cloned to `~\ai-os-dashboard` (override `$env:AI_OS_DASHBOARD_DIR`;
  path resolved by `lib\Dashboard.ps1`'s `Resolve-DashboardDir`, unit-tested in `tests\Dashboard.Tests.ps1`).
- **Installed by:** `install.ps1` section 7 clones/fast-forwards the mirror, then runs the repo's own
  `install.ps1` (Chrome probe → WScript.Shell desktop shortcut; falls back to the default browser
  when Chrome is absent). A failed clone/pull Warns and skips (never aborts the install). Windows-only
  — `install.sh` prints a skip note.
- **Update:** re-run the bootstrap — section 7 does `git pull --ff-only` and refreshes the shortcut.
  To publish new dashboard code, snapshot the private dev repo into the mirror (see the dev repo).
- **Use:** double-click the **AI OS Dashboard** desktop shortcut — it regenerates `dashboard.html`
  from `~/.claude` + project folders (all read-only) and opens it.

---

## Global-layer state (this machine)
- `~/.local/bin/` — `uv`, `uvx`, `specify` (CLIs on PATH).
- `~/.claude/skills/` — `council-loop` (**now hub-managed** — see §3). spec-kit skills are per-project.
- `~/.claude/agents/` — the 7 generic subagents (see §4), deployed by `install.ps1`.
- `~/.claude/` plugins — `superpowers@claude-plugins-official` (user scope, enabled).
- `~/.claude.json` `mcpServers` — `magic` (see §5; key lives only on the machine, never in this repo).
- `~\ai-os-dashboard\` — dashboard clone (see section 13); desktop shortcut `AI OS Dashboard.lnk`.
- `reference/` — read-only ECC snapshot to mine from; never installed/run (see `reference/README.md`).

## Adding the next tool
1. Append an entry above (repo, type, scope, install, use, update).
2. Wire its install into `install.ps1` (CLI → `uv tool install`; plugin → `claude plugin install`;
   skills/commands/agents → copy into `~/.claude/<dir>/`; MCP → `claude mcp add --scope user`).
3. Re-run `install.ps1`; commit.
