extends Node
## Headless navigation smoke test: boot -> title -> hub -> title -> settings -> language toggle -> title.
## Run: godot --headless --path game res://tests/smoke/run_smoke.tscn   (prints SMOKE_OK / SMOKE_FAIL)

var _fails: Array[String] = []


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
	# Router replaces the current scene, so move this harness out of the way first.
	get_tree().current_scene = null  # we stay alive under root; Router no longer frees us
	await _run()
	print("SMOKE_OK" if _fails.is_empty() else "SMOKE_FAIL")
	get_tree().quit(0 if _fails.is_empty() else 1)


func _run() -> void:
	Router.goto("boot")
	await _frames(4)
	_check(Router.current_key == "title", "boot routes to title")
	var title := _scene()
	_check(title != null and title.has_method("_refresh") and title.get("start_button") != null, "title scene is live")
	_check(title.load_button.disabled, "load button disabled")
	_check(not title.load_button.tooltip_text.begins_with("["), "load tooltip has a real translation")
	_check(title.start_button.text == "开始游戏", "title is Mandarin by default")

	title.start_button.pressed.emit()
	await _frames()
	_check(Router.current_key == "hub", "new game opens hub")
	_scene().back_button.pressed.emit()
	await _frames()
	_check(Router.current_key == "title", "hub back returns to title")

	_scene().settings_button.pressed.emit()
	await _frames()
	_check(Router.current_key == "settings", "settings opens")
	var settings := _scene()
	settings.language_buttons["en"].pressed.emit()
	await _frames(1)
	_check(Loc.locale == "en", "language toggle switches to English")
	_check(Saves.load_settings().get("locale") == "en", "language choice is persisted")
	_check(settings.back_button.text == "Back", "settings strings update live")
	settings.back_button.pressed.emit()
	await _frames()
	_check(_scene().start_button.text == "Start Game", "title shows English after toggle")
	Loc.set_locale("zh_CN")
	_check(_scene().start_button.text == "开始游戏", "title returns to Mandarin")
	await _persistence_flow()


func _write_garbage(slot: String) -> void:
	for suffix in ["", ".bak"]:
		var f := FileAccess.open(Saves.dir.path_join(slot) + suffix, FileAccess.WRITE)
		f.store_string("{ definitely not a save")
		f.close()


func _persistence_flow() -> void:
	var title := _scene()
	_check(title.load_button.disabled, "persist: load disabled with no saves")

	title.start_button.pressed.emit()
	await _frames()
	var hub := _scene()
	_check(Game.state.calendar.day == 1 and Game.state.calendar.slot == 1, "persist: new game starts day 1 slot 1")
	hub.advance_button.pressed.emit()
	_check(Game.state.calendar.slot == 2, "persist: advance moves to slot 2")
	_check(Saves.slot_exists(Saves.AUTO), "persist: advancing autosaves")
	hub.save_button.pressed.emit()
	_check(Saves.slot_exists(Saves.MANUAL), "persist: manual save writes a file")
	_check(hub.message_label.text == Loc.t("hub.saved"), "persist: hub confirms the save")

	hub.back_button.pressed.emit()
	await _frames()
	title = _scene()
	_check(not title.load_button.disabled, "persist: load enabled once a save exists")
	_check(title.load_note.text == Loc.t("ui.load_hint", {"day": 1, "slot": 2}), "persist: title summarises the save")

	Game.state = null  # simulate a fresh launch
	title.load_button.pressed.emit()
	await _frames()
	_check(Router.current_key == "hub", "persist: load opens hub")
	_check(Game.state.calendar.slot == 2, "persist: loaded run is at slot 2")
	_scene().back_button.pressed.emit()
	await _frames()

	# Both saves destroyed: the title must say so and Load must not leave the title.
	_write_garbage(Saves.MANUAL)
	_write_garbage(Saves.AUTO)
	Router.goto("title")
	await _frames()
	title = _scene()
	_check(title.load_note.text == Loc.t("save.error.corrupt"), "persist: corrupt saves are explained on the title")
	title.load_button.pressed.emit()
	await _frames()
	_check(Router.current_key == "title", "persist: failed load stays on title")
	_check(not title.load_note.text.begins_with("["), "persist: error text is a real translation")

	for f in DirAccess.get_files_at(Saves.dir):
		DirAccess.remove_absolute(Saves.dir.path_join(f))
