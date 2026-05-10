<!-- README for GitHub -->

[English](#bomzhhammer) | [Русский](#-описание-2) | [中文](#-说明-2)

> **This README is intended for GitHub publication.**

# BomzhHammer

![Status](https://img.shields.io/badge/status-in%20development-yellow)
![Engine](https://img.shields.io/badge/engine-Godot%204.x-478CBF)
![Language](https://img.shields.io/badge/language-GDScript-478CBF)
![Platforms](https://img.shields.io/badge/platforms-Mobile%20%7C%20PC-lightgrey)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

**БомжХаммер** — a turn-based card strategy game with dark satirical humor. Command homeless empires battling for control of city dumps, train stations, and garbage bins. Choose your ideology. Choose your religion. Survive the streets.

Inspired by the same engine patterns as [Civil War: Blue & Gray](https://github.com/your-org/civil-war-blue-gray).

---

## Features

- **Dark satirical setting** — Homeless empires fight for territorial dominance over dumps, train stations, and garbage bins
- **Two-deck system** — Management/situations deck + combat units deck for strategic depth
- **Ideology system** — *Alcoholism* vs *Der'mokratiya* — each ideology grants different bonuses and unlocks unique cards
- **Religion system** — *Mnogobomzhie* vs *Trezvost'* — faith-based mechanics that influence morale and special abilities
- **Territory capture** — Fight for control of city locations on a strategic map
- **Combat resolution** — ATK/DEF/HP stats + d6 dice rolls for unpredictable encounters
- **Spell system** — Cast powerful spells to turn the tide of battle
- **Quest chains** — Multi-stage quests with narrative progression and rewards
- **Achievements** — Track your accomplishments across campaigns
- **AI opponent** — Battle against a computer-controlled rival empire
- **AI-generated card art** — Uses the free [Pollinations API](https://pollinations.ai/) (no API key required)
- **Mobile-first design** — Primary resolution 1080×1920, with PC support

## Tech Stack

| Layer | Technology |
|---|---|
| Engine | Godot 4.x |
| Language | GDScript |
| Card Art | AI-generated via Pollinations API (free, no key) |
| Data Format | JSON |
| Resolution | 1080×1920 (mobile), scales for PC |

## Installation

### Prerequisites

- [Godot 4.x](https://godotengine.org/) editor
- Internet connection (for AI card art generation via Pollinations)

### Build from Source

```bash
git clone https://github.com/your-org/bomzhhammer.git
cd bomzhhammer

# Open the project in Godot 4.x editor
# File -> Open Project -> select the project folder
```

### AI Card Art Generation

Card art is generated on-the-fly using the **Pollinations API**, which is completely free and requires no API key:

```
https://image.pollinations.ai/prompt/{description}
```

Art is generated when cards are first viewed or when explicitly triggered. No configuration or authentication needed.

## Project Structure

```
├── scenes/
│   ├── main_menu/           # Main menu
│   ├── battle/              # Battle screen and card resolution
│   ├── map/                 # City territory map
│   ├── deck_builder/        # Deck management screens
│   └── quest/               # Quest chain UI
├── scripts/
│   ├── card_system/         # Card logic, two-deck management
│   ├── combat/              # Combat engine (ATK/DEF/HP + d6)
│   ├── ai/                  # AI opponent logic
│   ├── ideology/            # Ideology system (Alcoholism / Der'mokratiya)
│   ├── religion/            # Religion system (Mnogobomzhie / Trezvost')
│   ├── spells/              # Spell system
│   ├── quests/              # Quest chain logic
│   ├── territory/           # Map and territory capture
│   └── art_generator/       # Pollinations API integration
├── data/
│   ├── units/               # Unit card definitions (JSON)
│   ├── situations/          # Situation/event cards (JSON)
│   ├── spells/              # Spell definitions (JSON)
│   ├── quests/              # Quest chain data (JSON)
│   ├── territories/         # Map location data (JSON)
│   └── achievements/        # Achievement definitions (JSON)
├── assets/
│   ├── ui/                  # UI elements
│   ├── maps/                # City map graphics
│   └── generated_art/       # Cached AI-generated card art
├── localization/
│   ├── en.json              # English strings
│   └── ru.json              # Russian strings
└── project.godot            # Godot project configuration
```

## Game Mechanics

### Two-Deck System
Players manage two separate decks:
- **Management/Situations Deck** — Events, resource management, political maneuvers
- **Combat Units Deck** — Fighters, defenders, and special characters for direct confrontations

### Ideology: Alcoholism vs Der'mokratiya
Your chosen ideology shapes available cards, passive bonuses, and strategic options. Each ideology has a full progression tree.

### Religion: Mnogobomzhie vs Trezvost'
Faith mechanics add another layer of strategy. Religious choices affect morale regeneration, spell availability, and unique unit unlocks.

### Combat
Each engagement uses unit ATK/DEF/HP stats combined with a d6 dice roll. The formula accounts for terrain, morale, ideology bonuses, and spell effects for rich tactical gameplay.

## Localization

| Language | Status |
|---|---|
| Russian | In progress |
| English | In progress |

## Related Projects

- **[Civil War: Blue & Gray](https://github.com/your-org/civil-war-blue-gray)** — Turn-based card strategy game sharing the same engine patterns. BomzhHammer builds on CWG's architecture.

## Current Status

The game is **in active development**. Core systems (two-deck, combat, territory capture) are functional. Ideology, religion, quest chains, and AI are being refined.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## 🇷🇺 Описание

**БомжХаммер** — пошаговая карточная стратегия с мрачным сатирическим юмором. Командуйте империями бездомных, сражающимися за контроль над городскими свалками, вокзалами и мусорными баками. Выберите свою идеологию. Выберите свою религию. Выживите на улицах.

Игра создана на тех же архитектурных паттернах, что и [Civil War: Blue & Gray](https://github.com/your-org/civil-war-blue-gray).

### Возможности

- **Мрачная сатирическая стилистика** — Империи бездомных сражаются за территориальное господство над свалками, вокзалами и мусорными баками
- **Система двух колод** — Колода управления/ситуаций + колода боевых отрядов для стратегической глубины
- **Система идеологий** — *Алкоголизм* против *Дерьмократии* — каждая идеология даёт разные бонусы и открывает уникальные карты
- **Система религий** — *Многобомжие* против *Трезвости* — механики веры, влияющие на мораль и специальные способности
- **Захват территорий** — Борьба за контроль над городскими локациями на стратегической карте
- **Боевая система** — Характеристики ATK/DEF/HP + бросок кубика d6 для непредсказуемых столкновений
- **Система заклинаний** — Применяйте мощные заклинания, чтобы переломить ход боя
- **Цепочки квестов** — Многоэтапные задания с сюжетным прогрессом и наградами
- **Достижения** — Отслеживайте свои успехи в кампаниях
- **AI-противник** — Сражайтесь с компьютерным противником
- **ИИ-генерация арта карт** — Использует бесплатный [Pollinations API](https://pollinations.ai/) (без API-ключа)
- **Mobile-first дизайн** — Основное разрешение 1080×1920 с поддержкой ПК

### Технологический стек

| Слой | Технология |
|---|---|
| Движок | Godot 4.x |
| Язык | GDScript |
| Генерация арта | ИИ через Pollinations API (бесплатно, без ключа) |
| Формат данных | JSON |
| Разрешение | 1080×1920 (мобильные), масштабируется для ПК |

### Установка

```bash
git clone https://github.com/your-org/bomzhhammer.git
cd bomzhhammer
# Откройте проект в редакторе Godot 4.x
```

### Структура проекта

```
├── scenes/          # Сцены: меню, бой, карта, сборка колоды, квесты
├── scripts/         # Скрипты: карты, бой, ИИ, идеологии, религии, заклинания
├── data/            # JSON-данные: отряды, ситуации, заклинания, квесты, территории
├── assets/          # Ресурсы: UI, карта города, сгенерированный арт
├── localization/    # Локализация: en.json, ru.json
└── project.godot    # Конфигурация проекта Godot
```

### Текущий статус

Игра находится **в активной разработке**. Основные системы (две колоды, бой, захват территорий) работают. Идеологии, религии, цепочки квестов и ИИ дорабатываются.

---

## 🇨🇳 说明

**BomzhHammer（流浪汉之锤）** — 具有黑色讽刺幽默的回合制卡牌策略游戏。指挥流浪汉帝国，争夺城市垃圾场、火车站和垃圾桶的控制权。选择你的意识形态。选择你的信仰。在街头生存下去。

游戏引擎架构与 [Civil War: Blue & Gray](https://github.com/your-org/civil-war-blue-gray) 相同。

### 游戏特色

- **黑色讽刺设定** — 流浪汉帝国为争夺垃圾场、火车站和垃圾桶的领土控制权而战
- **双牌组系统** — 管理/情境牌组 + 战斗单位牌组，提供策略深度
- **意识形态系统** — *酒精主义* 对抗 *Der'mokratiya（屎主）* — 每种意识形态提供不同加成并解锁独特卡牌
- **宗教系统** — *多流浪汉神教* 对抗 *清醒派* — 基于信仰的机制影响士气和特殊能力
- **领土攻占** — 在战略地图上争夺城市地段的控制权
- **战斗解决** — ATK/DEF/HP属性 + d6骰子掷点，带来不可预测的遭遇战
- **法术系统** — 施放强力法术扭转战局
- **任务链** — 具有剧情推进和奖励的多阶段任务
- **成就系统** — 追踪你在战役中的成就
- **AI对手** — 与电脑控制的敌对帝国对战
- **AI生成卡牌美术** — 使用免费的[Pollinations API](https://pollinations.ai/)（无需API密钥）
- **移动端优先设计** — 主分辨率1080×1920，同时支持PC

### 技术栈

| 层级 | 技术 |
|---|---|
| 引擎 | Godot 4.x |
| 语言 | GDScript |
| 卡牌美术 | 通过Pollinations API AI生成（免费，无需密钥） |
| 数据格式 | JSON |
| 分辨率 | 1080×1920（移动端），PC自适应缩放 |

### 安装

```bash
git clone https://github.com/your-org/bomzhhammer.git
cd bomzhhammer
# 在Godot 4.x编辑器中打开项目
```

### 项目结构

```
├── scenes/          # 场景：菜单、战斗、地图、牌组构建、任务
├── scripts/         # 脚本：卡牌、战斗、AI、意识形态、宗教、法术
├── data/            # JSON数据：单位、情境、法术、任务、领土
├── assets/          # 资源：UI、城市地图、AI生成美术
├── localization/    # 本地化：en.json, ru.json
└── project.godot    # Godot项目配置
```

### 当前状态

游戏**正在积极开发中**。核心系统（双牌组、战斗、领土攻占）可正常运行。意识形态、宗教、任务链和AI正在完善中。
