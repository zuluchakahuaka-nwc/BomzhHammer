"""
tg_server.py — Telegram Mini App сервер для БомжХаммер.

Запуск:
    python telegram/tg_server.py [WEBAPP_URL]

    WEBAPP_URL — публичный HTTPS URL (например от ngrok, cloudflare tunnel, или хостинг).
    Если не указан — бот работает через polling, Flask отдаёт игру на localhost:8080.

Примеры:
    python telegram/tg_server.py                                    # локально
    python telegram/tg_server.py https://abc.ngrok-free.app         # через ngrok
    python telegram/tg_server.py https://bomzhhammer.onrender.com  # на хостинге

Архитектура:
    - Flask: отдаёт HTML5-сборку Godot (telegram/static/)
    - Telegram Bot: через polling (не нужен webhook/public URL)
    - index.html патчится: добавляется telegram-web-app.js
"""

import os
import sys
import json
import threading
import urllib.request
import urllib.error

from flask import Flask, send_from_directory, request as flask_request, jsonify

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(BASE_DIR)
STATIC_DIR = os.path.join(BASE_DIR, "static")
ENV_PATH = os.path.join(BASE_DIR, ".env")

BOT_TOKEN = ""
WEBAPP_URL = ""

app = Flask(__name__, static_folder=STATIC_DIR, static_url_path="")


