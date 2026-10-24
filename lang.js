/*
 * Sprachumschaltung Deutsch / Englisch.
 *
 * So funktioniert es:
 *   Beide Sprachen stehen gleichzeitig im HTML, jeweils in einem Element mit
 *   lang="de" bzw. lang="en". Welche davon sichtbar ist, entscheidet das CSS
 *   anhand des Attributs data-lang am <html>-Element. Dieses Skript setzt nur
 *   dieses eine Attribut.
 *
 * Warum so und nicht per Textaustausch?
 *   Weil das Umschalten dann das CSS erledigt und nicht JavaScript. Das Skript
 *   laeuft als blockierendes <script> im <head>, also bevor der Browser den
 *   Body zeichnet - dadurch steht von der ersten Bildschirmausgabe an die
 *   richtige Sprache da. Es blitzt nichts auf und nichts springt um.
 *
 * Ohne JavaScript:
 *   Im HTML steht fest data-lang="de", also bleibt die Seite auf Deutsch
 *   lesbar. Es verschwindet nur die Umschaltmoeglichkeit.
 *
 * Reihenfolge der Spracherkennung:
 *   1. Was der Besucher zuletzt selbst gewaehlt hat (localStorage)
 *   2. Die Spracheinstellung des Browsers
 *   3. Englisch
 */
(function () {
	'use strict';

	var KEY = 'bjj-amberg-lang';
	var SUPPORTED = ['de', 'en'];
	var root = document.documentElement;

	function readStored() {
		// Im privaten Modus kann der Zugriff eine Exception werfen.
		try { return window.localStorage.getItem(KEY); } catch (e) { return null; }
	}

	function writeStored(lang) {
		try { window.localStorage.setItem(KEY, lang); } catch (e) { /* egal */ }
	}

	function detect() {
		var saved = readStored();
		if (SUPPORTED.indexOf(saved) !== -1)
			return saved;

		var prefs = navigator.languages || [navigator.language || navigator.userLanguage || ''];
		for (var i = 0; i < prefs.length; i++) {
			var p = String(prefs[i]).toLowerCase();
			if (p.indexOf('de') === 0) return 'de';
			if (p.indexOf('en') === 0) return 'en';
		}

		// Weder Deutsch noch Englisch eingestellt: Englisch ist die
		// international verstaendlichere Variante.
		return 'en';
	}

	function apply(lang) {
		if (SUPPORTED.indexOf(lang) === -1) lang = 'de';

		root.setAttribute('data-lang', lang);
		root.setAttribute('lang', lang);

		var title = root.getAttribute('data-title-' + lang);
		if (title) document.title = title;

		// Nur die Knoepfe im Umschalter bekommen den Aktiv-Zustand. Links mit
		// data-set-lang im Fliesstext (etwa "zur deutschen Fassung") werden
		// zwar angeklickt, sollen aber ihr eigenes Styling behalten.
		var buttons = document.querySelectorAll(".lang-switch [data-set-lang]");
		for (var i = 0; i < buttons.length; i++) {
			var active = buttons[i].getAttribute("data-set-lang") === lang;
			buttons[i].setAttribute("aria-pressed", active ? "true" : "false");
			buttons[i].className = active ? "is-active" : "";
		}
	}

	// Sofort setzen, noch bevor der Body gezeichnet wird.
	apply(detect());

	function wireButtons() {
		var buttons = document.querySelectorAll('[data-set-lang]');
		for (var i = 0; i < buttons.length; i++) {
			buttons[i].addEventListener('click', function (event) {
				event.preventDefault();
				var lang = this.getAttribute('data-set-lang');
				if (SUPPORTED.indexOf(lang) === -1) return;
				writeStored(lang);
				apply(lang);
			});
		}
		// Nochmal anwenden, damit die Knoepfe ihren aktiven Zustand bekommen -
		// beim ersten Aufruf oben gab es sie im DOM noch nicht.
		apply(root.getAttribute('data-lang') || 'de');
	}

	if (document.readyState === 'loading')
		document.addEventListener('DOMContentLoaded', wireButtons);
	else
		wireButtons();
})();
