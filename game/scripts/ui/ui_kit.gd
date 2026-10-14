extends RefCounted
## Shared look for all screens: one Theme built in code so scene scripts stay free of styling details.

const JADE := Color("5fd1a5")
const INK := Color("0b1f1e")
const PAPER := Color("eef3e6")
const MIN_TOUCH := Vector2(360, 76)  # comfortably above the 44 px touch target at 1280x720

static var _theme: Theme


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font_size = 30
	t.set_color("font_color", "Label", PAPER)
	t.set_color("font_outline_color", "Label", Color(0.02, 0.08, 0.08, 0.9))
	t.set_constant("outline_size", "Label", 4)

	t.set_stylebox("normal", "Button", _box(Color(0.05, 0.14, 0.14, 0.78), JADE.darkened(0.35)))
	t.set_stylebox("hover", "Button", _box(Color(0.09, 0.24, 0.22, 0.88), JADE))
	t.set_stylebox("pressed", "Button", _box(Color(0.16, 0.38, 0.33, 0.95), JADE.lightened(0.2)))
	t.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), PAPER, 3))
	t.set_stylebox("disabled", "Button", _box(Color(0.05, 0.1, 0.1, 0.55), Color(0.35, 0.45, 0.43, 0.6)))
	t.set_color("font_color", "Button", PAPER)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(0.62, 0.7, 0.68, 0.8))
	_theme = t
	return t


static func _box(bg: Color, border: Color, border_w: int = 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(10)
	s.content_margin_left = 24
	s.content_margin_right = 24
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s


static func apply(root: Control) -> void:
	root.theme = theme()


static func make_button(min_size: Vector2 = MIN_TOUCH) -> Button:
	var b := Button.new()
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_ALL
	return b


static func make_label(font_size: int = 30, align: int = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", font_size)
	l.horizontal_alignment = align as HorizontalAlignment
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l
