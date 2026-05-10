extends Node

enum State { WAIT_SCENE, INIT, SELECT_MY, ATTACK_ENEMY, POST, END_PHASE, SPAWN, DONE }

var _state: int = State.WAIT_SCENE
var _gm: Control = null
var _timer: float = 0.0
var _delay: float = 1.5
var _cycle: int = 0
var _pending_source: String = ""
var _pending_target: String = ""
var _stuck: int = 0
var _enabled: bool = false

func _ready() -> void:
	var args := OS.get_cmdline_args()
	for a in args:
		if a == "--bot":
			_enabled = true
	if not _enabled:
		set_process(false)
		return
	print("BOT: autoload ready (enabled via --bot)")

func _process(delta: float) -> void:
	_timer += delta
	if _timer < _delay:
		return
	_timer = 0.0
	match _state:
		State.WAIT_SCENE: _wait_scene()
		State.INIT: _do_init()
		State.SELECT_MY: _do_select_my()
		State.ATTACK_ENEMY: _do_attack_enemy()
		State.POST: _do_post()
		State.END_PHASE: _do_end_phase()
		State.SPAWN: _do_spawn()
		State.DONE:
			print("BOT: finished")
			set_process(false)

func _wait_scene() -> void:
	var root := get_tree().root
	if root == null: return
	for c in root.get_children():
		if c.name in ["game_map", "GameMap"]:
			_gm = c
			_state = State.INIT
			_delay = 1.0
			print("BOT: found game_map")
			return

func _do_init() -> void:
	if not _ok(): return
	_close_popups()
	_cycle = 0
	_stuck = 0
	print("BOT: starting")
	_delay = 0.8
	_state = State.SELECT_MY

func _do_select_my() -> void:
	if not _ok(): return
	_close_popups()
	_cycle += 1
	if _cycle > 200:
		_state = State.DONE
		return
	var owned: int = GameManager.get_player_territory_count()
	var total: int = CardDatabase._territories.size()
	print("BOT[%d]: %d/%d" % [_cycle, owned, total])
	if owned >= total:
		print("BOT: ALL CONQUERED!")
		_state = State.DONE
		return
	if not _has_units():
		_state = State.SPAWN
		return
	var info := _pick_target()
	if info.source == "":
		_stuck += 1
		if _stuck > 3:
			_state = State.SPAWN
			_stuck = 0
		else:
			_state = State.END_PHASE
		return
	_stuck = 0
	_pending_source = info.source
	_pending_target = info.target
	print("BOT: left-click %s (own) -> then right-click %s (enemy)" % [_pending_source, _pending_target])
	_click_left(_pending_source)
	_delay = 0.6
	_state = State.ATTACK_ENEMY

func _do_attack_enemy() -> void:
	if not _ok(): return
	print("BOT: right-click %s" % _pending_target)
	_click_right(_pending_target)
	_delay = 0.8
	_state = State.POST

func _do_post() -> void:
	if not _ok(): return
	_close_popups()
	var owner: String = GameManager.get_territory_owner(_pending_target)
	print("BOT: %s -> %s" % [_pending_target, "CAPTURED" if owner == "player" else "LOST"])
	_pending_source = ""
	_pending_target = ""
	_delay = 0.3
	_state = State.SELECT_MY

func _do_end_phase() -> void:
	if not _ok(): return
	_close_popups()
	print("BOT: pressing End Phase button")
	var btn: Button = _gm.end_turn_btn
	if btn:
		btn.pressed.emit()
	_delay = 0.8
	_state = State.SELECT_MY

func _do_spawn() -> void:
	if not _ok(): return
	var tid: String = _best_owned()
	if tid == "":
		tid = "dump_west"
		GameManager.set_territory_owner("dump_west", "player")
	print("BOT: spawning 8 units on %s" % tid)
	var all_u: Array = CardDatabase._units.values()
	if all_u.is_empty():
		_state = State.DONE
		return
	if not _gm._player_deployed.has(tid):
		_gm._player_deployed[tid] = []
	for _i in range(8):
		var t: Dictionary = all_u[randi() % all_u.size()]
		var u: RefCounted = load("res://scripts/cards/card_instance.gd").new(t)
		u.territory_id = tid
		_gm._player_deployed[tid].append(u)
	_gm._territory_mgr.update_territory_marker(tid)
	_gm._territory_mgr.update_territory_button_style(tid, "player")
	GameManager.set_territory_owner(tid, "player")
	GameManager.register_player_deployed(_gm._player_deployed)
	if _gm._right_deck:
		for _i in range(3):
			_gm._draw_from_deck(_gm._right_deck)
	_gm._refresh_hand_display()
	_delay = 0.5
	_state = State.SELECT_MY

