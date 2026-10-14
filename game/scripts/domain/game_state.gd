extends RefCounted
## Everything that must survive a save/load. Never put transient UI state here.

const SCHEMA_VERSION := 1

const PlayerState = preload("res://scripts/domain/player_state.gd")
const CalendarState = preload("res://scripts/domain/calendar_state.gd")
const ResourceState = preload("res://scripts/domain/resource_state.gd")
const CultivationState = preload("res://scripts/domain/cultivation_state.gd")
const RelationshipState = preload("res://scripts/domain/relationship_state.gd")

var player: RefCounted
var calendar: RefCounted
var resources: RefCounted
var cultivation: RefCounted
var relationships: RefCounted


func _init() -> void:
	player = PlayerState.new()
	calendar = CalendarState.new()
	resources = ResourceState.new()
	cultivation = CultivationState.new()
	relationships = RelationshipState.new()


static func new_game() -> RefCounted:
	return new()


func to_dict() -> Dictionary:
	return {
		"player": player.to_dict(),
		"calendar": calendar.to_dict(),
		"resources": resources.to_dict(),
		"cultivation": cultivation.to_dict(),
		"relationships": relationships.to_dict(),
	}


## Tolerant loader: missing or malformed sections fall back to defaults; unknown keys are ignored.
static func from_dict(d: Variant) -> RefCounted:
	var s = new()
	if not (d is Dictionary):
		return s
	s.player = PlayerState.from_dict(d.get("player"))
	s.calendar = CalendarState.from_dict(d.get("calendar"))
	s.resources = ResourceState.from_dict(d.get("resources"))
	s.cultivation = CultivationState.from_dict(d.get("cultivation"))
	s.relationships = RelationshipState.from_dict(d.get("relationships"))
	return s
