extends Node
## Central scene navigation. Scenes are addressed by stable keys, never by path.

signal scene_changed(key: String)

const SCENES := {
	"boot": "res://scenes/boot/boot.tscn",
	"title": "res://scenes/menus/title.tscn",
	"cultivation": "res://scenes/cultivation/cultivation.tscn",
	"exploration": "res://scenes/exploration/exploration.tscn",
	"hero_creation": "res://scenes/menus/hero_creation.tscn",
	"minigame": "res://scenes/minigame/minigame_host.tscn",
	"map": "res://scenes/map/map.tscn",
	"battle": "res://scenes/battle/battle.tscn",
	"dialogue": "res://scenes/dialogue/dialogue.tscn",
	"ending": "res://scenes/ending/ending.tscn",
	"settings": "res://scenes/menus/settings.tscn",
}

var current_key: String = ""
## Where the Settings screen's Back button leads (the pause menu sets it to the game screen it came from).
var settings_back: String = "title"


func goto(key: String) -> bool:
	if not SCENES.has(key):
		push_error("Router: unknown scene key '%s'" % key)
		return false
	var err := get_tree().change_scene_to_file(SCENES[key])
	if err != OK:
		push_error("Router: failed to load '%s' (error %d)" % [key, err])
		return false
	current_key = key
	scene_changed.emit(key)
	print("ROUTE ", key)
	return true
