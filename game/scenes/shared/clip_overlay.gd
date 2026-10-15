extends ColorRect
## Plays an activity clip: the hero's chibi doing the activity for a couple of seconds. Tap, click or Enter/Space/Esc skips.
## Emits `finished` exactly once.

const StageView = preload("res://scenes/shared/stage_view.gd")
const ClipRules = preload("res://scripts/domain/clip_rules.gd")
const UiKit = preload("res://scripts/ui/ui_kit.gd")

signal finished

var clip: Dictionary = {}
var stage_view: Control
var caption: Label
var _t: float = 0.0
var _last_key: Dictionary = {}
var _done: bool = false


func setup(clip_def: Dictionary) -> void:
	clip = clip_def
	color = Color(0, 0, 0, 0.72)
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	focus_mode = Control.FOCUS_ALL
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(box)
	var vp := Layout.usable_width()
	var w := minf(760.0, vp - 40.0)
	stage_view = StageView.new()
	stage_view.custom_minimum_size = Vector2(w, w * 0.62)
	stage_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(stage_view)
	caption = UiKit.make_label(28, HORIZONTAL_ALIGNMENT_CENTER)
	caption.text = Loc.t(str(clip.caption_key))
	caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(caption)
	var hint := UiKit.make_label(22, HORIZONTAL_ALIGNMENT_CENTER)
	hint.text = Loc.t("minigame.skip_hint")
	hint.modulate = Color(1, 1, 1, 0.6)
	hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(hint)
	_apply(0.0)
	print("CLIP_SHOWN %s" % str(clip.id))


func _apply(t: float) -> void:
	var key: Dictionary = ClipRules.key_at(clip, t)
	if key == _last_key:
		return
	_last_key = key
	stage_view.show_stage({"bg": str(clip.bg), "actors": {"center": {"who": "hero", "pose": key.pose, "face": key.face}}, "focus": ""}, [])


func _process(delta: float) -> void:
	if _done:
		return
	_t += delta
	_apply(_t)
	if _t >= float(clip.duration):
		_finish()


func _gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton and event.pressed) or (event is InputEventScreenTouch and event.pressed):
		_finish()


func _input(event: InputEvent) -> void:
	if _done:
		return
	if event is InputEventKey and event.pressed and not event.echo and [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_ESCAPE].has(event.keycode):
		get_viewport().set_input_as_handled()
		_finish()


func skip() -> void:
	_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	finished.emit()
	queue_free()
