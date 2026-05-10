class_name HelpUI
extends RefCounted

var _map: Control = null

func _init(map: Control) -> void:
	_map = map

func show_help() -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.9)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.z_index = 500
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_map.add_child(overlay)
	var scroll := ScrollContainer.new()
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.offset_left = 40
	scroll.offset_top = 20
	scroll.offset_right = -40
	scroll.offset_bottom = -60
	scroll.z_index = 501
	overlay.add_child(scroll)
	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.custom_minimum_size = Vector2(0, 0)
	scroll.add_child(vbox)
	var sections := [
		{"title": "КАК ИГРАТЬ", "text": "БомжХаммер — пошаговая карточная стратегия. Вы управляете империей бездомных, захватывая территории на карте города.\n\nКаждый ход состоит из фаз: Ресурсы -> Розыгрыш -> Перемещение -> Бой -> События -> Конец.\n\nНажимайте 'Конец фазы' для перехода к следующей."},
		{"title": "КАК ЗАХВАТЫВАТЬ ТЕРРИТОРИИ", "text": "1. Кликните ЛЕВОЙ кнопкой на СВОЮ территорию — она подсветится, отряды появятся внизу слева.\n2. Кликните ПРАВОЙ кнопкой на ВРАЖЕСКУЮ или НЕЙТРАЛЬНУЮ соседнюю территорию — все ваши отряды атакуют.\n3. Атаковать можно только СОСЕДНИЕ территории (связанные дорогами).\n4. Можно перетаскивать отряды из руки на территорию — ЛЕВЫЙ клик по карте -> перетащить на территорию -> отпустить.\n5. Если на территории нет врага — она захватывается без боя."},
		{"title": "КАК ПЕРЕМЕЩАТЬ ОТРЯДЫ", "text": "ЛЕВЫЙ клик по карте отряда в руке -> карта прилипнет к курсору -> наведите на территорию -> отпустите кнопку.\n\nТакже можно перетащить отряд с одной своей территории на другую свою — перетаскиванием как из руки."},
		{"title": "ВЕРОВАНИЕ (3 территории)", "text": "При захвате 3 территорий появляется выбор верования:\n\nМНОГОБОМЖИЕ — вера в древних бомжей-покровителей. Бог свалки, бог вокзала, бог картона, бог полторашки. Разные бонусы.\n\nТРЕЗВОСТЬ — путь воздержания. +производительность, но алкогольные карты заблокированы."},
		{"title": "СТРОЙ (5 территорий)", "text": "При захвате 5 территорий появляется выбор строя:\n\nАЛКОГОЛИЗМ — тоталитарный строй. 0 налогов. Водка правит. +1 карта отряда при доборе.\n\nДЕРЬМОКРАТИЯ — свободный рынок мусора. +25% к мелочишке. Торговля краденым."},
		{"title": "РЕСУРСЫ", "text": "АЛЮМИНИЕВЫЕ БАНКИ — основная валюта. Добываются на свалках.\n\nМЕЛОЧИШКА — мелкие деньги. С вокзалов, попрошайничества.\n\nВОДКА (РОЛЛТОНЫ) — и валюта, и ресурс, и боевое средство. Производится самогонными реакторами.\n\nКАРТОН — строительный материал. Для построек и техники.\n\nУВАЖЕНИЕ — влияние. От действий и завоеваний.\n\nНАСЕЛЕНИЕ — количество подданных. Растёт от ночлежек, падает от облав и голода."},
		{"title": "ТИПЫ КАРТ", "text": "ОТРЯДЫ (правая колода) — боевые единицы с ATK/DEF/HP. Размещаются на территориях.\n\nСИТУАЦИИ (левая колода) — события, эффекты, достижения. Разыгрываются автоматически.\n\nЗАКЛИНАНИЯ (левая колода) — буффы и дебаффы. Бафф дают бонус, проклятья штраф.\n\nКОМАНДИРЫ — сильные отряды с особыми способностями."},
		{"title": "БОЕВАЯ СИСТЕМА", "text": "Урон = ATK атакующего - DEF обороняющегося (минимум 0) + бросок d6.\n\nМодификаторы территории добавляются к DEF.\n\nЗаклинания могут менять ATK/DEF.\n\nHP уменьшается, при HP <= 0 отряд уничтожен.\n\nНАГЛОСТЬ — каждый второй ход добавляет урон с 50% шансом."},
		{"title": "МАРКЕРЫ НА ТЕРРИТОРИЯХ", "text": "xN (жёлтый) — ваши отряды.\n\n[xN] (зелёный) — NPC-гарнизон (враг).\n\nНейтральные территории содержат 1-5 NPC. Вражеские — 3-10 NPC."}
	]
	for sec in sections:
		var t := Label.new()
		t.text = sec["title"]
		t.add_theme_font_size_override("font_size", 30)
		t.add_theme_color_override("font_color", Color(1, 0.84, 0))
		t.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		t.add_theme_constant_override("outline_size", 3)
		vbox.add_child(t)
		var d := Label.new()
		d.text = sec["text"]
		d.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		d.custom_minimum_size = Vector2(800, 0)
		d.add_theme_font_size_override("font_size", 22)
		d.add_theme_color_override("font_color", Color(1, 1, 1))
		d.add_theme_color_override("font_outline_color", Color(0, 0, 0))
		d.add_theme_constant_override("outline_size", 2)
		vbox.add_child(d)
		var sp := Control.new()
		sp.custom_minimum_size = Vector2(0, 15)
		vbox.add_child(sp)
	var close_btn := Button.new()
	close_btn.text = "ЗАКРЫТЬ"
	close_btn.custom_minimum_size = Vector2(200, 50)
	close_btn.z_index = 502
	close_btn.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	close_btn.offset_top = -60
	close_btn.offset_left = -120
	close_btn.offset_right = -120
	overlay.add_child(close_btn)
	close_btn.pressed.connect(func(): overlay.queue_free())
