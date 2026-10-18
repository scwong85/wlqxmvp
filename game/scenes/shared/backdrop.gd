extends Control
## The painted backdrop behind every non-story screen: a painted landscape (res://art/backgrounds/<id>.jpg) under a warm
## ink-brown veil, so the menus read as a scroll over a view and text stays readable. Falls back to a plain dark wash.

const BG_DIR := "res://art/backgrounds/"

var art_id: String = "valley_dawn"
var veil: float = 0.55
var _tex: Texture2D = null


func _init(id: String = "valley_dawn") -> void:
	art_id = id
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)
	var path := "%s%s.jpg" % [BG_DIR, id]
	if ResourceLoader.exists(path):
		_tex = load(path) as Texture2D


func _draw() -> void:
	var w := size.x
	var h := size.y
	if w <= 0.0 or h <= 0.0:
		return
	if _tex == null:
		draw_rect(Rect2(0, 0, w, h), Color("1b1511"))
		return
	var tsz := _tex.get_size()
	var k := maxf(w / tsz.x, h / tsz.y)   # cover the screen, crop the overflow evenly
	var src := Vector2(w / k, h / k)
	draw_texture_rect_region(_tex, Rect2(0, 0, w, h), Rect2((tsz - src) * 0.5, src))
	draw_rect(Rect2(0, 0, w, h), Color(0.09, 0.06, 0.04, veil))
	# Darker edges, like a vignette, so the centre (where the panels sit) stays calm.
	var edge := Color(0.05, 0.03, 0.02, 0.0)
	var shade := Color(0.05, 0.03, 0.02, 0.38)
	draw_polygon(PackedVector2Array([Vector2(0, h * 0.7), Vector2(w, h * 0.7), Vector2(w, h), Vector2(0, h)]), PackedColorArray([edge, edge, shade, shade]))
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(w, 0), Vector2(w, h * 0.2), Vector2(0, h * 0.2)]), PackedColorArray([shade, shade, edge, edge]))
