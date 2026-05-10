extends Control

const BotPlayerScript := preload("res://scripts/ui/bot_player.gd")
const BattleResolverScript := preload("res://scripts/combat/battle_resolver.gd")

@onready var map_area: Control = $MapArea
@onready var turn_label: Label = $TopBar/HBox/TurnLabel
@onready var phase_label: Label = $TopBar/HBox/PhaseLabel
@onready var speed_1x: Button = $TopBar/HBox/Speed1x
@onready var speed_2x: Button = $TopBar/HBox/Speed2x
@onready var speed_4x: Button = $TopBar/HBox/Speed4x
@onready var pause_btn: Button = $TopBar/HBox/PauseBtn
@onready var blue_name: Label = $BluePanel/VBox/NameLabel
@onready var blue_res: Label = $BluePanel/VBox/ResLabel
@onready var blue_units: Label = $BluePanel/VBox/UnitsLabel
@onready var blue_terr: Label = $BluePanel/VBox/TerrLabel
@onready var blue_hand: HBoxContainer = $BluePanel/VBox/HandPreview
@onready var red_name: Label = $RedPanel/VBox/NameLabel
@onready var red_res: Label = $RedPanel/VBox/ResLabel
@onready var red_units: Label = $RedPanel/VBox/UnitsLabel
@onready var red_terr: Label = $RedPanel/VBox/TerrLabel
@onready var red_hand: HBoxContainer = $RedPanel/VBox/HandPreview
@onready var log_rich: RichTextLabel = $LogPanel/LogRich
@onready var anim_layer: Control = $AnimLayer

var _bot_a: RefCounted = null
var _bot_b: RefCounted = null
var _territory_buttons: Dictionary = {}
var _territory_labels: Dictionary = {}
var _speed: float = 1.0
var _paused: bool = false
var _running: bool = false
var _turn: int = 1
var _max_turns: int = 50

var _anim: Node = null
var _arena_log: FileAccess = null

func _ready() -> void:
	_anim = load("res://scripts/ui/animation_controller.gd").new()
	add_child(_anim)
	var log_path: String = "user://bot_arena.log"
	_arena_log = FileAccess.open(log_path, FileAccess.WRITE)
	if _arena_log:
		_arena_log.store_string("=== BOT ARENA LOG: " + Time.get_datetime_string_from_system() + " ===\n")
	speed_1x.pressed.connect(func() -> void: _speed = 1.0)
	speed_2x.pressed.connect(func() -> void: _speed = 2.0)
	speed_4x.pressed.connect(func() -> void: _speed = 4.0)
	pause_btn.pressed.connect(_toggle_pause)
	_init_game()

func _init_game() -> void:
	GameManager.start_game()
	_bot_a = BotPlayerScript.new("player", "Синие", Color(0.3, 0.6, 1.0))
	_bot_b = BotPlayerScript.new("enemy", "Красные", Color(1.0, 0.3, 0.3))
	_bot_a.init_decks()
	_bot_b.init_decks()
	_turn = 1
	_running = true
	_log("БИТВА БОТОВ НАЧАЛАСЬ! Синие vs Красные", Color(1, 0.9, 0.3))
	_log("Синие столица: dump_west | Красные столица: dump_east", Color(0.8, 0.8, 0.8))
	_update_panels()
	call_deferred("_build_map")
	call_deferred("_start_loop")

