# Cheatsheet `_vsvim`

## Table of content

- [Cheatsheet `_vsvim`](#cheatsheet-_vsvim)
  - [Allgemeine Einstellungen & Modus-Wechsel](#allgemeine-einstellungen-modus-wechsel)
  - [Allgemeine Bearbeitung (General)](#allgemeine-bearbeitung-general)
  - [Text verschieben & Formatieren (Editing)](#text-verschieben-formatieren-editing)
  - [Fenster & Tab-Management (Buf_Win_Tab)](#fenster-tab-management-buf_win_tab)

---

## Allgemeine Einstellungen & Modus-Wechsel

| Code-Zeile | Was es genau macht | Dein Vorteil im Alltag |
| --- | --- | --- |
| `set ignorecase` | Ignoriert Groß-/Kleinschreibung bei der Suche. | Wenn du nach `stefan` suchst, wird auch `Stefan` gefunden. |
| `set smartcase` | Sucht exakt nach Großbuchstaben, sobald du einen tippst. | Suchst du nach `Stefan`, wird `stefan` ignoriert. Best of both worlds! |
| `set hlsearch` | Hebt alle gefundenen Suchtreffer farblich hervor. | Du siehst sofort visuell, wo deine Suchbegriffe im Code stecken. |
| `inoremap jk <Esc>`<br>

<br>`vnoremap jk <Esc>`<br>

<br>`tnoremap jk <Esc>` | Drücken der Tasten **`j` und `k` direkt hintereinander** verlässt den aktuellen Modus (Insert, Visual, Terminal) und springt in den Normal Mode. | Du musst deine Finger nicht mehr zur weit entfernten `Esc`-Taste bewegen. Extrem gut für den Schreibfluss. |

---

## Allgemeine Bearbeitung (General)

| Code-Zeile | Was es genau macht | Dein Vorteil im Alltag |
| --- | --- | --- |
| `nnoremap <C-a> ggVG` | `Strg + A` markiert das gesamte Dokument. | Verhält sich wie der Windows-Standard, aber nutzt im Hintergrund Vim-Befehle (`gg` = Anfang, `V` = Zeilen-Visual-Mode, `G` = Ende). |
| `nnoremap <C-s> :vsc File.SaveSelectedItems<CR>` | `Strg + S` speichert die aktuelle Datei. | Löst den echten, nativen Speicherbefehl von Visual Studio aus. |
| `nnoremap x "_x` | Löscht das Zeichen unter dem Cursor, **ohne** es in die Zwischenablage (Register) zu legen. | Verhindert, dass Text, den du gerade kopiert hast, durch ein gelöschtes Zeichen überschrieben wird. |
| `nnoremap dw vb"_d` | Löscht das aktuelle Wort rückwärts, ohne es in die Zwischenablage zu legen. | Perfekt, um Tippfehler im Wort davor schnell zu entfernen. |
| `nnoremap + <C-a>`<br>

<br>`nnoremap - <C-x>` | `+` erhöht eine Zahl unter dem Cursor um 1, `-` verringert sie um 1. | Schnelles Hoch- oder Runterzählen von Zahlen (z.B. Versionen oder IDs) wie in Neovim. |

---

## Text verschieben & Formatieren (Editing)

| Code-Zeile | Was es genau macht | Dein Vorteil im Alltag |
| --- | --- | --- |
| `nnoremap <leader><CR> o<Esc>k` | Fügt eine leere Zeile *unter* dem Cursor ein und springt zurück. | Schafft Platz im Code, ohne dass du den Normal Mode dauerhaft verlässt. |
| `nnoremap <CR> 0i<CR><Esc>k` | Fügt eine leere Zeile *über* dem Cursor ein. | Trennt Code-Blöcke blitzschnell ab. |
| `xnoremap p "_dP` | Fügt kopierten Text über eine Markierung ein, **ohne** den überschriebenen Text in die Zwischenablage zu packen. | Du kannst denselben Text mehrfach hintereinander über andere Wörter drüber-einfügen. |
| `nnoremap <A-Up> ...`<br>

<br>`nnoremap <A-Down> ...` | `Alt + Pfeiltaste hoch/runter` verschiebt die aktuelle Zeile oder markierte Zeilen nach oben oder unten. | Nutzt die native Visual Studio Logik für perfektes Einrücken während des Verschiebens. |

---

## Fenster & Tab-Management (Buf_Win_Tab)

| Code-Zeile | Was es genau macht | Dein Vorteil im Alltag |
| --- | --- | --- |
| `nnoremap <C-h> <C-w>h`<br>

<br>`nnoremap <C-l> <C-w>l`<br>

<br>`nnoremap <C-j> <C-w>j`<br>

<br>`nnoremap <C-k> <C-w>k` | `Strg` + `h/j/k/l` wechselt den Fokus zwischen geteilten Code-Fenstern (Splits). | Schnelles Hin- und Herspringen zwischen zwei parallel geöffneten Dateien. |
| `nnoremap <leader>q :vsc ...` | Deine Leader-Taste (meistens Leertaste) + `q` schließt das aktuelle Dokumentenfenster. | Schnelles Aufräumen von offenen Tabs. |
| `nnoremap <leader>tn ...`<br>

<br>`nnoremap <leader>tp ...` | `<leader>tn` springt zum nächsten Tab, `<leader>tp` zum vorherigen Tab. | Schnelles Durchblättern deiner geöffneten Dateien in Visual Studio. |

> **Info zu `:vsc`:** Dieser Befehl ist eine Besonderheit von VSVim. Er sagt der Erweiterung: *"Hey, führe hier keinen Vim-Befehl aus, sondern steuere direkt eine Funktion von Visual Studio an"*. Damit klinkst du dich perfekt in die Windows-Entwicklungsumgebung ein.

---
