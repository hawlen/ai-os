#requires -Version 5
<#
  AI OS machine-layer installer — IDEMPOTENT. Re-installs / re-syncs every global Claude Code tool on this
  machine. Safe to run repeatedly.

  Run:  powershell -ExecutionPolicy Bypass -File .\install.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
function Info($m) { Write-Host "[ai-os] $m" -ForegroundColor Cyan }
function Good($m) { Write-Host "   OK  $m" -ForegroundColor Green }
function Warn($m) { Write-Host "   !!  $m" -ForegroundColor Yellow }

$bin     = Join-Path $env:USERPROFILE '.local\bin'
$uv      = Join-Path $bin 'uv.exe'
$specify = Join-Path $bin 'specify.exe'

# --- 1. uv (package manager for global CLI tools) ----------------------------------------------
Info 'Ensuring uv is installed...'
if (-not (Test-Path $uv)) {
    irm https://astral.sh/uv/install.ps1 | iex
}
if (Test-Path $uv) { Good ('uv ' + (& $uv --version)) } else { throw 'uv install failed' }

# --- 2. spec-kit CLI (specify) — spec-driven development --------------------------------------
#   Global CLI; per-project `.specify/` is created with `specify init --here` (see MANIFEST.md).
Info 'Installing / updating spec-kit CLI (specify)...'
& $uv tool install specify-cli --from git+https://github.com/github/spec-kit.git --python 3.13 --force
if (Test-Path $specify) { Good ('specify ' + (& $specify --version)) } else { Warn 'specify shim not found in ~/.local/bin' }

# --- 3. Superpowers — Claude Code plugin (user scope, global) ----------------------------------
Info 'Installing / updating superpowers plugin (user scope)...'
# Migrate off the old superpowers-marketplace coordinate — ai-os enables
# superpowers@claude-plugins-official at project scope, and two coordinates load the skills twice.
try { & claude plugin uninstall superpowers@superpowers-marketplace 2>$null } catch {}
try {
    & claude plugin install superpowers@claude-plugins-official 2>$null
    Good 'superpowers installed/enabled (restart Claude Code to apply if it was just added)'
} catch { Warn "plugin install (likely already installed): $($_.Exception.Message)" }

# --- 4. skills (user scope, global) ------------------------------------------------------------
#   Deploys every directory under skills\ → ~/.claude/skills/ (council-loop, python-performance-
#   optimization, and any future vendored skill).
Info 'Deploying skills to ~/.claude/skills ...'
$skillsSrc = Join-Path $PSScriptRoot 'skills'
$skillsDst = Join-Path $env:USERPROFILE '.claude\skills'
New-Item -ItemType Directory -Force $skillsDst | Out-Null
Get-ChildItem $skillsSrc -Directory | ForEach-Object { Copy-Item $_.FullName $skillsDst -Recurse -Force }
Good ((Get-ChildItem $skillsSrc -Directory | Measure-Object).Count.ToString() + ' skill(s) deployed to ~/.claude/skills')

# --- 5. generic subagents (user scope, global) -------------------------------------------------
Info 'Deploying subagents to ~/.claude/agents ...'
$agentsSrc = Join-Path $PSScriptRoot 'agents'
$agentsDst = Join-Path $env:USERPROFILE '.claude\agents'
New-Item -ItemType Directory -Force $agentsDst | Out-Null
Copy-Item (Join-Path $agentsSrc '*.md') $agentsDst -Force
Good ((Get-ChildItem $agentsSrc -Filter *.md | Measure-Object).Count.ToString() + ' subagents deployed to ~/.claude/agents')

# --- 6. Magic MCP (21st.dev) — user scope ------------------------------------------------------
#   Needs a 21st.dev API key. Set $env:TWENTY_FIRST_API_KEY before running. Never commit the key.
Info 'Configuring Magic MCP (user scope)...'
if ($env:TWENTY_FIRST_API_KEY) {
    try {
        & claude mcp add magic --scope user --env "API_KEY=$env:TWENTY_FIRST_API_KEY" -- npx -y '@21st-dev/magic@latest' 2>$null
        Good 'Magic MCP configured (user scope)'
    } catch { Warn "Magic MCP add (likely already present): $($_.Exception.Message)" }
} else {
    Warn 'TWENTY_FIRST_API_KEY not set — skipping Magic MCP. Set it and re-run to enable (key at https://21st.dev).'
}

# --- 7. AI OS Dashboard — per-machine clone + desktop shortcut (Windows) ------------------------
#   Clones (or fast-forwards) the dashboard repo, then runs its own installer to (re)create the
#   desktop shortcut. Wrapped so a dashboard failure never aborts the rest of the install.
Info 'Installing / updating AI OS Dashboard...'
$dashDir = if ($env:AI_OS_DASHBOARD_DIR) { $env:AI_OS_DASHBOARD_DIR } else { Join-Path $env:USERPROFILE 'ai-os-dashboard' }
try {
    if (Test-Path (Join-Path $dashDir '.git')) {
        git -C $dashDir pull --ff-only
    } else {
        git clone https://github.com/hawlen/ai-os-dashboard.git $dashDir
    }
    & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $dashDir 'install.ps1')
    Good "dashboard ready at $dashDir (desktop shortcut created)"
} catch {
    Warn "dashboard install skipped: $($_.Exception.Message)"
}

# --- guard-destructive hook: VENDORED ONLY, intentionally NOT enabled --------------------------
#   hooks\guard-destructive.ps1 is a destructive-command backstop. It is deliberately NOT wired here:
#   it runs on every Bash/PowerShell call and can false-positive. To opt in, copy it into a project's
#   .claude\hooks\ and add a PreToolUse matcher in settings (see MANIFEST.md §6).
Info 'guard-destructive hook is vendored but OFF by default (see MANIFEST.md to enable).'

# --- Summary ----------------------------------------------------------------------------------
Info 'Installed tooling:'
try { & claude plugin list 2>$null } catch {}
Info 'Done. Per-project step for spec-kit:  specify init --here --integration claude --script ps --force'
Info 'Project kickoff prompts live in .\prompts\'
