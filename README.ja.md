# BomzhHammer（ボムジ・ハンマー）

**Languages:** [English](README.md) | [Русский](README.ru.md) | [中文](README.zh-CN.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Português](README.pt-BR.md) | [العربية](README.ar.md) | [日本語](README.ja.md) | [हिन्दी](README.hi.md) | [한국어](README.ko.md)

**ブラックな風刺の効いたターン制カード戦略ゲーム。ホームレスの帝国が、都市のゴミ捨て場、駅、ゴミ箱の支配をめぐって戦う。**

> ジャンル：ターン制カード戦略。エンジン：Godot 4.2.2 (GDScript)。プラットフォーム：PC（モバイルファースト 1080×1920）。

## 概要

BomzhHammer は、プラスチックとゴミの山へと変わり果てた世界を舞台にした、ステップ式のカードベース終末戦略ゲームです。イデオロギーと宗教を選び、2 つのデッキを組み、ライバル帝国と都市の領土を争います。風刺的でダークな作風で、成人向けの内容です。

## 遊び方（Windows）

1. [Releases](https://github.com/zuluchakahuaka-nwc/BomzhHammer/releases) を開き、[v0.2-alpha リリース](https://github.com/zuluchakahuaka-nwc/BomzhHammer/releases/tag/v0.2-alpha)から `BomzhHammer_v0.2-alpha.zip` をダウンロードします。
2. 好きな場所に解凍します。
3. `Play.bat` をダブルクリック — これだけでゲームが起動します。

## ソースから実行する（開発者向け）

```bash
git clone https://github.com/zuluchakahuaka-nwc/BomzhHammer
```

[Godot 4.x](https://godotengine.org/) でプロジェクトフォルダーを開き、**F5** を押してプレイします。カードのアートは、無料の [Pollinations API](https://pollinations.ai/) で必要に応じて取得されます（API キー不要）。

## 操作

| アクション | 操作 |
|------------|------|
| フェーズ終了 / スキップ | スペースまたは Enter |
| メインメニュー | Esc |
| カードを出す | 左クリック |
| カード情報を見る | 右クリック |
| 領土を選ぶ | 左クリック |
| 言語 | メニューの設定ボタン |

## 特徴

- 2 デッキシステム：管理／状況デッキ + 戦闘ユニットデッキ
- 32 種のユニット、67 枚の状況カード、9 個の呪文、5 人の指揮官
- 戦略的都市マップ上の 29 の領土
- イデオロギーシステム：アルコール独裁 vs デルモクラツィア
- 宗教システム：Mnogobomzhie、Trezvost、Alcoteism、Etanolstvo
- ATK/DEF/HP の数値に d6 のダイスロールを加えた戦闘解決
- AI 対戦相手と内蔵ボットモード（`--bot`）
- AI 生成のカードアート（Pollinations API）
- ゲーム内言語：ロシア語 / 英語

## 状態と注意

- **鋭意開発中**（現在のリリース：`v0.2-alpha`）。
- アルコール依存や貧困への言及を含むダークな風刺ユーモアあり。成人向けです。

## ライセンス

MIT ライセンス（プロジェクト内で明記。リポジトリに `LICENSE` ファイルは存在しません）。
