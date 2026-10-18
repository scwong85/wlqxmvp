extends Control
## Ending screen (M12): title and text of the ending reached, the faction epilogue, and the way back.

const EpilogueRules = preload("res://scripts/domain/epilogue_rules.gd")
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
	var art_path := "res://art/endings/%s.jpg" % ending_id
	var has_art := ResourceLoader.exists(art_path)
	if has_art:
		# The painted ending fills the screen; a gradient darkens the lower part where the text sits.
		var art := TextureRect.new()
		art.texture = load(art_path) as Texture2D
		art.set_anchors_preset(Control.PRESET_FULL_RECT)
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(art)
		var grad := Gradient.new()
		grad.offsets = PackedFloat32Array([0.0, 0.24, 0.36, 1.0])
		grad.colors = PackedColorArray([Color(0.06, 0.04, 0.03, 0.0), Color(0.06, 0.04, 0.03, 0.0), Color(0.06, 0.04, 0.03, 0.8), Color(0.06, 0.04, 0.03, 0.93)])
		var gt := GradientTexture2D.new()
		gt.gradient = grad
		gt.fill_from = Vector2(0, 0)
		gt.fill_to = Vector2(0, 1)
		var shade := TextureRect.new()
		shade.texture = gt
		shade.set_anchors_preset(Control.PRESET_FULL_RECT)
		shade.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(shade)
	else:
		var dim := ColorRect.new()
		dim.color = Color(0.05, 0.03, 0.02, 0.66)
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
	title_label.modulate = UiKit.GOLD
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
	new_run_button.theme_type_variation = "SealButton"
	title_button = UiKit.make_button(Vector2(0, 72))
	for b in [new_run_button, title_button]:
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(b)
	if has_art and Layout.is_portrait():
		var gap := Control.new()   # leave the top of the picture clear
		gap.custom_minimum_size = Vector2(0, get_viewport_rect().size.y * 0.3)
		box.add_child(gap)
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
	for p in EpilogueRules.compose(Game.state, Content, ending_id):
		var line: Array[String] = []
		for k in p.keys:
			line.append(Loc.t(str(k), p.params))
		parts.append(" ".join(line))
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
