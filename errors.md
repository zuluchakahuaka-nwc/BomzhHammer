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
