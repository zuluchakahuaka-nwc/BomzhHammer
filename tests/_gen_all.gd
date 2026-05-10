extends SceneTree

func _hash_int(s: String, seed_val: int) -> int:
	var h: int = seed_val
	for i in range(s.length()):
		h = (h * 31 + s.unicode_at(i)) % 2147483647
	if h < 0: h = -h
	return h

func _hash_color(s: String, seed_val: int) -> Color:
	var h: int = _hash_int(s, seed_val)
	var r: float = float(h % 256) / 256.0
	h = (h * 31 + 7) % 2147483647
	var g: float = float(h % 256) / 256.0
	h = (h * 31 + 13) % 2147483647
	var b: float = float(h % 256) / 256.0
	return Color(r, g, b)

func _fill_circle(img: Image, cx: int, cy: int, radius: int, color: Color) -> void:
	for y in range(cy - radius, cy + radius + 1):
		for x in range(cx - radius, cx + radius + 1):
			if (x - cx) * (x - cx) + (y - cy) * (y - cy) <= radius * radius:
				if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
					img.set_pixel(x, y, color)

func _fill_rect(img: Image, rx: int, ry: int, rw: int, rh: int, color: Color) -> void:
	for y in range(ry, ry + rh):
		for x in range(rx, rx + rw):
			if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
				img.set_pixel(x, y, color)

func _fill_ellipse(img: Image, cx: int, cy: int, rx: int, ry: int, color: Color) -> void:
	for y in range(cy - ry, cy + ry + 1):
		for x in range(cx - rx, cx + rx + 1):
			var dx: float = float(x - cx) / float(rx) if rx > 0 else 0.0
			var dy: float = float(y - cy) / float(ry) if ry > 0 else 0.0
			if dx * dx + dy * dy <= 1.0:
				if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
					img.set_pixel(x, y, color)

func _fill_triangle(img: Image, x1: int, y1: int, x2: int, y2: int, x3: int, y3: int, color: Color) -> void:
	var min_x: int = mini(x1, mini(x2, x3))
	var max_x: int = maxi(x1, maxi(x2, x3))
	var min_y: int = mini(y1, mini(y2, y3))
	var max_y: int = maxi(y1, maxi(y2, y3))
	for y in range(min_y, max_y + 1):
		for x in range(min_x, max_x + 1):
			var d1: float = float((x - x2) * (y1 - y2) - (x1 - x2) * (y - y2))
			var d2: float = float((x - x3) * (y2 - y3) - (x2 - x3) * (y - y3))
			var d3: float = float((x - x1) * (y3 - y1) - (x3 - x1) * (y - y1))
			var has_neg: bool = (d1 < 0) or (d2 < 0) or (d3 < 0)
			var has_pos: bool = (d1 > 0) or (d2 > 0) or (d3 > 0)
			if not (has_neg and has_pos):
				if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
					img.set_pixel(x, y, color)

