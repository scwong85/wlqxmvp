extends RefCounted
## Modal pop-ups (dimmed backdrop + centred panel) that never outgrow the screen: the panel's
## preferred width is capped to the usable width, and `fit` re-caps it after a rotation.


## Returns [overlay (add it to the scene), box (VBoxContainer inside the panel)].
static func make(preferred_width: float, separation: int = 8) -> Array:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.62)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.set_meta("pref_w", preferred_width)
	panel.custom_minimum_size = Vector2(_cap(preferred_width), 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	panel.add_child(box)
	return [overlay, box]


static func _cap(preferred_width: float) -> float:
	return minf(preferred_width, Layout.usable_width() - 32.0)


## Re-applies the width cap to every panel in an overlay (call after the layout mode changed).
static func fit(overlay: Control) -> void:
	if overlay == null or not is_instance_valid(overlay):
		return
	for p in overlay.find_children("*", "PanelContainer", true, false):
		if p.has_meta("pref_w"):
			p.custom_minimum_size.x = _cap(float(p.get_meta("pref_w")))
