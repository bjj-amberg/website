# bjj-amberg.de

Website der Trainingsgruppe BJJ Amberg. Statische Seite, gehostet auf
GitHub Pages unter der Domain aus `CNAME`.

## Aufbau

    index.html          Startseite
    impressum.html      \ erzeugt - nicht direkt bearbeiten,
    datenschutz.html    / siehe redesign/README.md
    style.css           gesamtes Styling
    contact.js          setzt E-Mail-Adressen erst im Browser zusammen
    lang.js             Sprachumschaltung Deutsch / Englisch
    images/             Bilder
    images/galerie/     Fotos fuer den Abschnitt "Einblicke"
    redesign/           Quellen und Build-Skripte

## Haeufige Aufgaben

**Galeriebilder austauschen:** Fotos nach `images/galerie/` legen, dann

    perl redesign/build.pl

**Impressum oder Datenschutz aendern:** Die Texte liegen unter
`redesign/_content/`, je Seite und Sprache eine Datei. Danach ebenfalls
`perl redesign/build.pl`.

**Texte auf der Startseite aendern:** Direkt in `index.html`. Jeder Text
steht zweimal da, einmal `lang="de"` und einmal `lang="en"` - beide
anpassen.

Details in `redesign/README.md`. Was noch offen ist, steht in `todo.txt`.
