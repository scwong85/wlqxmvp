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
var tech_levels: Dictionary = {}  # technique id -> level (1..10); raises damage and healing
var tech_uses: Dictionary = {}    # technique id -> times used this battle (feeds technique experience)
var used_once: Array = []         # once-per-battle techniques already used
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
	return {"id": id, "team": team, "name_key": name_key, "template": template, "pos": [pos.x, pos.y], "hp": hp,
			"max_hp": max_hp, "body": body, "power": power, "agility": agility, "spirit": spirit, "tp": tp,
			"max_resolve": max_resolve, "resolve": resolve, "broken": broken, "guarding": guarding,
			"statuses": statuses.duplicate(true), "techniques": techniques.duplicate(), "leader": leader,
			"protected": protected, "npc": npc, "ap": ap, "mp": mp, "used_once": used_once.duplicate(),
			"followed_round": followed_round, "tech_levels": tech_levels.duplicate(), "tech_uses": tech_uses.duplicate()}


static func from_dict(d: Dictionary) -> RefCounted:
	var u = new()
	u.id = str(d.get("id", ""))
	u.team = str(d.get("team", "player"))
	u.name_key = str(d.get("name_key", ""))
	u.template = str(d.get("template", ""))
	var p: Array = d.get("pos", [0, 0])
	u.pos = Vector2i(int(p[0]), int(p[1]))
	u.max_hp = maxi(1, int(d.get("max_hp", 1)))
	u.hp = clampi(int(d.get("hp", u.max_hp)), 0, u.max_hp)
	u.body = int(d.get("body", 5))
	u.power = int(d.get("power", 5))
	u.agility = int(d.get("agility", 5))
	u.spirit = int(d.get("spirit", 5))
	u.tp = int(d.get("tp", 0))
	u.max_resolve = maxi(1, int(d.get("max_resolve", 10)))
	u.resolve = clampi(int(d.get("resolve", u.max_resolve)), 0, u.max_resolve)
	u.broken = bool(d.get("broken", false))
	u.guarding = bool(d.get("guarding", false))
	for s in d.get("statuses", []):
		u.statuses.append({"id": str(s.id), "turns": int(s.turns)})
	for t in d.get("techniques", []):
		u.techniques.append(str(t))
	u.leader = bool(d.get("leader", false))
	u.protected = bool(d.get("protected", false))
	u.npc = bool(d.get("npc", false))
	u.ap = int(d.get("ap", 0))
	u.mp = int(d.get("mp", 0))
	for t in d.get("used_once", []):
		u.used_once.append(str(t))
	u.followed_round = int(d.get("followed_round", 0))
	var tl: Variant = d.get("tech_levels", {})
	if tl is Dictionary:
		for k in tl:
			u.tech_levels[str(k)] = clampi(int(tl[k]), 1, 10)
	var tu: Variant = d.get("tech_uses", {})
	if tu is Dictionary:
		for k in tu:
			u.tech_uses[str(k)] = maxi(0, int(tu[k]))
	return u
