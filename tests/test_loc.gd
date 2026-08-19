extends SceneTree

func _init():
	var csv_path = "res://data/localization/translations.csv"
	var csv_exists = FileAccess.file_exists(csv_path)
	print("CSV exists: ", csv_exists)

	var ru_path = "res://data/localization/translations.ru.translation"
	var en_path = "res://data/localization/translations.en.translation"
	print("RU exists: ", ResourceLoader.exists(ru_path))
	print("EN exists: ", ResourceLoader.exists(en_path))

	if ResourceLoader.exists(ru_path):
		var tr = load(ru_path)
		if tr:
			print("RU locale: ", tr.locale)
			print("RU message count: ", tr.get_message_count())
			var keys = tr.get_message_list()
			print("RU keys (first 5): ", keys.slice(0, 5))
			for k in ["quote.institutions", "quote.un_habitat", "btn.new_game"]:
				var val = tr.get_message(k)
				print("  ", k, " = ", val)
		else:
			print("RU translation load FAILED")

	if ResourceLoader.exists(en_path):
		var tr2 = load(en_path)
		if tr2:
			print("EN locale: ", tr2.locale)
			print("EN message count: ", tr2.get_message_count())
			for k in ["quote.institutions", "quote.un_habitat", "btn.new_game"]:
				var val = tr2.get_message(k)
				print("  ", k, " = ", val)
		else:
			print("EN translation load FAILED")

	if csv_exists:
		var f = FileAccess.open(csv_path, FileAccess.READ)
		if f:
			var line1 = f.get_csv_line()
			print("CSV header: ", line1)
			var line2 = f.get_csv_line()
			print("CSV line 2: ", line2)
			f.close()
		else:
			print("CSV open FAILED, error: ", FileAccess.get_open_error())

	print("=== DONE ===")
	quit()
