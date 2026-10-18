extends Node
## Visual check (not part of the build): run under xvfb with a real renderer to save screenshots into SHOT_DIR.
## xvfb-run -a godot --path game --rendering-driver opengl3 --resolution 390x844 res://tests/shots/shots.tscn -- /tmp/shots

const StageView = preload("res://scenes/shared/stage_view.gd")
var out_dir := "/tmp/shots"


func _frames(n: int = 3) -> void:
	for i in n:
		await get_tree().process_frame


func _snap(name: String) -> void:
	await _frames(4)
	var img := get_viewport().get_texture().get_image()
	img.save_png("%s/%s.png" % [out_dir, name])
	print("SHOT ", name, " ", img.get_size())


func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		out_dir = a
	DirAccess.make_dir_recursive_absolute(out_dir)
	Saves.dir = "user://shots_saves/"
	DirAccess.make_dir_recursive_absolute(Saves.dir)
	get_tree().current_scene = null
	await _frames(5)
	Loc.set_locale("zh_CN")
	# 1. Stage compositions (backgrounds + figures).
	var combos := [
		["city_night", ["hero", "qian_man", "mask_chi"]],
		["yanmen_fort", ["xiao_hanchuan", "hero", "leader"]],
		["shrine_night", ["mask_hui", "hero", "mask_xuan"]],
		["valley_dawn", ["elder", "hero", "villager"]],
		["city_docks", ["guild_master", "su_dai", "lu_chenzhou"]],
		["cangwu_night", ["master_gu", "xia_zhi", "bai_yan"]],
		["penglai_sea", ["li_shan", "shen_qinghe", "xie_wujiu"]],
		["riverside_day", ["wanderer", "bandit", "head_lei"]],
	]
	var holder := VBoxContainer.new()
	holder.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(holder)
	for c in combos:
		var sv := StageView.new()
		sv.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sv.animate = false
		holder.add_child(sv)
		var who: Array = c[1]
		sv.show_stage({"bg": c[0], "actors": {"left": {"who": who[0], "pose": "idle", "face": "neutral"}, "center": {"who": who[1], "pose": "idle", "face": "neutral"}, "right": {"who": who[2], "pose": "idle", "face": "neutral"}}, "focus": ""}, [])
	await _snap("stages")
	holder.queue_free()
	await _frames(2)
	# 2. Endings.
	for e in Content.endings:
		Game.new_game(7)
		Game.state.story.dialogue = {}
		Game.state.story.ending = str(e.id)
		Router.goto("ending")
		await _frames(6)
		await _snap("ending_" + str(e.id))
	# 3. Title, creation (female), cultivation with a party.
	Router.goto("title")
	await _snap("title")
	Game.new_game(7)
	Router.goto("hero_creation")
	await _frames(4)
	var sc := get_tree().current_scene
	sc.gender_buttons["f"].pressed.emit()
	await _snap("creation_f")
	Game.new_game(7)
	Game.state.relationships.set_status("shen_qinghe", "joined")
	Router.goto("title")
	await _frames(3)
	get_tree().current_scene.call("_on_practice")
	await _frames(8)
	await _snap("battle")
	get_tree().quit()
