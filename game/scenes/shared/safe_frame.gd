extends MarginContainer
## Full-rect container that keeps content away from screen edges and device cut-outs.
## Margin scales with viewport height so 16:9, 20:9 and ultra-wide layouts all breathe.

const MIN_MARGIN := 40.0


func _init() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)


func _ready() -> void:
	get_viewport().size_changed.connect(_update)
	_update()


func _update() -> void:
	var vp := get_viewport_rect().size
	var base := maxf(MIN_MARGIN, vp.y * 0.07)
	var inset := _device_insets(vp)
	add_theme_constant_override("margin_left", int(base + inset.x))
	add_theme_constant_override("margin_top", int(base * 0.8 + inset.y))
	add_theme_constant_override("margin_right", int(base + inset.z))
	add_theme_constant_override("margin_bottom", int(base * 0.8 + inset.w))


## Returns (left, top, right, bottom) device safe-area insets in viewport units. Zero on desktop/web.
func _device_insets(vp: Vector2) -> Vector4:
	var win := Vector2(DisplayServer.window_get_size())
	if win.x <= 0.0 or win.y <= 0.0:
		return Vector4.ZERO
	var area := Rect2(DisplayServer.get_display_safe_area())
	if area.size.x <= 0.0 or area.size.y <= 0.0:
		return Vector4.ZERO
	var sx := vp.x / win.x
	var sy := vp.y / win.y
	return Vector4(
		maxf(0.0, area.position.x) * sx,
		maxf(0.0, area.position.y) * sy,
		maxf(0.0, win.x - area.end.x) * sx,
		maxf(0.0, win.y - area.end.y) * sy)
