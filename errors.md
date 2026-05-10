# errors.md — Решённые проблемы

## 1. Pollinations API: Godot не загружает .jpg через load()

**Симптом:** `load("res://assets/sprites/splash/intro_bg.jpg")` возвращает `null`, ошибка `No loader found for resource`.

**Причина:** Godot не умеет напрямую загружать arbitrary .jpg файлы через `load()` — ему нужен ресурсный формат (.tres, .png с .import).

**Решение:** Использовать `Image.load()` + `ImageTexture.create_from_image()`:
```gdscript
var img := Image.new()
if img.load("res://assets/sprites/splash/intro_bg.jpg") == OK:
    bg.texture = ImageTexture.create_from_image(img)
```
Это обходит кэш ресурсов Godot и читает файл напрямую с диска.

---

## 2. Pollinations API: картинка не обновляется при перегенерации

**Симптом:** Файл .jpg на диске обновился, но Godot показывает старую картинку.

**Причина:** `load()` и `ResourceLoader` кэшируют ресурсы в памяти. Даже если файл на диске изменился, Godot отдаёт закэшированную версию.

**Решение:**
- НЕ использовать `load()` и НЕ создавать .tres файл.
- Использовать `Image.load()` — он читает файл с диска каждый раз, минуя кэш.
- Удалить .tres если он был создан ранее.

---

## 3. Pollinations API: генерирует животных (тигры) вместо свалки

**Симптом:** API возвращает изображения с тиграми или другими животными вместо запрошенной сцены.

**Причина:** API кэширует по промпту. Похожие промпты с "stray dogs", "crows", "wanderer" могут триггерить генерацию животных.

**Решение:**
- Убрать из промпта ВСЕ упоминания животных (dogs, crows, animals, creatures).
- Добавить `seed=$((Get-Random))` в URL для обхода кэша: `?width=768&height=768&nologo=true&seed=$seed`.
- Использовать абстрактные описания (aerial view, industrial, landfill, concrete, steam).
- URL кодировать промпт через `[System.Uri]::EscapeDataString()`.

---

## 4. Pollinations API: всегда возвращает 768x768

**Симптом:** Запрос `width=1280&height=720` возвращает 768x768.

**Причина:** API ограничен размером 768x768, игнорирует параметры width/height.

**Решение:** Принять 768x768 как максимум. Использовать `STRETCH_KEEP_ASPECT_COVERED` в TextureRect для заполнения экрана.

---

## 5. Pollinations API: промпт обрезается / Queue full (50/50)

**Симптом:** Ошибка `Queue full` или `Internal Server Error`, промпт обрезается в URL.

**Причина:** Длинный промпт с русским текстом + спецсимволы не полностью экранируется в URL.

**Решение:**
- Использовать короткие английские промпты.
- Предварительно кодировать: `$encoded = [System.Uri]::EscapeDataString($prompt)`.
- Или заранее закодировать в URL: `Aerial%20drone%20view%20of%20a%20massive%20industrial%20landfill...`.
- При 50/50 подождать минуту и повторить.

---

## 6. Картинка города (city_map.jpg) пропадает во время игры

**Симптом:** Фоновая картинка города на карте исчезает посреди игры, но адреса территорий (кнопки и лейблы) остаются на месте.

**Причина (множественная):**

1. **Перезапись файла.** Файл `city_map.jpg` был перезаписан посторонним изображением (129KB вместо оригинала 161KB, появился тигр). Источник — возможно Pollinations API генерация или ручная ошибка.
2. **Godot import cache рассинхрон.** Файл на диске обновился (9 мая), а `.ctex` кеш остался от 8 мая. `ResourceLoader.load()` отдавал старый кеш или null.
3. **TextureRect — дочерняя нода MapArea.** `MapArea` имеет `clip_contents = true`. При пересчёте layout размер MapArea может кратковременно стать нулевым, TextureRect обнуляется и не восстанавливается. Кнопки и лейблы при этом используют якорные позиции (anchor_*), поэтому не пропадают.
4. **MapBg (ColorRect) перекрывал.** Тёмный ColorRect внутри MapArea на z_index=-1 рисовался поверх `GameMap._draw()`, полностью перекрывая картинку.

**Решение:**

1. **Восстановить файл из бэкапа:** `Copy-Item city_map_backup.jpg city_map.jpg -Force`
2. **Загрузка напрямую с диска** через абсолютный путь, мимо кеша Godot:
```gdscript
func load_city_texture() -> Texture2D:
    var paths = [
        "D:/Projects/BOMZHHAMMER/assets/sprites/map/city_map.jpg",
        "D:/Projects/BOMZHHAMMER/assets/sprites/map/city_map_backup.jpg",
        "res://assets/sprites/map/city_map.jpg"
    ]
    for p in paths:
        var raw := Image.new()
        if raw.load(p) == OK and raw.get_width() > 0:
            return ImageTexture.create_from_image(raw)
    return null
```
3. **Рисовать через `_draw()` на корневом GameMap** — каждый кадр через `queue_redraw()` в `_process()`. Не TextureRect, не дочерняя нода — просто `_draw()`:
```gdscript
var _city_map_tex: Texture2D = null

func _process(_delta):
    queue_redraw()

func _draw():
    if _city_map_tex == null:
        return
    var area_pos := map_area.position
    var area_size := map_area.size
    var tex_size := _city_map_tex.get_size()
    var s := maxf(area_size.x / tex_size.x, area_size.y / tex_size.y)
    var draw_size := tex_size * s
    var offset := area_pos + (area_size - draw_size) * 0.5
    draw_texture_rect(_city_map_tex, Rect2(offset, draw_size), false)
```
4. **Убрать MapBg ColorRect** из `map_builder.gd` — `_draw()` уже обеспечивает фон.
5. **Хранить текстуру в переменной** `_city_map_tex` на GameMap — предотвращает garbage collection.

