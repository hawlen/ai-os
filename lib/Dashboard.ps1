# Pure helpers for the AI OS Dashboard install step (section 7 of install.ps1).
# Kept in a dot-sourceable file so the logic is unit-testable without running the
# whole installer. PowerShell 5.1.

function Resolve-DashboardDir {
    # Where the per-machine dashboard clone lives: the AI_OS_DASHBOARD_DIR override
    # if set, otherwise <user profile>\ai-os-dashboard. Both inputs are parameters
    # (not read from $env directly) so tests can drive them.
    param(
        [string]$EnvOverride,
        [string]$UserProfile
    )
    if ($EnvOverride) { return $EnvOverride }
    return (Join-Path $UserProfile 'ai-os-dashboard')
}
