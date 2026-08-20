# Configs

Konfigurationsdateien für meine Maschinen — Shells, Terminals, Prompt, CLI-Tools —
plus die zwei Installer, die sie auf einer neuen Maschine verknüpfen.

Das Repo enthält ausschließlich **Layer A**: Konfiguration, die symlinkt und
gemeinsam installiert wird. Maschinen-Assets (Fonts, Profile, Bookmarks) liegen
in einem privaten Repo, eigenständige Programme in eigenen — die Begründung für
diesen Schnitt steht in [docs/RESTRUCTURE.md](./docs/RESTRUCTURE.md).

> **Kein Angebot zur Nachnutzung.** Siehe [UNLICENSED](./UNLICENSED) und
> [DISCLAIMER.md](./DISCLAIMER.md). Das hier ist persönliche Konfiguration,
> öffentlich, damit ich sie überall klonen kann — nicht mehr.

## Struktur

| Ordner | Inhalt |
| ------ | ------ |
| `install/` | Manifest `links.conf` + `install.sh` / `install.ps1` — [README](./install/README.md) |
| `shells/` | `bash/`, `pwsh/` (Profil, `MyCliHelpers`), `zsh/` → Submodul [my-zsh](https://github.com/StefanBartl/my-zsh) |
| `terminals/` | `wezterm/` (modular, `init.lua`), `kitty/`, `tmux/`, `windows-terminal/` |
| `prompt/` | `starship.toml` — von zsh **und** pwsh geteilt, deshalb eigener Ordner |
| `cli/` | `lazygit`, `glow` |
| `editors/` | vim-Emulation für VS Code und Visual Studio |
| `scripts/`, `containers/` | Einzelskripte, Podman-Containerfile |
| `docs/` | [RESTRUCTURE.md](./docs/RESTRUCTURE.md) (Umbauhistorie und Entscheidungen), [checklisten/](./docs/checklisten/) (Regeln und Gates) |

## Einrichten

```bash
git clone https://github.com/StefanBartl/Configs.git "$REPOS_DIR/Configs"
```

```bash
cd "$REPOS_DIR/Configs" && ./install/install.sh --dry-run
```

Ohne Argumente fragt der Installer, welche Komponenten er einrichten soll;
`--dry-run` zeigt vorher, was passieren würde. Windows analog mit
`install\install.ps1`. Alle Aufrufarten, die Verknüpfungssemantik und wie man
das Manifest erweitert: [install/README.md](./install/README.md).

Der Installer **verlinkt Konfiguration, er installiert keine Programme.**
Fehlt ein Tool im PATH, sagt er das und verlinkt trotzdem.

Schritt für Schritt inklusive Diagnose (`Test-ProfileHealth`) und Secrets:
[docs/checklisten/gates/NEW_MACHINE.md](./docs/checklisten/gates/NEW_MACHINE.md).

## Beitragen

Nein — siehe Disclaimer oben. Für mich selbst gelten vor jedem Merge und jedem
Push die Gates in [docs/checklisten/](./docs/checklisten/).
