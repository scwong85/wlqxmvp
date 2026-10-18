extends Control
## Battle screen (M10). The board shows the rules' state; every button calls one rule action.
## Player actions: Move, Attack / Support (pick technique, pick target, then Confirm or Cancel), Item, Guard, End turn.
## Enemy turns are played step by step from BattleAI.decide(); fast-forward only shortens the waits.

const UiKit = preload("res://scripts/ui/ui_kit.gd")
const Backdrop = preload("res://scenes/shared/backdrop.gd")
const SafeFrame = preload("res://scenes/shared/safe_frame.gd")
const OverlayUtil = preload("res://scenes/shared/overlay_util.gd")
const BoardView = preload("res://scenes/battle/board_view.gd")
const BattleText = preload("res://scenes/battle/battle_text.gd")
const DeltaText = preload("res://scenes/shared/delta_text.gd")
const BattleAI = preload("res://scripts/domain/combat/battle_ai.gd")
const CombatGrid = preload("res://scripts/domain/combat/combat_grid.gd")

const FONT := 24
const MAX_LOG := 60

# Public so tests can drive the screen like a player.
var board: Control
var battle: RefCounted
var action_buttons: Dictionary = {}   # id -> Button (move, attack, support, item, guard, end, confirm, cancel, back, skip, tech:<id>)
var continue_button: Button = null
var fast_button: Button
var result_overlay: Control = null
var log_lines: Array[String] = []
var mode: String = "idle"             # idle, move, tech, target, confirm, followup, ai, over
var fast: bool = false

var _title: Label
var _round: Label
var _info: Label
var _action_box: VBoxContainer
var _log_label: Label
var _log_scroll: ScrollContainer
var _body: BoxContainer
var _board_holder: Control
var _side: PanelContainer
var _bar: BoxContainer
var _log_seen: int = 0
var _busy: bool = false
var _kind: String = ""                # attack, support, item
var _tech: String = ""
var _target: String = ""
var _selected: String = ""
var _hint: String = ""


func _ready() -> void:
	UiKit.apply(self)
	Game.ensure_state()
	battle = Game.battle
	if battle == null:
		Router.goto.call_deferred("title")
		return
	add_child(Backdrop.new("shrine_night"))
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.04, 0.03, 0.3)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	var frame := SafeFrame.new()
	add_child(frame)
	var main := VBoxContainer.new()
	main.add_theme_constant_override("separation", 8)
	frame.add_child(main)

	_bar = BoxContainer.new()
	_bar.add_theme_constant_override("separation", 16)
	_title = UiKit.make_label(FONT)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_title.autowrap_mode = TextServer.AUTOWRAP_OFF
	_title.clip_text = true
	_round = UiKit.make_label(FONT)
	_round.autowrap_mode = TextServer.AUTOWRAP_OFF
	fast_button = UiKit.make_button(Vector2(120, 48))
	fast_button.toggle_mode = true
	fast_button.pressed.connect(func() -> void: _set_fast(fast_button.button_pressed))
	for n in [_title, _round, fast_button]:
		_bar.add_child(n)
	main.add_child(_bar)

	_body = BoxContainer.new()
	_body.add_theme_constant_override("separation", 10)
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_child(_body)

	_board_holder = Control.new()
	_board_holder.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board_holder.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board_holder.size_flags_stretch_ratio = 60.0
	_body.add_child(_board_holder)
	board = BoardView.new()
	board.battle = battle
	board.set_anchors_preset(Control.PRESET_FULL_RECT)
	board.cell_tapped.connect(_on_cell)
	_board_holder.add_child(board)

	_side = PanelContainer.new()
	_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_side.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_side.size_flags_stretch_ratio = 40.0
	_body.add_child(_side)
	var side_box := VBoxContainer.new()
	side_box.add_theme_constant_override("separation", 6)
	_side.add_child(side_box)
	_info = UiKit.make_label(FONT)
	_info.custom_minimum_size = Vector2(0, 92)
	_info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	side_box.add_child(_info)
	_action_box = VBoxContainer.new()
	_action_box.custom_minimum_size = Vector2(0, 124)
	_action_box.add_theme_constant_override("separation", 6)
	side_box.add_child(_action_box)
	_log_scroll = ScrollContainer.new()
	_log_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_log_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_log_scroll.custom_minimum_size = Vector2(0, 70)
	side_box.add_child(_log_scroll)
	_log_label = UiKit.make_label(22)
	_log_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_log_label.modulate = Color(0.96, 0.91, 0.8, 0.95)
	_log_scroll.add_child(_log_label)

	Loc.locale_changed.connect(func(_c: String) -> void: _refresh())
	Layout.mode_changed.connect(func(_m: String) -> void: _apply_layout(); _refresh())
	_apply_layout()
	_append_log(Loc.t("combat.scenario." + battle.scenario_id + ".objective"))
	_replay_log()
	print("BATTLE_READY scenario=%s seed=%d" % [battle.scenario_id, battle.seed_value])
	_advance_turns()
	_report_layout()


