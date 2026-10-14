extends Control
## Settings placeholder with the language toggle. Persisting the choice arrives with SaveService (M2).

const UiKit = preload("res://scripts/ui/ui_kit.gd")
const Backdrop = preload("res://scenes/shared/backdrop.gd")
const SafeFrame = preload("res://scenes/shared/safe_frame.gd")

var back_button: Button
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

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	box.add_child(row)
	var group := ButtonGroup.new()
	for code in Loc.SUPPORTED:
		var b := UiKit.make_button(Vector2(260, 76))
		b.toggle_mode = true
		b.button_group = group
		b.pressed.connect(func() -> void: Loc.set_locale(code))
		row.add_child(b)
		language_buttons[code] = b

	back_button = UiKit.make_button()
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	box.add_child(back_button)
	back_button.pressed.connect(func() -> void: Router.goto("title"))

	Loc.locale_changed.connect(func(_c: String) -> void: _refresh())
	_refresh()
	print("SETTINGS_READY")


func _refresh() -> void:
	_title_label.text = Loc.t("ui.settings")
	_language_label.text = Loc.t("ui.language")
	back_button.text = Loc.t("ui.back")
	for code in language_buttons:
		var b: Button = language_buttons[code]
		b.text = Loc.t("ui.language." + code)
		b.set_pressed_no_signal(code == Loc.locale)
