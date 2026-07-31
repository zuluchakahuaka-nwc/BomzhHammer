# BomzhHammer

**Languages:** [English](README.md) | [Русский](README.ru.md) | [中文](README.zh-CN.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Português](README.pt-BR.md) | [العربية](README.ar.md) | [日本語](README.ja.md) | [हिन्दी](README.hi.md) | [한국어](README.ko.md)

**Un juego de estrategia de cartas por turnos con humor satírico negro, donde imperios de personas sin hogar luchan por el control de vertederos, estaciones de tren y contenedores de basura.**

> Género: estrategia de cartas por turnos. Motor: Godot 4.2.2 (GDScript). Plataforma: PC (mobile-first 1080×1920).

## Acerca de

BomzhHammer es una estrategia posapocalíptica de cartas por turnos ambientada en un mundo que se ha convertido en un vertedero de plástico y basura. Elige tu ideología, elige tu religión, construye dos mazos y lucha contra un imperio rival por el control del territorio de la ciudad. El tono es satírico y oscuro, y el juego está pensado para un público adulto.

## Cómo jugar (Windows)

1. Ve a [Releases](https://github.com/zuluchakahuaka-nwc/BomzhHammer/releases) y descarga `BomzhHammer_v0.2-alpha.zip` desde el [lanzamiento v0.2-alpha](https://github.com/zuluchakahuaka-nwc/BomzhHammer/releases/tag/v0.2-alpha).
2. Descomprime el archivo en cualquier lugar.
3. Haz doble clic en `Play.bat` y listo, el juego se inicia.

## Ejecutar desde el código fuente (desarrolladores)

```bash
git clone https://github.com/zuluchakahuaka-nwc/BomzhHammer
```

Abre la carpeta del proyecto en [Godot 4.x](https://godotengine.org/) y pulsa **F5** para jugar. El arte de las cartas se obtiene bajo demanda mediante la API gratuita [Pollinations](https://pollinations.ai/) (no requiere clave de API).

## Controles

| Acción | Control |
|--------|---------|
| Terminar fase / saltar | Espacio o Enter |
| Menú principal | Esc |
| Jugar carta | Clic izquierdo |
| Ver información de la carta | Clic derecho |
| Seleccionar territorio | Clic izquierdo |
| Idioma | Botón de ajustes en el menú |

## Características

- Sistema de dos mazos: mazo de gestión/situaciones + mazo de unidades de combate
- 32 tipos de unidades, 67 cartas de situación, 9 hechizos, 5 comandantes
- 29 territorios en el mapa estratégico de la ciudad
- Sistema de ideologías: Dictadura del Alcohol vs Der'mokratiya
- Sistema de religiones: Mnogobomzhie, Trezvost, Alcoteísmo, Etanolismo
- Combate resuelto con atributos ATK/DEF/HP más una tirada de dado d6
- Oponente IA y un modo bot integrado (`--bot`)
- Arte de cartas generado por IA (API de Pollinations)
- Idiomas del juego: ruso / inglés

## Estado y notas

- **En desarrollo activo** (lanzamiento actual: `v0.2-alpha`).
- Humor satírico oscuro con referencias al alcoholismo y la pobreza; para público adulto.

## Licencia

Licencia MIT (indicada en el proyecto; no hay archivo `LICENSE` en el repositorio).
