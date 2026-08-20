<#
.SYNOPSIS
    Configs — Installer fuer Windows.

.DESCRIPTION
    Legt Verknuepfungen gemaess install/links.conf an. Gegenstueck:
    install/install.sh fuer Linux/macOS/WSL, das dieselbe Manifestdatei liest.

    Ohne Parameter werden die Komponenten interaktiv ausgewaehlt.
    Configs verlinkt Konfiguration — es installiert keine Programme.

    Verknuepfungsstrategie (ohne Admin-Rechte lauffaehig):
      Verzeichnis : Junction (braucht nie Admin)
      Datei       : Symlink -> faellt auf Hardlink zurueck (gleiches Laufwerk,
                    kein Admin/Entwicklermodus noetig) -> zuletzt Kopie mit Warnung

.PARAMETER List
    Zeigt die verfuegbaren Komponenten an und beendet sich.

.PARAMETER All
    Waehlt alle Komponenten ohne Rueckfrage.

.PARAMETER Only
    Nur diese Komponenten installieren (Namen oder Nummern aus -List).

.PARAMETER Skip
    Diese Komponenten von der Auswahl ausnehmen.

.PARAMETER DryRun
    Zeigt nur an, was passieren wuerde; aendert nichts.

.PARAMETER Force
    Ersetzt auch vorhandene echte Dateien/Ordner am Ziel. Der bisherige Inhalt
    wird vorher nach <ziel>.bak-<zeitstempel> verschoben.

.EXAMPLE
    .\install\install.ps1 -List
.EXAMPLE
    .\install\install.ps1 -Only wezterm,pwsh -DryRun
.EXAMPLE
    .\install\install.ps1 -All -Skip glow -Force