func _build_map() -> void:
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0.1, 0.06)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.z_index = -1
	map_area.add_child(bg)
	var tex := load("res://assets/sprites/map/city_map.jpg")
	if tex:
		var img := TextureRect.new()
		img.texture = tex
		img.set_anchors_preset(Control.PRESET_FULL_RECT)
		img.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		img.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		img.z_index = 0
		map_area.add_child(img)
	var all_t: Array = CardDatabase._territories.values()
	for t_data in all_t:
		var tid: String = t_data.get("id", "")
		var raw_x: float = float(t_data.get("map_x", 540))
		var raw_y: float = float(t_data.get("map_y", 400))
		var pct_x: float = raw_x / 1080.0
		var pct_y: float = raw_y / 800.0
		var is_capital: bool = t_data.get("is_capital", false)
		var sz: float = 0.07 if is_capital else 0.05
		var owner: String = GameManager.get_territory_owner(tid)
		var btn := Button.new()
		btn.name = "T_" + tid
		btn.anchor_left = pct_x - sz / 2.0
		btn.anchor_top = pct_y - sz / 2.0
		btn.anchor_right = pct_x + sz / 2.0
		btn.anchor_bottom = pct_y + sz / 2.0
		btn.z_index = 10
		btn.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(8)
		style.set_border_width_all(3)
		_style_by_owner(style, owner)
		btn.add_theme_stylebox_override("normal", style)
		var icons := {"dump":"S","station":"B","square_three_stations":"3B","den":"D",
			"supermarket_dumpster":"M","pharmacy_dumpster":"A","dacha":"Da",
			"obrygalovka":"O","kutuzka":"K","open_street":"."}
		btn.text = icons.get(t_data.get("terrain", ""), "?")
		btn.add_theme_font_size_override("font_size", 22)
		map_area.add_child(btn)
		_territory_buttons[tid] = btn
		var lbl := Label.new()
		lbl.text = t_data.get("name_ru", tid)
		lbl.anchor_left = pct_x - 0.08
		lbl.anchor_top = pct_y + sz / 2.0
		lbl.anchor_right = pct_x + 0.08
		lbl.anchor_bottom = pct_y + sz / 2.0 + 0.03
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lbl.z_index = 11
		lbl.add_theme_font_size_override("font_size", 14)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		map_area.add_child(lbl)
		_territory_labels[tid] = lbl
	Logger.info("BotArena", "Map built with %d territories" % all_t.size())

func _style_by_owner(style: StyleBoxFlat, owner: String) -> void:
	match owner:
		"player":
			style.bg_color = Color(0.15, 0.45, 0.85, 0.75)
			style.border_color = Color(0.3, 0.6, 1.0)
		"enemy":
			style.bg_color = Color(0.85, 0.15, 0.15, 0.75)
			style.border_color = Color(1.0, 0.3, 0.3)
		_:
			style.bg_color = Color(0.45, 0.38, 0.28, 0.65)
			style.border_color = Color(0.65, 0.55, 0.4)

func _toggle_pause() -> void:
	_paused = not _paused
	pause_btn.text = "▶ ПРОДОЛЖИТЬ" if _paused else "⏸ ПАУЗА"

func _start_loop() -> void:
	while _running:
		if _paused:
			await get_tree().create_timer(0.1).timeout
			continue
		if _turn > _max_turns:
			_finish_game()
			return
		await get_tree().create_timer(0.4 / _speed).timeout
		if _paused:
			continue
		await _execute_turn_phase()

func _execute_turn_phase() -> void:
	var phases: Array = ["income_a", "draw_a", "play_a", "deploy_a", "move_a",
		"income_b", "draw_b", "play_b", "deploy_b", "move_b",
		"combat", "capture_a", "capture_b", "end"]
	for phase_name in phases:
		var result: Dictionary = {}
		match phase_name:
			"income_a":
				phase_label.text = "Доход Синих"
				result = _bot_a.phase_income()
				_log_income(result, _bot_a)
			"draw_a":
				phase_label.text = "Набор Синих"
				result = _bot_a.phase_draw()
				_log_draw(result, _bot_a)
			"play_a":
				phase_label.text = "Карты Синих"
				result = _bot_a.phase_play_cards()
				_log_play(result, _bot_a)
			"deploy_a":
				phase_label.text = "Деплой Синих"
				result = _bot_a.phase_deploy()
				_log_deploy(result, _bot_a)
				_animate_deploy(result, _bot_a)
			"move_a":
				phase_label.text = "Движение Синих"
				result = _bot_a.phase_move()
				_log_move(result, _bot_a)
				_animate_move(result, _bot_a)
			"income_b":
				phase_label.text = "Доход Красных"
				result = _bot_b.phase_income()
				_log_income(result, _bot_b)
			"draw_b":
				phase_label.text = "Набор Красных"
				result = _bot_b.phase_draw()
				_log_draw(result, _bot_b)
			"play_b":
				phase_label.text = "Карты Красных"
				result = _bot_b.phase_play_cards()
				_log_play(result, _bot_b)
			"deploy_b":
				phase_label.text = "Деплой Красных"
				result = _bot_b.phase_deploy()
				_log_deploy(result, _bot_b)
				_animate_deploy(result, _bot_b)
			"move_b":
				phase_label.text = "Движение Красных"
				result = _bot_b.phase_move()
				_log_move(result, _bot_b)
				_animate_move(result, _bot_b)
			"combat":
				phase_label.text = "БОЙ!"
				var combat_res: Dictionary = await _resolve_combat()
				_log_combat(combat_res)
			"capture_a":
				result = _bot_a.phase_end()
				_log_capture(result, _bot_a)
			"capture_b":
				result = _bot_b.phase_end()
				_log_capture(result, _bot_b)
			"end":
				phase_label.text = "Конец хода"
		_update_map_colors()
		_update_panels()
		await get_tree().create_timer(0.15 / _speed).timeout
	_turn += 1
	turn_label.text = "Ход %d/%d" % [_turn, _max_turns]
	_check_victory()

