# `WezTerm`-Custom `wsl`-Modul

Dieses Modul (`config.wsl`) steuert ein extrem mächtiges Feature von WezTerm: **Native Multiplexing- und Launch-Domains für WSL.**

Kurz gesagt: Es sorgt dafür, dass deine WSL-Distributionen direkt in das GUI von WezTerm integriert werden, anstatt dass WezTerm einfach nur ein Windows-Fenster öffnet, in dem ein `wsl.exe`-Prozess gestartet wird.

---

## Was bringt das genau? (Die Vorteile von `wsl_domains`)

Wenn du dieses Modul aktivierst, passiert Folgendes:

1. **Einträge im WezTerm-Launcher:** Wenn du in WezTerm das Launcher-Menü öffnest (standardmäßig mit `Ctrl+Shift+L` oder über das Plus-Symbol in der Tab-Leiste), tauchen dort saubere Einträge auf: `WSL:Ubuntu` und `WSL:Alpine`. Ein Klick darauf öffnet sofort einen neuen Tab direkt in dieser Distro.
2. **Echte native Linux-Umgebung (Kein Windows-Tunnel):**
WezTerm startet hier nicht `wsl.exe Ubuntu`, sondern kommuniziert direkt mit der WSL-Instanz. Das sorgt für eine bessere Performance bei der Textausgabe und verhindert oft Probleme mit Zeichensätzen, Shortcuts oder dem Rendern von CLI-Tools (wie Neovim).
3. **Direkter User- und Pfad-Login:**
Du landest ohne Umwege sofort im Home-Verzeichnis (`~`) deines Linux-Users (`weltschmerz`), ohne dass du erst Windows-Pfade durchqueren musst.

---

## Solltest du das für deine anderen Distros auch machen?

**Ja, absolut – aber selektiv!** Schauen wir uns deine `wsl --list` an:

* `Ubuntu (Standard)` -> **Ja.** (Hast du schon drin).
* `archlinux` -> **Ja, definitiv.** Wenn du Arch nutzt, willst du dafür einen schnellen, sauberen Einstiegspunkt haben.
* `docker-desktop` & `podman-machine-default` -> **Nein, eher nicht.**

### Warum nicht für Docker und Podman?

`docker-desktop` und `podman-machine-default` sind reine **Infrastruktur-Distros**. Sie enthalten kein vollwertiges Betriebssystem zum interaktiven Arbeiten, sondern nur die minimalen Runtimes, um die Container-Engines unter Windows laufen zu lassen. Wenn du einen Tab in `docker-desktop` öffnest, landest du in einer extrem abgespeckten Shell ohne deine gewohnten Tools (kein Zsh, kein Neovim, kein Git). Da willst du interaktiv im Terminal eigentlich nie direkt rein.

---

## So erweiterst du deine Config sinnvoll

Da du laut deiner Liste `archlinux` installiert hast, Alpine (`WSL:Alpine`) im Skript aber als Leiche drinsteht (das hast du laut `wsl --list` gar nicht installiert), solltest du das Skript aufräumen und Arch hinzufügen.

Hier ist die perfekt angepasste `config.wsl`:

```lua
---@module 'config.wsl'
---@brief WSL domain configuration for WezTerm to enable launch targets via the launcher.

require("@types.types")

---@param Config WezTerm.Config
---@return nil
return function(Config)
  --- Definiert die verfügbaren WSL-Distros für den WezTerm Launcher.
  Config.wsl_domains = {
    {
      name = "WSL:Ubuntu",
      distribution = "Ubuntu",
      username = "weltschmerz",
      default_cwd = "~",
      default_prog = { "bash", "-i", "-l" }, -- Startet standardmäßig die Bash (oder zsh, falls dort als Default-Shell gesetzt)
    },
    {
      name = "WSL:Arch",
      distribution = "archlinux",          -- MUSS exakt mit dem Namen aus `wsl --list` übereinstimmen
      username = "weltschmerz",            -- Falls dein User dort auch so heißt, ansonsten anpassen
      default_cwd = "~",
    },
  }
end

```

### Ein kleiner Tipp für die Zukunft:

Wenn du in deiner Arch- oder Ubuntu-Distro standardmäßig die `zsh` als Standard-Shell konfiguriert hast (z.B. via `chsh -s $(which zsh)` im Linux), kannst du das `default_prog` in der Config komplett weglassen (wie ich es oben bei Arch gemacht habe). WezTerm fragt dann die Distro automatisch nach der Default-Shell des Users und startet diese direkt.
