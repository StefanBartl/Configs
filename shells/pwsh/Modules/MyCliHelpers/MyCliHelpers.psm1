# ==============================================================================
# MyCliHelpers.psm1
# ==============================================================================
# Cross-platform-freundliche Shell-Helfer für Windows PowerShell 7+.
#
# Pfade:
#   Quelle:  $env:REPOS_DIR\Configs\shells\pwsh\Modules\MyCliHelpers\
#   Geladen: über Junction in $env:LOCALAPPDATA\PowerShell\Modules\MyCliHelpers\
#            (primär) oder $DOCUMENTS\PowerShell\Modules\MyCliHelpers\ (Fallback)
#   Angelegt von: install\install.ps1 -Only pwsh
#
# Hinweise:
#   – Funktionen wie `ls`, `mkcd`, `gg` nutzen Unix-vertraute Kurznamen statt
#     Verb-Noun-Konvention. Import mit -DisableNameChecking, um die Warnung zu
#     unterdrücken.
#   – Windows-spezifische Funktionen sind mit $IsWindows-Guards versehen.
#   – Alle Pfade werden aus Umgebungsvariablen abgeleitet – keine hardcodierten
#     User-Pfade. Plattformabhängiges steckt in Get-ReposRoot und
#     Get-NvimDirectory, nicht verstreut in den einzelnen Funktionen.
#   – `Test-ProfileHealth` (Alias `checkhealth`) prüft, ob alles Nötige da ist.
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
# $HOME ist die PowerShell-eigene Variable und auf jeder Plattform gesetzt —
# $env:USERPROFILE gibt es unter Linux/macOS nicht.
function ~ { Set-Location $HOME }

# Interner Helfer: Neovims Verzeichnisse liegen je nach Plattform woanders.
# Windows: %LOCALAPPDATA%\nvim(-data), sonst XDG (~/.config/nvim, ~/.local/share/nvim).
function Get-NvimDirectory {
    param([Parameter(Mandatory)][ValidateSet('config', 'data')][string]$Kind)

    if ($IsWindows) {
        $leaf = if ($Kind -eq 'config') { 'nvim' } else { 'nvim-data' }
        return Join-Path $env:LOCALAPPDATA $leaf
    }
    if ($Kind -eq 'config') {
        $base = if ($env:XDG_CONFIG_HOME) { $env:XDG_CONFIG_HOME } else { Join-Path $HOME '.config' }
        return Join-Path $base 'nvim'
    }
    $base = if ($env:XDG_DATA_HOME) { $env:XDG_DATA_HOME } else { Join-Path $HOME '.local/share' }
    return Join-Path $base 'nvim'
}

# nvim-config : Wechsel ins Neovim-Config-Verzeichnis und öffnet nvim
function nvim-config {
    # Pfad aus Umgebungsvariablen – funktioniert für jeden User, jede Maschine
    $cfgDir = Get-NvimDirectory -Kind config
    if (-not (Test-Path $cfgDir)) {
        Write-Host "[error] Neovim config dir nicht gefunden: $cfgDir" -ForegroundColor Red
        return
    }
    Set-Location $cfgDir
    if (Test-HasCommand 'nvim') { nvim }
}

# nvim-data : Wechsel ins Neovim-Data-Verzeichnis
function nvim-data {
    $dataDir = Get-NvimDirectory -Kind data
    if (Test-Path $dataDir) { Set-Location $dataDir }
    else { Write-Host "[error] Nicht gefunden: $dataDir" -ForegroundColor Red }
}

# Interner Helfer: Repo-Wurzel. $env:REPOS_DIR ist die Vorgabe; der Fallback
# haengt an der Plattform, damit 'C:\repos' nicht unter Linux vorgeschlagen wird.
function Get-ReposRoot {
    if ($env:REPOS_DIR) { return $env:REPOS_DIR }
    if ($IsWindows) { return 'C:\repos' }
    return (Join-Path $HOME 'repos')
}

# repos : Wechsel ins Repos-Root-Verzeichnis ($env:REPOS_DIR oder Fallback)
function repos {
    $dir = Get-ReposRoot
    if (Test-Path $dir) { Set-Location $dir }
    else { Write-Host "[error] Repos-Verzeichnis nicht gefunden: $dir (setze `$env:REPOS_DIR)" -ForegroundColor Red }
}

# Configs : Wechsel in $env:REPOS_DIR\Configs
function Configs {
    $dir = Join-Path (Get-ReposRoot) 'Configs'
    if (Test-Path $dir) { Set-Location $dir }
    else { Write-Host "[error] Configs nicht gefunden: $dir" -ForegroundColor Red }
}

