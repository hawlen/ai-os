# AI OS publish - ADMIN PC ONLY. Promote a reviewed version into canonical main
# and push it. Refuses to run unless ~/.ai-os-admin exists on this machine
# (create it by running install.ps1 -Admin on the admin PC).
# Usage: powershell -ExecutionPolicy Bypass -File publish.ps1 -Ref origin/machine/SOMEPC

param([string]$Ref = '')
$ErrorActionPreference = 'Continue'
$env:GIT_TERMINAL_PROMPT = '0'
$env:GCM_INTERACTIVE = 'never'

if (-not (Test-Path (Join-Path $env:USERPROFILE '.ai-os-admin'))) {
    Write-Host '[AI OS] This is not the admin PC (no ~/.ai-os-admin marker). Refusing to update main.'
    Write-Host '[AI OS] Use sync.ps1 to log versions on this machine branch instead.'
    exit 1
}

Set-Location $PSScriptRoot
git fetch origin --prune
$cur = (git rev-parse --abbrev-ref HEAD).Trim()
git checkout --quiet main
git pull origin main
if ($Ref) {
    git merge --no-ff $Ref -m "Publish: adopt $Ref into main"
    if ($LASTEXITCODE -ne 0) { Write-Host '[AI OS] Merge conflict - resolve manually, then push main'; exit 1 }
}
git push origin main
if ($LASTEXITCODE -eq 0) { Write-Host '[AI OS] main updated and pushed' } else { Write-Host '[AI OS] Push of main failed' }
if ($cur -ne 'main') { git checkout --quiet $cur }
