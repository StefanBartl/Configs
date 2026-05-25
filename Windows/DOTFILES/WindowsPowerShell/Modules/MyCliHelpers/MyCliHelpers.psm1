# ==============================================================================
# MyCliHelpers.psm1
# Path: C:\Users\StefanBartl\...\WindowsPowerShell\Modules\MyCliHelpers\MyCliHelpers.psm1
# Cross-platform friendly shell helpers.
#
# Note on verb naming: functions like `ls`, `mkcd`, `gg` intentionally use
# short, Unix-familiar names rather than the Verb-Noun convention required for
# published modules. Import with -DisableNameChecking to suppress the warning.
# ==============================================================================

# function prompt {
    # # Sendet das aktuelle Verzeichnis an das Windows Terminal
    # $currentDir = $ExecutionContext.SessionState.Path.CurrentLocation.ProviderPath
    # if ($env:WT_SESSION) {
        # [Console]::Write("`e]9;9;`"$currentDir`"`e\")
    # }

    # # Hier wird der normale Prompt-Text definiert (z.B. "PWSH C:\Pfad>")
    # "PWSH $($ExecutionContext.SessionState.Path.CurrentFolderText)> "
# }

# ------------------------------------------------------------------------------
# Internal: human-readable byte sizes (KiB/MiB/GiB)
# ------------------------------------------------------------------------------
function Convert-BytesToHuman {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][long]$Bytes
    )
    $units = [string[]]@('B','KiB','MiB','GiB','TiB','PiB','EiB')
    $i     = 0
    $value = [double]$Bytes
    while ($value -ge 1024 -and $i -lt ($units.Count - 1)) {
        $value /= 1024
        $i++
    }
    '{0:0.##} {1}' -f $value, $units[$i]
}

# ------------------------------------------------------------------------------
# Internal: check whether an external command exists on PATH.
# Duplicated here so the module works standalone without the profile helper.
# ------------------------------------------------------------------------------
function Test-HasCommand {
    param([Parameter(Mandatory = $true)][string]$Name)
    try {
        $null -ne (Get-Command -Name $Name -ErrorAction Stop)
    } catch { $false }
}

# ==============================================================================
# Navigation helpers
# ==============================================================================

# Navigate to $USERPROFILE
function ~ { Set-Location $env:USERPROFILE }

# Open the Neovim config directory and optionally start nvim
function nvim-config {
    $cfgDir = 'C:\Users\StefanBartl\AppData\Local\nvim'
    if (-not (Test-Path $cfgDir)) {
        Write-Host "[error] Neovim config dir not found: $cfgDir" -ForegroundColor Red
        return
    }
    Set-Location $cfgDir
    if (Test-HasCommand 'nvim') { nvim }
}

# Navigate to the Neovim data directory
function nvim-data {
    $dataDir = 'C:\Users\StefanBartl\AppData\Local\nvim-data'
    if (Test-Path $dataDir) { Set-Location $dataDir }
    else { Write-Host "[error] Not found: $dataDir" -ForegroundColor Red }
}

# Quick jumps to common project roots
function repos   { Set-Location 'C:\repos' }
function Configs { Set-Location 'C:\repos\Configs' }

# Quick jump to AppData
function appdata {
    $p = Join-Path $env:USERPROFILE 'AppData'
    if (Test-Path $p) { Set-Location $p }
    else { Write-Host "[error] Not found: $p" -ForegroundColor Red }
}

# mkcd: create directory hierarchy and enter it
function mkcd {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory, Position = 0)][string]$Path
    )
    try {
        if ($PSCmdlet.ShouldProcess($Path, 'Create directory and enter')) {
            New-Item -ItemType Directory -Path $Path -Force -ErrorAction Stop | Out-Null
            Set-Location -Path (Resolve-Path -Path $Path -ErrorAction Stop)
        }
    } catch { Write-Error $_ }
}

