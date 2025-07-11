Hier ist das Shell-Skript, das den Alias als Eingabeparameter annimmt und diesen effizient in die angegebenen Dateien einfügt. Das Skript überprüft, ob der Alias bereits vorhanden ist, und fügt ihn nur hinzu, wenn er noch nicht existiert. Es gibt außerdem Meldungen aus, um den Status anzuzeigen:

### Skript: `add_alias.sh`

```bash
#!/bin/bash

# Check if alias string is provided
if [ -z "$1" ]; then
    echo "Usage: $0 'alias yourAlias=\"command\"'"
    exit 1
fi

# Alias string to be added
alias_string="$1"

# List of target files
files=(
    ~/.zshrc
    ~/.bashrc
    ~/.bash_aliases
    ~/MyGithub/smt/.bash_aliases
    ~/MyGithub/smt/.bashrc
    ~/MyGithub/smt/oh-my-zsh/.zshrc
    ~/MyGithub/smt/.bash_aliases
    ~/MyGithub/smt/.bashrc
    ~/MyGithub/smt/oh-my-zsh/.zshrc
)

# Function to add alias to a file if not already present
add_alias_to_file() {
    local file="$1"
    if grep -qxF "$alias_string" "$file"; then
        echo "Alias already exists in $file"
    else
        echo "$alias_string" >> "$file"
        echo "Alias added to $file"
    fi
}

# Loop through each file and add alias
for file in "${files[@]}"; do
    if [ -f "$file" ]; then
        add_alias_to_file "$file"
    else
        echo "File $file does not exist. Skipping."
    fi
done
```

### Erklärung:
1. **`if [ -z "$1" ]; then ... fi`**: Prüft, ob ein Alias als Argument übergeben wurde. Falls nicht, zeigt es eine Anleitung an und beendet das Skript.
2. **`alias_string="$1"`**: Speichert den übergebenen Alias-String.
3. **`files=(...)`**: Enthält die Liste der Dateien, in die der Alias eingefügt werden soll.
4. **`add_alias_to_file` Funktion:** Überprüft, ob der Alias bereits in der Datei vorhanden ist. Falls nicht, wird er hinzugefügt und eine Bestätigung ausgegeben.
5. **`for file in "${files[@]}"; do ... done`**: Durchläuft jede Datei und wendet die `add_alias_to_file`-Funktion an.

### Nutzung:
Speichern Sie das Skript als `add_alias.sh`, machen Sie es ausführbar und führen Sie es aus:
```bash
chmod +x add_alias.sh
./add_alias.sh 'alias updateRepos="~/MyGithub/update_repos.sh"'
./add_alias.sh 'alias updateRepos="~/MyGithub/update_repos.sh"'
```

### Beispiel-Ausgabe:
```plaintext
Alias added to /home/user/.zshrc
Alias already exists in /home/user/.bashrc
File /home/user/.bash_aliases does not exist. Skipping.
Alias added to /home/user/MyGithub/LinuxFiles/.bash_aliases
Alias added to /home/user/MyGithub/LinuxFiles/.bashrc
Alias added to /home/user/MyGithub/LinuxFiles/oh-my-zsh/.zshrc
Alias added to /home/user/MyGithub/LinuxFiles/.bash_aliases
Alias added to /home/user/MyGithub/LinuxFiles/.bashrc
Alias added to /home/user/MyGithub/LinuxFiles/oh-my-zsh/.zshrc
```

Das Skript ist flexibel und kann mit verschiedenen Alias-Strings verwendet werden. Es sorgt dafür, dass keine doppelten Einträge entstehen und bietet hilfreiche Rückmeldungen.
