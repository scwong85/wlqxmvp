extends Control
## The story board: a background and up to four chibi characters, driven by a stage dictionary (StageRules).
## Used by dialogue and event scenes. Transient effects (shake, flash, fade) are played when a node appears.

const StageBackground = preload("res://scenes/shared/stage_background.gd")
const ChibiRig = preload("res://scenes/shared/chibi_rig.gd")
const StageRules = preload("res://scripts/domain/stage_rules.gd")
const LookRules = preload("res://scripts/domain/look_rules.gd")

const SLOT_X := {"left": 0.17, "center": 0.5, "right": 0.83, "far": 0.66}

var background: Control
var actors: Dictionary = {}       # slot -> ChibiRig
var animate: bool = true
var _layer: Control
var _flash: ColorRect
var _fade: ColorRect
var _stage: Dictionary = {}


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(0, 160)
	background = StageBackground.new()
	add_child(background)
	_layer = Control.new()
	_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_layer)
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	_fade = ColorRect.new()
	_fade.color = Color(0, 0, 0, 0)
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade)
	resized.connect(_layout)


## Look for a character id: the hero's own, an NPC from the looks table, or a neutral default.
static func look_for(who: String) -> Dictionary:
	var game: Node = Engine.get_main_loop().root.get_node("Game")
	if who == "hero":
		var l: Dictionary = LookRules.sanitize(game.state.player.look) if game.state != null else LookRules.default_look()
		l["weapon"] = "sword"
		return l
	var content: Node = Engine.get_main_loop().root.get_node("Content")
	var l2: Dictionary = content.look_of(who)
	return l2 if not l2.is_empty() else LookRules.default_look()


func show_stage(stage: Dictionary, transient: Array = []) -> void:
	_stage = StageRules.sanitize(stage)
	background.set_bg(str(_stage.bg))
	for slot in actors.keys():
		if not _stage.actors.has(slot):
			actors[slot].queue_free()
			actors.erase(slot)
	for slot in StageRules.SLOTS:
		if not _stage.actors.has(slot):
			continue
		var a: Dictionary = _stage.actors[slot]
		var rig: Control = actors.get(slot)
		if rig == null:
			rig = ChibiRig.new()
			_layer.add_child(rig)
			actors[slot] = rig
		rig.animate = animate
		rig.setup(look_for(str(a.who)), str(a.pose), str(a.face))
		rig.flip = slot == "right" or slot == "far"
		rig.dim = str(_stage.focus) != "" and str(_stage.focus) != str(a.who)
	_layout()
	_play(transient)


func _layout() -> void:
	for slot in actors:
		var rig: Control = actors[slot]
		var scale_f := 0.72 if slot == "far" else 0.94
		var h := size.y * scale_f
		var w := minf(h / 1.5 * 1.15, size.x * 0.32)
		h = minf(h, w / 1.15 * 1.5) if w < h / 1.5 * 1.15 else h
		rig.size = Vector2(w, h)
		rig.position = Vector2(clampf(size.x * float(SLOT_X[slot]) - w * 0.5, 0.0, maxf(0.0, size.x - w)), size.y - h - (size.y * 0.07 if slot == "far" else 0.0))
		rig.custom_minimum_size = Vector2.ZERO
		rig.queue_redraw()


func _play(transient: Array) -> void:
	if not animate:
		return
	for c in transient:
		match str(c.get("c", "")):
			"flash":
				_flash.color = Color(1, 1, 1, 0.85)
				create_tween().tween_property(_flash, "color:a", 0.0, 0.35)
			"fade":
				_fade.color = Color(0, 0, 0, 1)
				create_tween().tween_property(_fade, "color:a", 0.0, 0.6)
			"shake":
				var tw := create_tween()
				for i in range(6):
					tw.tween_property(_layer, "position", Vector2(randf_range(-10, 10), randf_range(-6, 6)), 0.04)
				tw.tween_property(_layer, "position", Vector2.ZERO, 0.04)
			"sfx":
				var audio: Node = Engine.get_main_loop().root.get_node("Audio")
				if audio.has_method("play_click"):
					audio.play_click()
