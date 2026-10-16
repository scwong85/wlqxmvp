extends Node
## Headless play-through of the real UI. Drives buttons the way a player would:
## boot -> title -> cultivation screen -> select/confirm activities -> story pop-ups -> end of week,
## plus language toggle, layout audit, save/load, and corrupt-save handling.
## Run: godot --headless --path game res://tests/smoke/run_smoke.tscn   (prints SMOKE_OK / SMOKE_FAIL)

const UiKit = preload("res://scripts/ui/ui_kit.gd")
const BattleAI = preload("res://scripts/domain/combat/battle_ai.gd")
const EventRules = preload("res://scripts/domain/event_rules.gd")

var _fails: Array[String] = []
var _recruit_log: Array = []
var _story_problems: Array = []
var _reached_end := false


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
	if not _reached_end:
		_fails.append("the smoke run stopped early (script error)")
		print("  FAIL: the smoke run stopped early (script error)")
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
	if is_instance_valid(screen) and screen.choice_panel != null:  # activities with approaches ask first
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
			seen.append(Game.state.calendar.week)
			screen.event_continue_button.pressed.emit()
		await _frames(1)
	return seen


## Story dialogues are covered by their own checks; other tests start from a run whose story scenes are already seen.
func _quiet() -> void:
	for h in Content.day_hooks:
		EventRules.mark_fired(Game.state, str(h.id))


## Plays dialogue/battle scenes with the real buttons until the game is back on a normal screen (or at the ending).
func _play_story(log: Array) -> void:
	var guard := 0
	while ["dialogue", "battle", "ending"].has(Router.current_key) and guard < 40:
		guard += 1
		var sc := _scene()
		if Router.current_key == "ending":
			return
		if Router.current_key == "dialogue":
			var did: String = Game.state.story.dialogue.get("id", "")
			if log.is_empty() or log[-1] != did:
				log.append(did)
			var problems: Array[String] = sc.audit_layout()
			if not problems.is_empty():
				_story_problems.append("%s: %s" % [did, str(problems.slice(0, 2))])
			if sc.continue_button != null:
				sc.continue_button.pressed.emit()
			else:
				var pick := ""
				for cid in sc.choice_buttons:
					if not sc.choice_buttons[cid].disabled and (pick == "" or cid == "together" or cid == "later"):
						pick = cid
				sc.choice_buttons[pick].pressed.emit()
		elif Game.battle != null:
			log.append("battle:" + str(Game.battle_ctx.scenario))
			Game.battle.outcome = "victory"
			Router.goto(Game.finish_battle())
		await _frames(3)