func _resolve_combat() -> Dictionary:
	var results: Array = []
	var a_deployed: Dictionary = _bot_a.get_deployed()
	var b_deployed: Dictionary = _bot_b.get_deployed()
	var contested: Array = []
	for t_id in a_deployed:
		if b_deployed.has(t_id):
			contested.append(t_id)
	if contested.is_empty():
		return {"battles": 0, "results": []}
	var resolver: RefCounted = BattleResolverScript.new()
	for t_id in contested:
		if not a_deployed.has(t_id) or not b_deployed.has(t_id):
			continue
		var a_units: Array = a_deployed[t_id]
		var b_units: Array = b_deployed[t_id]
		var alive_a: Array = []
		var alive_b: Array = []
		for u in a_units:
			if u.is_alive():
				alive_a.append(u)
		for u in b_units:
			if u.is_alive():
				alive_b.append(u)
		if alive_a.is_empty() or alive_b.is_empty():
			continue
		var t_owner: String = GameManager.get_territory_owner(t_id)
		var a_is_attacker: bool = true
		if t_owner == "player":
			a_is_attacker = false
		elif t_owner == "enemy":
			a_is_attacker = true
		else:
			a_is_attacker = alive_a.size() >= alive_b.size()
		var attackers: Array = alive_a if a_is_attacker else alive_b
		var defenders: Array = alive_b if a_is_attacker else alive_a
		var territory: Dictionary = CardDatabase.get_territory(t_id)
		var duel_result: Dictionary = resolver.resolve_multi(attackers, defenders, territory)
		var attacker_won: bool = duel_result.get("player_won", false)
		var winner: String
		if a_is_attacker:
			winner = "a" if attacker_won else "b"
		else:
			winner = "b" if attacker_won else "a"
		var t_name: String = territory.get("name_ru", t_id)
		results.append({"territory": t_name, "t_id": t_id, "winner": winner, "rounds": duel_result.get("rounds", [])})
		_animate_battle(t_id, winner)
		if winner == "a":
			GameManager.set_territory_owner(t_id, "player")
			b_deployed.erase(t_id)
		else:
			GameManager.set_territory_owner(t_id, "enemy")
			a_deployed.erase(t_id)
		await get_tree().create_timer(0.6 / _speed).timeout
	return {"battles": results.size(), "results": results}

func _animate_battle(t_id: String, winner: String) -> void:
	if not _territory_buttons.has(t_id):
		return
	var btn: Button = _territory_buttons[t_id]
	var center := btn.global_position + btn.size * 0.5
	_anim.battle_effect(anim_layer, center, 0.8)
	var color := Color(0.3, 0.6, 1.0) if winner == "a" else Color(1.0, 0.3, 0.3)
	_anim.flash_overlay(anim_layer, color, Rect2(btn.global_position, btn.size), 0.5)
	var t_name: String = _territory_labels[t_id].text if _territory_labels.has(t_id) else t_id
	var win_text := "СИНИЕ WIN" if winner == "a" else "КРАСНЫЕ WIN"
	_anim.float_text(anim_layer, win_text, center - Vector2(60, 30), color, 1.5, 28)
	_anim.shake_control(btn, 10.0, 0.4)

func _animate_deploy(result: Dictionary, bot: RefCounted) -> void:
	var units: Array = result.get("units", [])
	for entry in units:
		var t_id: String = entry.get("t_id", "")
		if _territory_buttons.has(t_id):
			var btn: Button = _territory_buttons[t_id]
			var to := btn.global_position + btn.size * 0.5
			var from := Vector2(100, get_viewport().size.y * 0.5) if bot.id == "player" else Vector2(get_viewport().size.x - 100, get_viewport().size.y * 0.5)
			_anim.card_fly(anim_layer, from, to, entry.get("card", ""), bot.accent_color, 0.5)

