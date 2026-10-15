extends Control
## Settings placeholder with the language toggle. Persisting the choice arrives with SaveService (M2).

const UiKit = preload("res://scripts/ui/ui_kit.gd")
const Backdrop = preload("res://scenes/shared/backdrop.gd")
const SafeFrame = preload("res://scenes/shared/safe_frame.gd")

var back_button: Button
var fullscreen_button: Button   # web only
var _row: BoxContainer
var language_buttons: Dictionary = {}  # locale code -> Button

var _title_label: Label
var _language_label: Label


func _ready() -> void:
	UiKit.apply(self)
	add_child(Backdrop.new())
	var frame := SafeFrame.new()
	add_child(frame)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 20)
	frame.add_child(box)

	_title_label = UiKit.make_label(64)
	_language_label = UiKit.make_label(32)
	box.add_child(_title_label)
	box.add_child(_language_label)

	var row := BoxContainer.new()
	_row = row
	row.add_theme_constant_override("separation", 20)
	box.add_child(row)
	var group := ButtonGroup.new()
	for code in Loc.SUPPORTED:
		var b := UiKit.make_button(Vector2(260, 76))
		b.toggle_mode = true
		b.button_group = group
		b.pressed.connect(func() -> void:
			Loc.set_locale(code)
			Saves.save_settings({"locale": code}))
		row.add_child(b)
		language_buttons[code] = b

	if Layout.fullscreen_available():
		fullscreen_button = UiKit.make_button()
		fullscreen_button.pressed.connect(func() -> void: Layout.toggle_fullscreen())
		box.add_child(fullscreen_button)

	back_button = UiKit.make_button()
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	box.add_child(back_button)
	back_button.pressed.connect(func() -> void: Router.goto("title"))

	Loc.locale_changed.connect(func(_c: String) -> void: _refresh())
	Layout.mode_changed.connect(func(_m: String) -> void: _apply_layout())
	_refresh()
	_apply_layout()
	print("SETTINGS_READY")


func _apply_layout() -> void:
	var portrait: bool = Layout.is_portrait()
	_row.vertical = portrait
	_title_label.add_theme_font_size_override("font_size", 56 if portrait else 64)
	var align := HORIZONTAL_ALIGNMENT_CENTER if portrait else HORIZONTAL_ALIGNMENT_LEFT
	_title_label.horizontal_alignment = align
	_language_label.horizontal_alignment = align
	var fill := Control.SIZE_FILL if portrait else Control.SIZE_SHRINK_BEGIN
	back_button.size_flags_horizontal = fill
	if fullscreen_button != null:
		fullscreen_button.size_flags_horizontal = fill
	for b in language_buttons.values():
		b.custom_minimum_size = Vector2(0 if portrait else 260, 76)
		b.size_flags_horizontal = Control.SIZE_FILL if portrait else Control.SIZE_SHRINK_BEGIN


func _refresh() -> void:
	_title_label.text = Loc.t("ui.settings")
	_language_label.text = Loc.t("ui.language")
	back_button.text = Loc.t("ui.back")
	if fullscreen_button != null:
		fullscreen_button.text = Loc.t("ui.fullscreen")
	for code in language_buttons:
		var b: Button = language_buttons[code]
		b.text = Loc.t("ui.language." + code)
		b.set_pressed_no_signal(code == Loc.locale)