func _run() -> void:
	Saves.update_settings({"animations": false, "minigames": false})   # clips and minigames are tested separately below
	Router.goto("boot")
	await _frames(4)
	_check(Router.current_key == "title", "boot routes to title")
	var title := _scene()
	_check(title.load_button.disabled, "title: load disabled with no saves")
	_check(title.start_button.text == "开始游戏", "title: Mandarin by default")

	# --- New game opens the cultivation screen ---
	title.start_button.pressed.emit()
	await _frames(4)
	_check(Router.current_key == "hero_creation", "start opens hero creation")
	var creation := _scene()
	var create_problems: Array[String] = creation.audit_layout()
	_check(create_problems.is_empty(), "hero creation: layout audit is clean %s" % str(create_problems.slice(0, 2)))
	creation.name_edit.text = "云澈"
	creation.gender_buttons.f.pressed.emit()
	creation.confirm_button.pressed.emit()
	await _frames(4)
	_check(Router.current_key == "dialogue", "confirming opens the day-1 intro dialogue")
	_check(Game.state.player.hero_name == "云澈" and Game.state.player.look.gender == "f", "the chosen name and look are in the run")
	Game.state.run_seed = 5  # fixed seed so outcomes are reproducible
	var story_log: Array = []
	var intro := _scene()
	_check(intro.continue_button != null and intro.text_label.text == Loc.t("story.day1_intro.n1"), "dialogue: the first node is shown with a Continue button")
	await _play_story(story_log)
	_check(Router.current_key == "cultivation" and story_log == ["day1_intro", "day2_path"], "dialogue: the intro and the path choice (\"later\") come first, then the cultivation screen")
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
	_check(cult.party_panel != null and cult.party_buttons.size() == Content.companions.size(), "party: the companion panel lists every companion")
	problems = cult.audit_layout()
	_check(problems.is_empty(), "party: panel fits the screen with readable text %s" % str(problems.slice(0, 2)))
	_check(cult.party_buttons["shen_qinghe"].is_empty() and Game.state.relationships.get_status("shen_qinghe") == "available", "party: nobody can be invited before conditions are met")
	cult.party_close_button.pressed.emit()
	await _frames(2)
	_check(cult.party_panel == null, "party: close works")
	# Give Shen the bond and insight she needs so the day-3 invitation can be accepted.
	Game.state.relationships.add_score("shen_qinghe", 6)
	Game.state.player.attributes["insight"] = 6

	# --- Play the week; story scenes are played with the real buttons ---
	var popup_days: Array = []
	var guard := 0
	while Game.state.calendar.slots_used() < 9 and guard < 20:
		guard += 1
		cult = _scene()
		await _do(cult, "rest")
		await _frames(2)
		await _play_story(story_log)
		cult = _scene()
		popup_days.append_array(await _dismiss_events(cult))
	cult = _scene()
	_check(Router.current_key == "cultivation" and Game.state.calendar.week == 5 and Game.state.calendar.slot == 2, "month: the last slot of the opening month is reached")
	_check(popup_days == [2], "month: only the week-2 invitation is a pop-up (got %s)" % str(popup_days))
	_check(story_log == ["day1_intro", "day2_path", "day4_battle", "battle:rescue_battle", "day4_win", "day5_faction", "day6_prepare", "day7_crisis"], "month: the story scenes came in order (%s)" % str(story_log))
	_check(Game.state.calendar.events_fired == ["day1_intro", "day2_path", "day3_recruit", "day4_battle", "day5_faction", "day6_prepare", "day7_crisis"], "week: hooks acknowledged and recorded (%s)" % str(Game.state.calendar.events_fired))
	_check(Game.state.relationships.has_flag("bandits_beaten") or Game.state.relationships.has_flag("villager_saved"), "week: the rescue result is remembered")
	_check(_story_problems.is_empty(), "layout: every dialogue screen is clean %s" % str(_story_problems.slice(0, 2)))
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
	problems = cult.audit_layout()
	_check(problems.is_empty(), "layout: still clean on the last day")

	# --- The last slot of the opening month: the climax fight, and the story goes on ---
	await _do(cult, "rest")
	await _frames(3)
	_check(Router.current_key == "dialogue" and Game.state.story.dialogue.id == "crisis_final", "crisis: using the opening month's last slot opens the climax dialogue")
	await _play_story(story_log)
	_check(Router.current_key == "cultivation" and story_log.has("battle:final_crisis") and Game.state.story.ending == "" and Game.state.calendar.week == 6, "month: after the climax the game goes on into month 2")
	_check(Game.state.relationships.has_flag("bandits_defeated"), "month: the climax result is remembered")
	cult = _scene()
	# --- Three years later: the last slot of week 180 ends the campaign with an ending ---
	Game.state.calendar.week = 180
	Game.state.calendar.slot = 2
	cult.call("_refresh_all")
	await _do(cult, "rest")
	await _frames(4)
	_check(Router.current_key == "ending" and Game.state.calendar.finished and Game.state.story.ending != "", "ending: using the very last slot opens the ending screen (%s)" % Game.state.story.ending)
	var end_scene := _scene()
	_check(end_scene.title_label.text == Loc.t("ending.%s.title" % Game.state.story.ending) and Saves.slot_exists(Saves.AUTO), "ending: its title is shown and the run is saved")
	problems = end_scene.audit_layout()
	_check(problems.is_empty(), "ending: layout is clean %s" % str(problems.slice(0, 2)))
	var ending_id: String = Game.state.story.ending

	# --- Closing and loading a finished run returns to its ending; the ending leads to the title and to a new run ---
	end_scene.title_button.pressed.emit()
	await _frames(3)
	title = _scene()
	_check(Router.current_key == "title" and not title.load_button.disabled, "load: title offers Load once a save exists")
	Game.state = null
	title.load_button.pressed.emit()
	await _frames(5)
	_check(Router.current_key == "ending" and Game.state.story.ending == ending_id, "load: a finished run opens its ending again")
	_check(Game.state.player.path_id == "xuan_fist" and Game.state.run_seed == 5, "load: path and seed restored")
	Loc.set_locale("en")
	await _frames(2)
	_check(_scene().new_run_button.text == "New journey" or _scene().new_run_button.text == Loc.t("ending.new_run"), "language: the ending follows the language toggle")
	Loc.set_locale("zh_CN")
	_scene().new_run_button.pressed.emit()
	await _frames(5)
	_check(Router.current_key == "dialogue" and Game.state.story.ending == "" and Game.state.calendar.week == 1 and Game.state.player.path_id == "", "ending: starting again clears the finished run and opens the day-1 intro")

	# --- Exploration (M8) ---
	Saves.delete_slot(Saves.MANUAL)
	Game.new_game(5)
	_quiet()
	Game.state.calendar.week = 2
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
	_quiet()
	Game.state.calendar.week = 2
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
	_quiet()
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
	Game.state.calendar.week = 2
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
	Game.state.calendar.week = 2
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
	# --- Pause menu (M13): resume, save mid-day, settings and back to the game, title ---
	cult.menu_button.pressed.emit()
	await _frames(3)
	_check(cult.pause_panel != null and cult.pause_buttons.size() == 4, "pause: the menu button opens the pause menu")
	problems = cult.audit_layout()
	_check(problems.is_empty(), "pause: menu fits with readable text %s" % str(problems.slice(0, 2)))
	cult.pause_buttons.resume.pressed.emit()
	await _frames(2)
	_check(cult.pause_panel == null, "pause: resume closes it")
	Saves.delete_slot(Saves.MANUAL)
	cult.menu_button.pressed.emit()
	await _frames(2)
	cult.pause_buttons.save.pressed.emit()
	await _frames(2)
	_check(Saves.slot_exists(Saves.MANUAL), "pause: manual save works from the pause menu")
	cult.pause_buttons.settings.pressed.emit()
	await _frames(3)
	var settings := _scene()
	_check(Router.current_key == "settings", "settings: opens from the pause menu")
	settings.sliders["sfx"].value = 35
	await _frames(1)
	_check(Saves.load_settings().get("sfx_volume") == 35 and Audio.get_volume("sfx") == 35, "settings: the volume slider saves")
	settings.sliders["sfx"].value = Audio.DEFAULTS.sfx
	problems = UiKit.audit(settings)
	_check(problems.is_empty(), "settings: layout with volume sliders is clean %s" % str(problems.slice(0, 2)))
	settings.back_button.pressed.emit()
	await _frames(3)
	_check(Router.current_key == "cultivation", "settings: Back from the pause menu returns to the game")
	Router.goto("settings")
	await _frames(2)
	settings = _scene()
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
	await _story_layouts()
	await _arts_layouts()
	await _battle_ui()
	await _clip_and_minigame()
	Saves.update_settings({"animations": true, "minigames": true})
	_reached_end = true


