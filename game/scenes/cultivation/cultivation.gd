extends Control
## The main play screen (M5): hero and path on the left, activity choices in the middle, attributes
## and resources on the right. All rules live in scripts/domain; this scene only shows state and
## forwards choices to Game. Selecting is a tap, doing it is a separate confirm, so touch works the
## same as mouse and nothing depends on hover.

const UiKit = preload("res://scripts/ui/ui_kit.gd")
const Backdrop = preload("res://scenes/shared/backdrop.gd")
const SafeFrame = preload("res://scenes/shared/safe_frame.gd")
const HeroPortrait = preload("res://scenes/shared/hero_portrait.gd")
const PlayerState = preload("res://scripts/domain/player_state.gd")
const ResourceState = preload("res://scripts/domain/resource_state.gd")
const CultivationRules = preload("res://scripts/domain/cultivation_rules.gd")
const ActivityRules = preload("res://scripts/domain/activity_rules.gd")
const RelationshipRules = preload("res://scripts/domain/relationship_rules.gd")
const CompanionPortrait = preload("res://scenes/shared/companion_portrait.gd")
const ROLE_COLORS := {"support": Color("5fd1a5"), "striker": Color("e0a35a"), "control": Color("7aa8e0")}

const FONT_BODY := 24
const FONT_SMALL := 22
const FONT_HEAD := 28

# Public so tests (and later screens) can drive the UI exactly as a player would.
var cards: Dictionary = {}          # activity id -> Button
var path_buttons: Dictionary = {}   # path id -> Button (only while no path is chosen)
var confirm_button: Button
var save_button: Button
var menu_button: Button
var info_label: Label
var status_label: Label
var event_panel: Control = null
var event_continue_button: Button
var selected_id: String = ""
## Companion list overlay (M7-08) and recruitment prompt (M7-09).
var party_button: Button
var party_panel: Control = null
var party_close_button: Button
var _party_box: VBoxContainer
var party_buttons: Dictionary = {}   # npc id -> {recruit, activate, dismiss} (only those shown)
var recruit_panel: Control = null
var recruit_accept_button: Button
var recruit_decline_button: Button
## Approach chooser overlay (M6): shown when the confirmed activity has options.
var choice_panel: Control = null
var option_buttons: Dictionary = {}
var choice_cancel_button: Button

var _day_label: Label
var _slot_label: Label
var _hero_name: Label
var _stamina_label: Label
var _stamina_bar: ProgressBar
var _path_box: VBoxContainer
var _attr_labels: Dictionary = {}
var _derived_labels: Array[Label] = []
var _resource_labels: Dictionary = {}
var _bonds_label: Label
var _headers: Array = []            # [Label, translation key]
var _showing_result: bool = false
var _last_result: Dictionary = {}
var _status_key: String = ""


func _ready() -> void:
	UiKit.apply(self)
	Game.ensure_state()
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
	main.add_child(_build_top_bar())

	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(body)
	body.add_child(_build_hero_panel())
	body.add_child(_build_activity_panel())
	body.add_child(_build_stats_panel())

	Loc.locale_changed.connect(func(_c: String) -> void: _refresh_all())
	_select_default()
	_refresh_all()
	confirm_button.grab_focus()
	var cal: RefCounted = Game.state.calendar
	print("CULT_READY day=%d slot=%d stamina=%d" % [cal.day, cal.slot, Game.state.player.stamina])
	_check_events()
	await get_tree().process_frame
	await get_tree().process_frame
	var problems: Array[String] = audit_layout()
	var vp := get_viewport_rect().size
	print("LAYOUT_AUDIT size=%dx%d problems=%d" % [int(vp.x), int(vp.y), problems.size()])
	for p in problems:
		print("  audit: ", p)


## Problems that would make this screen hard to use in landscape (see UiKit.audit).
func audit_layout() -> Array[String]:
	return UiKit.audit(self)


# --- Building ---------------------------------------------------------------------------------

