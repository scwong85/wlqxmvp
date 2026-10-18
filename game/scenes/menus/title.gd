extends Control
## Title screen: new game, load game (disabled until saves exist), settings.

const UiKit = preload("res://scripts/ui/ui_kit.gd")
const Backdrop = preload("res://scenes/shared/backdrop.gd")
const SafeFrame = preload("res://scenes/shared/safe_frame.gd")

var start_button: Button
var load_button: Button
var settings_button: Button
var practice_button: Button
var _pair: HBoxContainer
var fullscreen_button: Button   # web only

var _name_label: Label
var _tagline_label: Label
var load_note: Label

var _load_error: String = ""
var _build_label: Label
var _box: VBoxContainer
var _name_wrap: PanelContainer


## Painted title art (art/title_key.jpg) behind the menu, with a soft dark scrim so the buttons and title stay readable.
func _add_key_art() -> void:
	var tex := TextureRect.new()
	tex.texture = load("res://art/title_key.jpg") as Texture2D
	tex.set_anchors_preset(Control.PRESET_FULL_RECT)
	tex.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tex.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tex.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tex)
	var scrim := ColorRect.new()
	scrim.color = Color(0.06, 0.04, 0.03, 0.42)
	scrim.set_anchors_preset(Control.PRESET_FULL_RECT)
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(scrim)


func _ready() -> void:
	UiKit.apply(self)
	add_child(Backdrop.new())
	if ResourceLoader.exists("res://art/title_key.jpg"):
		_add_key_art()
	var frame := SafeFrame.new()
	add_child(frame)

	var box := VBoxContainer.new()
	_box = box
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 18)
	frame.add_child(box)

	_name_label = UiKit.make_label(96)
	_name_label.add_theme_constant_override("outline_size", 8)
	_tagline_label = UiKit.make_label(34)
	_tagline_label.add_theme_constant_override("outline_size", 9)   # legible over the light key art
	_name_label.modulate = UiKit.GOLD
	var plate := UiKit.brush_plate_box()
	if plate != null:
		_name_wrap = PanelContainer.new()
		_name_wrap.add_theme_stylebox_override("panel", plate)
		_name_wrap.add_child(_name_label)
		box.add_child(_name_wrap)
	else:
		box.add_child(_name_label)
	box.add_child(_tagline_label)
	box.add_child(_spacer(28))

	start_button = UiKit.make_button()
	start_button.theme_type_variation = "SealButton"
	load_button = UiKit.make_button()
	settings_button = UiKit.make_button()
	practice_button = UiKit.make_button()
	for b in [start_button, load_button]:
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		box.add_child(b)
	# Practice and Settings share one row so the menu keeps its height in landscape.
	_pair = HBoxContainer.new()
	var pair := _pair
	pair.add_theme_constant_override("separation", 12)
	pair.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	box.add_child(pair)
	for b in [practice_button, settings_button]:
		b.custom_minimum_size = Vector2(0, 76)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		pair.add_child(b)
	pair.custom_minimum_size = Vector2(480, 0)

	if Layout.fullscreen_available():
		fullscreen_button = UiKit.make_button()
		fullscreen_button.pressed.connect(func() -> void: Layout.toggle_fullscreen())
		box.add_child(fullscreen_button)

	# Touch users cannot hover for a tooltip, so the reason is also shown as visible text.
	load_note = UiKit.make_label(24)
	load_note.modulate = Color(1, 1, 1, 0.9)
	load_note.add_theme_constant_override("outline_size", 8)
	box.add_child(load_note)
	_build_label = UiKit.make_label(22)
	_build_label.modulate = Color(1, 1, 1, 0.8)
	_build_label.add_theme_constant_override("outline_size", 8)
	box.add_child(_build_label)

	start_button.pressed.connect(_on_start)
	load_button.pressed.connect(_on_load)
	settings_button.pressed.connect(func() -> void:
		Router.settings_back = "title"
		Router.goto("settings"))
	practice_button.pressed.connect(_on_practice)
	Loc.locale_changed.connect(func(_c: String) -> void: _refresh())
	Layout.mode_changed.connect(func(_m: String) -> void: _apply_layout())
	_refresh()
	_apply_layout()
	start_button.grab_focus()
	print("TITLE_READY load_enabled=%s" % (not load_button.disabled))
	_report_positions()


