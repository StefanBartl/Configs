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
# Verbesserter Helfer: Prüft PATH und fügt bei Bedarf den Winget-Pfad live hinzu
# ------------------------------------------------------------------------------
function Test-HasCommand {
    param([Parameter(Mandatory = $true)][string]$Name)

    # 1. Standard-Prüfung über die Umgebungsvariablen
    if (Get-Command -Name $Name -ErrorAction SilentlyContinue) {
        return $true
    }

    # 2. Fallback: Falls Windows den Winget-Pfad verschluckt hat, fügen wir ihn live hinzu
    $wingetPath = Join-Path $env:LOCALAPPDATA "Microsoft\WinGet\Links"
    if (Test-Path $wingetPath) {
        # Falls der Pfad noch nicht im aktuellen Umgebungspfad ist, temporär in dieser Session anhängen
        if ($env:PATH -notlike "*$wingetPath*") {
            $env:PATH = "$env:PATH;$wingetPath"
        }
        # Erneuter Versuch nach dem Fix
        if (Get-Command -Name $Name -ErrorAction SilentlyContinue) {
            return $true
        }
    }

    return $false
}

# ------------------------------------------------------------------------------
# Starship prompt  –  BOM-freier Cache für PS 5.1
# ------------------------------------------------------------------------------
if (Test-HasCommand 'starship') {
    try {
        $starshipCache = Join-Path $env:TEMP 'pwsh_starship_init.ps1'
        $needsRefresh  = (-not (Test-Path $starshipCache)) -or
                         ((Get-Item $starshipCache).LastWriteTime -lt (Get-Date).AddDays(-1))

        if ($needsRefresh) {
            $initScript = (& starship init powershell) -join "`n"
            if ([string]::IsNullOrWhiteSpace($initScript)) {
                throw "starship init returned empty output"
            }
            # UTF-8 OHNE BOM – wichtig für PS 5.1, sonst schlägt dot-sourcing silent fehl
            [System.IO.File]::WriteAllText(
                $starshipCache,
                $initScript,
                [System.Text.UTF8Encoding]::new($false)   # $false = kein BOM
            )
        }

        . $starshipCache
    } catch {
        Write-Host "[warn] starship init failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "[info] starship not found. Install via: winget install Starship.Starship" -ForegroundColor DarkYellow
}

# ------------------------------------------------------------------------------
# zoxide  –  BOM-freier Cache + danach PSReadLine-Suggestions konfigurieren
# ------------------------------------------------------------------------------
if (Test-HasCommand 'zoxide') {
    try {
        $zoxideCache  = Join-Path $env:TEMP 'pwsh_zoxide_init.ps1'
        $needsRefresh = (-not (Test-Path $zoxideCache)) -or
                        ((Get-Item $zoxideCache).LastWriteTime -lt (Get-Date).AddDays(-1))

        if ($needsRefresh) {
            $initScript = (& zoxide init powershell --hook prompt) -join "`n"
            if ([string]::IsNullOrWhiteSpace($initScript)) {
                throw "zoxide init returned empty output"
            }
            [System.IO.File]::WriteAllText(
                $zoxideCache,
                $initScript,
                [System.Text.UTF8Encoding]::new($false)
            )
        }

        . $zoxideCache
    } catch {
        Write-Host "[warn] zoxide init failed: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host "[info] zoxide not found. Install via: winget install ajeetdsouza.zoxide" -ForegroundColor DarkYellow
}

# ------------------------------------------------------------------------------
# PSReadLine  –  Inline-Suggestions + komfortables Tab-Verhalten
#
# Voraussetzung: PSReadLine >= 2.1
#   Install-Module PSReadLine -Scope CurrentUser -Force   (einmalig, als Admin)
# ------------------------------------------------------------------------------
if (Get-Module -Name PSReadLine -ErrorAction SilentlyContinue) {
    $psrlVersion = (Get-Module PSReadLine).Version

    # Inline-Suggestion aus der History (grauer Geistertext) – ab PSReadLine 2.1
    if ($psrlVersion -ge [version]'2.1') {
        Set-PSReadLineOption -PredictionSource History
    }

    # Dropdown-Liste statt einzelner Inline-Suggestion – ab PSReadLine 2.2
    if ($psrlVersion -ge [version]'2.2') {
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin
        Set-PSReadLineOption -PredictionViewStyle ListView   # F2 schaltet zwischen beiden um
    }

    # Tab öffnet ein auswählbares Menü aller Matches (statt blindem erstem Treffer)
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

    # Shift+Tab rückwärts durch die Completion-Liste
    Set-PSReadLineKeyHandler -Key Shift+Tab -Function TabCompletePrevious

    # Pfeiltasten filtern die History auf den bereits getippten Prefix
    Set-PSReadLineKeyHandler -Key UpArrow   -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward
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
