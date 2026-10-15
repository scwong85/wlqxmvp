extends Control
## Code-drawn story backgrounds, chosen by id (original placeholder art). Each is a sky, a ground band and a few shapes.

var bg_id: String = "default"

const THEMES := {
	"default": {"top": "0b1f24", "mid": "1d4b4a", "low": "6aa89a", "ground": "1d3a33", "kind": "hills"},
	"valley_dawn": {"top": "3b4a6b", "mid": "e8a98a", "low": "f6dcb0", "ground": "3d5a46", "kind": "hills", "sun": true},
	"valley_day": {"top": "5aa0c8", "mid": "a8d4e0", "low": "e6f2e4", "ground": "4f8a58", "kind": "hills", "sun": true},
	"village_dusk": {"top": "2d2a4a", "mid": "b8667a", "low": "f0b98a", "ground": "4a3a30", "kind": "houses"},
	"riverside_day": {"top": "6ab0d4", "mid": "b6dcea", "low": "e8f4ee", "ground": "5a9a64", "kind": "river"},
	"terraces_green": {"top": "7fb8d0", "mid": "bfe0c8", "low": "e8f2d8", "ground": "4a8a3c", "kind": "terraces"},
	"shrine_night": {"top": "070d16", "mid": "142437", "low": "2a4258", "ground": "1a2a28", "kind": "shrine", "moon": true},
	"ferry_dusk": {"top": "3a3560", "mid": "c0707a", "low": "f2c090", "ground": "2a4a5a", "kind": "river"},
	"night_camp": {"top": "060a12", "mid": "10202c", "low": "203540", "ground": "1c2a22", "kind": "camp", "moon": true},
}


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func set_bg(id: String) -> void:
	bg_id = id if THEMES.has(id) else "default"
	queue_redraw()


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	var th: Dictionary = THEMES[bg_id]
	var top := Color(str(th.top))
	var mid := Color(str(th.mid))
	var low := Color(str(th.low))
	var ground := Color(str(th.ground))
	var hor := h * 0.62
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, hor * 0.55), Vector2(0, hor * 0.55)]), PackedColorArray([top, top, mid, mid]))
	draw_polygon(PackedVector2Array([Vector2(0, hor * 0.55), Vector2(w, hor * 0.55), Vector2(w, hor), Vector2(0, hor)]), PackedColorArray([mid, mid, low, low]))
	if th.get("sun", false):
		draw_circle(Vector2(w * 0.72, hor * 0.5), h * 0.07, Color(1, 0.95, 0.75, 0.9))
	if th.get("moon", false):
		draw_circle(Vector2(w * 0.78, hor * 0.22), h * 0.05, Color(0.95, 0.96, 0.85, 0.95))
		draw_circle(Vector2(w * 0.78, hor * 0.22), h * 0.09, Color(0.95, 0.96, 0.85, 0.12))
	# Far hills.
	var far := PackedVector2Array([Vector2(0, hor)])
	for i in range(0, 9):
		far.append(Vector2(w * float(i) / 8.0, hor - h * (0.08 + 0.07 * absf(sin(float(i) * 1.7)))))
	far.append(Vector2(w, hor))
	draw_colored_polygon(far, mid.darkened(0.25))
	# Ground.
	draw_rect(Rect2(0, hor, w, h - hor), ground)
	draw_rect(Rect2(0, hor, w, h * 0.012), ground.lightened(0.2))
	match str(th.kind):
		"houses":
			for i in range(3):
				var x := w * (0.1 + 0.3 * i)
				var bw := w * 0.16
				draw_rect(Rect2(x, hor - h * 0.1, bw, h * 0.1), Color("3a2a26"))
				draw_colored_polygon(PackedVector2Array([Vector2(x - bw * 0.1, hor - h * 0.1), Vector2(x + bw * 0.5, hor - h * 0.19), Vector2(x + bw * 1.1, hor - h * 0.1)]), Color("5a3a32"))
				draw_rect(Rect2(x + bw * 0.4, hor - h * 0.065, bw * 0.2, h * 0.04), Color("f2c070"))
		"river":
			draw_rect(Rect2(0, hor + h * 0.02, w, h * 0.14), Color(low.r * 0.8, low.g * 0.95, low.b, 0.85))
			for i in range(6):
				draw_line(Vector2(w * (0.05 + 0.17 * i), hor + h * (0.06 + 0.02 * (i % 3))), Vector2(w * (0.05 + 0.17 * i + 0.08), hor + h * (0.06 + 0.02 * (i % 3))), Color(1, 1, 1, 0.5), 3.0)
		"terraces":
			for i in range(4):
				var y := hor + h * (0.03 + 0.07 * i)
				draw_rect(Rect2(0, y, w, h * 0.045), ground.lightened(0.05 * i))
				draw_line(Vector2(0, y), Vector2(w, y), ground.darkened(0.3), 3.0)
		"shrine":
			for i in [0.3, 0.7]:
				draw_rect(Rect2(w * i - w * 0.015, hor - h * 0.2, w * 0.03, h * 0.2), Color("2a1c1c"))
			draw_rect(Rect2(w * 0.26, hor - h * 0.22, w * 0.48, h * 0.03), Color("3a2424"))
			draw_rect(Rect2(w * 0.22, hor - h * 0.26, w * 0.56, h * 0.025), Color("3a2424"))
		"camp":
			draw_circle(Vector2(w * 0.5, hor + h * 0.05), h * 0.03, Color("f2a540"))
			draw_circle(Vector2(w * 0.5, hor + h * 0.05), h * 0.07, Color(0.95, 0.65, 0.25, 0.18))
		_:
			pass
	# Soft floor shade where the characters stand.
	draw_rect(Rect2(0, h * 0.86, w, h * 0.14), Color(0, 0, 0, 0.18))
