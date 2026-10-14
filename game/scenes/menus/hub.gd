extends Control
## Placeholder hub. M5 replaces this with the cultivation screen.

const UiKit = preload("res://scripts/ui/ui_kit.gd")
const Backdrop = preload("res://scenes/shared/backdrop.gd")
const SafeFrame = preload("res://scenes/shared/safe_frame.gd")

var back_button: Button

var _day_label: Label
var _body_label: Label


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

	_day_label = UiKit.make_label(64)
	_body_label = UiKit.make_label(32)
	_body_label.custom_minimum_size = Vector2(640, 0)
	back_button = UiKit.make_button()
	back_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	box.add_child(_day_label)
	box.add_child(_body_label)
	box.add_child(back_button)

	back_button.pressed.connect(func() -> void: Router.goto("title"))
	Loc.locale_changed.connect(func(_c: String) -> void: _refresh())
	_refresh()
	print("HUB_READY")


func _refresh() -> void:
	_day_label.text = Loc.t("hub.day", {"day": 1, "total": 7})
	_body_label.text = Loc.t("hub.placeholder")
	back_button.text = Loc.t("ui.back")
