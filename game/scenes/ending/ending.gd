extends Control
## Ending screen (M12): title and text of the ending reached, the faction epilogue, and the way back.

const UiKit = preload("res://scripts/ui/ui_kit.gd")
const Backdrop = preload("res://scenes/shared/backdrop.gd")
const SafeFrame = preload("res://scenes/shared/safe_frame.gd")

var title_label: Label
var body_label: Label
var new_run_button: Button
var title_button: Button
var ending_id: String = ""


func _ready() -> void:
	UiKit.apply(self)
	Game.ensure_state()
	ending_id = Game.state.story.ending
	if ending_id == "" or Content.ending(ending_id).is_empty():
		Router.goto.call_deferred("title")
		return
	add_child(Backdrop.new())
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.07, 0.07, 0.66)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var frame := SafeFrame.new()
	add_child(frame)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	frame.add_child(box)
	var heading := UiKit.make_label(24)
	heading.modulate = Color(1, 1, 1, 0.7)
	heading.text = Loc.t("ending.heading")
	title_label = UiKit.make_label(48)
	title_label.modulate = Color("9be3c3")
	title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	body_label = UiKit.make_label(26)
	body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(body_label)
	var row := BoxContainer.new()
	row.vertical = Layout.is_portrait()
	row.add_theme_constant_override("separation", 12)
	new_run_button = UiKit.make_button(Vector2(0, 72))
	title_button = UiKit.make_button(Vector2(0, 72))
	for b in [new_run_button, title_button]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
	for n in [heading, title_label, panel, row]:
		box.add_child(n)
	new_run_button.pressed.connect(func() -> void:
		Game.restart_run()
		Router.goto("cultivation"))
	title_button.pressed.connect(func() -> void: Router.goto("title"))
	Loc.locale_changed.connect(func(_c: String) -> void: _refresh())
	_refresh()
	new_run_button.grab_focus()
	print("ENDING_SHOWN id=%s" % ending_id)
	_report_layout()


func _refresh() -> void:
	var e: Dictionary = Content.ending(ending_id)
	title_label.text = Loc.t(str(e.title_key))
	var parts: Array[String] = [Loc.t("ending.days"), Loc.t(str(e.body_key))]
	for f in ["pavilion", "couriers", "scribes", "neutral"]:
		if Game.state.relationships.has_flag("faction_" + f):
			parts.append(Loc.t("ending.faction." + f))
	body_label.text = "\n\n".join(parts)
	new_run_button.text = Loc.t("ending.new_run")
	title_button.text = Loc.t("ending.to_title")


func audit_layout() -> Array[String]:
	return UiKit.audit(self)


func _report_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var vp := get_viewport_rect().size
	var p := title_button.get_global_rect().get_center()
	var q := new_run_button.get_global_rect().get_center()
	print("UI_POS vp=%d,%d end_new=%d,%d end_title=%d,%d" % [int(vp.x), int(vp.y), int(q.x), int(q.y), int(p.x), int(p.y)])
	var problems := audit_layout()
	print("LAYOUT_AUDIT size=%dx%d problems=%d" % [int(vp.x), int(vp.y), problems.size()])
	for pr in problems:
		print("  audit: ", pr)
