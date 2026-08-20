# WezTerm Entry Point

WezTerm sucht seine Konfiguration an einem festen Ort im Home-Verzeichnis, nicht
im Repo. Statt die Config dorthin zu kopieren, liegt dort nur ein kleiner
**Entry-Loader**, der die Repo-Config findet und an sie delegiert.

Der Loader ist genau eine Datei im Repo:

> [`install/wezterm-entry.lua`](../../../install/wezterm-entry.lua)

Er wird von den Installern als Symlink nach `~/.config/wezterm/wezterm.lua`
gelegt — unter Windows genauso wie unter Linux/macOS:

```bash
./install/install.sh
```

```bash
pwsh -File .\install\install.ps1
```

## Warum ein Symlink und kein kopiertes Snippet

Bis Schritt 4 der Restrukturierung stand der Repo-Pfad in jeder Maschine
einzeln in `~/.config/wezterm/wezterm.lua` — ein `Terminals/` → `terminals/`
kodierte sich damit in jede Installation ein und musste pro Maschine
nachgezogen werden. Als Symlink ins Repo wirkt eine Pfadänderung an *einer*
Stelle überall.

## Was der Loader tut

1. Repo-Wurzel bestimmen: `$REPOS_DIR`, sonst `~/repos`
2. Repo-Verzeichnis suchen: `<root>/{Configs,dotfiles}/terminals/wezterm`
   (der zweite Name ist der in `docs/RESTRUCTURE.md` skizzierte Zielname)
3. `package.path` um `<dir>/?.lua` und `<dir>/?/init.lua` erweitern, damit
   `require("config.fonts")` usw. auflösen
4. `<dir>/init.lua` per `dofile` laden — die Datei gibt eine Funktion
   `function(Config) -> Config` zurück
5. `wezterm.config_builder()` bauen, durch diese Funktion schicken, Ergebnis
   zurückgeben

Jeder Schritt ist in `pcall` gekapselt: schlägt etwas fehl, wird der Fehler in
den WezTerm-Log geschrieben und eine leere Config zurückgegeben — WezTerm
startet also weiterhin.

## Fehlersuche

Findet der Loader das Repo nicht, steht der Grund samt der durchsuchten
Wurzelverzeichnisse im WezTerm-Log:

```bash
wezterm --config-file /dev/null start -- true
```

Häufigste Ursache: `$REPOS_DIR` ist im GUI-Kontext nicht gesetzt (Login-Shell
vs. Desktop-Session). Dann greift der `~/repos`-Fallback — oder `REPOS_DIR`
muss in der Session-Umgebung gesetzt werden (`~/.zshenv`, `environment.d`,
Windows-Benutzervariablen).
