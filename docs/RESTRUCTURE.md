# Restrukturierung `Configs` — Analyse & Plan

> **Status:** Analyse abgeschlossen, Umsetzung offen
> **Stand:** 2026-08-20
> **Ausgangsfrage:** Eigenes Repo für pwsh/wezterm (analog `my-zsh`), oder alles
> in ein Repo zusammenführen?

---

## 0. Erledigt: Exponierte Zugangsdaten (2026-08-20)

`StefanBartl/Configs` war **public** und enthielt getrackte Zugangsdaten.
Erstmals eingecheckt mit Commit `b92cb6e`, seither durchgehend in `main`.

Betroffen waren:

- `env/` — API-Key-Datei
- `VPN/ProtonVPN/WireGuard/` — 4 Configs mit privatem Schlüsselmaterial
- `VPN/ProtonVPN/` — 7 OpenVPN-Profile
- `VPN/RemotePlay/` — Screenshot mit Schlüsselmaterial
- `docker-cred/` — GPG-**Public**-Keyring-Listing, kein privates Material (geringe Schwere, unverändert im Repo)
- `Settings_Profiles/` — Bookmark-Export und Softwareinventar (Privacy, nicht sicherheitskritisch, unverändert im Repo)

### Durchgeführt, in dieser Reihenfolge

1. ✅ API-Key nur noch als lokale Umgebungsvariable geführt, nicht mehr im Repo
2. ✅ ProtonVPN/WireGuard: alte Konfigurationen ungültig, keine aktiven Peers mehr
3. ✅ History-Purge (`git filter-repo`) + Force-Push auf `main` und `main-unix`

Die betroffenen Dateien sind vollständig aus der Git-History entfernt (verifiziert
per Blob-Scan über alle Objekte, alle Refs). `.gitignore` verhindert versehentliches
erneutes Einchecken. `docker-cred/` und `Settings_Profiles/` blieben unangetastet —
kein privates Schlüsselmaterial bzw. nur Privacy-relevant, nicht sicherheitskritisch.

`my-zsh` löst Secret-Handling bereits korrekt: `secrets.zsh` lädt zur Laufzeit aus
`~/personel_env/` — außerhalb des Repos. Dieses Muster ist die Zielvorgabe
für alle Plattformen.

---

## 1. Ist-Zustand (Stand vor Schritt 1–3, siehe Historie unten für den aktuellen Stand)

|  | `Configs` | `my-zsh` |
|---|---|---|
| Sichtbarkeit | public | public |
| Getrackte Dateien | 115 | ~25 + 5 Submodule |
| **Pack-Größe** | **89,7 MB** → **2,0 MB** nach Schritt 3 (2026-08-20) | klein |
| Commits | 71 | 32 |
| Secret-Handling | im Repo committet | extern (`~/personel_env/`) |
| Install | `install-DOTFILES.ps1` (nur pwsh) | `ln -sf`, in `INSTRUCTIONS.md` dokumentiert |
| Fremdcode | vendored | Submodule |

### Herkunft der 89,7 MB (historisch — per Schritt 3 vollständig gepurgt)

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

