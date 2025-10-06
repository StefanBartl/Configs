# verify.ps1
# Quick test runner to ensure the chain VBS -> PS1 -> NVIM works.

param(
  [string]$Target = "$env:USERPROFILE\Desktop\openin-test.txt"
)

$ErrorActionPreference = 'Stop'
$Here = Split-Path -LiteralPath $PSCommandPath -Parent
$cscript = Join-Path $Here 'open-in-nvim.vbs'

if (-not (Test-Path -LiteralPath $cscript)) {
  throw "VBS not found: $cscript"
}

# This will open a new Neovim instance (depending on config).
wscript.exe //nologo "$cscript" "$Target"
Write-Host "Dispatched to VBS. If nothing opened, check NVIM_BIN in open-in-nvim.config.ps1"