## Landscape: big title and compact buttons on the left. Portrait: centred column, full-width buttons.
func _apply_layout() -> void:
	var portrait: bool = Layout.is_portrait()
	# Portrait: the menu sits in the top half so the painted heroes at the bottom of the key art stay visible.
	_box.alignment = BoxContainer.ALIGNMENT_BEGIN if portrait else BoxContainer.ALIGNMENT_CENTER
	for b in [start_button, load_button, practice_button, settings_button, fullscreen_button]:
		if b != null:
			b.custom_minimum_size.y = 64.0 if portrait else 76.0
	_name_label.add_theme_font_size_override("font_size", (72 if _name_label.text.length() <= 8 else 60) if portrait else 88)
	_tagline_label.add_theme_font_size_override("font_size", 28 if portrait else 34)
	var align := HORIZONTAL_ALIGNMENT_CENTER if portrait else HORIZONTAL_ALIGNMENT_LEFT
	if _name_wrap != null:
		var sb: StyleBoxTexture = _name_wrap.get_theme_stylebox("panel") as StyleBoxTexture
		if sb != null:   # a slimmer plate in landscape, where the menu has to fit 720 px
			sb.content_margin_top = 26.0 if portrait else 2.0
			sb.content_margin_bottom = 30.0 if portrait else 4.0
		# Portrait: the plate spans the width and a long (English) title wraps inside it. Landscape: shrink to the text.
		_name_wrap.size_flags_horizontal = Control.SIZE_FILL if portrait else Control.SIZE_SHRINK_BEGIN
		_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if portrait else TextServer.AUTOWRAP_OFF
		_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for l in [_name_label, _tagline_label, load_note, _build_label]:
		l.horizontal_alignment = align
	var buttons: Array = [start_button, load_button]
	if fullscreen_button != null:
		buttons.append(fullscreen_button)
	_pair.size_flags_horizontal = Control.SIZE_FILL if portrait else Control.SIZE_SHRINK_BEGIN
	_pair.custom_minimum_size.x = 0.0 if portrait else 480.0
	for b in buttons:
		b.size_flags_horizontal = Control.SIZE_FILL if portrait else Control.SIZE_SHRINK_BEGIN


func _refresh() -> void:
	_name_label.text = Loc.t("title.name")
	_tagline_label.text = Loc.t("title.tagline")
	start_button.text = Loc.t("ui.start")
	load_button.text = Loc.t("ui.load")
	settings_button.text = Loc.t("ui.settings")
	practice_button.text = Loc.t("title.practice")
	if fullscreen_button != null:
		fullscreen_button.text = Loc.t("ui.fullscreen")
	_refresh_load()
	_build_label.text = Loc.t("ui.build", {"v": "0.1 M1"})


## For the browser test: where the buttons are, once the layout has settled.
func _report_positions() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var vp := get_viewport_rect().size
	var parts: Array[String] = []
	for pair in [["start", start_button], ["practice", practice_button], ["settings", settings_button]]:
		var c: Control = pair[1]
		var p := c.get_global_rect().get_center()
		parts.append("%s=%d,%d" % [pair[0], int(p.x), int(p.y)])
	print("UI_POS vp=%d,%d %s" % [int(vp.x), int(vp.y), " ".join(parts)])


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _on_practice() -> void:
	Game.ensure_state()
	if Game.start_battle("training_match", "practice"):
		Router.goto("battle")


func _on_start() -> void:
	Router.goto("hero_creation")


func _on_load() -> void:
	var r: Dictionary = Game.load_latest()
	if r.ok:
		Router.goto("cultivation")
	else:
		_load_error = r.error_key
		_refresh_load()


## Load is available whenever any save file exists. The note says what is in it, or what is wrong.
func _refresh_load() -> void:
	var has_save: bool = Saves.has_any()
	load_button.disabled = not has_save
	if _load_error != "":
		load_note.text = Loc.t(_load_error)
	elif not has_save:
		load_note.text = Loc.t("ui.load_disabled")
	else:
		var r: Dictionary = Saves.load_latest()
		if r.ok:
			load_note.text = Loc.t("ui.load_hint", {"year": r.state.calendar.year(), "month": r.state.calendar.month(), "week": r.state.calendar.week_in_month(), "slot": r.state.calendar.slot})
		else:
			load_note.text = Loc.t(r.error_key)
	load_button.tooltip_text = load_note.text
