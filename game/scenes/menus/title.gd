extends Control
## Title screen: new game, load game (disabled until saves exist), settings.

const UiKit = preload("res://scripts/ui/ui_kit.gd")
const Backdrop = preload("res://scenes/shared/backdrop.gd")
const SafeFrame = preload("res://scenes/shared/safe_frame.gd")

var start_button: Button
var load_button: Button
var settings_button: Button
var fullscreen_button: Button   # web only

var _name_label: Label
var _tagline_label: Label
var load_note: Label

var _load_error: String = ""
var _build_label: Label
var _box: VBoxContainer


func _ready() -> void:
	UiKit.apply(self)
	add_child(Backdrop.new())
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
	box.add_child(_name_label)
	box.add_child(_tagline_label)
	box.add_child(_spacer(28))

	start_button = UiKit.make_button()
	load_button = UiKit.make_button()
	settings_button = UiKit.make_button()
	for b in [start_button, load_button, settings_button]:
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		box.add_child(b)

	if Layout.fullscreen_available():
		fullscreen_button = UiKit.make_button()
		fullscreen_button.pressed.connect(func() -> void: Layout.toggle_fullscreen())
		box.add_child(fullscreen_button)

	# Touch users cannot hover for a tooltip, so the reason is also shown as visible text.
	load_note = UiKit.make_label(24)
	load_note.modulate = Color(1, 1, 1, 0.8)
	box.add_child(load_note)
	_build_label = UiKit.make_label(22)
	_build_label.modulate = Color(1, 1, 1, 0.6)
	box.add_child(_build_label)

	start_button.pressed.connect(_on_start)
	load_button.pressed.connect(_on_load)
	settings_button.pressed.connect(func() -> void: Router.goto("settings"))
	Loc.locale_changed.connect(func(_c: String) -> void: _refresh())
	Layout.mode_changed.connect(func(_m: String) -> void: _apply_layout())
	_refresh()
	_apply_layout()
	start_button.grab_focus()
	print("TITLE_READY load_enabled=%s" % (not load_button.disabled))


## Landscape: big title and compact buttons on the left. Portrait: centred column, full-width buttons.
func _apply_layout() -> void:
	var portrait: bool = Layout.is_portrait()
	_name_label.add_theme_font_size_override("font_size", 72 if portrait else 96)
	_tagline_label.add_theme_font_size_override("font_size", 28 if portrait else 34)
	var align := HORIZONTAL_ALIGNMENT_CENTER if portrait else HORIZONTAL_ALIGNMENT_LEFT
	for l in [_name_label, _tagline_label, load_note, _build_label]:
		l.horizontal_alignment = align
	var buttons: Array = [start_button, load_button, settings_button]
	if fullscreen_button != null:
		buttons.append(fullscreen_button)
	for b in buttons:
		b.size_flags_horizontal = Control.SIZE_FILL if portrait else Control.SIZE_SHRINK_BEGIN


func _refresh() -> void:
	_name_label.text = Loc.t("title.name")
	_tagline_label.text = Loc.t("title.tagline")
	start_button.text = Loc.t("ui.start")
	load_button.text = Loc.t("ui.load")
	settings_button.text = Loc.t("ui.settings")
	if fullscreen_button != null:
		fullscreen_button.text = Loc.t("ui.fullscreen")
	_refresh_load()
	_build_label.text = Loc.t("ui.build", {"v": "0.1 M1"})


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c


func _on_start() -> void:
	Game.new_game()
	Router.goto("cultivation")


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
			load_note.text = Loc.t("ui.load_hint", {"day": r.state.calendar.day, "slot": r.state.calendar.slot})
		else:
			load_note.text = Loc.t(r.error_key)
	load_button.tooltip_text = load_note.text
