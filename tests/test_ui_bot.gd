extends SceneTree

var _step: int = 0
var _wait: float = 0.0
var _gm: Variant = null
var _log_lines: Array = []
var _max_turns: int = 5
var _current_turn: int = 0
var _phase_actions_done: bool = false

func _init() -> void:
	print("=== UI BOT START ===")

func _process(delta: float) -> bool:
	if _gm == null:
		_try_init()
		return false
	_wait -= delta
	if _wait > 0:
		return false
	_do_step()
	return false

func _try_init() -> void:
	var root_node: Node = get_root()
	if root_node == null:
		return
	_gm = root_node.get_node_or_null("GameManager")
	if _gm == null:
		return
	_log("UI BOT: GameManager found, starting in 2s")
	_wait = 2.0
	_step = 0

func _log(msg: String) -> void:
	print(msg)
	_log_lines.append(msg)

func _do_step() -> void:
	var scene: Node = get_tree().current_scene
	if scene == null:
		_wait = 1.0
		return
	match _step:
		0:
			_click_new_game(scene)
		1:
			_wait_for_game_map(scene)
		2:
			_close_intro(scene)
		3:
			_play_game_loop(scene)

func _click_new_game(scene: Node) -> void:
	_log("UI BOT: Clicking New Game...")
	var btn: Button = _find_button(scene, "NewGameButton")
	if btn:
		btn.pressed.emit()
		_step = 1
		_wait = 3.0
	else:
		_log("UI BOT: NewGameButton not found, retrying...")
		_wait = 1.0

func _find_button(node: Node, name: String) -> Button:
	if node.name == name and node is Button:
		return node
	for child in node.get_children():
		var found: Button = _find_button(child, name)
		if found:
			return found
	return null

func _wait_for_game_map(scene: Node) -> void:
	if scene.name in ["game_map", "GameMap"]:
		_log("UI BOT: Game map loaded!")
		_step = 2
		_wait = 1.0
		_current_turn = _gm.get_current_turn()
	else:
		_log("UI BOT: Waiting for game map... scene=%s" % scene.name)
		_wait = 2.0

func _close_intro(scene: Node) -> void:
	var intro: Node = _find_node(scene, "IntroOverlay")
	if intro:
		_log("UI BOT: Closing intro overlay")
		intro.queue_free()
		_step = 3
		_wait = 2.0
		_phase_actions_done = false
	else:
		_log("UI BOT: No intro overlay, proceeding")
		_step = 3
		_wait = 1.0
		_phase_actions_done = false

func _find_node(node: Node, name: String) -> Node:
	if node.name == name:
		return node
	for child in node.get_children():
		var found: Node = _find_node(child, name)
		if found:
			return found
	return null

func _play_game_loop(scene: Node) -> void:
	if not scene.name in ["game_map", "GameMap"]:
		_log("UI BOT: Left game map, stopping")
		_finish()
		return
	var turn: int = _gm.get_current_turn()
	if turn > _max_turns:
		_log("UI BOT: Reached max turns (%d), done!" % _max_turns)
		_finish()
		return
	if turn != _current_turn:
		_current_turn = turn
		_phase_actions_done = false
		_log("UI BOT: === TURN %d ===" % turn)
	var phase: int = _gm.get_current_phase()
	_do_phase_action(scene, phase)

func _do_phase_action(scene: Node, phase: int) -> void:
	match phase:
		0:
			if not _phase_actions_done:
				_log("UI BOT: Phase 0 - Resources (auto)")
				_phase_actions_done = true
			_click_end_phase(scene)
			_wait = 0.5
		1:
			if not _phase_actions_done:
				_log("UI BOT: Phase 1 - Draw (auto)")
				_phase_actions_done = true
			_click_end_phase(scene)
			_wait = 0.5
		2:
			if not _phase_actions_done:
				_log("UI BOT: Phase 2 - Movement, deploying cards...")
				_deploy_units(scene)
				_phase_actions_done = true
				_wait = 1.0
			else:
				_click_end_phase(scene)
				_wait = 0.5
		3:
			if not _phase_actions_done:
				_log("UI BOT: Phase 3 - Combat (auto)")
				_phase_actions_done = true
			_click_end_phase(scene)
			_wait = 1.0
		4:
			if not _phase_actions_done:
				_log("UI BOT: Phase 4 - Events (auto)")
				_phase_actions_done = true
			_click_end_phase(scene)
			_wait = 0.5
		5:
			if not _phase_actions_done:
				_log("UI BOT: Phase 5 - End turn")
				_phase_actions_done = true
			_click_end_phase(scene)
			_wait = 1.0
		_:
			_click_end_phase(scene)
			_wait = 0.5

func _click_end_phase(scene: Node) -> void:
	var btn: Button = _find_node(scene, "EndTurnButton") as Button
	if btn and btn.visible:
		_log("UI BOT: Clicking End Phase button (phase=%d)" % _gm.get_current_phase())
		btn.pressed.emit()
	else:
		_log("UI BOT: EndTurnButton not found/hidden, trying space key")
		_send_space()

func _send_space() -> void:
	var ev := InputEventKey.new()
	ev.keycode = KEY_SPACE
	ev.pressed = true
	Input.parse_input_event(ev)
	var ev2 := InputEventKey.new()
	ev2.keycode = KEY_SPACE
	ev2.pressed = false
	Input.parse_input_event(ev2)

func _deploy_units(scene: Node) -> void:
	_log("UI BOT: Deploying units from hand...")
	var unit_side: Node = _find_node(scene, "UnitSide")
	if unit_side == null:
		_log("UI BOT: UnitSide not found")
		return
	var cards: Array = unit_side.get_children()
	var unit_cards: Array = []
	for c in cards:
		if c.has_signal("card_clicked"):
			unit_cards.append(c)
	_log("UI BOT: Found %d cards in UnitSide" % unit_cards.size())
	if unit_cards.size() == 0:
		return
	var card: Control = unit_cards[0]
	var card_data: Dictionary = {}
	if card.has_method("get_card_data"):
		card_data = card.get_card_data()
	elif "_card_data" in card:
		card_data = card.get("_card_data")
	if card_data.get("is_deployed", false):
		_log("UI BOT: Card is already deployed, skipping")
		return
	_log("UI BOT: Clicking card: %s" % Localization.get_card_name(card_data))
	card.card_clicked.emit(card_data)
	_wait = 0.5
	var territory_btns: Dictionary = {}
	var gm_script: Node = scene
	if "_territory_buttons" in gm_script:
		territory_btns = gm_script.get("_territory_buttons")
	var target: String = ""
	for t_id in territory_btns:
		var owner: String = _gm.get_territory_owner(t_id)
		if owner != "player" and owner != "enemy":
			target = t_id
			break
	if target == "":
		for t_id in territory_btns:
			target = t_id
			break
	if target != "" and territory_btns.has(target):
		var t_btn: Button = territory_btns[target]
		_log("UI BOT: Dropping card on territory: %s" % target)
		t_btn.pressed.emit()
	else:
		_log("UI BOT: No territory target found")

func _finish() -> void:
	_log("=== UI BOT END ===")
	_log("Turns played: %d" % _current_turn)
	var file := FileAccess.open("user://ui_bot_log.txt", FileAccess.WRITE)
	if file:
		for line in _log_lines:
			file.store_line(line)
		file.close()
	quit()
