#!/bin/bash

# Funktion, um die aktuelle Node-Version zu überprüfen und ggf. auf LTS zu aktualisieren
check_and_update_node() {
  # Überprüfen, ob nvm verfügbar ist
  if ! command -v nvm &> /dev/null; then
    echo "nvm ist nicht verfügbar. Stelle sicher, dass es korrekt installiert ist."
    return
  fi

  # Hole die aktuell verwendete Node.js-Version
  local current_version=$(nvm current)

  # Hole die neueste LTS-Version von nvm (filtere nur die LTS-Versionen heraus und wähle die letzte)
  local lts_version=$(nvm ls-remote --lts | grep -Eo 'v[0-9]+\.[0-9]+\.[0-9]+' | tail -1)

  # Überprüfe, ob die aktuelle Version die LTS-Version ist
  if [ "$current_version" != "$lts_version" ]; then
    # fzf-Auswahl zur Bestätigung der Aktualisierung
  echo "Aktuelle LTS-Version $current_version ist älter als die neueste gefundene $lts_version. Möchtest du updaten?"
    local choice=$(echo -e "Nein\nJa" | fzf --prompt="Auswahl: " --header="Aktuelle Version: $current_version | Neueste LTS: $lts_version" --header-lines=1)

    if [ "$choice" = "Ja" ]; then
      echo "Wechsle zur neuesten LTS-Version von Node.js..."
      nvm install --lts
      nvm use --lts
      echo "Erfolgreich zur LTS-Version gewechselt!"
    else
      echo "Behalte die aktuelle Node-Version: $current_version"
    fi
  else
    echo "Aktuelle Node.js-Version ist die neueste LTS-Version: $lts_version"
  fi
}
