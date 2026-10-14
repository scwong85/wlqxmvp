extends Control
## Placeholder hero portrait drawn in code (original design): robe, head, topknot and a sword hilt.
## Final character art replaces this later; the panel around it does not change.


func _init() -> void:
	custom_minimum_size = Vector2(0, 190)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	var cx := w * 0.5
	var r := minf(w, h) * 0.47
	var mid := Vector2(cx, h * 0.5)
	draw_circle(mid, r, Color(0.09, 0.27, 0.25, 0.95))
	draw_arc(mid, r, 0.0, TAU, 64, Color("5fd1a5"), 3.0, true)

	# Sword hilt over the shoulder.
	draw_line(Vector2(cx + r * 0.62, h * 0.68), Vector2(cx + r * 0.86, h * 0.28), Color("cfd8d3"), 6.0)
	draw_line(Vector2(cx + r * 0.74, h * 0.46), Vector2(cx + r * 0.98, h * 0.5), Color("e1c06b"), 5.0)

	# Robe with a pale collar, clipped to the circle by staying inside it.
	var robe := PackedVector2Array([
		Vector2(cx - r * 0.78, h * 0.93), Vector2(cx - r * 0.5, h * 0.66), Vector2(cx, h * 0.58),
		Vector2(cx + r * 0.5, h * 0.66), Vector2(cx + r * 0.78, h * 0.93)])
	draw_colored_polygon(robe, Color("2f7a6a"))
	var collar := PackedVector2Array([
		Vector2(cx - r * 0.3, h * 0.62), Vector2(cx, h * 0.8), Vector2(cx + r * 0.3, h * 0.62),
		Vector2(cx + r * 0.15, h * 0.6), Vector2(cx, h * 0.69), Vector2(cx - r * 0.15, h * 0.6)])
	draw_colored_polygon(collar, Color("e8e2c8"))

	# Head, hair and topknot.
	var head := Vector2(cx, h * 0.42)
	var hr := r * 0.34
	draw_circle(head, hr, Color("e9cfae"))
	var hair := PackedVector2Array()
	for i in range(0, 13):
		var a := PI + PI * float(i) / 12.0
		hair.append(head + Vector2(cos(a), sin(a)) * (hr * 1.04))
	draw_colored_polygon(hair, Color("17201f"))
	draw_circle(head + Vector2(0, -hr * 1.15), hr * 0.32, Color("17201f"))
	draw_circle(head + Vector2(-hr * 0.38, hr * 0.05), hr * 0.07, Color("2a2a2a"))
	draw_circle(head + Vector2(hr * 0.38, hr * 0.05), hr * 0.07, Color("2a2a2a"))
