# $PROFILE

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
