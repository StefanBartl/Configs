# Regeln & Checklisten — Dotfiles

Übertragung der Systematik aus
`WKDBooks/Development/wkdbook-Lua/Checklists` auf dieses Repo.

**Was hier steht und was nicht.** Die dortige Sammlung ist die kanonische
Fassung für **Lua- und Neovim-Code**. Dieses Repo ist etwas anderes: Dotfiles,
zwei Installer, geteilte Konfiguration über zwei Betriebssysteme. Kopiert wird
deshalb nichts — der Grundsatz „jede Regel steht genau einmal" gilt über Repos
hinweg. Hier stehen nur die Regeln, die es dort nicht gibt, weil sie ein
Dotfiles-Repo betreffen.

Für den Lua-Anteil dieses Repos (`terminals/wezterm/**`) gilt die dortige
Sammlung, soweit die Regeln nicht Neovim-API-spezifisch sind:
`Checklists/regeln/PRINCIPLES.md` vollständig, `Checklists/regeln/LUA_NVIM.md`
in den Abschnitten Code-Stil, Annotationen, Fehlerbehandlung und Sicherheit.

---

## Aufbau

| Ordner | Frage | Wann gelesen |
| ------ | ----- | ------------ |
| [`regeln/`](./regeln/) | Was gilt? | beim Ändern von Config, Skripten, Manifest |
| [`gates/`](./gates/) | Bin ich fertig? | neue Maschine, vor Merge, vor Push |

### regeln/ — Norm

| Datei | Zweck |
| ----- | ----- |
| [regeln/DOTFILES.md](./regeln/DOTFILES.md) | Was gehört in dieses Repo, was nicht; Installer- und Verknüpfungssemantik |
| [regeln/SHELL.md](./regeln/SHELL.md) | Skriptregeln für bash **und** PowerShell, inklusive Cross-Platform-Pfaden |
| [regeln/SECRETS.md](./regeln/SECRETS.md) | Was nie ins Repo darf und wie Geheimnisse stattdessen geladen werden |

### gates/ — abhakbar, zeitpunktgebunden

| Datei | Zeitpunkt |
| ----- | --------- |
| [gates/NEW_MACHINE.md](./gates/NEW_MACHINE.md) | einmal, beim Einrichten einer Maschine |
| [gates/REVIEW.md](./gates/REVIEW.md) | vor jedem Merge |
| [gates/PUBLISH.md](./gates/PUBLISH.md) | vor jedem Push in ein öffentliches Repo |

### Kein `belege/` — die Belege sind die eigene Historie

Die Lua-Sammlung hat einen `belege/`-Ordner mit gegroundeten Befunden aus 33
Repos. Hier ist das unnötig: dieses Repo **ist** der Beleg. Jede Regel unten
trägt in der Spalte „Beleg" den Vorfall, aus dem sie entstanden ist, mit
Verweis auf [RESTRUCTURE.md](../RESTRUCTURE.md) oder den Commit. Eine Regel
ohne Vorfall ist eine Vermutung und steht hier nicht.

---

## Regel-IDs

Stabile IDs, damit die Gates verweisen statt zu wiederholen. Bewusst andere
Präfixe als die Lua-Sammlung — ein `SEC-03` dort und hier wären sonst zwei
verschiedene Regeln unter einem Namen.

| Präfix | Herkunft |
| ------ | -------- |
| `DOT-` | [regeln/DOTFILES.md](./regeln/DOTFILES.md) |
| `SH-` | [regeln/SHELL.md](./regeln/SHELL.md) |
| `KEY-` | [regeln/SECRETS.md](./regeln/SECRETS.md) |
| `MACH-` | [gates/NEW_MACHINE.md](./gates/NEW_MACHINE.md) |
| `REV-` | [gates/REVIEW.md](./gates/REVIEW.md) |
| `PUB-` | [gates/PUBLISH.md](./gates/PUBLISH.md) |

## Prioritäten-Legende

| Symbol | Bedeutung |
| ------ | --------- |
| 🔴 KRITISCH | Verstoß hat schon einmal echten Schaden angerichtet. Kein Merge, kein Push. |
| 🟡 EMPFOHLEN | Verstoß kostet später Zeit oder erzeugt stille Fehler. |
| 🟢 NICE-TO-HAVE | Konsistenz und Lesbarkeit. |
