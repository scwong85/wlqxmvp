extends Control
## Placeholder hub. M5 replaces this with the cultivation screen. For now it shows the run state and
## offers a test button to advance time, plus manual save, so persistence can be tried by hand.

const UiKit = preload("res://scripts/ui/ui_kit.gd")
const Backdrop = preload("res://scenes/shared/backdrop.gd")
const SafeFrame = preload("res://scenes/shared/safe_frame.gd")

var advance_button: Button
var save_button: Button
var back_button: Button
var message_label: Label

var _day_label: Label
var _slot_label: Label
var _coins_label: Label
var _message_key: String = ""


func _ready() -> void:
	UiKit.apply(self)
	Game.ensure_state()
	add_child(Backdrop.new())
	var frame := SafeFrame.new()
	add_child(frame)

	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.size_flags_vertical = Control.SIZE_EXPAND_FILL
	box.add_theme_constant_override("separation", 16)
	frame.add_child(box)

	_day_label = UiKit.make_label(64)
	_slot_label = UiKit.make_label(34)
	_coins_label = UiKit.make_label(30)
	message_label = UiKit.make_label(28)
	message_label.modulate = Color(0.75, 1.0, 0.88, 0.95)
	box.add_child(_day_label)
	box.add_child(_slot_label)
	box.add_child(_coins_label)
	box.add_child(_spacer(12))

	advance_button = UiKit.make_button(Vector2(520, 76))
	save_button = UiKit.make_button()
	back_button = UiKit.make_button()
	for b in [advance_button, save_button, back_button]:
		b.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		box.add_child(b)
	box.add_child(message_label)

	advance_button.pressed.connect(_on_advance)
	save_button.pressed.connect(_on_save)
	back_button.pressed.connect(func() -> void: Router.goto("title"))
	Loc.locale_changed.connect(func(_c: String) -> void: _refresh())
	_refresh()
	advance_button.grab_focus()
	var cal: RefCounted = Game.state.calendar
	print("HUB_READY day=%d slot=%d coins=%d" % [cal.day, cal.slot, Game.state.resources.get_amount("coins")])


func _on_advance() -> void:
	var r: Dictionary = Game.state.calendar.advance_slot()
	if r.advanced:
		var saved: Dictionary = Game.autosave()
		_message_key = "hub.autosaved" if saved.ok else "hub.save_failed"
	_refresh()


func _on_save() -> void:
	var r: Dictionary = Game.save_manual()
	_message_key = "hub.saved" if r.ok else "hub.save_failed"
	_refresh()


func _refresh() -> void:
	var cal: RefCounted = Game.state.calendar
	_day_label.text = Loc.t("hub.day", {"day": cal.day, "total": cal.DAYS})
	_slot_label.text = Loc.t("hub.finished") if cal.finished else Loc.t("hub.slot", {"slot": cal.slot, "total": cal.SLOTS})
	_coins_label.text = Loc.t("hub.coins", {"coins": Game.state.resources.get_amount("coins")})
	advance_button.text = Loc.t("hub.dev_advance")
	advance_button.disabled = cal.finished
	save_button.text = Loc.t("hub.save")
	back_button.text = Loc.t("ui.back")
	message_label.text = Loc.t(_message_key) if _message_key != "" else ""


func _spacer(h: int) -> Control:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	return c
