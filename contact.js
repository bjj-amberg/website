/*
 * Baut E-Mail-Adressen erst im Browser zusammen.
 *
 * Hintergrund: Spam-Harvester durchsuchen den HTML-Quelltext nach dem Muster
 * "benutzer" + at-Zeichen + "domain.de". Steht die Adresse dort im Klartext, landet sie
 * innerhalb von Tagen auf Spam-Listen. Die allerwenigsten Harvester fuehren
 * JavaScript aus - deshalb wird die Adresse hier getrennt hinterlegt und erst
 * zur Laufzeit zusammengesetzt.
 *
 * Verwendung im HTML:
 *   <span data-mail="benutzer|example.de"></span>
 *   <span data-mail="benutzer|example.de" data-mail-text="Schreib uns"></span>
 *
 * Zum Aendern einer Adresse einfach das data-mail-Attribut anpassen -
 * Benutzername und Domain durch einen senkrechten Strich getrennt.
 */
(function () {
	'use strict';

	function render(el) {
		var parts = (el.getAttribute('data-mail') || '').split('|');

		if (parts.length !== 2 || !parts[0] || !parts[1])
			return;

		var address = parts[0] + String.fromCharCode(64) + parts[1],
			link = document.createElement('a');

		link.href = 'mailto:' + address;
		link.textContent = el.getAttribute('data-mail-text') || address;

		// Klassen der Platzhalter uebernehmen, damit das Styling erhalten bleibt.
		if (el.className)
			link.className = el.className;

		el.parentNode.replaceChild(link, el);
	}

	function init() {
		var nodes = document.querySelectorAll('[data-mail]');

		for (var i = 0; i < nodes.length; i++)
			render(nodes[i]);
	}

	if (document.readyState === 'loading')
		document.addEventListener('DOMContentLoaded', init);
	else
		init();
})();