# cdl: cd and list newest-first with human-readable sizes
function cdl {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)][string]$Path = $HOME
    )
    Set-Location -Path $Path
    Get-ChildItem -Force -ErrorAction SilentlyContinue |
        Sort-Object -Property LastWriteTime -Descending |
        ForEach-Object {
            $time = $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
            $size = if ($_.PSIsContainer) { '<DIR>' } else { Convert-BytesToHuman $_.Length }
            '{0}  {1,8}  {2}' -f $time, $size, $_.Name
        }
}

# ==============================================================================
# Clipboard helpers
# ==============================================================================

# Copy the output of the last history entry to the clipboard
function Copy-LastOutput {
    try {
        $hist = Get-History
        if (-not $hist) { Write-Host "[info] No history yet" -ForegroundColor DarkYellow; return }
        $last   = $hist[-1].CommandLine
        $result = Invoke-Expression $last
        if (Test-HasCommand 'clip') {
            $result | clip
            Write-Host "Output copied from: $last"
        } else {
            Write-Host "[warn] 'clip' not found" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Bind Alt+c to Copy-LastOutput if PSReadLine is available
if (Get-Module PSReadLine -ErrorAction SilentlyContinue) {
    try { Set-PSReadLineKeyHandler -Key Alt+c -ScriptBlock { Copy-LastOutput } } catch { }
}

# ==============================================================================
# File system helpers
# ==============================================================================

# Open a file or directory in Windows Explorer
function Open-Explorer {
    param([string]$Path = '.')
    if (-not (Test-Path $Path)) { Write-Host "Not found: $Path" -ForegroundColor Red; return }
    $full = (Resolve-Path $Path).Path
    if (Test-Path $full -PathType Leaf) { Start-Process explorer.exe "/select,`"$full`"" }
    else                                { Start-Process explorer.exe "`"$full`"" }
}

# Create a symbolic link; falls back to mklink via elevated cmd on access errors
function New-Symlink {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Target
    )
    if (-not (Test-Path $Source)) { Write-Host "Source not found: $Source" -ForegroundColor Red; return }
    $resolvedSrc  = (Resolve-Path $Source).Path
    $targetParent = Split-Path $Target -Parent
    if ($targetParent -and -not (Test-Path $targetParent)) {
        New-Item -ItemType Directory -Path $targetParent | Out-Null
    }
    $isDir = Test-Path $resolvedSrc -PathType Container
    try {
        New-Item -ItemType SymbolicLink -Path $Target -Target $resolvedSrc -Force | Out-Null
        Write-Host "Symlink created: $Target -> $resolvedSrc"
    } catch {
        $flag    = if ($isDir) { '/D' } else { '' }
        $cmdline = "/c mklink $flag `"$Target`" `"$resolvedSrc`""
        try {
            Start-Process cmd.exe -ArgumentList $cmdline -Verb RunAs -WindowStyle Hidden
            Write-Host "Symlink created via mklink: $Target -> $resolvedSrc"
        } catch {
            Write-Host "Failed: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

# Count files recursively
function countfiles {
    [CmdletBinding()]
    param([Parameter(Position = 0)][string]$Path = '.')
    try {
        (Get-ChildItem -Path $Path -Recurse -File -Force -ErrorAction SilentlyContinue |
            Measure-Object).Count
    } catch { Write-Error $_ }
}

# o: Öffne Dateien oder Ordner mit der Standard-App (Ersatz für o.cmd)
function o {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0, ValueFromPipeline = $true)]
        [string]$Path = '.'
    )
    process {
        # Falls nichts übergeben wurde oder ein leerer String
        if ([string]::IsNullOrWhiteSpace($Path)) { $Path = '.' }

        try {
            # Startet die Datei/Ordner mit der Windows-Standardanwendung
            Start-Process -FilePath $Path
        } catch {
            Write-Error "Datei oder Verzeichnis konnte nicht geöffnet werden: $_"
        }
    }
}
# ==============================================================================
# Elevation helpers
# ==============================================================================

function Elevate-Shell {
    Start-Process -Verb RunAs -FilePath 'powershell.exe'
}

function Elevate-StarshipShell {
    Start-Process -Verb RunAs -FilePath 'powershell.exe' `
        -ArgumentList '-NoExit', '-Command', $PROFILE
}

# ==============================================================================
# Enhanced external command wrappers
# ==============================================================================

# ls: prefer Unix ls (from Git for Windows / WSL), fall back to Get-ChildItem
function ls {
    $lsCmd = Get-Command -Name 'ls.exe' -ErrorAction SilentlyContinue
    if (-not $lsCmd) {
        $lsCmd = Get-Command -Name 'ls' -CommandType Application -ErrorAction SilentlyContinue
    }
    if ($lsCmd) { & $lsCmd.Source --color=auto --hyperlink @args }
    else        { Get-ChildItem @args }
}

# rgrep: ripgrep wrapper with kitty hyperlinks
function rgrep {
    if (Test-HasCommand 'rg') { & rg --hyperlink-format=kitty @args }
    else { Write-Host "[error] ripgrep (rg) not found" -ForegroundColor Red }
}

# delta: diff pager with hyperlinks
function delta {
    if (Test-HasCommand 'delta') {
        & delta --hyperlinks --hyperlinks-file-link-format="file://{path}#{line}" @args
    } else {
        Write-Host "[error] delta not found" -ForegroundColor Red
    }
}

# ==============================================================================
# Search
# ==============================================================================

# gg: recursive text search (uses Select-String; skips common binary extensions)
function gg {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)][string]$Pattern,
        [Parameter(Position = 1)][string]$Path = '.',
        [switch]$Fixed,
        [string[]]$ExcludeExtensions
    )

    # Default binary extension skip-list
    if (-not $ExcludeExtensions) {
        $ExcludeExtensions = [string[]]@(
            'png','jpg','jpeg','gif','bmp','ico','svg','pdf',
            'zip','gz','tgz','bz2','xz','7z','rar',
            'exe','dll','so','dylib','bin','obj','class','o','a',
            'woff','woff2','ttf','otf',
            'mp3','wav','flac','mp4','mkv','avi','mov','webm','iso','psd'
        )
    }

    $files = Get-ChildItem -Path $Path -Recurse -File -Force -ErrorAction SilentlyContinue |
        Where-Object {
            $ext = ($_.Extension -replace '^\.', '').ToLowerInvariant()
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

# ==============================================================================
# Network helpers
# ==============================================================================

# myip: show local IPv4 and public IP address
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

    # Ensure TLS 1.2 for older Windows PowerShell
    $prevProto = [Net.ServicePointManager]::SecurityProtocol
    try {
        [Net.ServicePointManager]::SecurityProtocol =
            $prevProto -bor [Net.SecurityProtocolType]::Tls12
    } catch { }

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
    if (-not $public) { $public = '(unavailable)' }

    [Console]::WriteLine('Local:  {0}' -f $local)
    [Console]::WriteLine('Public: {0}' -f $public)

    try { [Net.ServicePointManager]::SecurityProtocol = $prevProto } catch { }
}

# ==============================================================================
# Web server helper
# ==============================================================================

# pythonserver: start a Python HTTP server on the given port
function pythonserver {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)][ValidateRange(1, 65535)][int]$Port = 8000
    )
    $python = $null
    foreach ($c in @('py', 'python3', 'python')) {
        $cmd = Get-Command $c -ErrorAction SilentlyContinue
        if ($cmd) { $python = $cmd.Source; break }
    }
    if (-not $python) {
        Write-Error 'No Python interpreter found. Ensure python is on PATH.'
        return
    }
    Write-Host ('Serving on http://localhost:{0}' -f $Port)
    & $python -m http.server $Port
}

# ==============================================================================
# Module export
# ==============================================================================
Export-ModuleMember -Function * -Alias *