func _label(size: int = FONT_BODY) -> Label:
	var l := UiKit.make_label(size)
	return l


func _header(key: String) -> Label:
	var l := _label(FONT_HEAD)
	l.modulate = Color("9be3c3")
	_headers.append([l, key])
	return l


func _panel(stretch: float) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.size_flags_stretch_ratio = stretch
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 6)
	panel.add_child(box)
	# The panel is returned as its inner box; keep a reference to the container for parenting.
	box.set_meta("panel", panel)
	return box


func _build_top_bar() -> Control:
	var bar := HBoxContainer.new()
	bar.add_theme_constant_override("separation", 20)
	# Labels in a horizontal bar must never wrap, or they stack one character per line.
	_day_label = _label(36)
	_slot_label = _label(FONT_BODY)
	_slot_label.size_flags_vertical = Control.SIZE_SHRINK_END
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	status_label = _label(FONT_SMALL)
	status_label.modulate = Color(0.75, 1.0, 0.88, 0.95)
	for l in [_day_label, _slot_label, status_label]:
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
	party_button = UiKit.make_button(Vector2(130, 52))
	party_button.pressed.connect(_show_party)
	save_button = UiKit.make_button(Vector2(130, 52))
	menu_button = UiKit.make_button(Vector2(170, 52))
	for b in [party_button, save_button, menu_button]:
		b.add_theme_font_size_override("font_size", FONT_BODY)
	save_button.pressed.connect(_on_save)
	menu_button.pressed.connect(func() -> void: Router.goto("title"))
	for c in [_day_label, _slot_label, spacer, status_label, party_button, save_button, menu_button]:
		bar.add_child(c)
	return bar


func _build_hero_panel() -> Control:
	var box := _panel(19.0)
	box.add_child(_header("cult.panel.hero"))
	var portrait := HeroPortrait.new()
	portrait.size_flags_vertical = Control.SIZE_EXPAND_FILL
	portrait.custom_minimum_size = Vector2(0, 120)
	box.add_child(portrait)
	_hero_name = _label(FONT_BODY)
	_hero_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(_hero_name)
	_stamina_label = _label(FONT_SMALL)
	box.add_child(_stamina_label)
	_stamina_bar = ProgressBar.new()
	_stamina_bar.show_percentage = false
	_stamina_bar.custom_minimum_size = Vector2(0, 16)
	box.add_child(_stamina_bar)
	_path_box = VBoxContainer.new()
	_path_box.add_theme_constant_override("separation", 6)
	box.add_child(_path_box)
	return box.get_meta("panel")


func _build_activity_panel() -> Control:
	var box := _panel(44.0)
	box.add_child(_header("cult.panel.activities"))
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	box.add_child(grid)
	var group := ButtonGroup.new()
	for def in Content.activities:
		var id: String = def.id
		var b := Button.new()
		b.theme_type_variation = "CardButton"
		b.toggle_mode = true
		b.button_group = group
		b.custom_minimum_size = Vector2(0, 56)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_size_override("font_size", FONT_SMALL)
		b.clip_text = true
		b.pressed.connect(func() -> void: select_activity(id))
		grid.add_child(b)
		cards[id] = b

	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.custom_minimum_size = Vector2(0, 72)
	info_label = _label(FONT_SMALL)
	info_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(info_label)
	box.add_child(scroll)

	confirm_button = UiKit.make_button(Vector2(0, 60))
	confirm_button.add_theme_font_size_override("font_size", FONT_HEAD)
	confirm_button.pressed.connect(_on_confirm)
	box.add_child(confirm_button)
	return box.get_meta("panel")


