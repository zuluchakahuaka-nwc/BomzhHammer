class_name TerritoryManager
extends RefCounted

var _map: Control = null
var _attacks_this_turn: int = 0
var _max_attacks_per_turn: int = 2

func reset_turn_attacks() -> void:
	_attacks_this_turn = 0

func _init(map: Control) -> void:
	_map = map

func attack_territory(target_id: String) -> void:
	if _attacks_this_turn >= _max_attacks_per_turn:
		_map._lm("Only %d attack(s) per turn!" % _max_attacks_per_turn)
		return
	if _map._selected_territory == "":
		_map._lm("Select your territory first, then right-click to attack/move")
		return
	if _map._selected_territory == target_id:
		return
	var adjacent: Array = CardDatabase.get_adjacent_territories(_map._selected_territory)
	Logger.info("TerritoryMgr", "Attack check: %s -> %s | adjacent_to_src: %s" % [_map._selected_territory, target_id, str(adjacent)])
	if not adjacent.has(target_id):
		_map._lm("Not adjacent: %s and %s" % [target_id, _map._selected_territory])
		return
	var attacker_owner: String = GameManager.get_territory_owner(_map._selected_territory)
	if attacker_owner != "player":
		_map._lm("You don't own %s" % _map._selected_territory)
		return
	var target_owner: String = GameManager.get_territory_owner(target_id)
	var p_units: Array = _get_alive(_map._player_deployed.get(_map._selected_territory, []))
	if p_units.is_empty():
		_map._lm("No units on %s" % _map._selected_territory)
		return
	if target_owner == "player":
		_move_all_units(_map._selected_territory, target_id)
		return
	var e_units: Array = []
	if _map._npc_garrisons.has(target_id):
		e_units = _get_alive(_map._npc_garrisons[target_id])
	if e_units.is_empty():
		_move_all_units(_map._selected_territory, target_id)
		update_territory_button_style(target_id, "player")
		GameManager.set_territory_owner(target_id, "player")
		_map._lm("Captured %s without resistance!" % target_id)
		GameManager.register_player_deployed(_map._player_deployed)
		return
	_map._lm("Attacking %s -> %s (%d vs %d)" % [_map._selected_territory, target_id, p_units.size(), e_units.size()])
	_attacks_this_turn += 1
	var p_before: int = p_units.size()
	var e_before: int = e_units.size()
	var territory_data: Dictionary = CardDatabase.get_territory(target_id)
	var resolver: RefCounted = load("res://scripts/combat/battle_resolver.gd").new()
	var result: Dictionary = resolver.resolve_multi(p_units, e_units, territory_data)
	var player_won: bool = result.get("player_won", false)
	var src_name: String = Localization.get_territory_name(CardDatabase.get_territory(_map._selected_territory))
	var tgt_name: String = Localization.get_territory_name(CardDatabase.get_territory(target_id))
	if player_won:
		_map._npc_garrisons.erase(target_id)
		update_npc_marker(target_id)
		_map._player_deployed[_map._selected_territory] = _get_alive(_map._player_deployed.get(_map._selected_territory, []))
		for u in _map._player_deployed[_map._selected_territory].duplicate():
			_map._player_deployed[_map._selected_territory].erase(u)
			if not _map._player_deployed.has(target_id):
				_map._player_deployed[target_id] = []
			_map._player_deployed[target_id].append(u)
			u.territory_id = target_id
		if _map._player_deployed.has(_map._selected_territory) and _map._player_deployed[_map._selected_territory].is_empty():
			_map._player_deployed.erase(_map._selected_territory)
		update_territory_marker(_map._selected_territory)
		update_territory_marker(target_id)
		update_territory_button_style(target_id, "player")
		GameManager.set_territory_owner(target_id, "player")
		_map._battle_overlay.show_result(src_name, tgt_name, true, _map._player_deployed.get(target_id, []).size(), p_before - _map._player_deployed.get(target_id, []).size(), 0, e_before)
		_map._result_popup.show_victory(tgt_name)
		_map._lm("VICTORY! Captured %s — all enemies destroyed" % target_id)
		_map._check_victory()
	else:
		_map._player_deployed.erase(_map._selected_territory)
		update_territory_marker(_map._selected_territory)
		update_territory_marker(target_id)
		_map._battle_overlay.show_result(src_name, tgt_name, false, 0, p_before, e_before, 0)
		_map._result_popup.show_defeat(tgt_name)
		_map._lm("DEFEAT at %s — all your units destroyed" % target_id)
	_map._refresh_hand_display()
	_map._select_territory(target_id if player_won else _map._selected_territory)
	GameManager.register_player_deployed(_map._player_deployed)

