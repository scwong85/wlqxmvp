extends Control
## Title screen: new game, load game (disabled until saves exist), settings.

const UiKit = preload("res://scripts/ui/ui_kit.gd")
const Backdrop = preload("res://scenes/shared/backdrop.gd")
const SafeFrame = preload("res://scenes/shared/safe_frame.gd")

var start_button: Button
var load_button: Button
var settings_button: Button

var _name_label: Label
var _tagline_label: Label
var _load_note: Label
var _build_label: Label


func _ready() -> void:
	UiKit.apply(self)
	add_child(Backdrop.new())
	var frame := SafeFrame.new()
	add_child(frame)

	var box := VBoxContainer.new()
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

	# Touch users cannot hover for a tooltip, so the reason is also shown as visible text.
	_load_note = UiKit.make_label(24)
	_load_note.modulate = Color(1, 1, 1, 0.8)
	box.add_child(_load_note)
	_build_label = UiKit.make_label(22)
	_build_label.modulate = Color(1, 1, 1, 0.6)
	box.add_child(_build_label)

	load_button.disabled = true  # M2 enables this once SaveService exists.
	start_button.pressed.connect(func() -> void: Router.goto("hub"))
	settings_button.pressed.connect(func() -> void: Router.goto("settings"))
	Loc.locale_changed.connect(func(_c: String) -> void: _refresh())
	_refresh()
	start_button.grab_focus()
	print("TITLE_READY")


func _refresh() -> void:
	_name_label.text = Loc.t("title.name")
	_tagline_label.text = Loc.t("title.tagline")
	start_button.text = Loc.t("ui.start")
	load_button.text = Loc.t("ui.load")
	settings_button.text = Loc.t("ui.settings")
	load_button.tooltip_text = Loc.t("ui.load_disabled")
	_load_note.text = Loc.t("ui.load_disabled")
	_build_label.text = Loc.t("ui.build", {"v": "0.1 M1"})


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