func _build_stats_panel() -> Control:
	var box := _panel(37.0)
	box.add_theme_constant_override("separation", 2)
	box.add_child(_header("cult.panel.attributes"))
	var attrs := GridContainer.new()
	attrs.columns = 2
	for a in PlayerState.ATTRS:
		var name_label := _label(FONT_BODY)
		var value_label := _label(FONT_BODY)
		value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		value_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		attrs.add_child(name_label)
		attrs.add_child(value_label)
		_attr_labels[a] = [name_label, value_label]
	box.add_child(attrs)

	var derived := GridContainer.new()
	derived.columns = 2
	derived.add_theme_constant_override("h_separation", 8)
	for i in 3:
		var d := _label(FONT_SMALL)
		d.modulate = Color(1, 1, 1, 0.85)
		d.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		derived.add_child(d)
		_derived_labels.append(d)
	box.add_child(derived)

	box.add_child(_header("cult.panel.resources"))
	var res := GridContainer.new()
	res.columns = 2
	res.add_theme_constant_override("h_separation", 8)
	for c in ResourceState.CURRENCIES:
		var l := _label(FONT_SMALL)
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		res.add_child(l)
		_resource_labels[c] = l
	box.add_child(res)

	box.add_child(_header("cult.panel.bonds"))
	_bonds_label = _label(FONT_SMALL)
	box.add_child(_bonds_label)
	return box.get_meta("panel")


# --- Selection and actions ----------------------------------------------------------------------

func _select_default() -> void:
	for def in Content.activities:
		if ActivityRules.availability(Game.state, def).ok:
			select_activity(def.id)
			return
	if not Content.activities.is_empty():
		select_activity(Content.activities[0].id)


func select_activity(id: String) -> void:
	if not cards.has(id):
		return
	selected_id = id
	cards[id].set_pressed_no_signal(true)
	_showing_result = false
	_refresh_info()


func _on_confirm() -> void:
	if _overlay_open() or selected_id == "":
		return
	var def: Dictionary = Content.activity(selected_id)
	if not def.get("options", []).is_empty():
		_show_choice(def)
		return
	_perform(selected_id, "")


func _overlay_open() -> bool:
	return event_panel != null or choice_panel != null or party_panel != null or recruit_panel != null


func _perform(activity_id: String, option_id: String) -> void:
	var r: Dictionary = Game.perform_activity(activity_id, option_id)
	if not r.ok:
		_showing_result = false
		_refresh_all()
		return
	_last_result = r
	_showing_result = true
	_status_key = "cult.autosaved" if r.get("saved", false) else "cult.save_failed"
	print("ACTIVITY %s/%s grade=%s day=%d slot=%d" % [r.activity_id, r.option_id, r.grade, Game.state.calendar.day, Game.state.calendar.slot])
	_refresh_all()
	_check_events()


func _on_save() -> void:
	var r: Dictionary = Game.save_manual()
	_status_key = "cult.saved" if r.ok else "cult.save_failed"
	_refresh_all()


func _on_path_pressed(path_id: String) -> void:
	if Game.choose_path(path_id):
		_refresh_all()


# --- Approach chooser ---------------------------------------------------------------------------

