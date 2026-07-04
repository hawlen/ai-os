# AI OS installer — deploys universal principles into ~/.claude/CLAUDE.md and
# registers session-logging hooks in ~/.claude/settings.json.
# Idempotent: safe to re-run after every git pull. PowerShell 5.1 compatible.
#
# Usage:  powershell -ExecutionPolicy Bypass -File install.ps1 [-SkipHooks]

param([switch]$SkipHooks, [switch]$Admin)
$ErrorActionPreference = 'Stop'

$root = $PSScriptRoot
$claudeDir = Join-Path $env:USERPROFILE '.claude'
if (-not (Test-Path $claudeDir)) { New-Item -ItemType Directory -Path $claudeDir -Force | Out-Null }
$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# ---------------------------------------------------------------------------
# 1. Deploy principles/ into ~/.claude/CLAUDE.md between AI-OS markers.
#    Content outside the markers is never touched.
# ---------------------------------------------------------------------------
$begin = '<!-- AI-OS:BEGIN -->'
$end   = '<!-- AI-OS:END -->'

$files = Get-ChildItem (Join-Path $root 'principles') -Filter '*.md' | Sort-Object Name
if (-not $files) { throw "No principle files found in $root\principles" }
$body = ($files | ForEach-Object { (Get-Content $_.FullName -Raw -Encoding UTF8).TrimEnd() }) -join "`r`n`r`n---`r`n`r`n"
$block = "$begin`r`n<!-- Managed by AI OS ($root). Edit principles\*.md and re-run install.ps1; do not edit inside this block. -->`r`n`r`n$body`r`n$end"

$claudeMd = Join-Path $claudeDir 'CLAUDE.md'
if (Test-Path $claudeMd) {
    $existing = Get-Content $claudeMd -Raw
    $i = $existing.IndexOf($begin)
    $j = $existing.IndexOf($end)
    if ($i -ge 0 -and $j -gt $i) {
        $updated = $existing.Substring(0, $i) + $block + $existing.Substring($j + $end.Length)
    } else {
        $updated = $existing.TrimEnd() + "`r`n`r`n" + $block + "`r`n"
    }
} else {
    $updated = $block + "`r`n"
}
[System.IO.File]::WriteAllText($claudeMd, $updated, $utf8NoBom)
Write-Host "[AI OS] Principles deployed to $claudeMd ($($files.Count) file(s))"

# ---------------------------------------------------------------------------
# 2. Versioning guard: only the admin PC (marker file) may push main.
# ---------------------------------------------------------------------------
if ($Admin) {
    New-Item -ItemType File -Path (Join-Path $env:USERPROFILE '.ai-os-admin') -Force | Out-Null
    Write-Host '[AI OS] Admin marker created - this PC may publish main'
}
if (Test-Path (Join-Path $root '.git')) {
    $hookDir = Join-Path $root '.git\hooks'
    if (-not (Test-Path $hookDir)) { New-Item -ItemType Directory -Path $hookDir -Force | Out-Null }
    $guard = @(
        '#!/bin/sh',
        '# AI OS guard: only the admin PC may push main.',
        'if [ -f "$HOME/.ai-os-admin" ] || [ -f "$HOME/.ai-os-bootstrap" ]; then exit 0; fi',
        'while read local_ref local_sha remote_ref remote_sha; do',
        '  if [ "$remote_ref" = "refs/heads/main" ]; then',
        '    echo "AI OS guard: this PC is not the admin PC; pushing main is blocked." >&2',
        '    echo "Use sync.ps1 (machine branch) instead. If this IS the admin PC, run install.ps1 -Admin." >&2',
        '    exit 1',
        '  fi',
        'done',
        'exit 0'
    )
    [System.IO.File]::WriteAllText((Join-Path $hookDir 'pre-push'), (($guard -join "`n") + "`n"))
    Write-Host '[AI OS] Git pre-push guard installed (main is admin-only)'
}

# ---------------------------------------------------------------------------
# 3. Register SessionStart/SessionEnd logging hooks in ~/.claude/settings.json.
#    Merges with existing settings; skips events that already have the hook.
# ---------------------------------------------------------------------------
if ($SkipHooks) { Write-Host '[AI OS] Hooks skipped (-SkipHooks)'; exit 0 }

$settingsPath = Join-Path $claudeDir 'settings.json'
if (Test-Path $settingsPath) {
    $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json
} else {
    $settings = New-Object PSObject
}

$hookScript = Join-Path $root 'hooks\log-session.ps1'
if (-not (Test-Path $hookScript)) { throw "Hook script not found: $hookScript" }

function New-AiOsHookEntry {
    param([string]$ScriptPath)
    # Exec form (command + args): spawned directly, no shell - spaces in the
    # repo path never hit a shell parser.
    [pscustomobject]@{
        hooks = @([pscustomobject]@{
            type    = 'command'
            command = 'powershell.exe'
            args    = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $ScriptPath)
            timeout = 10
            async   = $true
        })
    }
}

if (-not ($settings.PSObject.Properties.Name -contains 'hooks')) {
    $settings | Add-Member -NotePropertyName 'hooks' -NotePropertyValue (New-Object PSObject)
}

foreach ($eventName in @('SessionStart', 'SessionEnd')) {
    $alreadyThere = $false
    if ($settings.hooks.PSObject.Properties.Name -contains $eventName) {
        foreach ($entry in @($settings.hooks.$eventName)) {
            foreach ($h in @($entry.hooks)) {
                if ($null -ne $h) {
                    $joined = "$($h.command) $((@($h.args) -join ' '))"
                    if ($joined -like '*log-session.ps1*') {
                        $alreadyThere = $true
                        # Checkout moved: repoint the hook at this copy.
                        if (-not (@($h.args) -contains $hookScript)) {
                            $h.args = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', $hookScript)
                            Write-Host "[AI OS] $eventName hook repointed to $hookScript"
                        }
                    }
                }
            }
        }
    }
    if ($alreadyThere) {
        Write-Host "[AI OS] $eventName hook already registered"
        continue
    }
    $newEntry = New-AiOsHookEntry -ScriptPath $hookScript
    if ($settings.hooks.PSObject.Properties.Name -contains $eventName) {
        $settings.hooks.$eventName = @($settings.hooks.$eventName) + @($newEntry)
    } else {
        $settings.hooks | Add-Member -NotePropertyName $eventName -NotePropertyValue @($newEntry)
    }
    Write-Host "[AI OS] $eventName hook registered"
}

$json = $settings | ConvertTo-Json -Depth 12
# Round-trip check: never write settings.json we cannot parse back.
$null = $json | ConvertFrom-Json
[System.IO.File]::WriteAllText($settingsPath, $json, $utf8NoBom)
Write-Host "[AI OS] Settings written to $settingsPath"
Write-Host '[AI OS] Done. Hooks take effect in new Claude Code sessions.'
