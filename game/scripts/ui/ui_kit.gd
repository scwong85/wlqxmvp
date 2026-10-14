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

	# Panels, progress bars and the compact "card" button used for activity choices.
	t.set_stylebox("panel", "PanelContainer", _panel_box())
	t.set_stylebox("background", "ProgressBar", _bar_box(Color(0.02, 0.07, 0.07, 0.9)))
	t.set_stylebox("fill", "ProgressBar", _bar_box(JADE))
	t.set_color("font_color", "ProgressBar", Color.WHITE)

	t.add_type("CardButton")
	t.set_type_variation("CardButton", "Button")
	t.set_stylebox("normal", "CardButton", _card_box(Color(0.05, 0.14, 0.14, 0.85), JADE.darkened(0.45)))
	t.set_stylebox("hover", "CardButton", _card_box(Color(0.09, 0.24, 0.22, 0.92), JADE))
	t.set_stylebox("pressed", "CardButton", _card_box(Color(0.17, 0.42, 0.36, 0.97), JADE.lightened(0.25), 3))
	t.set_stylebox("hover_pressed", "CardButton", _card_box(Color(0.19, 0.45, 0.39, 0.97), JADE.lightened(0.35), 3))
	t.set_stylebox("disabled", "CardButton", _card_box(Color(0.05, 0.1, 0.1, 0.5), Color(0.35, 0.45, 0.43, 0.5)))
	t.set_stylebox("focus", "CardButton", _card_box(Color(0, 0, 0, 0), PAPER, 3))
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


static func _panel_box() -> StyleBoxFlat:
	var b := _box(Color(0.03, 0.10, 0.10, 0.74), JADE.darkened(0.55))
	b.content_margin_left = 16
	b.content_margin_right = 16
	b.content_margin_top = 12
	b.content_margin_bottom = 12
	return b


static func _card_box(bg: Color, border: Color, border_w: int = 2) -> StyleBoxFlat:
	var b := _box(bg, border, border_w)
	b.content_margin_left = 8
	b.content_margin_right = 8
	b.content_margin_top = 6
	b.content_margin_bottom = 6
	b.set_corner_radius_all(8)
	return b


static func _bar_box(color: Color) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = color
	b.set_corner_radius_all(6)
	return b


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


## Layout audit for a screen that must work in landscape. Returns a list of problems (empty = fine):
## text smaller than MIN_FONT, buttons shorter than MIN_TOUCH_HEIGHT, and visible controls that
## stick out of the viewport (scrolled content inside a ScrollContainer is exempt).
const MIN_FONT := 22
const MIN_TOUCH_HEIGHT := 44.0


static func audit(root: Control) -> Array[String]:
	var problems: Array[String] = []
	var view := root.get_viewport_rect().grow(1.0)
	_audit_node(root, view, false, problems)
	return problems


static func _audit_node(n: Node, view: Rect2, in_scroll: bool, problems: Array[String]) -> void:
	if n is Control:
		var c: Control = n
		if c.is_visible_in_tree():
			if c is Label or c is Button:
				var fs := c.get_theme_font_size("font_size")
				if fs < MIN_FONT:
					problems.append("%s: font size %d is below %d" % [c.name, fs, MIN_FONT])
			if c is Button and c.size.y < MIN_TOUCH_HEIGHT:
				problems.append("%s: touch target %.0f px high" % [c.name, c.size.y])
			if not in_scroll and c.size.x > 0 and c.size.y > 0 and not view.encloses(c.get_global_rect()):
				problems.append("%s: outside the viewport %s" % [c.name, str(c.get_global_rect())])
	var scrolled := in_scroll or n is ScrollContainer
	for child in n.get_children():
		_audit_node(child, view, scrolled, problems)
