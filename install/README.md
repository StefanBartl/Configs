# Installation

Ein Manifest, zwei Installer. Beide lesen dieselbe Datei
[`links.conf`](links.conf) und legen daraus Verknüpfungen ins Home-Verzeichnis —
die Dateien selbst bleiben im Repo.

| Datei | Zweck |
|---|---|
| [`links.conf`](links.conf) | gemeinsames Manifest: Komponenten + Verknüpfungen (Quelle der Wahrheit) |
| [`install.sh`](install.sh) | Linux / macOS / WSL |
| [`install.ps1`](install.ps1) | Windows (PowerShell 5.1 und 7) |
| [`wezterm-entry.lua`](wezterm-entry.lua) | Entry-Loader für WezTerm, siehe [terminals/wezterm/docs/EntryPoint.md](../terminals/wezterm/docs/EntryPoint.md) |

> **Was der Installer nicht tut:** Programme installieren. Wählst du `kitty`,
> wird `kitty.conf` verlinkt — kitty selbst bringt dein Paketmanager. Fehlt das
> Programm im PATH, weist der Installer darauf hin und verlinkt trotzdem.

## Voraussetzung

`$REPOS_DIR` bzw. `$env:REPOS_DIR` zeigt auf das Verzeichnis, das dieses Repo
enthält (z. B. `/mnt/e/repos` oder `E:\repos`). Die Installer selbst brauchen
die Variable nicht — sie arbeiten relativ zu ihrem eigenen Pfad —, aber der
WezTerm-Loader und Teile von `my-zsh` schon.

## Auf einer frischen Maschine

```bash
git clone https://github.com/StefanBartl/Configs.git "$REPOS_DIR/Configs"
```

```bash
cd "$REPOS_DIR/Configs" && ./install/install.sh
```

Ohne Argumente fragt der Installer, welche Komponenten er einrichten soll:

```
Verfuegbare Komponenten (Plattform: unix)

   1) zsh        my-zsh als Submodul (shells/zsh) plus ~/.zshrc
   2) bash       .bashrc und .bash_aliases
   3) starship   Prompt-Konfiguration, von zsh UND pwsh geteilt
   4) wezterm    Entry-Loader nach ~/.config/wezterm/wezterm.lua
   5) kitty      kitty.conf (kitty nicht im PATH)
   6) tmux       tmux.conf (tmux nicht im PATH)
   7) lazygit    lazygit config.yml
   8) glow       glow glow.yml

Auswahl (Nummern oder Namen, Leer = alle, q = abbrechen):
```

Nummern und Namen sind mischbar, getrennt durch Leerzeichen oder Kommas.
Die Liste zeigt nur, was auf der aktuellen Plattform überhaupt etwas tut —
`pwsh` taucht unter Linux gar nicht erst auf.

## Alle Aufrufarten

| | Linux / macOS / WSL | Windows |
|---|---|---|
| interaktiv auswählen | `./install/install.sh` | `pwsh -File .\install\install.ps1` |
| Komponenten anzeigen | `./install/install.sh --list` | `... -List` |
| alles ohne Rückfrage | `./install/install.sh --all` | `... -All` |
| nur bestimmte | `./install/install.sh --only wezterm,zsh` | `... -Only wezterm,pwsh` |
| bestimmte auslassen | `./install/install.sh --skip glow` | `... -Skip glow` |
| Trockenlauf | `./install/install.sh --dry-run` | `... -DryRun` |
| Vorhandenes ersetzen | `./install/install.sh --force` | `... -Force` |

Ohne interaktive Konsole (Pipe, CI, Provisioning-Skript) wird nicht gefragt,
sondern alles ausgewählt — der Installer blockiert also nie auf eine Eingabe.

Existiert am Ziel bereits eine **echte** Datei (kein Symlink), wird sie
übersprungen. Mit `--force` / `-Force` wird sie nach
`<ziel>.bak-<zeitstempel>` verschoben und dann verlinkt. Bestehende Symlinks
werden immer ersetzt, ohne Rückfrage.

Das `my-zsh`-Submodul unter `shells/zsh` wird nur initialisiert, wenn die
Komponente `zsh` gewählt ist.

## Verknüpfungsarten

Unix legt für alles Symlinks an (`ln -sfn`).

Windows unterscheidet, damit der Lauf **ohne Administratorrechte und ohne
Entwicklermodus** durchgeht:

| Eintrag | Strategie |
|---|---|
| `dir` | Junction (`mklink /J`) — braucht nie erhöhte Rechte |
| `link` | Symlink → Fallback Hardlink → Fallback Kopie |

Nur der letzte Fallback ist verlustbehaftet: eine Kopie folgt späteren
Repo-Änderungen nicht mehr und wird deshalb als `KOPIE` gewarnt. Er greift in
der Praxis nur, wenn Ziel und Repo auf verschiedenen Laufwerken liegen und
Symlinks nicht erlaubt sind.

## Manifest erweitern

`links.conf` kennt zwei Zeilentypen, unterschieden am ersten Feld.

**Komponente anmelden** — nur nötig für einen neuen Namen:

```
component  <name>  <cmd|->  <beschreibung ...>
```

`cmd` ist das Programm, das diese Komponente konfiguriert (`-` wenn keines);
fehlt es im PATH, gibt der Installer einen Hinweis aus. Die Beschreibung läuft
bis Zeilenende und erscheint im Auswahlmenü.

**Verknüpfung eintragen:**

```
<platform>  <component>  <kind>  <source>  <target>
```

* `platform` — `unix`, `windows` oder `all`
* `component` — Name aus der Registry
* `kind` — `link` (Datei) oder `dir` (Verzeichnis)
* `source` — Pfad relativ zur Repo-Wurzel
* `target` — Zielpfad mit Tokens

Tokens: unter Unix `$HOME` und `$XDG_CONFIG` (= `${XDG_CONFIG_HOME:-$HOME/.config}`),
unter Windows `$HOME` (`%USERPROFILE%`), `$APPDATA`, `$PS5` und `$PS7`
(Dokumente\WindowsPowerShell bzw. Dokumente\PowerShell).

Pfade dürfen keine Leerzeichen enthalten — die Aufteilung erfolgt an
Whitespace. Fehlt eine Quelle, wird die Zeile mit Warnung übersprungen; das
Manifest darf also Einträge für Tools enthalten, die nicht auf jeder Maschine
im Repo liegen.
