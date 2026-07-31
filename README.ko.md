# BomzhHammer (봄지 해머)

**Languages:** [English](README.md) | [Русский](README.ru.md) | [中文](README.zh-CN.md) | [Español](README.es.md) | [Français](README.fr.md) | [Deutsch](README.de.md) | [Português](README.pt-BR.md) | [العربية](README.ar.md) | [日本語](README.ja.md) | [हिन्दी](README.hi.md) | [한국어](README.ko.md)

**어둡고 풍자적인 유머가 담긴 턴제 카드 전략 게임으로, 홈리스 제국이 도시의 쓰레기 매립지, 기차역, 쓰레기통의 통제권을 두고 싸웁니다.**

> 장르: 턴제 카드 전략. 엔진: Godot 4.2.2 (GDScript). 플랫폼: PC (모바일 우선 1080×1920).

## 소개

BomzhHammer는 플라스틱과 쓰레기 더미로 변해버린 세계를 배경으로 한 단계별 카드 기반 종말 전략 게임입니다. 이념과 종교를 선택하고, 두 덱을 구성하여 도시 영토를 두고 경쟁 제국과 싸우세요. 어조는 풍자적이고 어두우며, 성인을 대상으로 합니다.

## 플레이 방법 (Windows)

1. [Releases](https://github.com/zuluchakahuaka-nwc/BomzhHammer/releases)로 이동하여 [v0.2-alpha 릴리스](https://github.com/zuluchakahuaka-nwc/BomzhHammer/releases/tag/v0.2-alpha)에서 `BomzhHammer_v0.2-alpha.zip`을 다운로드하세요.
2. 아무 곳에나 압축을 푸세요.
3. `Play.bat`을 더블 클릭하면 게임이 실행됩니다.

## 소스에서 실행 (개발자)

```bash
git clone https://github.com/zuluchakahuaka-nwc/BomzhHammer
```

[Godot 4.x](https://godotengine.org/)에서 프로젝트 폴더를 열고 **F5**를 눌러 플레이하세요. 카드 아트는 무료 [Pollinations API](https://pollinations.ai/)를 통해 필요할 때 가져옵니다(API 키 불필요).

## 조작

| 동작 | 조작 |
|------|------|
| 페이즈 종료 / 건너뛰기 | 스페이스 또는 Enter |
| 메인 메뉴 | Esc |
| 카드 사용 | 왼쪽 클릭 |
| 카드 정보 보기 | 오른쪽 클릭 |
| 영토 선택 | 왼쪽 클릭 |
| 언어 | 메뉴의 설정 버튼 |

## 특징

- 두 덱 시스템: 관리/상황 덱 + 전투 유닛 덱
- 32종 유닛, 67장의 상황 카드, 9개 주문, 5명 사령관
- 전략적 도시 지도 위 29개 영토
- 이념 시스템: 알코올 독재 vs 데르모크라티야
- 종교 시스템: Mnogobomzhie, Trezvost, Alcoteism, Etanolstvo
- ATK/DEF/HP 수치와 d6 주사위 굴림으로 해결되는 전투
- AI 상대와 내장된 봇 모드(`--bot`)
- AI 생성 카드 아트(Pollinations API)
- 게임 내 언어: 러시아어 / 영어

## 상태 및 참고

- **활발히 개발 중** (현재 릴리스: `v0.2-alpha`).
- 알코올 중독과 빈곤을 다루는 어두운 풍자 유머; 성인용입니다.

## 라이선스

MIT 라이선스(프로젝트에 명시됨; 저장소에는 `LICENSE` 파일이 없습니다).
