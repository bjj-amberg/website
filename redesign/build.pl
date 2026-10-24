#!/usr/bin/env perl
#
# Baut die erzeugten Teile der Website.
#
#   perl redesign/build.pl
#
# Zwei Aufgaben:
#
#   1. GALERIE
#      Liest alles aus images/galerie/ und schreibt die <img>-Tags zwischen
#      die Marker GALERIE:START / GALERIE:ENDE - in die Quelldatei und in die
#      index.html im Wurzelverzeichnis.
#
#      Warum ein Skript und kein Automatismus im Browser? GitHub Pages kann
#      kein Verzeichnis auflisten, und beim lokalen Oeffnen per Doppelklick
#      blockiert der Browser Dateizugriffe aus JavaScript. Die Bildliste muss
#      also fest im HTML stehen. Dieses Skript schreibt sie.
#
#   2. RECHTSTEXTE
#      Setzt Impressum und Datenschutz aus _content/ zusammen - beide
#      Sprachen in eine Datei, sichtbar ist je nach data-lang nur eine.
#
# Angefasst wird immer nur der jeweilige Block. Von Hand eingetragene Werte
# wie der FormSubmit-Endpoint bleiben erhalten.
#
use strict;
use warnings;

my $ROOT   = "/home/jakob/Repos_Privat/website";
my $SOURCE = "mat-black";          # Quellverzeichnis unter redesign/

# Formate, die jeder Browser direkt anzeigt. HEIC vom iPhone gehoert NICHT
# dazu - deshalb unten die Warnung.
my @WEB_OK  = qw(jpg jpeg png webp gif avif);
my @WEB_BAD = qw(heic heif tif tiff bmp raw dng cr2 nef);

sub slurp { my $f = shift; open(my $h, "<:raw", $f) or die "Kann $f nicht lesen: $!\n";
            my $s = do { local $/; <$h> }; close $h; $s }
sub spew  { my ($f,$s) = @_; open(my $h, ">:raw", $f) or die $!; print $h $s; close $h }

# Dateinamen fuer die URL kodieren (Leerzeichen etc.).
sub urlenc { my $s = shift; $s =~ s/([^A-Za-z0-9._~,()-])/sprintf("%%%02X", ord($1))/ge; $s }

# ----------------------------------------------------------------- Galerie

