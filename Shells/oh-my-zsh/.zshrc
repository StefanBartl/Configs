# Setzen Sie den $PATH mit den erforderlichen Pfaden
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$HOME/bin:$HOME/nvim-linux64/bin:$HOME/lua-language-server/bin:$HOME/Development/lua-language-server/bin:snap/bin:$HOME/perl5/bin${PATH:+:${PATH}}"

# Legen Sie den Pfad zu oh-my-zsh fest
export ZSH="$HOME/.oh-my-zsh"

export VISUAL="nvim"
export EDITOR="$VISUAL"

# Wählen Sie Ihr bevorzugtes Theme aus
ZSH_THEME="amuse"

# Konfigurieren Sie oh-my-zsh-Einstellungen nach Bedarf

# Laden von benutzerdefinierten Aliassen
ZSH_CUSTOM="$HOME/MyGithub/LinuxFiles/oh-my-zsh/custom/my_aliases.zsh"
source $ZSH_CUSTOM

# Laden von benutzerdefinierten Plugins
ZSH_CUSTOM_PLUGINS="$HOME/MyGithub/LinuxFiles/oh-my-zsh/plugins"
for plugin ($ZSH_CUSTOM_PLUGINS/*.zsh) {
  source $plugin
}

# Laden von oh-my-zsh
source $ZSH/oh-my-zsh.sh

# tmux

## tmux config einbinden
export TMUX_CONFIG=~/.config/tmux/tmux.conf

## tmux bei start von zsh starten, außer es gibt eine aktie session
#if [ -z "$TMUX" ]; then
#  tmux
#fi

## tmux autmatisches windows renaming aktivieren
#tmux-window-name() {
#	($TMUX_PLUGIN_MANAGER_PATH/tmux-window-name/scripts/rename_session_windows.py &)
#}
# add-zsh-hook chpwd tmux-window-name

# Autojump
if [[ -s /home/lvalue/.autojump/etc/profile.d/autojump.sh ]]; then
  source /home/lvalue/.autojump/etc/profile.d/autojump.sh
fi

# NVM (Node Version Manager) einrichten
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion" # This loads nvm bash_completion

# Lazy Loading für NVM
export NVM_LAZY_LOAD=true

# Automatisch die neueste LTS-Version verwenden
#nvm alias default 'lts/*'
#nvm use default

# Setzen des Linuxbrew-Pfads, wenn Linuxbrew verwendet wird
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Autojump, wenn es verfügbar ist
if [[ -s /home/lvalue/.autojump/etc/profile.d/autojump.sh ]]; then
  source /home/lvalue/.autojump/etc/profile.d/autojump.sh
fi

# Zsh completions
autoload -U compinit && compinit -u

# Setzen des Linuxbrew-Pfads, wenn Sie Linuxbrew verwende
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Set up fzf key bindings and fuzzy completion
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# zioxide
eval "$(zoxide init zsh)"
alias fd=fdfind
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


# Shell Aliase aus .bash_aliases einlesen
[ -f ~/.bash_aliases ] && source ~/.bash_aliases

alias less="less -M"

