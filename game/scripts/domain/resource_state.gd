extends RefCounted
## Coins, materials and items. Amounts never go below zero.

const CURRENCIES := ["coins", "food", "herbs", "ore", "medicine"]
const START_COINS := 20

var amounts: Dictionary = {}
var items: Dictionary = {}


func _init() -> void:
	for c in CURRENCIES:
		amounts[c] = 0
	amounts["coins"] = START_COINS


func get_amount(id: String) -> int:
	return int(amounts.get(id, 0))


## Adds (or removes, if negative) and clamps at zero. Returns the change actually applied.
func add(id: String, n: int) -> int:
	if not CURRENCIES.has(id):
		return 0
	var before := get_amount(id)
	amounts[id] = maxi(0, before + n)
	return get_amount(id) - before


## Spends only if the full amount is available. Nothing changes on failure.
func spend(id: String, n: int) -> bool:
	if n < 0 or not CURRENCIES.has(id) or get_amount(id) < n:
		return false
	amounts[id] = get_amount(id) - n
	return true


func can_afford(costs: Dictionary) -> bool:
	for id in costs:
		if get_amount(str(id)) < int(costs[id]):
			return false
	return true


func get_item(id: String) -> int:
	return int(items.get(id, 0))


func add_item(id: String, n: int) -> int:
	if id == "":
		return 0
	var before := get_item(id)
	var after := maxi(0, before + n)
	if after == 0:
		items.erase(id)
	else:
		items[id] = after
	return after - before


func to_dict() -> Dictionary:
	return {"amounts": amounts.duplicate(), "items": items.duplicate()}


static func from_dict(d: Variant) -> RefCounted:
	var s = new()
	if not (d is Dictionary):
		return s
	var a: Variant = d.get("amounts", {})
	if a is Dictionary:
		for c in CURRENCIES:
			if a.has(c):
				s.amounts[c] = maxi(0, int(a[c]))
	var it: Variant = d.get("items", {})
	if it is Dictionary:
		for k in it:
			s.add_item(str(k), int(it[k]))
	return s
