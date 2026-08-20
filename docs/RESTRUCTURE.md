# Restrukturierung `Configs` — Analyse & Plan

> **Status:** Analyse abgeschlossen, Umsetzung offen
> **Stand:** 2026-08-20
> **Ausgangsfrage:** Eigenes Repo für pwsh/wezterm (analog `my-zsh`), oder alles
> in ein Repo zusammenführen?

---

## 0. Vorrangig: Exponierte Zugangsdaten

`StefanBartl/Configs` ist **public** und enthält getrackte Zugangsdaten.
Erstmals eingecheckt mit Commit `b92cb6e`, seither durchgehend in `main`.

Betroffen sind:

- `env/` — API-Key-Datei
- `VPN/ProtonVPN/WireGuard/` — 4 Configs mit privatem Schlüsselmaterial
- `VPN/ProtonVPN/` — 7 OpenVPN-Profile
- `VPN/RemotePlay/` — Screenshot mit Schlüsselmaterial
- `docker-cred/` — GPG-**Public**-Keyring-Listing, kein privates Material (geringe Schwere)
- `Settings_Profiles/` — Bookmark-Export und Softwareinventar (Privacy, nicht sicherheitskritisch)

### Reihenfolge ist nicht verhandelbar

Ein History-Rewrite macht bereits abgegriffene Schlüssel **nicht** ungültig.
Public-GitHub wird von Scrapern erfasst, üblicherweise binnen Minuten.

1. API-Key revoken
2. ProtonVPN: WireGuard-Configs neu generieren, alte Peers entfernen
3. **Erst dann** History-Purge + Force-Push

`my-zsh` löst das bereits korrekt: `secrets.zsh` lädt zur Laufzeit aus
`~/personel_env/` — außerhalb des Repos. Dieses Muster ist die Zielvorgabe
für alle Plattformen.

---

## 1. Ist-Zustand

|  | `Configs` | `my-zsh` |
|---|---|---|
| Sichtbarkeit | public | public |
| Getrackte Dateien | 115 | ~25 + 5 Submodule |
| **Pack-Größe** | **89,7 MB** | klein |
| Commits | 71 | 32 |
| Secret-Handling | im Repo committet | extern (`~/personel_env/`) |
| Install | `install-DOTFILES.ps1` (nur pwsh) | `ln -sf`, in `INSTRUCTIONS.md` dokumentiert |
| Fremdcode | vendored | Submodule |

### Herkunft der 89,7 MB

```
 25.72 MB  Fonts/OpenDyslexic.zip
 23.94 MB  Fonts/Noto_Color_Emoji.zip
 23.62 MB  Fonts/IBM_Plex_Mono,Inter,Source_Code_Pro.zip   <- nicht mehr in HEAD
 18.93 MB  Windows/tools/marksman.exe                       <- nicht mehr in HEAD
 15.40 MB  Fonts/Monoid.zip
  5.36 MB  Fonts/JetBrainsMono-2.304.zip
  2.79 MB  Fonts/NerdFontsSymbolsOnly.zip
  1.53 MB  CLITools/TCPView.zip
```

Rund 113 MB der History sind heruntergeladene Fonts und eine Binary. Zwei der
größten Objekte sind aus `HEAD` bereits gelöscht, liegen aber weiterhin in der
History. **115 Textdateien in einem 90-MB-Repo** ist das eigentliche Symptom.

### Strukturbefund

`my-zsh` ist ein Framework: klare Modulgrenzen (`init.zsh`, `paths.zsh`,
`integrations.zsh`, `fishify.zsh`), Fremdcode als Submodul, Secrets außerhalb,
dokumentierter Install.

`Configs` ist kein Dotfiles-Repo, sondern ein Sammelarchiv für alles rund um
die eigenen Maschinen: Dotfiles *und* Font-Downloads *und* VPN-Profile *und*
iCue-Tastaturprofile *und* Browser-Bookmarks *und* eine vollständige
C#-Anwendung (`Windows/Contextmenu/OpenInNvim`, mit eigener `.csproj`,
`README.md`, `docs/ROADMAP.md`, Deploy-Skripten).

Das Problem ist nicht die *Anzahl* der Repos, sondern dass hier vier Dinge mit
grundverschiedenem Lebenszyklus im selben Repo liegen.

---

## 2. Nach welcher Naht schneiden?

### Verworfen: Naht "pro Tool"

Symmetrisch zu `my-zsh`, bricht aber an einem harten Fakt:

```
Linux/macOS installiert:   zsh + wezterm + starship + tmux + fonts
Windows installiert:       pwsh + wezterm + starship + fonts
                                  ^^^^^^^^^^^^^^^^^^^^^^^^^^
                                  in BEIDEN Sets
```

`Terminals/wezterm/config/wsl/`, `Terminals/wezterm/config/powershell.lua` und
`Shells/starship/starship.toml` werden von beiden Plattformen genutzt.
`Windows/DOTFILES/ROADMAP.md` #2–#4 beschreibt Starship-Tuning — dieselbe
`starship.toml`, die auch zsh lädt.

Ein separates `my-pwsh` müsste starship und wezterm **duplizieren** oder per
Submodul einbinden. Beides schlechter als der Status quo. Diese Naht verläuft
quer zur tatsächlichen Abhängigkeitsstruktur.

### Verworfen: Naht "alles in eins"