## The cultivation sheet and the arts screen (all three tabs) fit in every orientation and both languages.
func _arts_layouts() -> void:
	var win := get_window()
	for size in [Vector2i(390, 844), Vector2i(360, 640), Vector2i(1280, 720), Vector2i(844, 390)]:
		win.size = size
		await _frames(3)
		for lang in ["zh_CN", "en"]:
			Loc.set_locale(lang)
			Game.new_game(5)
			Game.state.calendar.week = 8
			Game.state.player.path_id = "xuan_fist"
			Game.state.cultivation.realm = 3
			Game.state.cultivation.path_progress["xuan_fist"] = 40
			Game.state.resources.add_item("manual_iron_palm", 1)
			Game.state.resources.add("ore", 12)
			Router.goto("sheet")
			await _frames(4)
			var problems: Array[String] = UiKit.audit(_scene())
			_check(problems.is_empty(), "sheet layout %s %s: fits %s" % [str(size), lang, str(problems.slice(0, 2))])
			Router.goto("arts")
			await _frames(4)
			var arts := _scene()
			for t in ["tree", "manuals", "gear"]:
				arts.select_tab(t)
				await _frames(3)
				problems = UiKit.audit(arts)
				_check(problems.is_empty(), "arts layout %s %s %s: fits %s" % [str(size), lang, t, str(problems.slice(0, 2))])
	Loc.set_locale("zh_CN")
	win.size = Vector2i(1280, 720)
	await _frames(3)


