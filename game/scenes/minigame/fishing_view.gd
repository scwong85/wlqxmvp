extends Control
## Draws a Fishing snapshot: water scene with the hero fishing, a vertical track with the fish and the hook bar,
## and the catch meter. Holds the "hold" input: mouse, touch, Space/Enter/Up all raise the hook.

const ChibiRig = preload("res://scenes/shared/chibi_rig.gd")

signal hold_changed(down: bool)

var snap: Dictionary = {}
var rig: Control
var _holding_pointer: bool = false


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP
	rig = ChibiRig.new()
	rig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(rig)
	resized.connect(_layout)


func set_hero_look(look: Dictionary) -> void:
	rig.setup(look, "fish", "neutral")


func _layout() -> void:
	var h := size.y * 0.6
	rig.size = Vector2(h / 1.5 * 1.15, h)
	rig.position = Vector2(size.x * 0.06, size.y - h - size.y * 0.04)


func update_snapshot(s: Dictionary) -> void:
	snap = s
	rig.pose = "fish"
	rig.face = "happy" if bool(s.get("caught", false)) else ("sad" if bool(s.get("escaped", false)) else "neutral")
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		var down: bool = event.pressed
		if down != _holding_pointer:
			_holding_pointer = down
			hold_changed.emit(down)
		accept_event()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	# Water and sky.
	draw_rect(Rect2(0, 0, w, h * 0.42), Color("8cc8e0"))
	draw_rect(Rect2(0, h * 0.42, w, h * 0.58), Color("2f7f9a"))
	for i in range(7):
		draw_line(Vector2(w * (0.04 + 0.14 * i), h * (0.5 + 0.06 * (i % 3))), Vector2(w * (0.04 + 0.14 * i + 0.07), h * (0.5 + 0.06 * (i % 3))), Color(1, 1, 1, 0.35), 3.0)
	# Track.
	var tx := w * 0.72
	var tw := minf(w * 0.14, 90.0)
	var ty := h * 0.08
	var th := h * 0.78
	draw_rect(Rect2(tx, ty, tw, th), Color(0.02, 0.1, 0.14, 0.55))
	draw_rect(Rect2(tx, ty, tw, th), Color("a8e0d0"), false, 3.0)
	if snap.is_empty():
		return
	var bar_h := float(snap.bar) * th
	var bar_y := ty + th - (float(snap.hook) + float(snap.bar)) * th
	var bar_col := Color(0.3, 0.9, 0.5, 0.75) if bool(snap.get("holding", false)) else Color(0.3, 0.75, 0.5, 0.6)
	draw_rect(Rect2(tx + 4, bar_y, tw - 8, bar_h), bar_col)
	var fy := ty + th - float(snap.fish) * th
	var fc := Vector2(tx + tw * 0.5, fy)
	draw_circle(fc, tw * 0.22, Color("f0a030"))
	draw_colored_polygon(PackedVector2Array([fc + Vector2(-tw * 0.2, 0), fc + Vector2(-tw * 0.42, -tw * 0.14), fc + Vector2(-tw * 0.42, tw * 0.14)]), Color("f0a030"))
	draw_circle(fc + Vector2(tw * 0.1, -tw * 0.05), tw * 0.04, Color.BLACK)
	# Line from the rod to the hook bar.
	var rod := Vector2(w * 0.06 + rig.size.x * 0.9, size.y - rig.size.y * 0.75 - size.y * 0.04)
	draw_line(rod, Vector2(tx, bar_y + bar_h * 0.5), Color(1, 1, 1, 0.55), 2.0)
	# Catch meter (left of the track) and the time bar (top).
	var mx := tx - tw * 0.55
	draw_rect(Rect2(mx, ty, tw * 0.3, th), Color(0.02, 0.1, 0.14, 0.55))
	var ph := float(snap.progress) * th
	draw_rect(Rect2(mx, ty + th - ph, tw * 0.3, ph), Color("e1c06b"))
	draw_rect(Rect2(mx, ty, tw * 0.3, th), Color("a8e0d0"), false, 2.0)
	var frac := clampf(float(snap.time_left) / float(snap.limit), 0.0, 1.0)
	draw_rect(Rect2(w * 0.06, h * 0.02, w * 0.5, 10), Color(0, 0, 0, 0.35))
	draw_rect(Rect2(w * 0.06, h * 0.02, w * 0.5 * frac, 10), Color("c8f0e0"))