func _move_all_units(from_id: String, to_id: String) -> void:
	var units: Array = _get_alive(_map._player_deployed.get(from_id, []))
	if units.is_empty():
		return
	for u in units:
		_map._player_deployed[from_id].erase(u)
		if not _map._player_deployed.has(to_id):
			_map._player_deployed[to_id] = []
		_map._player_deployed[to_id].append(u)
		u.territory_id = to_id
	if _map._player_deployed.has(from_id) and _map._player_deployed[from_id].is_empty():
		_map._player_deployed.erase(from_id)
	update_territory_marker(from_id)
	update_territory_marker(to_id)
	_map._refresh_hand_display()
	_map._select_territory(to_id)
	_map._lm("Moved %d units: %s -> %s" % [units.size(), from_id, to_id])
	GameManager.register_player_deployed(_map._player_deployed)

func move_single_unit(from_id: String, to_id: String, unit: RefCounted) -> void:
	if not _map._player_deployed.has(from_id):
		return
	_map._player_deployed[from_id].erase(unit)
	if _map._player_deployed[from_id].is_empty():
		_map._player_deployed.erase(from_id)
	if not _map._player_deployed.has(to_id):
		_map._player_deployed[to_id] = []
	_map._player_deployed[to_id].append(unit)
	unit.territory_id = to_id
	update_territory_marker(from_id)
	update_territory_marker(to_id)
	_map._refresh_hand_display()
	GameManager.register_player_deployed(_map._player_deployed)
	_map._lm("Moved %s: %s -> %s" % [unit.get_name(), from_id, to_id])

func select_territory(t_id: String) -> void:
	_map._selected_territory = t_id
	for tid in _map._territory_buttons:
		update_territory_button_style(tid, GameManager.get_territory_owner(tid))
	if _map._territory_buttons.has(t_id):
		var btn: Button = _map._territory_buttons[t_id]
		var style := StyleBoxFlat.new()
		style.set_corner_radius_all(4)
		style.bg_color = Color(0.2, 0.6, 1.0, 0.4)
		style.border_color = Color(1, 1, 0.3)
		style.set_border_width_all(4)
		style.shadow_color = Color(1, 1, 0.3, 0.6)
		style.shadow_size = 8
		btn.add_theme_stylebox_override("normal", style)
	_map._refresh_hand_display()

func update_territory_button_style(t_id: String, owner: String) -> void:
	if not _map._territory_buttons.has(t_id):
		return
	var btn: Button = _map._territory_buttons[t_id]
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(8)
	style.set_border_width_all(3)
	var mb: RefCounted = _map._map_builder
	mb.style_by_owner(style, owner)
	btn.add_theme_stylebox_override("normal", style)

func update_territory_marker(t_id: String) -> void:
	if not _map._territory_buttons.has(t_id):
		return
	var map_area: Control = _map.map_area
	var badge_name: String = "UM_" + t_id
	var existing: Node = map_area.get_node_or_null(badge_name)
	if existing != null:
		existing.queue_free()
	var count: int = 0
	if _map._player_deployed.has(t_id):
		for u in _map._player_deployed[t_id]:
			if u.is_alive():
				count += 1
	print("[Marker] Player territory=%s count=%d has_btn=%s" % [t_id, count, _map._territory_buttons.has(t_id)])
	if count == 0:
		return
	_place_count_badge(map_area, badge_name, t_id, count, false)

func update_npc_marker(t_id: String) -> void:
	if not _map._territory_buttons.has(t_id):
		return
	var map_area: Control = _map.map_area
	var badge_name: String = "NM_" + t_id
	var existing: Node = map_area.get_node_or_null(badge_name)
	if existing != null:
		existing.queue_free()
	var count: int = 0
	if _map._npc_garrisons.has(t_id):
		for u in _map._npc_garrisons[t_id]:
			if u.is_alive():
				count += 1
	if count == 0:
		_map._npc_garrisons.erase(t_id)
		return
	_place_count_badge(map_area, badge_name, t_id, count, true)

func _place_count_badge(map_area: Control, node_name: String, t_id: String, count: int, is_enemy: bool) -> void:
	var btn: Button = _map._territory_buttons[t_id]
	var badge := Panel.new()
	badge.name = node_name
	badge.z_index = 20
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pct_x: float = (btn.anchor_left + btn.anchor_right) / 2.0
	var pct_y: float = btn.anchor_top + 0.01
	badge.anchor_left = pct_x - 0.04
	badge.anchor_top = pct_y
	badge.anchor_right = pct_x + 0.04
	badge.anchor_bottom = pct_y + 0.05
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(6)
	style.set_border_width_all(2)
	if is_enemy:
		style.bg_color = Color(0.15, 0.0, 0.0)
		style.border_color = Color(1.0, 0.2, 0.2)
	else:
		style.bg_color = Color(0.1, 0.08, 0.0)
		style.border_color = Color(1.0, 0.85, 0.0)
	badge.add_theme_stylebox_override("panel", style)
	map_area.add_child(badge)
	var lbl := Label.new()
	lbl.text = "x%d" % count
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 28)
	if is_enemy:
		lbl.add_theme_color_override("font_color", Color(1.0, 0.25, 0.25))
	else:
		lbl.add_theme_color_override("font_color", Color(1.0, 0.9, 0.1))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lbl.set_anchors_preset(Control.PRESET_FULL_RECT)
	badge.add_child(lbl)

