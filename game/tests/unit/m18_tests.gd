extends RefCounted
## M18 tests: hero look and name, stage rules, stage in dialogues (saved and restored), backlog, validator, and the
## hero creation and stage screens built headless.

const LookRules = preload("res://scripts/domain/look_rules.gd")
const StageRules = preload("res://scripts/domain/stage_rules.gd")
const DialogueSystem = preload("res://scripts/domain/dialogue_system.gd")
const GameState = preload("res://scripts/domain/game_state.gd")
const SaveService = preload("res://scripts/services/save_service.gd")
const ContentService = preload("res://scripts/services/content_service.gd")

var check: Callable


func run(check_fn: Callable, _loc: Node) -> void:
	check = check_fn
	_look()
	_stage_rules()
	_dialogue_stage()
	_validator()
	_screens()


func _look() -> void:
	check.call(LookRules.sanitize(null) == LookRules.default_look(), "m18: no look data gives the default look")
	var l := LookRules.sanitize({"gender": "x", "hair": 99, "hair_color": -3, "outfit": 2, "skin": "7"})
	check.call(l.gender == "m" and l.hair == LookRules.HAIR_STYLES - 1 and l.hair_color == 0 and l.outfit == 2 and l.skin == 2, "m18: out-of-range look values are clamped")
	check.call(LookRules.clean_name("  风{x}清扬[1]  ") == "风x清扬1", "m18: braces and brackets are stripped from names")
	check.call(LookRules.clean_name("一二三四五六七八九十").length() == LookRules.MAX_NAME, "m18: names are limited to %d characters" % LookRules.MAX_NAME)
	check.call(LookRules.clean_name("a\nb\tc") == "abc", "m18: control characters are removed from names")
	var st: RefCounted = GameState.new_game(3)
	st.player.hero_name = "云澈"
	st.player.look = LookRules.sanitize({"gender": "f", "hair": 3, "outfit": 4})
	var back: RefCounted = GameState.from_dict(JSON.parse_string(JSON.stringify(st.to_dict())))
	check.call(back.player.hero_name == "云澈" and back.player.look.gender == "f" and back.player.look.hair == 3 and back.player.look.outfit == 4, "m18: name and look survive a save round trip")
	var svc: Node = SaveService.new()
	var old: RefCounted = GameState.from_dict(svc.migrate({"calendar": {"week": 2, "slot": 1}}, 8))
	check.call(old.player.hero_name == "" and old.player.look == LookRules.default_look(), "m18: older saves load with the default hero")
	svc.free()


func _stage_rules() -> void:
	var s := StageRules.blank()
	StageRules.apply(s, [{"c": "bg", "id": "valley_day"}, {"c": "show", "who": "hero", "slot": "left", "pose": "bow", "face": "happy"},
			{"c": "show", "who": "elder", "slot": "right"}])
	check.call(s.bg == "valley_day" and s.actors.size() == 2 and s.actors.left.pose == "bow" and s.actors.right.face == "neutral", "m18: show places characters with defaults")
	StageRules.apply(s, [{"c": "pose", "slot": "left", "pose": "laugh"}, {"c": "face", "slot": "right", "face": "sad"}, {"c": "focus", "who": "elder"}])
	check.call(s.actors.left.pose == "laugh" and s.actors.right.face == "sad" and s.focus == "elder", "m18: pose, face and focus change")
	StageRules.apply(s, [{"c": "move", "slot": "left", "to": "center"}])
	check.call(s.actors.has("center") and not s.actors.has("left"), "m18: move changes slot")
	StageRules.apply(s, [{"c": "hide", "who": "elder"}])
	check.call(s.actors.size() == 1, "m18: hide by name")
	StageRules.apply(s, [{"c": "clear"}])
	check.call(s.actors.is_empty() and s.focus == "", "m18: clear empties the stage")
	var dirty := StageRules.sanitize({"bg": "nowhere", "actors": {"left": {"who": "hero", "pose": "flying", "face": "??"}, "middle": {"who": "x"}, "right": {"who": ""}}})
	check.call(dirty.bg == "default" and dirty.actors.size() == 1 and dirty.actors.left.pose == "idle" and dirty.actors.left.face == "neutral", "m18: a damaged stage is repaired")
	var known := func(w: String) -> bool: return w == "hero"
	check.call(StageRules.problems({"c": "show", "who": "hero", "slot": "left"}, known).is_empty(), "m18: a good command has no problems")
	check.call(not StageRules.problems({"c": "show", "who": "ghost", "slot": "up", "pose": "fly"}, known).is_empty(), "m18: a bad command is reported")
	check.call(StageRules.transient([{"c": "shake"}, {"c": "bg", "id": "x"}]).size() == 1, "m18: transient commands are separated")


