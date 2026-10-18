extends Control
## Menu-based exploration (M8): story text on the left, choices on the right, and a feedback box that
## shows the last check, costs and changes. All rules live in ExplorationSystem; this scene only shows
## state and forwards the chosen option to Game, which autosaves after every step.

const UiKit = preload("res://scripts/ui/ui_kit.gd")
const Backdrop = preload("res://scenes/shared/backdrop.gd")
const SafeFrame = preload("res://scenes/shared/safe_frame.gd")
const ExplorationSystem = preload("res://scripts/domain/exploration_system.gd")
const RecruitDialog = preload("res://scenes/shared/recruit_dialog.gd")
const OverlayUtil = preload("res://scenes/shared/overlay_util.gd")
const DeltaText = preload("res://scenes/shared/delta_text.gd")
const CultivationRules = preload("res://scripts/domain/cultivation_rules.gd")

const FONT_BODY := 24
const FONT_SMALL := 22
const FONT_HEAD := 28

# Public so tests can drive the screen like a player.
var choice_buttons: Dictionary = {}   # choice id -> Button
var continue_button: Button           # only after the route ended
var fight_button: Button              # when a story node triggered a battle
var text_label: Label
var result_label: Label
var recruit_panel: Control = null
var recruit_accept_button: Button
var recruit_decline_button: Button

var _title_label: Label
var _clues_label: Label
var _stamina_label: Label
var _choices_box: VBoxContainer
var _last_result: Dictionary = {}
var _ended: bool = false
var _bar: BoxContainer
var _body: BoxContainer
var _story_panel: PanelContainer
var _choice_panel: PanelContainer
var _end_node_id: String = ""


