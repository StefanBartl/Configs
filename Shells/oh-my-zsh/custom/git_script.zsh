#!/bin/bash

# Pfade zu den Verzeichnissen
MY_GITHUB_DIR=~/MyGithub
GIT_REPO_DIR=~/GitRepo

# Caching Funktion
cache_git_repos() {
    # Alle Git-Repos in den Verzeichnissen scannen und cachen
    cached_repos=()
    while IFS= read -r -d '' repo; do
        cached_repos+=("$repo")
    done < <(find "$MY_GITHUB_DIR" "$GIT_REPO_DIR" -type d -name ".git" -prune -print0 | sed 's|/.git||g')
}

# Auswahlmenü mit fzf
select_option() {
    options=("MyGithub" "GitRepo" "Beide" "Spezifisches Repo")
    selected=$(echo "${options[@]}" | tr ' ' '\n' | fzf --prompt="Wähle eine Option: ")
    echo "$selected"
}

# Repo-Auswahl mit fzf
select_repo() {
    local repos=("$@")
    selected=$(printf "%s\n" "${repos[@]}" | fzf --prompt="Wähle ein Repository: " --header="Oder wähle 'Alle' für alle Repos")
    echo "$selected"
}

# Git-Befehle
git_action() {
    local action="$1"
    local repo="$2"
    case "$action" in
        "force")
            echo "Running: git add . && git commit -m 'DEFAULT' && git push in $repo"
            (cd "$repo" && git add . && git commit -m "DEFAULT" && git push)
            ;;
        "fetch")
            echo "Running: git fetch in $repo"
            (cd "$repo" && git fetch)
            ;;
        "add")
            echo "Running: git add . in $repo"
            (cd "$repo" && git add .)
            ;;
        "commit")
            local message="$3"
            echo "Running: git commit -m '$message' in $repo"
            (cd "$repo" && git commit -m "$message")
            ;;
        "amend")
            echo "Running: git commit --amend in $repo"
            (cd "$repo" && git commit --amend)
            ;;
        "push")
            echo "Running: git push in $repo"
            (cd "$repo" && git push)
            ;;
        *)
            echo "Unbekannte Aktion: $action"
            ;;
    esac
}

# Interaktive Befehlsauswahl
run_interactive() {
    local repos=("${!1}")
    selected_option=$(select_option)

    case "$selected_option" in
        "MyGithub")
            selected_repo=$(select_repo $(find "$MY_GITHUB_DIR" -type d -name ".git" -prune -print | sed 's|/.git||g'))
            ;;
        "GitRepo")
            selected_repo=$(select_repo $(find "$GIT_REPO_DIR" -type d -name ".git" -prune -print | sed 's|/.git||g'))
            ;;
        "Beide")
            selected_repo=$(select_repo "${cached_repos[@]}")
            ;;
        "Spezifisches Repo")
            specific_repo=$(printf "%s\n" "${cached_repos[@]}" | fzf --prompt="Gib den Namen eines spezifischen Repos ein: ")
            selected_repo="$specific_repo"
            ;;
        *)
            echo "Ungültige Auswahl. Abbruch."
            exit 1
            ;;
    esac

    if [[ "$selected_repo" == "Alle" ]]; then
        for repo in "${repos[@]}"; do
            run_git_menu "$repo"
        done
    else
        run_git_menu "$selected_repo"
    fi
}

# Menü für Git-Aktionen
run_git_menu() {
    local repo="$1"
    selected_action=$(echo -e "Force\nFetch\nAdd\nCommit\nAmend\nPush" | fzf --prompt="Wähle eine Aktion: ")

    case "$selected_action" in
        "Force")
            git_action "force" "$repo"
            ;;
        "Fetch")
            git_action "fetch" "$repo"
            ;;
        "Add")
            git_action "add" "$repo"
            ;;
        "Commit")
            commit_msg=$(echo "Default" | fzf --prompt="Gib Commit-Message ein (Standard: 'Default'): ")
            git_action "commit" "$repo" "$commit_msg"
            ;;
        "Amend")
            git_action "amend" "$repo"
            ;;
        "Push")
            git_action "push" "$repo"
            ;;
        *)
            echo "Ungültige Auswahl."
            ;;
    esac
}

# Skriptstart
cache_git_repos
run_interactive cached_repos[@]
