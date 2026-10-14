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
	_check(settings.back_button.text == "Back", "settings strings update live")
	settings.back_button.pressed.emit()
	await _frames()
	_check(_scene().start_button.text == "Start Game", "title shows English after toggle")
	Loc.set_locale("zh_CN")
	_check(_scene().start_button.text == "开始游戏", "title returns to Mandarin")
