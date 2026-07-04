# AI OS - one-time GitHub connection for this PC.
# Run in a normal PowerShell window whenever you're ready:
#   powershell -ExecutionPolicy Bypass -File "C:\AI OS\connect-github.ps1"
# Requests a GitHub device code (copied to your clipboard), opens the approval
# page in your browser, waits for approval, then stores a permanent repo-local
# credential and pushes this PC's branches. Run again any time if it times out.

$ErrorActionPreference = 'Continue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$repo = $PSScriptRoot

$ids = @('0120e057bd645470c1ed', '178c6fc778ccc68e1d6a')
$resp = $null
$clientId = $null
foreach ($cid in $ids) {
    try {
        $r = Invoke-RestMethod -Method Post -Uri 'https://github.com/login/device/code' `
            -Headers @{ Accept = 'application/json' } `
            -Body @{ client_id = $cid; scope = 'repo' } -TimeoutSec 20
        if ($r.user_code) { $resp = $r; $clientId = $cid; break }
    } catch {}
}
if (-not $resp) { Write-Host 'Could not reach GitHub - check your network and run again.'; exit 1 }

try { Set-Clipboard -Value $resp.user_code } catch {}
Write-Host ''
Write-Host '===================================================='
Write-Host '  Enter this code on the GitHub page that opens:'
Write-Host ''
Write-Host "      $($resp.user_code)      (already in your clipboard)"
Write-Host '===================================================='
Write-Host ''
Start-Process $resp.verification_uri

$interval = [Math]::Max([int]$resp.interval, 5)
$deadline = (Get-Date).AddSeconds([int]$resp.expires_in)
$token = $null
Write-Host 'Waiting for your approval in the browser...'
while ((Get-Date) -lt $deadline) {
    Start-Sleep -Seconds $interval
    try {
        $p = Invoke-RestMethod -Method Post -Uri 'https://github.com/login/oauth/access_token' `
            -Headers @{ Accept = 'application/json' } `
            -Body @{ client_id = $clientId; device_code = $resp.device_code; grant_type = 'urn:ietf:params:oauth:grant-type:device_code' }
    } catch { continue }
    if ($p.access_token) { $token = $p.access_token; break }
    if ($p.error -eq 'authorization_pending') { continue }
    if ($p.error -eq 'slow_down') { Start-Sleep -Seconds 5; continue }
    Write-Host "GitHub returned an error: $($p.error)"; exit 1
}
if (-not $token) { Write-Host 'Timed out. Just run this script again.'; exit 1 }
Write-Host 'Approved!'

# Permanent headless credential, scoped to this repo (git file store, no GCM).
$credFile = Join-Path $env:USERPROFILE '.ai-os-git-credentials'
Set-Content -Path $credFile -Value "https://oauth:$token@github.com" -Encoding ASCII
Set-Location $repo
git config --local --unset-all credential.helper 2>$null
git --% config --local --add credential.helper ""
git config --local --add credential.helper "store --file=$(($env:USERPROFILE -replace '\\','/') + '/.ai-os-git-credentials')"
Write-Host 'Permanent credential stored for this repo.'

git fetch origin
$machineBranch = "machine/$env:COMPUTERNAME"
$remoteMain = git ls-remote --heads origin main
if ($remoteMain) {
    $remoteCommits = (git rev-list --count origin/main).Trim()
    if ([int]$remoteCommits -le 1) {
        git push --force-with-lease origin main
        Write-Host 'main pushed (replaced the auto-generated initial commit).'
    } else {
        Write-Host 'Remote main already has real history - leaving it untouched.'
    }
} else {
    git push -u origin main
    Write-Host 'main pushed.'
}
if (git branch --list $machineBranch) {
    git push -u origin $machineBranch
    Write-Host "$machineBranch pushed."
}
Write-Host ''
Write-Host 'AI OS is connected to GitHub. All future syncs are automatic.'