func _apply_layout() -> void:
	var portrait: bool = Layout.is_portrait()
	_body.vertical = portrait
	board.rotated = not portrait
	_board_holder.size_flags_stretch_ratio = 56.0 if portrait else 60.0
	_side.size_flags_stretch_ratio = 44.0 if portrait else 40.0
	_log_scroll.custom_minimum_size.y = 70.0 if portrait else 120.0
	_side.custom_minimum_size.x = 0.0 if portrait else 430.0
	board.queue_redraw()


## Shows the existing log as text only (a new battle has two lines, a resumed one many), without floating numbers.
func _replay_log() -> void:
	while _log_seen < battle.log.size():
		var line := BattleText.log_line(battle, battle.log[_log_seen])
		_log_seen += 1
		if line != "":
			_append_log(line)
	board.queue_redraw()
	_refresh()


func _set_fast(on: bool) -> void:
	fast = on
	_refresh()


# ---------------------------------------------------------------- turn flow

func _advance_turns() -> void:
	if battle.outcome != "":
		_finish()
		return
	var u: RefCounted = battle.active()
	if u == null:
		return
	if u.team == "player" and not u.npc:
		_begin_player_turn()
	else:
		_run_ai_turn()


func _begin_player_turn() -> void:
	_busy = false
	_selected = battle.active().id
	Game.save_battle_progress()
	_set_mode("idle")


func _run_ai_turn() -> void:
	if _busy:
		return
	_busy = true
	_set_mode("ai")
	var u: RefCounted = battle.active()
	await _wait(0.35)
	if not is_inside_tree():
		return
	for fa in BattleAI.free_actions(battle):
		if fa.kind == "attack":
			battle.attack(u.id, fa.tech, fa.target)
		else:
			battle.support(u.id, fa.tech, fa.target)
		_sync()
		await _wait(0.45)
	var plan: Dictionary = BattleAI.decide(battle)
	if not plan.is_empty():
		if plan.cell != u.pos:
			battle.move(u.id, plan.cell)
			_sync()
			await _wait(0.4)
		if plan.kind == "attack":
			battle.attack(u.id, plan.tech, plan.target)
		elif plan.kind == "support":
			battle.support(u.id, plan.tech, plan.target)
		elif plan.kind == "item":
			battle.use_item(u.id, plan.tech, plan.target)
		_sync()
		if plan.kind != "advance":
			await _wait(0.55)
	var guard := 0
	while not battle.pending_followups.is_empty() and battle.outcome == "" and guard < 10:
		guard += 1
		var f: Dictionary = battle.pending_followups[0]
		var r: Dictionary = battle.follow_up(f.unit, f.target)
		if not r.ok and not battle.pending_followups.is_empty() and battle.pending_followups[0] == f:
			battle.pending_followups.remove_at(0)
		_sync()
		await _wait(0.4)
	if not is_inside_tree():
		return
	if battle.outcome == "" and battle.active() == u:
		battle.end_turn()
		_sync()
	_busy = false
	_advance_turns()


func _wait(seconds: float) -> void:
	if Game.battle_instant:
		return
	await get_tree().create_timer(seconds * (0.15 if fast else 1.0)).timeout


## Copies new rule-log entries to the on-screen log and floating numbers.
func _sync() -> void:
	while _log_seen < battle.log.size():
		var e: Dictionary = battle.log[_log_seen]
		_log_seen += 1
		var line := BattleText.log_line(battle, e)
		if line != "":
			_append_log(line)
		_popup_for(e)
	board.queue_redraw()
	_refresh()


