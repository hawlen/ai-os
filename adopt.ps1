# AI OS adopt - take the content of any logged version (branch, tag, or commit)
# into THIS machine's branch, re-install, and log the adoption.
# This is also the rollback mechanism: adopt an older commit hash.
# Usage: powershell -ExecutionPolicy Bypass -File adopt.ps1 -Ref origin/main
#        powershell -ExecutionPolicy Bypass -File adopt.ps1 -Ref origin/machine/OTHERPC
#        powershell -ExecutionPolicy Bypass -File adopt.ps1 -Ref abc1234

param([Parameter(Mandatory=$true)][string]$Ref)
$ErrorActionPreference = 'Continue'
$env:GIT_TERMINAL_PROMPT = '0'
$env:GCM_INTERACTIVE = 'never'
Set-Location $PSScriptRoot

git fetch origin --prune
git rev-parse --verify --quiet ($Ref + '^{commit}') | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host "[AI OS] Unknown ref: $Ref"; exit 1 }

# Overlay that version's tracked files onto the working tree.
git checkout $Ref -- .
if ($LASTEXITCODE -ne 0) { Write-Host "[AI OS] Failed to apply $Ref"; exit 1 }
Write-Host "[AI OS] Applied content of $Ref"

# Re-deploy principles and hooks from the adopted version.
& (Join-Path $PSScriptRoot 'install.ps1')

# Record the adoption as a new logged version on this machine's branch.
& (Join-Path $PSScriptRoot 'sync.ps1') -Message "Adopted version $Ref"
