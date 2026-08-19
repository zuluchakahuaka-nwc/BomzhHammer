extends Node

static func texture(path: String) -> Texture2D:
	var tex = load(path)
	if tex is Texture2D:
		return tex
	return null

static func font(path: String) -> FontFile:
	if FileAccess.file_exists(path):
		var f := FontFile.new()
		if f.load_dynamic_font(path) == OK:
			return f
	var res = load(path)
	if res is FontFile:
		return res
	return null

static func audio(path: String) -> AudioStream:
	var res = load(path)
	if res is AudioStream:
		return res
	if FileAccess.file_exists(path):
		if path.ends_with(".mp3"):
			var data := FileAccess.get_file_as_bytes(path)
			if data.size() > 0:
				var s := AudioStreamMP3.new()
				s.data = data
				return s
		elif path.ends_with(".ogg"):
			var data := FileAccess.get_file_as_bytes(path)
			if data.size() > 0:
				var s := AudioStreamOggVorbis.new()
				var seq := AudioStreamOggVorbis.load_from_buffer(data)
				if seq != null:
					return seq
		elif path.ends_with(".wav"):
			var f := FileAccess.open(path, FileAccess.READ)
			if f:
				var s := AudioStreamWAV.new()
				s.data = f.get_buffer(f.get_length())
				f.close()
				return s
	return null

static func image(path: String) -> Image:
	var tex = load(path)
	if tex is Texture2D:
		var img: Image = tex.get_image()
		if img != null:
			return img
	return null
