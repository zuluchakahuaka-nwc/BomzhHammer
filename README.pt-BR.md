# BomzhHammer

**Languages:** [English](README.md) | [Русский](README.ru.md) | [中文](README.zh-CN.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Português](README.pt-BR.md) | [العربية](README.ar.md) | [日本語](README.ja.md) | [हिन्दी](README.hi.md) | [한국어](README.ko.md)

**Um jogo de estratégia de cartas por turnos com humor satírico sombrio, onde impérios de sem-teto lutam pelo controle de lixões, estações de trem e lixeiras.**

> Gênero: estratégia de cartas por turnos. Engine: Godot 4.2.2 (GDScript). Plataforma: PC (mobile-first 1080×1920).

## Sobre

BomzhHammer é uma estratégia pós-apocalíptica de cartas por turnos, ambientada em um mundo que virou um despejo de plástico e lixo. Escolha sua ideologia, escolha sua religião, monte dois decks e lute contra um império rival pelo controle dos territórios da cidade. O tom é satírico e sombrio, e o jogo é destinado a um público adulto.

## Como jogar (Windows)

1. Acesse [Releases](https://github.com/zuluchakahuaka-nwc/BomzhHammer/releases) e baixe `BomzhHammer_v0.2-alpha.zip` do [lançamento v0.2-alpha](https://github.com/zuluchakahuaka-nwc/BomzhHammer/releases/tag/v0.2-alpha).
2. Descompacte o arquivo em qualquer lugar.
3. Dê um duplo clique em `Play.bat` — pronto, o jogo abre.

## Executar a partir do código-fonte (desenvolvedores)

```bash
git clone https://github.com/zuluchakahuaka-nwc/BomzhHammer
```

Abra a pasta do projeto no [Godot 4.x](https://godotengine.org/) e pressione **F5** para jogar. A arte das cartas é obtida sob demanda pela API gratuita [Pollinations](https://pollinations.ai/) (sem chave de API).

## Controles

| Ação | Controle |
|------|----------|
| Encerrar fase / pular | Espaço ou Enter |
| Menu principal | Esc |
| Jogar carta | Clique esquerdo |
| Ver informações da carta | Clique direito |
| Selecionar território | Clique esquerdo |
| Idioma | Botão de ajustes no menu |

## Recursos

- Sistema de dois decks: deck de gestão/situações + deck de unidades de combate
- 32 tipos de unidades, 67 cartas de situação, 9 magias, 5 comandantes
- 29 territórios no mapa estratégico da cidade
- Sistema de ideologias: Ditadura do Álcool vs Der'mokratiya
- Sistema de religiões: Mnogobomzhie, Trezvost, Alcoteísmo, Etanolismo
- Combate resolvido com atributos ATK/DEF/HP mais uma jogada de dado d6
- Oponente de IA e um modo bot integrado (`--bot`)
- Arte de cartas gerada por IA (API Pollinations)
- Idiomas do jogo: russo / inglês

## Status e observações

- **Em desenvolvimento ativo** (lançamento atual: `v0.2-alpha`).
- Humor satírico sombrio com referências a alcoolismo e pobreza; destinado a jogadores adultos.

## Licença

Licença MIT (indicada no projeto; não há arquivo `LICENSE` no repositório).