func _show_choice(def: Dictionary) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.62)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(900, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var title := _label(FONT_HEAD)
	title.text = "%s · %s" % [Loc.t(def.name_key), Loc.t("cult.choose_title")]
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	box.add_child(title)
	option_buttons.clear()
	var first: Button = null
	for o in def.options:
		var oid: String = o.id
		var eff: Dictionary = ActivityRules.effective_def(def, oid)
		var av: Dictionary = ActivityRules.availability(Game.state, def, oid)
		var b := Button.new()
		b.theme_type_variation = "CardButton"
		b.custom_minimum_size = Vector2(0, 76)
		b.add_theme_font_size_override("font_size", FONT_SMALL)
		b.clip_text = true
		var line2: String = _cost_list(eff)
		if eff.has("check"):
			line2 += "  " + Loc.t("cult.chance_short", {"chance": ActivityRules.check_chance(Game.state, def, oid)})
		if not av.ok:
			line2 += "  " + Loc.t(av.reasons[0])
		b.text = "%s  %s\n%s  %s" % [Loc.t(o.name_key), Loc.t(o.desc_key), Loc.t("cult.gain", {"list": _reward_list(eff)}), line2]
		b.disabled = not av.ok
		b.pressed.connect(func() -> void: _on_option_chosen(oid))
		box.add_child(b)
		option_buttons[oid] = b
		if first == null and av.ok:
			first = b
	choice_cancel_button = UiKit.make_button(Vector2(0, 56))
	choice_cancel_button.text = Loc.t("cult.choose_cancel")
	choice_cancel_button.add_theme_font_size_override("font_size", FONT_BODY)
	choice_cancel_button.pressed.connect(_close_choice)
	box.add_child(choice_cancel_button)
	choice_panel = overlay
	add_child(overlay)
	(first if first != null else choice_cancel_button).grab_focus()
	print("CHOICE_SHOWN ", def.id)


func _close_choice() -> void:
	if choice_panel != null:
		choice_panel.queue_free()
		choice_panel = null
		option_buttons.clear()
	confirm_button.grab_focus()


func _on_option_chosen(option_id: String) -> void:
	var activity_id := selected_id
	_close_choice()
	_perform(activity_id, option_id)


# --- Story hooks ---------------------------------------------------------------------------------

func _check_events() -> void:
	if event_panel != null or recruit_panel != null:
		return
	var pending: Array = Game.pending_events()
	if not pending.is_empty():
		_show_event(pending[0])


func _show_event(hook: Dictionary) -> void:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.62)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(640, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	var title := _label(36)
	title.text = Loc.t(hook.title_key)
	var body := _label(FONT_BODY)
	body.text = Loc.t(hook.body_key)
	event_continue_button = UiKit.make_button(Vector2(0, 64))
	event_continue_button.text = Loc.t("event.continue")
	box.add_child(title)
	box.add_child(body)
	box.add_child(event_continue_button)
	var hook_id: String = hook.id
	event_continue_button.pressed.connect(func() -> void:
		Game.acknowledge_event(hook_id)
		overlay.visible = false
		overlay.queue_free()
		event_panel = null
		_refresh_all()
		if str(hook.get("payload", {}).get("type", "")) == "recruitment_opportunity" and _show_recruit_prompt(str(hook.payload.npc)):
			return
		_check_events())
	event_panel = overlay
	add_child(overlay)
	event_continue_button.grab_focus()
	print("EVENT_SHOWN ", hook_id)


# --- Companions (M7) ----------------------------------------------------------------------------

func _make_overlay(width: float) -> Array:
	var overlay := ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.62)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(width, 0)
	center.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	return [overlay, box]


func _show_party() -> void:
	if _overlay_open():
		return
	var parts := _make_overlay(1000)
	party_panel = parts[0]
	_party_box = parts[1]
	add_child(party_panel)
	_fill_party(_party_box)
	print("PARTY_SHOWN")


func _fill_party(box: VBoxContainer) -> void:
	for c in box.get_children():
		box.remove_child(c)
		c.queue_free()
	party_buttons.clear()
	var st: RefCounted = Game.state
	var title := _label(FONT_HEAD)
	title.text = Loc.t("party.title")
	title.autowrap_mode = TextServer.AUTOWRAP_OFF
	box.add_child(title)
	for id in Content.companion_ids():
		box.add_child(_party_row(st, id))
	party_close_button = UiKit.make_button(Vector2(0, 56))
	party_close_button.text = Loc.t("party.close")
	party_close_button.add_theme_font_size_override("font_size", FONT_BODY)
	party_close_button.pressed.connect(_close_party)
	box.add_child(party_close_button)
	party_close_button.grab_focus()


