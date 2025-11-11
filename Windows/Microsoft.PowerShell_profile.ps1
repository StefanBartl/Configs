# -----------------------------------
# Alias for ~ to Userprofile
# -----------------------------------
function ~ {
    Set-Location $env:USERPROFILE
}

# -----------------------------------
# Neovim related aliase
# -----------------------------------
function nvim-config {
    Set-Location C:\Users\bartl\AppData\Local\nvim
}
function nvim-data {
    Set-Location C:\Users\bartl\AppData\Local\nvim-data
}


# -----------------------------------
# Repos related aliase
# -----------------------------------
function repos {
    Set-Location E:\repos
}
function Configs {
    Set-Location E:\repos\Configs
}

# -----------------------------------
# Helper: test if an external command exists
# -----------------------------------
function Test-HasCommand {
  param([Parameter(Mandatory=$true)][string]$Name)
  try {
    $null -ne (Get-Command -Name $Name -ErrorAction Stop)
  } catch { $false }
}

# -----------------------------------
# Starship prompt (guarded)
# -----------------------------------
if (Test-HasCommand 'starship') {
  try {
    Invoke-Expression (& starship init powershell)
  } catch {
    Write-Host "[warn] starship init failed: $($_.Exception.Message)" -ForegroundColor Yellow
  }
} else {
  # Optional: hint once per session
  Write-Host "[info] starship not found. Install via winget/scoop/choco." -ForegroundColor DarkYellow
}

# -----------------------------------
# zoxide directory jumper (guarded)
# -----------------------------------
if (Test-HasCommand 'zoxide') {
  try {
    # zoxide prints init script to stdout; Out-String ensures a single string for Invoke-Expression
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
  } catch {
    Write-Host "[warn] zoxide init failed: $($_.Exception.Message)" -ForegroundColor Yellow
  }
} else {
  Write-Host "[info] zoxide not found. Install via winget/scoop/choco." -ForegroundColor DarkYellow
}

# -----------------------------------
# Window title from CWD (works without external deps)
# -----------------------------------
function Invoke-Starship-PreCommand {
  try {
    $cwd = Split-Path -Leaf $PWD.Path
    $host.ui.RawUI.WindowTitle = "$cwd"
  } catch { }
}

# -----------------------------------
# Aliases as functions (to support arguments), guarded 'command'
# -----------------------------------
function ls {
  # Colored 'ls' with hyperlinks (kitty-compatible flags are harmless elsewhere)
  if (Test-HasCommand 'ls') {
    command ls --color=auto --hyperlink @args
  } elseif (Test-HasCommand 'Get-ChildItem') {
    # Fallback to PowerShell ls
    Get-ChildItem @args
  } else {
    Write-Host "[error] No 'ls' available" -ForegroundColor Red
  }
}

function rgrep {
  # ripgrep with hyperlink output for Kitty terminal
  if (Test-HasCommand 'rg') {
    command rg --hyperlink-format=kitty @args
  } else {
    Write-Host "[error] 'rg' (ripgrep) not found" -ForegroundColor Red
  }
}

function delta {
  # pretty git diffs with clickable file+line links
  if (Test-HasCommand 'delta') {
    command delta --hyperlinks --hyperlinks-file-link-format="file://{path}#{line}" @args
  } else {
    Write-Host "[error] 'delta' not found" -ForegroundColor Red
  }
}

# Quick jump to AppData
function appdata {
  $p = Join-Path $env:USERPROFILE 'AppData'
  if (Test-Path $p) { Set-Location $p } else { Write-Host "[error] Not found: $p" -ForegroundColor Red }
}

# Enable colored output in less pager (used by git, etc.)
$env:LESS = "-R"

# -----------------------------------
# Toggle Vi/Emacs mode in PSReadLine (guarded)
# -----------------------------------
function Toggle-ViMode {
  if (-not (Get-Module -ListAvailable PSReadLine)) {
    Write-Host "[warn] PSReadLine not available" -ForegroundColor Yellow
    return
  }
  $current = (Get-PSReadLineOption).EditMode
  if ($current -eq 'Vi') {
    Set-PSReadLineOption -EditMode Emacs
    Write-Host "Switched to Emacs mode"
  } else {
    Set-PSReadLineOption -EditMode Vi
    Write-Host "Switched to Vi mode"
  }
}

try {
  Set-PSReadLineKeyHandler -Key Alt+v -ScriptBlock { Toggle-ViMode }
} catch { }

# -----------------------------------
# Copy output of last command to clipboard (guarded, re-executes last cmd)
# -----------------------------------
function Copy-LastOutput {
  try {
    $hist = Get-History
    if (-not $hist) { Write-Host "[info] No history yet" -ForegroundColor DarkYellow; return }
    $last = $hist[-1].CommandLine
    # Warning: re-executes the last command; consider excluding destructive commands if needed
    $result = Invoke-Expression $last
    if (Test-HasCommand 'clip') {
      $result | clip
      Write-Host "Output copied to clipboard from: $last"
    } else {
      Write-Host "[warn] 'clip' not found; cannot copy to clipboard" -ForegroundColor Yellow
    }
  } catch {
    Write-Host "Error copying output: $($_.Exception.Message)" -ForegroundColor Red
  }
}

