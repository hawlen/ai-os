# AI OS

A configuration layer that makes every Claude Code session — on every PC you own — operate under the same universal principles, and keeps a ledger of what happens on each machine.

## What it actually does (honest scope)

| Goal | Mechanism | Status |
|---|---|---|
| Universal principles in every session | `install.ps1` deploys everything in `principles/` into `~/.claude/CLAUDE.md` (loaded by Claude Code at the start of every session, in every project) | ✅ v1 |
| Same principles on all PCs | This folder is a git repo. Push it to a **private** remote, clone on another PC, run `install.ps1`. Re-run after pulling updates. | ✅ v1 (manual sync) |
| "Knows everything that goes on" | Two sources: (1) Claude Code already stores full session transcripts under `~/.claude/projects/`; (2) AI OS registers SessionStart/SessionEnd hooks that append a machine-local ledger to `logs/activity.jsonl` | ✅ v1 (per-machine) |
| Model orchestration (Sonnet executes, Opus plans, Fable architects) | `principles/00-model-orchestration.md` — enforced by the running model via subagent delegation with model overrides | ✅ v1 |

### Known limits (by design, not bugs)

- **No automatic cloud sync.** A Claude Code subscription syncs your login and usage, not files or settings. Cross-PC distribution is git pull + `install.ps1`. A scheduled task could automate the pull later.
- **The main session model can't be hot-swapped by a config file.** You pick it with `/model`. The orchestration policy works around this: whatever model is running delegates work to subagents spawned at the right tier (`sonnet` / `opus` / `fable`).
- **The activity ledger is per-machine** and gitignored. Syncing it through the repo would require committing on every session — possible later via a hook, not enabled by default.

## Layout

```
AI OS/
├── README.md                     ← this file
├── install.ps1                   ← deploys principles + registers hooks (idempotent)
├── principles/
│   └── 00-model-orchestration.md ← universal principle #1 (add more as NN-name.md)
├── hooks/
│   └── log-session.ps1           ← SessionStart/SessionEnd → logs/activity.jsonl
└── logs/
    └── activity.jsonl            ← machine-local session ledger (gitignored)
```

## Install on a new PC

```powershell
git clone https://github.com/hawlen/ai-os.git "C:\AI OS"
powershell -ExecutionPolicy Bypass -File "C:\AI OS\install.ps1"
```

`install.ps1` is idempotent and non-destructive:
- It writes the principles into `~/.claude/CLAUDE.md` **between `<!-- AI-OS:BEGIN -->` / `<!-- AI-OS:END -->` markers**, leaving anything you wrote outside the markers untouched. Re-running replaces only the managed block.
- It adds the logging hooks to `~/.claude/settings.json` only if they aren't already there, and if the checkout has moved it repoints existing hooks at the new path. Pass `-SkipHooks` to skip that part.

## Update the principles everywhere

1. Edit or add files in `principles/` on any PC.
2. Commit + push.
3. On each other PC: `git pull` then re-run `install.ps1`.

## Uninstall

- Delete the `<!-- AI-OS:BEGIN -->` … `<!-- AI-OS:END -->` block from `~/.claude/CLAUDE.md`.
- Remove the two hook entries containing `log-session.ps1` from `~/.claude/settings.json`.

## Roadmap ideas

- Auto-pull principles on a schedule (Windows Task Scheduler or a Claude Code scheduled task).
- Cross-machine ledger sync (hook that commits `logs/` to a separate branch).
- More principles: coding standards, security posture, project conventions.
