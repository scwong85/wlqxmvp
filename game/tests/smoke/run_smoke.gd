extends Node
## Headless play-through of the real UI. Drives buttons the way a player would:
## boot -> title -> cultivation screen -> select/confirm activities -> story pop-ups -> end of week,
## plus language toggle, layout audit, save/load, and corrupt-save handling.
## Run: godot --headless --path game res://tests/smoke/run_smoke.tscn   (prints SMOKE_OK / SMOKE_FAIL)

const UiKit = preload("res://scripts/ui/ui_kit.gd")

var _fails: Array[String] = []
var _recruit_log: Array = []


func _check(cond: bool, label: String) -> void:
	if not cond:
		_fails.append(label)
		print("  FAIL: ", label)
	else:
		print("  ok: ", label)


func _frames(n: int = 3) -> void:
	for i in n:
		await get_tree().process_frame


func _scene() -> Node:
	return get_tree().current_scene


func _ready() -> void:
	# Isolated save folder so the test never touches real saves.
	Saves.dir = "user://smoke_saves/"
	DirAccess.make_dir_recursive_absolute(Saves.dir)
	_wipe_saves()
	get_tree().current_scene = null  # we stay alive under root; Router no longer frees us
	await _run()
	_wipe_saves()
	print("SMOKE_OK" if _fails.is_empty() else "SMOKE_FAIL")
	get_tree().quit(0 if _fails.is_empty() else 1)


func _wipe_saves() -> void:
	for f in DirAccess.get_files_at(Saves.dir):
		DirAccess.remove_absolute(Saves.dir.path_join(f))


func _write_garbage(slot: String) -> void:
	for suffix in ["", ".bak"]:
		var f := FileAccess.open(Saves.dir.path_join(slot) + suffix, FileAccess.WRITE)
		f.store_string("{ definitely not a save")
		f.close()


## Selects an activity and presses confirm, like a player.
func _do(screen: Node, activity_id: String, option_id: String = "") -> void:
	screen.select_activity(activity_id)
	screen.confirm_button.pressed.emit()
	await _frames(1)
	if screen.choice_panel != null:  # activities with approaches ask first
		var oid: String = option_id if option_id != "" else screen.option_buttons.keys()[0]
		screen.option_buttons[oid].pressed.emit()
		await _frames(1)


## Presses Continue on any story pop-up. Returns the in-game days on which pop-ups appeared.
func _dismiss_events(screen: Node) -> Array:
	var seen: Array = []
	var guard := 0
	while (screen.event_panel != null or screen.recruit_panel != null) and guard < 8:
		guard += 1
		if screen.recruit_panel != null:  # invitation prompt: accept when offered, otherwise "maybe later"
			if screen.recruit_accept_button != null:
				_recruit_log.append("accept")
				screen.recruit_accept_button.pressed.emit()
			else:
				_recruit_log.append("decline")
				screen.recruit_decline_button.pressed.emit()
		else:
			seen.append(Game.state.calendar.day)
			screen.event_continue_button.pressed.emit()
		await _frames(1)
	return seen


