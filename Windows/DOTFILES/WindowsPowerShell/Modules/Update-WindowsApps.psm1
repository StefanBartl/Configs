# Requires PowerShell 5.1 or newer; enables early detection of typos in variable
# and hashtable key names instead of silent null-value bugs
Set-StrictMode -Version Latest

# Central mapping of manager name to its corresponding upgrade-all scriptblock.
# Keeping this in one place avoids duplicating the same switch logic in
# multiple branches of the interactive menu below.
$script:UpdateActions = [ordered]@{
  winget = { winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements }
  choco  = { choco upgrade all -y }
  scoop  = { scoop update * }
}

# Mapping of manager name to the command that lists pending updates without
# applying them, used both for the listing step and for -ShowCommandsOnly.
$script:ListActions = [ordered]@{
  winget = { winget upgrade }
  choco  = { choco outdated }
  scoop  = { scoop status }
}

function Test-IsAdministrator {
  # Returns $true if the current PowerShell session runs with elevated
  # (administrator) privileges; choco in particular usually requires this
  [CmdletBinding()]
  param()

  $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal = [Security.Principal.WindowsPrincipal]::new($identity)
  return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Show-UpdateCommands {
  # Prints the manual, single-package and bulk update commands for every
  # detected manager; kept as its own function so it can be called directly
  # instead of recursively re-invoking the main function
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [hashtable]$DetectedManagers
  )

  Write-Host "=== Individual update commands ===" -ForegroundColor Cyan

  Write-Host "To update all packages of a manager:" -ForegroundColor Yellow
  if ($DetectedManagers['winget']) { Write-Host "  winget upgrade --all --include-unknown" }
  if ($DetectedManagers['choco']) { Write-Host "  choco upgrade all -y" }
  if ($DetectedManagers['scoop']) { Write-Host "  scoop update *" }

  Write-Host "`nTo update a single, specific package:" -ForegroundColor Yellow
  if ($DetectedManagers['winget']) { Write-Host "  winget upgrade <package-id>" }
  if ($DetectedManagers['choco']) { Write-Host "  choco upgrade <package-name>" }
  if ($DetectedManagers['scoop']) { Write-Host "  scoop update <package-name>" }
}

function Update-WindowsApps {
  <#
    .SYNOPSIS
        Detects installed Windows package managers and updates their packages.

    .DESCRIPTION
        Checks for the presence of winget, choco and scoop, lists pending
        updates for each detected manager, and offers an interactive menu to
        upgrade all packages of one, several, or all managers at once.
        Supports -WhatIf and -Confirm via ShouldProcess.

    .PARAMETER ShowCommandsOnly
        Skips the interactive menu and only prints the manual commands that
        could be used to perform the updates by hand.

    .EXAMPLE
        Update-WindowsApps
        Runs the interactive updater.

    .EXAMPLE
        Update-WindowsApps -ShowCommandsOnly
        Only lists the manual update commands without prompting or updating.

    .EXAMPLE
        Update-WindowsApps -WhatIf
        Shows which upgrade actions would run without actually executing them.
    #>
  [CmdletBinding(SupportsShouldProcess)]
  param(
    [switch]$ShowCommandsOnly
  )

  Write-Host "`n=== Windows Package Manager Updater ===" -ForegroundColor Cyan

  # Detect which of the supported managers are actually available on PATH
  $managers = @{}
  foreach ($name in $script:UpdateActions.Keys) {
    if (Get-Command $name -ErrorAction SilentlyContinue) {
      $managers[$name] = $true
    }
  }

  if ($managers.Count -eq 0) {
    Write-Warning "No supported package managers (winget, choco, scoop) were found."
    return
  }

  Write-Host "Detected package managers: $($managers.Keys -join ', ')" -ForegroundColor Gray

  # choco typically fails silently or with access-denied errors when the
  # session is not elevated, so warn early instead of letting it fail later
  if ($managers['choco'] -and -not (Test-IsAdministrator)) {
    Write-Warning "Chocolatey usually requires an elevated session; consider re-running this shell as administrator."
  }

  if ($ShowCommandsOnly) {
    Show-UpdateCommands -DetectedManagers $managers
    return
  }

  Write-Host "Checking for available updates...`n" -ForegroundColor Yellow

  # List pending updates per manager, wrapped in try/catch so a single
  # failing manager does not abort the listing of the remaining ones
  foreach ($name in $managers.Keys) {
    Write-Host "--- [ $name updates ] ---" -ForegroundColor Green
    try {
      & $script:ListActions[$name]
    }
    catch {
      Write-Warning "Failed to list updates for '$name': $($_.Exception.Message)"
    }
    Write-Host ""
  }

  # Build the interactive menu; numeric options map to individual managers
  Write-Host "--------------------------------------------------" -ForegroundColor DarkGray
  Write-Host "Update options:" -ForegroundColor Cyan
  Write-Host "  [A] Update all detected package managers at once"

  $index = 1
  $numericOptions = @{}
  foreach ($name in $managers.Keys) {
    Write-Host "  [$index] Update only $name"
    $numericOptions["$index"] = $name
    $index++
  }
  Write-Host "  [C] Show manual commands only, without updating"
  Write-Host "  [Q] Cancel"
  Write-Host "--------------------------------------------------" -ForegroundColor DarkGray

  # Loop the prompt until a valid selection is made instead of aborting
  # immediately on the first invalid input
  $targets = $null
  do {
    $selection = Read-Host "Please choose an option"

    switch ($selection.ToUpper()) {
      'A' { $targets = $managers.Keys }
      'C' { Show-UpdateCommands -DetectedManagers $managers; return }
      'Q' { Write-Host "Cancelled." -ForegroundColor Gray; return }
      default {
        if ($numericOptions.ContainsKey($selection)) {
          $targets = @($numericOptions[$selection])
        }
        else {
          Write-Warning "Invalid selection, please try again."
        }
      }
    }
  } while (-not $targets)

  # Execute the upgrade for every selected target, respecting -WhatIf/-Confirm
  foreach ($target in $targets) {
    if ($PSCmdlet.ShouldProcess($target, 'Upgrade all packages')) {
      Write-Host "`nStarting update for $target..." -ForegroundColor Yellow
      try {
        & $script:UpdateActions[$target]
      }
      catch {
        Write-Warning "Update for '$target' failed: $($_.Exception.Message)"
      }
    }
  }
}

# Only the public entry point is exposed to callers of this module;
# helper functions and the action tables stay private to the module scope
Export-ModuleMember -Function Update-WindowsApps