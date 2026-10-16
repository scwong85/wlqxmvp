extends RefCounted
## Gear: weapon, armor and charm. Forged from ore and coins, kept as items, one worn per slot. Bonuses apply in battle.
## content/cultivation/equipment.json: [{id, item, name_key, slot, realm_min, cost:{ore, coins}, bonus:{stat: n}}]

const SLOTS := ["weapon", "armor", "charm"]


static func piece(content: Object, id: String) -> Dictionary:
	for e in content.equipment:
		if str(e.id) == id:
			return e
	return {}


static func owned(state: RefCounted, id: String, content: Object) -> bool:
	var e := piece(content, id)
	return not e.is_empty() and state.resources.get_item(str(e.item)) > 0


static func worn(state: RefCounted, slot: String) -> String:
	return str(state.cultivation.equipment.get(slot, ""))


## {ok, reasons:[{key, params}]}.
static func can_forge(state: RefCounted, id: String, content: Object) -> Dictionary:
	var e := piece(content, id)
	if e.is_empty() or owned(state, id, content):
		return {"ok": false, "reasons": [{"key": "equip.owned", "params": {}}]}
	var reasons: Array = []
	if int(state.cultivation.realm) < int(e.realm_min):
		reasons.append({"key": "equip.realm", "params": {"realm": int(e.realm_min)}})
	if not state.resources.can_afford(e.cost):
		reasons.append({"key": "equip.poor", "params": {}})
	return {"ok": reasons.is_empty(), "reasons": reasons}


static func forge(state: RefCounted, id: String, content: Object) -> Dictionary:
	var c := can_forge(state, id, content)
	if not c.ok:
		return c
	var e := piece(content, id)
	for k in e.cost:
		state.resources.spend(str(k), int(e.cost[k]))
	state.resources.add_item(str(e.item), 1)
	return {"ok": true, "reasons": [], "piece": e}


## Wears an owned piece in its slot (replacing the old one). Empty id takes the slot's piece off.
static func equip(state: RefCounted, slot: String, id: String, content: Object) -> bool:
	if not SLOTS.has(slot):
		return false
	if id == "":
		state.cultivation.equipment.erase(slot)
		return true
	var e := piece(content, id)
	if e.is_empty() or str(e.slot) != slot or not owned(state, id, content):
		return false
	state.cultivation.equipment[slot] = id
	return true


## Total bonuses of everything worn: {stat: amount}.
static func bonus(state: RefCounted, content: Object) -> Dictionary:
	var out := {}
	for slot in SLOTS:
		var e := piece(content, worn(state, slot))
		if e.is_empty() or not owned(state, str(e.id), content):
			continue
		for k in e.bonus:
			out[str(k)] = int(out.get(str(k), 0)) + int(e.bonus[k])
	return out
