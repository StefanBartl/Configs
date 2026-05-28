# ==============================================================================
# Microsoft.PowerShell_profile.ps1  –  CurrentUserCurrentHost
# ==============================================================================
# Managed via Symlink / Loader-Script aus:
#   $env:REPOS_DIR\Configs\Windows\DOTFILES\WindowsPowerShell\
#
# Einrichtung auf neuer Maschine:
#   $env:REPOS_DIR setzen, dann ausführen:
#   & "$env:REPOS_DIR\Configs\Windows\DOTFILES\install-DOTFILES.ps1"
#
# ==============================================================================

#region ── 0. Lokaler Modul-Pfad (Performance-kritisch) ──────────────────────
# Trägt einen lokalen Pfad (nie OneDrive) vorne in $PSModulePath ein.
# Dadurch findet Import-Module MyCliHelpers die Local-Junction statt des
# OneDrive-Pfads → kein Sync-Layer, kein Cloud-Overhead, kein AV-Delay.
# Die Junction wird von install-DOTFILES.ps1 erstellt.
$_localModules = Join-Path $env:LOCALAPPDATA 'PowerShell\Modules'
if ((Test-Path $_localModules) -and ($env:PSModulePath -notlike "*$_localModules*")) {
    $env:PSModulePath = "$_localModules$([IO.Path]::PathSeparator)$env:PSModulePath"
}
Remove-Variable -Name _localModules -ErrorAction SilentlyContinue
#endregion

#region ── 1. Test-HasCommand ──────────────────────────────────────────────────
# Session-Dictionary als Cache: jeder Tool-Name wird maximal einmal via
# Get-Command geprüft. Winget-Fallback läuft ebenfalls maximal einmal pro Name.
$script:_cmdCache = [System.Collections.Generic.Dictionary[string, bool]]::new(8)

function Test-HasCommand {
    [OutputType([bool])]
    param([Parameter(Mandatory)][string]$Name)

    [bool]$cached = $false
    if ($script:_cmdCache.TryGetValue($Name, [ref]$cached)) { return $cached }

    $found = [bool](Get-Command -Name $Name -ErrorAction SilentlyContinue)

    # Winget-Fallback: falls der Winget-Link-Pfad fehlt, einmalig reparieren
    if (-not $found) {
        $wingetPath = Join-Path $env:LOCALAPPDATA 'Microsoft\WinGet\Links'
        if ((Test-Path $wingetPath) -and ($env:PATH -notlike "*$wingetPath*")) {
            $env:PATH = "$env:PATH;$wingetPath"
            $found    = [bool](Get-Command -Name $Name -ErrorAction SilentlyContinue)
        }
    }

    $script:_cmdCache[$Name] = $found
    return $found
}
#endregion

#region ── 2. Init-Cache-Hilfsfunktion ────────────────────────────────────────
# Gemeinsame Logik für Starship und Zoxide:
# – Cache liegt in LocalAppData (lokal, persistent, nie OneDrive, nie TEMP)
# – TTL: 7 Tage – init-Skripte ändern sich selten; tägliche Neuausführung war
#   unnötige Startup-Last
# – Schreibt nur, wenn Init-Ausgabe nicht leer ist → altes Cache bleibt erhalten
#   wenn ein Tool vorübergehend kaputt ist
function Update-InitCache {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CachePath,
        [Parameter(Mandatory)][scriptblock]$InitBlock,
        [int]$MaxAgeDays = 7
    )
    $dir = Split-Path $CachePath
    if (-not (Test-Path $dir)) { $null = New-Item -ItemType Directory -Path $dir -Force }

    $isStale = (-not (Test-Path $CachePath)) -or
               ((Get-Item $CachePath -ErrorAction SilentlyContinue).LastWriteTime `
                -lt (Get-Date).AddDays(-$MaxAgeDays))

    if ($isStale) {
        $lines = & $InitBlock
        if ($lines -and -not [string]::IsNullOrWhiteSpace(($lines -join ''))) {
            # UTF-8 ohne BOM – wichtig für PS 5.1 Dot-Sourcing
            [System.IO.File]::WriteAllText(
                $CachePath,
                ($lines -join "`n"),
                [System.Text.UTF8Encoding]::new($false)
            )
        }
    }

    # Dot-Source: auch dann noch möglich wenn Update fehlschlug (alter Cache)
    if (Test-Path $CachePath) { . $CachePath }
}

$_cacheBase = Join-Path $env:LOCALAPPDATA 'pwsh\cache'
#endregion

#region ── 3. Starship Prompt ─────────────────────────────────────────────────
if (Test-HasCommand 'starship') {
    try {
        Update-InitCache `
            -CachePath (Join-Path $_cacheBase 'starship_init.ps1') `
            -InitBlock { & starship init powershell }
    } catch {
        Write-Host "[warn] starship init fehlgeschlagen: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host '[info] starship nicht gefunden – winget install Starship.Starship' -ForegroundColor DarkYellow
}
#endregion

#region ── 4. Zoxide ──────────────────────────────────────────────────────────
if (Test-HasCommand 'zoxide') {
    try {
        Update-InitCache `
            -CachePath (Join-Path $_cacheBase 'zoxide_init.ps1') `
            -InitBlock { & zoxide init powershell --hook prompt }
    } catch {
        Write-Host "[warn] zoxide init fehlgeschlagen: $($_.Exception.Message)" -ForegroundColor Yellow
    }
} else {
    Write-Host '[info] zoxide nicht gefunden – winget install ajeetdsouza.zoxide' -ForegroundColor DarkYellow
}

Remove-Variable -Name _cacheBase -ErrorAction SilentlyContinue
#endregion

#region ── 5. PSReadLine ──────────────────────────────────────────────────────
# In PS 7 ist PSReadLine bereits geladen – kein ListAvailable-Scan nötig.
# Einmalig in Variable cachen statt zweimal Get-Module aufzurufen.
$_psrl = Get-Module PSReadLine -ErrorAction SilentlyContinue
if ($_psrl) {
    $psrlVer = $_psrl.Version

    # Prediction-Source: HistoryAndPlugin erst ab 2.2 verfügbar
    if ($psrlVer -ge [version]'2.2') {
        Set-PSReadLineOption -PredictionSource HistoryAndPlugin
        Set-PSReadLineOption -PredictionViewStyle ListView   # F2 wechselt Ansicht
    } elseif ($psrlVer -ge [version]'2.1') {
        Set-PSReadLineOption -PredictionSource History
    }

    Set-PSReadLineKeyHandler -Key Tab        -Function MenuComplete
    Set-PSReadLineKeyHandler -Key Shift+Tab  -Function TabCompletePrevious
    Set-PSReadLineKeyHandler -Key UpArrow    -Function HistorySearchBackward
    Set-PSReadLineKeyHandler -Key DownArrow  -Function HistorySearchForward
}
Remove-Variable -Name _psrl -ErrorAction SilentlyContinue
#endregion

#region ── 6. Umgebungsvariablen ──────────────────────────────────────────────
# Farbige Pager-Ausgabe für git, delta, man, etc.
$env:LESS = '-R'
#endregion

#region ── 7. MyCliHelpers-Modul ──────────────────────────────────────────────
# Wird aus dem lokalen Pfad (Abschnitt 0) geladen – kein OneDrive-Zugriff.
# -DisableNameChecking unterdrückt "unapproved verb"-Warnung für Kurzaliase
# wie ls, mkcd, gg etc., die absichtlich Unix-vertraut benannt sind.
Import-Module MyCliHelpers -ErrorAction SilentlyContinue -DisableNameChecking
#endregion

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
  Import-Module "$ChocolateyProfile"
}