func _popup_for(e: Dictionary) -> void:
	var t := str(e.type)
	var target: RefCounted = battle.unit(str(e.get("target", e.get("unit", ""))))
	if target == null:
		return
	if t == "attack" or t == "follow_up":
		board.add_popup(target.pos, "-%d" % int(e.damage), Color(1.0, 0.45, 0.35))
	elif t == "support" and int(e.heal) > 0:
		board.add_popup(target.pos, "+%d" % int(e.heal), Color(0.5, 1.0, 0.6))
	elif t == "item":
		board.add_popup(target.pos, "+%d" % int(e.heal), Color(0.5, 1.0, 0.6))
	elif t == "damage":
		board.add_popup(target.pos, "-%d" % int(e.amount), Color(1.0, 0.6, 0.3))
	elif t == "break":
		board.add_popup(target.pos, Loc.t("combat.ui.broken"), Color(1.0, 0.9, 0.3))


func _append_log(line: String) -> void:
	log_lines.append(line)
	if log_lines.size() > MAX_LOG:
		log_lines.remove_at(0)
	_log_label.text = "\n".join(log_lines)
	_scroll_log.call_deferred()


func _scroll_log() -> void:
	await get_tree().process_frame
	if is_instance_valid(_log_scroll):
		_log_scroll.scroll_vertical = int(_log_scroll.get_v_scroll_bar().max_value)


# ---------------------------------------------------------------- modes and overlays

func _set_mode(m: String) -> void:
	mode = m
	if m == "idle":
		_kind = ""
		_tech = ""
		_target = ""
		_hint = ""
	_refresh()
	if m == "idle" or m == "move":
		_report_layout()


func _active() -> RefCounted:
	return battle.active()


func _player_turn() -> bool:
	var u: RefCounted = battle.active()
	return battle.outcome == "" and u != null and u.team == "player" and not u.npc and not _busy


func _refresh() -> void:
	if battle == null or _info == null:
		return
	var u: RefCounted = battle.active()
	_title.text = Loc.t("combat.ui.title", {"name": Loc.t("combat.scenario." + battle.scenario_id)})
	var who := Loc.t("combat.ui.enemy_turn") if (u != null and (u.team != "player" or u.npc)) else ""
	if u != null and who == "":
		who = Loc.t("combat.ui.turn_of", {"name": BattleText.unit_name(battle, u)})
	_round.text = "%s  %s" % [Loc.t("combat.ui.round", {"n": battle.round_no}), who] if Layout.is_portrait() else Loc.t("combat.ui.round", {"n": battle.round_no})
	fast_button.text = Loc.t("combat.ui.fast_on") if fast else Loc.t("combat.ui.fast")
	if fast_button.button_pressed != fast:
		fast_button.set_pressed_no_signal(fast)
	_update_overlays()
	_info.text = _info_text()
	_rebuild_actions()


func _update_overlays() -> void:
	var u: RefCounted = battle.active()
	board.move_cells = {}
	board.target_cells = {}
	board.range_cells = {}
	board.chosen_target = _target if mode == "confirm" else ""
	board.selected_id = _selected
	board.support_mode = _kind == "support" or _kind == "item"
	if _player_turn():
		if mode == "move":
			for c in battle.move_options(u):
				if c != u.pos:
					board.move_cells[c] = true
		elif mode == "target" or mode == "confirm":
			for c in CombatGrid.all_cells():
				if CombatGrid.distance(u.pos, c) <= _range():
					board.range_cells[c] = true
			for id in _valid_targets():
				board.target_cells[battle.unit(id).pos] = true
	board.queue_redraw()


func _range() -> int:
	if _kind == "item":
		return int(battle.content.combat_item("medicine").get("range", 1))
	return int(battle.content.combat_tech(_tech).get("range", 1))


func _valid_targets() -> Array:
	var out: Array = []
	var u: RefCounted = battle.active()
	if u == null:
		return out
	for t in battle.units:
		if not t.alive() or CombatGrid.distance(u.pos, t.pos) > _range():
			continue
		if _kind == "attack" and t.team != u.team:
			out.append(t.id)
		elif _kind == "support" and t.team == u.team:
			out.append(t.id)
		elif _kind == "item" and t.team == u.team and t.hp < t.max_hp:
			out.append(t.id)
	return out


