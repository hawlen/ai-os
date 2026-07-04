# AI OS sync - commit local changes to this machine's branch with an explanation
# and push it to GitHub as a logged version. Never touches main.
# Usage: powershell -ExecutionPolicy Bypass -File sync.ps1 -Message "what changed and why"

param([Parameter(Mandatory=$true)][string]$Message)
$ErrorActionPreference = 'Continue'
$root = $PSScriptRoot
$machine = $env:COMPUTERNAME
$branch = "machine/$machine"
Set-Location $root

$cur = (git rev-parse --abbrev-ref HEAD).Trim()
if ($cur -ne $branch) {
    $exists = git branch --list $branch
    if ($exists) { git checkout --quiet $branch } else { git checkout --quiet -b $branch }
    if ($LASTEXITCODE -ne 0) { Write-Host "[AI OS] Could not switch to $branch - resolve manually"; exit 1 }
}

# Append to this machine's changelog so every version carries its explanation.
$logDir = Join-Path $root (Join-Path 'machines' $machine)
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$stamp = (Get-Date).ToString('yyyy-MM-dd HH:mm')
Add-Content -Path (Join-Path $logDir 'log.md') -Value "- **$stamp**: $Message" -Encoding UTF8

git add -A
git commit -m "[$machine] $Message" | Out-Null
if ($LASTEXITCODE -ne 0) { Write-Host '[AI OS] Nothing new to commit'; exit 0 }
Write-Host "[AI OS] Version committed on ${branch}: $Message"

git push -u origin $branch
if ($LASTEXITCODE -eq 0) {
    Write-Host "[AI OS] Pushed $branch to GitHub"
} else {
    Write-Host '[AI OS] Push failed (auth/network?) - the version is committed locally and will be pushed on the next successful sync'
}