func _party_row(st: RefCounted, id: String) -> Control:
	var c: Dictionary = Content.companion(id)
	var status: String = st.relationships.get_status(id)
	var row := PanelContainer.new()
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	row.add_child(h)
	var portrait := CompanionPortrait.new()
	portrait.setup(Loc.t(c.name_key), ROLE_COLORS.get(c.role, Color.WHITE))
	h.add_child(portrait)
	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 0)
	h.add_child(info)
	var status_text: String = Loc.t("status." + status)
	if st.relationships.active == id:
		status_text = Loc.t("party.active")
	var line1 := _label(FONT_BODY)
	line1.autowrap_mode = TextServer.AUTOWRAP_OFF
	line1.text = "%s  ·  %s  ·  %s" % [Loc.t(c.name_key), status_text, Loc.t("party.affinity", {"score": st.relationships.get_score(id)})]
	info.add_child(line1)
	var likes: Array = []
	for a in c.preferred_activities:
		likes.append(Loc.t("activity." + str(a)))
	var line2 := _label(FONT_SMALL)
	line2.autowrap_mode = TextServer.AUTOWRAP_OFF
	line2.modulate = Color(1, 1, 1, 0.8)
	line2.text = Loc.t("party.role_line", {"role": Loc.t("role." + str(c.role)), "list": Loc.t("ui.list_sep").join(likes)})
	info.add_child(line2)
	var line3 := _label(FONT_SMALL)
	line3.autowrap_mode = TextServer.AUTOWRAP_OFF
	line3.modulate = Color(0.75, 1.0, 0.88, 0.9)
	info.add_child(line3)
	var btns := {}
	var col := VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)
	h.add_child(col)
	if status == "joined":
		line3.text = Loc.t("ability.%s" % c.battle_abilities[0]) + Loc.t("ui.list_sep") + Loc.t("ability.%s" % c.battle_abilities[1])
		if st.relationships.active != id:
			btns["activate"] = _row_button("party.set_active", func() -> void: _party_action("activate", id))
		btns["dismiss"] = _row_button("party.dismiss", func() -> void: _party_action("dismiss", id))
	elif status == "available" or status == "left":
		var ev: Dictionary = RelationshipRules.evaluate_recruitment(st, id, Content)
		if ev.result == "ready":
			line3.text = Loc.t("recruit.body_ready", {"name": Loc.t(c.name_key)})
			btns["recruit"] = _row_button("party.recruit", func() -> void: _party_action("recruit", id))
		else:
			line3.text = Loc.t("party.hint_refuse", {"list": _reason_text(ev.reasons)})
	for k in btns:
		col.add_child(btns[k])
	party_buttons[id] = btns
	return row


func _row_button(key: String, cb: Callable) -> Button:
	var b := UiKit.make_button(Vector2(190, 48))
	b.add_theme_font_size_override("font_size", FONT_SMALL)
	b.text = Loc.t(key)
	b.pressed.connect(cb)
	return b


func _reason_text(reasons: Array) -> String:
	var out: Array = []
	for r in reasons:
		var params: Dictionary = (r.params as Dictionary).duplicate()
		if params.has("attr"):
			params["attr"] = Loc.t("attr." + str(params.attr))
		out.append(Loc.t(r.key, params))
	return Loc.t("ui.list_sep").join(out)


func _party_action(action: String, id: String) -> void:
	match action:
		"recruit":
			if Game.recruit_companion(id).ok:
				_status_key = ""
		"activate":
			Game.set_active_companion(id)
		"dismiss":
			Game.dismiss_companion(id)
	if party_panel != null:
		_fill_party(_party_box)
	_refresh_all()


func _close_party() -> void:
	if party_panel != null:
		party_panel.queue_free()
		party_panel = null
		party_buttons.clear()
	party_button.grab_focus()


