<#
.SYNOPSIS
    Configs — Installer fuer Windows.

.DESCRIPTION
    Legt Verknuepfungen gemaess install/links.conf an (Zeilen mit Plattform
    "windows" oder "all"). Gegenstueck: install/install.sh fuer Linux/macOS/WSL,
    das dieselbe Manifestdatei liest.

    Verknuepfungsstrategie (ohne Admin-Rechte lauffaehig):
      Verzeichnis : Junction (braucht nie Admin)
      Datei       : Symlink -> faellt auf Hardlink zurueck (gleiches Laufwerk,
                    kein Admin/Entwicklermodus noetig) -> zuletzt Kopie mit Warnung

.PARAMETER DryRun
    Zeigt nur an, was passieren wuerde; aendert nichts.

.PARAMETER Force
    Ersetzt auch vorhandene echte Dateien/Ordner am Ziel. Der bisherige Inhalt
    wird vorher nach <ziel>.bak-<zeitstempel> verschoben.

.EXAMPLE
    .\install\install.ps1 -DryRun
.EXAMPLE
    .\install\install.ps1 -Force
#>
[CmdletBinding()]
param(
    [switch]$DryRun,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

# --- Pfade ----------------------------------------------------------------

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot  = Split-Path -Parent $scriptDir
$manifest  = Join-Path $scriptDir 'links.conf'

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

# --- Submodule (my-zsh unter shells/zsh) ----------------------------------

function Initialize-Submodules {
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
    Write-Info 'Initialisiere Submodule (shells/zsh -> my-zsh) ...'
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

Write-Info "Repo:     $repoRoot"
Write-Info "Manifest: $manifest"
if ($DryRun) { Write-Info 'Modus:    dry-run (es wird nichts geaendert)' }

Initialize-Submodules

foreach ($rawLine in Get-Content -LiteralPath $manifest) {
    $line = ($rawLine -replace '#.*$', '').Trim()
    if (-not $line) { continue }

    $fields = $line -split '\s+'
    if ($fields.Count -lt 4) {
        Write-Warn "Manifestzeile unvollstaendig, ignoriert: $line"
        continue
    }

    $platform = $fields[0]
    if ($platform -ne 'windows' -and $platform -ne 'all') { continue }

    New-ConfigLink -Kind $fields[1] -SourceRelative $fields[2] -Target (Expand-TargetPath $fields[3])
}

Write-Host ''
Write-Info "verlinkt: $($stats.Linked), uebersprungen: $($stats.Skipped), fehlgeschlagen: $($stats.Failed)"

if ($stats.Failed -gt 0) { exit 1 }
