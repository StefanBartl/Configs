# VSVim Konfiguration einrichten

Diese Anleitung beschreibt, wie du deine `_vsvimrc` (deine Vim-Keymappings für Visual Studio) hinterlegst, damit die Erweiterung **VSVim** sie automatisch lädt.

## Speicherort der Datei

Damit Visual Studio (VSVim) die Konfiguration erkennt, muss die Datei unter folgendem Pfad liegen:

`C:\Users\<DeinBenutzername>\_vsvimrc`

*(Wichtig: Die Datei muss mit einem Unterstrich `_` beginnen, nicht mit einem Punkt `.` wie unter Linux/Neovim).*

---

## Einrichtungsschritte (Schnellanleitung)

1. Drücke `Win + R`, gib `%USERPROFILE%` ein und drücke **Enter**. (Das öffnet direkt deinen Benutzerordner).
2. Erstelle in diesem Ordner eine neue Textdatei und benenne sie exakt um in: **`_vsvimrc`**
   *(Achte darauf, dass Windows die Dateiendung `.txt` entfernt!).*
3. Kopiere den gesamten Inhalt der Konfiguration in diese Datei und speichere sie ab.
4. Starte Visual Studio neu (falls es geöffnet war).

---

## Alternative: Verknüpfung mit deinem Config-Repo (Empfohlen)

Da du deine Configs in einem Repository pflegst (`c:\repos\Configs\Windows\...`), musst du die Datei nicht jedes Mal kopieren. Du kannst einen **Symbolic Link (Symlink)** erstellen.

Dadurch holt sich Visual Studio die Datei direkt aus deinem Repo. Jede Änderung in deinem Repo ist sofort aktiv!

### So erstellst du den Symlink:
1. Öffne die **Eingabeaufforderung (cmd)** oder **PowerShell** als **Administrator**.
2. Führe folgenden Befehl aus (passe ggf. den Pfad zu deinem Repo an):

```cmd
mklink "%USERPROFILE%\_vsvimrc" "C:\repos\Configs\Windows\DOTFILES\vsvim\_vsvimrc"

```

Ab jetzt musst du die Datei nur noch in deinem Repo pflegen!