func _draw_person(img: Image, id: String, card_type: String, subtype: String) -> void:
	var W: int = img.get_width()
	var H: int = img.get_height()
	var h: int = _hash_int(id, 1)
	var skin_tones: Array = [Color(0.96, 0.80, 0.69), Color(0.87, 0.72, 0.53), Color(0.70, 0.50, 0.35), Color(0.55, 0.38, 0.22), Color(0.40, 0.26, 0.13)]
	var skin: Color = skin_tones[h % skin_tones.size()]
	var cloth_color: Color = _hash_color(id + "cloth", 42)
	cloth_color.v = clampf(cloth_color.v * 0.4 + 0.2, 0.2, 0.7)
	cloth_color.s = clampf(cloth_color.s * 0.5 + 0.2, 0.2, 0.8)
	var pants_color: Color = cloth_color.darkened(0.3)
	var boot_color: Color = Color(0.15, 0.1, 0.08)
	var hair_color: Color = _hash_color(id + "hair", 77)
	hair_color.v = clampf(hair_color.v * 0.3, 0.05, 0.35)
	var cx: int = W / 2
	var fatness: int = 35 + h % 20
	h = (h * 31 + 7) % 2147483647
	var head_r: int = 40 + h % 15
	var body_top: int = 220
	var body_bot: int = 480
	var head_y: int = body_top - head_r + 10

	_fill_ellipse(img, cx, body_bot + 60, fatness + 15, 30, Color(0.3, 0.25, 0.2))
	_fill_ellipse(img, cx, body_bot + 50, fatness + 10, 25, Color(0.25, 0.2, 0.15))
	_fill_ellipse(img, cx - fatness - 5, body_bot + 50, 20, 15, boot_color)
	_fill_ellipse(img, cx + fatness + 5, body_bot + 50, 20, 15, boot_color)
	_fill_ellipse(img, cx, body_bot, fatness + 5, 60, pants_color)
	_fill_ellipse(img, cx, (body_top + body_bot) / 2, fatness + 10, (body_bot - body_top) / 2, cloth_color)
	_fill_circle(img, cx, head_y, head_r, skin)
	_fill_ellipse(img, cx, head_y - head_r + 5, head_r + 5, head_r / 2, hair_color)

	var hat_type: int = _hash_int(id + "hat", 33) % 4
	match hat_type:
		0:
			_fill_ellipse(img, cx, head_y - head_r - 10, head_r + 15, 15, _hash_color(id + "hatc", 44))
			_fill_rect(img, cx - head_r - 20, head_y - head_r - 12, head_r * 2 + 40, 6, _hash_color(id + "hatc", 44).darkened(0.2))
		1:
			_fill_ellipse(img, cx, head_y - head_r - 5, head_r + 5, 20, _hash_color(id + "hatc", 44))
		2:
			_fill_circle(img, cx, head_y - head_r - 15, 25, _hash_color(id + "hatc", 44))
		3:
			pass

	var eye_y: int = head_y - 3
	_fill_circle(img, cx - 14, eye_y, 5, Color.WHITE)
	_fill_circle(img, cx + 14, eye_y, 5, Color.WHITE)
	_fill_circle(img, cx - 14, eye_y, 3, Color(0.1, 0.1, 0.1))
	_fill_circle(img, cx + 14, eye_y, 3, Color(0.1, 0.1, 0.1))
	_fill_ellipse(img, cx, eye_y + 20, 12, 4, Color(0.6, 0.3, 0.3))

	var beard_type: int = _hash_int(id + "beard", 55) % 3
	match beard_type:
		0: _fill_triangle(img, cx - 15, eye_y + 25, cx + 15, eye_y + 25, cx, eye_y + 55, hair_color.lightened(0.1))
		1: _fill_ellipse(img, cx, eye_y + 30, 18, 15, hair_color.lightened(0.1))
		2: pass

	var nose_y: int = eye_y + 10
	_fill_circle(img, cx, nose_y, 4, skin.darkened(0.15))

	h = _hash_int(id + "arm", 99)
	var arm_angle: float = float(h % 60 - 30) * 0.01
	_fill_ellipse(img, cx - fatness - 20, (body_top + body_bot) / 2, 15, 50, cloth_color.darkened(0.1))
	_fill_ellipse(img, cx + fatness + 20, (body_top + body_bot) / 2, 15, 50, cloth_color.darkened(0.1))
	_fill_circle(img, cx - fatness - 20, (body_top + body_bot) / 2 + 45, 10, skin)
	_fill_circle(img, cx + fatness + 20, (body_top + body_bot) / 2 + 45, 10, skin)

	var prop_type: int = _hash_int(id + "prop", 88) % 6
	var prop_color: Color = Color(0.0, 0.6, 0.2)
	match prop_type:
		0:
			var bottle_y: int = (body_top + body_bot) / 2 + 40
			_fill_rect(img, cx + fatness + 14, bottle_y, 12, 50, Color(0.2, 0.5, 0.2, 0.8))
			_fill_rect(img, cx + fatness + 17, bottle_y - 15, 6, 18, Color(0.2, 0.5, 0.2, 0.8))
		1:
			var stick_y: int = body_top - 20
			_fill_rect(img, cx - fatness - 30, stick_y, 6, 280, Color(0.45, 0.3, 0.15))
		2:
			var bag_y: int = (body_top + body_bot) / 2
			_fill_rect(img, cx + fatness + 8, bag_y - 10, 25, 30, Color(0.4, 0.35, 0.2))
			_fill_rect(img, cx + fatness + 10, bag_y - 15, 21, 6, Color(0.3, 0.25, 0.15))
		3:
			var sign_y: int = (body_top + body_bot) / 2 - 30
			_fill_rect(img, cx + fatness + 5, sign_y, 40, 4, Color(0.4, 0.3, 0.15))
			_fill_rect(img, cx + fatness + 10, sign_y - 25, 30, 25, Color(0.6, 0.55, 0.3))
		4:
			_fill_ellipse(img, cx - fatness - 25, (body_top + body_bot) / 2 + 50, 12, 12, Color(0.6, 0.4, 0.1))
			_fill_ellipse(img, cx + fatness + 25, (body_top + body_bot) / 2 + 50, 12, 12, Color(0.6, 0.4, 0.1))
		5:
			_fill_rect(img, cx + fatness + 10, body_top + 20, 8, 80, Color(0.5, 0.5, 0.5))
			_fill_circle(img, cx + fatness + 14, body_top + 15, 10, Color(0.5, 0.5, 0.5))

