#Set-Location 'E:\MyGithub'

# Starship prompt
Invoke-Expression (&starship init powershell)

# zoxide directory jumper
Invoke-Expression (& { (zoxide init powershell | Out-String) })

function Invoke-Starship-PreCommand {
  $cwd = Split-Path -Leaf $PWD.Path
  $host.ui.RawUI.WindowTitle = "$cwd"
}

# -----------------------------------
# Aliases as functions (to support arguments)
# -----------------------------------

# Colored 'ls' with hyperlinks (Kitty compatible)
# Usage: ls [args]
function ls {
  command ls --color=auto --hyperlink @args
}

# ripgrep with hyperlink output for Kitty terminal
# Usage: rg [pattern] [path?]
function rgrep {
  command rg --hyperlink-format=kitty @args
}

# delta for pretty git diffs with clickable file+line links
# Usage: delta [file]
function delta {
  command delta --hyperlinks --hyperlinks-file-link-format="file://{path}#{line}" @args
}

function appdata {
  Set-Location "C:\Users\bartl\AppData"
}

# Enable colored output in less pager (used by git, etc.)
$env:LESS = "-R"

# -----------------------------------
# Toggle Vi/Emacs mode in PSReadLine
# -----------------------------------

# Toggle between Vi and Emacs editing modes
# Shortcut: Alt+v
# Usage: Toggle-ViMode
function Toggle-ViMode {
  $current = (Get-PSReadLineOption).EditMode
  if ($current -eq 'Vi') {
    Set-PSReadLineOption -EditMode Emacs
    Write-Host "Switched to Emacs mode"
  } else {
    Set-PSReadLineOption -EditMode Vi
    Write-Host "Switched to Vi mode"
  }
}

Set-PSReadLineKeyHandler -Key Alt+v -ScriptBlock { Toggle-ViMode }

# -----------------------------------
# Copy output of last command to clipboard
# -----------------------------------

# Re-executes the last command and copies its output to clipboard
# Shortcut: Alt+c
# Usage: Copy-LastOutput
function Copy-LastOutput {
  try {
    $last = (Get-History)[-1].CommandLine
    $result = Invoke-Expression $last
    $result | clip
    Write-Host "Output copied to clipboard from: $last"
  }
  catch {
    Write-Host "Error copying output"
  }
}

Set-PSReadLineKeyHandler -Key Alt+c -ScriptBlock { Copy-LastOutput }

# -----------------------------------
# Open file or folder in Windows Explorer
# -----------------------------------

# Opens a file (highlighted) or folder in Explorer
# Usage: Open-Explorer -Path <path>
function Open-Explorer {
  param (
    [string]$Path
  )

  if (-not (Test-Path $Path)) {
    Write-Host "Path does not exist: $Path" -ForegroundColor Red
    return
  }

  $fullPath = (Resolve-Path $Path).Path

  if (Test-Path $fullPath -PathType Leaf) {
    Start-Process "explorer.exe" "/select,`"$fullPath`""
  } elseif (Test-Path $fullPath -PathType Container) {
    Start-Process "explorer.exe" "`"$fullPath`""
  }
}

# -----------------------------------
# Create a symbolic link (file or directory)
# -----------------------------------

# ! Requires admin rights !
# Creates a symbolic link between -Source and -Target
# Detects whether target is a file or directory and uses /D if needed
# Usage: New-Symlink -Source <original file/folder> -Target <link name>
function New-Symlink {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $true)]
    [string]$Source,

    [Parameter(Mandatory = $true)]
    [string]$Target
  )

  if (-not (Test-Path $Source)) {
    Write-Host "Source does not exist: $Source" -ForegroundColor Red
    return
  }

  $resolvedSource = (Resolve-Path $Source).Path
  $resolvedTarget = (Resolve-Path -LiteralPath (Split-Path $Target -Parent)).Path + "\" + (Split-Path $Target -Leaf)

  $cmd = "mklink"
  $args = ""

  if (Test-Path $resolvedSource -PathType Container) {
    $args += " /D"
  }

  $args += " `"$resolvedTarget`" `"$resolvedSource`""

  try {
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c $cmd $args" -Verb RunAs -WindowStyle Hidden
    Write-Host "Symbolic link created: $resolvedTarget → $resolvedSource"
  }
  catch {
    Write-Host "Failed to create symlink: $_" -ForegroundColor Red
  }
}

# -----------------------------------
# Open new PowerShell window with admin rights
# -----------------------------------

# ! Requires admin rights !
# Launches a new PowerShell window with administrator privileges.
# Usage: Elevate-Shell
function Elevate-Shell {
  Start-Process -Verb RunAs -FilePath "powershell.exe"
}

# -----------------------------------
# Open new Starship-enabled PowerShell with admin rights
# -----------------------------------

# ! Requires admin rights !
# Launches a new PowerShell window with administrator privileges
# and loads the user's PowerShell profile (e.g. starship, functions).
# Usage: Elevate-StarshipShell
function Elevate-StarshipShell {
  Start-Process -Verb RunAs -FilePath "powershell.exe" -ArgumentList "-NoExit", "-Command", "$PROFILE"
}

Import-Module MyCliHelpers