#>
[CmdletBinding()]
param(
    [switch]$List,
    [switch]$All,
    [string[]]$Only,
    [string[]]$Skip,
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# --- Pfade ----------------------------------------------------------------

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot  = Split-Path -Parent $scriptDir
$manifest  = Join-Path $scriptDir 'links.conf'
$platform  = 'windows'

if (-not (Test-Path -LiteralPath $manifest)) {
    Write-Error "Manifest nicht gefunden: $manifest"
    return
}

$docsDir = [Environment]::GetFolderPath('MyDocuments')
$tokens  = @{
    '$PS5'     = Join-Path $docsDir 'WindowsPowerShell'
    '$PS7'     = Join-Path $docsDir 'PowerShell'
    '$APPDATA' = $env:APPDATA
    '$HOME'    = $env:USERPROFILE
}

$stats = @{ Linked = 0; Skipped = 0; Failed = 0 }

function Write-Info { param([string]$Message) Write-Host "[info] $Message" -ForegroundColor DarkGray }
function Write-Ok   { param([string]$Message) Write-Host "[ ok ] $Message" -ForegroundColor Green }
function Write-Warn { param([string]$Message) Write-Host "[warn] $Message" -ForegroundColor Yellow }
function Write-Fail { param([string]$Message) Write-Host "[fail] $Message" -ForegroundColor Red }

# --- Manifest einlesen ----------------------------------------------------

function Read-ManifestLine {
    # Gibt pro Nutzzeile die an Whitespace zerlegten Felder zurueck.
    foreach ($rawLine in Get-Content -LiteralPath $manifest) {
        $line = ($rawLine -replace '#.*$', '').Trim()
        if (-not $line) { continue }
        , ($line -split '\s+')
    }
}

# Registry: Name -> @{ Cmd; Description }
$registry = [ordered]@{}
foreach ($fields in Read-ManifestLine) {
    if ($fields[0] -ne 'component') { continue }
    if ($fields.Count -lt 3) { continue }
    $registry[$fields[1]] = @{
        Cmd         = $fields[2]
        Description = ($fields[3..($fields.Count - 1)] -join ' ')
    }
}

# Verknuepfungszeilen dieser Plattform
$entries = @()
foreach ($fields in Read-ManifestLine) {
    if ($fields[0] -eq 'component') { continue }
    if ($fields.Count -lt 5) {
        Write-Warn "Manifestzeile unvollstaendig, ignoriert: $($fields -join ' ')"
        continue
    }
    if ($fields[0] -ne $platform -and $fields[0] -ne 'all') { continue }
    $entries += [PSCustomObject]@{
        Component      = $fields[1]
        Kind           = $fields[2]
        SourceRelative = $fields[3]
        Target         = $fields[4]
    }
}

# Komponenten, die auf dieser Plattform ueberhaupt Eintraege haben
$available = @($registry.Keys | Where-Object { $entries.Component -contains $_ })

if ($available.Count -eq 0) {
    Write-Fail "Manifest enthaelt keine Komponenten fuer Plattform '$platform'"
    exit 1
}

# --- Komponentenauswahl ---------------------------------------------------

function Get-MissingCommand {
    param([Parameter(Mandatory)][string]$Component)

    $cmd = $registry[$Component].Cmd
    if (-not $cmd -or $cmd -eq '-') { return $null }
    if (Get-Command $cmd -ErrorAction SilentlyContinue) { return $null }
    return $cmd
}

function Show-Components {
    Write-Host "Verfuegbare Komponenten (Plattform: $platform)" -ForegroundColor White
    Write-Host ''
    for ($i = 0; $i -lt $available.Count; $i++) {
        $name    = $available[$i]
        $missing = Get-MissingCommand -Component $name
        $line    = '  {0,2}) {1,-10} {2}' -f ($i + 1), $name, $registry[$name].Description
        if ($missing) {
            Write-Host $line -NoNewline
            Write-Host " ($missing nicht im PATH)" -ForegroundColor Yellow
        } else {
            Write-Host $line
        }
    }
    Write-Host ''
}

function Resolve-Selection {
    # Nimmt Namen und/oder Nummern (auch komma-getrennt) und liefert Namen.
    param([string[]]$Tokens)

    $result = @()
    foreach ($raw in $Tokens) {
        foreach ($token in ($raw -split '[,\s]+' | Where-Object { $_ })) {
            $index = 0
            if ([int]::TryParse($token, [ref]$index)) {
                if ($index -ge 1 -and $index -le $available.Count) {
                    $result += $available[$index - 1]
                } else {
                    Write-Warn "Nummer ausserhalb der Liste, ignoriert: $token"
                }
            } elseif ($available -contains $token) {
                $result += $token
            } else {
                Write-Warn "unbekannte Komponente, ignoriert: $token"
            }
        }
    }
    return $result
}

function Select-ComponentsInteractive {
    Show-Components
    $reply = Read-Host 'Auswahl (Nummern oder Namen, Leer = alle, q = abbrechen)'
    if ($reply -eq 'q' -or $reply -eq 'Q') {
        Write-Info 'abgebrochen'
        exit 0
    }
    if (-not $reply.Trim()) { return @($available) }
    return Resolve-Selection -Tokens @($reply)
}

if ($List) {
    Show-Components
    exit 0
}

if ($Only) {
    $selected = Resolve-Selection -Tokens $Only
} elseif ($All -or [Console]::IsInputRedirected) {
    # Ohne interaktive Konsole (Pipe, CI) nicht blockierend nachfragen.
    $selected = @($available)
} else {
    $selected = Select-ComponentsInteractive
}

if ($Skip) {
    $skipNames = @($Skip | ForEach-Object { $_ -split '[,\s]+' } | Where-Object { $_ })
    $selected  = @($selected | Where-Object { $skipNames -notcontains $_ })
}

$selected = @($selected | Select-Object -Unique)

if ($selected.Count -eq 0) {
    Write-Info 'keine Komponente ausgewaehlt — nichts zu tun'
    exit 0
}

# --- Submodule (my-zsh unter shells/zsh) ----------------------------------

function Initialize-Submodules {
    if ($selected -notcontains 'zsh') { return }
    if (-not (Test-Path -LiteralPath (Join-Path $repoRoot '.gitmodules'))) { return }
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Warn 'git nicht gefunden — Submodule uebersprungen'
        return
    }
    # Nur initialisieren, wenn wirklich noch nichts ausgecheckt ist.
    if (Test-Path -LiteralPath (Join-Path $repoRoot 'shells\zsh\.zshrc')) { return }

    if ($DryRun) {
        Write-Info '(dry-run) git submodule update --init --recursive'
        return
    }
    Write-Info 'Initialisiere Submodul (shells/zsh -> my-zsh) ...'
    git -C $repoRoot submodule update --init --recursive
}

# --- Token-Expansion ------------------------------------------------------

function Expand-TargetPath {
    param([Parameter(Mandatory)][string]$Target)

    $out = $Target
    foreach ($key in $tokens.Keys) {
        $value = $tokens[$key]
        if ([string]::IsNullOrEmpty($value)) { continue }
        $out = $out.Replace($key, $value)
    }
    return $out.Replace('/', '\')
}

# --- Ziel freiraeumen -----------------------------------------------------

# Gibt $true zurueck, wenn das Ziel jetzt frei ist und verlinkt werden darf.
function Clear-LinkTarget {
    param([Parameter(Mandatory)][string]$Path)

    $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
    if (-not $item) { return $true }

    # ReparsePoint = bestehender Symlink/Junction: darf immer weg.
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        if ($item.PSIsContainer) {
            [IO.Directory]::Delete($Path)
        } else {
            Remove-Item -LiteralPath $Path -Force
        }
        return $true
    }

    if (-not $Force) {
        Write-Warn "existiert bereits (echte Datei/Ordner), -Force noetig: $Path"
        $stats.Skipped++
        return $false
    }

    $backup = "$Path.bak-$(Get-Date -Format 'yyyyMMddHHmmss')"
    Move-Item -LiteralPath $Path -Destination $backup -Force
    Write-Warn "vorhandener Inhalt gesichert: $backup"
    return $true
}