func _draw_scene(img: Image, id: String) -> void:
	var W: int = img.get_width()
	var H: int = img.get_height()
	var h: int = _hash_int(id, 200)
	var scene_type: int = h % 8
	var c1: Color = _hash_color(id + "bg1", 10)
	var c2: Color = _hash_color(id + "bg2", 20)
	c1.v = clampf(c1.v * 0.3 + 0.15, 0.1, 0.5)
	c2.v = clampf(c2.v * 0.3 + 0.15, 0.1, 0.5)
	for y in range(H):
		var t: float = float(y) / float(H)
		for x in range(W):
			img.set_pixel(x, y, c1.lerp(c2, t))

	var ground_y: int = H * 2 / 3
	var ground_c: Color = _hash_color(id + "ground", 30)
	ground_c.v = clampf(ground_c.v * 0.4, 0.1, 0.4)
	_fill_rect(img, 0, ground_y, W, H - ground_y, ground_c)

	match scene_type:
		0:
			_fill_triangle(img, 50, ground_y, 150, ground_y - 200, 250, ground_y, Color(0.3, 0.25, 0.2))
			_fill_triangle(img, 200, ground_y, 350, ground_y - 250, 500, ground_y, Color(0.35, 0.28, 0.18))
			_fill_rect(img, 300, ground_y - 100, 80, 100, Color(0.4, 0.3, 0.15))
			_fill_triangle(img, 290, ground_y - 150, 340, ground_y - 200, 390, ground_y - 150, Color(0.5, 0.2, 0.1))
		1:
			_fill_rect(img, 100, ground_y - 180, 120, 180, Color(0.3, 0.3, 0.35))
			_fill_rect(img, 115, ground_y - 160, 25, 40, Color(0.6, 0.8, 0.6))
			_fill_rect(img, 175, ground_y - 160, 25, 40, Color(0.6, 0.8, 0.6))
			_fill_rect(img, 300, ground_y - 150, 100, 150, Color(0.35, 0.3, 0.25))
			_fill_triangle(img, 290, ground_y - 190, 350, ground_y - 240, 410, ground_y - 190, Color(0.4, 0.25, 0.15))
		2:
			_fill_rect(img, 50, ground_y - 60, 400, 60, Color(0.35, 0.35, 0.3))
			_fill_rect(img, 80, ground_y - 200, 8, 200, Color(0.4, 0.4, 0.35))
			_fill_rect(img, 420, ground_y - 200, 8, 200, Color(0.4, 0.4, 0.35))
			_fill_triangle(img, 70, ground_y - 200, 90, ground_y - 300, 110, ground_y - 200, Color(0.5, 0.4, 0.2))
		3:
			for i in range(5):
				var bx: int = (h * (i + 1) * 47) % (W - 60) + 30
				by = ground_y - 40 - i * 20
				_fill_rect(img, bx, by, 50, 40, Color(0.6, 0.5, 0.3, 0.8))
		4:
			_fill_ellipse(img, W / 2, H / 3, 180, 80, Color(0.5, 0.45, 0.3))
			_fill_rect(img, W / 2 - 20, H / 3 + 60, 40, 120, Color(0.4, 0.35, 0.2))
		5:
			_fill_rect(img, 150, ground_y - 120, 200, 120, Color(0.3, 0.3, 0.28))
			_fill_rect(img, 170, ground_y - 100, 40, 50, Color(0.15, 0.1, 0.08))
			_fill_rect(img, 290, ground_y - 100, 40, 50, Color(0.15, 0.1, 0.08))
			_fill_rect(img, 230, ground_y - 160, 30, 40, Color(0.15, 0.1, 0.08))
		6:
			for i in range(8):
				var tx: int = 30 + i * 60
				var ty: int = ground_y - 10
				_fill_rect(img, tx, ty - 80, 8, 80, Color(0.4, 0.3, 0.15))
				_fill_circle(img, tx + 4, ty - 90, 25, Color(0.2, 0.5, 0.15))
		7:
			_fill_rect(img, 100, ground_y - 250, 300, 250, Color(0.25, 0.25, 0.3))
			var wy: int = ground_y - 200
			for row in range(4):
				for col in range(3):
					_fill_rect(img, 130 + col * 80, wy + row * 55, 40, 30, Color(0.6, 0.75, 0.85))

	var icon_color: Color = _hash_color(id + "icon", 50)
	icon_color.v = clampf(icon_color.v * 0.5 + 0.4, 0.4, 0.9)
	icon_color.s = clampf(icon_color.s * 0.6 + 0.3, 0.3, 0.9)
	_fill_circle(img, W - 70, 70, 40, icon_color)
	_fill_circle(img, W - 70, 70, 30, icon_color.lightened(0.3))

