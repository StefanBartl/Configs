# ==============================================================================
# PowerShell Profile Configuration
# ==============================================================================
# Paths:
#   C:\Users\StefanBartl\OneDrive - TRICENTIS\Dokumente\WindowsPowerShell\Microsoft.PowerShell_profile.ps1
#   $PROFILE
# ==============================================================================

# ------------------------------------------------------------------------------
# Internal helper: check whether an external command exists on PATH.
# Declared first so all subsequent guards can use it.
# ------------------------------------------------------------------------------
function Test-HasCommand {
    param([Parameter(Mandatory = $true)][string]$Name)
    try {
        $null -ne (Get-Command -Name $Name -ErrorAction Stop)
    } catch { $false }
}

# ------------------------------------------------------------------------------
# Starship prompt
#
# Problem: `starship init powershell` spawns a child process on every shell
# start (~800ms). The generated init script is stable between invocations, so
# it can safely be cached to disk and sourced directly.
#
# Cache invalidation: once per day (file mtime check). To force a refresh,
# delete the cache file manually:
#   Remove-Item "$env:TEMP\pwsh_starship_init.ps1"
# ------------------------------------------------------------------------------
if (Test-HasCommand 'starship') {
    try {
        $starshipCache = Join-Path $env:TEMP 'pwsh_starship_init.ps1'
        $needsRefresh = (-not (Test-Path $starshipCache)) -or
                        ((Get-Item $starshipCache).LastWriteTime -lt (Get-Date).AddDays(-1))

        if ($needsRefresh) {
            # Write with UTF-8 BOM so dot-sourcing works reliably on Windows
            (& starship init powershell) -join "`n" |
                Set-Content -Path $starshipCache -Encoding UTF8 -Force
        }

        . $starshipCache
    } catch {
        Write-Host "[warn] starship init failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "[info] starship not found. Install via: winget install Starship.Starship" -ForegroundColor DarkYellow
}

# ------------------------------------------------------------------------------
# zoxide directory jumper
#
# Same caching strategy as starship. The generated hook is stable.
# Force refresh: Remove-Item "$env:TEMP\pwsh_zoxide_init.ps1"
# ------------------------------------------------------------------------------
if (Test-HasCommand 'zoxide') {
    try {
        $zoxideCache = Join-Path $env:TEMP 'pwsh_zoxide_init.ps1'
        $needsRefresh = (-not (Test-Path $zoxideCache)) -or
                        ((Get-Item $zoxideCache).LastWriteTime -lt (Get-Date).AddDays(-1))

        if ($needsRefresh) {
            (& zoxide init powershell --hook prompt) -join "`n" |
                Set-Content -Path $zoxideCache -Encoding UTF8 -Force
        }

        . $zoxideCache
    } catch {
        Write-Host "[warn] zoxide init failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "[info] zoxide not found. Install via: winget install ajeetdsouza.zoxide" -ForegroundColor DarkYellow
}

# Enable colored output in less pager (used by git, delta, etc.)
$env:LESS = '-R'

# ------------------------------------------------------------------------------
# MyCliHelpers module
#
# Avoid Get-Module -ListAvailable: it scans all paths in $PSModulePath and can
# cost 1-2s on network-backed paths (OneDrive, UNC). Instead, attempt a direct
# import and suppress the error silently.
#
# -DisableNameChecking suppresses the "unapproved verb" warning that fires for
# convenience aliases like `ls`, `mkcd`, `gg`, etc. These helpers are
# intentionally named for muscle-memory, not for discoverability.
# ------------------------------------------------------------------------------
Import-Module MyCliHelpers -ErrorAction SilentlyContinue -DisableNameChecking
