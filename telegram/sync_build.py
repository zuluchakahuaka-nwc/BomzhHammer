"""
sync_build.py — копирует build_web/ в telegram/static/ и патчит index.html.

Запуск:
    python telegram/sync_build.py
"""

import os
import shutil

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
PROJECT_DIR = os.path.dirname(BASE_DIR)
BUILD_SRC = os.path.join(PROJECT_DIR, "build_web")
STATIC_DIR = os.path.join(BASE_DIR, "static")


def patch_index_html():
    index_path = os.path.join(STATIC_DIR, "index.html")
    if not os.path.exists(index_path):
        print("[WARN] index.html not found")
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
    print("[OK] Patched with Telegram Web App API")


def main():
    if not os.path.exists(BUILD_SRC):
        print(f"[ERROR] {BUILD_SRC} not found. Export web build first.")
        return

    if os.path.exists(STATIC_DIR):
        shutil.rmtree(STATIC_DIR)
    shutil.copytree(BUILD_SRC, STATIC_DIR)
    print(f"[OK] Copied {BUILD_SRC} -> {STATIC_DIR}")

    patch_index_html()


if __name__ == "__main__":
    main()
