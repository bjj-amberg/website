#!/usr/bin/env bash
#
# Uebernimmt den Stand aus redesign/mat-black/ ins Wurzelverzeichnis.
#
#   ./redesign/deploy.sh
#
# Ablauf:
#   1. build.pl laufen lassen (Galerie und Rechtstexte auf Stand bringen)
#   2. Die aktuellen Dateien im Wurzelverzeichnis nach
#      redesign/_backup-<zeitstempel>/ sichern
#   3. Die Dateien kopieren und die Bildpfade von ../../images/ auf images/
#      umschreiben
#
# Rueckgaengig: Dateien aus dem Backup-Ordner zurueckkopieren.
#
# ACHTUNG: Das ueberschreibt die index.html im Wurzelverzeichnis und damit
# auch den dort eingetragenen FormSubmit-Endpoint. Fuer blosse Aenderungen
# an Galerie oder Rechtstexten reicht "perl redesign/build.pl" - das fasst
# nur die jeweiligen Bloecke an und laesst den Endpoint in Ruhe.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/redesign/mat-black"

if [ ! -d "$SRC" ]; then
	echo "Quellverzeichnis fehlt: $SRC" >&2
	exit 1
fi

STAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP="$ROOT/redesign/_backup-$STAMP"
FILES="index.html impressum.html datenschutz.html style.css contact.js lang.js"

echo "Quelle:  $SRC"
echo "Ziel:    $ROOT"
echo "Backup:  $BACKUP"
echo

perl "$ROOT/redesign/build.pl" > /dev/null
echo "  build.pl durchgelaufen"

mkdir -p "$BACKUP"
for f in $FILES; do
	if [ -f "$ROOT/$f" ]; then
		cp -p "$ROOT/$f" "$BACKUP/$f"
		echo "  gesichert: $f"
	fi
done
echo

for f in $FILES; do
	cp "$SRC/$f" "$ROOT/$f"
	echo "  kopiert:   $f"
done

for f in index.html impressum.html datenschutz.html style.css; do
	perl -i -pe 's{\.\./\.\./images/}{images/}g' "$ROOT/$f"
done
echo "  Bildpfade auf images/ umgeschrieben"
echo
echo "Nicht vergessen: den FormSubmit-Endpoint in index.html wieder"
echo "eintragen, falls er vorher schon gesetzt war (siehe Backup)."
