import os

BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN", "")
WEBAPP_URL = os.environ.get("WEBAPP_URL", "")
HOST = "0.0.0.0"
PORT = 8080

STATIC_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "static")
