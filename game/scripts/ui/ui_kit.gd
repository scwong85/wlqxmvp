extends RefCounted
## Shared look for all screens: one Theme built in code so scene scripts stay free of styling details.
## The look is a wuxia scroll: warm ink-brown panels with paper grain, gold lines, parchment text, vermilion seal buttons
## and a serif brush-like face for headings. Jade survives only as an accent (healing, success).

const WuxiaFrame = preload("res://scripts/ui/wuxia_frame.gd")

const JADE := Color("6fae98")        # accent only
const INK := Color("1b1511")         # ground of panels
const PAPER := Color("f3e9d2")       # parchment: body text
const GOLD := Color("e3c27a")        # headings and highlights
const GOLD_LINE := Color("c9a45c")   # borders
const GOLD_DIM := Color("8c6f3c")
const VERMILION := Color("a8352a")   # seal red: primary actions
const VERMILION_HI := Color("c9473a")
const MIN_TOUCH := Vector2(360, 76)  # comfortably above the 44 px touch target at 1280x720

const SERIF_PATH := "res://fonts/NotoSerifSC-subset.otf"
const PAPER_PATH := "res://art/ui/paper.jpg"

static var _theme: Theme
static var _serif: Font
static var _paper: Texture2D


## The heading face (a bold serif); null falls back to the default font.
static func serif() -> Font:
	if _serif == null and ResourceLoader.exists(SERIF_PATH):
		_serif = load(SERIF_PATH) as Font
	return _serif


static func paper() -> Texture2D:
	if _paper == null and ResourceLoader.exists(PAPER_PATH):
		_paper = load(PAPER_PATH) as Texture2D
	return _paper


## A brush-stroke plate (ink on transparent) as a panel style, for title banners. Null if the art is missing.
static func brush_plate_box() -> StyleBox:
	var path := "res://art/ui/brush_plate.png"
	if not ResourceLoader.exists(path):
		return null
	var b := StyleBoxTexture.new()
	b.texture = load(path) as Texture2D
	b.content_margin_left = 56
	b.content_margin_right = 56
	b.content_margin_top = 26
	b.content_margin_bottom = 30
	b.modulate_color = Color(1, 1, 1, 0.92)
	return b


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font_size = 30
	t.set_color("font_color", "Label", PAPER)
	t.set_color("font_outline_color", "Label", Color(0.06, 0.04, 0.03, 0.92))
	t.set_constant("outline_size", "Label", 4)

	t.set_stylebox("normal", "Button", _box(Color(0.10, 0.07, 0.05, 0.84), GOLD_DIM))
	t.set_stylebox("hover", "Button", _box(Color(0.17, 0.12, 0.08, 0.92), GOLD_LINE))
	t.set_stylebox("pressed", "Button", _box(VERMILION, GOLD))
	t.set_stylebox("hover_pressed", "Button", _box(VERMILION_HI, GOLD))
	t.set_stylebox("focus", "Button", _box(Color(0, 0, 0, 0), GOLD, 3))
	t.set_stylebox("disabled", "Button", _box(Color(0.09, 0.07, 0.06, 0.55), Color(0.4, 0.34, 0.26, 0.6)))
	t.set_color("font_color", "Button", PAPER)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", Color.WHITE)
	t.set_color("font_disabled_color", "Button", Color(0.66, 0.6, 0.5, 0.8))

	# The seal button: primary actions (start, confirm, continue) in vermilion with a gold rim.
	t.add_type("SealButton")
	t.set_type_variation("SealButton", "Button")
	t.set_stylebox("normal", "SealButton", _box(VERMILION, GOLD_LINE))
	t.set_stylebox("hover", "SealButton", _box(VERMILION_HI, GOLD))
	t.set_stylebox("pressed", "SealButton", _box(VERMILION.darkened(0.25), GOLD))
	t.set_stylebox("hover_pressed", "SealButton", _box(VERMILION_HI, GOLD))
	t.set_color("font_color", "SealButton", Color("fff3d6"))

	# Panels, progress bars and the compact "card" button used for activity choices.
	t.set_stylebox("panel", "PanelContainer", _panel_box())
	t.set_stylebox("background", "ProgressBar", _bar_box(Color(0.05, 0.035, 0.025, 0.92)))
	t.set_stylebox("fill", "ProgressBar", _bar_box(GOLD_LINE))
	t.set_color("font_color", "ProgressBar", Color.WHITE)

	t.set_stylebox("normal", "LineEdit", _box(Color(0.06, 0.045, 0.035, 0.92), GOLD_DIM))
	t.set_stylebox("focus", "LineEdit", _box(Color(0.08, 0.06, 0.045, 0.95), GOLD, 3))
	t.set_color("font_color", "LineEdit", PAPER)
	t.set_color("caret_color", "LineEdit", GOLD)
	t.set_color("selection_color", "LineEdit", Color(0.66, 0.21, 0.16, 0.7))

	t.add_type("CardButton")
	t.set_type_variation("CardButton", "Button")
	t.set_stylebox("normal", "CardButton", _card_box(Color(0.10, 0.07, 0.05, 0.86), GOLD_DIM))
	t.set_stylebox("hover", "CardButton", _card_box(Color(0.17, 0.12, 0.08, 0.93), GOLD_LINE))
	t.set_stylebox("pressed", "CardButton", _card_box(VERMILION, GOLD, 3))
	t.set_stylebox("hover_pressed", "CardButton", _card_box(VERMILION_HI, GOLD, 3))
	t.set_stylebox("disabled", "CardButton", _card_box(Color(0.09, 0.07, 0.06, 0.5), Color(0.4, 0.34, 0.26, 0.5)))
	t.set_stylebox("focus", "CardButton", _card_box(Color(0, 0, 0, 0), GOLD, 3))
	_theme = t
	return t


static func _box(bg: Color, border: Color, border_w: int = 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(4)
	s.content_margin_left = 24
	s.content_margin_right = 24
	s.content_margin_top = 12
	s.content_margin_bottom = 12
	return s


static func _panel_box() -> StyleBox:
	var f := WuxiaFrame.new()
	f.paper = paper()
	f.set_content_margin_all(18)
	f.content_margin_top = 14
	f.content_margin_bottom = 14
	return f


static func _card_box(bg: Color, border: Color, border_w: int = 2) -> StyleBoxFlat:
	var b := _box(bg, border, border_w)
	b.content_margin_left = 8
	b.content_margin_right = 8
	b.content_margin_top = 6
	b.content_margin_bottom = 6
	b.set_corner_radius_all(4)
	return b


static func _bar_box(color: Color) -> StyleBoxFlat:
	var b := StyleBoxFlat.new()
	b.bg_color = color
	b.set_corner_radius_all(4)
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
	if font_size >= 32 and serif() != null:
		l.add_theme_font_override("font", serif())   # headings in the serif face
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
