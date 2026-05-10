extends Control

const CardWidgetScript := preload("res://scripts/ui/card_widget.gd")

@onready var back_btn: Button = $TopBar/BackBtn
@onready var progress: Label = $TopBar/Progress
@onready var btn_all: Button = $FilterHBox/BtnAll
@onready var btn_units: Button = $FilterHBox/BtnUnits
@onready var btn_situations: Button = $FilterHBox/BtnSituations
@onready var btn_spells: Button = $FilterHBox/BtnSpells
@onready var btn_commanders: Button = $FilterHBox/BtnCommanders
@onready var card_display: Control = $CardArea/CardDisplay
@onready var prev_btn: Button = $PrevBtn
@onready var next_btn: Button = $NextBtn
@onready var card_name: Label = $InfoPanel/CardName
@onready var card_id: Label = $InfoPanel/CardId
@onready var card_stats: Label = $InfoPanel/CardStats
@onready var card_desc: Label = $InfoPanel/CardDesc
@onready var btn_y: Button = $BottomBar/BtnY
@onready var btn_n: Button = $BottomBar/BtnN
@onready var status_log: RichTextLabel = $StatusLog

var _all_cards: Array = []
var _filtered: Array = []
var _current_idx: int = 0
var _current_filter: String = "all"
var _card_widget: Control = null

func _ready() -> void:
	back_btn.pressed.connect(_on_back)
	btn_all.pressed.connect(func() -> void: _set_filter("all"))
	btn_units.pressed.connect(func() -> void: _set_filter("unit"))
	btn_situations.pressed.connect(func() -> void: _set_filter("situation"))
	btn_spells.pressed.connect(func() -> void: _set_filter("spell"))
	btn_commanders.pressed.connect(func() -> void: _set_filter("commander"))
	prev_btn.pressed.connect(_on_prev)
	next_btn.pressed.connect(_on_next)
	btn_y.pressed.connect(_on_y)
	btn_n.pressed.connect(_on_n)
	call_deferred("_load_cards")

func _load_cards() -> void:
	_all_cards.clear()
	for u in CardDatabase._units.values():
		_all_cards.append(u)
	for s in CardDatabase._situations.values():
		_all_cards.append(s)
	for sp in CardDatabase._spells.values():
		_all_cards.append(sp)
	for c in CardDatabase._commanders.values():
		_all_cards.append(c)
	_log("Загружено карт: %d" % _all_cards.size())
	_set_filter("all")

func _set_filter(filter: String) -> void:
	_current_filter = filter
	_filtered.clear()
	for c in _all_cards:
		if filter == "all" or c.get("type", "") == filter:
			_filtered.append(c)
	_current_idx = 0
	_log("Фильтр: %s — %d карт" % [filter, _filtered.size()])
	_show_current()

func _show_current() -> void:
	if _card_widget != null:
		_card_widget.queue_free()
		_card_widget = null
	progress.text = "%d/%d" % [_current_idx + 1, _filtered.size()]
	if _filtered.is_empty():
		card_name.text = "Нет карт"
		card_id.text = ""
		card_stats.text = ""
		card_desc.text = ""
		return
	var data: Dictionary = _filtered[_current_idx]
	var widget := Control.new()
	widget.set_script(CardWidgetScript)
	widget.name = "ReviewCard"
	widget.custom_minimum_size = Vector2(300, 450)
	widget.size = Vector2(300, 450)
	widget.mouse_filter = Control.MOUSE_FILTER_IGNORE
	widget.position = Vector2(-150, -225)
	card_display.add_child(widget)
	widget.setup(data)
	_card_widget = widget
	card_name.text = data.get("name_ru", "")
	card_name.add_theme_font_size_override("font_size", 32)
	card_name.add_theme_color_override("font_color", Color(0, 0, 0))
	card_name.add_theme_color_override("font_outline_color", Color(1, 1, 1))
	card_name.add_theme_constant_override("outline_size", 5)
	card_id.text = "ID: %s | Тип: %s | Редкость: %s" % [data.get("id", ""), data.get("type", ""), data.get("rarity", "")]
	if data.get("type", "") == "unit":
		card_stats.text = "ATK:%d DEF:%d HP:%d MOV:%d NAG:%d" % [data.get("attack",0), data.get("defense",0), data.get("hp",0), data.get("movement",1), data.get("naglost",0)]
	else:
		card_stats.text = "Эффект: %s | Кол-во: %d" % [data.get("effect_type", ""), data.get("amount", 0)]
	card_desc.text = data.get("description_ru", "")

func _on_prev() -> void:
	if _filtered.is_empty():
		return
	_current_idx = (_current_idx - 1) % _filtered.size()
	if _current_idx < 0:
		_current_idx = _filtered.size() - 1
	_show_current()

func _on_next() -> void:
	if _filtered.is_empty():
		return
	_current_idx = (_current_idx + 1) % _filtered.size()
	_show_current()

func _on_y() -> void:
	if _filtered.is_empty():
		return
	var data: Dictionary = _filtered[_current_idx]
	_log("[color=green]Y %s — %s[/color]" % [data.get("id", ""), data.get("name_ru", "")])
	_on_next()

func _on_n() -> void:
	if _filtered.is_empty():
		return
	var data: Dictionary = _filtered[_current_idx]
	var card_id: String = data.get("id", "")
	var card_type: String = data.get("type", "unit")
	var name_ru: String = data.get("name_ru", "")
	_log("[color=yellow]Перегенерация %s — %s...[/color]" % [card_id, name_ru])
	var sub: String = "units"
	match card_type:
		"situation": sub = "situations"
		"spell": sub = "spells"
		"commander": sub = "commanders"
	var style: String = "Dark satirical 2D illustration, post-soviet underground style, caricature, muted dirty colors, cardboard and trash aesthetic. "
	var desc: String = data.get("description_ru", name_ru)
	var prompt_text: String = style + desc
	var prompt_encoded: String = prompt_text.uri_encode()
	var url: String = "https://image.pollinations.ai/prompt/%s?width=512&height=768&nologo=true" % prompt_encoded
	var out_path: String = "res://assets/sprites/cards/%s/%s.jpg" % [sub, card_id]
	var local_path: String = "D:/Projects/BOMZHHAMMER/assets/sprites/cards/%s/%s.jpg" % [sub, card_id]
	_log("URL: %s" % url)
	var http := HTTPRequest.new()
	add_child(http)
	http.request_completed.connect(_on_image_generated.bind(card_id, name_ru, local_path))
	var err: int = http.request(url)
	if err != OK:
		_log("[color=red]Ошибка HTTP: %d[/color]" % err)
		http.queue_free()

func _on_image_generated(result: int, code: int, headers: PackedStringArray, body: PackedByteArray, card_id: String, name_ru: String, local_path: String) -> void:
	var http: Node = get_node_or_null("HTTPRequest")
	if http:
		http.queue_free()
	if code == 200 and body.size() > 1000:
		var f := FileAccess.open(local_path, FileAccess.WRITE)
		if f:
			f.store_buffer(body)
			f.close()
		_log("[color=green]Готово: %s — %s (%d KB)[/color]" % [card_id, name_ru, body.size() / 1024])
		_show_current()
	else:
		_log("[color=red]Ошибка генерации %s: code=%d size=%d[/color]" % [card_id, code, body.size()])

func _log(msg: String) -> void:
	status_log.append_text(msg + "\n")

func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
