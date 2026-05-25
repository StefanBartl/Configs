# ==============================================================================
# PowerShell Profile Configuration
# ==============================================================================

# -----------------------------------
# Import PSReadLine for tab completion and history
# -----------------------------------
if (Get-Module -ListAvailable PSReadLine) {
  Import-Module PSReadLine

  # Check PSReadLine version to determine available features
  $psReadLineVersion = (Get-Module PSReadLine).Version

  if ($psReadLineVersion -ge '2.1.0') {
    # Modern PSReadLine features (v2.1.0+)
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
  }

  # Basic completion settings (works on all versions)
  Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
  Set-PSReadLineOption -HistorySearchCursorMovesToEnd
  Set-PSReadLineKeyHandler -Key UpArrow -Function HistorySearchBackward
  Set-PSReadLineKeyHandler -Key DownArrow -Function HistorySearchForward

} else {
  Write-Host "[warn] PSReadLine not available. Install via: Install-Module PSReadLine -Force" -ForegroundColor Yellow
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
  Write-Host "[info] starship not found. Install via winget/scoop/choco." -ForegroundColor DarkYellow
}

# -----------------------------------
# zoxide directory jumper (guarded)
# -----------------------------------
if (Test-HasCommand 'zoxide') {
  try {
    # Get the init script as a single string
    $zoxideInit = & zoxide init powershell --hook prompt
    if ($zoxideInit) {
      # Join array into single string if necessary
      if ($zoxideInit -is [array]) {
        $zoxideInit = $zoxideInit -join "`n"
      }
      Invoke-Expression $zoxideInit
    }
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
# Alias for ~ to Userprofile
# -----------------------------------
function ~ {
  Set-Location $env:USERPROFILE
}

# -----------------------------------
# Neovim related aliases
# -----------------------------------
function nvim-config {
  Set-Location C:\Users\bernhard\AppData\Local\nvim
  if (Test-HasCommand 'nvim') { nvim }
}

function nvim-data {
  Set-Location C:\Users\bernhard\AppData\Local\nvim-data
}

# -----------------------------------
# Repos related aliases
# -----------------------------------
function repos {
  Set-Location E:\repos
}

function Configs {
  Set-Location E:\repos\Configs
}

# -----------------------------------
# Enhanced aliases with proper command invocation
# -----------------------------------
function ls {
  # Try to find Unix-style ls (from Git, WSL, or similar)
  $lsCmd = Get-Command -Name 'ls.exe' -ErrorAction SilentlyContinue
  if (-not $lsCmd) {
    $lsCmd = Get-Command -Name 'ls' -CommandType Application -ErrorAction SilentlyContinue
  }

  if ($lsCmd) {
    & $lsCmd.Source --color=auto --hyperlink @args
  } else {
    # Fallback to PowerShell's Get-ChildItem
    Get-ChildItem @args
  }
}

function rgrep {
  if (Test-HasCommand 'rg') {
    & rg --hyperlink-format=kitty @args
  } else {
    Write-Host "[error] 'rg' (ripgrep) not found" -ForegroundColor Red
  }
}

function delta {
  if (Test-HasCommand 'delta') {
    & delta --hyperlinks --hyperlinks-file-link-format="file://{path}#{line}" @args
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

if (Get-Module PSReadLine) {
  try {
    Set-PSReadLineKeyHandler -Key Alt+v -ScriptBlock { Toggle-ViMode }
  } catch { }
}

# -----------------------------------
# Copy output of last command to clipboard (guarded)
# -----------------------------------
function Copy-LastOutput {
  try {
    $hist = Get-History
    if (-not $hist) { Write-Host "[info] No history yet" -ForegroundColor DarkYellow; return }
    $last = $hist[-1].CommandLine
    # Warning: re-executes the last command
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

if (Get-Module PSReadLine) {
  try {
    Set-PSReadLineKeyHandler -Key Alt+c -ScriptBlock { Copy-LastOutput }
  } catch { }
}

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
# Create a symbolic link
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
    New-Item -ItemType SymbolicLink -Path $Target -Target $resolvedSource -Force | Out-Null
    Write-Host "Symbolic link created: $Target → $resolvedSource"
  } catch {
    # Fallback to mklink via elevated cmd
    $args = if ($isDir) { '/c mklink /D'} else {'/c mklink'}
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