Zieht `my-zsh` — klein, sauber, mit eigenen Submodulen — in ein 90-MB-Repo mit
Windows-Fonts, VPN-Profilen und einer C#-App. Auf einer Linux-Maschine würden
90 MB geklont, um an eine `.zshrc` zu kommen. Verschachtelte Submodule
(my-zsh-Plugins innerhalb eines Monorepos) sind zusätzlich unangenehm zu warten.

Merge ist die richtige Richtung — aber nicht in diesen Zustand hinein.

### Gewählt: Naht nach Lebenszyklus

| Layer | Inhalt | Deployment | Ziel |
|---|---|---|---|
| **A — Dotfiles** | zsh, pwsh, wezterm, kitty, tmux, starship, bash, CLI-Tools | Symlink / Loader | 1 Repo, public, klein |
| **B — Assets & Backups** | Fonts, VPN, iCue, Audio, Bookmarks, Software-Listen, Gaomon | wird nie verlinkt | privates Repo — oder gar nicht in Git |
| **C — Eigenständige Projekte** | `OpenInNvim` (C#-App) | eigenes Build/Deploy | eigenes Repo |
| **D — Secrets** | API-Keys, VPN-Schlüssel | Runtime-Load | nie in Git (`my-zsh`-Muster) |

Layer A ist exakt die Menge, die gemeinsam installiert wird und sich
gegenseitig referenziert. Das ist die tragfähige Naht.

---

## 3. Zielstruktur

```
dotfiles/                  (public, wenige MB — heutiges Configs, entkernt)
├── shells/
│   ├── zsh/               <- my-zsh als Submodul
│   ├── pwsh/              <- Windows/DOTFILES/WindowsPowerShell
│   └── bash/
├── terminals/
│   ├── wezterm/           <- Terminals/wezterm (inhaltlich unverändert)
│   ├── kitty/
│   └── tmux/
├── prompt/
│   └── starship.toml      <- von zsh UND pwsh geteilt
├── cli/                   <- lazygit, glow
└── install/
    ├── install.ps1        <- heutiges install-DOTFILES.ps1
    └── install.sh         <- my-zsh INSTRUCTIONS.md, als Skript

machine-assets/            (PRIVAT — Fonts, VPN, iCue, Bookmarks, Audio)
open-in-nvim/              (eigenes Repo — die C#-Anwendung)
```

### Begründung

- Ein `$REPOS_DIR/dotfiles` pro Maschine, ein Install-Skript je Plattform
- `starship.toml` und wezterm-Config haben **einen** Ort, keine Duplikate
- Klein genug für jede frische VM
- Public unbedenklich, weil Layer B und D ausgelagert sind
- Layer B darf versioniert sein — nur eben nicht öffentlich

### `my-zsh`: absorbieren oder Submodul?

|  | Absorbieren | Submodul |
|---|---|---|
| History | verloren (außer via `subtree merge`) | bleibt erhalten |
| Standalone installierbar | nein | ja |
| Wartung | ein Commit ändert alles | Pointer-Commits, Submodul-in-Submodul |

**Entscheidung: Submodul.** `my-zsh` hat mit `INSTRUCTIONS.md`,
`DISCLAIMER.md`, `UNLICENSED` und eigener `ROADMAP.md` bereits eine
eigenständige Identität und bleibt so auf Maschinen installierbar, auf denen
nur zsh gebraucht wird.

---

## 4. Bekannte Bruchstellen

Drei Stellen kodieren Repo-Pfade hart und müssen bei einem Umbau mitgezogen
werden — begrenzt und bekannt:

1. `~/.config/wezterm/wezterm.lua`
   `candidates = { join(REPOS_DIR, "Configs", "Terminals", "wezterm") }`
   Bereits als Liste gebaut — Einzeiler.
2. `Windows/DOTFILES/install-DOTFILES.ps1`
   `$repoDotfilesDir = Join-Path $env:REPOS_DIR "Configs\Windows\DOTFILES\WindowsPowerShell"`
3. `my-zsh/INSTRUCTIONS.md` — Pfadangaben in der Anleitung

Zusätzlich: `Windows/DOTFILES/OLD_Powershell/` ist toter Ballast (alte
Profilstände, redundant zur Git-History) und entfällt beim Umbau ersatzlos.

---

## 5. Umsetzungsreihenfolge

| # | Schritt | Voraussetzung |
|---|---|---|
| 1 | **Zugangsdaten rotieren** (API-Key, WireGuard) | — |
| 2 | Layer B in privates Repo, Layer C in eigenes Repo auslagern | 1 |
| 3 | History-Purge (`git filter-repo`): Zugangsdaten + Fonts + `marksman.exe` + Force-Push | 2 |
| 4 | Umbau auf Zielstruktur, `my-zsh` als Submodul einhängen | 3 |
| 5 | `install.sh` + `install.ps1` vereinheitlichen | 4 |
| 6 | Offene Punkte aus `Windows/DOTFILES/ROADMAP.md`: #8 hardcodierte Pfade, #13 Admin-freier Symlink-Fallback, #20 `Test-ProfileHealth` | 5 |

Schritt 3 reduziert das Repo von 89,7 MB auf wenige MB.
Schritt 1 ist von allem anderen unabhängig und sollte sofort erfolgen.

---

## 6. Nachgelagert

Übertragung der Checklisten- und Gate-Systematik aus
`WKDBooks/Development/wkdbook-Lua/Checklists` (`KONZEPT.md`, `WORKFLOW.md`,
`regeln/`, `gates/`, `belege/`) auf die hiesigen Repos. Nicht Lua-spezifisch,
greift aber sinnvoll erst auf einer aufgeräumten Struktur — also nach Schritt 5.
