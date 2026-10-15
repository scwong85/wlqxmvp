extends RefCounted
## One fighter. Plain data plus a few helpers; all rules live in CombatRules / Battle.

var id: String = ""
var team: String = "player"       # "player" or "enemy"
var name_key: String = ""
var template: String = ""
var pos: Vector2i = Vector2i.ZERO
var max_hp: int = 1
var hp: int = 1
var body: int = 5
var power: int = 5
var agility: int = 5
var spirit: int = 5
var tp: int = 0                   # technique points left this battle
var max_resolve: int = 10
var resolve: int = 10
var broken: bool = false          # Break: next turn is lost, resolve then refills
var guarding: bool = false        # lasts until this unit's next turn starts
var statuses: Array = []          # [{id, turns}]
var techniques: Array = []        # technique ids (basic_attack is always available)
var leader: bool = false
var protected: bool = false       # objective: this unit must survive
var npc: bool = false             # takes no actions of its own (e.g. the villager to protect)
var ap: int = 0
var mp: int = 0
var followed_round: int = 0       # last round in which this unit took a follow-up (one per round)


func alive() -> bool:
	return hp > 0


func defense() -> int:
	return body / 2


func initiative() -> int:
	return agility


func has_status(status_id: String) -> bool:
	for s in statuses:
		if s.id == status_id:
			return true
	return false


## Adds or refreshes a status (no stacking: the longer duration wins).
func add_status(status_id: String, turns: int) -> void:
	for s in statuses:
		if s.id == status_id:
			s.turns = maxi(int(s.turns), turns)
			return
	statuses.append({"id": status_id, "turns": turns})


func to_dict() -> Dictionary:
	return {"id": id, "team": team, "pos": [pos.x, pos.y], "hp": hp, "max_hp": max_hp, "tp": tp, "resolve": resolve,
			"broken": broken, "guarding": guarding, "statuses": statuses.duplicate(true), "ap": ap, "mp": mp,
			"followed_round": followed_round, "npc": npc}
