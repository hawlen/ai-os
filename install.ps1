#requires -Version 5
<#
  claude-tooling installer — IDEMPOTENT. Re-installs / re-syncs every global Claude Code tool on this
  machine. Safe to run repeatedly.

  Run:  powershell -ExecutionPolicy Bypass -File .\install.ps1
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
function Info($m) { Write-Host "[claude-tooling] $m" -ForegroundColor Cyan }
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
try { & claude plugin marketplace add obra/superpowers-marketplace 2>$null } catch { Warn "marketplace add (likely already present): $($_.Exception.Message)" }
try {
    & claude plugin install superpowers@superpowers-marketplace 2>$null
    Good 'superpowers installed/enabled (restart Claude Code to apply if it was just added)'
} catch { Warn "plugin install (likely already installed): $($_.Exception.Message)" }

# --- Summary ----------------------------------------------------------------------------------
Info 'Installed tooling:'
try { & claude plugin list 2>$null } catch {}
Info 'Done. Per-project step for spec-kit:  specify init --here --integration claude --script ps --force'
Info 'Project kickoff prompts live in .\prompts\'
