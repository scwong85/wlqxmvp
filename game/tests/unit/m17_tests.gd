extends RefCounted
## M17 tests: the Map screen and Journal (built headless, driven like a player without changing scenes).

const WorldRules = preload("res://scripts/domain/world_rules.gd")

var check: Callable


func run(check_fn: Callable, _loc: Node) -> void:
	check = check_fn
	var root: Node = Engine.get_main_loop().root
	var game: Node = root.get_node("Game")
	game.new_game(31)
	game.battle = null
	game.state.calendar.week = 7
	for h in root.get_node("Content").day_hooks:
		game.state.calendar.events_fired.append(str(h.id))
	game.state.calendar.events_fired.append("prologue_crisis")
	var scene: Control = load("res://scenes/map/map.tscn").instantiate()
	Engine.get_main_loop().current_scene.add_child(scene)
	check.call(scene.area_buttons.has("valley_village") and scene.area_buttons.has("old_shrine"), "m17: every area has a button")
	check.call(scene.selected_id != "" and not scene.go_button.disabled, "m17: an open area is selected and can be visited")
	check.call(str(scene.area_buttons.valley_village.text).contains(root.get_node("Loc").t("map.state.due")), "m17: the village shows 'something due' in its window")
	scene.area_buttons.old_shrine.pressed.emit()
	check.call(scene.selected_id == "old_shrine" and scene.go_button.disabled, "m17: the locked shrine cannot be visited")
	check.call(str(scene._detail_label.text).contains(root.get_node("Loc").t("world.area.locked")), "m17: and says why")
	game.state.world.add_lead("shrine_rumor")
	scene.tab_buttons.journal.pressed.emit()
	check.call(scene.tab == "journal", "m17: the journal tab opens")
	var texts := ""
	for c in scene._list_box.get_children():
		if c is Label:
			texts += c.text + "\n"
	check.call(texts.contains(root.get_node("Loc").t("world.lead.shrine_rumor.name")), "m17: the journal lists the lead")
	root.get_node("Loc").set_locale("en") if root.get_node("Loc").has_method("set_locale") else null
	scene.queue_free()
	root.get_node("Loc").set_locale("zh_CN") if root.get_node("Loc").has_method("set_locale") else null
	game.battle = null