func _run() -> void:
	Router.goto("boot")
	await _frames(4)
	_check(Router.current_key == "title", "boot routes to title")
	var title := _scene()
	_check(title.load_button.disabled, "title: load disabled with no saves")
	_check(title.start_button.text == "开始游戏", "title: Mandarin by default")

	# --- New game opens the cultivation screen ---
	title.start_button.pressed.emit()
	await _frames(4)
	_check(Router.current_key == "cultivation", "start opens the cultivation screen")
	Game.state.run_seed = 5  # fixed seed so outcomes are reproducible
	var cult := _scene()
	_check(cult.cards.size() == 12, "screen: all 12 activities are listed")
	_check(cult.selected_id == "training", "screen: first available activity is preselected")
	_check(cult.info_label.text.contains(Loc.t("activity.training.desc")), "screen: selected activity shows its description")
	_check(not cult.confirm_button.disabled, "screen: confirm enabled for an available activity")
	var problems: Array[String] = cult.audit_layout()
	for p in problems:
		print("    audit: ", p)
	_check(problems.is_empty(), "layout: no small text, short touch targets or off-screen controls")

	# --- Blocked activities explain themselves ---
	cult.select_activity("cooking")
	_check(cult.confirm_button.disabled, "blocked: cooking is not confirmable without food")
	_check(cult.info_label.text.contains(Loc.t("activity.blocked.resource")), "blocked: reason is shown as text")
	cult.select_activity("mining")
	_check(cult.confirm_button.disabled and cult.info_label.text.contains(Loc.t("activity.blocked.day_gate")), "blocked: mining is gated to day 2")

	# --- Approach chooser (M6) ---
	cult.select_activity("technique_practice")
	cult.confirm_button.pressed.emit()
	await _frames(2)
	_check(cult.choice_panel != null and cult.option_buttons.size() == 3, "choice: confirming an activity with approaches opens the chooser")
	var layout_problems: Array[String] = cult.audit_layout()
	_check(layout_problems.is_empty(), "choice: chooser fits the screen with readable text %s" % str(layout_problems.slice(0, 2)))
	cult.choice_cancel_button.pressed.emit()
	await _frames(2)
	_check(cult.choice_panel == null and Game.state.calendar.slot == 1 and Game.state.player.stamina == 20, "choice: cancel changes nothing")
	cult.select_activity("rest")
	cult.confirm_button.pressed.emit()
	await _frames(1)
	_check(cult.choice_panel == null and Game.state.calendar.slot == 2, "choice: activities without approaches act immediately")
	Game.state.calendar.slot = 1
	Game.state.player.stamina = 20

	# --- Perform an activity ---
	var power_before: int = Game.state.player.get_attr("power")
	await _do(cult, "training", "heavy_strike")
	_check(Game.state.calendar.slot == 2, "action: training uses a slot")
	_check(Game.state.player.stamina == 15, "action: training costs 5 stamina")
	_check(Game.state.player.get_attr("power") > power_before, "action: training raises power")
	_check(cult.info_label.text.begins_with(Loc.t("cult.result.success")) or cult.info_label.text.begins_with(Loc.t("cult.result.partial")), "action: result panel shows the outcome")
	_check(Saves.slot_exists(Saves.AUTO), "action: autosave written")
	cult.select_activity("rest")
	_check(not cult.info_label.text.begins_with(Loc.t("cult.result.success")), "action: choosing another card clears the result")

	# --- Choose a path ---
	_check(cult.path_buttons.size() == 3, "path: three paths offered before choosing")
	cult.path_buttons["xuan_fist"].pressed.emit()
	await _frames(2)
	_check(Game.state.player.path_id == "xuan_fist", "path: choosing sets the path")
	_check(cult.path_buttons.is_empty(), "path: the choice buttons disappear once chosen")

	# --- Companion panel (M7) ---
	cult.party_button.pressed.emit()
	await _frames(2)
	_check(cult.party_panel != null and cult.party_buttons.size() == 3, "party: the companion panel lists the three companions")
	problems = cult.audit_layout()
	_check(problems.is_empty(), "party: panel fits the screen with readable text %s" % str(problems.slice(0, 2)))
	_check(cult.party_buttons["shen_qinghe"].is_empty() and Game.state.relationships.get_status("shen_qinghe") == "available", "party: nobody can be invited before conditions are met")
	cult.party_close_button.pressed.emit()
	await _frames(2)
	_check(cult.party_panel == null, "party: close works")
	# Give Shen the bond and insight she needs so the day-3 invitation can be accepted.
	Game.state.relationships.add_score("shen_qinghe", 6)
	Game.state.player.attributes["insight"] = 6

	# --- Play the rest of the week with rests, acknowledging story pop-ups ---
	var popup_days: Array = []
	var guard := 0
	while not Game.state.calendar.finished and guard < 20:
		guard += 1
		await _do(cult, "rest")
		popup_days.append_array(await _dismiss_events(cult))
	_check(Game.state.calendar.finished, "week: the seven days end")
	_check(popup_days == [3, 6, 7], "week: story pop-ups appeared on days 3, 6 and 7 (got %s)" % str(popup_days))
	_check(Game.state.calendar.events_fired == ["day3_recruit", "day6_prepare", "day7_crisis"], "week: hooks acknowledged and recorded")
	_check(_recruit_log == ["accept"] and Game.state.relationships.active == "shen_qinghe", "recruit: the day-3 invitation was accepted and Shen is the active companion (%s)" % str(_recruit_log))
	cult.party_button.pressed.emit()
	await _frames(2)
	_check(cult.party_buttons["shen_qinghe"].has("dismiss") and not cult.party_buttons["shen_qinghe"].has("activate"), "party: the active companion can be dismissed but not re-activated")
	_check(cult.party_buttons["lu_chenzhou"].is_empty(), "party: a companion whose conditions are unmet shows no invite button")
	cult.party_buttons["shen_qinghe"]["dismiss"].pressed.emit()
	await _frames(2)
	_check(Game.state.relationships.get_status("shen_qinghe") == "left" and cult.party_buttons["shen_qinghe"].has("recruit"), "party: dismissing lets her be invited again")
	cult.party_buttons["shen_qinghe"]["recruit"].pressed.emit()
	await _frames(2)
	_check(Game.state.relationships.active == "shen_qinghe", "party: re-inviting works from the panel")
	cult.party_close_button.pressed.emit()
	await _frames(2)
	_check(cult.confirm_button.disabled, "week: nothing can be confirmed after day 7")
	problems = cult.audit_layout()
	_check(problems.is_empty(), "layout: still clean at the end of the week")

	# --- Save, restart, load ---
	cult.save_button.pressed.emit()
	await _frames(1)
	_check(Saves.slot_exists(Saves.MANUAL) and cult.status_label.text == Loc.t("cult.saved"), "save: manual save confirmed on screen")
	cult.menu_button.pressed.emit()
	await _frames(3)
	title = _scene()
	_check(Router.current_key == "title" and not title.load_button.disabled, "load: title offers Load once a save exists")
	Game.state = null
	title.load_button.pressed.emit()
	await _frames(4)
	_check(Router.current_key == "cultivation", "load: opens the cultivation screen")
	_check(Game.state.calendar.finished and Game.state.player.path_id == "xuan_fist", "load: week state and path restored")
	_check(Game.state.run_seed == 5, "load: run seed restored")
	cult = _scene()
	_check(cult.confirm_button.disabled, "load: finished week stays finished")

	# --- Language toggle on the real screen ---
	Loc.set_locale("en")
	_check(cult._day_label.text == "Day 7 of 7", "language: cultivation screen follows the language toggle")
	Loc.set_locale("zh_CN")

	# --- Exploration (M8) ---
	Saves.delete_slot(Saves.MANUAL)
	Game.new_game(5)
	Game.state.calendar.day = 2
	preload("res://scripts/domain/relationship_rules.gd").refresh(Game.state, Content)  # day 2 normally arrives through a slot
	Router.goto("cultivation")
	await _frames(4)
	cult = _scene()
	_check(not cult.explore_button.disabled and cult.explore_button.text.contains(Loc.t("exploration.bamboo_pass")), "explore: the training screen offers Bamboo Pass from day 2")
	cult.explore_button.pressed.emit()
	await _frames(4)
	_check(Router.current_key == "exploration" and Game.state.exploration.active, "explore: pressing it opens the exploration screen")
	var ex := _scene()
	_check(ex.choice_buttons.size() == 3 and ex.choice_buttons["ridge"].disabled and not ex.choice_buttons["old_road"].disabled, "explore: three paths, the ridge is gated by body")
	_check(ex.choice_buttons["ridge"].text.contains(Loc.t("attr.body")), "explore: the gate reason is shown as text")
	_check(ex.text_label.text == Loc.t("exploration.bamboo_pass.start.text"), "explore: the story text is shown from data")
	problems = ex.audit_layout()
	_check(problems.is_empty(), "explore: layout is clean with readable text %s" % str(problems.slice(0, 2)))
	ex.choice_buttons["old_road"].pressed.emit()
	await _frames(2)
	ex.choice_buttons["greet"].pressed.emit()
	await _frames(2)
	_check(ex.recruit_panel != null and ex.recruit_accept_button == null, "explore: meeting the courier shows an invitation prompt (he is not ready yet)")
	ex.choice_buttons["travel_on"].pressed.emit()
	await _frames(1)
	_check(Game.state.exploration.node == "courier", "explore: choices are blocked while the prompt is open")
	ex.recruit_decline_button.pressed.emit()
	await _frames(2)
	_check(ex.recruit_panel == null and Game.state.exploration.pending_recruit == "" and Game.state.relationships.has_flag("declined_lu_chenzhou"), "explore: declining closes the prompt and is remembered")
	ex.choice_buttons["travel_on"].pressed.emit()
	await _frames(2)
	ex.choice_buttons["pass_through"].pressed.emit()
	await _frames(2)
	_check(ex.continue_button != null and ex.result_label.text.contains(Loc.t("explore.ended")), "explore: the ending shows feedback and a return button")
	_check(Game.state.calendar.slot == 2 and Game.state.exploration.completed == ["bamboo_pass"], "explore: finishing used one slot and is recorded")
	ex.continue_button.pressed.emit()
	await _frames(4)
	cult = _scene()
	_check(Router.current_key == "cultivation" and cult.explore_button.disabled, "explore: back on the training screen the route is marked done")

	# Resume after reload: start again on a new run, choose once, drop the state, load, land on the same node.
	Game.new_game(5)
	Game.state.calendar.day = 2
	preload("res://scripts/domain/relationship_rules.gd").refresh(Game.state, Content)  # day 2 normally arrives through a slot
	Game.start_exploration("bamboo_pass")
	Game.explore_choose("stream")
	Game.state = null
	_check(Game.load_latest().ok and Game.state.exploration.active, "explore: loading a mid-route save restores the route")
	Router.goto("cultivation")
	await _frames(5)
	_check(Router.current_key == "exploration" and _scene().text_label.text == Loc.t("exploration.bamboo_pass.stream.text"), "explore: the training screen sends you back to the saved node")
	Game.state.exploration.active = false
	Game.autosave()
	Router.goto("cultivation")
	await _frames(4)
	cult = _scene()

	# --- Portrait layout (M-portrait) ---
	var win := get_window()
	win.size = Vector2i(390, 844)  # a phone held upright
	await _frames(3)
	print("PORTRAIT_PROBE window=", win.size, " mode=", Layout.mode, " viewport=", get_viewport().get_visible_rect().size)
	_check(Layout.is_portrait() and Layout.mode_for(Vector2(390, 844)) == "portrait" and Layout.mode_for(Vector2(844, 390)) == "landscape" and Layout.mode_for(Vector2(800, 800)) == "landscape", "portrait: the layout follows the window shape (tall = portrait, square or wide = landscape)")
	Game.new_game(5)
	Router.goto("title")
	await _frames(4)
	title = _scene()
	problems = UiKit.audit(title)
	_check(problems.is_empty() and title.start_button.size_flags_horizontal == Control.SIZE_FILL, "portrait: title screen fits with full-width buttons %s" % str(problems.slice(0, 2)))
	Router.goto("settings")
	await _frames(4)
	problems = UiKit.audit(_scene())
	_check(problems.is_empty(), "portrait: settings fits %s" % str(problems.slice(0, 2)))
	Router.goto("cultivation")
	await _frames(5)
	cult = _scene()
	_check(cult.current_tab == "hero" and cult._tab_bar.visible and cult._panels["hero"].visible and not cult._panels["activities"].visible, "portrait: a new game starts on the hero tab (path choice first)")
	problems = cult.audit_layout()
	_check(problems.is_empty(), "portrait: hero tab fits %s" % str(problems.slice(0, 3)))
	cult.tab_buttons["activities"].pressed.emit()
	await _frames(2)
	_check(cult._panels["activities"].visible and not cult._panels["hero"].visible and not cult._panels["stats"].visible, "portrait: choosing a tab shows only that panel")
	problems = cult.audit_layout()
	_check(problems.is_empty(), "portrait: activities tab fits %s" % str(problems.slice(0, 3)))
	_check(cult.confirm_button.is_visible_in_tree() and cult.explore_button.is_visible_in_tree(), "portrait: Execute and Explore stay on screen")
	cult.tab_buttons["stats"].pressed.emit()
	await _frames(2)
	problems = cult.audit_layout()
	_check(problems.is_empty() and cult._panels["stats"].visible, "portrait: stats tab fits %s" % str(problems.slice(0, 3)))
	cult.tab_buttons["activities"].pressed.emit()
	await _frames(2)
	cult.select_activity("social_visit")
	Game.state.calendar.day = 2
	cult.confirm_button.pressed.emit()
	await _frames(3)
	problems = cult.audit_layout()
	_check(cult.choice_panel != null and cult.option_buttons.size() == 4 and problems.is_empty(), "portrait: the four-approach chooser fits %s" % str(problems.slice(0, 3)))
	cult.choice_cancel_button.pressed.emit()
	await _frames(2)
	cult.party_button.pressed.emit()
	await _frames(3)
	problems = cult.audit_layout()
	_check(cult.party_panel != null and problems.is_empty(), "portrait: companion panel fits %s" % str(problems.slice(0, 3)))
	cult.party_close_button.pressed.emit()
	await _frames(2)
	# English strings are longer: every portrait view must still fit.
	Loc.set_locale("en")
	await _frames(2)
	for tab in ["hero", "activities", "stats"]:
		cult.tab_buttons[tab].pressed.emit()
		await _frames(2)
		problems = cult.audit_layout()
		_check(problems.is_empty(), "portrait en: %s tab fits %s" % [tab, str(problems.slice(0, 3))])
	cult.tab_buttons["activities"].pressed.emit()
	await _frames(2)
	for act in ["social_visit", "technique_practice"]:
		cult.select_activity(act)
		cult.confirm_button.pressed.emit()
		await _frames(3)
		problems = cult.audit_layout()
		_check(cult.choice_panel != null and problems.is_empty(), "portrait en: %s chooser fits %s" % [act, str(problems.slice(0, 3))])
		cult.choice_cancel_button.pressed.emit()
		await _frames(2)
	cult.party_button.pressed.emit()
	await _frames(3)
	problems = cult.audit_layout()
	_check(problems.is_empty(), "portrait en: companion panel fits %s" % str(problems.slice(0, 3)))
	cult.party_close_button.pressed.emit()
	await _frames(2)
	Loc.set_locale("zh_CN")
	cult.select_activity("social_visit")
	await _frames(2)
	# Rotating with a chooser open closes it; the layout flips and back again without losing state.
	cult.confirm_button.pressed.emit()
	await _frames(2)
	win.size = Vector2i(1280, 720)
	await _frames(4)
	_check(not Layout.is_portrait() and cult.choice_panel == null and not cult._tab_bar.visible and cult._panels["hero"].visible and cult._panels["stats"].visible, "rotate: landscape shows all three panels, no tab bar, and closed the open chooser")
	_check(cult.selected_id == "social_visit", "rotate: the selected activity survives the rotation")
	problems = cult.audit_layout()
	_check(problems.is_empty(), "rotate: landscape still fits %s" % str(problems.slice(0, 3)))
	win.size = Vector2i(390, 844)
	await _frames(4)
	_check(Layout.is_portrait() and cult.selected_id == "social_visit" and cult._tab_bar.visible, "rotate: back to portrait restores the tab layout")
	# Exploration in portrait.
	Game.state.calendar.day = 2
	preload("res://scripts/domain/relationship_rules.gd").refresh(Game.state, Content)
	Game.state.exploration.active = false
	Game.start_exploration("bamboo_pass")
	Router.goto("exploration")
	await _frames(5)
	ex = _scene()
	problems = ex.audit_layout()
	_check(problems.is_empty() and ex._body.vertical, "portrait: exploration fits with story above choices %s" % str(problems.slice(0, 3)))
	ex.choice_buttons["old_road"].pressed.emit()
	await _frames(2)
	ex.choice_buttons["greet"].pressed.emit()
	await _frames(3)
	problems = ex.audit_layout()
	_check(ex.recruit_panel != null and problems.is_empty(), "portrait: the invitation prompt fits %s" % str(problems.slice(0, 3)))
	ex.recruit_decline_button.pressed.emit()
	await _frames(2)
	Game.state.exploration.active = false
	Game.autosave()
	win.size = Vector2i(1280, 720)
	await _frames(4)
	Router.goto("cultivation")
	await _frames(4)
	cult = _scene()

	# --- Settings keeps working ---
	cult.menu_button.pressed.emit()
	await _frames(3)
	_scene().settings_button.pressed.emit()
	await _frames(3)
	var settings := _scene()
	_check(Router.current_key == "settings", "settings: opens")
	settings.language_buttons["en"].pressed.emit()
	await _frames(1)
	_check(Loc.locale == "en" and Saves.load_settings().get("locale") == "en", "settings: language switches and persists")
	settings.language_buttons["zh_CN"].pressed.emit()
	settings.back_button.pressed.emit()
	await _frames(3)

	# --- Corrupt saves are explained, never crash ---
	_write_garbage(Saves.MANUAL)
	_write_garbage(Saves.AUTO)
	Router.goto("title")
	await _frames(3)
	title = _scene()
	_check(title.load_note.text == Loc.t("save.error.corrupt"), "corrupt: the title explains the problem")
	title.load_button.pressed.emit()
	await _frames(3)
	_check(Router.current_key == "title" and not title.load_note.text.begins_with("["), "corrupt: failed load stays on the title with a real message")
