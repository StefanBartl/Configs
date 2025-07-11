#!/bin/bash

# Datum aktualisieren
current_date=$(date +"%a %b %d %T %Z %Y")

# Systeminformationen abrufen
system_info=$(uname -a)
system_load=$(uptime)
disk_usage=$(df -h /)
memory_usage=$(free -m)
ip_address=$(hostname -I)
available_updates=$(sudo apt list --upgradable 2>/dev/null | grep -c "upgradable")

# ANSI-Escape Sequenzen Farbdefinitionen
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

# TPUT Farbdefinitionen
# GREEN=$(tput setaf 2)
# YELLOW=$(tput setaf 3)
# RESET=$(tput sgr0)

# Starting Page erstellen
echo -e "${GREEN}Willkommen Stefan zu $(lsb_release -sd)${RESET}"
echo ""
echo -e "  ${YELLOW}Systeminformationen von $current_date${RESET}"
echo ""
echo ""
echo "  Systemlast seit Boot:  $system_load"
echo -e "  Speichernutzung:\n$disk_usage"
echo -e "  RAM-Speichernutzung:\n$memory_usage"
echo "  IP-Addresse:   $ip_address"
echo ""

echo -e "  Verfügbare updates: ${GREEN}$available_updates${RESET}"