func _dialogue_stage() -> void:
	var content: Node = ContentService.new()
	content.load_all()
	var st: RefCounted = GameState.new_game(4)
	var dlg: Dictionary = content.dialogue("day1_intro")
	DialogueSystem.start(st, dlg, "day1_intro", content)
	var stage: Dictionary = st.story.dialogue.stage
	check.call(stage.bg == "valley_dawn" and stage.actors.has("left") and stage.actors.left.who == "hero" and stage.actors.has("right"), "m18: the first node puts the hero and the elder on stage")
	check.call((st.story.dialogue.log as Array).size() == 1, "m18: the first line enters the backlog")
	DialogueSystem.advance(st, dlg, content)
	check.call((st.story.dialogue.log as Array).size() == 2, "m18: each line is logged")
	var back: RefCounted = GameState.from_dict(JSON.parse_string(JSON.stringify(st.to_dict())))
	check.call(back.story.dialogue.stage.bg == "valley_dawn" and back.story.dialogue.stage.actors.size() == stage.actors.size() and back.story.dialogue.log.size() == 2, "m18: stage and backlog survive saving mid-dialogue")
	var path_dlg: Dictionary = content.dialogue("day2_path")
	var s2: RefCounted = GameState.new_game(4)
	DialogueSystem.start(s2, path_dlg, "day2_path", content)
	DialogueSystem.choose(s2, path_dlg, "later", content)
	check.call(s2.story.dialogue.is_empty(), "m18: ending a dialogue clears its stage")
	var s3: RefCounted = GameState.new_game(4)
	DialogueSystem.start(s3, path_dlg, "day2_path", content)
	var before: int = (s3.story.dialogue.log as Array).size()
	DialogueSystem.choose(s3, path_dlg, "fist", content)
	check.call(before == 1, "m18: a choice is logged with its label before the reply")
	content.free()


func _validator() -> void:
	var has_key := func(k: String) -> bool: return Engine.get_main_loop().root.get_node("Loc").has_key(k)
	var c: Node = ContentService.new()
	c.load_all()
	check.call(c.validate(has_key).is_empty(), "m18: shipped content validates with stage commands")
	c.dialogues[0].nodes[0]["stage"] = [{"c": "show", "who": "nobody", "slot": "left"}, {"c": "dance"}]
	var joined := "\n".join(c.validate(has_key))
	check.call(joined.contains("unknown character") and joined.contains("unknown stage command"), "m18: the validator catches bad stage commands")
	for l in c.looks:
		check.call(Color(str(l.get("hair_hex", "000000"))) != null and str(l.id) != "", "m18: look %s has valid colours" % l.id)
	c.free()


func _screens() -> void:
	var root: Node = Engine.get_main_loop().root
	var game: Node = root.get_node("Game")
	var host: Node = Engine.get_main_loop().current_scene
	game.new_game(41)
	var scene: Control = load("res://scenes/menus/hero_creation.tscn").instantiate()
	host.add_child(scene)
	check.call(scene.name_edit != null and scene.name_edit.text == root.get_node("Loc").t("hero.default_name"), "m18: hero creation starts with the default name")
	scene.gender_buttons.f.pressed.emit()
	scene.hair_next.pressed.emit()
	scene.outfit_buttons[3].pressed.emit()
	check.call(scene.look.gender == "f" and scene.look.hair == 1 and scene.look.outfit == 3, "m18: the form changes the look")
	scene.name_edit.text = "云澈"
	game.set_hero(scene.name_edit.text, scene.look)
	check.call(game.state.player.hero_name == "云澈" and root.get_node("Loc").globals.get("hero") == "云澈", "m18: the hero's name becomes the {hero} text variable")
	scene.queue_free()
	var StageView = load("res://scenes/shared/stage_view.gd")
	var sv: Control = StageView.new()
	host.add_child(sv)
	sv.size = Vector2(600, 400)
	sv.show_stage({"bg": "shrine_night", "actors": {"left": {"who": "hero", "pose": "sword", "face": "angry"}, "right": {"who": "elder", "pose": "idle", "face": "neutral"}}, "focus": "hero"}, [])
	check.call(sv.actors.size() == 2 and sv.actors.right.dim and not sv.actors.left.dim, "m18: the stage shows two characters and dims the one who is not speaking")
	sv.show_stage({"bg": "default", "actors": {}}, [])
	check.call(sv.actors.is_empty(), "m18: an empty stage removes them")
	sv.queue_free()
	var failures := 0
	for pose in StageRules.POSES:
		var prm: Dictionary = load("res://scenes/shared/chibi_code_skin.gd").pose_params(pose, 1.3)
		if not (prm.has("lean") and prm.has("la") and prm.has("ra")):
			failures += 1
	check.call(failures == 0, "m18: every pose has arm and lean parameters")
	game.battle = null
