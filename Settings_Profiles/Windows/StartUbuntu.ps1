# Dieses Skript startet das WSL Ubuntu und wechselt in ein Verzeichnis
# -d ubuntu wählt die Ubuntu-Distribution aus.
# -e bash startet die Bash-Shell.
# -c "cd ~/Development && exec bash" wechselt in das Verzeichnis und führt die Bash-Shell aus.

# Definieren Sie die Optionen und zeigen Sie sie an
$options = @(
    "~",
    "nvim",
    "Development",
    "LinuxFiles",
    "Kurse",
    "FrontendMasters"
)

# Zeigen Sie die Optionen an und lassen Sie den Benutzer auswählen
for ($i = 0; $i -lt $options.Length; $i++) {
    Write-Host "$($i+1): $($options[$i])"
}

$choice = Read-Host "`nWohin willst du? (1-6)"

# Führen Sie den entsprechenden Befehl basierend auf der Auswahl aus
switch ($choice) {
    "1" { wsl -d ubuntu -e bash -c "cd ~ && exec bash" }
    "2" { wsl -d ubuntu -e bash -c "cd ~/.config/nvim && exec bash" }
    "3" { wsl -d ubuntu -e bash -c "cd ~/Development && exec bash" }
    "4" { wsl -d ubuntu -e bash -c "cd ~/Development/LinuxFiles && exec bash" }
    "5" { wsl -d ubuntu -e bash -c "cd ~/Development/BauhausCoder/Kurse && exec bash" }
    "6" { wsl -d ubuntu -e bash -c "cd ~/Development/BauhausCoder/Kurse/Web-Development/FrontendMasters && exec bash" }
    default { Write-Host "Ungültige Auswahl." }
}

