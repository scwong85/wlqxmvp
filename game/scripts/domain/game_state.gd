extends RefCounted
## Everything that must survive a save/load. Never put transient UI state here.

const SCHEMA_VERSION := 8

const PlayerState = preload("res://scripts/domain/player_state.gd")
const CalendarState = preload("res://scripts/domain/calendar_state.gd")
const ResourceState = preload("res://scripts/domain/resource_state.gd")
const CultivationState = preload("res://scripts/domain/cultivation_state.gd")
const RelationshipState = preload("res://scripts/domain/relationship_state.gd")
const StoryState = preload("res://scripts/domain/story_state.gd")
const WorldState = preload("res://scripts/domain/world_state.gd")
const ExplorationState = preload("res://scripts/domain/exploration_state.gd")
const CultivationRules = preload("res://scripts/domain/cultivation_rules.gd")

var player: RefCounted
var calendar: RefCounted
var resources: RefCounted
var cultivation: RefCounted
var relationships: RefCounted
var exploration: RefCounted
var story: RefCounted
var world: RefCounted
## Snapshot of a battle in progress (see Battle.to_dict plus ctx), empty when none. Lets an interrupted fight resume.
var battle: Dictionary = {}
## Seeds every skill check in this run, so outcomes are reproducible from a save.
var run_seed: int = 1


func _init() -> void:
	player = PlayerState.new()
	calendar = CalendarState.new()
	resources = ResourceState.new()
	cultivation = CultivationState.new()
	relationships = RelationshipState.new()
	exploration = ExplorationState.new()
	story = StoryState.new()
	world = WorldState.new()
	_resolve_stamina()


## seed_value < 0 picks a fresh random seed; tests pass an explicit one.
static func new_game(seed_value: int = -1) -> RefCounted:
	var g = new()
	g.run_seed = seed_value if seed_value >= 0 else int(randi() & 0x7fffffff)
	return g


func _resolve_stamina() -> void:
	if player.stamina < 0:
		player.stamina = CultivationRules.max_stamina(player)
	CultivationRules.clamp_stamina(player)


func to_dict() -> Dictionary:
	return {
		"player": player.to_dict(),
		"calendar": calendar.to_dict(),
		"resources": resources.to_dict(),
		"cultivation": cultivation.to_dict(),
		"relationships": relationships.to_dict(),
		"exploration": exploration.to_dict(),
		"battle": battle.duplicate(true),
		"story": story.to_dict(),
		"world": world.to_dict(),
		"run_seed": run_seed,
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
	s.exploration = ExplorationState.from_dict(d.get("exploration"))
	s.story = StoryState.from_dict(d.get("story"))
	s.world = WorldState.from_dict(d.get("world"))
	var snap: Variant = d.get("battle")
	s.battle = (snap as Dictionary).duplicate(true) if snap is Dictionary else {}
	s.run_seed = maxi(0, int(d.get("run_seed", 1)))
	s._resolve_stamina()
	return s