# --- Eine Verknuepfung anlegen -------------------------------------------

function New-ConfigLink {
    param(
        [Parameter(Mandatory)][string]$Kind,
        [Parameter(Mandatory)][string]$SourceRelative,
        [Parameter(Mandatory)][string]$Target
    )

    $source = Join-Path $repoRoot ($SourceRelative -replace '/', '\')

    if (-not (Test-Path -LiteralPath $source)) {
        Write-Warn "Quelle fehlt, uebersprungen: $SourceRelative"
        $stats.Skipped++
        return
    }

    # Bereits korrekt verlinkt?
    $existing = Get-Item -LiteralPath $Target -Force -ErrorAction SilentlyContinue
    if ($existing -and ($existing.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        if ($existing.Target -and ((Resolve-Path -LiteralPath $existing.Target -ErrorAction SilentlyContinue).Path -eq (Resolve-Path -LiteralPath $source).Path)) {
            Write-Info "bereits verlinkt: $Target"
            $stats.Skipped++
            return
        }
    }

    if ($DryRun) {
        Write-Host "[dry ] $Target -> $SourceRelative" -ForegroundColor DarkGray
        $stats.Linked++
        return
    }

    $parent = Split-Path -Parent $Target
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }

    if (-not (Clear-LinkTarget -Path $Target)) { return }

    if ($Kind -eq 'dir') {
        # Junction: funktioniert ohne Admin und ohne Entwicklermodus.
        cmd /c "mklink /J `"$Target`" `"$source`"" | Out-Null
        if ($LASTEXITCODE -eq 0) {
            Write-Ok "$Target -> $SourceRelative (Junction)"
            $stats.Linked++
        } else {
            Write-Fail "Junction fehlgeschlagen: $Target"
            $stats.Failed++
        }
        return
    }

    # Datei: Symlink bevorzugt (folgt Umbenennungen der Quelle sauber),
    # sonst Hardlink, sonst Kopie.
    try {
        New-Item -ItemType SymbolicLink -Path $Target -Target $source -Force -ErrorAction Stop | Out-Null
        Write-Ok "$Target -> $SourceRelative (Symlink)"
        $stats.Linked++
        return
    } catch {
        Write-Info "Symlink nicht moeglich ($($_.Exception.Message.Trim())) — versuche Hardlink"
    }

    try {
        New-Item -ItemType HardLink -Path $Target -Target $source -Force -ErrorAction Stop | Out-Null
        Write-Ok "$Target -> $SourceRelative (Hardlink)"
        $stats.Linked++
        return
    } catch {
        Write-Info 'Hardlink nicht moeglich (anderes Laufwerk?) — kopiere'
    }

    try {
        Copy-Item -LiteralPath $source -Destination $Target -Force -ErrorAction Stop
        Write-Warn "$Target -> $SourceRelative (KOPIE — Aenderungen im Repo wirken hier nicht automatisch)"
        $stats.Linked++
    } catch {
        Write-Fail "Verknuepfung fehlgeschlagen: $Target ($($_.Exception.Message.Trim()))"
        $stats.Failed++
    }
}

# --- Ablauf ---------------------------------------------------------------

Write-Info "Repo:        $repoRoot"
Write-Info "Manifest:    $manifest"
Write-Info "Komponenten: $($selected -join ' ')"
if ($DryRun) { Write-Info 'Modus:       dry-run (es wird nichts geaendert)' }

foreach ($name in $selected) {
    $missing = Get-MissingCommand -Component $name
    if ($missing) {
        Write-Info "Hinweis: '$missing' ist nicht im PATH — Config wird trotzdem verlinkt"
    }
}

Initialize-Submodules

foreach ($entry in $entries) {
    if ($selected -notcontains $entry.Component) { continue }
    New-ConfigLink -Kind $entry.Kind -SourceRelative $entry.SourceRelative -Target (Expand-TargetPath $entry.Target)
}

Write-Host ''
Write-Info "verlinkt: $($stats.Linked), uebersprungen: $($stats.Skipped), fehlgeschlagen: $($stats.Failed)"

if ($stats.Failed -gt 0) { exit 1 }
