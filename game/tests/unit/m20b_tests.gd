extends RefCounted
## M20b tests: skill trees, manuals, equipment, their battle effects, saving and the arts screen.

const GameState = preload("res://scripts/domain/game_state.gd")
const SkillTree = preload("res://scripts/domain/skill_tree.gd")
const ManualRules = preload("res://scripts/domain/manual_rules.gd")
const EquipmentRules = preload("res://scripts/domain/equipment_rules.gd")
const BattleSetup = preload("res://scripts/domain/combat/battle_setup.gd")
const ContentService = preload("res://scripts/services/content_service.gd")

var check: Callable
var content: Node


func run(check_fn: Callable, _loc: Node) -> void:
	check = check_fn
	content = ContentService.new()
	content.load_all()
	_tree()
	_manuals()
	_gear()
	_save()
	_screen()
	content.free()


func _state(path := "xuan_fist") -> RefCounted:
	var s: RefCounted = GameState.new_game(8)
	s.player.path_id = path
	s.player.stamina = 30
	return s


func _tree() -> void:
	for path in ["xuan_fist", "green_sword", "listening_rain"]:
		var nodes: Array = SkillTree.nodes_of(_state(path), content)
		check.call(nodes.size() == 8, "m20b: %s has eight skill nodes" % path)
	var s := _state()
	check.call(SkillTree.points_total(s) == 0 and not SkillTree.can_learn(s, "iron_skin", content).ok, "m20b: no points, nothing to learn")
	s.cultivation.realm = 1
	check.call(SkillTree.points_total(s) == 2, "m20b: each realm gives two points")
	check.call(SkillTree.can_learn(s, "iron_skin", content).ok, "m20b: a root node can be learned with a point")
	check.call(not SkillTree.can_learn(s, "heavy_shoulder", content).ok, "m20b: a node needs its requirement first")
	check.call(SkillTree.learn(s, "iron_skin", content).ok and SkillTree.points_free(s, content) == 1, "m20b: learning spends the points")
	check.call(not SkillTree.learn(s, "iron_skin", content).ok, "m20b: a node is learned once")
	var other := _state("green_sword")
	other.cultivation.realm = 3
	check.call(not SkillTree.can_learn(other, "iron_skin", content).ok, "m20b: another school's node is closed")
	s.cultivation.realm = 4
	s.cultivation.path_progress["xuan_fist"] = 200
	check.call(SkillTree.points_total(s) == 16, "m20b: path progress adds up to eight points")
	for id in ["heavy_shoulder", "fist_quake", "steady_stance", "deep_earth", "fist_tremor", "qi_thread"]:
		check.call(SkillTree.learn(s, id, content).ok, "m20b: learn %s" % id)
	check.call(s.player.techniques.has("fist_quake") and s.player.techniques.has("fist_tremor"), "m20b: technique nodes teach the technique")
	check.call(SkillTree.learn(s, "fist_dragon", content).ok and s.player.techniques.has("fist_dragon"), "m20b: the signature art follows from both branches")
	var b: Dictionary = SkillTree.stat_bonus(s, content)
	check.call(int(b.get("hp", 0)) == 14 and int(b.get("power", 0)) == 1 and int(b.get("body", 0)) == 1 and int(b.get("tp", 0)) == 1, "m20b: stat nodes add up %s" % str(b))
	var unit: RefCounted = BattleSetup.build(content, "training_match", 1, s).units[0]
	var plain: RefCounted = BattleSetup.build(content, "training_match", 1, _state()).units[0]
	check.call(unit.max_hp > plain.max_hp and unit.power == plain.power + 1 and unit.tp >= plain.tp + 1, "m20b: the hero fights with the tree bonuses")


func _manuals() -> void:
	var s := _state()
	check.call(ManualRules.owned(s, content).is_empty(), "m20b: no manuals at the start")
	check.call(not ManualRules.can_study(s, "iron_palm", content).ok, "m20b: a manual that is not owned cannot be studied")
	s.resources.add_item("manual_iron_palm", 1)
	s.resources.add_item("manual_wind_step", 1)
	s.resources.add_item("manual_ember_fist", 1)
	var slot_before: int = s.calendar.slot + s.calendar.week * 10
	var r := ManualRules.study(s, "iron_palm", content)
	check.call(r.ok and s.player.techniques.has("iron_palm") and s.player.stamina == 26, "m20b: studying teaches the technique and costs stamina")
	check.call(s.calendar.slot + s.calendar.week * 10 != slot_before, "m20b: studying takes a slot")
	check.call(not ManualRules.can_study(s, "wind_step", content).ok, "m20b: only one manual of a kind can be studied")
	check.call(not ManualRules.can_study(s, "ember_fist", content).ok, "m20b: a rare manual needs the realm")
	s.cultivation.realm = 3
	check.call(ManualRules.study(s, "ember_fist", content).ok, "m20b: another kind is still open")
	var lv: RefCounted = BattleSetup.build(content, "training_match", 2, s).units[0]
	check.call(lv.techniques.has("iron_palm"), "m20b: the manual technique is in the battle")


