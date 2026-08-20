# Installation

Ein Manifest, zwei Installer. Beide lesen dieselbe Datei
[`links.conf`](links.conf) und legen daraus Verknüpfungen ins Home-Verzeichnis —
die Dateien selbst bleiben im Repo.

| Datei | Zweck |
|---|---|
| [`links.conf`](links.conf) | gemeinsames Link-Manifest (Quelle der Wahrheit) |
| [`install.sh`](install.sh) | Linux / macOS / WSL |
| [`install.ps1`](install.ps1) | Windows (PowerShell 5.1 und 7) |
| [`wezterm-entry.lua`](wezterm-entry.lua) | Entry-Loader für WezTerm, siehe [terminals/wezterm/docs/EntryPoint.md](../terminals/wezterm/docs/EntryPoint.md) |

## Voraussetzung

`$REPOS_DIR` bzw. `$env:REPOS_DIR` zeigt auf das Verzeichnis, das dieses Repo
enthält (z. B. `/mnt/e/repos` oder `E:\repos`). Die Installer selbst brauchen
die Variable nicht — sie arbeiten relativ zu ihrem eigenen Pfad —, aber der
WezTerm-Loader und Teile von `my-zsh` schon.

## Nutzung

```bash
./install/install.sh --dry-run
```

```bash
./install/install.sh
```

```bash
pwsh -File .\install\install.ps1 -DryRun
```

```bash
pwsh -File .\install\install.ps1
```

`--dry-run` / `-DryRun` zeigt nur an, was passieren würde.

Existiert am Ziel bereits eine **echte** Datei (kein Symlink), wird sie
übersprungen. Mit `--force` / `-Force` wird sie nach
`<ziel>.bak-<zeitstempel>` verschoben und dann verlinkt. Bestehende Symlinks
werden immer ersetzt, ohne Rückfrage.

Beide Installer initialisieren das `my-zsh`-Submodul unter `shells/zsh`, falls
es noch nicht ausgecheckt ist.

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

Eine Zeile pro Verknüpfung, Felder durch Whitespace getrennt:

```
<platform>  <kind>  <source>  <target>
```

* `platform` — `unix`, `windows` oder `all`
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
