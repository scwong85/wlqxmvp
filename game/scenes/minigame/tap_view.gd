extends Control
## Draws the tap minigames (mining and music) from a snapshot. Press anywhere (mouse, touch, Space/Enter/Up) to tap.

signal hold_changed(down: bool)

var snap: Dictionary = {}
var _down: bool = false


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_STOP


func set_hero_look(_look: Dictionary) -> void:
	pass


func update_snapshot(s: Dictionary) -> void:
	snap = s
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		var down: bool = event.pressed
		if down != _down:
			_down = down
			hold_changed.emit(down)
		accept_event()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	var kind := str(snap.get("kind", ""))
	if kind == "mining":
		_draw_mining(w, h)
	elif kind == "music":
		_draw_music(w, h)
	else:
		draw_rect(Rect2(0, 0, w, h), Color("2a2f3a"))


func _draw_mining(w: float, h: float) -> void:
	draw_rect(Rect2(0, 0, w, h), Color("4a4540"))
	for i in 6:
		draw_line(Vector2(w * (0.1 + 0.16 * i), 0), Vector2(w * (0.05 + 0.16 * i), h), Color(0, 0, 0, 0.18), 3.0)
	var bx := w * 0.06
	var bw := w * 0.88
	var by := h * 0.4
	var bh := h * 0.22
	draw_rect(Rect2(bx, by, bw, bh), Color(0.05, 0.05, 0.07, 0.7))
	if snap.is_empty():
		return
	var vw := float(snap.vein_w) * bw
	var vx := bx + float(snap.vein) * bw - vw * 0.5
	draw_rect(Rect2(vx, by, vw, bh), Color("e8c860"))
	draw_rect(Rect2(vx + vw * 0.25, by, vw * 0.5, bh), Color("fff0a0"))
	var mx := bx + float(snap.marker) * bw
	draw_rect(Rect2(mx - 4, by - 10, 8, bh + 20), Color("ffffff"))
	var total := int(snap.total)
	var hits: Array = snap.hits
	for i in total:
		var c := Color(0.3, 0.3, 0.3)
		if i < hits.size():
			c = Color("5ad07a") if float(hits[i]) >= 1.0 else (Color("e8c860") if float(hits[i]) > 0.0 else Color("c85a5a"))
		draw_circle(Vector2(w * (0.3 + 0.1 * i), h * 0.8), minf(w, h) * 0.04, c)
	var frac := clampf(float(snap.time_left) / float(snap.limit), 0.0, 1.0)
	draw_rect(Rect2(w * 0.06, h * 0.06, w * 0.88, 10), Color(0, 0, 0, 0.35))
	draw_rect(Rect2(w * 0.06, h * 0.06, w * 0.88 * frac, 10), Color("c8f0e0"))


func _draw_music(w: float, h: float) -> void:
	draw_rect(Rect2(0, 0, w, h), Color("2a2438"))
	var line_x := w * 0.8
	var y := h * 0.5
	draw_line(Vector2(w * 0.04, y), Vector2(w * 0.96, y), Color(1, 1, 1, 0.25), 3.0)
	draw_line(Vector2(line_x, h * 0.2), Vector2(line_x, h * 0.8), Color("f0d890"), 5.0)
	if snap.is_empty():
		return
	for n in snap.notes:
		var x := w * 0.04 + float(n.p) * (line_x - w * 0.04)
		var s := float(n.s)
		var c := Color("c8b8ff")
		if s >= 1.0:
			c = Color("5ad07a")
		elif s >= 0.5:
			c = Color("e8c860")
		elif s == 0.0:
			c = Color("c85a5a")
		draw_circle(Vector2(x, y), minf(w, h) * 0.07, c)
	var total := int(snap.total)
	for i in total:
		draw_circle(Vector2(w * (0.1 + 0.07 * i), h * 0.88), minf(w, h) * 0.02, Color("e8c860") if i < int(snap.played) else Color(0.4, 0.4, 0.5))
