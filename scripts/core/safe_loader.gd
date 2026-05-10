extends Node

static func texture(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var tex = load(path)
		if tex is Texture2D:
			return tex
	if FileAccess.file_exists(path):
		var img := Image.new()
		if img.load(path) == OK and img.get_width() > 0:
			return ImageTexture.create_from_image(img)
	return null

static func font(path: String) -> FontFile:
	if FileAccess.file_exists(path):
		var f := FontFile.new()
		if f.load_dynamic_font(path) == OK:
			return f
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is FontFile:
			return res
	return null

static func audio(path: String) -> AudioStream:
	if FileAccess.file_exists(path):
		if path.ends_with(".mp3"):
			var data := FileAccess.get_file_as_bytes(path)
			if data.size() > 0:
				var s := AudioStreamMP3.new()
				s.data = data
				return s
		elif path.ends_with(".wav"):
			var f := FileAccess.open(path, FileAccess.READ)
			if f:
				var s := AudioStreamWAV.new()
				s.data = f.get_buffer(f.get_length())
				f.close()
				return s
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is AudioStream:
			return res
	return null

static func image(path: String) -> Image:
	if FileAccess.file_exists(path):
		var img := Image.new()
		if img.load(path) == OK and img.get_width() > 0:
			return img
	return null
