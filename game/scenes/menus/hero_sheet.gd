extends Control
## Cultivation sheet (M20a): realm and breakthrough, technique levels, life skills. Rules live in RealmRules,
## TechniqueLevels and LifeSkillRules; this screen only shows them and forwards the breakthrough to Game.

const UiKit = preload("res://scripts/ui/ui_kit.gd")
const Backdrop = preload("res://scenes/shared/backdrop.gd")
const SafeFrame = preload("res://scenes/shared/safe_frame.gd")
const RealmRules = preload("res://scripts/domain/realm_rules.gd")
const TechniqueLevels = preload("res://scripts/domain/technique_levels.gd")
const LifeSkillRules = preload("res://scripts/domain/life_skill_rules.gd")
const CultivationRules = preload("res://scripts/domain/cultivation_rules.gd")

# Public so tests can drive the screen like a player.
var break_button: Button
var back_button: Button
var arts_button: Button
var realm_label: Label
var notice_label: Label

var _title: Label
var _list: VBoxContainer
var _stamina_label: Label


func _ready() -> void:
	UiKit.apply(self)
	Game.ensure_state()
	var dest := Game.next_story_scene()
	if dest != "":
		Router.goto.call_deferred(dest)
		return
	add_child(Backdrop.new())
	var frame := SafeFrame.new()
	add_child(frame)
	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", 10)
	frame.add_child(main)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	main.add_child(top)
	_title = UiKit.make_label(36)
	_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(_title)
	back_button = UiKit.make_button(Vector2(150, 56))
	back_button.add_theme_font_size_override("font_size", 24)
	back_button.pressed.connect(func() -> void: Router.goto("cultivation"))
	top.add_child(back_button)
	var panel := PanelContainer.new()
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(panel)
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(scroll)
	_list = VBoxContainer.new()
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_theme_constant_override("separation", 8)
	scroll.add_child(_list)
	Loc.locale_changed.connect(func(_c: String) -> void: _refresh())
	_refresh()
	back_button.grab_focus()
	print("SHEET_READY realm=%d" % Game.state.cultivation.realm)
	_report_layout()


func _label(text: String, size: int = 24, dim: bool = false) -> Label:
	var l := UiKit.make_label(size)
	l.text = text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if dim:
		l.modulate = Color(1, 1, 1, 0.7)
	return l


func _refresh() -> void:
	var st: RefCounted = Game.state
	_title.text = Loc.t("sheet.title")
	back_button.text = Loc.t("sheet.back")
	for c in _list.get_children():
		c.queue_free()
	break_button = null
	var realm: Dictionary = RealmRules.current(st, Content)
	realm_label = _label(Loc.t("sheet.realm_line", {"label": Loc.t("sheet.realm"), "name": Loc.t(str(realm.name_key))}), 30)
	_list.add_child(realm_label)
	_list.add_child(_label(Loc.t(str(realm.desc_key)), 22, true))
	_list.add_child(_label("%s\n%s" % [Loc.t("realm.cap", {"cap": int(realm.attr_cap)}), Loc.t("realm.bonus", {"hp": int(realm.hp_bonus), "tp": int(realm.tp_bonus)})], 22))
	_stamina_label = _label(Loc.t("cult.stamina_value", {"cur": st.player.stamina, "max": CultivationRules.max_stamina(st.player)}), 22)
	_list.add_child(_stamina_label)
	for a in st.player.ATTRS:
		if st.player.get_attr(a) >= st.player.attr_cap and not RealmRules.is_last(st, Content):
			_list.add_child(_label(Loc.t("sheet.bottleneck"), 22, true))
			break
	if RealmRules.is_last(st, Content):
		_list.add_child(_label(Loc.t("sheet.last"), 24))
	else:
		var next: Dictionary = Content.realms[int(st.cultivation.realm) + 1]
		_list.add_child(_label(Loc.t("sheet.next", {"name": Loc.t(str(next.name_key))}), 26))
		for l in RealmRules.requirement_lines(st, Content):
			var t := Loc.t("realm.req." + str(l.key), {"have": int(l.have), "need": int(l.need)})
			var row := _label(("OK  " if l.met else "..  ") + t, 22)
			row.modulate = Color("9be3c3") if l.met else Color(1, 1, 1, 0.8)
			_list.add_child(row)
		var c: Dictionary = RealmRules.can_break(st, Content)
		break_button = UiKit.make_button(Vector2(0, 64))
		break_button.add_theme_font_size_override("font_size", 24)
		break_button.text = Loc.t("sheet.break", {"stamina": RealmRules.BREAKTHROUGH_STAMINA})
		break_button.clip_text = true
		break_button.disabled = not c.ok
		break_button.pressed.connect(_on_break)
		_list.add_child(break_button)
		if not c.ok:
			var why: Array = []
			for r in c.reasons:
				why.append(Loc.t(str(r)))
			_list.add_child(_label(Loc.t("ui.list_sep").join(why), 22, true))
	notice_label = _label("", 24)
	notice_label.modulate = Color("e1c06b")
	_list.add_child(notice_label)

	arts_button = UiKit.make_button(Vector2(0, 64))
	arts_button.add_theme_font_size_override("font_size", 24)
	arts_button.text = Loc.t("arts.button")
	arts_button.pressed.connect(func() -> void: Router.goto("arts"))
	_list.add_child(arts_button)
	_list.add_child(_label(Loc.t("sheet.techniques"), 28))
	if st.player.techniques.is_empty():
		_list.add_child(_label(Loc.t("sheet.no_techniques"), 22, true))
	for t in st.player.techniques:
		var lv := TechniqueLevels.level(st, str(t))
		var xp := int(st.cultivation.technique_xp.get(t, 0))
		var key := "sheet.tech_line_max" if lv >= TechniqueLevels.MAX_LEVEL else "sheet.tech_line"
		_list.add_child(_label(Loc.t(key, {"name": Loc.t("technique." + str(t)), "lv": lv, "xp": "%d/%d" % [xp, xp + TechniqueLevels.xp_to_next(st, str(t))]}), 22))
	_list.add_child(_label(Loc.t("sheet.tech_bonus"), 22, true))
	_list.add_child(_label(Loc.t("sheet.life"), 28))
	for s in LifeSkillRules.skill_ids():
		_list.add_child(_label(Loc.t("sheet.life_line", {"name": Loc.t("lifeskill." + str(s)), "lv": LifeSkillRules.level(st, str(s)), "n": LifeSkillRules.count(st, str(s))}), 22))
	_list.add_child(_label(Loc.t("sheet.life_bonus"), 22, true))


func _on_break() -> void:
	var r: Dictionary = Game.attempt_breakthrough()
	if not r.ok:
		_refresh()
		return
	var name_text := Loc.t(str(RealmRules.current(Game.state, Content).name_key))
	_refresh()
	notice_label.text = Loc.t("sheet.break_done", {"name": name_text})
	print("BREAKTHROUGH realm=%d" % Game.state.cultivation.realm)
	var dest: String = Game.next_story_scene()
	if dest != "":
		Router.goto(dest)


func audit_layout() -> Array[String]:
	return UiKit.audit(self)


func _report_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var vp := get_viewport_rect().size
	var bp := back_button.get_global_rect().get_center()
	print("UI_POS vp=%d,%d sheet_back=%d,%d" % [int(vp.x), int(vp.y), int(bp.x), int(bp.y)])
	var problems := audit_layout()
	print("LAYOUT_AUDIT size=%dx%d problems=%d" % [int(vp.x), int(vp.y), problems.size()])
	for p in problems:
		print("  audit: ", p)
