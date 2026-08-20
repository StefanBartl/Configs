# ==============================================================================
# MyCliHelpers.psm1
# ==============================================================================
# Cross-platform-freundliche Shell-Helfer für Windows PowerShell 7+.
#
# Pfade:
#   Quelle:  $env:REPOS_DIR\Configs\Windows\DOTFILES\WindowsPowerShell\Modules\MyCliHelpers\
#   Geladen: über Junction in $env:LOCALAPPDATA\PowerShell\Modules\MyCliHelpers\
#            (primär) oder $DOCUMENTS\PowerShell\Modules\MyCliHelpers\ (Fallback)
#
# Hinweise:
#   – Funktionen wie `ls`, `mkcd`, `gg` nutzen Unix-vertraute Kurznamen statt
#     Verb-Noun-Konvention. Import mit -DisableNameChecking, um die Warnung zu
#     unterdrücken.
#   – Windows-spezifische Funktionen sind mit $IsWindows-Guards versehen.
#   – Alle Pfade werden aus Umgebungsvariablen abgeleitet – keine hardcodierten
#     User-Pfade.
# ==============================================================================

#region ── Modul-init: einmalige Command-Lookups ──────────────────────────────
# Gecacht auf Modul-Ebene ($script:): teuer nur beim ersten Import, dann O(1).
# Path ändert sich in einer Session nicht – daher ist einmaliges Cachen sicher.

# ls-Executable: Git-for-Windows ls.exe bevorzugt, dann jede Application 'ls'
$script:_lsExe = (Get-Command 'ls.exe' -CommandType Application -ErrorAction SilentlyContinue) ??
                 (Get-Command 'ls'      -CommandType Application -ErrorAction SilentlyContinue)

# Session-Cache für Test-HasCommand (innerhalb des Moduls)
$script:_cmdCache = [System.Collections.Generic.Dictionary[string, bool]]::new(8)
#endregion

#region ── Interne Helfer ─────────────────────────────────────────────────────

# ------------------------------------------------------------------------------
# Convert-BytesToHuman  –  menschenlesbare Byte-Größen (KiB/MiB/GiB)
# ------------------------------------------------------------------------------
function Convert-BytesToHuman {
    [CmdletBinding()]
    param([Parameter(Mandatory)][long]$Bytes)

    $units = [string[]]@('B', 'KiB', 'MiB', 'GiB', 'TiB', 'PiB', 'EiB')
    $i     = 0
    $value = [double]$Bytes
    while ($value -ge 1024 -and $i -lt ($units.Count - 1)) {
        $value /= 1024
        $i++
    }
    '{0:0.##} {1}' -f $value, $units[$i]
}

# ------------------------------------------------------------------------------
# Test-HasCommand  –  prüft ob ein externer Befehl im PATH verfügbar ist.
# Separat implementiert damit das Modul standalone (ohne Profil) funktioniert.
# Ergebnisse werden session-weit gecacht.
# ------------------------------------------------------------------------------
function Test-HasCommand {
    param([Parameter(Mandatory)][string]$Name)

    [bool]$hit = $false
    if ($script:_cmdCache.TryGetValue($Name, [ref]$hit)) { return $hit }

    $found = [bool](Get-Command -Name $Name -ErrorAction SilentlyContinue)
    $script:_cmdCache[$Name] = $found
    return $found
}
#endregion

#region ── Navigation ─────────────────────────────────────────────────────────

# ~ : Wechsel ins Home-Verzeichnis
function ~ { Set-Location $env:USERPROFILE }

# nvim-config : Wechsel ins Neovim-Config-Verzeichnis und öffnet nvim
function nvim-config {
    # Pfad aus Umgebungsvariable – funktioniert für jeden User, jede Maschine
    $cfgDir = Join-Path $env:LOCALAPPDATA 'nvim'
    if (-not (Test-Path $cfgDir)) {
        Write-Host "[error] Neovim config dir nicht gefunden: $cfgDir" -ForegroundColor Red
        return
    }
    Set-Location $cfgDir
    if (Test-HasCommand 'nvim') { nvim }
}