func _info_text() -> String:
	if battle.outcome != "" or battle.active() == null:
		return ""
	var shown: RefCounted = battle.unit(_selected) if _selected != "" else battle.active()
	if shown == null or not shown.alive():
		shown = battle.active()
	var text := BattleText.unit_line(battle, shown) if shown != null else ""
	if mode == "move":
		text += "\n" + Loc.t("combat.ui.pick_cell", {"mp": battle.active().mp})
	elif mode == "tech":
		text += "\n" + Loc.t("combat.ui.pick_tech")
	elif mode == "target":
		text += "\n" + (Loc.t("combat.ui.pick_target") if not _valid_targets().is_empty() else Loc.t("combat.ui.no_target"))
	elif mode == "confirm":
		text = _preview_text()
	elif mode == "followup":
		var f: Dictionary = battle.pending_followups[0] if not battle.pending_followups.is_empty() else {}
		if not f.is_empty():
			text += "\n" + Loc.t("combat.ui.followup", {"name": BattleText.name_of(battle, f.unit), "target": BattleText.name_of(battle, f.target)})
	elif mode == "over":
		text = ""
	return text


func _preview_text() -> String:
	var u: RefCounted = battle.active()
	var tname := BattleText.name_of(battle, _target)
	if _kind == "attack":
		var p: Dictionary = battle.preview_attack(u.id, _tech, _target)
		if not p.ok:
			return ""
		var t: RefCounted = battle.unit(_target)
		var s: String = Loc.t("combat.ui.preview_attack", {"target": tname, "dmg": p.damage, "from": t.hp, "to": p.hp_after, "res": p.resolve_damage})
		if p.kills:
			s += " " + Loc.t("combat.ui.preview_kill")
		elif p.breaks:
			s += " " + Loc.t("combat.ui.preview_break")
		if not p.mods.is_empty():
			s += "\n" + Loc.t("combat.ui.preview_mods", {"list": Loc.t("ui.list_sep").join(p.mods.map(func(m: String) -> String: return Loc.t("combat.mod." + m)))})
		return s
	if _kind == "support":
		var q: Dictionary = battle.preview_support(u.id, _tech, _target)
		if not q.ok:
			return ""
		if int(q.mp) > 0:
			return Loc.t("combat.ui.preview_boost", {"target": tname, "mp": q.mp})
		return Loc.t("combat.ui.preview_support", {"target": tname, "heal": q.heal, "res": q.resolve_gain})
	var item: Dictionary = battle.content.combat_item("medicine")
	var t2: RefCounted = battle.unit(_target)
	return Loc.t("combat.ui.preview_support", {"target": tname, "heal": mini(int(item.heal), t2.max_hp - t2.hp), "res": 0})


# ---------------------------------------------------------------- action buttons

func _rebuild_actions() -> void:
	for c in _action_box.get_children():
		_action_box.remove_child(c)
		c.queue_free()
	action_buttons.clear()
	if battle.outcome != "" or mode == "ai" or mode == "over" or not _player_turn():
		return
	var u: RefCounted = battle.active()
	match mode:
		"idle":
			var grid := GridContainer.new()
			grid.columns = 3
			grid.add_theme_constant_override("h_separation", 6)
			grid.add_theme_constant_override("v_separation", 6)
			grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_action_box.add_child(grid)
			var item_n: int = int(battle.items.get("medicine", 0))
			_add_button(grid, "move", Loc.t("combat.ui.move"), _enter_move, u.mp < 1 or battle.move_options(u).size() <= 1)
			_add_button(grid, "attack", Loc.t("combat.ui.attack"), func() -> void: _enter_tech("attack"), not _can_any("attack"))
			_add_button(grid, "support", Loc.t("combat.ui.support"), func() -> void: _enter_tech("support"), not _can_any("support"))
			_add_button(grid, "item", "%s %d" % [Loc.t("combat.ui.item"), item_n], _enter_item, u.ap < 1 or item_n < 1)
			_add_button(grid, "guard", Loc.t("combat.ui.guard"), _guard, u.ap < 1)
			_add_button(grid, "end", Loc.t("combat.ui.end_turn"), _end_turn, false)
		"move", "target":
			_add_button(_action_box, "back", Loc.t("combat.ui.back"), func() -> void: _set_mode("idle"), false)
		"tech":
			var sv := ScrollContainer.new()
			sv.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
			sv.size_flags_vertical = Control.SIZE_EXPAND_FILL
			sv.custom_minimum_size = Vector2(0, 124)
			_action_box.add_child(sv)
			var col := VBoxContainer.new()
			col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			col.add_theme_constant_override("separation", 6)
			sv.add_child(col)
			for t in _techs_of(_kind):
				var cost: int = int(t.get("cost", 0))
				var label: String = Loc.t("combat.ui.tech_line", {"name": Loc.t(str(t.name_key)), "range": int(t.range), "cost": cost})
				if u.used_once.has(str(t.id)):
					label += "  (%s)" % Loc.t("combat.ui.once_used")
				_add_button(col, "tech:" + str(t.id), label, func() -> void: _pick_tech(str(t.id)), not battle.can_use(u, str(t.id)))
			_add_button(col, "back", Loc.t("combat.ui.back"), func() -> void: _set_mode("idle"), false)
		"confirm":
			var row := HBoxContainer.new()
			row.add_theme_constant_override("separation", 8)
			_action_box.add_child(row)
			_add_button(row, "confirm", Loc.t("combat.ui.confirm"), _confirm, false)
			_add_button(row, "cancel", Loc.t("combat.ui.cancel"), func() -> void: _set_mode("target"), false)
		"followup":
			var row2 := HBoxContainer.new()
			row2.add_theme_constant_override("separation", 8)
			_action_box.add_child(row2)
			_add_button(row2, "strike", Loc.t("combat.ui.attack"), _strike, false)
			_add_button(row2, "skip", Loc.t("combat.ui.skip"), _skip_follow_up, false)


