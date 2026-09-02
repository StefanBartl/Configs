# ==============================================================================
# Microsoft.PowerShell_profile.ps1  –  CurrentUserCurrentHost
# ==============================================================================
# Managed via Symlink / Junction aus:
#   $env:REPOS_DIR\Configs\shells\pwsh\
#
# Einrichtung auf neuer Maschine:
#   $env:REPOS_DIR setzen, dann ausführen:
#   & "$env:REPOS_DIR\Configs\install\install.ps1" -Only pwsh
#
# ==============================================================================

#region ── -1. Fehlerverhalten während des Profil-Laufs ───────────────────────
# Ein einzelner Fehler in einer Initialisierung (starship weg, zoxide kaputt,
# Chocolatey-Profil defekt) darf den Rest des Profils nicht abbrechen. Der
# aufrufende Wert wird gesichert und am Ende wiederhergestellt, damit die
# interaktive Session nicht mit einem vom Profil gesetzten Wert weiterläuft.
$_eapSaved = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
#endregion

Remove-PSReadLineKeyHandler -Chord 'Ctrl+s' -ErrorAction SilentlyContinue

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
            $found = [bool](Get-Command -Name $Name -ErrorAction SilentlyContinue)
        }
    }

    $script:_cmdCache[$Name] = $found
    return $found
}
#endregion