func _animate_move(result: Dictionary, bot: RefCounted) -> void:
	var moves: Array = result.get("moves", [])
	for entry in moves:
		var from_id: String = entry.get("from_id", "")
		var to_id: String = entry.get("to_id", "")
		if _territory_buttons.has(from_id) and _territory_buttons.has(to_id):
			var from_btn: Button = _territory_buttons[from_id]
			var to_btn: Button = _territory_buttons[to_id]
			var from_pos := from_btn.global_position + from_btn.size * 0.5
			var to_pos := to_btn.global_position + to_btn.size * 0.5
			_anim.movement_arrow(anim_layer, from_pos, to_pos, bot.accent_color, 0.8)
			_anim.float_text(anim_layer, "x%d →" % entry.get("count", 1), from_pos + Vector2(-20, -30), bot.accent_color, 1.0, 22)

func _update_map_colors() -> void:
	for t_id in _territory_buttons:
		var btn: Button = _territory_buttons[t_id]
		var owner := GameManager.get_territory_owner(t_id)
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(8)
		style.set_border_width_all(3)
		_style_by_owner(style, owner)
		btn.add_theme_stylebox_override("normal", style)

func _update_panels() -> void:
	turn_label.text = "Ход %d/%d" % [_turn, _max_turns]
	var a_res: Dictionary = _bot_a.get_resources()
	blue_res.text = "Б:%d М:%d В:%d К:%d" % [a_res.get("bottles", 0), a_res.get("coins", 0), a_res.get("rolltons", 0), a_res.get("cardboard", 0)]
	blue_units.text = "Отрядов: %d" % _bot_a.count_alive()
	blue_terr.text = "Территорий: %d" % _bot_a.count_territories()
	var b_res: Dictionary = _bot_b.get_resources()
	red_res.text = "Б:%d М:%d В:%d К:%d" % [b_res.get("bottles", 0), b_res.get("coins", 0), b_res.get("rolltons", 0), b_res.get("cardboard", 0)]
	red_units.text = "Отрядов: %d" % _bot_b.count_alive()
	red_terr.text = "Территорий: %d" % _bot_b.count_territories()
	_update_hand_display(blue_hand, _bot_a.get_hand())
	_update_hand_display(red_hand, _bot_b.get_hand())

func _update_hand_display(container: HBoxContainer, hand: RefCounted) -> void:
	for child in container.get_children():
		child.queue_free()
	if hand == null:
		return
	var cards: Array = hand.get_all()
	var shown: int = mini(cards.size(), 8)
	for i in range(shown):
		var c := Panel.new()
		c.custom_minimum_size = Vector2(50, 70)
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var card_data: Dictionary = cards[i]
		var rarity: String = card_data.get("rarity", "common")
		var card_type: String = card_data.get("type", "unit")
		var border_color := _get_type_border_color(card_type, rarity)
		if card_type == "spell":
			border_color = Color(0.7, 0.3, 1.0)
		elif card_type == "situation":
			border_color = Color(1.0, 0.85, 0.1)
		elif card_type == "commander":
			border_color = Color(1.0, 0.5, 0.0)
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(3)
		style.set_border_width_all(2)
		style.border_color = border_color
		style.bg_color = Color(0.06, 0.05, 0.03)
		c.add_theme_stylebox_override("panel", style)
		container.add_child(c)
		var lbl := Label.new()
		var name_text: String = card_data.get("name_ru", "?")
		lbl.text = name_text.left(6)
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.add_theme_color_override("font_color", Color(0, 0, 0))
		lbl.add_theme_color_override("font_outline_color", Color(1, 1, 1))
		lbl.add_theme_constant_override("outline_size", 3)
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(lbl)
	if cards.size() > shown:
		var more := Label.new()
		more.text = "+%d" % (cards.size() - shown)
		more.add_theme_font_size_override("font_size", 14)
		more.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
		more.mouse_filter = Control.MOUSE_FILTER_IGNORE
		container.add_child(more)

func _get_rarity_color(rarity: String) -> Color:
	match rarity:
		"common": return Color(0.55, 0.55, 0.55)
		"uncommon": return Color(0.15, 0.65, 0.15)
		"rare": return Color(0.2, 0.45, 0.95)
		"legendary": return Color(1.0, 0.84, 0.0)
		_: return Color(0.55, 0.55, 0.55)

func _get_type_border_color(card_type: String, rarity: String) -> Color:
	var b: float = {"common": 0.7, "uncommon": 0.85, "rare": 1.0, "legendary": 1.0}.get(rarity, 0.7)
	match card_type:
		"unit": return Color(0.15 * b, 0.75 * b, 0.2 * b)
		"commander": return Color(1.0 * b, 0.55 * b, 0.0)
		"situation": return Color(1.0 * b, 0.85 * b, 0.1 * b)
		"spell": return Color(0.7 * b, 0.25 * b, 1.0 * b)
		_: return _get_rarity_color(rarity)