## Dialogue and ending screens fit in every orientation and in both languages.
func _story_layouts() -> void:
	var win := get_window()
	for size in [Vector2i(390, 844), Vector2i(360, 640), Vector2i(768, 1024), Vector2i(1280, 720), Vector2i(2400, 1080)]:
		win.size = size
		await _frames(3)
		for lang in ["zh_CN", "en"]:
			Loc.set_locale(lang)
			Game.new_game(5)
			Game.state.calendar.week = 4
			Game.state.relationships.set_status("shen_qinghe", "joined")
			Game.state.relationships.scores["shen_qinghe"] = 8
			preload("res://scripts/domain/party_system.gd").set_active(Game.state, "shen_qinghe")
			for h in ["day1_intro", "day2_path", "day3_recruit"]:
				EventRules.mark_fired(Game.state, h)
			Router.goto("cultivation")
			await _frames(4)
			_check(Router.current_key == "dialogue" and Game.state.story.dialogue.id == "day4_battle", "story layout %s %s: day 4 opens its dialogue" % [str(size), lang])
			var d := _scene()
			Game.dialogue_advance()
			d.call("_show")
			await _frames(3)
			var problems: Array[String] = d.audit_layout()
			_check(problems.is_empty() and d.choice_buttons.size() == 2, "story layout %s %s: choices fit %s" % [str(size), lang, str(problems.slice(0, 2))])
			Router.settings_back = "title"
			Router.goto("settings")
			await _frames(3)
			problems = UiKit.audit(_scene())
			_check(problems.is_empty(), "story layout %s %s: settings fits %s" % [str(size), lang, str(problems.slice(0, 2))])
			for e in Content.endings:
				Game.state.story.dialogue = {}
				Game.state.story.ending = str(e.id)
				Router.goto("ending")
				await _frames(4)
				problems = _scene().audit_layout()
				_check(problems.is_empty(), "story layout %s %s: ending %s fits %s" % [str(size), lang, str(e.id), str(problems.slice(0, 2))])
	Loc.set_locale("zh_CN")
	win.size = Vector2i(1280, 720)
	await _frames(3)