func _gear() -> void:
	var s := _state()
	check.call(not EquipmentRules.can_forge(s, "iron_sword", content).ok, "m20b: forging needs ore and coins")
	s.resources.add("ore", 20)
	s.resources.add("coins", 100)
	check.call(EquipmentRules.forge(s, "iron_sword", content).ok and s.resources.get_amount("ore") == 17, "m20b: forging spends the materials")
	check.call(not EquipmentRules.can_forge(s, "iron_sword", content).ok, "m20b: a piece is forged once")
	check.call(not EquipmentRules.can_forge(s, "jade_saber", content).ok, "m20b: top gear needs the realm")
	check.call(not EquipmentRules.equip(s, "armor", "iron_sword", content), "m20b: a piece fits only its slot")
	check.call(not EquipmentRules.equip(s, "weapon", "steel_blade", content), "m20b: unowned gear cannot be worn")
	check.call(EquipmentRules.equip(s, "weapon", "iron_sword", content) and int(EquipmentRules.bonus(s, content).get("power", 0)) == 1, "m20b: worn gear gives its bonus")
	var wearing: RefCounted = BattleSetup.build(content, "training_match", 3, s).units[0]
	var bare: RefCounted = BattleSetup.build(content, "training_match", 3, _state()).units[0]
	check.call(wearing.power == bare.power + 1, "m20b: the hero fights with the gear bonus")
	EquipmentRules.equip(s, "weapon", "", content)
	check.call(EquipmentRules.bonus(s, content).is_empty(), "m20b: taking it off removes the bonus")


func _save() -> void:
	var s := _state()
	s.cultivation.nodes = ["iron_skin"]
	s.cultivation.manual_choices = {"palm": "iron_palm"}
	s.cultivation.equipment = {"weapon": "iron_sword"}
	var back: RefCounted = GameState.from_dict(JSON.parse_string(JSON.stringify(s.to_dict())))
	check.call(back.cultivation.nodes == ["iron_skin"] and back.cultivation.manual_choices.get("palm") == "iron_palm" and back.cultivation.equipment.get("weapon") == "iron_sword", "m20b: nodes, manual choices and worn gear survive saving")
	var old: RefCounted = GameState.from_dict({"calendar": {"week": 2, "slot": 1}})
	check.call(old.cultivation.nodes.is_empty() and old.cultivation.equipment.is_empty(), "m20b: older saves have none")
	var bad: RefCounted = GameState.from_dict({"cultivation": {"nodes": [5, "iron_skin", "iron_skin"], "equipment": 7}})
	check.call(bad.cultivation.nodes == ["iron_skin"], "m20b: damaged node lists are cleaned")


func _screen() -> void:
	var root: Node = Engine.get_main_loop().root
	var game: Node = root.get_node("Game")
	var host: Node = Engine.get_main_loop().current_scene
	game.new_game(52)
	game.state.player.path_id = "xuan_fist"
	game.state.player.stamina = 30
	game.state.cultivation.realm = 2
	game.state.resources.add_item("manual_iron_palm", 1)
	game.state.resources.add("ore", 10)
	game.state.resources.add("coins", 50)
	var scene: Control = load("res://scenes/menus/arts_screen.tscn").instantiate()
	host.add_child(scene)
	check.call(scene.action_buttons.has("iron_skin") and not scene.action_buttons["iron_skin"].disabled, "m20b: the tree tab offers the root node")
	check.call(scene.action_buttons.has("heavy_shoulder") and scene.action_buttons["heavy_shoulder"].disabled, "m20b: a locked node is disabled")
	scene.action_buttons["iron_skin"].pressed.emit()
	check.call(game.state.cultivation.nodes.has("iron_skin") and scene.notice_label.text != "", "m20b: learning from the screen works and says so")
	scene.select_tab("manuals")
	check.call(scene.action_buttons.has("iron_palm"), "m20b: the manuals tab lists the owned manual")
	scene.action_buttons["iron_palm"].pressed.emit()
	check.call(game.state.player.techniques.has("iron_palm"), "m20b: studying from the screen works")
	scene.select_tab("gear")
	scene.action_buttons["iron_sword"].pressed.emit()
	check.call(game.state.resources.get_item("eq_iron_sword") == 1, "m20b: forging from the screen works")
	scene.action_buttons["iron_sword"].pressed.emit()
	check.call(EquipmentRules.worn(game.state, "weapon") == "iron_sword", "m20b: and wearing it")
	scene.queue_free()
	game.battle = null