| Layer | Inhalt | Deployment | Ziel | Status |
|---|---|---|---|---|
| **A — Dotfiles** | zsh, pwsh, wezterm, kitty, tmux, starship, bash, CLI-Tools | Symlink / Loader | 1 Repo, public, klein | bleibt in `Configs`, Umbau offen (Abschnitt 3–4) |
| **B — Assets & Backups** | Fonts, VPN, iCue, Audio, Bookmarks, Software-Listen, Gaomon | wird nie verlinkt | privates Repo | ✅ migriert nach [`StefanBartl/machine-assets`](https://github.com/StefanBartl/machine-assets) (privat), 2026-08-20 |
| **C — Eigenständige Projekte** | `OpenInNvim` (C#-App) | eigenes Build/Deploy | eigenes Repo | ✅ migriert nach [`StefanBartl/open-in-nvim`](https://github.com/StefanBartl/open-in-nvim) (public), 2026-08-20 |
| **D — Secrets** | API-Keys, VPN-Schlüssel | Runtime-Load | nie in Git (`my-zsh`-Muster) | ✅ erledigt, siehe Abschnitt 0 |

Layer A ist exakt die Menge, die gemeinsam installiert wird und sich
gegenseitig referenziert. Das ist die tragfähige Naht.

### Migration Layer B/C — Details (2026-08-20)

Beide neuen Repos wurden mit **frischer History** angelegt (ein Initial-Commit),
nicht per `git filter-repo`-Subtree-Split — so bewusst entschieden, weil die
alte `Configs`-History für diese Pfade ohnehin nur die (inzwischen entfernten)
Secrets und unnötigen Ballast mitgeschleppt hätte.

Bei der Migration von `Windows/Contextmenu/OpenInNvim/` fiel auf: `bin/`, `obj/`
und `publish/*.exe` (zwei self-contained .NET-Singlefile-Exes, ~66 MB je Datei,
zusammen ~214 MB) lagen zwar im Arbeitsverzeichnis, waren aber **nie
Git-getrackt** (`git ls-files` liefert dafür nichts) — reiner lokaler
Build-Output ohne Auswirkung auf die Repo-Größe. `open-in-nvim` hat jetzt ein
`.gitignore` dafür, damit das so bleibt.

`Configs` selbst wurde per `git rm` von `Fonts/`, `VPN/`, `Settings_Profiles/`,
`docker-cred/` und `Windows/Contextmenu/OpenInNvim/` bereinigt. Die alten Inhalte
bleiben bis Schritt 3 (History-Purge) in der `Configs`-Git-History erhalten —
das ist der noch offene Schritt, der die Repo-Größe tatsächlich reduziert.

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

### Tatsächlich umgesetzt (Schritt 4, 2026-08-20)

Die Skizze oben deckte nicht alle 115 damals getrackten Dateien ab. Reale
Struktur nach dem Umbau, inklusive der drei zusätzlichen Layer-A-Ordner für
Inhalte ohne offensichtlichen Platz in der Skizze:

```
Configs/
├── shells/{pwsh,bash,zsh(Submodul)}/
├── terminals/{wezterm,kitty,tmux,windows-terminal}/
├── prompt/starship.toml
├── cli/{lazygit,glow,TCPView.zip,List.md}
├── install/install.ps1               (install.sh folgt in Schritt 5)
├── containers/podman/nvim            (Podman-Containerfile)
├── scripts/                          (keepawake*.ps1, install-tools-win.ps1, pdf_zu_bilder.py)
├── editors/{vscodevim,vsvim}/
└── docs/{ROADMAP.md,RESTRUCTURE.md}
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

Drei Stellen kodierten Repo-Pfade hart:

1. `~/.config/wezterm/wezterm.lua` — `candidates = { join(REPOS_DIR, "Configs",
   "Terminals", "wezterm") }` auf jeder Maschine, auf der wezterm bereits
   deployed ist. **Nicht Teil dieses Repos**, daher von Schritt 4 nicht
   automatisch mitgezogen — muss pro Maschine manuell auf
   `"Configs", "terminals", "wezterm"` angepasst werden, bevor wezterm dort
   wieder eine Config findet.
2. ~~`Windows/DOTFILES/install-DOTFILES.ps1`~~ → jetzt `install/install.ps1`,
   Pfad im Skript selbst auf `Configs\shells\pwsh` mitgefixt (Schritt 4).
3. `my-zsh/INSTRUCTIONS.md` — Pfadangaben in der Anleitung. Liegt im
   `my-zsh`-Repo selbst, nicht in `Configs`; unverändert, da `my-zsh` jetzt als
   Submodul unter `shells/zsh/` hängt und seine eigene Anleitung weiterhin für
   den Standalone-Einsatz gilt.

Zusätzlich: `Windows/DOTFILES/OLD_Powershell/` war toter Ballast (alte
Profilstände, redundant zur Git-History) — in Schritt 4 ersatzlos entfernt.

### Umbau durchgeführt (Schritt 4, 2026-08-20)

Vollständige Übernahme der Zielstruktur aus Abschnitt 3: `shells/{pwsh,bash,zsh}`,
`terminals/{wezterm,kitty,tmux,windows-terminal}`, `prompt/starship.toml`,
`cli/{lazygit,glow,TCPView.zip,List.md}`, `install/install.ps1`, plus drei
zusätzliche, in der Zielskizze nicht explizit genannte Ordner für Inhalte ohne
festen Platz in Layer A: `containers/podman/` (Podman-Containerfile),
`scripts/` (keepawake, install-tools-win, pdf_zu_bilder.py), `editors/`
(vscodevim, vsvim). `my-zsh` als Submodul unter `shells/zsh/` eingehängt.
`Windows/DOTFILES/ROADMAP.md` (pwsh-spezifisch, #2–#20) ist mit nach
`shells/pwsh/ROADMAP.md` gewandert, analog zu `my-zsh`s eigener `ROADMAP.md`.

**Windows-Stolperstein:** `git mv Terminals/wezterm terminals/wezterm` schlägt
auf NTFS (case-insensitive) mit `Invalid argument` fehl, weil Quelle und Ziel
sich nur in der Groß-/Kleinschreibung eines Vorfahren-Pfadsegments
unterscheiden und die Datei-Engine das als Rename auf sich selbst wertet.
Workaround: zweistufig über einen Zwischennamen —
`git mv Terminals/wezterm Terminals/wezterm_tmp && git mv Terminals/wezterm_tmp terminals/wezterm`.

---

## 5. Umsetzungsreihenfolge

| # | Schritt | Voraussetzung |
|---|---|---|
| 1 | ~~Zugangsdaten rotieren (API-Key, WireGuard) + History-Purge~~ ✅ erledigt 2026-08-20 (Abschnitt 0) | — |
| 2 | ~~Layer B in privates Repo, Layer C in eigenes Repo auslagern~~ ✅ erledigt 2026-08-20 (Abschnitt 2, Migration-Details) | — |
| 3 | ~~History-Purge (`git filter-repo`): Fonts + `marksman.exe` + Layer-B/C-Pfade + Force-Push~~ ✅ erledigt 2026-08-20 — `.git` 90 MB → 2,0 MB (lokal + `origin/main` + `origin/main-unix`) | 2 |
| 4 | ~~Umbau auf Zielstruktur, `my-zsh` als Submodul einhängen~~ ✅ erledigt 2026-08-20, siehe "Umbau durchgeführt" oben | 3 |
| 5 | `install.sh` + `install.ps1` vereinheitlichen (inkl. Fix für `~/.config/wezterm/wezterm.lua` auf betroffenen Maschinen) | 4 |
| 6 | Offene Punkte aus `Windows/DOTFILES/ROADMAP.md`: #8 hardcodierte Pfade, #13 Admin-freier Symlink-Fallback, #20 `Test-ProfileHealth` | 5 |

Schritt 3 reduziert das Repo zusätzlich von 89,7 MB auf wenige MB (Fonts/Binary,
unabhängig von den bereits gepurgten Zugangsdaten).

---

## 6. Nachgelagert

Übertragung der Checklisten- und Gate-Systematik aus
`WKDBooks/Development/wkdbook-Lua/Checklists` (`KONZEPT.md`, `WORKFLOW.md`,
`regeln/`, `gates/`, `belege/`) auf die hiesigen Repos. Nicht Lua-spezifisch,
greift aber sinnvoll erst auf einer aufgeräumten Struktur — also nach Schritt 5.
