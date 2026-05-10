extends RefCounted

static func style_card_name(label: Label) -> void:
	label.add_theme_font_size_override("font_size", 28)
	label.add_theme_color_override("font_color", Color(0, 0, 0))
	label.add_theme_color_override("font_outline_color", Color(1, 1, 1))
	label.add_theme_constant_override("outline_size", 5)

static func style_card_name_mini(label: Label) -> void:
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color(0, 0, 0))
	label.add_theme_color_override("font_outline_color", Color(1, 1, 1))
	label.add_theme_constant_override("outline_size", 4)

static func style_card_name_large(label: Label) -> void:
	label.add_theme_font_size_override("font_size", 36)
	label.add_theme_color_override("font_color", Color(0, 0, 0))
	label.add_theme_color_override("font_outline_color", Color(1, 1, 1))
	label.add_theme_constant_override("outline_size", 6)
