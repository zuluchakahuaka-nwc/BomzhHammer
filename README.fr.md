# BomzhHammer

**Languages:** [English](README.md) | [Русский](README.ru.md) | [中文](README.zh-CN.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Português](README.pt-BR.md) | [العربية](README.ar.md) | [日本語](README.ja.md) | [हिन्दी](README.hi.md) | [한국어](README.ko.md)

**Un jeu de stratégie de cartes au tour par tour avec un humour satirique noir, où des empires de sans-abri se battent pour le contrôle des décharges, des gares et des poubelles.**

> Genre : stratégie de cartes au tour par tour. Moteur : Godot 4.2.2 (GDScript). Plateforme : PC (mobile-first 1080×1920).

## À propos

BomzhHammer est une stratégie de cartes post-apocalyptique au tour par tour, se déroulant dans un monde devenu une décharge de plastique et d'ordures. Choisissez votre idéologie, choisissez votre religion, bâtissez deux decks et affrontez un empire rival pour le contrôle des territoires de la ville. Le ton est satirique et sombre, et le jeu s'adresse à un public adulte.

## Comment jouer (Windows)

1. Allez dans [Releases](https://github.com/zuluchakahuaka-nwc/BomzhHammer/releases) et téléchargez `BomzhHammer_v0.2-alpha.zip` depuis la [version v0.2-alpha](https://github.com/zuluchakahuaka-nwc/BomzhHammer/releases/tag/v0.2-alpha).
2. Décompressez l'archive où vous le souhaitez.
3. Double-cliquez sur `Play.bat` — c'est tout, le jeu se lance.

## Lancer depuis les sources (développeurs)

```bash
git clone https://github.com/zuluchakahuaka-nwc/BomzhHammer
```

Ouvrez le dossier du projet dans [Godot 4.x](https://godotengine.org/) et appuyez sur **F5** pour jouer. Les illustrations des cartes sont récupérées à la demande via l'API gratuite [Pollinations](https://pollinations.ai/) (aucune clé d'API requise).

## Contrôles

| Action | Contrôle |
|--------|----------|
| Terminer la phase / passer | Espace ou Entrée |
| Menu principal | Échap |
| Jouer une carte | Clic gauche |
| Voir les infos d'une carte | Clic droit |
| Sélectionner un territoire | Clic gauche |
| Langue | Bouton Réglages dans le menu |

## Fonctionnalités

- Système à deux decks : deck gestion/situations + deck d'unités de combat
- 32 types d'unités, 67 cartes de situation, 9 sorts, 5 commandants
- 29 territoires sur la carte stratégique de la ville
- Système d'idéologies : Dictature de l'Alcool vs Der'mokratiya
- Système de religions : Mnogobomzhie, Trezvost, Alcoteisme, Etanolstvo
- Combats résolus avec les stats ATK/DEF/HP plus un jet de dé d6
- Adversaire IA et un mode bot intégré (`--bot`)
- Illustrations de cartes générées par IA (API Pollinations)
- Langues du jeu : russe / anglais

## Statut et notes

- **En développement actif** (version actuelle : `v0.2-alpha`).
- Humour satirique noir avec des références à l'alcoolisme et à la pauvreté ; destiné à un public adulte.

## Licence

Licence MIT (indiquée dans le projet ; aucun fichier `LICENSE` n'est présent dans le dépôt).
