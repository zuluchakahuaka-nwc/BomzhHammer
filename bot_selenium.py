import time
import json
import logging
import sys
import os
import traceback
import threading
from datetime import datetime
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.common.action_chains import ActionChains
from selenium.webdriver.common.keys import Keys
from selenium.common.exceptions import (
    WebDriverException, StaleElementReferenceException,
)

LOG_DIR = os.path.join(os.path.dirname(__file__), "bot_logs")
os.makedirs(LOG_DIR, exist_ok=True)

SESSION_ID = datetime.now().strftime("%Y%m%d_%H%M%S")
LOG_FILE = os.path.join(LOG_DIR, f"bot_{SESSION_ID}.log")
SCREENSHOT_DIR = os.path.join(LOG_DIR, f"ss_{SESSION_ID}")
os.makedirs(SCREENSHOT_DIR, exist_ok=True)

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-7s | %(message)s",
    datefmt="%H:%M:%S",
    handlers=[
        logging.StreamHandler(sys.stdout),
        logging.FileHandler(LOG_FILE, encoding="utf-8"),
    ],
)
log = logging.getLogger("Bot")

GRID = [
    ["romashkovy_proezd", "ulica_trezvyh", "dacha_area", "dumpster_north", "kutuzka", "dumpster_elite"],
    ["dump_west", "street_west", "pereulok_poproshaek", "den_basman", "dump_north", "station_yaroslavsky"],
    ["dumpster_pharmacy", "ulica_pohmelnaya_44", "pereulok_skautov", "station_leningradsky", "station_kazansky", "prospect_avtoritetov"],
    ["dump_south", "obrygalovka", "street_center", "square_three_stations", "prospect_peregarova", "street_east"],
    ["", "den_taganka", "magazin_spirtmaster", "ploschad_pelmenistana", "ulica_djamala", "dump_east"],
]
ROWS, COLS = 5, 6

TNAMES = {
    "dump_west": "Западная", "dump_east": "Восточная", "dump_north": "Северная", "dump_south": "Южная",
    "street_west": "Зап.переулок", "street_east": "Вост.переулок", "street_center": "Похмельная",
    "den_basman": "Притон", "den_taganka": "Сквер", "station_kazansky": "Аллея",
    "station_yaroslavsky": "Шкурников", "station_leningradsky": "Депо",
    "square_three_stations": "Площадь50", "dumpster_north": "МусоркаN",
    "dumpster_elite": "Элит.помойка", "dumpster_pharmacy": "Аптеч.помойка",
    "dacha_area": "Дачи", "obrygalovka": "Обрыгаловка", "kutuzka": "Кутузка",
    "prospect_peregarova": "Перегарова", "pereulok_skautov": "Скаутов",
    "ulica_djamala": "Джамала", "ploschad_pelmenistana": "Пельменистан",
    "ulica_trezvyh": "Трезвых", "prospect_avtoritetov": "Авторитетов",
    "ulica_pohmelnaya_44": "Похмельная44", "pereulok_poproshaek": "Попрошаек",
    "romashkovy_proezd": "Ромашковый", "magazin_spirtmaster": "Спиртмастер",
}

CONNECTIONS_PATH = os.path.join(os.path.dirname(__file__), "data", "maps", "connections.json")
TIMEOUT_SEC = 300

def load_connections():
    with open(CONNECTIONS_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)
    adj = {}
    for c in data:
        a, b = c["from"], c["to"]
        adj.setdefault(a, set()).add(b)
        adj.setdefault(b, set()).add(a)
    return adj

def grid_pos(tid):
    for r, row in enumerate(GRID):
        for c, cell in enumerate(row):
            if cell == tid:
                return r, c
    return None, None


class TimeoutWatcher:
    def __init__(self, limit):
        self.limit = limit
        self.last_action = time.time()
        self.timed_out = False

    def poke(self):
        self.last_action = time.time()

    def check(self):
        if time.time() - self.last_action > self.limit:
            self.timed_out = True
            return True
        return False


