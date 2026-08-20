<#
.SYNOPSIS
    Erstellt echte Windows-Verknüpfungen (Symlinks/Junctions) für die 
    PowerShell-Profile und Module direkt in dein Configs-Repository.
#>

# 1. Sicherstellen, dass die Umgebungsvariable $env:REPOS_DIR existiert
if (-not $env:REPOS_DIR) {
    if (Test-Path "C:\repos") {
        $env:REPOS_DIR = "C:\repos"
        Write-Host "[info] `$env:REPOS_DIR war nicht gesetzt. Nutze Fallback: C:\repos" -ForegroundColor DarkYellow
    } else {
        Write-Error "Die Umgebungsvariable `$env:REPOS_DIR wurde nicht gefunden."
        return
    }
}

# 2. Quellpfade im Repository definieren (Die echten Dateien)
$repoDotfilesDir       = Join-Path $env:REPOS_DIR "Configs\shells\pwsh"
$srcProfile            = Join-Path $repoDotfilesDir "Microsoft.PowerShell_profile.ps1"
$srcModuleDir          = Join-Path $repoDotfilesDir "Modules\MyCliHelpers"
$srcUpdateWindowsApps  = Join-Path $repoDotfilesDir "Modules\Update-WindowsApps.psm1"

# Prüfen, ob die Quellen im Repo überhaupt existieren
if (-not (Test-Path $srcProfile)) { Write-Error "Quelle nicht gefunden: $srcProfile"; return }
if (-not (Test-Path $srcModuleDir)) { Write-Error "Quelle nicht gefunden: $srcModuleDir"; return }
if (-not (Test-Path $srcUpdateWindowsApps)) { Write-Error "Quelle nicht gefunden: $srcUpdateWindowsApps"; return }

# 3. Zielpfade für PS5 und PS7 bestimmen
$docsDir = [Environment]::GetFolderPath("MyDocuments")
$ps5Dir  = Join-Path $docsDir "WindowsPowerShell"
$ps7Dir  = Join-Path $docsDir "PowerShell"

$targets = @(
    [PSCustomObject]@{ Name = "PS5 Profil";               TargetPath = Join-Path $ps5Dir "Microsoft.PowerShell_profile.ps1";       SourcePath = $srcProfile; Type = "File" },
    [PSCustomObject]@{ Name = "PS5 Modul";                 TargetPath = Join-Path $ps5Dir "Modules\MyCliHelpers";                   SourcePath = $srcModuleDir; Type = "Directory" },
    [PSCustomObject]@{ Name = "PS5 Update-WindowsApps"; TargetPath = Join-Path $ps5Dir "Modules\Update-WindowsApps.psm1";       SourcePath = $srcUpdateWindowsApps; Type = "File" },
    [PSCustomObject]@{ Name = "PS7 Profil";               TargetPath = Join-Path $ps7Dir "Microsoft.PowerShell_profile.ps1";       SourcePath = $srcProfile; Type = "File" },
    [PSCustomObject]@{ Name = "PS7 Modul";                 TargetPath = Join-Path $ps7Dir "Modules\MyCliHelpers";                   SourcePath = $srcModuleDir; Type = "Directory" },
    [PSCustomObject]@{ Name = "PS7 Update-WindowsApps"; TargetPath = Join-Path $ps7Dir "Modules\Update-WindowsApps.psm1";       SourcePath = $srcUpdateWindowsApps; Type = "File" }
)

# 4. Verknüpfungen erstellen
foreach ($t in $targets) {
    # Übergeordneten Ordner erstellen, falls er existiert (z.B. Dokumente\PowerShell\Modules)
    $parentDir = Split-Path $t.TargetPath -Parent
    if (-not (Test-Path $parentDir)) {
        New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
    }

    # Falls am Zielort bereits eine echte Datei oder ein Ordner existiert: Weg damit!
    if (Test-Path $t.TargetPath) {
        Remove-Item $t.TargetPath -Recurse -Force | Out-Null
    }

    # Erstelle die echte Verknüpfung
    try {
        if ($t.Type -eq "File") {
            # Symbolischer Link für die Profildatei
            New-Item -ItemType SymbolicLink -Path $t.TargetPath -Target $t.SourcePath -Force | Out-Null
            Write-Host "Echter Datei-Symlink erstellt: $($t.Name) -> $($t.TargetPath)" -ForegroundColor Green
        } else {
            # Directory Junction für das Modul (Funktioniert überall ohne Admin-Zicken)
            cmd /c "mklink /J `"$($t.TargetPath)`" `"$($t.SourcePath)`"" | Out-Null
            Write-Host "Echte Ordner-Junction erstellt: $($t.Name) -> $($t.TargetPath)" -ForegroundColor Green
        }
    } catch {
        Write-Error "Fehler beim Erstellen der Verknüpfung für $($t.Name): $_"
    }
}

Write-Host "`nFertig! Alle Pfade zeigen nun direkt als Verknüpfung in dein Repo." -ForegroundColor Cyan