func _log(text: String, color: Color = Color.WHITE) -> void:
	var color_hex := "#%s" % color.to_html(false)
	log_rich.append_text("[color=%s]%s[/color]\n" % [color_hex, text])
	log_rich.scroll_to_line(log_rich.get_line_count())
	_alog(text)

func _alog(text: String) -> void:
	if _arena_log:
		var ts: String = Time.get_time_string_from_system()
		_arena_log.store_string("[%s] [T%d] %s\n" % [ts, _turn, text])
		_arena_log.flush()

func _log_income(result: Dictionary, bot: RefCounted) -> void:
	var income: Dictionary = result.get("income", {})
	var total: int = 0
	for v in income.values():
		total += v
	if total > 0:
		_log("%s: доход +%d ресурсов (%d терр.)" % [bot.display_name, total, result.get("territories", 0)], bot.accent_color)

func _log_draw(result: Dictionary, bot: RefCounted) -> void:
	var cards: Array = result.get("cards", [])
	if not cards.is_empty():
		_log("%s: набрал %d карт (%s)" % [bot.display_name, cards.size(), ", ".join(cards.slice(0, 4))], bot.accent_color * 0.8)

func _log_play(result: Dictionary, bot: RefCounted) -> void:
	var cards: Array = result.get("cards", [])
	if not cards.is_empty():
		_log("%s: разыграл: %s" % [bot.display_name, ", ".join(cards)], Color(1.0, 0.9, 0.5))

func _log_deploy(result: Dictionary, bot: RefCounted) -> void:
	var units: Array = result.get("units", [])
	for entry in units:
		_log("%s: → %s [%s]" % [bot.display_name, entry.get("territory", ""), entry.get("card", "")], bot.accent_color)

func _log_move(result: Dictionary, bot: RefCounted) -> void:
	var moves: Array = result.get("moves", [])
	for entry in moves:
		_log("%s: %s → %s (x%d)" % [bot.display_name, entry.get("from", ""), entry.get("to", ""), entry.get("count", 1)], bot.accent_color * 0.9)

func _log_combat(result: Dictionary) -> void:
	var battles: int = result.get("battles", 0)
	if battles == 0:
		return
	_log("═══ БОЙ: %d столкновений! ═══" % battles, Color(1.0, 0.5, 0.1))
	var results: Array = result.get("results", [])
	for r in results:
		var winner_name := "Синие" if r.get("winner", "") == "a" else "Красные"
		var rounds: int = r.get("rounds", []).size()
		_log("  %s → %s победил (%d раундов)" % [r.get("territory", ""), winner_name, rounds], Color(1.0, 0.8, 0.3))

func _log_capture(result: Dictionary, bot: RefCounted) -> void:
	var captured: Array = result.get("captured", [])
	for t_name in captured:
		_log("%s: ЗАХВАТИЛ %s!" % [bot.display_name, t_name], Color(1.0, 1.0, 0.3))
		_anim.float_text(anim_layer, "ЗАХВАТ!", Vector2(get_viewport().size.x * 0.5, get_viewport().size.y * 0.3), bot.accent_color, 2.0, 42)

func _check_victory() -> void:
	var a_count: int = _bot_a.count_territories()
	var b_count: int = _bot_b.count_territories()
	var total: int = GameManager._territory_owners.size()
	if a_count >= total * 0.7:
		_finish_game()
	elif b_count >= total * 0.7:
		_finish_game()

func _finish_game() -> void:
	_running = false
	var a_count: int = _bot_a.count_territories()
	var b_count: int = _bot_b.count_territories()
	var winner: String
	var color: Color
	if a_count > b_count:
		winner = "СИНИЕ ПОБЕДИЛИ!"
		color = Color(0.3, 0.6, 1.0)
	elif b_count > a_count:
		winner = "КРАСНЫЕ ПОБЕДИЛИ!"
		color = Color(1.0, 0.3, 0.3)
	else:
		winner = "НИЧЬЯ!"
		color = Color(1.0, 1.0, 0.3)
	_log("═══════════════════════════", Color(1, 1, 1))
	_log("ИГРА ОКОНЧЕНА! %s" % winner, color)
	_log("Синие: %d терр., %d отр. | Красные: %d терр., %d отр." % [
		a_count, _bot_a.count_alive(), b_count, _bot_b.count_alive()], Color(1, 1, 1))
	_log("═══════════════════════════", Color(1, 1, 1))
	phase_label.text = winner

func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE:
		if _arena_log:
			_arena_log.store_string("=== BOT ARENA LOG END ===\n")
			_arena_log.close()
