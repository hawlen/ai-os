#!/usr/bin/env pwsh
<#
  AI OS (machine layer) one-line bootstrap (Windows).

  On any Windows machine with git + Claude Code:
    irm https://raw.githubusercontent.com/hawlen/ai-os/main/bootstrap.ps1 | iex

  Clones (or updates) the hub, then runs the idempotent installer. Override the clone
  location with  $env:AI_OS_DIR  before running. (Repo was formerly named
  claude-tooling — existing ~/claude-tooling clones keep updating in place.)
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repo = 'https://github.com/hawlen/ai-os.git'
$legacy = Join-Path $env:USERPROFILE 'claude-tooling'
$dest = if ($env:AI_OS_DIR) { $env:AI_OS_DIR }
        elseif ($env:CLAUDE_TOOLING_DIR) { $env:CLAUDE_TOOLING_DIR }
        elseif (Test-Path (Join-Path $legacy '.git')) { $legacy }
        else { Join-Path $env:USERPROFILE 'ai-os' }

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw 'git is required. Install Git for Windows (winget install Git.Git) and re-run.'
}

if (Test-Path (Join-Path $dest '.git')) {
    Write-Host "[bootstrap] updating existing clone at $dest"
    git -C $dest pull --ff-only
} else {
    Write-Host "[bootstrap] cloning hub to $dest"
    git clone $repo $dest
}

Write-Host "[bootstrap] running installer..."
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $dest 'install.ps1')
Write-Host "[bootstrap] done. Hub at: $dest"
