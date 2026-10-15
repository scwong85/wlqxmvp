extends RefCounted
## Technique levels 1..10 from experience. Experience comes from practising (the technique-practice activity) and from
## using the technique in battle. Each two levels above 1 add 1 damage / 1 healing in combat (see Battle.leveled).

const MAX_LEVEL := 10
## Cumulative experience needed for level 1..10.
const XP_FOR_LEVEL := [0, 3, 8, 15, 25, 38, 55, 75, 100, 130]


static func level_for_xp(xp: int) -> int:
	var lv := 1
	for i in XP_FOR_LEVEL.size():
		if xp >= int(XP_FOR_LEVEL[i]):
			lv = i + 1
	return lv


static func level(state: RefCounted, tech_id: String) -> int:
	return level_for_xp(int(state.cultivation.technique_xp.get(tech_id, 0)))


## Experience still needed for the next level (0 at the maximum).
static func xp_to_next(state: RefCounted, tech_id: String) -> int:
	var lv := level(state, tech_id)
	if lv >= MAX_LEVEL:
		return 0
	return int(XP_FOR_LEVEL[lv]) - int(state.cultivation.technique_xp.get(tech_id, 0))


## Adds experience to a known technique. Returns {level_before, level_after}.
static func add_xp(state: RefCounted, tech_id: String, amount: int) -> Dictionary:
	var before := level(state, tech_id)
	if amount > 0 and state.player.techniques.has(tech_id):
		state.cultivation.technique_xp[tech_id] = int(state.cultivation.technique_xp.get(tech_id, 0)) + amount
	return {"level_before": before, "level_after": level(state, tech_id)}


## Levels of all the hero's techniques, for the battle unit.
static func levels_of(state: RefCounted) -> Dictionary:
	var out := {}
	for t in state.player.techniques:
		out[str(t)] = level(state, str(t))
	return out