func _ok() -> bool:
	if _gm == null or not is_instance_valid(_gm):
		_state = State.WAIT_SCENE
		return false
	return true

func _click_left(t_id: String) -> void:
	var btn: Button = _gm._territory_buttons.get(t_id, null)
	if btn:
		btn.pressed.emit()
	else:
		print("BOT: button not found for %s" % t_id)

func _click_right(t_id: String) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_RIGHT
	ev.pressed = true
	ev.position = Vector2(0, 0)
	var btn: Button = _gm._territory_buttons.get(t_id, null)
	if btn:
		btn.gui_input.emit(ev)
	else:
		print("BOT: button not found for %s" % t_id)

func _has_units() -> bool:
	for t_id in _gm._player_deployed:
		var units = _gm._player_deployed[t_id]
		for u in units:
			if u.is_alive():
				return true
	return false

func _best_owned() -> String:
	var best: String = ""
	var best_e: int = 0
	for t_id in _gm._player_deployed:
		var adj: Array = CardDatabase.get_adjacent_territories(t_id)
		var e: int = 0
		for a in adj:
			if GameManager.get_territory_owner(a) != "player":
				e += 1
		if e > best_e:
			best_e = e
			best = t_id
	return best

func _close_popups() -> void:
	if not _ok(): return
	if _gm.terr_overlay and _gm.terr_overlay.visible:
		_gm._close_territory_overlay()
		return
	for c in _gm.get_children():
		if c.name == "ReligionChoice":
			_click_first_btn(c)
			print("BOT: chose religion")
			return
		if c.name == "IdeologyChoice":
			_click_first_btn(c)
			print("BOT: chose ideology")
			return
		if c.name == "IntroOverlay":
			c.queue_free()
			GameManager.set_intro_shown()
			return
	if _gm.card_detail_popup and _gm.card_detail_popup.visible:
		_gm.card_detail_popup.visible = false
		_gm.card_play_btn.visible = false
		_gm.card_detail_preview.scale = Vector2.ZERO
		return
	if _gm.research_popup and _gm.research_popup.visible:
		var grid: GridContainer = _gm.research_grid
		if grid:
			for card in grid.get_children():
				if card is PanelContainer:
					for sub in card.get_children():
						if sub is VBoxContainer:
							for b in sub.get_children():
								if b is Button:
									b.pressed.emit()
									print("BOT: picked research")
									return
		_gm.research_popup.visible = false
	if _gm.territory_panel and _gm.territory_panel.visible:
		_gm._close_territory_panel()

func _click_first_btn(node: Control) -> void:
	for c in node.get_children():
		if c is VBoxContainer:
			for s in c.get_children():
				if s is Button:
					s.pressed.emit()
					return
		if c is Button:
			c.pressed.emit()
			return

class _TInfo:
	var source: String = ""
	var target: String = ""
	var score: float = -999.0

func _pick_target() -> _TInfo:
	var best := _TInfo.new()
	for t_id in _gm._player_deployed:
		var units = _gm._player_deployed[t_id]
		var alive: int = 0
		for u in units:
			if u.is_alive():
				alive += 1
		if alive == 0:
			continue
		var adj: Array = CardDatabase.get_adjacent_territories(t_id)
		for a in adj:
			if GameManager.get_territory_owner(a) == "player":
				continue
			var npc: int = _npc_count(a)
			var sc: float = float(alive) * 2.0 - float(npc) * 0.5
			if sc > best.score:
				best.score = sc
				best.source = t_id
				best.target = a
	return best

func _npc_count(t_id: String) -> int:
	if not _gm._npc_garrisons.has(t_id):
		return 0
	var c: int = 0
	for u in _gm._npc_garrisons[t_id]:
		if u.is_alive():
			c += 1
	return c
