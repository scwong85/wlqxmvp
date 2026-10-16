extends Control
## Arts and gear (M20b): the school's skill tree, manuals and equipment. Rules live in SkillTree, ManualRules and
## EquipmentRules; this screen only lists them and forwards the actions to Game.

const UiKit = preload("res://scripts/ui/ui_kit.gd")
const Backdrop = preload("res://scenes/shared/backdrop.gd")
const SafeFrame = preload("res://scenes/shared/safe_frame.gd")
const SkillTree = preload("res://scripts/domain/skill_tree.gd")
const ManualRules = preload("res://scripts/domain/manual_rules.gd")
const EquipmentRules = preload("res://scripts/domain/equipment_rules.gd")

const TABS := ["tree", "manuals", "gear"]

# Public so tests can drive the screen like a player.
var back_button: Button
var tab_buttons: Dictionary = {}
var action_buttons: Dictionary = {}   # node / manual / piece id -> its action button (only those shown)
var notice_label: Label
var tab: String = "tree"

var _title: Label
var _list: VBoxContainer


func _ready() -> void:
	UiKit.apply(self)
	Game.ensure_state()
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
	back_button.pressed.connect(func() -> void: Router.goto("sheet"))
	top.add_child(back_button)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	main.add_child(tabs)
	for t in TABS:
		var b := UiKit.make_button(Vector2(0, 52))
		b.add_theme_font_size_override("font_size", 22)
		b.toggle_mode = true
		b.clip_text = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.pressed.connect(func() -> void: select_tab(t))
		tabs.add_child(b)
		tab_buttons[t] = b
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
	print("ARTS_READY")
	_report_layout()


func select_tab(id: String) -> void:
	tab = id
	_refresh()


func _label(text: String, size: int = 22, dim: bool = false) -> Label:
	var l := UiKit.make_label(size)
	l.text = text
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if dim:
		l.modulate = Color(1, 1, 1, 0.7)
	return l


func _button(text: String, cb: Callable, disabled: bool = false) -> Button:
	var b := UiKit.make_button(Vector2(0, 56))
	b.add_theme_font_size_override("font_size", 22)
	b.text = text
	b.clip_text = true
	b.disabled = disabled
	b.pressed.connect(cb)
	return b


func _card() -> VBoxContainer:
	var p := PanelContainer.new()
	p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_list.add_child(p)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	p.add_child(v)
	return v


func _realm_name(i: int) -> String:
	return Loc.t(str(Content.realms[clampi(i, 0, Content.realms.size() - 1)].name_key))


func _reason_text(r: Dictionary) -> String:
	var params: Dictionary = (r.params as Dictionary).duplicate()
	if params.has("realm"):
		params["realm"] = _realm_name(int(params.realm))
		return Loc.t(str(r.key), params)
	if params.has("list"):
		var names: Array = []
		for id in params.list:
			names.append(Loc.t(str(SkillTree.node(Content, str(id)).get("name_key", ""))))
		return Loc.t(str(r.key), {"list": Loc.t("ui.list_sep").join(names)})
	return Loc.t(str(r.key))


func _reasons_line(reasons: Array) -> String:
	var parts: Array = []
	for r in reasons:
		parts.append(_reason_text(r))
	return Loc.t("ui.list_sep").join(parts)


func _stat_text(bonus: Dictionary) -> String:
	var parts: Array = []
	for k in bonus:
		parts.append("%s +%d" % [Loc.t("arts.stat." + str(k)), int(bonus[k])])
	return Loc.t("ui.list_sep").join(parts)


func _refresh() -> void:
	_title.text = Loc.t("arts.title")
	back_button.text = Loc.t("arts.back")
	for t in TABS:
		tab_buttons[t].text = Loc.t("arts.tab." + t)
		tab_buttons[t].set_pressed_no_signal(t == tab)
	for c in _list.get_children():
		c.queue_free()
	action_buttons.clear()
	notice_label = null
	match tab:
		"tree":
			_fill_tree()
		"manuals":
			_fill_manuals()
		"gear":
			_fill_gear()


func _notice() -> void:
	notice_label = _label("", 22)
	notice_label.modulate = Color("e1c06b")
	_list.add_child(notice_label)


