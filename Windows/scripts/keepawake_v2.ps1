$code = @'
using System;
using System.Runtime.InteropServices;

public static class SleepUtil
{
    [DllImport("kernel32.dll")]
    public static extern uint SetThreadExecutionState(uint esFlags);
}
'@

Add-Type -TypeDefinition $code -ErrorAction SilentlyContinue

$ES_CONTINUOUS      = [uint32]2147483648
$ES_SYSTEM_REQUIRED = [uint32]1

[SleepUtil]::SetThreadExecutionState(
    $ES_CONTINUOUS -bor $ES_SYSTEM_REQUIRED
) | Out-Null

Write-Host "Laptop bleibt wach. Fenster offen lassen. STRG+C zum Beenden."

try {
    while ($true) {
        Start-Sleep 3600
    }
}
finally {
    [SleepUtil]::SetThreadExecutionState($ES_CONTINUOUS) | Out-Null
}