func refresh_all_markers() -> void:
	for t_id in _map._player_deployed:
		update_territory_marker(t_id)
	for t_id in _map._npc_garrisons:
		update_npc_marker(t_id)

func generate_npc_garrisons() -> void:
	var all_unit_data: Array = CardDatabase._units.values()
	if all_unit_data.is_empty():
		return
	var strong_units: Array = []
	for ud in all_unit_data:
		if ud.get("attack", 0) >= 3 or ud.get("hp", 0) >= 4:
			strong_units.append(ud)
	if strong_units.is_empty():
		strong_units = all_unit_data
	var all_t: Array = CardDatabase._territories.keys()
	for tid in all_t:
		var owner: String = GameManager.get_territory_owner(tid)
		if owner == "player":
			continue
		var is_enemy_capital: bool = (owner == "enemy" and CardDatabase.get_territory(tid).get("is_capital", false))
		var count: int = randi_range(4, 7) if owner == "neutral" else randi_range(7, 14)
		if is_enemy_capital:
			count = randi_range(12, 18)
		var garrison: Array = []
		for _i in range(count):
			var pool: Array = strong_units if randf() > 0.35 else all_unit_data
			var template: Dictionary = pool[randi() % pool.size()]
			var unit: RefCounted = load("res://scripts/cards/card_instance.gd").new(template)
			garrison.append(unit)
		_map._npc_garrisons[tid] = garrison
		update_npc_marker(tid)
	_map._lm("NPC garrisons placed on %d territories" % _map._npc_garrisons.size())

func start_move_mode(from_id: String) -> void:
	_map._moving = true
	_map._moving_from = from_id
	var alive: Array = []
	for u in _map._player_deployed[from_id]:
		if u.is_alive():
			alive.append(u)
	_map._moving_units = alive
	var adjacent: Array = CardDatabase.get_adjacent_territories(from_id)
	for adj_id in adjacent:
		if _map._territory_buttons.has(adj_id):
			var btn: Button = _map._territory_buttons[adj_id]
			var hl := StyleBoxFlat.new()
			hl.set_corner_radius_all(8)
			hl.set_border_width_all(4)
			hl.bg_color = Color(0.2, 0.6, 1.0, 0.5)
			hl.border_color = Color(0.3, 0.8, 1.0)
			hl.shadow_color = Color(0.3, 0.7, 1.0, 0.6)
			hl.shadow_size = 8
			btn.add_theme_stylebox_override("hover", hl)
	_map._lm("Move mode: %d units from %s — click adjacent territory" % [alive.size(), from_id])

func finish_move(to_id: String) -> void:
	_map._moving = false
	var from_id: String = _map._moving_from
	_map._moving_from = ""
	var units_to_move: Array = _map._moving_units
	_map._moving_units = []
	if from_id == to_id:
		clear_move_highlights()
		_map._lm("Move cancelled (same territory)")
		return
	var adjacent: Array = CardDatabase.get_adjacent_territories(from_id)
	if not adjacent.has(to_id):
		clear_move_highlights()
		_map._lm("Cannot move: %s not adjacent to %s" % [to_id, from_id])
		return
	var moving: Array = []
	for u in units_to_move:
		if u.is_alive():
			moving.append(u)
	if moving.is_empty():
		clear_move_highlights()
		return
	if not _map._player_deployed.has(to_id):
		_map._player_deployed[to_id] = []
	for u in moving:
		_map._player_deployed[from_id].erase(u)
		_map._player_deployed[to_id].append(u)
		u.territory_id = to_id
	if _map._player_deployed.has(from_id) and _count_alive(_map._player_deployed[from_id]) == 0:
		_map._player_deployed.erase(from_id)
	if _map._npc_garrisons.has(to_id) and _count_alive(_map._npc_garrisons[to_id]) > 0:
		_map._resolve_npc_battle(to_id)
	else:
		update_territory_button_style(to_id, "player")
		GameManager.set_territory_owner(to_id, "player")
	update_territory_marker(from_id)
	update_territory_marker(to_id)
	clear_move_highlights()
	GameManager.register_player_deployed(_map._player_deployed)
	_map._lm("Moved %d units: %s -> %s" % [moving.size(), from_id, to_id])

func clear_move_highlights() -> void:
	for t_id in _map._territory_buttons:
		update_territory_button_style(t_id, GameManager.get_territory_owner(t_id))

func _get_alive(units: Array) -> Array:
	var alive: Array = []
	for u in units:
		if u.is_alive():
			alive.append(u)
	return alive

func _count_alive(units: Array) -> int:
	var c: int = 0
	for u in units:
		if u.is_alive():
			c += 1
	return c