# nvim-data : Wechsel ins Neovim-Data-Verzeichnis
function nvim-data {
    $dataDir = Join-Path $env:LOCALAPPDATA 'nvim-data'
    if (Test-Path $dataDir) { Set-Location $dataDir }
    else { Write-Host "[error] Nicht gefunden: $dataDir" -ForegroundColor Red }
}

# repos : Wechsel ins Repos-Root-Verzeichnis ($env:REPOS_DIR oder C:\repos)
function repos {
    $dir = if ($env:REPOS_DIR) { $env:REPOS_DIR } else { 'C:\repos' }
    if (Test-Path $dir) { Set-Location $dir }
    else { Write-Host "[error] Repos-Verzeichnis nicht gefunden: $dir" -ForegroundColor Red }
}

# Configs : Wechsel in $env:REPOS_DIR\Configs
function Configs {
    $base = if ($env:REPOS_DIR) { $env:REPOS_DIR } else { 'C:\repos' }
    $dir  = Join-Path $base 'Configs'
    if (Test-Path $dir) { Set-Location $dir }
    else { Write-Host "[error] Configs nicht gefunden: $dir" -ForegroundColor Red }
}

# appdata : Wechsel ins AppData-Verzeichnis
function appdata {
    $p = Join-Path $env:USERPROFILE 'AppData'
    if (Test-Path $p) { Set-Location $p }
    else { Write-Host "[error] Nicht gefunden: $p" -ForegroundColor Red }
}

# mkcd : Verzeichnis anlegen und hineinwechseln
function mkcd {
    [CmdletBinding(SupportsShouldProcess)]
    param([Parameter(Mandatory, Position = 0)][string]$Path)

    try {
        if ($PSCmdlet.ShouldProcess($Path, 'Verzeichnis anlegen und betreten')) {
            New-Item -ItemType Directory -Path $Path -Force -ErrorAction Stop | Out-Null
            Set-Location -Path (Resolve-Path -Path $Path -ErrorAction Stop)
        }
    } catch { Write-Error $_ }
}

# cdl : cd + sortierte Verzeichnisanzeige (neueste zuerst, menschenlesbare Größen)
function cdl {
    [CmdletBinding()]
    param([Parameter(Position = 0)][string]$Path = $HOME)

    Set-Location -Path $Path
    Get-ChildItem -Force -ErrorAction SilentlyContinue |
        Sort-Object -Property LastWriteTime -Descending |
        ForEach-Object {
            $time = $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
            $size = if ($_.PSIsContainer) { '<DIR>' } else { Convert-BytesToHuman $_.Length }
            '{0}  {1,8}  {2}' -f $time, $size, $_.Name
        }
}
#endregion

#region ── Clipboard ──────────────────────────────────────────────────────────

