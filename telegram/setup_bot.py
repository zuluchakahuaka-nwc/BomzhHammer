"""
setup_bot.py — настройка Telegram-бота для Mini App.

Использование:
    python telegram/setup_bot.py <BOT_TOKEN> <WEBAPP_URL>

Пример:
    python telegram/setup_bot.py 123456:ABC-DEF... https://abc123.ngrok-free.app

Что делает:
    1. Устанавливает кнопку меню бота (открывает Mini App)
    2. Устанавливает описание бота
    3. Сохраняет токен в .env файл
"""

import sys
import json
import urllib.request
import urllib.error
import os


def api_call(token: str, method: str, data: dict) -> dict:
    url = f"https://api.telegram.org/bot{token}/{method}"
    payload = json.dumps(data).encode("utf-8")
    req = urllib.request.Request(
        url, data=payload, headers={"Content-Type": "application/json"}
    )
    with urllib.request.urlopen(req) as resp:
        return json.loads(resp.read().decode("utf-8"))


def set_menu_button(token: str, webapp_url: str):
    result = api_call(token, "setMenuButton", {
        "menu_button": {
            "type": "web_app",
            "text": "Играть",
            "web_app": {
                "url": webapp_url
            }
        }
    })
    return result


def set_bot_commands(token: str):
    result = api_call(token, "setMyCommands", {
        "commands": [
            {"command": "start", "description": "Начать игру"},
            {"command": "play", "description": "Открыть БомжХаммер"},
        ]
    })
    return result


def set_short_description(token: str):
    api_call(token, "setMyShortDescription", {
        "short_description": "БомжХаммер — карточная стратегия о бездомных империях"
    })
    api_call(token, "setMyDescription", {
        "description": "БомжХаммер (BomzhHammer) — пошаговая карточная стратегия.\n\n"
                       "Сражайся за контроль над свалками, вокзалами и помойками!\n"
                       "Собирай отряды бомжей, разыгрывай заклинания, выбирай идеологию."
    })


def save_env(token: str, webapp_url: str):
    env_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), ".env")
    with open(env_path, "w", encoding="utf-8") as f:
        f.write(f"TELEGRAM_BOT_TOKEN={token}\n")
        f.write(f"WEBAPP_URL={webapp_url}\n")
    print(f"[OK] Config saved to {env_path}")


def main():
    if len(sys.argv) < 3:
        print("Usage: python telegram/setup_bot.py <BOT_TOKEN> <WEBAPP_URL>")
        print()
        print("1. Create bot via @BotFather: /newbot")
        print("2. Get token like 123456:ABC-DEF...")
        print("3. Run this script:")
        print("   python telegram/setup_bot.py 123456:ABC-DEF... https://your-server.com")
        sys.exit(1)

    token = sys.argv[1]
    webapp_url = sys.argv[2].rstrip("/")

    print(f"[...] Setting up bot...")

    r1 = set_menu_button(token, webapp_url)
    if r1.get("ok"):
        print(f"[OK] Menu button set -> {webapp_url}")
    else:
        print(f"[FAIL] Menu button: {r1}")

    r2 = set_bot_commands(token)
    if r2.get("ok"):
        print(f"[OK] Bot commands set")
    else:
        print(f"[FAIL] Bot commands: {r2}")

    set_short_description(token)
    print(f"[OK] Bot description set")

    save_env(token, webapp_url)

    print()
    print("=== DONE ===")
    print(f"Now start server:  python telegram/tg_server.py")
    print(f"Bot menu button -> {webapp_url}")


if __name__ == "__main__":
    main()
