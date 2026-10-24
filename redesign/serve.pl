#!/usr/bin/env perl
#
# Kleiner lokaler Webserver zum Testen.
#
#   perl redesign/serve.pl          # http://localhost:8000
#   perl redesign/serve.pl 8080     # anderer Port
#
# Wofuer das noetig ist: Manche Dienste lehnen Seiten ab, die per Doppelklick
# als file:// geoeffnet wurden. FormSubmit zum Beispiel antwortet dann mit
# "Make sure you open this page through a web server". Mit diesem Server
# laeuft die Seite unter http://localhost:8000 und wird akzeptiert.
#
# Beenden mit Strg+C.
#
use strict;
use warnings;
use IO::Socket::INET;

my $PORT = $ARGV[0] || 8000;
my $ROOT = "/home/jakob/Repos_Privat/website";

my %MIME = (
	html => "text/html; charset=utf-8",
	css  => "text/css; charset=utf-8",
	js   => "text/javascript; charset=utf-8",
	json => "application/json",
	txt  => "text/plain; charset=utf-8",
	jpg  => "image/jpeg",  jpeg => "image/jpeg",
	png  => "image/png",   gif  => "image/gif",
	webp => "image/webp",  avif => "image/avif",
	svg  => "image/svg+xml",
	ico  => "image/x-icon",
);

# Nur auf localhost lauschen - der Server soll nicht im Netz erreichbar sein.
my $sock = IO::Socket::INET->new(
	LocalAddr => "127.0.0.1",
	LocalPort => $PORT,
	Proto     => "tcp",
	Listen    => 16,
	ReuseAddr => 1,
) or die "Port $PORT belegt oder nicht verfuegbar: $!\n";

$| = 1;
print "Laeuft auf http://localhost:$PORT\n";
print "Verzeichnis: $ROOT\n";
print "Beenden mit Strg+C.\n\n";

sub respond {
	my ($client, $status, $type, $body) = @_;
	print $client "HTTP/1.1 $status\r\n";
	print $client "Content-Type: $type\r\n";
	print $client "Content-Length: " . length($body) . "\r\n";
	print $client "Cache-Control: no-store\r\n";   # beim Testen immer frisch
	print $client "Connection: close\r\n\r\n";
	print $client $body;
}

while (my $client = $sock->accept) {
	my $req = <$client>;
	unless (defined $req) { close $client; next; }

	# Restliche Kopfzeilen wegschlucken.
	while (my $l = <$client>) { last if $l =~ /^\r?\n$/; }

	my ($method, $path) = $req =~ m{^(\w+)\s+(\S+)};
	$path = "/" unless defined $path;
	$path =~ s/\?.*$//;
	$path =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/ge;
	$path = "/index.html" if $path eq "/";

	if (!defined $method || $method ne "GET") {
		respond($client, "405 Method Not Allowed", "text/plain", "Nur GET.\n");
		close $client; next;
	}

	# Pfad-Ausbrueche verhindern.
	my $file = "$ROOT$path";
	if ($path =~ m{(^|/)\.\.(/|$)}) {
		respond($client, "403 Forbidden", "text/plain", "Nein.\n");
		close $client; next;
	}

	if (-d $file) { $file =~ s{/?$}{/index.html}; }

	if (-f $file && open(my $fh, "<:raw", $file)) {
		my $body = do { local $/; <$fh> };
		close $fh;
		my ($ext) = $file =~ /\.([^.\/]+)$/;
		my $type = $MIME{lc($ext // "")} || "application/octet-stream";
		respond($client, "200 OK", $type, $body);
		printf("  200  %s\n", $path);
	} else {
		respond($client, "404 Not Found", "text/plain", "Nicht gefunden: $path\n");
		printf("  404  %s\n", $path);
	}

	close $client;
}
