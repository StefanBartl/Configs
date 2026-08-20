
# Alias für das sofortige Löschen ohne Bestätigung
alias remove='rm -rf'

alias updateOS='brew update && brew upgrade && brew cleanup && softwareupdate -i -a'
alias o='/usr/bin/open'

alias ls='ls --hyperlink --color=auto'
alias delta="delta --hyperlinks --hyperlinks-file-link-format='file://{path}#{line}'"
alias rg='rg --hyperlink-format=kitty'

# Verzeichnisse; Funktionieren nur wenn richtig aufgesetzt:
alias downloads='cd ~/Downloads'
alias ndir='cd ~/.config/nvim && git fetch && git status'

# Skripte
alias pdf_zu_bilder='~/MyGithub/Configs/Shells/PythonScripts/pdf_zu_bilder.py'

# Configs
alias bashconfig="nvim ~/.bashrc"
alias zshconfig="nvim ~/.zshrc"

alias shortboard="nvim ~/MyGithub/WKDBooks/wkdbook-OS/wkdbook-CLI/wkdbook-PosixShells/CLITools/Shortboard.md"
alias gitinfo='echo "Repository: $(git rev-parse --show-toplevel) | Branch: $(git rev-parse --abbrev-ref HEAD) | Commit: $(git rev-parse HEAD) | Remote: $(git remote get-url origin | sed -E "s|.*github.com[:/](.*)\.git|\1|") | Status: $(git status -s)"'