func _add_button(parent: Node, id: String, text: String, cb: Callable, disabled: bool) -> Button:
	var b := UiKit.make_button(Vector2(100, 56))
	b.text = text
	b.disabled = disabled
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.clip_text = true
	b.pressed.connect(cb)
	parent.add_child(b)
	action_buttons[id] = b
	return b


## Is any technique of this kind usable right now (free bond abilities work even with no action left)?
func _can_any(kind: String) -> bool:
	var u: RefCounted = battle.active()
	for t in _techs_of(kind):
		if battle.can_use(u, str(t.id)):
			return true
	return false


func _techs_of(kind: String) -> Array:
	var out: Array = []
	var u: RefCounted = battle.active()
	for id in battle.technique_ids(u):
		var t: Dictionary = battle.content.combat_tech(str(id))
		if not t.is_empty() and t.kind == kind:
			out.append(t)
	return out


func _enter_move() -> void:
	_set_mode("move")


func _enter_tech(kind: String) -> void:
	_kind = kind
	_set_mode("tech")


func _enter_item() -> void:
	_kind = "item"
	_tech = ""
	_set_mode("target")


func _pick_tech(id: String) -> void:
	_tech = id
	_set_mode("target")


func _guard() -> void:
	battle.guard(battle.active().id)
	_after_action()


func _end_turn() -> void:
	if not _player_turn():
		return
	battle.end_turn()
	_sync()
	_advance_turns()


func _confirm() -> void:
	var u: RefCounted = battle.active()
	var r: Dictionary = {}
	if _kind == "attack":
		r = battle.attack(u.id, _tech, _target)
	elif _kind == "support":
		r = battle.support(u.id, _tech, _target)
	elif _kind == "item":
		r = battle.use_item(u.id, "medicine", _target)
	_after_action()


func _strike() -> void:
	if battle.pending_followups.is_empty():
		_set_mode("idle")
		return
	var f: Dictionary = battle.pending_followups[0]
	battle.follow_up(f.unit, f.target)
	_after_action()


func _skip_follow_up() -> void:
	battle.pending_followups.clear()
	_set_mode("idle")


func _after_action() -> void:
	_sync()
	Game.save_battle_progress()
	if battle.outcome != "":
		_advance_turns()
		return
	if not battle.pending_followups.is_empty():
		_set_mode("followup")
	else:
		_set_mode("idle")


## Taps on the board. Works the same for finger and mouse; hovering is never needed.
func _on_cell(cell: Vector2i) -> void:
	if battle.outcome != "" or _busy:
		return
	var occupant: RefCounted = battle.unit_at(cell)
	if _player_turn() and mode == "move":
		var u: RefCounted = battle.active()
		if occupant == null and battle.move(u.id, cell).ok:
			_sync()
			Game.save_battle_progress()
			_set_mode("idle")
			return
	if _player_turn() and (mode == "target" or mode == "confirm") and occupant != null and _valid_targets().has(occupant.id):
		_target = occupant.id
		_selected = occupant.id
		_set_mode("confirm")
		return
	if occupant != null:
		_selected = occupant.id
	elif mode == "idle":
		_selected = battle.active().id if battle.active() != null else ""
	_refresh()