def load_env():
    token = ""
    url = ""
    if os.path.exists(ENV_PATH):
        with open(ENV_PATH, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if line.startswith("TELEGRAM_BOT_TOKEN="):
                    token = line.split("=", 1)[1].strip()
                elif line.startswith("WEBAPP_URL="):
                    url = line.split("=", 1)[1].strip()
    return token, url


def save_env():
    with open(ENV_PATH, "w", encoding="utf-8") as f:
        f.write(f"TELEGRAM_BOT_TOKEN={BOT_TOKEN}\n")
        f.write(f"WEBAPP_URL={WEBAPP_URL}\n")


def tg_api(method: str, data: dict) -> dict:
    url = f"https://api.telegram.org/bot{BOT_TOKEN}/{method}"
    payload = json.dumps(data).encode("utf-8")
    req = urllib.request.Request(
        url, data=payload, headers={"Content-Type": "application/json"}
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            return json.loads(resp.read().decode("utf-8"))
    except urllib.error.HTTPError as e:
        body = e.read().decode("utf-8", errors="replace")
        print(f"[TG ERROR] {method}: {e.code} {body}")
        return {"ok": False, "error": body}
    except Exception as e:
        print(f"[TG ERROR] {method}: {e}")
        return {"ok": False, "error": str(e)}


def setup_bot():
    r = tg_api("setMyCommands", {
        "commands": [
            {"command": "start", "description": "Начать игру"},
            {"command": "play", "description": "Открыть БомжХаммер"},
        ]
    })
    print(f"[Commands] {'OK' if r.get('ok') else r}")

    if WEBAPP_URL:
        r = tg_api("setMenuButton", {
            "menu_button": {
                "type": "web_app",
                "text": "\U0001F3AE Играть",
                "web_app": {"url": WEBAPP_URL}
            }
        })
        print(f"[MenuButton] {'OK' if r.get('ok') else r}")

    r = tg_api("setMyShortDescription", {
        "short_description": "\U0001F3AE Карточная стратегия о бездомных империях"
    })
    print(f"[ShortDesc] {'OK' if r.get('ok') else r}")

    r = tg_api("setMyDescription", {
        "description": (
            "\U0001F3AE БомжХаммер — пошаговая карточная стратегия\n\n"
            "Сражайся за свалки, вокзалы и помойки!\n"
            "Собирай отряды, разыгрывай заклинания, выбирай идеологию.\n\n"
            "Нажми /play чтобы начать!"
        )
    })
    print(f"[Description] {'OK' if r.get('ok') else r}")


def send_play_button(chat_id: int):
    url = WEBAPP_URL or "http://localhost:8080"
    tg_api("sendMessage", {
        "chat_id": chat_id,
        "text": (
            "\U0001F3AE БомжХаммер\n\n"
            "Карточная стратегия о бездомных империях!\n"
            "Нажми кнопку ниже чтобы играть:"
        ),
        "reply_markup": {
            "inline_keyboard": [[{
                "text": "\U0001F3AE Играть в БомжХаммер",
                "web_app": {"url": url}
            }]]
        }
    })


def polling_loop():
    import time

    print("[Polling] Starting...")
    tg_api("deleteWebhook", {"drop_pending_updates": True})

    offset = 0
    while True:
        try:
            r = tg_api("getUpdates", {
                "offset": offset,
                "timeout": 30,
                "allowed_updates": json.dumps(["message"])
            })
            if r.get("ok") and r.get("result"):
                for update in r["result"]:
                    offset = update["update_id"] + 1
                    msg = update.get("message")
                    if not msg:
                        continue
                    chat_id = msg["chat"]["id"]
                    text = msg.get("text", "")
                    username = msg.get("from", {}).get("username", "?")
                    print(f"[Message] @{username}: {text}")

                    if text.startswith("/start") or text.startswith("/play"):
                        send_play_button(chat_id)
                    elif text:
                        tg_api("sendMessage", {
                            "chat_id": chat_id,
                            "text": "Нажми /play чтобы начать игру!"
                        })
        except Exception as e:
            print(f"[Polling Error] {e}")
            time.sleep(5)


@app.route("/")
def index():
    return send_from_directory(STATIC_DIR, "index.html")


@app.route("/<path:filename>")
def static_files(filename):
    fp = os.path.join(STATIC_DIR, filename)
    if os.path.exists(fp):
        return send_from_directory(STATIC_DIR, filename)
    return "Not found", 404


@app.route("/health")
def health():
    return jsonify(
        status="ok",
        bot_token_set=bool(BOT_TOKEN),
        webapp_url=WEBAPP_URL or "local only"
    )


def copy_build():
    import shutil
    build_src = os.path.join(PROJECT_DIR, "build_web")
    if not os.path.exists(build_src):
        print(f"[WARN] {build_src} not found")
        return False
    if os.path.exists(STATIC_DIR):
        shutil.rmtree(STATIC_DIR)
    shutil.copytree(build_src, STATIC_DIR)
    print(f"[OK] Copied build_web -> telegram/static/")
    return True


def patch_index_html():
    index_path = os.path.join(STATIC_DIR, "index.html")
    if not os.path.exists(index_path):
        return

    with open(index_path, "r", encoding="utf-8") as f:
        html = f.read()

    tg_script = '<script src="https://telegram.org/js/telegram-web-app.js"></script>'
    if tg_script not in html:
        html = html.replace("</head>", f"    {tg_script}\n    </head>")

    tg_init = """
    <script>
    if (window.Telegram && window.Telegram.WebApp) {
        const tg = window.Telegram.WebApp;
        tg.ready();
        tg.expand();
        tg.setHeaderColor('#1a1a1a');
        tg.setBackgroundColor('#000000');
    }
    </script>
"""
    if "Telegram.WebApp" not in html:
        html = html.replace("</body>", f"    {tg_init}\n    </body>")

    with open(index_path, "w", encoding="utf-8") as f:
        f.write(html)
    print("[OK] Patched index.html with Telegram Web App API")


def main():
    global BOT_TOKEN, WEBAPP_URL

    env_token, env_url = load_env()
    BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN", "") or env_token
    WEBAPP_URL = os.environ.get("WEBAPP_URL", "") or env_url

    if len(sys.argv) > 1:
        WEBAPP_URL = sys.argv[1].rstrip("/")

    if not BOT_TOKEN:
        print("[ERROR] No BOT_TOKEN! Set TELEGRAM_BOT_TOKEN env or create telegram/.env")
        sys.exit(1)

    save_env()

    if os.path.exists(os.path.join(STATIC_DIR, "index.html")):
        print(f"[OK] Static files found at {STATIC_DIR}")
        patch_index_html()
    elif not copy_build():
        print("[ERROR] No static files! Run Godot Web export first.")
        sys.exit(1)

    setup_bot()

    bot_thread = threading.Thread(target=polling_loop, daemon=True)
    bot_thread.start()

    print(f"\n{'='*55}")
    print(f"  \U0001F3AE BomzhHammer Telegram Mini App")
    print(f"  Local:   http://localhost:8080")
    if WEBAPP_URL:
        print(f"  Public:  {WEBAPP_URL}")
    else:
        print(f"  Public:  (not set, use argument or .env)")
    print(f"  Bot:     polling mode")
    print(f"  Open @BomzhUnlimBot in Telegram -> /play")
    print(f"{'='*55}\n")

    from werkzeug.serving import run_simple
    run_simple("0.0.0.0", 8080, app)


if __name__ == "__main__":
    main()