# appdata : Wechsel ins AppData-Verzeichnis (Windows-only)
function appdata {
    if (-not $IsWindows) { Write-Host '[error] appdata ist Windows-only' -ForegroundColor Red; return }

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

# Copy-LastCommand : Kommandozeile des letzten History-Eintrags kopieren.
# Immer sicher — es wird nichts ausgefuehrt, nur Text kopiert.
function Copy-LastCommand {
    [CmdletBinding()]
    param()

    $hist = Get-History
    if (-not $hist) { Write-Host '[info] Noch kein History-Eintrag' -ForegroundColor DarkYellow; return }

    $last = $hist[-1].CommandLine
    Set-Clipboard -Value $last
    Write-Host "Befehl kopiert: $last"
}

# Copy-LastOutput : Ausgabe des letzten History-Eintrags in die Zwischenablage.
#
# PowerShell speichert in der History nur die Kommandozeile, nicht deren
# Ausgabe. "Output kopieren" heisst deshalb zwangslaeufig: den Befehl NOCHMAL
# ausfuehren. Bei `git push`, `rm`, `Invoke-RestMethod -Method Post` oder jedem
# anderen nicht-idempotenten Befehl passiert die Wirkung damit ein zweites Mal.
# Frueher lief das ungefragt bei jedem Alt+c.
#
# Deshalb: ohne -Rerun wird nichts ausgefuehrt. Alt+c kopiert nur noch die
# Kommandozeile (Copy-LastCommand).
function Copy-LastOutput {
    [CmdletBinding()]
    param(
        # Fuehrt den letzten Befehl erneut aus, um an seine Ausgabe zu kommen.
        [switch]$Rerun
    )

    $hist = Get-History
    if (-not $hist) { Write-Host '[info] Noch kein History-Eintrag' -ForegroundColor DarkYellow; return }

    $last = $hist[-1].CommandLine

    if (-not $Rerun) {
        Write-Host "[info] Letzter Befehl: $last" -ForegroundColor DarkYellow
        Write-Host '[info] Die Ausgabe liegt nicht in der History. Fuer erneutes' -ForegroundColor DarkYellow
        Write-Host '       Ausfuehren:  Copy-LastOutput -Rerun' -ForegroundColor DarkYellow
        Write-Host '       Nur den Befehl kopieren:  Copy-LastCommand  (Alt+c)' -ForegroundColor DarkYellow
        return
    }

    try {
        $result = Invoke-Expression $last
        Set-Clipboard -Value ($result | Out-String)
        Write-Host "Output kopiert von: $last"
    } catch {
        Write-Host "Fehler: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Alt+c → Copy-LastCommand (nur wenn PSReadLine verfügbar).
# Bewusst NICHT Copy-LastOutput: ein Tastendruck darf keinen Befehl wiederholen.
if (Get-Module PSReadLine -ErrorAction SilentlyContinue) {
    try { Set-PSReadLineKeyHandler -Key 'Alt+c' -ScriptBlock { Copy-LastCommand } } catch { }
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

#region ── Diagnose ───────────────────────────────────────────────────────────

# Interner Helfer: ein Befund fuer Test-ProfileHealth.
function New-HealthResult {
    param(
        [Parameter(Mandatory)][string]$Area,
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][ValidateSet('ok', 'warn', 'fail', 'info')][string]$Status,
        [string]$Detail = ''
    )
    [PSCustomObject]@{
        Area   = $Area
        Name   = $Name
        Status = $Status
        Detail = $Detail
    }
}

# ------------------------------------------------------------------------------
# Test-ProfileHealth  –  das :checkhealth dieses Setups.
#
# Prueft, was das Profil zur Laufzeit braucht, und sagt bei jedem Fehlschlag
# dazu, wie er zu beheben ist. Ohne Parameter farbig formatiert; mit -Quiet
# als Objekte, damit sich das Ergebnis weiterverarbeiten laesst
# (z. B. `Test-ProfileHealth -Quiet | Where-Object Status -ne 'ok'`).
# ------------------------------------------------------------------------------
function Test-ProfileHealth {
    [CmdletBinding()]
    [OutputType([PSCustomObject[]])]
    param(
        # Gibt Objekte statt formatierter Ausgabe zurueck.
        [switch]$Quiet
    )

    $results = [System.Collections.Generic.List[PSCustomObject]]::new()

    # --- Externe Tools ---------------------------------------------------
    # Wird eines davon vermisst, faellt eine Profil-Funktion still aus.
    $tools = [ordered]@{
        'starship' = 'Prompt              — winget install Starship.Starship'
        'zoxide'   = 'Verzeichnissprung   — winget install ajeetdsouza.zoxide'
        'rg'       = 'gg/rgrep-Backend    — winget install BurntSushi.ripgrep.MSVC'
        'nvim'     = 'Editor              — winget install Neovim.Neovim'
        'git'      = 'Versionskontrolle   — winget install Git.Git'
        'delta'    = 'Diff-Pager          — winget install dandavison.delta'
        'lazygit'  = 'Git-TUI             — winget install JesseDuffield.lazygit'
        'glow'     = 'Markdown-Renderer   — winget install charmbracelet.glow'
    }
    foreach ($tool in $tools.Keys) {
        # Bewusst nur -CommandType Application: dieses Modul definiert selbst
        # Wrapper-Funktionen (delta, ls, rgrep). Ohne die Einschraenkung faende
        # Get-Command die eigene Funktion und meldete das Tool als vorhanden,
        # obwohl die .exe fehlt.
        $cmd = Get-Command $tool -CommandType Application -ErrorAction SilentlyContinue |
            Select-Object -First 1
        if ($cmd) {
            $results.Add((New-HealthResult -Area 'Tools' -Name $tool -Status 'ok' -Detail $cmd.Source))
        } else {
            $results.Add((New-HealthResult -Area 'Tools' -Name $tool -Status 'warn' -Detail $tools[$tool]))
        }
    }

    # --- Umgebung --------------------------------------------------------
    if ($env:REPOS_DIR) {
        if (Test-Path -LiteralPath $env:REPOS_DIR) {
            $results.Add((New-HealthResult -Area 'Umgebung' -Name 'REPOS_DIR' -Status 'ok' -Detail $env:REPOS_DIR))
        } else {
            $results.Add((New-HealthResult -Area 'Umgebung' -Name 'REPOS_DIR' -Status 'fail' -Detail "gesetzt, aber nicht vorhanden: $env:REPOS_DIR"))
        }
    } else {
        $results.Add((New-HealthResult -Area 'Umgebung' -Name 'REPOS_DIR' -Status 'fail' -Detail 'nicht gesetzt — wezterm-Loader und Navigations-Funktionen brauchen sie'))
    }

    $results.Add((New-HealthResult -Area 'Umgebung' -Name 'PowerShell' -Status 'info' -Detail "$($PSVersionTable.PSVersion) ($($PSVersionTable.PSEdition))"))

    $psrl = Get-Module PSReadLine -ErrorAction SilentlyContinue
    if ($psrl) {
        $status = if ($psrl.Version -ge [version]'2.2') { 'ok' } else { 'warn' }
        $detail = if ($status -eq 'ok') { "$($psrl.Version)" } else { "$($psrl.Version) — ab 2.2 gibt es HistoryAndPlugin-Prediction" }
        $results.Add((New-HealthResult -Area 'Umgebung' -Name 'PSReadLine' -Status $status -Detail $detail))
    } else {
        $results.Add((New-HealthResult -Area 'Umgebung' -Name 'PSReadLine' -Status 'warn' -Detail 'nicht geladen — Tastenbelegungen im Profil greifen nicht'))
    }

    # --- Modul-Pfad (das OneDrive-Thema) ---------------------------------
    if ($IsWindows) {
        $localModules = Join-Path $env:LOCALAPPDATA 'PowerShell\Modules'
        $localMyCli   = Join-Path $localModules 'MyCliHelpers'

        if (Test-Path -LiteralPath $localMyCli) {
            $results.Add((New-HealthResult -Area 'Module' -Name 'lokale Junction' -Status 'ok' -Detail $localMyCli))
        } else {
            $results.Add((New-HealthResult -Area 'Module' -Name 'lokale Junction' -Status 'warn' -Detail "fehlt: $localMyCli — install.ps1 -Only pwsh anlegen lassen (sonst laedt das Modul ueber OneDrive)"))
        }

        if ($env:PSModulePath -like "*$localModules*") {
            $results.Add((New-HealthResult -Area 'Module' -Name 'PSModulePath' -Status 'ok' -Detail 'lokaler Pfad ist eingetragen'))
        } else {
            $results.Add((New-HealthResult -Area 'Module' -Name 'PSModulePath' -Status 'warn' -Detail 'lokaler Pfad fehlt — Abschnitt 0 des Profils hat ihn nicht eingetragen'))
        }

        $loaded = Get-Module MyCliHelpers -ErrorAction SilentlyContinue
        if ($loaded) {
            $viaOneDrive = $loaded.Path -like '*OneDrive*'
            $status = if ($viaOneDrive) { 'warn' } else { 'ok' }
            $detail = if ($viaOneDrive) { "$($loaded.Path) — laedt ueber OneDrive, das kostet bei jedem Start" } else { $loaded.Path }
            $results.Add((New-HealthResult -Area 'Module' -Name 'MyCliHelpers' -Status $status -Detail $detail))
        }
    }

    # --- Profil ----------------------------------------------------------
    if (Test-Path -LiteralPath $PROFILE) {
        $item   = Get-Item -LiteralPath $PROFILE -Force
        $isLink = [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -or [bool]$item.LinkType

        if (-not $isLink) {
            $results.Add((New-HealthResult -Area 'Profil' -Name 'Verknuepfung' -Status 'warn' -Detail 'echte Datei, keine Verknuepfung ins Repo — Repo-Aenderungen kommen hier nicht an'))
        } else {
            # Ein Symlink kann ins Leere zeigen, etwa nachdem das Repo
            # umstrukturiert wurde. Das faellt sonst erst auf, wenn Funktionen
            # aus dem Profil unerklaerlich fehlen.
            $target  = $item.Target
            $dangles = $target -and -not (Test-Path -LiteralPath $target)
            if ($dangles) {
                $results.Add((New-HealthResult -Area 'Profil' -Name 'Verknuepfung' -Status 'fail' -Detail "zeigt ins Leere: $target — install.ps1 -Only pwsh -Force neu setzen"))
            } else {
                $results.Add((New-HealthResult -Area 'Profil' -Name 'Verknuepfung' -Status 'ok' -Detail "$($item.LinkType) -> $target"))
            }
        }

        if ($PROFILE -like '*OneDrive*') {
            $results.Add((New-HealthResult -Area 'Profil' -Name 'Ablageort' -Status 'info' -Detail 'Dokumente sind nach OneDrive umgeleitet — das Profil selbst liegt dort, deshalb die lokale Modul-Junction'))
        }
    } else {
        $results.Add((New-HealthResult -Area 'Profil' -Name 'Verknuepfung' -Status 'fail' -Detail "nicht vorhanden: $PROFILE"))
    }

    # --- Init-Cache ------------------------------------------------------
    $cacheBase = Join-Path $env:LOCALAPPDATA 'pwsh\cache'
    foreach ($name in @('starship_init.ps1', 'zoxide_init.ps1')) {
        $path = Join-Path $cacheBase $name
        if (Test-Path -LiteralPath $path) {
            $age = [int]((Get-Date) - (Get-Item -LiteralPath $path).LastWriteTime).TotalDays
            $ver = if (Test-Path -LiteralPath "$path.ver") { (Get-Content "$path.ver" -Raw).Trim() } else { 'ohne Versionsstempel' }
            $results.Add((New-HealthResult -Area 'Cache' -Name $name -Status 'ok' -Detail "$age Tage alt, $ver"))
        } else {
            $results.Add((New-HealthResult -Area 'Cache' -Name $name -Status 'info' -Detail 'noch nicht erzeugt — entsteht beim naechsten Start'))
        }
    }

    if ($Quiet) { return $results.ToArray() }

    # --- Ausgabe ---------------------------------------------------------
    $glyphs = @{ ok = '[ ok ]'; warn = '[warn]'; fail = '[fail]'; info = '[info]' }
    $colors = @{ ok = 'Green'; warn = 'Yellow'; fail = 'Red'; info = 'DarkGray' }

    $currentArea = ''
    foreach ($r in $results) {
        if ($r.Area -ne $currentArea) {
            $currentArea = $r.Area
            Write-Host ''
            Write-Host $currentArea -ForegroundColor White
        }
        Write-Host $glyphs[$r.Status] -ForegroundColor $colors[$r.Status] -NoNewline
        Write-Host (' {0,-16} {1}' -f $r.Name, $r.Detail)
    }

    $bad = @($results | Where-Object { $_.Status -in @('warn', 'fail') })
    Write-Host ''
    if ($bad.Count -eq 0) {
        Write-Host 'Alles in Ordnung.' -ForegroundColor Green
    } else {
        Write-Host ("{0} Punkt(e) brauchen Aufmerksamkeit." -f $bad.Count) -ForegroundColor Yellow
    }
}

# checkhealth : Kurzform, analog zu Neovims :checkhealth
Set-Alias -Name checkhealth -Value Test-ProfileHealth
#endregion

# ==============================================================================
# Export
# ==============================================================================
Export-ModuleMember -Function * -Alias *
