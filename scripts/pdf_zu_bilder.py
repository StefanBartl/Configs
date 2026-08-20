#!/bin/bash

# Funktion zur Anzeige der Hilfe
function zeige_hilfe() {
    echo "Verwendung: $0 <pfad_zum_pdf> [<ziel_verzeichnis>]"
    echo "Konvertiert ein PDF-Dokument in Bilder und Textdateien."
    echo "Beispiel: $0 eingabe.pdf ausgabe_verzeichnis"
}

# Überprüfung der Anzahl der Argumente
if [ "$#" -lt 1 ] || [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
    zeige_hilfe
    exit 1
fi

pdf_path="$1"
output_dir="${2:-~/${pdf_path##*/}_TEXT}"

# Prüfen, ob Tesseract installiert ist
if ! command -v tesseract &> /dev/null; then
    echo "Tesseract ist nicht installiert. Soll es jetzt installiert werden? (y/n)"
    read -r install_tesseract
    if [[ $install_tesseract =~ ^[YyJj]$ ]]; then
        if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
            choco install tesseract
        else
            sudo apt-get update
            sudo apt-get install -y tesseract-ocr
        fi
    else
        echo "Tesseract ist erforderlich, um fortzufahren."
        exit 1
    fi
fi

# Erstelle das Ausgabeverzeichnis, wenn es nicht existiert
mkdir -p "$output_dir/Bilder"
mkdir -p "$output_dir/Text"

# PDF in Bilder umwandeln und Text extrahieren
pdftoppm -png "$pdf_path" "$output_dir/Bilder/Seite"

for image in "$output_dir/Bilder"/*.png; do
    base=$(basename "$image" .png)
    page_number="${base#Seite}"

    # Texterkennung durch Tesseract
    tesseract "$image" "$output_dir/Text/Seite${page_number}_text"

    # Markdown-Datei aktualisieren
    echo "## Seite ${page_number}" >> "$output_dir/inhalt.md"
    cat "$output_dir/Text/Seite${page_number}_text.txt" >> "$output_dir/inhalt.md"
    echo "" >> "$output_dir/inhalt.md"
done

echo "Verarbeitung abgeschlossen. Ergebnisse wurden im Verzeichnis '$output_dir' gespeichert."

