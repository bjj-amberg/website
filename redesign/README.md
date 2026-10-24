# Quellen und Build

Hier liegt das, woraus die Seite im Wurzelverzeichnis gebaut wird.

    mat-black/      Quelldateien des Designs
    _content/       Impressum und Datenschutz, je Sprache eine Datei
    build.pl        erzeugt Galerie und Rechtstexte
    deploy.sh       uebernimmt mat-black/ ins Wurzelverzeichnis
    _backup-*/      Sicherungen von deploy.sh (nicht im Repository)

Der Ordner ist in `_config.yml` von der Veroeffentlichung ausgenommen und
landet nicht auf bjj-amberg.de.

## Die zwei Befehle

**`perl redesign/build.pl`** - fuer den Alltag. Liest `images/galerie/` aus
und baut die Rechtstexte neu. Angefasst wird nur der jeweilige Block, sowohl
in `mat-black/` als auch direkt in der `index.html` im Wurzelverzeichnis.
Eingetragene Werte wie der FormSubmit-Endpoint bleiben erhalten.

**`./redesign/deploy.sh`** - nur nach Aenderungen am Design oder an der
Startseite. Kopiert alle Dateien aus `mat-black/` ins Wurzelverzeichnis und
schreibt die Bildpfade um. **Das ueberschreibt auch den FormSubmit-Endpoint**,
der steht danach wieder auf dem Platzhalter. Vorher wird alles nach
`_backup-<zeitstempel>/` gesichert.

Faustregel: Bilder oder Rechtstexte geaendert -> `build.pl`. Design oder
Startseite geaendert -> `deploy.sh`, danach den Endpoint neu eintragen.

## Galeriebilder austauschen

Fotos nach `images/galerie/` legen, dann `perl redesign/build.pl`.

- Unterstuetzt werden JPG, PNG, WEBP, GIF und AVIF. **HEIC vom iPhone nicht** -
  das zeigt kein Browser an. Das Skript meldet solche Dateien und ueberspringt
  sie; sie muessen vorher als JPG exportiert werden.
- Sortiert wird nach Dateiname, Zahlen dabei numerisch (`bild2` vor `bild10`).
- Leerzeichen im Dateinamen sind in Ordnung, die werden automatisch kodiert.
- Ist der Ordner leer, verschwindet die Galerie rueckstandslos.

Warum ein Befehl und kein Automatismus: GitHub Pages kann kein Verzeichnis
auflisten, und beim lokalen Oeffnen per Doppelklick blockiert der Browser
Dateizugriffe aus JavaScript. Die Bildliste muss fest im HTML stehen.

## Zweisprachigkeit (Deutsch / Englisch)

Beide Sprachen stehen gleichzeitig im HTML, jeweils in einem Element mit
`lang="de"` bzw. `lang="en"`. Welche sichtbar ist, entscheidet das CSS anhand
von `data-lang` am `<html>`-Element. `lang.js` setzt dieses eine Attribut -
als blockierendes Skript im `<head>`, also bevor der Browser etwas zeichnet.
Dadurch steht von Anfang an die richtige Sprache da, es blitzt nichts auf.

Spracherkennung, in dieser Reihenfolge:

1. Was der Besucher zuletzt selbst gewaehlt hat (`localStorage`)
2. Die Spracheinstellung seines Browsers
3. Englisch

Ohne JavaScript bleibt die Seite auf Deutsch lesbar (im HTML steht fest
`data-lang="de"`), nur der Umschalter faellt weg.

**Texte aendern: immer beide Fassungen anpassen.** Auf der Startseite stehen
sie direkt nebeneinander im HTML.

## Rechtstexte aendern

Die Texte liegen unter `_content/`, je Seite und Sprache eine Datei:

    impressum.de.part.html     impressum.en.part.html
    datenschutz.de.part.html   datenschutz.en.part.html

Danach `perl redesign/build.pl`. Header und Footer werden dabei aus
`mat-black/index.html` uebernommen - Startseite und Rechtstexte koennen also
nicht auseinanderlaufen.

Die englischen Fassungen sind Uebersetzungen zur Verstaendlichkeit. Beide
tragen oben einen Hinweis, dass im Zweifel die deutsche Fassung gilt.

## Keine externen Ressourcen

Keine Google Fonts, kein jQuery, kein CDN - nur Systemschriften und eigene
Dateien. Das ist kein Zufall: Die Datenschutzerklaerung sagt ausdruecklich zu,
dass nichts von Dritt-Servern nachgeladen wird. Wer eine externe Schrift oder
Bibliothek einbaut, macht diese Aussage falsch.
