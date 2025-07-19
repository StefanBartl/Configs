# Pfade
## Systemweite Standard-Binärverzeichnisse (für alle Benutzer verfügbar)
export PATH="/usr/local/sbin"       # Enthält systemweite Admin-Tools, meist für Root-Benutzer (nicht in allen Systemen vorhanden)
PATH="$PATH:/usr/local/bin"         # Programme, die manuell installiert wurden (nicht über den Paketmanager)
PATH="$PATH:/usr/sbin"              # Systemverwaltungsprogramme (z. B. `fdisk`, `ifconfig`), die Admin-Rechte benötigen
PATH="$PATH:/usr/bin"               # Standard-Binärdateien für alle Benutzer (z. B. `ls`, `grep`, `vim`)
PATH="$PATH:/sbin"                  # Weitere Systemverwaltungsprogramme, oft für den Boot-Prozess (ähnlich wie `/usr/sbin`)
PATH="$PATH:/bin"                   # Basis-Binärdateien für alle Benutzer (z. B. `cat`, `echo`, `cp`)
## Benutzerdefinierte Pfade für persönliche Skripte und Programme
PATH="$PATH:$HOME/bin"              # Benutzerdefinierte Skripte und Programme (falls angelegt)
PATH="$PATH:$HOME/nvim-linux64/bin" # Neovim-Binaries, wenn Neovim manuell installiert wurde
PATH="$PATH:$HOME/lua-language-server/bin"  # Lua Language Server für Syntaxprüfung und Autovervollständigung
PATH="$PATH:$HOME/Development/lua-language-server/bin"  # Alternative Installation des Lua Language Servers
## Snap-Programme (Containerisierte Anwendungen, installiert über `snap`)
PATH="$PATH:/snap/bin"              # Standard-Pfad für Snap-Pakete
## Perl-spezifischer Pfad (Falls Perl-Module installiert wurden)
PATH="$PATH:$HOME/perl5/bin"        # Enthält benutzerdefinierte Perl-Module und ausführbare Dateien
## Erhaltung des vorherigen PATH-Werts, falls bereits definiert
export PATH                         # Die exportierte PATH-Variable bleibt bestehen

export HISTCONTROL=ignoredups # Causes the shell's history recording feature to ignore a command if the same command was just recorded
export HISTSIZE=1000 # Increases the size of the command history from the usual default of 500 lines to 1,000 lines.

# Created by `pipx` on 2025-03-11 01:24:31
export PATH="$PATH:/home/steve/.local/bin"

# Preferred editor for local and remote sessions
 if [[ -n $SSH_CONNECTION ]]; then
   export EDITOR='nvim'
 else
   export EDITOR='nvim'
fi

# Mein Github Pfad auf dem PC
if [ -d "/media/steve/Depot/MyGithub" ]; then
  MY_GITHUB_PATH="/media/steve/Depot/MyGithub"
else
  echo "⚠️  MyGithub konnte nicht gefunden werden! Stelle sicher, dass die SSD gemountet ist."
fi

# oh-my-zsh
export ZSH="$HOME/.oh-my-zsh"

## Bevorzugtes zsh-Theme
ZSH_THEME="amuse"

## Funktion, um alle .sh-Dateien aus einem Ordner zu source'n
source_all_files() {
  local dir=$1
  if [ -d "$dir" ]; then
    for file in "$dir"/*.sh; do
      [ -f "$file" ] && source "$file"
    done
  fi
}

## Ordner mit Alias- und Skript-Dateien
ALIAS_DIR="$MY_GITHUB_PATH/my-zsh/aliase"
SCRIPTS_DIR="$MY_GITHUB_PATH/my-zsh/scripts"
FUNC_DIR="$MY_GITHUB_PATH/my-zsh/functions"

## Dateien aus den entsprechenden Ordnern source'n
source_all_files "$ALIAS_DIR"
source_all_files "$SCRIPTS_DIR"

export ZSH_CUSTOM="$HOME/.oh-my-zsh/custom"
plugins=(git zsh-autosuggestions zsh-syntax-highlighting fzf-zsh-plugin colored-man-pages)

## Laden von oh-my-zsh
source $ZSH/oh-my-zsh.sh

function set_win_title() {
  echo -ne "\033]0; $(basename "$PWD")\007"
}

# For bash:
#starship_precmd_user_func="set_win_title"

# For zsh:
precmd_functions+=(set_win_title)


# tmux
MY_TMUX_PATH="$MY_GITHUB_PATH/LinuxFiles/MyTmux"
## tmux config einbinden
export TMUX_CONFIG=~"$MY_TMUX_PATH/tmux.conf"

# NVM mit Homebrew nutzen
export NVM_DIR="$HOME/.nvm"  # Standard-Ordner für NVM
[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh" ] && \. "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh"  # NVM laden
[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm"  # NVM Autovervollständigung laden

# Lazy Loading für NVM aktivieren
export NVM_LAZY_LOAD=true

# Setzen des Linuxbrew-Pfads, wenn Linuxbrew verwendet wird
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Zsh completions
autoload -U compinit && compinit -u

# Set up fzf key bindings and fuzzy completion
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# zoxide
eval "$(zoxide init zsh)"

# Laden der .env Dateie im Root Verzeichnis
for file in ~/Custom/env/.*env; do
  [ -f "$file" ] && export $(grep -v '^#' "$file" | xargs)
done

# source ~/.oh-my-zsh/custom/my_prompt.zsh
#eval "$(oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/tokyo.omp.json)"
eval "$(oh-my-posh init zsh --config $(brew --prefix oh-my-posh)/themes/jandedobbeleer.omp.json)"