try {
  Set-PSReadLineKeyHandler -Key Alt+c -ScriptBlock { Copy-LastOutput }
} catch { }

# -----------------------------------
# Open file/folder in Explorer
# -----------------------------------
function Open-Explorer {
  param([string]$Path)
  if (-not $Path) { $Path = "." }
  if (-not (Test-Path $Path)) { Write-Host "Path does not exist: $Path" -ForegroundColor Red; return }
  $fullPath = (Resolve-Path $Path).Path
  if (Test-Path $fullPath -PathType Leaf) {
    Start-Process "explorer.exe" "/select,`"$fullPath`""
  } else {
    Start-Process "explorer.exe" "`"$fullPath`""
  }
}

# -----------------------------------
# Create a symbolic link (prefers native cmdlet; needs admin or Dev Mode)
# -----------------------------------
function New-Symlink {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory=$true)][string]$Source,
    [Parameter(Mandatory=$true)][string]$Target
  )
  if (-not (Test-Path $Source)) { Write-Host "Source does not exist: $Source" -ForegroundColor Red; return }
  $resolvedSource = (Resolve-Path $Source).Path
  $targetParent = Split-Path $Target -Parent
  if ($targetParent -and -not (Test-Path $targetParent)) { New-Item -ItemType Directory -Path $targetParent | Out-Null }
  $isDir = Test-Path $resolvedSource -PathType Container

  try {
    # Prefer New-Item SymbolicLink (PS 5.1+, Win10+)
    New-Item -ItemType SymbolicLink -Path $Target -Target $resolvedSource -Force | Out-Null
    Write-Host "Symbolic link created: $Target → $resolvedSource"
  } catch {
    # Fallback to mklink via elevated cmd
    $args = $isDir ? '/c mklink /D' : '/c mklink'
    $cmdline = "$args `"$Target`" `"$resolvedSource`""
    try {
      Start-Process -FilePath "cmd.exe" -ArgumentList $cmdline -Verb RunAs -WindowStyle Hidden
      Write-Host "Symbolic link created (mklink): $Target → $resolvedSource"
    } catch {
      Write-Host "Failed to create symlink: $($_.Exception.Message)" -ForegroundColor Red
    }
  }
}

# -----------------------------------
# Elevation helpers
# -----------------------------------
function Elevate-Shell { Start-Process -Verb RunAs -FilePath "powershell.exe" }
function Elevate-StarshipShell {
  Start-Process -Verb RunAs -FilePath "powershell.exe" -ArgumentList "-NoExit","-Command",$PROFILE
}

# -----------------------------------
# Import optional custom module (guarded)
# -----------------------------------
if (Get-Module -ListAvailable -Name 'MyCliHelpers') {
  Import-Module MyCliHelpers
}

# -----------------------------------
# Session-local quality-of-life
# -----------------------------------
# Ensure kitty-style hyperlinks are harmless in other terminals
$env:LESS = "-R"

# Progress Bar: Invoke-WebRequest Alternative

<#
.SYNOPSIS
    Downloads a file with inline progress instead of overlay banner
.PARAMETER Uri
    The URL to download from
.PARAMETER OutFile
    The destination file path
#>
function Get-WebFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,

        [Parameter(Mandatory = $true)]
        [string]$OutFile
    )

    # Disable progress bar overlay
    $oldPref = $ProgressPreference
    $ProgressPreference = 'SilentlyContinue'

    try {
        # Use WebClient for manual progress handling
        $webClient = New-Object System.Net.WebClient

        # Register progress event handler
        Register-ObjectEvent -InputObject $webClient -EventName DownloadProgressChanged -Action {
            $received = $EventArgs.BytesReceived
            $total = $EventArgs.TotalBytesToReceive

            if ($total -gt 0) {
                $percent = [math]::Round(($received / $total) * 100, 1)
                $receivedMB = [math]::Round($received / 1MB, 2)
                $totalMB = [math]::Round($total / 1MB, 2)

                # Inline progress without newline
                Write-Host "`rProgress: $percent% ($receivedMB MB / $totalMB MB)" -NoNewline -ForegroundColor Cyan
            }
        } | Out-Null

        # Start download
        $webClient.DownloadFileAsync($Uri, $OutFile)

        # Wait for completion
        while ($webClient.IsBusy) {
            Start-Sleep -Milliseconds 100
        }

        # Final newline
        Write-Host ""
        Write-Host "Download completed: $OutFile" -ForegroundColor Green

    } catch {
        Write-Host ""
        Write-Error "Download failed: $_"
    } finally {
        # Cleanup
        Get-EventSubscriber | Where-Object { $_.SourceObject -eq $webClient } | Unregister-Event
        $webClient.Dispose()
        $ProgressPreference = $oldPref
    }
}