**Ключевой принцип:** `_draw()` на корневой ноде + `queue_redraw()` каждый кадр = картинка рисуется ВСЕГДА, её невозможно удалить, скрыть или потерять.

---

## 7. Серый экран вместо игры (Parse Error в .gd = тихая смерть сцены)

**Симптом:** Запускаешь игру — видишь только серый экран. Нет кнопок, нет текста, ничего. Консоль (`--headless --script`) не показывает ошибок потому что autoloads грузятся нормально. Но сцена с ошибкой скрипта просто молча не загружается.

**Причина:** Godot глотает SCRIPT ERROR при загрузке сцены. Если `.gd` файл имеет Parse Error (сломанный отступ, необъявленная переменная, пропущенный блок), сцена инстанцируется но скрипт не прикрепляется. Нода существует но пустая — серый фон viewport'а.

**Как найти:**
1. Запустить с `--verbose` — Godot покажет `SCRIPT ERROR: Parse Error` только в verbose-режиме
2. Или запустить `test_screen_lens.gd` — он грузит каждую сцену через `load()` + `instantiate()` и ловит ошибки
3. Обычный `--headless --script test_runner.gd` **НЕ покажет** эту ошибку потому что test_runner не грузит сцены

**Что именно произошло:**
При замене `data.get("name_ru", "")` на `Localization.get_card_name(data)` в `game_map.gd` строка:
```gdscript
if not GameManager.can_afford(cost):
_lm("Cannot afford: %s" % data.get("name_ru", ""))
return
```
заменилась на:
```gdscript
if not GameManager.can_afford(cost):
_lm("Cannot afford: %s" % Localization.get_card_name(data))  # <- отступ не тот!
return
```
`_lm()` оказался на одном уровне с `if`, а не внутри него = Parse Error.

Вторая проблема: `var cost` была объявлена внутри `if is_from_hand:`, а `GameManager.spend(cost)` вызывался снаружи = `cost` вне scope.

**Решение:**
1. `var cost` вынести ДО блока `if`
2. `GameManager.spend(cost)` внести ВНЕ блок `if`
```gdscript
var cost: Dictionary = data.get("cost", {})
if is_from_hand:
    if not GameManager.can_afford(cost):
        _lm("Cannot afford: %s" % Localization.get_card_name(data))
        return
    GameManager.spend(cost)
```

**Правило:** После ЛЮБОГО изменения .gd файла — запускай `test_screen_lens.gd`, не только `test_runner.gd`. test_runner проверяет данные, test_screen_lens проверяет что сцены реально загружаются.

**Предупреждение:** Godot кэширует `.tscn` и `.gd` в `.godot/imported/`. После исправления скрипта удаляй `.godot` папку перед тестом: `Remove-Item -Recurse -Force .godot`

---

## Section 8: Серый/коричневый экран — заставки и фон не загружаются

### Симптомы
- Главное меню: коричневый фон `Color(0.1, 0.08, 0.06)` вместо логотипа/заставки справа
- Карта города: серый экран вместо картинки `city_map.jpg`
- Консоль: `ERROR: Failed loading resource: res://assets/... Make sure resources have been imported by opening the project in the editor at least once.`

### Причина
Godot требует `.godot/imported/` кэш для загрузки `.jpg`, `.png`, `.ttf` через `load()` и `ResourceLoader`. Без кэша все ресурсы падают. Кэш генерируется ТОЛЬКО при открытии проекта в редакторе Godot Editor.

### Решение: SafeLoader (autoload)
Создан `scripts/core/safe_loader.gd` — autoload `SafeLoader`, обходит кэш:
- **SafeLoader.texture(path)** — сначала `load()`, потом `FileAccess` + `Image.load()` + `ImageTexture`
- **SafeLoader.font(path)** — `FontFile.new()` + `load_dynamic_font(path)`, потом `load()`
- **SafeLoader.audio(path)** — `FileAccess.get_file_as_bytes()` + `AudioStreamMP3.data`

Все файлы обновлены: `main_menu.gd`, `splash_screen.gd`, `game_map.gd`, `bot_arena.gd`, `map_builder.gd`, `card_widget.gd`, `card_detail_ui.gd`, `result_popup.gd`, `overlay_ui.gd`, `research_ui.gd`, `battle_anim.gd`, `music_player.gd`

### LensScanner (autoload) — мониторинг экрана
`scripts/core/lens_scanner.gd` — два квадратика в правом верхнем углу:
- **MENU** — сканирует правую часть меню на коричневый `Color(0.1, 0.08, 0.06)`. Если 2/3 точки = фон → заставка слетела → автопочинка (перезагрузка logo через SafeLoader)
- **MAP** — сканирует центр карты на серый. Если 2/3 точки серые → карта города слетела → автопочинка (перезагрузка city_map.jpg)

Важно: `get_tree().current_scene.name` для определения сцены (НЕ первый child root — это autoload Logger).

### Статус: ПОЧИНЕНО. Игра работает без `.godot/imported/` кэша.
