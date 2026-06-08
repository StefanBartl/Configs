$wscript = New-Object -ComObject Wscript.Shell
Write-Host "Wachhalte-Skript aktiv. Drücke STRG+C im Terminal, um es zu beenden..." -ForegroundColor Green

while ($true) {
    # Sendet alle 60 Sekunden den virtuellen Tastendruck für 'ScrollLock'
    $wscript.SendKeys("{SCROLLLOCK}")
    Start-Sleep -Seconds 60

    # Optional: Ein kleiner Punkt im Terminal, damit du siehst, dass es noch läuft
    Write-Host "." -NoNewline
}