## Plays whole battles with the real buttons and board taps (the same path for finger and mouse).
func _battle_ui() -> void:
	var win := get_window()
	Game.battle_instant = true
	win.size = Vector2i(1280, 720)
	await _frames(3)
	Game.new_game(3)
	_quiet()
	Router.goto("title")
	await _frames(4)
	var title := _scene()
	var problems: Array[String] = UiKit.audit(title)
	_check(problems.is_empty(), "battle: title with the practice button fits at 1280x720 %s" % str(problems.slice(0, 2)))
	title.practice_button.pressed.emit()
	await _frames(4)
	_check(Router.current_key == "battle", "battle: the practice button opens the battle screen")
	var scr := _scene()
	_check(scr.board.rotated and not Layout.is_portrait(), "battle: landscape turns the board a quarter turn")
	problems = scr.audit_layout()
	_check(problems.is_empty(), "battle: landscape fits %s" % str(problems.slice(0, 3)))
	# Cell <-> screen mapping round-trips in both orientations.
	var mapped := true
	for c in [Vector2i(0, 0), Vector2i(5, 7), Vector2i(2, 4)]:
		mapped = mapped and scr.board.cell_at(scr.board.cell_center(c)) == c
	_check(mapped, "battle: tapping the centre of a cell finds that cell (landscape)")
	await _play_battle_with_buttons(scr, true)
	scr = _scene()
	_check(scr.result_overlay != null and scr.continue_button != null, "battle: a result panel appears")
	var outcome: String = scr.battle.outcome
	_check(outcome == "victory", "battle: the practice battle can be won with buttons and taps (%s, round %d)" % [outcome, scr.battle.round_no])
	scr.continue_button.pressed.emit()
	await _frames(4)
	_check(Router.current_key == "title" and Game.battle == null, "battle: Continue returns to the title after practice")

	# A story trigger: the exploration screen offers the fight, the result returns to the route.
	Game.new_game(4)
	_quiet()
	Game.state.calendar.week = 2
	preload("res://scripts/domain/relationship_rules.gd").refresh(Game.state, Content)
	Game.start_exploration("bamboo_pass")
	Game.state.exploration.pending_battle = "bandit_scouts"
	Router.goto("exploration")
	await _frames(4)
	var ex := _scene()
	_check(ex.fight_button != null and ex.choice_buttons.is_empty(), "battle: a pending fight replaces the story choices with one Fight button")
	ex.fight_button.pressed.emit()
	await _frames(4)
	_check(Router.current_key == "battle" and _scene().battle.scenario_id == "bandit_scouts", "battle: the Fight button opens the right scenario")
	await _play_battle_with_buttons(_scene(), false)
	_scene().continue_button.pressed.emit()
	await _frames(4)
	_check(Router.current_key == "exploration" and Game.state.exploration.pending_battle == "" and _scene().fight_button == null, "battle: after the fight the route continues")

	# Closing the game mid-fight: the next session picks the same battle up from the save.
	Game.state.exploration.pending_battle = "bandit_scouts"
	_check(Game.start_battle("bandit_scouts", "exploration"), "resume: a story battle starts")
	Router.goto("battle")
	await _frames(4)
	var live := _scene()
	live.action_buttons["guard"].pressed.emit()
	await _frames(2)
	var saved_hash: String = live.battle.state_hash()
	var loaded: Dictionary = Saves.load_latest()
	_check(loaded.ok and not loaded.state.battle.is_empty(), "resume: the autosave holds the battle in progress")
	Game.state = loaded.state
	Game.battle = null
	Router.goto("cultivation")
	await _frames(6)
	_check(Router.current_key == "battle" and _scene().battle.state_hash() == saved_hash, "resume: loading the save returns to the same battle")
	_check(_scene().mode == "idle" and _scene().log_lines.size() >= 3, "resume: it is still the player's turn and the log is back")
	_scene().action_buttons["end"].pressed.emit()
	await _frames(2)
	await _play_battle_with_buttons(_scene(), false)
	var done := _scene()
	_check(done.result_overlay != null and Game.state.battle.is_empty() and Game.state.exploration.pending_battle == "", "resume: finishing clears the saved battle and the trigger")
	done.continue_button.pressed.emit()
	await _frames(4)

	# Portrait phone, a different battle, confirm/cancel and the pending rules.
	win.size = Vector2i(390, 844)
	await _frames(4)
	_check(Game.start_battle("rescue_battle", "practice"), "battle: the rescue battle starts")
	Router.goto("battle")
	await _frames(4)
	scr = _scene()
	_check(Layout.is_portrait() and not scr.board.rotated and scr._body.vertical, "battle: portrait keeps the 6x8 board upright above the controls")
	problems = scr.audit_layout()
	_check(problems.is_empty(), "battle: portrait fits %s" % str(problems.slice(0, 3)))
	var board_rect: Rect2 = scr.board.get_global_rect()
	_check(board_rect.size.y > board_rect.size.x, "battle: the portrait board area is taller than wide")
	mapped = true
	for c in [Vector2i(0, 0), Vector2i(5, 7), Vector2i(2, 4)]:
		mapped = mapped and scr.board.cell_at(scr.board.cell_center(c)) == c
	_check(mapped, "battle: tapping the centre of a cell finds that cell (portrait)")
	# Rotating live keeps the battle.
	var before_hash: String = scr.battle.state_hash()
	win.size = Vector2i(844, 390)
	await _frames(4)
	_check(scr.board.rotated and scr.battle.state_hash() == before_hash, "battle: rotating changes only the view, not the battle")
	win.size = Vector2i(390, 844)
	await _frames(4)
	# No action without confirmation.
	var u: RefCounted = scr.battle.active()
	_check(scr.mode == "idle" and u.team == "player", "battle: the first turn belongs to the player")
	scr.action_buttons["end"].pressed.emit()
	await _frames(2)
	await _play_battle_with_buttons(scr, false)
	scr = _scene()
	_check(scr.battle.outcome != "", "battle: rescue battle reached a result (%s)" % scr.battle.outcome)
	scr.continue_button.pressed.emit()
	await _frames(4)
	Game.battle_instant = false


