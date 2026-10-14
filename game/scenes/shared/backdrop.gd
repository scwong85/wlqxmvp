extends Control
## Placeholder landscape art drawn in code: night sky, moon, layered misty mountains, bamboo.
## Original artwork; redraws to fit any viewport so it works at every aspect ratio.


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return

	# Sky gradient (top deep ink-teal, horizon pale jade).
	var top := Color("0b1f24")
	var mid := Color("1d4b4a")
	var low := Color("6aa89a")
	var band := PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h * 0.55), Vector2(0, h * 0.55)])
	draw_polygon(band, PackedColorArray([top, top, mid, mid]))
	var band2 := PackedVector2Array([Vector2(0, h * 0.55), Vector2(w, h * 0.55), Vector2(w, h), Vector2(0, h)])
	draw_polygon(band2, PackedColorArray([mid, mid, low, low]))

	# Moon with soft halo.
	var moon := Vector2(w * 0.74, h * 0.22)
	var r := h * 0.085
	for i in range(5):
		draw_circle(moon, r * (2.6 - i * 0.4), Color(0.9, 0.93, 0.8, 0.035))
	draw_circle(moon, r, Color("eee9cf"))
	draw_circle(moon + Vector2(r * 0.25, -r * 0.1), r * 0.85, Color(0.96, 0.94, 0.82, 0.55))

	# Three mountain ridges, far to near.
	_ridge(w, h, 0.60, 0.20, Color("3f7f77"), 0.7, 1.0)
	_ridge(w, h, 0.70, 0.22, Color("2a5f5a"), 1.3, 2.4)
	_ridge(w, h, 0.82, 0.20, Color("17403f"), 2.1, 4.1)

	# Mist band between ridges.
	# Two stacked bands so the mist fades in and back out with no hard edge.
	var clear := Color(0.8, 0.95, 0.9, 0.0)
	var haze := Color(0.8, 0.95, 0.9, 0.16)
	var up := PackedVector2Array([Vector2(0, h * 0.64), Vector2(w, h * 0.64), Vector2(w, h * 0.73), Vector2(0, h * 0.73)])
	draw_polygon(up, PackedColorArray([clear, clear, haze, haze]))
	var down := PackedVector2Array([Vector2(0, h * 0.73), Vector2(w, h * 0.73), Vector2(w, h * 0.84), Vector2(0, h * 0.84)])
	draw_polygon(down, PackedColorArray([haze, haze, clear, clear]))

	# Foreground ground and bamboo stalks on the right.
	var ground := PackedVector2Array([Vector2(0, h), Vector2(0, h * 0.93), Vector2(w * 0.5, h * 0.9), Vector2(w, h * 0.94), Vector2(w, h)])
	draw_colored_polygon(ground, Color("0b2423"))
	_bamboo(w, h)


func _ridge(w: float, h: float, base_y: float, amp: float, color: Color, phase_a: float, phase_b: float) -> void:
	var pts := PackedVector2Array()
	pts.append(Vector2(0, h))
	var steps := 48
	for i in range(steps + 1):
		var x := w * float(i) / steps
		var u := float(i) / steps
		var y := h * base_y - h * amp * (0.55 * pow(sin(u * 3.1 + phase_a), 2.0) + 0.45 * pow(sin(u * 7.3 + phase_b), 2.0)) * 0.6
		pts.append(Vector2(x, y))
	pts.append(Vector2(w, h))
	draw_colored_polygon(pts, color)


func _bamboo(w: float, h: float) -> void:
	var stalks := [0.86, 0.905, 0.95, 0.975]
	for i in range(stalks.size()):
		var x: float = w * stalks[i]
		var top_y: float = h * (0.12 + 0.07 * i)
		var thick: float = h * (0.016 - 0.002 * i)
		var shade := Color("0a1f1d").lerp(Color("1f5b4f"), 0.25 * i)
		draw_rect(Rect2(x - thick * 0.5, top_y, thick, h - top_y), shade)
		var y := h - h * 0.09
		while y > top_y:
			draw_rect(Rect2(x - thick * 0.75, y, thick * 1.5, thick * 0.35), shade.lightened(0.25))
			y -= h * 0.105
		# Leaves.
		for k in range(4):
			var ly := top_y + k * h * 0.07
			var dir := -1.0 if (k + i) % 2 == 0 else 1.0
			var leaf := PackedVector2Array([Vector2(x, ly), Vector2(x + dir * h * 0.09, ly + h * 0.015),
					Vector2(x + dir * h * 0.02, ly + h * 0.03)])
			draw_colored_polygon(leaf, shade.lightened(0.35))
