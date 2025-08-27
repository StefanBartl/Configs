# Funktion zur Anzeige der System-Uptime
system_uptime() {
    uptime -p
}

# Funktion für Git-Branch + Status
git_prompt() {
    if git rev-parse --is-inside-work-tree &>/dev/null; then
        local branch_name=$(git branch --show-current)
        local git_status=$(git status --porcelain 2>/dev/null)

        # Prüft, ob Änderungen vorhanden sind (ungespeichert oder gestaged)
        local status_symbol=""
        if [[ -n "$git_status" ]]; then
            status_symbol="%F{red}*%F{reset}"  # Ungesicherte Änderungen
        else
            status_symbol="%F{green}+%F{reset}"  # Sauberer Zustand
        fi

        echo "%F{green}git(%F{white}${branch_name}%F{green})${status_symbol}%F{reset} "
    fi
}

# Prompt setzen
set_prompt() {
    local uptime_formatted=$(system_uptime)

    PROMPT='[%F{magenta}%1~%f]$(git_prompt)%F{lightgray}[%F{cyan}'$uptime_formatted'%F{lightgray}]>%F{reset} '
}

set_prompt