sub gallery_images {
	my $dir = "$ROOT/images/galerie";
	unless (-d $dir) { print "  Hinweis: images/galerie/ existiert nicht.\n"; return ([], []); }

	opendir(my $d, $dir) or die $!;
	my @all = grep { !/^\./ && -f "$dir/$_" } readdir($d);
	closedir $d;

	my %ok  = map { $_ => 1 } @WEB_OK;
	my %bad = map { $_ => 1 } @WEB_BAD;

	my (@good, @skipped);
	for my $f (@all) {
		my ($ext) = $f =~ /\.([^.]+)$/;
		$ext = lc($ext // "");
		if    ($ok{$ext})  { push @good, $f }
		elsif ($bad{$ext}) { push @skipped, $f }
	}
	# Nach Namen sortieren, Zahlen dabei numerisch (bild2 vor bild10).
	@good = sort {
		my ($x,$y) = ($a,$b);
		$x =~ s/(\d+)/sprintf("%010d",$1)/ge;
		$y =~ s/(\d+)/sprintf("%010d",$1)/ge;
		lc($x) cmp lc($y);
	} @good;

	return (\@good, \@skipped);
}

sub update_galleries {
	my ($imgs, $skipped) = gallery_images();

	print "GALERIE\n";
	printf("  %d Bild(er) in images/galerie/\n", scalar @$imgs);
	if (@$skipped) {
		print "  ACHTUNG - uebersprungen, weil Browser das Format nicht anzeigen:\n";
		print "    - $_\n" for @$skipped;
		print "    Diese Dateien bitte als JPG oder PNG exportieren.\n";
	}

	# Nur diese beiden Dateien - bewusst kein Platzhalter-Muster, damit die
	# Sicherungen unter _backup-*/ nicht mitbearbeitet werden.
	my @targets = ("$ROOT/redesign/$SOURCE/index.html");
	push @targets, "$ROOT/index.html" if -f "$ROOT/index.html";

	for my $f (@targets) {
		next unless -f $f;
		my $s = slurp($f);
		next unless $s =~ /GALERIE:START/ && $s =~ /GALERIE:ENDE/;

		# Aus dem Quellverzeichnis heraus liegen die Bilder zwei Ebenen hoeher.
		my $prefix = ($f =~ m{/redesign/\Q$SOURCE\E/}) ? "../../images/galerie/" : "images/galerie/";
		my $indent = "\t\t\t\t";

		my $block = "";
		if (@$imgs) {
			$block .= $indent . '<img src="' . $prefix . urlenc($_)
			       . '" alt="Eindruck vom Training bei BJJ Amberg" loading="lazy">' . "\n"
				for @$imgs;
		} else {
			$block = $indent . "<!-- Noch keine Bilder. Fotos in images/galerie/ ablegen\n"
			       . $indent . "     und 'perl redesign/build.pl' ausfuehren. -->\n";
		}

		my $nl = ($s =~ /\r\n/) ? "\r\n" : "\n";
		$block =~ s/\n/$nl/g if $nl eq "\r\n";

		$s =~ s{(GALERIE:START[ \t]*-->).*?(<!--[ \t]*GALERIE:ENDE)}{$1$nl$block$indent$2}s
			or die "Marker in $f nicht ersetzbar\n";

		spew($f, $s);
		(my $short = $f) =~ s{^\Q$ROOT\E/}{};
		printf("  %-40s %d Bild(er)\n", $short, scalar @$imgs);
	}
	print "\n";
}

# ------------------------------------------------------------- Rechtstexte

my %PAGE = (
	impressum   => { de => "Impressum",   en => "Legal Notice",
	                 desc => "Impressum und Anbieterkennzeichnung von BJJ Amberg nach &sect; 5 DDG." },
	datenschutz => { de => "Datenschutz", en => "Privacy Policy",
	                 desc => "Datenschutzerkl&auml;rung von BJJ Amberg nach Art. 13 DSGVO." },
);

sub build_legal {
	print "RECHTSTEXTE  (zweisprachig)\n";

	my $idx = slurp("$ROOT/redesign/$SOURCE/index.html");

	my ($hdr) = $idx =~ m{(<header class="site-header">.*?</header>)}s
		or die "Header in $SOURCE/index.html nicht gefunden\n";
	my ($ftr) = $idx =~ m{(<footer class="site-footer">.*?</footer>)}s
		or die "Footer in $SOURCE/index.html nicht gefunden\n";

	# Anker-Links zeigen auf der Rechtstext-Seite ins Leere.
	$hdr =~ s{href="\#(?!")}{href="index.html\#}g;

	for my $page (sort keys %PAGE) {
		my $de = slurp("$ROOT/redesign/_content/$page.de.part.html");
		my $en = slurp("$ROOT/redesign/_content/$page.en.part.html");
		my ($td, $te, $d) = ($PAGE{$page}{de}, $PAGE{$page}{en}, $PAGE{$page}{desc});

		my $html = <<"HTML";
<!DOCTYPE html>
<!--
\tErzeugt von redesign/build.pl - Aenderungen hier gehen verloren.
\tDie Texte liegen unter redesign/_content/$page.de.part.html
\tund $page.en.part.html.
-->
<html lang="de" data-lang="de"
      data-title-de="$td &mdash; BJJ Amberg"
      data-title-en="$te &mdash; BJJ Amberg">
<head>
<meta charset="utf-8">
<title>$td &mdash; BJJ Amberg</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta name="description" content="$d">
<meta name="robots" content="noindex, follow">
<link rel="icon" type="image/png" href="../../images/logo.png">
<link rel="stylesheet" href="style.css">
<script src="lang.js"></script>
</head>
<body>

$hdr

<main class="legal">
\t<div class="wrap">
\t\t<p><a class="back-link" href="index.html"><span lang="de">&larr; Zur&uuml;ck zur Startseite</span><span lang="en">&larr; Back to the homepage</span></a></p>

\t\t<div lang="de">
$de
\t\t</div>

\t\t<div lang="en">
$en
\t\t</div>

\t\t<p style="margin-top: 3rem;"><a class="back-link" href="index.html"><span lang="de">&larr; Zur&uuml;ck zur Startseite</span><span lang="en">&larr; Back to the homepage</span></a></p>
\t</div>
</main>

$ftr

<script src="contact.js"></script>
</body>
</html>
HTML
		spew("$ROOT/redesign/$SOURCE/$page.html", $html);
		printf("  %-32s %6d Bytes\n", "$page.html", length($html));
	}
	print "\n";
}

update_galleries();
build_legal();
print "Fertig.\n";