func _fill_tree() -> void:
	var st: RefCounted = Game.state
	if st.player.path_id == "":
		_list.add_child(_label(Loc.t("tree.none"), 22, true))
		return
	_list.add_child(_label(Loc.t("arts.points", {"n": SkillTree.points_free(st, Content)}), 26))
	_notice()
	for n in SkillTree.nodes_of(st, Content):
		var card := _card()
		var learned := SkillTree.learned(st, str(n.id))
		var head := _label(Loc.t(str(n.name_key)), 24)
		card.add_child(head)
		var e: Dictionary = n.effect
		if str(e.type) == "stat":
			card.add_child(_label(Loc.t("tree.desc.stat", {"stat": Loc.t("arts.stat." + str(e.stat)), "n": int(e.amount)}), 22, true))
		else:
			card.add_child(_label(Loc.t("tree.desc.technique", {"name": Loc.t("technique." + str(e.id))}), 22, true))
		if learned:
			card.add_child(_label(Loc.t("tree.learned"), 22))
			continue
		var c: Dictionary = SkillTree.can_learn(st, str(n.id), Content)
		var id := str(n.id)
		var b := _button(Loc.t("tree.learn", {"cost": int(n.cost)}), func() -> void: _learn(id), not c.ok)
		card.add_child(b)
		action_buttons[id] = b
		if not c.ok:
			card.add_child(_label(_reasons_line(c.reasons), 22, true))


func _learn(id: String) -> void:
	var r: Dictionary = Game.learn_node(id)
	var name_text := Loc.t(str(SkillTree.node(Content, id).get("name_key", "")))
	_refresh()
	if r.ok:
		notice_label.text = Loc.t("tree.done", {"name": name_text})


func _fill_manuals() -> void:
	var st: RefCounted = Game.state
	_list.add_child(_label(Loc.t("manual.hint"), 22, true))
	_notice()
	var have := ManualRules.owned(st, Content)
	if have.is_empty():
		_list.add_child(_label(Loc.t("manual.none"), 22, true))
		return
	for m in have:
		var card := _card()
		card.add_child(_label(Loc.t(str(m.name_key)), 24))
		card.add_child(_label(Loc.t("manual.teaches", {"name": Loc.t("technique." + str(m.technique))}), 22, true))
		var id := str(m.id)
		if ManualRules.studied(st, id):
			card.add_child(_label(Loc.t("manual.known"), 22))
			continue
		var c: Dictionary = ManualRules.can_study(st, id, Content)
		var b := _button(Loc.t("manual.study", {"stamina": ManualRules.STUDY_STAMINA}), func() -> void: _study(id), not c.ok)
		card.add_child(b)
		action_buttons[id] = b
		if not c.ok:
			card.add_child(_label(_reasons_line(c.reasons), 22, true))


func _study(id: String) -> void:
	var r: Dictionary = Game.study_manual(id)
	_refresh()
	if r.ok:
		notice_label.text = Loc.t("manual.done", {"name": Loc.t(str(r.manual.name_key)), "tech": Loc.t("technique." + str(r.manual.technique))})


func _fill_gear() -> void:
	var st: RefCounted = Game.state
	_list.add_child(_label(Loc.t("equip.have", {"ore": st.resources.get_amount("ore"), "coins": st.resources.get_amount("coins")}), 24))
	var total := EquipmentRules.bonus(st, Content)
	if not total.is_empty():
		_list.add_child(_label(Loc.t("equip.bonus", {"list": _stat_text(total)}), 22))
	_notice()
	for slot in EquipmentRules.SLOTS:
		var worn := EquipmentRules.worn(st, slot)
		var worn_name := Loc.t("equip.none") if worn == "" else Loc.t(str(EquipmentRules.piece(Content, worn).name_key))
		_list.add_child(_label("%s: %s" % [Loc.t("equip.slot." + slot), worn_name], 26))
		for e in Content.equipment:
			if str(e.slot) != slot:
				continue
			var id := str(e.id)
			var card := _card()
			card.add_child(_label(Loc.t(str(e.name_key)), 24))
			card.add_child(_label(Loc.t("equip.bonus", {"list": _stat_text(e.bonus)}), 22, true))
			var b: Button
			if EquipmentRules.owned(st, id, Content):
				if worn == id:
					b = _button(Loc.t("equip.unequip"), func() -> void: _equip(slot, ""))
				else:
					b = _button(Loc.t("equip.equip"), func() -> void: _equip(slot, id))
			else:
				var c: Dictionary = EquipmentRules.can_forge(st, id, Content)
				b = _button(Loc.t("equip.forge", {"ore": int(e.cost.ore), "coins": int(e.cost.coins)}), func() -> void: _forge(id), not c.ok)
				if not c.ok:
					card.add_child(_label(_reasons_line(c.reasons), 22, true))
			card.add_child(b)
			action_buttons[id] = b


func _equip(slot: String, id: String) -> void:
	Game.equip_piece(slot, id)
	_refresh()


func _forge(id: String) -> void:
	var r: Dictionary = Game.forge_piece(id)
	_refresh()
	if r.ok:
		notice_label.text = Loc.t("equip.forged", {"name": Loc.t(str(r.piece.name_key))})


func audit_layout() -> Array[String]:
	return UiKit.audit(self)


func _report_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree():
		return
	var vp := get_viewport_rect().size
	var problems := audit_layout()
	print("LAYOUT_AUDIT size=%dx%d problems=%d" % [int(vp.x), int(vp.y), problems.size()])
	for p in problems:
		print("  audit: ", p)
