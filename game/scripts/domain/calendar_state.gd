extends RefCounted
## The campaign clock (M15): 3 years x 12 months x 5 weeks = 180 weeks, 2 action slots per week = 360 slots.
## `week` runs 1..180 and is the unit for gates and events. `finished` means the very last slot has been used.

const WEEKS_PER_MONTH := 5
const MONTHS_PER_YEAR := 12
const YEARS := 3
const SLOTS := 2
const WEEKS_PER_YEAR := WEEKS_PER_MONTH * MONTHS_PER_YEAR
const WEEKS := WEEKS_PER_YEAR * YEARS
const TOTAL_SLOTS := WEEKS * SLOTS
## The opening month (the prologue) is weeks 1..5.
const PROLOGUE_WEEKS := WEEKS_PER_MONTH

var week: int = 1
var slot: int = 1
var finished: bool = false
var events_fired: Array = []


func year() -> int:
	return (week - 1) / WEEKS_PER_YEAR + 1


## Month of the year, 1..12.
func month() -> int:
	return ((week - 1) % WEEKS_PER_YEAR) / WEEKS_PER_MONTH + 1


## Week inside the month, 1..5.
func week_in_month() -> int:
	return (week - 1) % WEEKS_PER_MONTH + 1


## 0 spring, 1 summer, 2 autumn, 3 winter (three months each).
func season() -> int:
	return (month() - 1) / 3


## Number of slots already used, 0..360 (360 once finished).
func slots_used() -> int:
	return TOTAL_SLOTS if finished else (week - 1) * SLOTS + (slot - 1)


## Moves to the next slot. Returns {advanced, new_week, new_month, new_year, finished}.
func advance_slot() -> Dictionary:
	if finished:
		return {"advanced": false, "new_week": false, "new_month": false, "new_year": false, "finished": true}
	if slot < SLOTS:
		slot += 1
		return {"advanced": true, "new_week": false, "new_month": false, "new_year": false, "finished": false}
	if week < WEEKS:
		week += 1
		slot = 1
		return {"advanced": true, "new_week": true, "new_month": week_in_month() == 1, "new_year": week % WEEKS_PER_YEAR == 1, "finished": false}
	finished = true
	return {"advanced": true, "new_week": false, "new_month": false, "new_year": false, "finished": true}


func to_dict() -> Dictionary:
	return {"week": week, "slot": slot, "finished": finished, "events_fired": events_fired.duplicate()}


static func from_dict(d: Variant) -> RefCounted:
	var s = new()
	if not (d is Dictionary):
		return s
	s.week = clampi(int(d.get("week", 1)), 1, WEEKS)
	s.slot = clampi(int(d.get("slot", 1)), 1, SLOTS)
	s.finished = bool(d.get("finished", false))
	var fired: Variant = d.get("events_fired", [])
	if fired is Array:
		for e in fired:
			if e is String and not s.events_fired.has(e):
				s.events_fired.append(e)
	return s
