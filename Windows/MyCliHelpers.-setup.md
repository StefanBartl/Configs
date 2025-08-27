# Ziel

Portierung deiner Bash/Zsh-Helfer nach PowerShell (Windows-first, PowerShell 7 kompatibel und weitgehend plattformunabhängig). Umsetzung als kleines Modul, das man sauber über das PowerShell-Profil lädt.

# Funktionsabbildung

| Bash/Zsh     | PowerShell   |
| ------------ | ------------ |
| mkcd         | mkcd         |
| cdl          | cdl          |
| countfiles   | countfiles   |
| gg           | gg           |
| myip         | myip         |
| pythonserver | pythonserver |

# Installation

1. Verzeichnisstruktur für das Modul anlegen:

   ```
   $dest = Join-Path $HOME "Documents/PowerShell/Modules/MyCliHelpers"
   New-Item -ItemType Directory -Path $dest -Force | Out-Null
   ```

2. Datei `MyCliHelpers.psm1` im Modulordner erstellen und den folgenden Code einfügen.

3. Modul in das PowerShell-Profil einbinden:

   ```
   if (-not (Test-Path $PROFILE)) { New-Item -ItemType File -Path $PROFILE -Force | Out-Null }
   Add-Content $PROFILE "`nImport-Module MyCliHelpers`n"
   . $PROFILE
   ```

4. Optional (Windows, falls Skriptausführung blockiert ist):

   ```
   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
   ```

# Modulcode: `MyCliHelpers.psm1`

