# BomzhHammer

**Languages:** [English](README.md) | [Русский](README.ru.md) | [中文](README.zh-CN.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Português](README.pt-BR.md) | [العربية](README.ar.md) | [日本語](README.ja.md) | [हिन्दी](README.hi.md) | [한국어](README.ko.md)

**A turn-based card strategy with dark satirical humor where homeless empires fight for control of city dumps, train stations, and garbage bins.**

> Genre: turn-based card strategy. Engine: Godot 4.2.2 (GDScript). Platform: PC (mobile-first 1080×1920).

## About

BomzhHammer is a step-by-step, card-based post-apocalyptic strategy set in a world that has turned into a dump of plastic and trash. Pick your ideology, pick your religion, build two decks, and battle a rival empire for territory across the city. The tone is satirical and dark, and the game is intended for a mature audience.

## How to play (Windows)

1. Go to [Releases](https://github.com/zuluchakahuaka-nwc/BomzhHammer/releases) and download `BomzhHammer_v0.2-alpha.zip` from the [v0.2-alpha release](https://github.com/zuluchakahuaka-nwc/BomzhHammer/releases/tag/v0.2-alpha).
2. Unzip the archive anywhere.
3. Double-click `Play.bat` — that's it, the game launches.

## Run from source (developers)

```bash
git clone https://github.com/zuluchakahuaka-nwc/BomzhHammer
```

Open the project folder in [Godot 4.x](https://godotengine.org/) and press **F5** to play. Card art is fetched on demand via the free [Pollinations API](https://pollinations.ai/) (no API key required).

## Controls

| Action | Control |
|--------|---------|
| End phase / skip | Space or Enter |
| Main menu | Esc |
| Play card | Left click |
| View card info | Right click |
| Select territory | Left click |
| Language | Settings button in the menu |

## Features

- Two-deck system: management/situations deck + combat units deck
- 32 unit types, 67 situation cards, 9 spells, 5 commanders
- 29 territories on the strategic city map
- Ideology system: Alcohol Dictatorship vs Der'mokratiya
- Religion system: Mnogobomzhie, Trezvost, Alcoteism, Etanolstvo
- Combat resolved with ATK/DEF/HP stats plus a d6 dice roll
- AI opponent and a built-in bot mode (`--bot`)
- AI-generated card art (Pollinations API)
- In-game languages: Russian / English

## Status & notes

- **In active development** (current release: `v0.2-alpha`).
- Dark satirical humor with references to alcoholism and poverty; intended for mature players.

## License

MIT License (stated in the project; no `LICENSE` file is present in the repository).