var by: int = 0

func _init():
	var f := FileAccess.open("res://data/cards/units.json", FileAccess.READ)
	var txt := f.get_as_text()
	f.close()
	var j := JSON.new()
	j.parse(txt)
	var units: Array = j.data
	for u in units:
		var id: String = u.get("id", "")
		var rarity: String = u.get("rarity", "common")
		var subtype: String = u.get("subtype", "infantry")
		var W: int = 512
		var H: int = 768
		var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
		var bg := _hash_color(id + "bg", 11)
		bg.v = clampf(bg.v * 0.25 + 0.08, 0.05, 0.35)
		var bg2 := _hash_color(id + "bg2", 22)
		bg2.v = clampf(bg2.v * 0.25 + 0.12, 0.08, 0.4)
		for y in range(H):
			var t: float = float(y) / float(H)
			for x in range(W):
				img.set_pixel(x, y, bg.lerp(bg2, t))
		_draw_person(img, id, "unit", subtype)
		var border_color := Color(0.55, 0.55, 0.55)
		match rarity:
			"common": border_color = Color(0.55, 0.55, 0.55)
			"uncommon": border_color = Color(0.15, 0.65, 0.15)
			"rare": border_color = Color(0.2, 0.45, 0.95)
			"legendary": border_color = Color(1.0, 0.84, 0.0)
		for x in range(W):
			for b in range(4):
				img.set_pixel(x, b, border_color)
				img.set_pixel(x, H - 1 - b, border_color)
		for y in range(H):
			for b in range(4):
				img.set_pixel(b, y, border_color)
				img.set_pixel(W - 1 - b, y, border_color)
		var path: String = "res://assets/sprites/cards/units/%s.png" % id
		img.save_png(path)
		print("OK: %s" % id)

	f = FileAccess.open("res://data/cards/situations.json", FileAccess.READ)
	txt = f.get_as_text()
	f.close()
	j = JSON.new()
	j.parse(txt)
	var sits: Array = j.data
	for s in sits:
		var id: String = s.get("id", "")
		var rarity: String = s.get("rarity", "common")
		var W: int = 512
		var H: int = 768
		var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
		_draw_scene(img, id)
		var border_color := Color(0.55, 0.55, 0.55)
		match rarity:
			"common": border_color = Color(0.55, 0.55, 0.55)
			"uncommon": border_color = Color(0.15, 0.65, 0.15)
			"rare": border_color = Color(0.2, 0.45, 0.95)
			"legendary": border_color = Color(1.0, 0.84, 0.0)
		for x in range(W):
			for b in range(4):
				img.set_pixel(x, b, border_color)
				img.set_pixel(x, H - 1 - b, border_color)
		for y in range(H):
			for b in range(4):
				img.set_pixel(b, y, border_color)
				img.set_pixel(W - 1 - b, y, border_color)
		var path: String = "res://assets/sprites/cards/situations/%s.png" % id
		img.save_png(path)
		print("OK: %s" % id)
	quit()