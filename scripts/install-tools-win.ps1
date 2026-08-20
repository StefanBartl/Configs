# Install Linux and MacOS command-line tools
## Based off of the following list, https://medium.com/@pachoyan/suprising-list-of-linux-and-macos-command-line-tools-available-on-windows-29c20b2f4325
## I have personally installed all options to use in testing envrinoments and they typically work as advertised

## Comment the following if you have already install Winget and scoop

# Installing scoop
# More info, https://scoop.sh/
#Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
#Invoke-RestMethod -Uri https://get.scoop.sh | Invoke-Expression

# Installing winget
# More info, https://learn.microsoft.com/en-us/windows/package-manager/winget/
#$progressPreference = 'silentlyContinue'
#Write-Host "Installing WinGet PowerShell module from PSGallery..."
#Install-PackageProvider -Name NuGet -Force | Out-Null
#Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery | Out-Null
#Write-Host "Using Repair-WinGetPackageManager cmdlet to bootstrap WinGet..."
#Repair-WinGetPackageManager -AllUsers
#Write-Host "Done."

## Installation of the following:
# Kitware CMake (CMake)
# cURL (cURL)
# coreutils (with Scoop, includes GNU Core Utilities)
# make (with Scoop, GNU Make)
# grepWin (Stefan's Tools, a GUI grep utility for Windows)
# gawk (GNU Awk)
# sed (GNU Stream Editor)
# Microsoft OpenSSH Beta (OpenSSH client/server from Microsoft)
# gsudo (a sudo equivalent for Windows)
# GnuWin32 FindUtils (UNIX find utilities)
# Git (distributed version control)
# Jernej Simoncic Wget (Windows port of GNU Wget)
# GNU Wget2 (successor to GNU Wget)
# xz (compression tools)
# neofetch-win (Neofetch for Windows)
# base64 (command-line base64 encoder/decoder)
# pass-winmenu-nogpg (Windows port of the password manager "pass" without GPG dependency)
# pasteboard (clipboard utility)
# vim
# GNU Nano
# Neovim
# pyenv
# lazygit

## Install apps via winget ##

winget install -e --id Kitware.CMake
winget install -e --id cURL.cURL
winget install -e --id StefansTools.grepWin
winget install -e --id Microsoft.OpenSSH.Beta
winget install -e --id GnuWin32.FindUtils
winget install -e --id Git.Git
winget install -e --id JernejSimoncic.Wget
winget install -e --id GNU.Wget2
winget install -e --id nepnep.neofetch-win
winget install -e --id vim.vim
winget install -e --id GNU.Nano
winget install -e --id Neovim.Neovim
winget install -e --id JesseDuffield.lazygit

## Install Extras repo in scoop ##

scoop bucket add extras

## Install apps via scoop ##

scoop install main/coreutils
scoop install main/make
scoop install main/gawk
scoop install main/sed
scoop install main/gsudo
scoop install main/xz
scoop install main/base64
scoop install extras/pass-winmenu-nogpg
scoop install extras/pasteboard
scoop install main/pyenv

## Unused installs
# Uncomment if you'd like to use the following
# scoop install extras/jenv
# winget install -e --id Rustlang.Rustup
# scoop install main/redis