## Shows the invitation dialog for a story opportunity. Returns false (and shows nothing) when the
## companion cannot be invited at all, so the caller carries on with the next event.
func _show_recruit_prompt(npc_id: String) -> bool:
	var ev: Dictionary = RelationshipRules.evaluate_recruitment(Game.state, npc_id, Content)
	if ev.result == "unavailable":
		return false
	var parts := _make_overlay(760)
	var box: VBoxContainer = parts[1]
	var name_text: String = Loc.t("npc." + npc_id)
	var title := _label(FONT_HEAD)
	title.text = Loc.t("recruit.title", {"name": name_text})
	box.add_child(title)
	var body := _label(FONT_BODY)
	body.text = Loc.t("recruit.body_ready", {"name": name_text}) if ev.result == "ready" else Loc.t("recruit.body_refuse", {"name": name_text, "list": _reason_text(ev.reasons)})
	box.add_child(body)
	recruit_accept_button = null
	if ev.result == "ready":
		recruit_accept_button = UiKit.make_button(Vector2(0, 60))
		recruit_accept_button.text = Loc.t("recruit.accept")
		recruit_accept_button.add_theme_font_size_override("font_size", FONT_BODY)
		recruit_accept_button.pressed.connect(func() -> void:
			Game.recruit_companion(npc_id)
			_status_key = ""
			_close_recruit())
		box.add_child(recruit_accept_button)
	recruit_decline_button = UiKit.make_button(Vector2(0, 60))
	recruit_decline_button.text = Loc.t("recruit.decline")
	recruit_decline_button.add_theme_font_size_override("font_size", FONT_BODY)
	recruit_decline_button.pressed.connect(func() -> void:
		Game.decline_companion(npc_id)
		_close_recruit())
	box.add_child(recruit_decline_button)
	recruit_panel = parts[0]
	add_child(recruit_panel)
	(recruit_accept_button if recruit_accept_button != null else recruit_decline_button).grab_focus()
	print("RECRUIT_PROMPT %s %s" % [npc_id, ev.result])
	return true


func _close_recruit() -> void:
	if recruit_panel != null:
		recruit_panel.queue_free()
		recruit_panel = null
	_refresh_all()
	_check_events()
	if event_panel == null and not _overlay_open():
		confirm_button.grab_focus()


# --- Refresh -------------------------------------------------------------------------------------

func _refresh_all() -> void:
	var st: RefCounted = Game.state
	var cal: RefCounted = st.calendar
	for h in _headers:
		h[0].text = Loc.t(h[1])
	_day_label.text = Loc.t("cult.day", {"day": cal.day, "total": cal.DAYS})
	_slot_label.text = Loc.t("cult.finished") if cal.finished else Loc.t("cult.slot", {"slot": cal.slot, "total": cal.SLOTS})
	party_button.text = Loc.t("cult.party")
	save_button.text = Loc.t("cult.save")
	menu_button.text = Loc.t("cult.menu")
	status_label.text = Loc.t(_status_key) if _status_key != "" else ""
	confirm_button.text = Loc.t("cult.confirm")

	_refresh_hero(st)
	_refresh_cards(st)
	_refresh_stats(st)
	_refresh_info()


func _refresh_hero(st: RefCounted) -> void:
	var max_st: int = CultivationRules.max_stamina(st.player)
	_hero_name.text = Loc.t("cult.hero.name")
	_stamina_label.text = Loc.t("cult.stamina_value", {"cur": st.player.stamina, "max": max_st})
	_stamina_bar.max_value = max_st
	_stamina_bar.value = st.player.stamina

	for c in _path_box.get_children():
		_path_box.remove_child(c)
		c.queue_free()
	path_buttons.clear()
	var path_id: String = st.player.path_id
	if path_id == "":
		var hint := _label(FONT_SMALL)
		hint.text = Loc.t("cult.path_pick_hint")
		_path_box.add_child(hint)
		for p in Content.paths:
			var pid: String = p.id
			var b := Button.new()
			b.theme_type_variation = "CardButton"
			b.custom_minimum_size = Vector2(0, 48)
			b.add_theme_font_size_override("font_size", FONT_SMALL)
			b.text = Loc.t(p.name_key)
			b.clip_text = true
			b.pressed.connect(func() -> void: _on_path_pressed(pid))
			_path_box.add_child(b)
			path_buttons[pid] = b
	else:
		var name_label := _label(FONT_BODY)
		name_label.text = "%s  %s" % [Loc.t("path." + path_id), Loc.t("cult.path_progress", {"progress": int(st.cultivation.path_progress.get(path_id, 0))})]
		_path_box.add_child(name_label)
		var tech_label := _label(FONT_SMALL)
		var names: Array = []
		for t_id in st.player.techniques:
			names.append(Loc.t("technique." + str(t_id)))
		tech_label.text = Loc.t("cult.techniques_line", {"list": Loc.t("ui.list_sep").join(names) if not names.is_empty() else Loc.t("cult.techniques_none")})
		_path_box.add_child(tech_label)
	if not st.player.buffs.is_empty():
		var buff_label := _label(FONT_SMALL)
		var entries: Array = []
		for b in st.player.buffs:
			entries.append(Loc.t("cult.buff_entry", {"name": Loc.t("buff." + str(b.id)), "attr": Loc.t("attr." + str(b.attr)), "amount": "%+d" % int(b.amount), "slots": int(b.slots)}))
		buff_label.text = Loc.t("cult.buffs_line", {"list": _sep().join(entries)})
		_path_box.add_child(buff_label)


