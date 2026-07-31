# BomzhHammer

**Languages:** [English](README.md) | [Русский](README.ru.md) | [中文](README.zh-CN.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Português](README.pt-BR.md) | [العربية](README.ar.md) | [日本語](README.ja.md) | [हिन्दी](README.hi.md) | [한국어](README.ko.md)

**Ein rundenbasiertes Kartenspiel mit bösem, satirischem Humor, in dem Obdachlosen-Imperien um die Kontrolle über städtische Mülldeponien, Bahnhöfe und Mülleimer kämpfen.**

> Genre: rundenbasierte Kartenstrategie. Engine: Godot 4.2.2 (GDScript). Plattform: PC (mobile-first 1080×1920).

## Über das Spiel

BomzhHammer ist eine rundenbasierte, kartenbasierte Postapokalypse-Strategie, angesiedelt in einer Welt, die zu einer Deponie aus Plastik und Müll geworden ist. Wähle deine Ideologie, wähle deine Religion, baue zwei Decks und kämpfe gegen ein rivalisierendes Imperium um die Stadtgebiete. Der Ton ist satirisch und düster, das Spiel richtet sich an ein erwachsenes Publikum.

## So wird gespielt (Windows)

1. Gehe zu [Releases](https://github.com/zuluchakahuaka-nwc/BomzhHammer/releases) und lade `BomzhHammer_v0.2-alpha.zip` aus dem [Release v0.2-alpha](https://github.com/zuluchakahuaka-nwc/BomzhHammer/releases/tag/v0.2-alpha) herunter.
2. Entpacke das Archiv an einen beliebigen Ort.
3. Doppelklicke auf `Play.bat` — das war's, das Spiel startet.

## Aus dem Quellcode starten (Entwickler)

```bash
git clone https://github.com/zuluchakahuaka-nwc/BomzhHammer
```

Öffne den Projektordner in [Godot 4.x](https://godotengine.org/) und drücke **F5**, um zu spielen. Das Kartenbildmaterial wird bei Bedarf über die kostenlose [Pollinations-API](https://pollinations.ai/) geladen (kein API-Schlüssel erforderlich).

## Steuerung

| Aktion | Steuerung |
|--------|-----------|
| Phase beenden / überspringen | Leertaste oder Enter |
| Hauptmenü | Esc |
| Karte ausspielen | Linksklick |
| Karteninfo anzeigen | Rechtsklick |
| Territorium auswählen | Linksklick |
| Sprache | Einstellungen-Button im Menü |

## Funktionen

- Zwei-Deck-System: Verwaltungs-/Situationsdeck + Kampfeinheiten-Deck
- 32 Einheitentypen, 67 Situationenkarten, 9 Zauber, 5 Kommandeure
- 29 Gebiete auf der strategischen Stadtkarte
- Ideologiesystem: Alkohol-Diktatur vs. Der'mokratiya
- Religionssystem: Mnogobomzhie, Trezvost, Alcoteismus, Etanolismus
- Kampf über ATK/DEF/HP-Werte plus einem d6-Würfelwurf
- KI-Gegner und ein integrierter Bot-Modus (`--bot`)
- KI-generiertes Kartenbildmaterial (Pollinations-API)
- Im Spiel verfügbare Sprachen: Russisch / Englisch

## Status und Hinweise

- **In aktiver Entwicklung** (aktueller Release: `v0.2-alpha`).
- Düsterer, satirischer Humor mit Anspielungen auf Alkoholismus und Armut; für erwachsene Spieler.

## Lizenz

MIT-Lizenz (im Projekt angegeben; im Repository ist keine `LICENSE`-Datei vorhanden).