#region ── 2. Init-Cache-Hilfsfunktion ────────────────────────────────────────
# Gemeinsame Logik für Starship und Zoxide:
# – Cache liegt in LocalAppData (lokal, persistent, nie OneDrive, nie TEMP)
# – Primärer Invalidierungsgrund ist die Tool-VERSION, nicht das Alter: ein
#   Update von starship/zoxide muss sofort greifen, und solange sich nichts
#   ändert, ist ein 3 Monate alter Cache genauso korrekt wie ein frischer.
#   Die Version steht in einer Sidecar-Datei <cache>.ver neben dem Cache.
# – Die TTL bleibt als Rückfallebene für alles, was die Version nicht abdeckt
#   (geänderte Konfiguration, kaputt geschriebener Cache).
# – Schreibt nur, wenn Init-Ausgabe nicht leer ist → altes Cache bleibt erhalten
#   wenn ein Tool vorübergehend kaputt ist
function Update-InitCache {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$CachePath,
        [Parameter(Mandatory)][scriptblock]$InitBlock,
        [scriptblock]$VersionBlock,
        [int]$MaxAgeDays = 90
    )
    $dir = Split-Path $CachePath
    if (-not (Test-Path $dir)) { $null = New-Item -ItemType Directory -Path $dir -Force }

    $verPath = "$CachePath.ver"
    $version = $null
    if ($VersionBlock) {
        # Schlägt der Versionsaufruf fehl, bleibt $version leer und die TTL
        # entscheidet allein — kein Grund, deswegen den Cache wegzuwerfen.
        try { $version = (& $VersionBlock | Out-String).Trim() } catch { $version = $null }
    }

    $isStale = -not (Test-Path $CachePath)

    if (-not $isStale -and $version) {
        $cachedVersion = if (Test-Path $verPath) { (Get-Content $verPath -Raw -ErrorAction SilentlyContinue).Trim() } else { $null }
        if ($cachedVersion -ne $version) { $isStale = $true }
    }

    if (-not $isStale) {
        $written = (Get-Item $CachePath -ErrorAction SilentlyContinue).LastWriteTime
        if ($written -lt (Get-Date).AddDays(-$MaxAgeDays)) { $isStale = $true }
    }

    if ($isStale) {
        $lines = & $InitBlock
        if ($lines -and -not [string]::IsNullOrWhiteSpace(($lines -join ''))) {
            # UTF-8 ohne BOM – wichtig für PS 5.1 Dot-Sourcing
            [System.IO.File]::WriteAllText(
                $CachePath,
                ($lines -join "`n"),
                [System.Text.UTF8Encoding]::new($false)
            )
            # Version erst NACH dem Cache schreiben: bricht der Schreibvorgang
            # ab, gilt der Cache beim nächsten Start weiterhin als veraltet.
            if ($version) {
                [System.IO.File]::WriteAllText($verPath, $version, [System.Text.UTF8Encoding]::new($false))
            }
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
            -InitBlock { & starship init powershell } `
            -VersionBlock { & starship --version }
    }
    catch {
        Write-Host "[warn] starship init fehlgeschlagen: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}
else {
    Write-Host '[info] starship nicht gefunden – winget install Starship.Starship' -ForegroundColor DarkYellow
}
#endregion

#region ── 4. Zoxide ──────────────────────────────────────────────────────────
if (Test-HasCommand 'zoxide') {
    try {
        Update-InitCache `
            -CachePath (Join-Path $_cacheBase 'zoxide_init.ps1') `
            -InitBlock { & zoxide init powershell --hook prompt } `
            -VersionBlock { & zoxide --version }
    }
    catch {
        Write-Host "[warn] zoxide init fehlgeschlagen: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}
else {
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

    # Prediction-Source: HistoryAndPlugin erfordert PSReadLine >= 2.2 UND PowerShell >= 7.2
    #
    # try/catch, weil Set-PSReadLineOption -PredictionSource wirft, sobald die
    # Konsolenausgabe umgeleitet ist oder kein Virtual-Terminal unterstuetzt
    # (pwsh -Command aus einem Skript, VS-Code-Tasks, CI). Ohne den Guard
    # entstehen dort bei jedem Start zwei rote Fehlerbloecke, obwohl
    # Prediction in so einer Session ohnehin sinnlos ist.
    try {
        if ($psrlVer -ge [version]'2.2' -and $PSVersionTable.PSVersion -ge [version]'7.2') {
            Set-PSReadLineOption -PredictionSource HistoryAndPlugin -ErrorAction Stop
            Set-PSReadLineOption -PredictionViewStyle ListView -ErrorAction Stop  # F2 wechselt Ansicht
        }
        elseif ($psrlVer -ge [version]'2.1' -and $PSVersionTable.PSVersion -ge [version]'7.0') {
            Set-PSReadLineOption -PredictionSource History -ErrorAction Stop
        }
    } catch {
        # Kein Terminal, das Prediction darstellen kann — still weitermachen.
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
#
# try/catch statt nur -ErrorAction: zeigt eine Junction im Modulpfad ins Leere
# (z. B. nach einem Repo-Umbau), meldet Import-Module einen Pfadfehler, den
# -ErrorAction SilentlyContinue nicht schluckt. Statt eines roten Blocks bei
# jedem Start gibt es dann einen Satz, der sagt, was zu tun ist.
try {
    Import-Module MyCliHelpers -ErrorAction Stop -DisableNameChecking
} catch {
    Write-Host '[warn] MyCliHelpers konnte nicht geladen werden.' -ForegroundColor Yellow
    Write-Host "        $($_.Exception.Message)" -ForegroundColor DarkYellow
    Write-Host '        Reparatur:  & "$env:REPOS_DIR\Configs\install\install.ps1" -Only pwsh -Force' -ForegroundColor DarkYellow
}
#endregion

#region ── 8. Update-WindowsApps-Modul ────────────────────────────────────────
# Robuste Pfadermittlung für den Ordner, in dem diese Profildatei liegt:
$_profileDir = if ($PSScriptRoot) { 
    $PSScriptRoot 
} elseif ($PSCommandPath) { 
    Split-Path -Parent $PSCommandPath 
} else { 
    Split-Path -Parent $PROFILE 
}

$UpdateWindowsAppsModule = Join-Path $_profileDir 'Modules\Update-WindowsApps.psm1'

if (Test-Path $UpdateWindowsAppsModule) {
    Import-Module $UpdateWindowsAppsModule -ErrorAction SilentlyContinue
}
else {
    # Debug-Hinweis: Zeigt dir exakt, wo PowerShell nach der Datei sucht
    Write-Host "[info] Update-WindowsApps.psm1 nicht gefunden unter: '$UpdateWindowsAppsModule'" -ForegroundColor DarkYellow
}

Remove-Variable -Name _profileDir, UpdateWindowsAppsModule -ErrorAction SilentlyContinue
#endregion

#region ── 9. casedesk: Case-Session-Kurzform ────────────────────────────────
# `case 1007631` springt direkt in die gespeicherte Session dieses Cases.
# Ohne Nummer: normales `nvim` (autoload = true in sessions.nvim lädt dann
# ohnehin die zuletzt geladene Session). Siehe
# docs/ROADMAP/casedesk/SESSIONS.md §4.2 im nvim-Config-Repo.
function case {
    param([string]$CaseNr)
    if ($CaseNr) { nvim -c "Session load $CaseNr" } else { nvim }
}
#endregion

#region ── 10. Repo-Sprung ───────────────────────────────────────────────────
# `spotlight` → cd $env:REPOS_DIR\spotlight.nvim, ohne dass irgendwo Namen
# gepflegt werden. Auflösung in MyCliHelpers (Resolve-Repo, repo),
# Konzept: docs/KONZEPT-REPO-SPRUNG.md
#
# Der Hook steht hier und nicht im Modul, weil er Session-State verändert.
# Er greift nur, wenn PowerShell das Wort nicht als Kommando auflösen konnte —
# also nur dort, wo ohnehin ein Fehler fällig wäre. Damit kann er nie ein
# echtes Kommando verdecken (`diff` bleibt der delta-Wrapper; das Repo
# diff.nvim ist über `diff-nvim` und `repo diff` erreichbar).
#
# -Strict lässt Substring-Treffer weg: ein Tippfehler soll ein Fehler bleiben
# und nicht in einem überraschenden Verzeichniswechsel enden.
try {
    if (Get-Command Resolve-Repo -ErrorAction SilentlyContinue) {

        # Einen bereits gesetzten Handler sichern statt ersetzen, damit ein
        # anderes Modul nicht stillschweigend entwertet wird.
        $_cnfPrev = $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction

        $ExecutionContext.SessionState.InvokeCommand.CommandNotFoundAction = {
            param($CommandName, $EventArgs)

            # Alles mit Pfadtrenner war nie als Repo-Name gemeint.
            if ($CommandName -notmatch '[\\/:]') {
                $hits = @(Resolve-Repo -Query $CommandName -Strict)
                if ($hits.Count -eq 1) {
                    $target = $hits[0]
                    $EventArgs.CommandScriptBlock = { Set-RepoLocation $target }.GetNewClosure()
                    $EventArgs.StopSearch = $true
                    return
                }
            }

            if ($_cnfPrev) { & $_cnfPrev $CommandName $EventArgs }
        }.GetNewClosure()

        # zoxide-Seeding: läuft nur, wenn sich der Inhalt von $env:REPOS_DIR seit
        # dem letzten Mal geändert hat. Im Normalfall kein Subprozess.
        Update-RepoSeed
    }
}
catch {
    Write-Host "[warn] Repo-Sprung nicht eingerichtet: $($_.Exception.Message)" -ForegroundColor Yellow
    Write-Host '        Reparatur:  & "$env:REPOS_DIR\Configs\install\install.ps1" -Only pwsh -Force' -ForegroundColor DarkYellow
}
#endregion

# Import the Chocolatey Profile that contains the necessary code to enable
# tab-completions to function for `choco`.
# Be aware that if you are missing these lines from your profile, tab completion
# for `choco` will not function.
# See https://ch0.co/tab-completion for details.
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path($ChocolateyProfile)) {
    Import-Module "$ChocolateyProfile" -ErrorAction SilentlyContinue
}
Remove-Variable -Name ChocolateyProfile -ErrorAction SilentlyContinue

#region ── 99. Fehlerverhalten wiederherstellen ───────────────────────────────
# Gegenstueck zu Abschnitt -1. Ab hier gilt wieder, was die Session vorgibt.
$ErrorActionPreference = $_eapSaved
Remove-Variable -Name _eapSaved -ErrorAction SilentlyContinue
#endregion