func _refresh_cards(st: RefCounted) -> void:
	for def in Content.activities:
		var b: Button = cards[def.id]
		var stamina_cost: int = int(def.get("cost", {}).get("stamina", 0))
		b.text = "%s\n%s" % [Loc.t(def.name_key), Loc.t("cult.delta", {"name": Loc.t("cult.stamina"), "amount": str(stamina_cost)})]
		var available: bool = ActivityRules.availability(st, def).ok
		b.modulate = Color(1, 1, 1, 1.0 if available else 0.55)


func _refresh_stats(st: RefCounted) -> void:
	for a in PlayerState.ATTRS:
		_attr_labels[a][0].text = Loc.t("attr." + a)
		_attr_labels[a][1].text = str(st.player.get_attr(a))
	var derived := [
		["cult.health", CultivationRules.max_health(st.player)],
		["cult.initiative", CultivationRules.initiative(st.player)],
		["cult.techpoints", CultivationRules.technique_points(st.player)],
	]
	for i in derived.size():
		_derived_labels[i].text = Loc.t("cult.delta", {"name": Loc.t(derived[i][0]), "amount": str(derived[i][1])})
	for c in ResourceState.CURRENCIES:
		_resource_labels[c].text = Loc.t("cult.delta", {"name": Loc.t("resource." + c), "amount": str(st.resources.get_amount(c))})
	var bonds: Array = []
	for npc in st.relationships.scores:
		if int(st.relationships.scores[npc]) != 0:
			bonds.append(Loc.t("cult.delta", {"name": Loc.t("npc." + str(npc)), "amount": str(st.relationships.scores[npc])}))
	_bonds_label.text = Loc.t("ui.list_sep").join(bonds) if not bonds.is_empty() else Loc.t("cult.bonds_none")
	if st.relationships.active != "":
		_bonds_label.text += "\n" + Loc.t("cult.active_companion", {"name": Loc.t("npc." + st.relationships.active)})


func _refresh_info() -> void:
	if selected_id == "":
		return
	var st: RefCounted = Game.state
	var def: Dictionary = Content.activity(selected_id)
	if _showing_result and not _last_result.is_empty():
		info_label.text = _result_text(_last_result)
	else:
		info_label.text = _detail_text(def)
	confirm_button.disabled = not ActivityRules.availability(st, def).ok


# --- Text builders -------------------------------------------------------------------------------

func _sep() -> String:
	return Loc.t("ui.list_sep")


func _name_for(type: String, id: String) -> String:
	match type:
		"attr":
			return Loc.t("attr." + id)
		"resource":
			return Loc.t("resource." + id)
		"item":
			return Loc.t("item." + id)
		"buff":
			return Loc.t("buff." + id)
		"relationship":
			return "%s %s" % [Loc.t("npc." + id), Loc.t("cult.affinity")]
		"stamina":
			return Loc.t("cult.stamina")
		"path_progress":
			if id == "current":
				return Loc.t("cult.progress")
			return "%s %s" % [Loc.t("path." + id), Loc.t("cult.progress")]
	return id


