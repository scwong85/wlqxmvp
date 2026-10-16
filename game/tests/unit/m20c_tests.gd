extends RefCounted
## M20c tests: a party of two companions, saving it, and duo techniques in battle.

const GameState = preload("res://scripts/domain/game_state.gd")
const PartySystem = preload("res://scripts/domain/party_system.gd")
const RelationshipRules = preload("res://scripts/domain/relationship_rules.gd")
const BattleSetup = preload("res://scripts/domain/combat/battle_setup.gd")
const CombatRules = preload("res://scripts/domain/combat/combat_rules.gd")
const ContentService = preload("res://scripts/services/content_service.gd")

var check: Callable
var content: Node


func run(check_fn: Callable, _loc: Node) -> void:
	check = check_fn
	content = ContentService.new()
	content.load_all()
	_party()
	_duo()
	_screen()
	content.free()


func _state() -> RefCounted:
	var s: RefCounted = GameState.new_game(9)
	s.player.path_id = "xuan_fist"
	for id in ["shen_qinghe", "lu_chenzhou", "bai_yan"]:
		s.relationships.set_status(id, "joined")
	return s


func _party() -> void:
	var s := _state()
	check.call(PartySystem.party(s).is_empty(), "m20c: the party starts empty")
	PartySystem.set_active(s, "shen_qinghe")
	PartySystem.set_active(s, "lu_chenzhou")
	check.call(PartySystem.party(s) == ["shen_qinghe", "lu_chenzhou"], "m20c: two companions can be in the party")
	PartySystem.set_active(s, "bai_yan")
	check.call(PartySystem.party(s) == ["shen_qinghe", "bai_yan"], "m20c: a third replaces the second place")
	check.call(PartySystem.set_active(s, "shen_qinghe") and PartySystem.party(s).size() == 2, "m20c: adding someone already in the party changes nothing")
	check.call(PartySystem.leave(s, "shen_qinghe") and PartySystem.party(s) == ["bai_yan"] and s.relationships.active == "bai_yan", "m20c: when the first steps out the second moves up")
	check.call(not PartySystem.set_active(GameState.new_game(1), "bai_yan"), "m20c: only joined companions can be added")
	PartySystem.set_active(s, "lu_chenzhou")
	PartySystem.dismiss(s, "bai_yan")
	check.call(PartySystem.party(s) == ["lu_chenzhou"] and s.relationships.get_status("bai_yan") == "left", "m20c: dismissing removes them from the party")
	var back: RefCounted = GameState.from_dict(JSON.parse_string(JSON.stringify(_two().to_dict())))
	check.call(PartySystem.party(back) == ["shen_qinghe", "lu_chenzhou"], "m20c: the party survives saving")
	var bad: RefCounted = GameState.from_dict({"relationships": {"status": {"a": "joined"}, "active": "a", "second": "a"}})
	check.call(PartySystem.party(bad) == ["a"], "m20c: a damaged save cannot repeat or invent members")
	var gone: RefCounted = GameState.from_dict({"relationships": {"status": {"a": "joined"}, "active": "", "second": "a"}})
	check.call(gone.relationships.active == "a" and gone.relationships.second == "", "m20c: a lone second member moves up")
	var two := _two()
	two.relationships.scores["lu_chenzhou"] = 20
	two.relationships.set_flag("x")
	var b: RefCounted = BattleSetup.build(content, "training_match", 4, two, PartySystem.party(two))
	check.call(b.units.filter(func(u: RefCounted) -> bool: return u.team == "player").size() == 3, "m20c: the battle has the hero and two companions")


func _two() -> RefCounted:
	var s := _state()
	PartySystem.set_active(s, "shen_qinghe")
	PartySystem.set_active(s, "lu_chenzhou")
	return s


func _duo() -> void:
	var s := _two()
	var party := PartySystem.party(s)
	var weak: RefCounted = BattleSetup.build(content, "training_match", 5, s, party)
	check.call(not weak.units[0].techniques.has("duo_spring_breeze"), "m20c: a weak bond gives no duo technique")
	s.relationships.scores["shen_qinghe"] = 12
	var b: RefCounted = BattleSetup.build(content, "training_match", 5, s, party)
	var hero: RefCounted = b.units[0]
	check.call(hero.techniques.has("duo_spring_breeze") and not hero.techniques.has("duo_twin_dash"), "m20c: a strong bond unlocks that companion's duo technique")
	var without: RefCounted = BattleSetup.build(content, "training_match", 5, s, [])
	check.call(not without.units[0].techniques.has("duo_spring_breeze"), "m20c: without the companion there is no duo")
	var tech: Dictionary = content.combat_tech("duo_spring_breeze")
	var foe: RefCounted = b.units.filter(func(u: RefCounted) -> bool: return u.team == "enemy")[0]
	var with_partner := CombatRules.attack_result(b, hero, tech, foe)
	check.call(with_partner.mods.has("duo"), "m20c: the duo attack is marked")
	var plain := CombatRules.attack_result(b, hero, {"id": "x", "kind": "attack", "damage": int(tech.damage), "range": 3}, foe)
	check.call(int(with_partner.damage) > int(plain.damage), "m20c: the partner adds damage")
	check.call(b.duo_ready(tech), "m20c: the duo is ready while the partner stands")
	b.unit("shen_qinghe").hp = 0
	check.call(not b.duo_ready(tech) and not b.can_use(hero, "duo_spring_breeze"), "m20c: it cannot be used once the partner has fallen")
	check.call(not b.preview_attack("hero", "duo_spring_breeze", foe.id).ok, "m20c: and the preview refuses it")


func _screen() -> void:
	var root: Node = Engine.get_main_loop().root
	var game: Node = root.get_node("Game")
	game.new_game(53)
	for id in ["shen_qinghe", "lu_chenzhou", "bai_yan"]:
		game.state.relationships.set_status(id, "joined")
	check.call(game.set_active_companion("shen_qinghe") and game.set_active_companion("lu_chenzhou"), "m20c: the session adds two companions")
	check.call(game.start_battle("training_match", "practice") and game.battle.units.filter(func(u: RefCounted) -> bool: return u.team == "player").size() == 3, "m20c: a battle started by the session brings both")
	check.call(game.leave_party("shen_qinghe") and PartySystem.party(game.state) == ["lu_chenzhou"], "m20c: a companion can step out of the party")
	game.battle = null
