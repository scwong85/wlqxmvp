extends Control
## Placeholder companion portrait: a coloured medallion with the first character of the name.
## Replaced by real portrait art (the `portrait` reference in companion data) later.

var glyph: String = ""
var tint: Color = Color("5fd1a5")


func _init() -> void:
	custom_minimum_size = Vector2(72, 72)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(display_name: String, color: Color) -> void:
	glyph = display_name.substr(0, 1)
	tint = color
	queue_redraw()


func _draw() -> void:
	var c := size * 0.5
	var r := minf(size.x, size.y) * 0.48
	draw_circle(c, r, tint.darkened(0.55))
	draw_arc(c, r, 0.0, TAU, 40, tint, 3.0, true)
	var font := get_theme_default_font()
	if font != null and glyph != "":
		var fs := 36
		var asc := font.get_ascent(fs)
		var desc := font.get_descent(fs)
		draw_string(font, Vector2(0, c.y + (asc - desc) * 0.5), glyph, HORIZONTAL_ALIGNMENT_CENTER, size.x, fs, Color("eef3e6"))