func _ready() -> void:
	UiKit.apply(self)
	Game.ensure_state()
	var story_scene := Game.next_story_scene()  # an interrupted fight, an open scene, an ending, a day-start scene
	if story_scene != "":
		Router.goto.call_deferred(story_scene)
		return
	add_child(Backdrop.new("cangwu_day"))
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.04, 0.03, 0.25)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var frame := SafeFrame.new()
	add_child(frame)
	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", 12)
	frame.add_child(main)

	var bar := BoxContainer.new()
	_bar = bar
	bar.add_theme_constant_override("separation", 24)
	_title_label = UiKit.make_label(36)
	_clues_label = UiKit.make_label(FONT_BODY)
	_stamina_label = UiKit.make_label(FONT_BODY)
	for l in [_title_label, _clues_label, _stamina_label]:
		l.autowrap_mode = TextServer.AUTOWRAP_OFF
		bar.add_child(l)
	_clues_label.size_flags_vertical = Control.SIZE_SHRINK_END
	_stamina_label.size_flags_vertical = Control.SIZE_SHRINK_END
	main.add_child(bar)

	var body := BoxContainer.new()
	_body = body
	body.add_theme_constant_override("separation", 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(body)

	var story_panel := PanelContainer.new()
	_story_panel = story_panel
	story_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	story_panel.size_flags_stretch_ratio = 58.0
	body.add_child(story_panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	story_panel.add_child(scroll)
	var story_box := VBoxContainer.new()
	story_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_box.add_theme_constant_override("separation", 16)
	scroll.add_child(story_box)
	text_label = UiKit.make_label(FONT_BODY)
	text_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_label = UiKit.make_label(FONT_SMALL)
	result_label.modulate = Color(0.75, 1.0, 0.88, 0.95)
	result_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	story_box.add_child(text_label)
	story_box.add_child(result_label)

	var choice_panel := PanelContainer.new()
	_choice_panel = choice_panel
	choice_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	choice_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_panel.size_flags_stretch_ratio = 42.0
	body.add_child(choice_panel)
	var choice_scroll := ScrollContainer.new()
	choice_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	choice_panel.add_child(choice_scroll)
	_choices_box = VBoxContainer.new()
	_choices_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_choices_box.add_theme_constant_override("separation", 10)
	choice_scroll.add_child(_choices_box)

	Loc.locale_changed.connect(func(_c: String) -> void: _refresh())
	Layout.mode_changed.connect(func(_m: String) -> void: _on_layout_changed())
	_apply_layout()
	if not Game.state.exploration.active:  # nothing to explore: go back to training
		Router.goto.call_deferred("cultivation")
		return
	_refresh()
	print("EXPLORE_READY route=%s node=%s" % [Game.state.exploration.route, Game.state.exploration.node])
	_maybe_recruit()
	_report_layout()


## Landscape: story left, choices right. Portrait: title bar wraps, story above, choices below.
func _apply_layout() -> void:
	var portrait: bool = Layout.is_portrait()
	_bar.vertical = portrait
	_bar.add_theme_constant_override("separation", 4 if portrait else 24)
	_body.vertical = portrait
	_title_label.add_theme_font_size_override("font_size", 32 if portrait else 36)
	for l in [_clues_label, _stamina_label]:
		l.size_flags_vertical = Control.SIZE_FILL if portrait else Control.SIZE_SHRINK_END
	# Portrait gives the story a little more than the choices; landscape keeps 58:42 side by side.
	_story_panel.size_flags_stretch_ratio = 46.0 if portrait else 58.0
	_choice_panel.size_flags_stretch_ratio = 54.0 if portrait else 42.0


func _on_layout_changed() -> void:
	_apply_layout()
	OverlayUtil.fit(recruit_panel)
	_refresh()


func _report_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var vp := get_viewport_rect().size
	var problems: Array[String] = UiKit.audit(self)
	print("LAYOUT_AUDIT size=%dx%d problems=%d" % [int(vp.x), int(vp.y), problems.size()])
	for p in problems:
		print("  audit: ", p)


func audit_layout() -> Array[String]:
	return UiKit.audit(self)


func _route() -> Dictionary:
	return Game.current_route()


func _refresh() -> void:
	var st: RefCounted = Game.state
	var route := _route()
	_title_label.text = Loc.t("explore.title", {"name": Loc.t(route.name_key)})
	_clues_label.text = Loc.t("explore.clues", {"n": st.exploration.clues.size()})
	_stamina_label.text = Loc.t("cult.stamina_value", {"cur": st.player.stamina, "max": CultivationRules.max_stamina(st.player)})
	var node: Dictionary = ExplorationSystem.node_of(route, _end_node_id if _ended else st.exploration.node)
	text_label.text = Loc.t(node.text_key)
	result_label.text = _result_text(_last_result) if not _last_result.is_empty() else ""
	_rebuild_choices(route)


func _rebuild_choices(route: Dictionary) -> void:
	for c in _choices_box.get_children():
		_choices_box.remove_child(c)
		c.queue_free()
	choice_buttons.clear()
	continue_button = null
	var head := UiKit.make_label(FONT_HEAD)
	head.modulate = Color("e3c27a")
	head.text = Loc.t("explore.choose")
	_choices_box.add_child(head)
	fight_button = null
	var pending: String = Game.state.exploration.pending_battle
	if pending != "":
		fight_button = UiKit.make_button(Vector2(0, 76))
		fight_button.theme_type_variation = "SealButton"
		fight_button.add_theme_font_size_override("font_size", FONT_BODY)
		fight_button.text = Loc.t("explore.fight", {"name": Loc.t("battle." + pending)})
		fight_button.pressed.connect(_start_fight)
		_choices_box.add_child(fight_button)
		if recruit_panel == null:
			fight_button.grab_focus()
		return
	if _ended:
		continue_button = UiKit.make_button(Vector2(0, 76))
		continue_button.add_theme_font_size_override("font_size", FONT_BODY)
		continue_button.text = Loc.t("explore.continue")
		continue_button.pressed.connect(func() -> void: Router.goto("cultivation"))
		_choices_box.add_child(continue_button)
		if recruit_panel == null:
			continue_button.grab_focus()
		return
	var first: Button = null
	for cs in ExplorationSystem.choice_states(Game.state, route, Content):
		var cid: String = cs.id
		var b := Button.new()
		b.theme_type_variation = "CardButton"
		b.custom_minimum_size = Vector2(0, 76)
		b.add_theme_font_size_override("font_size", FONT_SMALL)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.clip_text = true
		var note: Array = []
		for k in cs.cost:
			if int(cs.cost[k]) > 0:
				note.append(Loc.t("cult.delta", {"name": Loc.t("resource." + str(k)), "amount": "-%d" % int(cs.cost[k])}))
		if cs.chance >= 0:
			note.append(Loc.t("explore.chance", {"chance": cs.chance}))
		if not cs.available:
			note = [RecruitDialog.reason_text(cs.reasons)]
		b.text = Loc.t(cs.label_key) + ("\n" + Loc.t("ui.list_sep").join(note) if not note.is_empty() else "")
		b.disabled = not cs.available
		b.pressed.connect(func() -> void: _on_choice(cid))
		_choices_box.add_child(b)
		choice_buttons[cid] = b
		if first == null and cs.available:
			first = b
	if first != null and recruit_panel == null:
		first.grab_focus()


func _start_fight() -> void:
	var id: String = Game.state.exploration.pending_battle
	if Game.start_battle(id, "exploration"):
		Router.goto("battle")
	else:  # no scenario for this trigger: skip it rather than trap the player
		Game.state.exploration.pending_battle = ""
		_refresh()


func choose(choice_id: String) -> void:
	_on_choice(choice_id)


func _on_choice(choice_id: String) -> void:
	if recruit_panel != null or _ended:
		return
	var r: Dictionary = Game.explore_choose(choice_id)
	if not r.ok:
		_refresh()
		return
	_last_result = r
	print("EXPLORE %s/%s grade=%s next=%s ended=%s" % [r.node, r.choice, r.grade, r.next, r.ended])
	if r.ended:
		_ended = true
		_end_node_id = r.next
	_refresh()
	_maybe_recruit()


func _maybe_recruit() -> void:
	var npc: String = Game.state.exploration.pending_recruit
	if npc == "" or recruit_panel != null:
		return
	var d: Dictionary = RecruitDialog.build(npc, _close_recruit)
	if d.is_empty():
		Game.clear_pending_recruit()
		return
	recruit_accept_button = d.accept
	recruit_decline_button = d.decline
	recruit_panel = d.overlay
	add_child(recruit_panel)
	(recruit_accept_button if recruit_accept_button != null else recruit_decline_button).grab_focus()
	_report_layout()


func _close_recruit() -> void:
	Game.clear_pending_recruit()
	if recruit_panel != null:
		recruit_panel.queue_free()
		recruit_panel = null
	_refresh()


func _result_text(r: Dictionary) -> String:
	var lines: Array[String] = []
	if r.text_key != "":
		lines.append(Loc.t(r.text_key))
	if not r.check.is_empty():
		lines.append(Loc.t("explore.check", {"attr": Loc.t("attr." + str(r.check.attr)), "target": int(r.check.target),
				"roll": int(r.check.roll), "chance": int(r.check.chance)}) + " - " + Loc.t("explore.check_ok" if r.grade == "success" else "explore.check_fail"))
	var paid: Array = []
	for c in r.cost:
		var nm: String = Loc.t("cult.stamina") if c.id == "stamina" else Loc.t("resource." + str(c.id))
		paid.append(Loc.t("cult.delta", {"name": nm, "amount": "-%d" % int(c.amount)}))
	if not paid.is_empty():
		lines.append(Loc.t("cult.result.paid", {"list": Loc.t("ui.list_sep").join(paid)}))
	var gained: Array = []
	for d in r.deltas:
		if d.type != "battle":
			gained.append(DeltaText.delta_line(d))
	if not r.flags.is_empty():
		gained.append(Loc.t("explore.fx.flag"))
	if not gained.is_empty():
		lines.append(Loc.t("explore.gained", {"list": Loc.t("ui.list_sep").join(gained)}))
	if r.battle != "":
		lines.append(Loc.t("explore.battle_pending", {"name": Loc.t("battle." + str(r.battle))}))
	if r.ended:
		lines.append(Loc.t("explore.ended"))
		if not r.time.is_empty() and r.time.new_week:
			lines.append(Loc.t("cult.result.new_week", {"amount": int(r.time.recovered)}))
		if not r.met.is_empty():
			lines.append(Loc.t("cult.result.met", {"list": Loc.t("ui.list_sep").join(r.met.map(func(i: String) -> String: return Loc.t("npc." + i)))}))
		if not r.departed.is_empty():
			lines.append(Loc.t("cult.result.departed", {"list": Loc.t("ui.list_sep").join(r.departed.map(func(i: String) -> String: return Loc.t("npc." + i)))}))
	return "\n".join(lines)
