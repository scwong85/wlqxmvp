extends RefCounted
## Seven days, two activity slots per day. `finished` means the final slot has been used.

const DAYS := 7
const SLOTS := 2

var day: int = 1
var slot: int = 1
var finished: bool = false
var events_fired: Array = []


## Moves to the next slot. Returns {advanced, new_day, finished}.
func advance_slot() -> Dictionary:
	if finished:
		return {"advanced": false, "new_day": false, "finished": true}
	if slot < SLOTS:
		slot += 1
		return {"advanced": true, "new_day": false, "finished": false}
	if day < DAYS:
		day += 1
		slot = 1
		return {"advanced": true, "new_day": true, "finished": false}
	finished = true
	return {"advanced": true, "new_day": false, "finished": true}


func to_dict() -> Dictionary:
	return {"day": day, "slot": slot, "finished": finished, "events_fired": events_fired.duplicate()}


static func from_dict(d: Variant) -> RefCounted:
	var s = new()
	if not (d is Dictionary):
		return s
	s.day = clampi(int(d.get("day", 1)), 1, DAYS)
	s.slot = clampi(int(d.get("slot", 1)), 1, SLOTS)
	s.finished = bool(d.get("finished", false))
	var fired: Variant = d.get("events_fired", [])
	if fired is Array:
		for e in fired:
			if e is String and not s.events_fired.has(e):
				s.events_fired.append(e)
	return s