func _play_battle_with_buttons(scr: Node, test_cancel: bool) -> void:
	var cancelled := not test_cancel
	var preview_ok := true
	var guard := 0
	while scr.battle.outcome == "" and guard < 400:
		guard += 1
		if scr.mode == "followup":
			scr.action_buttons["strike"].pressed.emit()
			continue
		if scr.mode != "idle":
			await _frames(1)
			continue
		var u: RefCounted = scr.battle.active()
		var plan: Dictionary = BattleAI.decide(scr.battle)
		if not plan.is_empty():
			if plan.cell != u.pos:
				scr.action_buttons["move"].pressed.emit()
				scr.tap_cell(plan.cell)
			if plan.kind == "attack" or plan.kind == "support":
				scr.action_buttons[plan.kind].pressed.emit()
				scr.action_buttons["tech:" + plan.tech].pressed.emit()
				scr.tap_cell(scr.battle.unit(plan.target).pos)
				if scr.mode == "confirm":
					if plan.kind == "attack":
						var pv: Dictionary = scr.battle.preview_attack(u.id, plan.tech, plan.target)
						preview_ok = preview_ok and scr._info.text.contains(str(pv.damage))
					if not cancelled:
						var hp0: int = scr.battle.unit(plan.target).hp
						scr.action_buttons["cancel"].pressed.emit()
						preview_ok = preview_ok and scr.mode == "target" and scr.battle.unit(plan.target).hp == hp0
						scr.tap_cell(scr.battle.unit(plan.target).pos)
						cancelled = true
					scr.action_buttons["confirm"].pressed.emit()
			elif plan.kind == "item":
				scr.action_buttons["item"].pressed.emit()
				scr.tap_cell(scr.battle.unit(plan.target).pos)
				scr.action_buttons["confirm"].pressed.emit()
		while scr.mode == "followup":
			scr.action_buttons["strike"].pressed.emit()
		if scr.battle.outcome == "":
			scr.action_buttons["end"].pressed.emit()
		await _frames(1)
	_check(cancelled and preview_ok, "battle: cancel leaves the battle untouched and the preview shows the real damage")


## Activity clips and the fishing minigame through the real screens.
func _clip_and_minigame() -> void:
	Saves.update_settings({"animations": true, "minigames": true})
	Game.new_game(7)
	_quiet()
	Game.state.calendar.week = 3
	Game.state.world.add_lead("x")
	Router.goto("cultivation")
	await _frames(3)
	var cult := _scene()
	cult.select_activity("rest")
	var week0: int = Game.state.calendar.week
	var slot0: int = Game.state.calendar.slot
	cult.confirm_button.pressed.emit()
	await _frames(2)
	_check(cult.clip_overlay != null and Game.state.calendar.slot == slot0, "clip: confirming an activity plays its clip first (nothing happens yet)")
	var probs: Array[String] = cult.audit_layout()
	_check(probs.is_empty(), "clip: layout audit is clean %s" % str(probs.slice(0, 2)))
	cult.clip_overlay.skip()
	await _frames(3)
	_check(cult.clip_overlay == null and (Game.state.calendar.slot != slot0 or Game.state.calendar.week != week0), "clip: skipping it performs the activity")
	# Fishing: a minigame; quick resolve pays like an average attempt.
	cult.select_activity("fishing")
	cult.confirm_button.pressed.emit()
	await _frames(2)
	if cult.choice_panel != null:
		cult.option_buttons.keys()
		cult.option_buttons[cult.option_buttons.keys()[0]].pressed.emit()
		await _frames(3)
	_check(Router.current_key == "minigame", "minigame: fishing opens the minigame screen")
	var mg := _scene()
	var mprobs: Array[String] = mg.audit_layout()
	_check(mprobs.is_empty(), "minigame: layout audit is clean %s" % str(mprobs.slice(0, 2)))
	var coins0: int = Game.state.resources.get_amount("coins")
	var food0: int = Game.state.resources.get_amount("food")
	mg.start_button.pressed.emit()
	await _frames(2)
	_check(mg.phase == "play", "minigame: Start begins the play")
	mg.game_logic.set_input("hold", true)
	for i in range(60 * 22):   # play it out: the logic is stepped by the screen; here we fast-forward
		if mg.game_logic.done:
			break
		mg.game_logic.step(1.0 / 60.0)
	await _frames(3)
	_check(mg.phase == "result" and ["poor", "ok", "good", "perfect"].has(mg.record.grade), "minigame: the play ends with a graded result (%s)" % str(mg.record.get("grade", "")))
	var slot1: int = Game.state.calendar.slot
	mg.collect_button.pressed.emit()
	await _frames(4)
	_check(Router.current_key == "cultivation" and Game.state.calendar.slot != slot1, "minigame: Collect performs the activity and returns to training")
	_check(Game.state.resources.get_amount("food") + Game.state.resources.get_amount("coins") >= food0 + coins0, "minigame: rewards were paid")
	_check(not _scene()._last_result.is_empty() and _scene()._last_result.has("play"), "minigame: the training screen shows the result with the play record")
