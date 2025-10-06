# install-context.ps1
# Installs a single Explorer context menu entry "Open with Neovim (new instance)"
# under HKCU and removes common legacy entries under HKCU/HKLM.
# Default install path: C:\tools\OpenInNvim

param(
  [string]$InstallPath = 'C:\tools\OpenInNvim'
)

$ErrorActionPreference = 'Stop'

function Ensure-Path {
  param([string]$p)
  if (-not (Test-Path -LiteralPath $p)) {
    New-Item -ItemType Directory -Path $p -Force | Out-Null
  }
}

function Remove-Key {
  param([string]$key)
  try {
    if (Test-Path -LiteralPath $key) {
      Remove-Item -LiteralPath $key -Recurse -Force -ErrorAction Stop
      Write-Host "Removed: $key"
    }
  } catch {
    Write-Warning "Could not remove $key: $($_.Exception.Message)"
  }
}

function Set-Menu {
  param([string]$baseKey, [string]$display, [string]$command, [string]$icon)
  New-Item -Path $baseKey -Force | Out-Null
  New-ItemProperty -Path $baseKey -Name '(default)' -Value $display -PropertyType String -Force | Out-Null
  if ($icon) { New-ItemProperty -Path $baseKey -Name 'Icon' -Value $icon -PropertyType String -Force | Out-Null }
  New-Item -Path ($baseKey + '\command') -Force | Out-Null
  New-ItemProperty -Path ($baseKey + '\command') -Name '(default)' -Value $command -PropertyType String -Force | Out-Null
}

# 1) Verify required files exist
Ensure-Path $InstallPath
$ps1 = Join-Path $InstallPath 'open-in-nvim.ps1'
$vbs = Join-Path $InstallPath 'open-in-nvim.vbs'
$config = Join-Path $InstallPath 'open-in-nvim.config.ps1'

foreach ($f in @($ps1, $vbs)) {
  if (-not (Test-Path -LiteralPath $f)) {
    throw "Required file missing: $f"
  }
}

# 2) Remove legacy keys (HKCU + HKLM common names)
$targets = @(
  'HKCU:\Software\Classes\*\shell\Open_in_Neovim',
  'HKCU:\Software\Classes\*\shell\Open_in_Neovim_nvr',
  'HKCU:\Software\Classes\*\shell\Open_in_Neovim_new_hidden',
  'HKCU:\Software\Classes\*\shell\Open_in_Neovim_Debug',
  'HKCU:\Software\Classes\*\shell\Open_in_Neovim_new',
  'HKCU:\Software\Classes\Directory\shell\Open_in_Neovim',
  'HKCU:\Software\Classes\Directory\shell\Open_in_Neovim_nvr',
  'HKCU:\Software\Classes\Directory\shell\Open_in_Neovim_new_hidden',
  'HKCU:\Software\Classes\Directory\shell\Open_in_Neovim_Debug',
  'HKCU:\Software\Classes\Directory\shell\Open_in_Neovim_new',
  'HKCU:\Software\Classes\Directory\Background\shell\Open_in_Neovim',
  'HKCU:\Software\Classes\Directory\Background\shell\Open_in_Neovim_nvr',
  'HKCU:\Software\Classes\Directory\Background\shell\Open_in_Neovim_new_hidden',
  'HKCU:\Software\Classes\Directory\Background\shell\Open_in_Neovim_Debug',
  'HKCU:\Software\Classes\Directory\Background\shell\Open_in_Neovim_new',

  'HKLM:\Software\Classes\*\shell\Open_in_Neovim',
  'HKLM:\Software\Classes\*\shell\Open_in_Neovim_nvr',
  'HKLM:\Software\Classes\*\shell\Open_in_Neovim_new_hidden',
  'HKLM:\Software\Classes\*\shell\Open_in_Neovim_Debug',
  'HKLM:\Software\Classes\*\shell\Open_in_Neovim_new',
  'HKLM:\Software\Classes\Directory\shell\Open_in_Neovim',
  'HKLM:\Software\Classes\Directory\shell\Open_in_Neovim_nvr',
  'HKLM:\Software\Classes\Directory\shell\Open_in_Neovim_new_hidden',
  'HKLM:\Software\Classes\Directory\shell\Open_in_Neovim_Debug',
  'HKLM:\Software\Classes\Directory\shell\Open_in_Neovim_new',
  'HKLM:\Software\Classes\Directory\Background\shell\Open_in_Neovim',
  'HKLM:\Software\Classes\Directory\Background\shell\Open_in_Neovim_nvr',
  'HKLM:\Software\Classes\Directory\Background\shell\Open_in_Neovim_new_hidden',
  'HKLM:\Software\Classes\Directory\Background\shell\Open_in_Neovim_Debug',
  'HKLM:\Software\Classes\Directory\Background\shell\Open_in_Neovim_new'
)

foreach ($k in $targets) { Remove-Key $k }

# 3) Create the single working entry under HKCU
$display = 'Open with Neovim (new instance)'
$icon = 'C:\Program Files\Neovim\bin\nvim.exe'
$wscript = (Get-Command -Name 'wscript.exe' -ErrorAction SilentlyContinue)?.Source
if (-not $wscript) { $wscript = 'wscript.exe' }
$cmdFile = $wscript + ' //nologo ' + '"' + (Join-Path $InstallPath 'open-in-nvim.vbs').Replace('"','""') + '"'

Set-Menu -baseKey 'HKCU:\Software\Classes\*\shell\Open_in_Neovim_new' -display $display -command ($cmdFile + ' "%1"') -icon $icon
Set-Menu -baseKey 'HKCU:\Software\Classes\Directory\shell\Open_in_Neovim_new' -display $display -command ($cmdFile + ' "%1"') -icon $icon
Set-Menu -baseKey 'HKCU:\Software\Classes\Directory\Background\shell\Open_in_Neovim_new' -display $display -command ($cmdFile + ' "%V"') -icon $icon

Write-Host 'Installed HKCU context menu entry: Open with Neovim (new instance)'
Write-Host 'Done.'
