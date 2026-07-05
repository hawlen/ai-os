$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$repo = Split-Path -Parent $here
. "$repo\lib\Dashboard.ps1"

Describe 'Resolve-DashboardDir' {
    It 'returns the AI_OS_DASHBOARD_DIR override when set' {
        Resolve-DashboardDir -EnvOverride 'D:\custom\dash' -UserProfile 'C:\Users\bob' | Should Be 'D:\custom\dash'
    }
    It 'falls back to <UserProfile>\ai-os-dashboard when no override' {
        Resolve-DashboardDir -EnvOverride '' -UserProfile 'C:\Users\bob' | Should Be 'C:\Users\bob\ai-os-dashboard'
    }
    It 'treats a null override as unset' {
        Resolve-DashboardDir -EnvOverride $null -UserProfile 'C:\Users\bob' | Should Be 'C:\Users\bob\ai-os-dashboard'
    }
}
