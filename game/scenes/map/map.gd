extends Control
## Map tab (M17): pick an area to visit, and a Journal of leads and past events. Rules live in WorldRules;
## this screen only shows state and forwards the visit to Game.

const UiKit = preload("res://scripts/ui/ui_kit.gd")
const Backdrop = preload("res://scenes/shared/backdrop.gd")
const SafeFrame = preload("res://scenes/shared/safe_frame.gd")
const WorldRules = preload("res://scripts/domain/world_rules.gd")
const CultivationRules = preload("res://scripts/domain/cultivation_rules.gd")
const DeltaText = preload("res://scenes/shared/delta_text.gd")

const FONT_BODY := 24
const FONT_SMALL := 22

# Public so tests can drive the screen like a player.
var area_buttons: Dictionary = {}   # area id -> Button
var go_button: Button
var back_button: Button
var tab_buttons: Dictionary = {}    # "map" | "journal" -> Button
var result_label: Label
var selected_id: String = ""
var tab: String = "map"

var _title_label: Label
var _week_label: Label
var _bar: BoxContainer
var _body: BoxContainer
var _list_box: VBoxContainer
var _detail_box: VBoxContainer
var _detail_label: Label
var _list_panel: PanelContainer
var _detail_panel: PanelContainer


func _ready() -> void:
	UiKit.apply(self)
	Game.ensure_state()
	var story_scene := Game.next_story_scene()
	if story_scene != "":
		Router.goto.call_deferred(story_scene)
		return
	add_child(Backdrop.new())
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.07, 0.07, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var frame := SafeFrame.new()
	add_child(frame)
	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", 12)
	frame.add_child(main)

	_bar = BoxContainer.new()
	_bar.add_theme_constant_override("separation", 16)
	_title_label = UiKit.make_label(36)
	_title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_week_label = UiKit.make_label(FONT_BODY)
	_week_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	_week_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	back_button = UiKit.make_button(Vector2(150, 56))
	back_button.add_theme_font_size_override("font_size", FONT_BODY)
	back_button.pressed.connect(func() -> void: Router.goto("cultivation"))
	for c in [_title_label, _week_label]:
		_bar.add_child(c)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	for id in ["map", "journal"]:
		var b := UiKit.make_button(Vector2(140, 56))
		b.toggle_mode = true
		b.add_theme_font_size_override("font_size", FONT_BODY)
		b.pressed.connect(func() -> void: _set_tab(id))
		tabs.add_child(b)
		tab_buttons[id] = b
	tabs.add_child(back_button)
	main.add_child(_bar)
	main.add_child(tabs)

	_body = BoxContainer.new()
	_body.add_theme_constant_override("separation", 16)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(_body)
	_list_panel = PanelContainer.new()
	_list_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_list_panel.size_flags_stretch_ratio = 52.0
	_body.add_child(_list_panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_list_panel.add_child(scroll)
	_list_box = VBoxContainer.new()
	_list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list_box.add_theme_constant_override("separation", 10)
	scroll.add_child(_list_box)

	_detail_panel = PanelContainer.new()
	_detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_detail_panel.size_flags_stretch_ratio = 48.0
	_body.add_child(_detail_panel)
	var dscroll := ScrollContainer.new()
	dscroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_detail_panel.add_child(dscroll)
	_detail_box = VBoxContainer.new()
	_detail_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_detail_box.add_theme_constant_override("separation", 12)
	dscroll.add_child(_detail_box)
	_detail_label = UiKit.make_label(FONT_BODY)
	_detail_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_label = UiKit.make_label(FONT_SMALL)
	result_label.modulate = Color(0.75, 1.0, 0.88, 0.95)
	result_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	go_button = UiKit.make_button(Vector2(0, 64))
	go_button.add_theme_font_size_override("font_size", 28)
	go_button.pressed.connect(_on_go)
	_detail_box.add_child(_detail_label)
	_detail_box.add_child(go_button)
	_detail_box.add_child(result_label)

	Loc.locale_changed.connect(func(_c: String) -> void: _refresh())
	Layout.mode_changed.connect(func(_m: String) -> void: _apply_layout())
	_select_default()
	_apply_layout()
	_refresh()
	print("MAP_READY week=%d areas=%d" % [Game.state.calendar.week, WorldRules.area_ids(Content).size()])
	_report_layout()


func _report_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var vp := get_viewport_rect().size
	var problems: Array[String] = UiKit.audit(self)
	var parts: Array[String] = []
	for k in ["go", "back"]:
		var c: Control = go_button if k == "go" else back_button
		if c.is_visible_in_tree():
			var ctr := c.get_global_rect().get_center()
			parts.append("%s=%d,%d" % [k, int(ctr.x), int(ctr.y)])
	print("UI_POS vp=%d,%d %s" % [int(vp.x), int(vp.y), " ".join(parts)])
	print("LAYOUT_AUDIT size=%dx%d problems=%d" % [int(vp.x), int(vp.y), problems.size()])
	for p in problems:
		print("  audit: ", p)


func audit_layout() -> Array[String]:
	return UiKit.audit(self)


func _apply_layout() -> void:
	var portrait: bool = Layout.is_portrait()
	_bar.vertical = portrait
	_bar.add_theme_constant_override("separation", 4 if portrait else 16)
	_body.vertical = portrait
	_title_label.add_theme_font_size_override("font_size", 32 if portrait else 36)
	_week_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART if portrait else TextServer.AUTOWRAP_OFF
	_list_panel.size_flags_stretch_ratio = 55.0 if portrait else 52.0
	_detail_panel.size_flags_stretch_ratio = 45.0 if portrait else 48.0


func _select_default() -> void:
	var st: RefCounted = Game.state
	selected_id = ""
	for id in WorldRules.area_ids(Content):
		var s: Dictionary = WorldRules.area_status(st, Content, id)
		if s.state == "open" and (selected_id == "" or int(s.due) > 0 and int(WorldRules.area_status(st, Content, selected_id).due) == 0):
			selected_id = id
	if selected_id == "" and not Content.areas.is_empty():
		selected_id = str(Content.areas[0].id)


func _set_tab(id: String) -> void:
	tab = id
	_refresh()


func _state_text(s: Dictionary) -> String:
	if s.state == "open":
		return Loc.t("map.state.due") if int(s.due) > 0 else Loc.t("map.state.open")
	return Loc.t("map.state." + str(s.state))


func _refresh() -> void:
	var st: RefCounted = Game.state
	_title_label.text = Loc.t("map.title")
	_week_label.text = "%s · %s" % [Loc.t("map.week", {"week": st.calendar.week, "slot": st.calendar.slot}),
			Loc.t("cult.stamina_value", {"cur": st.player.stamina, "max": CultivationRules.max_stamina(st.player)})]
	back_button.text = Loc.t("map.back")
	for id in tab_buttons:
		tab_buttons[id].text = Loc.t("map.tab." + id)
		tab_buttons[id].set_pressed_no_signal(id == tab)
	for c in _list_box.get_children():
		c.queue_free()
	area_buttons.clear()
	if tab == "journal":
		_build_journal()
		_detail_panel.visible = false
		return
	_detail_panel.visible = true
	var last_region := ""
	for id in WorldRules.area_ids(Content):
		var a: Dictionary = Content.area(id)
		if str(a.region) != last_region:
			last_region = str(a.region)
			var h := UiKit.make_label(FONT_SMALL)
			h.text = Loc.t("map.region." + last_region)
			h.modulate = Color(0.8, 0.95, 0.85, 0.8)
			_list_box.add_child(h)
		var s: Dictionary = WorldRules.area_status(st, Content, id)
		var b := UiKit.make_button(Vector2(0, 64))
		b.add_theme_font_size_override("font_size", FONT_BODY)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.clip_text = true
		b.text = "%s · %s" % [Loc.t(a.name_key), _state_text(s)]
		b.toggle_mode = true
		b.set_pressed_no_signal(id == selected_id)
		b.modulate = Color(1, 1, 1, 1.0) if s.state == "open" else Color(1, 1, 1, 0.6)
		b.pressed.connect(func() -> void:
			selected_id = id
			result_label.text = ""
			_refresh())
		_list_box.add_child(b)
		area_buttons[id] = b
	_refresh_detail()


func _refresh_detail() -> void:
	var st: RefCounted = Game.state
	if selected_id == "":
		_detail_label.text = Loc.t("map.pick")
		go_button.visible = false
		return
	var a: Dictionary = Content.area(selected_id)
	var s: Dictionary = WorldRules.area_status(st, Content, selected_id)
	var lines: Array[String] = [Loc.t(a.name_key), Loc.t(a.desc_key), Loc.t("map.cost", {"cost": s.cost})]
	if s.state != "open":
		for r in s.reasons:
			lines.append("· " + Loc.t(str(r.key), r.params))
	_detail_label.text = "\n\n".join(lines)
	go_button.visible = true
	go_button.text = Loc.t("map.go", {"cost": s.cost})
	go_button.disabled = s.state != "open"


func _build_journal() -> void:
	var st: RefCounted = Game.state
	var head := UiKit.make_label(FONT_BODY)
	head.text = Loc.t("map.journal.leads")
	_list_box.add_child(head)
	if st.world.leads.is_empty():
		_list_box.add_child(_text(Loc.t("map.journal.none")))
	for l in st.world.leads:
		_list_box.add_child(_text("%s\n%s" % [Loc.t("world.lead." + str(l) + ".name"), Loc.t("world.lead." + str(l) + ".desc")]))
	var done: Array = st.world.done.keys()
	done.sort_custom(func(x: String, y: String) -> bool: return int(st.world.done[x]) < int(st.world.done[y]))
	var h2 := UiKit.make_label(FONT_BODY)
	h2.text = Loc.t("map.journal.done")
	_list_box.add_child(h2)
	if done.is_empty():
		_list_box.add_child(_text(Loc.t("map.journal.none")))
	for id in done:
		var ev: Dictionary = Content.event(str(id))
		if ev.is_empty() or not ev.has("title_key"):
			continue
		_list_box.add_child(_text("%s · %s" % [Loc.t(ev.title_key), Loc.t("map.journal.week", {"week": int(st.world.done[id])})]))
	if not st.world.missed.is_empty():
		var h3 := UiKit.make_label(FONT_BODY)
		h3.text = Loc.t("map.journal.missed")
		_list_box.add_child(h3)
		for id in st.world.missed:
			var ev2: Dictionary = Content.event(str(id))
			if not ev2.is_empty() and ev2.has("title_key"):
				_list_box.add_child(_text(Loc.t(ev2.title_key)))


func _text(t: String) -> Label:
	var l := UiKit.make_label(FONT_SMALL)
	l.text = t
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return l


func _on_go() -> void:
	if selected_id == "":
		return
	var r: Dictionary = Game.visit_area(selected_id)
	if not r.ok:
		result_label.text = Loc.t(str(r.reasons[0].key), r.reasons[0].params) if not r.reasons.is_empty() else ""
		_refresh()
		return
	if r.scene == "dialogue":
		Router.goto("dialogue")
		return
	var lines: Array[String] = []
	if not (r.wander as Dictionary).is_empty():
		lines.append(Loc.t(str(r.wander.text_key)))
	for d in r.deltas:
		lines.append(DeltaText.delta_line(d))
	result_label.text = "\n".join(lines)
	var dest: String = Game.next_story_scene()
	if dest != "":
		Router.goto(dest)
		return
	_select_default_keep()
	_refresh()


func _select_default_keep() -> void:
	if selected_id == "" or WorldRules.area_status(Game.state, Content, selected_id).state != "open":
		_select_default()
