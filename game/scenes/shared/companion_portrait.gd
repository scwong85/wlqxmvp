extends Control
## Placeholder companion portrait: a coloured medallion with the first character of the name.
## Replaced by real portrait art (the `portrait` reference in companion data) later.

var glyph: String = ""
var tint: Color = Color("5fd1a5")
var art_id: String = ""
var art: Texture2D = null   # painted face (PortraitArt) replaces the glyph medallion when present


const PortraitArt = preload("res://scenes/shared/portrait_art.gd")


func _init() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED   # outside the picture the edge colour continues
	custom_minimum_size = Vector2(72, 72)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(display_name: String, color: Color, character_id: String = "") -> void:
	glyph = display_name.substr(0, 1)
	tint = color
	art_id = character_id
	art = PortraitArt.texture_for(character_id) if character_id != "" else null
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.48
	if art != null:
		# a round crop of the head and shoulders (the top square of the portrait) inside a tinted ring
		var tsz := art.get_size()
		var crop: Rect2 = PortraitArt.thumb_rect(art_id, art)
		var pts := PackedVector2Array()
		var uvs := PackedVector2Array()
		for i in 40:
			var a := TAU * float(i) / 40.0
			pts.append(c + Vector2(cos(a), sin(a)) * r)
			uvs.append((crop.position + crop.size * 0.5 + Vector2(cos(a), sin(a)) * crop.size * 0.5) / tsz)
		draw_colored_polygon(pts, Color.WHITE, uvs, art)
		draw_arc(c, r, 0.0, TAU, 40, tint, 3.0, true)
		return
	draw_circle(c, r, tint.darkened(0.55))
	draw_arc(c, r, 0.0, TAU, 40, tint, 3.0, true)
	var font := get_theme_default_font()
	if font != null and glyph != "":
		var fs := 36
		var asc := font.get_ascent(fs)
		var desc := font.get_descent(fs)
		draw_string(font, Vector2(0, c.y + (asc - desc) * 0.5), glyph, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, Color("eef3e6"))