```powershell
# ===============================
# MyCliHelpers.psm1
# Cross-platform friendly helpers
# ===============================

# -------------------------------
# Internal: human-readable sizes
# -------------------------------
function Convert-BytesToHuman {
    <#
    .SYNOPSIS
    Convert bytes to a human readable string.
    .DESCRIPTION
    Converts a byte length into a compact "KiB/MiB/GiB" string.
    .PARAMETER Bytes
    The byte length to convert.
    .EXAMPLE
    Convert-BytesToHuman -Bytes 1536  # -> "1.50 KiB"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][long]$Bytes
    )
    # Use binary prefixes for familiarity with GNU `ls -h`
    $units = @('B','KiB','MiB','GiB','TiB','PiB','EiB')
    $i = 0
    $value = [double]$Bytes
    while ($value -ge 1024 -and $i -lt ($units.Count - 1)) {
        $value /= 1024
        $i++
    }
    '{0:0.##} {1}' -f $value, $units[$i]
}

# ---------------------------------------
# mkcd: create directory and cd into it
# ---------------------------------------
function mkcd {
    <#
    .SYNOPSIS
    Create a directory and immediately enter it.
    .DESCRIPTION
    Ensures the directory exists (creates parents as needed) and sets the current location.
    .PARAMETER Path
    Target directory to create and enter.
    .EXAMPLE
    mkcd src\myapp
    #>
    [CmdletBinding(SupportsShouldProcess=$true)]
    param(
        [Parameter(Mandatory, Position=0)]
        [string]$Path
    )
    try {
        if ($PSCmdlet.ShouldProcess($Path, 'Create directory and enter')) {
            New-Item -ItemType Directory -Path $Path -Force -ErrorAction Stop | Out-Null
            $resolved = Resolve-Path -Path $Path -ErrorAction Stop
            Set-Location -Path $resolved
        }
    } catch {
        Write-Error $_
    }
}

# -------------------------------------------------------
# cdl: cd (default $HOME) and list by time (newest first)
# -------------------------------------------------------
function cdl {
    <#
    .SYNOPSIS
    Change directory and list items sorted by modification time.
    .DESCRIPTION
    Enters the given directory (or $HOME if omitted) and lists contents newest-first,
    with human-readable file sizes (GNU `ls -thor`-like).
    .PARAMETER Path
    Directory to enter. Defaults to $HOME.
    .EXAMPLE
    cdl            # go to $HOME and list
    .EXAMPLE
    cdl .\logs
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]$Path = $HOME
    )
    Set-Location -Path $Path

    # Collect and sort by LastWriteTime descending
    $items = Get-ChildItem -Force -ErrorAction SilentlyContinue |
        Sort-Object -Property LastWriteTime -Descending

    # Render a compact table similar to `ls -thor`
    $items | ForEach-Object {
        $time  = $_.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
        $size  = if ($_.PSIsContainer) { '<DIR>' } else { Convert-BytesToHuman $_.Length }
        $name  = $_.Name
        # Right-pad columns for readability
        '{0}  {1,8}  {2}' -f $time, $size, $name
    }
}

# ---------------------------------------------
# countfiles: recursively count files in a dir
# ---------------------------------------------
function countfiles {
    <#
    .SYNOPSIS
    Count files recursively.
    .DESCRIPTION
    Returns the total number of regular files under the given path.
    .PARAMETER Path
    Directory to scan. Defaults to the current directory.
    .EXAMPLE
    countfiles
    .EXAMPLE
    countfiles C:\Projects
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [string]$Path = '.'
    )
    try {
        (Get-ChildItem -Path $Path -Recurse -File -Force -ErrorAction SilentlyContinue | Measure-Object).Count
    } catch {
        Write-Error $_
    }
}

# ---------------------------------------------------------
# gg: recursive grep-like search with sane binary filtering
# ---------------------------------------------------------
function gg {
    <#
    .SYNOPSIS
    Recursive grep-like text search.
    .DESCRIPTION
    Uses Select-String to search for a pattern across files under a path,
    skipping common binary extensions by default. Outputs MatchInfo objects,
    which format like "path:line:col ..." with highlighting in the console.
    .PARAMETER Pattern
    The regex pattern (or literal if -Fixed is used).
    .PARAMETER Path
    Root directory to search. Defaults to current directory.
    .PARAMETER Fixed
    Treat pattern as a literal string (like `grep -F`).
    .PARAMETER ExcludeExtensions
    Extensions to exclude (without dot). Overrides the default skip list.
    .EXAMPLE
    gg TODO
    .EXAMPLE
    gg "^\s*class " src
    .EXAMPLE
    gg "error: " . -Fixed
    .EXAMPLE
    gg "foo" . -ExcludeExtensions txt,md  # search everything except .txt/.md
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position=0)]
        [string]$Pattern,
        [Parameter(Position=1)]
        [string]$Path = '.',
        [switch]$Fixed,
        [string[]]$ExcludeExtensions
    )

    # Build candidate file set
    $files = Get-ChildItem -Path $Path -Recurse -File -Force -ErrorAction SilentlyContinue

    # Default binary extensions to skip (approximation of `-I`)
    if (-not $ExcludeExtensions) {
        $ExcludeExtensions = @(
            'png','jpg','jpeg','gif','bmp','ico','svg','pdf',
            'zip','gz','tgz','bz2','xz','7z','rar',
            'exe','dll','so','dylib','bin','obj','class','o','a',
            'woff','woff2','ttf','otf',
            'mp3','wav','flac','mp4','mkv','avi','mov','webm','iso','psd'
        )
    }
    $files = $files | Where-Object {
        $ext = ($_.Extension -replace '^\.', '').ToLowerInvariant()
        $ExcludeExtensions -notcontains $ext
    }

    if (-not $files) { return }

    $args = @{
        Pattern     = $Pattern
        Path        = $files.FullName
        Encoding    = 'utf8'
        ErrorAction = 'SilentlyContinue'
    }
    if ($Fixed) { $args['SimpleMatch'] = $true }

    # Output MatchInfo objects; PowerShell will render with filename:line:col and color
    Select-String @args
}

# -------------------------------------------------
# myip: show local IPv4 and public IP (with fallback)
# -------------------------------------------------
function myip {
    <#
    .SYNOPSIS
    Show local (IPv4) and public IP addresses.
    .DESCRIPTION
    Prints the first non-loopback IPv4 address found on active interfaces and
    attempts to resolve the public IP via several HTTPS endpoints with timeouts.
    .EXAMPLE
    myip
    #>
    [CmdletBinding()]
    param()

    # Local IPv4 (cross-platform via .NET)
    $local = [System.Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
        Where-Object { $_.OperationalStatus -eq 'Up' -and $_.NetworkInterfaceType -ne 'Loopback' } |
        ForEach-Object { $_.GetIPProperties().UnicastAddresses } |
        Where-Object { $_.Address.AddressFamily -eq [System.Net.Sockets.AddressFamily]::InterNetwork } |
        Select-Object -ExpandProperty Address -First 1 -ErrorAction SilentlyContinue

    if (-not $local) { $local = '(none)' }

    # Ensure TLS1.2 for older Windows PowerShell
    $prevProto = [Net.ServicePointManager]::SecurityProtocol
    try {
        [Net.ServicePointManager]::SecurityProtocol = $prevProto -bor [Net.SecurityProtocolType]::Tls12
    } catch { }

    $public = $null
    $endpoints = @(
        'https://ifconfig.me/ip',
        'https://api.ipify.org',
        'https://ipinfo.io/ip'
    )
    foreach ($url in $endpoints) {
        try {
            $resp = Invoke-RestMethod -Uri $url -TimeoutSec 3 -ErrorAction Stop
            $candidate = ($resp | Out-String).Trim()
            if ($candidate -match '^\d{1,3}(\.\d{1,3}){3}$') {
                $public = $candidate
                break
            }
        } catch {
            continue
        }
    }
    if (-not $public) { $public = '(unavailable)' }

    [Console]::WriteLine(("Local:  {0}" -f $local))
    [Console]::WriteLine(("Public: {0}" -f $public))

    # Restore TLS setting
    try { [Net.ServicePointManager]::SecurityProtocol = $prevProto } catch { }
}

# -----------------------------------------------------------
# pythonserver: start a Python HTTP server (port optional)
# -----------------------------------------------------------
function pythonserver {
    <#
    .SYNOPSIS
    Start a simple Python HTTP server.
    .DESCRIPTION
    Starts `http.server` on the given port. Prefers the Windows "py" launcher,
    falling back to `python3` or `python`. Prints the URL before starting.
    .PARAMETER Port
    TCP port to bind. Defaults to 8000.
    .EXAMPLE
    pythonserver
    .EXAMPLE
    pythonserver 9000
    #>
    [CmdletBinding()]
    param(
        [Parameter(Position=0)]
        [ValidateRange(1,65535)]
        [int]$Port = 8000
    )
    $candidates = @('py','python3','python')
    $python = $null
    foreach ($c in $candidates) {
        $cmd = Get-Command $c -ErrorAction SilentlyContinue
        if ($cmd) { $python = $cmd.Source; break }
    }
    if (-not $python) {
        Write-Error "No Python interpreter found. Install Python or ensure it is on PATH."
        return
    }

    Write-Host ("Serving HTTP on http://localhost:{0}" -f $Port)
    # Use "-m http.server" to be version-agnostic
    & $python -m http.server $Port
}

# Export everything defined above
Export-ModuleMember -Function * -Alias *
```

# Nutzung

Beispiele:

```
mkcd .\work\scratch
cdl
countfiles .
gg "^\s*func " .
gg "TODO" . -Fixed
myip
pythonserver 8080
```

# Hinweise

1. `gg` nutzt standardmäßig eine Binär-Extension-Skip-Liste zur Annäherung an `grep -I`. Bei Bedarf über `-ExcludeExtensions` überschreiben oder leeren: `gg pattern . -ExcludeExtensions @()`.
2. PowerShell 7 färbt `Select-String`-Treffer standardmäßig. Falls Farben fehlen, sicherstellen: `$PSStyle.OutputRendering -ne 'PlainText'`.
3. Die Funktionen sind grundsätzlich auch unter PowerShell 7 auf Linux/macOS nutzbar; nur `myip`’s Public-IP hängt von HTTPS-Erreichbarkeit ab.
4. Für sehr große Repos kann `gg` mit `--fixed-strings`-artigen Suchen via `-Fixed` erheblich schneller sein.