# Copy-LastOutput : Ausgabe des letzten History-Eintrags in die Zwischenablage
function Copy-LastOutput {
    try {
        $hist = Get-History
        if (-not $hist) { Write-Host '[info] Noch kein History-Eintrag' -ForegroundColor DarkYellow; return }

        $last   = $hist[-1].CommandLine
        $result = Invoke-Expression $last

        if (Test-HasCommand 'clip') {
            $result | clip
            Write-Host "Output kopiert von: $last"
        } else {
            Write-Host "[warn] 'clip' nicht gefunden" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Fehler: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Alt+c → Copy-LastOutput (nur wenn PSReadLine verfügbar)
if (Get-Module PSReadLine -ErrorAction SilentlyContinue) {
    try { Set-PSReadLineKeyHandler -Key 'Alt+c' -ScriptBlock { Copy-LastOutput } } catch { }
}
#endregion

#region ── Dateisystem ────────────────────────────────────────────────────────

# Open-Explorer : Datei oder Verzeichnis im Windows Explorer öffnen
function Open-Explorer {
    param([string]$Path = '.')

    if (-not (Test-Path $Path)) { Write-Host "Nicht gefunden: $Path" -ForegroundColor Red; return }

    if (-not $IsWindows) { Write-Host '[error] Open-Explorer ist Windows-only' -ForegroundColor Red; return }

    $full = (Resolve-Path $Path).Path
    if (Test-Path $full -PathType Leaf) { Start-Process explorer.exe "/select,`"$full`"" }
    else                                { Start-Process explorer.exe "`"$full`"" }
}

# New-Symlink : Symbolischen Link erstellen; Fallback auf mklink bei Zugriffsfehler
function New-Symlink {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Target
    )

    if (-not (Test-Path $Source)) { Write-Host "Quelle nicht gefunden: $Source" -ForegroundColor Red; return }

    $resolvedSrc  = (Resolve-Path $Source).Path
    $targetParent = Split-Path $Target -Parent
    if ($targetParent -and -not (Test-Path $targetParent)) {
        New-Item -ItemType Directory -Path $targetParent | Out-Null
    }

    $isDir = Test-Path $resolvedSrc -PathType Container
    try {
        New-Item -ItemType SymbolicLink -Path $Target -Target $resolvedSrc -Force | Out-Null
        Write-Host "Symlink erstellt: $Target -> $resolvedSrc"
    } catch {
        $flag    = if ($isDir) { '/D' } else { '' }
        $cmdline = "/c mklink $flag `"$Target`" `"$resolvedSrc`""
        try {
            Start-Process cmd.exe -ArgumentList $cmdline -Verb RunAs -WindowStyle Hidden
            Write-Host "Symlink via mklink erstellt: $Target -> $resolvedSrc"
        } catch {
            Write-Host "Fehler: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# countfiles : Dateien rekursiv zählen
function countfiles {
    [CmdletBinding()]
    param([Parameter(Position = 0)][string]$Path = '.')

    try {
        (Get-ChildItem -Path $Path -Recurse -File -Force -ErrorAction SilentlyContinue |
            Measure-Object).Count
    } catch { Write-Error $_ }
}

# o : Datei oder Verzeichnis mit Standard-App öffnen
function o {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline)][string]$Path = '.'
    )
    process {
        if ([string]::IsNullOrWhiteSpace($Path)) { $Path = '.' }
        try { Start-Process -FilePath $Path }
        catch { Write-Error "Konnte nicht geöffnet werden: $_" }
    }
}
#endregion

#region ── Elevation ──────────────────────────────────────────────────────────

# Elevate-Shell : Neue erhöhte Shell mit der aktuellen PS-Version
function Elevate-Shell {
    if (-not $IsWindows) { Write-Host '[error] Elevation ist Windows-only' -ForegroundColor Red; return }
    # Nutzt den Pfad des laufenden Prozesses – funktioniert für pwsh.exe und powershell.exe
    $exe = (Get-Process -Id $PID).MainModule.FileName
    Start-Process -Verb RunAs -FilePath $exe
}

# Elevate-StarshipShell : Erhöhte Shell ohne separates Starship-Argument
# (Profil wird automatisch geladen, Starship initialisiert sich selbst)
function Elevate-StarshipShell {
    if (-not $IsWindows) { Write-Host '[error] Elevation ist Windows-only' -ForegroundColor Red; return }
    $exe = (Get-Process -Id $PID).MainModule.FileName
    Start-Process -Verb RunAs -FilePath $exe -ArgumentList '-NoExit'
}
#endregion

#region ── External-Command-Wrapper ───────────────────────────────────────────

# ls : Unix-ls bevorzugt (Git for Windows / WSL), Fallback auf Get-ChildItem.
#      $script:_lsExe wird einmalig beim Modul-Import gesetzt (Modul-Init-Region).
function ls {
    if ($script:_lsExe) { & $script:_lsExe.Source --color=auto --hyperlink @args }
    else                 { Get-ChildItem @args }
}

# rgrep : ripgrep mit kitty-Hyperlinks
function rgrep {
    if (Test-HasCommand 'rg') { & rg --hyperlink-format=kitty @args }
    else { Write-Host '[error] ripgrep (rg) nicht gefunden' -ForegroundColor Red }
}

# delta : Diff-Pager mit Hyperlinks
function delta {
    if (Test-HasCommand 'delta') {
        & delta --hyperlinks --hyperlinks-file-link-format='file://{path}#{line}' @args
    } else {
        Write-Host '[error] delta nicht gefunden' -ForegroundColor Red
    }
}
#endregion

#region ── Suche ──────────────────────────────────────────────────────────────

# gg : Rekursive Textsuche.
#      Wenn rg (ripgrep) verfügbar ist, wird es delegiert – deutlich schneller
#      als Select-String bei großen Verzeichnissen.
function gg {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)][string]$Pattern,
        [Parameter(Position = 1)][string]$Path = '.',
        [switch]$Fixed,
        [string[]]$ExcludeExtensions
    )

    # Wenn rg verfügbar: delegieren (wesentlich schneller als Select-String)
    if (Test-HasCommand 'rg') {
        $rgArgs = @('--color', 'auto')
        if ($Fixed)  { $rgArgs += '--fixed-strings' }
        if ($Path)   { $rgArgs += $Path }
        $rgArgs += $Pattern
        & rg @rgArgs
        return
    }

    # Fallback: Select-String (PS-native, langsamer bei großen Bäumen)
    if (-not $ExcludeExtensions) {
        $ExcludeExtensions = [string[]]@(
            'png', 'jpg', 'jpeg', 'gif', 'bmp', 'ico', 'svg', 'pdf',
            'zip', 'gz',  'tgz', 'bz2', 'xz',  '7z',  'rar',
            'exe', 'dll', 'so',  'dylib','bin',  'obj', 'class', 'o', 'a',
            'woff','woff2','ttf','otf',
            'mp3', 'wav', 'flac','mp4', 'mkv',  'avi', 'mov', 'webm', 'iso', 'psd'
        )
    }

    $files = Get-ChildItem -Path $Path -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object {
            $ext = ($_.Extension -replace '^\.',  '').ToLowerInvariant()
            $ExcludeExtensions -notcontains $ext
        }

    if (-not $files) { return }

    $ssArgs = @{
        Pattern     = $Pattern
        Path        = $files.FullName
        Encoding    = 'utf8'
        ErrorAction = 'SilentlyContinue'
    }
    if ($Fixed) { $ssArgs['SimpleMatch'] = $true }

    Select-String @ssArgs
}
#endregion