# ---------------------------------------------------------------- end of battle

func _finish() -> void:
	if result_overlay != null:
		return
	mode = "over"
	_rebuild_actions()
	var parts := OverlayUtil.make(440.0, 14)
	result_overlay = parts[0]
	var box: VBoxContainer = parts[1]
	var won: bool = battle.outcome == "victory"
	var head := UiKit.make_label(44, HORIZONTAL_ALIGNMENT_CENTER)
	head.text = Loc.t("combat.ui.result." + battle.outcome)
	head.modulate = Color("e3c27a") if won else Color("e8a090")
	var why := UiKit.make_label(FONT, HORIZONTAL_ALIGNMENT_CENTER)
	why.text = Loc.t("combat.outcome." + battle.outcome_reason)
	var rounds := UiKit.make_label(FONT, HORIZONTAL_ALIGNMENT_CENTER)
	rounds.text = Loc.t("combat.ui.result_rounds", {"n": battle.round_no})
	var res: Dictionary = Game.apply_battle_result()
	var lines: Array = res.deltas.map(func(d: Dictionary) -> String: return DeltaText.delta_line(d))
	if not res.flags.is_empty():
		lines.append(Loc.t("combat.ui.flag"))
	var spoils := UiKit.make_label(FONT, HORIZONTAL_ALIGNMENT_CENTER)
	spoils.text = "%s: %s" % [Loc.t("combat.ui.rewards"), Loc.t("ui.list_sep").join(lines)] if not lines.is_empty() else ""
	spoils.visible = not lines.is_empty()
	continue_button = UiKit.make_button(Vector2(260, 64))
	continue_button.text = Loc.t("combat.ui.continue")
	continue_button.pressed.connect(_continue)
	for n in [head, why, rounds, spoils, continue_button]:
		box.add_child(n)
	add_child(result_overlay)
	continue_button.grab_focus()
	print("BATTLE_OVER result=%s reason=%s rounds=%d hash=%s" % [battle.outcome, battle.outcome_reason, battle.round_no, battle.state_hash()])
	_report_layout()


func _continue() -> void:
	Router.goto(Game.finish_battle())


# ---------------------------------------------------------------- test and diagnostics support

func tap_cell(cell: Vector2i) -> void:
	_on_cell(cell)


func audit_layout() -> Array[String]:
	return UiKit.audit(self)


## Prints where the main controls are (logical pixels) and the layout audit, after the layout settles.
func _report_layout() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	if not is_inside_tree() or battle == null:
		return
	var parts: Array[String] = []
	for k in ["move", "attack", "guard", "end", "confirm", "back"]:
		var c: Control = action_buttons.get(k)
		if c != null and c.is_visible_in_tree():
			var p := c.get_global_rect().get_center()
			parts.append("act_%s=%d,%d" % [k, int(p.x), int(p.y)])
	if fast_button.is_visible_in_tree():
		var fp := fast_button.get_global_rect().get_center()
		parts.append("ff=%d,%d" % [int(fp.x), int(fp.y)])
	var u: RefCounted = battle.active()
	if u != null and mode == "move":
		var best := Vector2i(-1, -1)
		for c in battle.move_options(u):
			if best.x < 0 or c.y < best.y or (c.y == best.y and c.x < best.x):
				best = c
		if best.x >= 0 and best != u.pos:
			var mp: Vector2 = board.get_global_rect().position + board.cell_center(best)
			parts.append("move_to=%d,%d" % [int(mp.x), int(mp.y)])
	if continue_button != null and continue_button.is_visible_in_tree():
		var cp := continue_button.get_global_rect().get_center()
		parts.append("continue=%d,%d" % [int(cp.x), int(cp.y)])
	var vp := get_viewport_rect().size
	print("UI_POS vp=%d,%d %s" % [int(vp.x), int(vp.y), " ".join(parts)])
	var problems: Array[String] = audit_layout()
	print("LAYOUT_AUDIT size=%dx%d problems=%d" % [int(vp.x), int(vp.y), problems.size()])
	for p in problems:
		print("  audit: ", p)