func _cost_list(def: Dictionary) -> String:
	var parts: Array = []
	var cost: Dictionary = def.get("cost", {})
	for k in cost:
		if int(cost[k]) > 0:
			var nm: String = Loc.t("cult.stamina") if k == "stamina" else Loc.t("resource." + str(k))
			parts.append(Loc.t("cult.delta", {"name": nm, "amount": str(int(cost[k]))}))
	return _sep().join(parts) if not parts.is_empty() else Loc.t("cult.nocost")


func _reward_list(def: Dictionary) -> String:
	var parts: Array = []
	for r in def.get("rewards", []):
		parts.append(Loc.t("cult.delta", {"name": _name_for(r.type, r.id), "amount": "%+d" % int(r.amount)}))
	return _sep().join(parts)


func _detail_text(def: Dictionary) -> String:
	var lines: Array[String] = [Loc.t(def.desc_key)]
	if not def.get("options", []).is_empty():
		var names: Array = []
		for o in def.options:
			names.append(Loc.t(o.name_key))
		lines.append(Loc.t("cult.approaches", {"list": _sep().join(names)}))
	else:
		lines.append(Loc.t("cult.cost", {"list": _cost_list(def)}))
		lines.append(Loc.t("cult.gain", {"list": _reward_list(def)}))
	if def.has("check") and def.get("options", []).is_empty():
		lines.append(Loc.t("cult.check", {"attr": Loc.t("attr." + str(def.check.attr)), "target": int(def.check.target),
				"chance": ActivityRules.check_chance(Game.state, def)}))
	var av: Dictionary = ActivityRules.availability(Game.state, def)
	if not av.ok:
		var reasons: Array = []
		for key in av.reasons:
			reasons.append(Loc.t(key))
		lines.append(Loc.t("cult.blocked", {"list": _sep().join(reasons)}))
	return "\n".join(lines)


func _result_text(r: Dictionary) -> String:
	var lines: Array[String] = [Loc.t("cult.result.success" if r.grade == "success" else "cult.result.partial")]
	var gained: Array = []
	for d in r.deltas:
		gained.append(Loc.t("cult.delta", {"name": _name_for(d.type, d.id), "amount": "%+d" % int(d.delta)}))
	lines.append(Loc.t("cult.result.gained", {"list": _sep().join(gained) if not gained.is_empty() else Loc.t("cult.result.nothing")}))
	var stamina_entries := 0
	for c0 in r.cost:
		if c0.id == "stamina":
			stamina_entries += 1
	if stamina_entries > 1:
		lines.append(Loc.t("cult.result.extra_loss"))
	var paid: Array = []
	for c in r.cost:
		var nm: String = Loc.t("cult.stamina") if c.id == "stamina" else Loc.t("resource." + str(c.id))
		paid.append(Loc.t("cult.delta", {"name": nm, "amount": "-%d" % int(c.amount)}))
	if not paid.is_empty():
		lines.append(Loc.t("cult.result.paid", {"list": _sep().join(paid)}))
	if not r.unlocked.is_empty():
		var names: Array = []
		for t_id in r.unlocked:
			names.append(Loc.t("technique." + str(t_id)))
		lines.append(Loc.t("cult.result.unlocked", {"list": _sep().join(names)}))
	if not r.met.is_empty():
		lines.append(Loc.t("cult.result.met", {"list": _sep().join(r.met.map(func(i: String) -> String: return Loc.t("npc." + i)))}))
	if not r.departed.is_empty():
		lines.append(Loc.t("cult.result.departed", {"list": _sep().join(r.departed.map(func(i: String) -> String: return Loc.t("npc." + i)))}))
	if not r.expired_buffs.is_empty():
		var faded: Array = []
		for b_id in r.expired_buffs:
			faded.append(Loc.t("buff." + str(b_id)))
		lines.append(Loc.t("cult.buff_expired", {"list": _sep().join(faded)}))
	if r.time.new_day:
		lines.append(Loc.t("cult.result.new_day", {"amount": int(r.time.recovered)}))
	return "\n".join(lines)