#region ── Netzwerk ───────────────────────────────────────────────────────────

# myip : Lokale IPv4 + öffentliche IP anzeigen
function myip {
    [CmdletBinding()]
    param()

    $local = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
        Where-Object {
            $_.OperationalStatus -eq 'Up' -and
            $_.NetworkInterfaceType -ne 'Loopback'
        } |
        ForEach-Object { $_.GetIPProperties().UnicastAddresses } |
        Where-Object {
            $_.Address.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork
        } |
        Select-Object -ExpandProperty Address -First 1 -ErrorAction SilentlyContinue

    if (-not $local) { $local = '(none)' }

    $public    = $null
    $endpoints = [string[]]@(
        'https://ifconfig.me/ip',
        'https://api.ipify.org',
        'https://ipinfo.io/ip'
    )
    foreach ($url in $endpoints) {
        try {
            $resp      = Invoke-RestMethod -Uri $url -TimeoutSec 3 -ErrorAction Stop
            $candidate = ($resp | Out-String).Trim()
            if ($candidate -match '^\d{1,3}(\.\d{1,3}){3}$') { $public = $candidate; break }
        } catch { continue }
    }
    if (-not $public) { $public = '(nicht erreichbar)' }

    [Console]::WriteLine('Lokal:     {0}', $local)
    [Console]::WriteLine('Öffentlich:{0}', $public)
}
#endregion

#region ── Web-Server ─────────────────────────────────────────────────────────

# pythonserver : Python-HTTP-Server auf gegebenem Port starten
function pythonserver {
    [CmdletBinding()]
    param([Parameter(Position = 0)][ValidateRange(1, 65535)][int]$Port = 8000)

    $python = $null
    foreach ($c in @('py', 'python3', 'python')) {
        $cmd = Get-Command $c -ErrorAction SilentlyContinue
        if ($cmd) { $python = $cmd.Source; break }
    }
    if (-not $python) {
        Write-Error 'Kein Python-Interpreter gefunden. Sicherstellen, dass python im PATH ist.'
        return
    }
    Write-Host ('Server läuft auf http://localhost:{0}' -f $Port)
    & $python -m http.server $Port
}
#endregion

# ==============================================================================
# Export
# ==============================================================================
Export-ModuleMember -Function * -Alias *