class BomzhBot:
    def __init__(self, url="http://localhost:8899/"):
        self.url = url
        self.driver = None
        self.canvas = None
        self.w = 0
        self.h = 0
        self.adj = load_connections()
        self.owned = {"dump_west"}
        self.turn = 0
        self.actions = 0
        self.errors = 0
        self.ss_count = 0
        self.watcher = TimeoutWatcher(TIMEOUT_SEC)

    def _ss(self, label=""):
        self.ss_count += 1
        path = os.path.join(SCREENSHOT_DIR, f"{self.ss_count:03d}_{label}.png")
        try:
            self.driver.save_screenshot(path)
        except Exception as e:
            log.error("Screenshot fail: %s", e)

    def _console(self):
        try:
            entries = self.driver.get_log("browser")
            if entries:
                for e in entries[-10:]:
                    log.info("  [Browser] %s: %s", e.get("level", "?"), e.get("message", "")[:150])
        except Exception:
            pass

    def _find_canvas(self):
        self.canvas = self.driver.find_element(By.TAG_NAME, "canvas")
        self.w = self.canvas.size["width"]
        self.h = self.canvas.size["height"]

    def start(self):
        log.info("=" * 50)
        log.info("BOMZHHAMMER SELENIUM BOT")
        log.info("URL: %s | Timeout: %ds", self.url, TIMEOUT_SEC)
        log.info("Log: %s", LOG_FILE)
        log.info("Screenshots: %s", SCREENSHOT_DIR)
        log.info("=" * 50)

        opts = webdriver.EdgeOptions()
        opts.add_argument("--start-maximized")
        log.info("Launching Edge...")
        self.driver = webdriver.Edge(options=opts)
        self.driver.get(self.url)
        log.info("Page loaded")
        time.sleep(4)
        self._find_canvas()
        self._ss("opened")
        log.info("Canvas: %dx%d", self.w, self.h)

    def click(self, rx, ry, label=""):
        try:
            x = int(rx * self.w - self.w / 2)
            y = int(ry * self.h - self.h / 2)
            ActionChains(self.driver).move_to_element_with_offset(
                self.canvas, x, y
            ).pause(0.05).click().perform()
            self.actions += 1
            self.watcher.poke()
            log.info("  #%d CLICK (%.3f,%.3f) px(%d,%d) %s", self.actions, rx, ry, x, y, label)
        except StaleElementReferenceException:
            self._find_canvas()
            self.click(rx, ry, label)
        except Exception as e:
            self.errors += 1
            log.error("  Click error (%s): %s", label, e)

    def press(self, key, label=""):
        try:
            ActionChains(self.driver).send_keys(key).perform()
            self.actions += 1
            self.watcher.poke()
            log.info("  #%d KEY %s", self.actions, label)
        except Exception as e:
            self.errors += 1
            log.error("  Key error: %s", e)

    def click_tid(self, tid):
        r, c = grid_pos(tid)
        if r is None:
            return
        cw, ch = 0.96 / COLS, 0.74 / ROWS
        rx = 0.02 + (c + 0.5) * cw
        ry = 0.14 + (r + 0.5) * ch
        self.click(rx, ry, TNAMES.get(tid, tid))

    def right_click_tid(self, tid):
        r, c = grid_pos(tid)
        if r is None:
            return
        cw, ch = 0.96 / COLS, 0.74 / ROWS
        rx, ry = 0.02 + (c + 0.5) * cw, 0.14 + (r + 0.5) * ch
        try:
            x = int(rx * self.w - self.w / 2)
            y = int(ry * self.h - self.h / 2)
            ActionChains(self.driver).move_to_element_with_offset(
                self.canvas, x, y
            ).pause(0.05).context_click().perform()
            self.actions += 1
            self.watcher.poke()
            log.info("  #%d RCLICK %s", self.actions, TNAMES.get(tid, tid))
        except Exception as e:
            self.errors += 1
            log.error("  RClick error: %s", e)

    def adjacent_targets(self):
        targets = set()
        for own in self.owned:
            for a in self.adj.get(own, set()):
                if a not in self.owned:
                    targets.add(a)
        return targets

    def dismiss_popups(self):
        for _ in range(2):
            self.press(Keys.SPACE, "dismiss")
            time.sleep(0.3)
            self.click(0.5, 0.55, "dismiss")
            time.sleep(0.3)
            self.press(Keys.ESCAPE, "dismiss")
            time.sleep(0.3)

    def handle_choice(self):
        self.click(0.3, 0.55, "choice1")
        time.sleep(0.2)
        self.click(0.5, 0.55, "choice2")
        time.sleep(0.2)
        self.click(0.7, 0.55, "choice3")
        time.sleep(0.2)
        self.press(Keys.SPACE, "confirm")
        time.sleep(0.3)

    def skip_splash(self):
        log.info("=== SPLASH ===")
        time.sleep(5)
        for i in range(4):
            self.press(Keys.SPACE, "skip splash")
            time.sleep(2)
        self._ss("splash_skipped")

    def main_menu(self):
        log.info("=== MAIN MENU ===")
        time.sleep(2)
        self._ss("main_menu")
        self.press("n", "NewGame_key")
        time.sleep(3)
        self._ss("after_newgame")

    def play_turn(self):
        self.turn += 1
        log.info("=== TURN %d | Owned: %d ===", self.turn, len(self.owned))
        self._find_canvas()
        self._ss("t%d_start" % self.turn)
        self._console()

        targets = self.adjacent_targets()
        log.info("  Targets(%d): %s", len(targets), sorted(targets))

        for i in range(3):
            card_rx = 0.18 + i * 0.09
            self.click(card_rx, 0.82, "card#%d" % i)
            time.sleep(1.2)

            targets = self.adjacent_targets()
            if targets:
                t = sorted(targets)[self.turn % len(sorted(targets))]
                log.info("  Deploy card#%d -> %s", i, TNAMES.get(t, t))
                self.click_tid(t)
                time.sleep(2.5)
                self.owned.add(t)
                log.info("  +OWNED %s (total: %d)", TNAMES.get(t, t), len(self.owned))
                self.dismiss_popups()
            else:
                own = sorted(self.owned)
                if own:
                    self.click_tid(own[0])
                self.press(Keys.ESCAPE, "cancel")
                time.sleep(0.5)

        log.info("  End turn...")
        self.click(0.88, 0.96, "EndTurn")
        time.sleep(3)
        self.dismiss_popups()
        self.handle_choice()
        self._ss("t%d_end" % self.turn)
        self._console()

    def run(self, turns=8):
        try:
            self.start()
            self.skip_splash()
            self.main_menu()

            for t in range(turns):
                if self.watcher.check():
                    log.error("!!! TIMEOUT %ds - no activity !!!", TIMEOUT_SEC)
                    break
                try:
                    self.play_turn()
                except Exception as e:
                    self.errors += 1
                    log.error("Turn %d crashed: %s\n%s", t + 1, e, traceback.format_exc())
                    self._ss("t%d_crash" % (t + 1))
                    self._console()
                    time.sleep(2)
                    self.dismiss_popups()

        except Exception as e:
            log.critical("FATAL: %s\n%s", e, traceback.format_exc())
            if self.driver:
                self._ss("fatal")
                self._console()
        finally:
            log.info("=" * 50)
            log.info("BOT DONE | Turns:%d Actions:%d Errors:%d SS:%d",
                     self.turn, self.actions, self.errors, self.ss_count)
            log.info("Log: %s", LOG_FILE)
            log.info("Screenshots: %s", SCREENSHOT_DIR)
            log.info("=" * 50)
            if self.driver:
                time.sleep(3)
                try:
                    self.driver.quit()
                except Exception:
                    pass


if __name__ == "__main__":
    bot = BomzhBot()
    bot.run(turns=8)
